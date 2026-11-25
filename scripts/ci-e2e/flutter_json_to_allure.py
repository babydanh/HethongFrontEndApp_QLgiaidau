"""Đổi đầu ra `flutter test --reporter json` (hoặc `--file-reporter json:<file>`) thành thư mục allure-results.

  python flutter_json_to_allure.py <flutter-test.json> <allure-results-dir>

Mỗi ca test hiển thị là một `<uuid>-result.json`. Ca hidden (setUpAll, loading...) bị bỏ, trừ khi chúng hỏng:
loading lỗi biên dịch là lỗi thật và nếu bỏ thì lượt chạy trông như không có ca nào.
Ảnh do integration_test/support/shot.dart in ra dạng nhiều dòng print:
  [[SHOT-BEGIN name bytes]] / [[SHOT name i]] <base64> ... / [[SHOT-END name]]
(cũng nhận dạng một dòng `[[SHOT name]]<base64>`) được ghép theo chỉ số i, giải mã thành `<uuid>-attachment.png`.
Ảnh thiếu đoạn hoặc sai kích thước không được đính kèm. Không in nội dung ảnh ra log.
Exit 0 kể cả có ca đỏ; exit 2 khi không đọc được file vào.
"""
import base64
import binascii
import hashlib
import json
import os
import re
import sys
import uuid

CHUNK_RE = re.compile(r"^\[\[SHOT (.+?) (\d+)\]\] ?(.*)$")
SIMPLE_RE = re.compile(r"^\[\[SHOT ([^\]]+?)\]\] ?(\S.*)$")
BEGIN_RE = re.compile(r"^\[\[SHOT-BEGIN (.+) (\d+)\]\]$")
END_RE = re.compile(r"^\[\[SHOT-END (.+)\]\]$")
TC_RE = re.compile(r"\bTC-[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*-\d+\b")
STATUS = {"success": "passed", "failure": "failed", "error": "broken"}


class ShotCollector:
    """Gom các dòng SHOT của một ca; `finish()` trả về [(tên, bytes PNG)] theo thứ tự xuất hiện."""

    def __init__(self):
        self._shots = {}   # tên -> {"size": int|None, "parts": {i: str}, "ended": bool}
        self._order = []
        self.done = []     # ảnh đơn dòng đã giải mã

    def _slot(self, name):
        if name not in self._shots:
            self._shots[name] = {"size": None, "parts": {}, "ended": False}
            self._order.append(name)
        return self._shots[name]

    def feed(self, line):
        line = line.strip()
        if not line.startswith("[[SHOT"):
            return
        m = BEGIN_RE.match(line)
        if m:
            self._slot(m.group(1))["size"] = int(m.group(2))
            return
        m = END_RE.match(line)
        if m:
            self._slot(m.group(1))["ended"] = True
            return
        m = CHUNK_RE.match(line)
        if m:
            self._slot(m.group(1))["parts"][int(m.group(2))] = m.group(3).strip()
            return
        m = SIMPLE_RE.match(line)
        if m:
            data = _decode(m.group(2).strip())
            if data:
                self._order.append(m.group(1))
                self.done.append((m.group(1), data))

    def finish(self):
        out = list(self.done)
        for name in self._order:
            slot = self._shots.get(name)
            if not slot or not slot["ended"] or not slot["parts"]:
                continue
            parts = slot["parts"]
            if sorted(parts) != list(range(len(parts))):
                print(f"Bỏ ảnh '{name}': thiếu đoạn", file=sys.stderr)
                continue
            data = _decode("".join(parts[i] for i in range(len(parts))))
            if data is None or (slot["size"] is not None and len(data) != slot["size"]):
                print(f"Bỏ ảnh '{name}': base64 hỏng hoặc sai kích thước", file=sys.stderr)
                continue
            out.append((name, data))
        return out


def _decode(text):
    try:
        return base64.b64decode(text, validate=True)
    except (binascii.Error, ValueError):
        return None


def short_suite(path):
    path = (path or "").replace("\\", "/")
    idx = path.rfind("integration_test/")
    if idx >= 0:
        return path[idx:]
    return os.path.basename(path) or "unknown"


def read_events(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            raw = raw.strip()
            if not raw.startswith("{"):
                continue
            try:
                event = json.loads(raw)
            except ValueError:
                continue
            if isinstance(event, dict):
                yield event


def is_loading(name):
    return name.startswith("loading ")


def build_result(test, done, errors, shots, suite, out_dir, base_ms):
    name = test["name"]
    if done.get("skipped") or test.get("skipped"):
        status = "skipped"
    else:
        status = STATUS.get(done.get("result"), "broken")
    labels = [{"name": "suite", "value": suite}, {"name": "framework", "value": "flutter-integration-test"}]
    tc = TC_RE.search(name)
    if tc:
        labels.append({"name": "story", "value": tc.group(0)})
    result = {
        "uuid": str(uuid.uuid4()),
        "historyId": hashlib.md5(f"{suite}::{name}".encode("utf-8")).hexdigest(),
        "name": name,
        "fullName": name,
        "status": status,
        "stage": "finished",
        "start": base_ms + test["start"],
        "stop": base_ms + done.get("time", test["start"]),
        "labels": labels,
        "attachments": [],
    }
    if status == "skipped" and test.get("skipReason"):
        result["statusDetails"] = {"message": test["skipReason"], "trace": ""}
    if errors:
        result["statusDetails"] = {
            "message": "\n\n".join(e.get("error", "") for e in errors),
            "trace": "\n\n".join(e.get("stackTrace", "") for e in errors),
        }
    for shot_name, data in shots:
        source = f"{uuid.uuid4()}-attachment.png"
        with open(os.path.join(out_dir, source), "wb") as fh:
            fh.write(data)
        result["attachments"].append({"name": shot_name, "source": source, "type": "image/png"})
    return result


def attach_video(result, segments, video_dir, out_dir):
    """Cắt clip của ca từ các đoạn quay màn hình và đính vào result (mọi ca, không chỉ ca đỏ). Lỗi thì bỏ qua."""
    import app_video_clips as av

    plan = av.plan_clips(segments, result["start"], result["stop"])
    if not plan:
        return
    source = f"{uuid.uuid4()}-attachment.mp4"
    if av.cut_clip(plan, os.path.join(out_dir, source), video_dir):
        result["attachments"].append({"name": "video", "source": source, "type": "video/mp4"})


def convert(src, out_dir, video_dir=None, run_start_ms=None):
    """Trả về số ca đã ghi. Ném OSError nếu không đọc được src.

    Có `video_dir` (và `run_start_ms`: epoch ms lúc `flutter test` bắt đầu) thì mỗi ca có thêm clip video."""
    import time

    events = list(read_events(src))
    os.makedirs(out_dir, exist_ok=True)
    suites, tests, errors, shots = {}, {}, {}, {}
    last_time = max((e.get("time", 0) for e in events if isinstance(e.get("time"), int)), default=0)
    base_ms = run_start_ms if run_start_ms is not None else int(time.time() * 1000) - last_time
    segments = []
    if video_dir and os.path.isdir(video_dir):
        import app_video_clips as av

        segments = av.list_segments(video_dir)
    written = 0
    for e in events:
        kind = e.get("type")
        if kind == "suite":
            suites[e["suite"]["id"]] = e["suite"].get("path")
        elif kind == "testStart":
            t = e["test"]
            meta = t.get("metadata") or {}
            tests[t["id"]] = {"name": t["name"], "suiteID": t.get("suiteID"), "start": e.get("time", 0),
                              "skipped": bool(meta.get("skip")), "skipReason": meta.get("skipReason")}
        elif kind == "print":
            collector = shots.setdefault(e.get("testID"), ShotCollector())
            for line in str(e.get("message", "")).splitlines():
                collector.feed(line)
        elif kind == "error":
            errors.setdefault(e.get("testID"), []).append(e)
        elif kind == "testDone":
            test = tests.get(e.get("testID"))
            if not test:
                continue
            failed = e.get("result") != "success"
            if (e.get("hidden") or is_loading(test["name"])) and not failed:
                continue
            collector = shots.get(e["testID"])
            suite = short_suite(suites.get(test["suiteID"]))
            result = build_result(test, e, errors.get(e["testID"], []), collector.finish() if collector else [],
                                  suite, out_dir, base_ms)
            if segments:
                attach_video(result, segments, video_dir, out_dir)
            with open(os.path.join(out_dir, f"{result['uuid']}-result.json"), "w", encoding="utf-8") as fh:
                json.dump(result, fh, ensure_ascii=False)
            written += 1
    return written


def main(argv):
    args = list(argv[1:])
    video_dir = run_start_ms = None
    try:
        if "--video-dir" in args:
            i = args.index("--video-dir")
            video_dir = args[i + 1]
            del args[i:i + 2]
        if "--run-start-ms" in args:
            i = args.index("--run-start-ms")
            run_start_ms = int(args[i + 1])
            del args[i:i + 2]
    except (IndexError, ValueError):
        args = []
    if len(args) != 2:
        print("Cách dùng: flutter_json_to_allure.py <flutter-test.json> <allure-results-dir> "
              "[--video-dir <thư mục seg_*.mp4> --run-start-ms <epoch ms>]", file=sys.stderr)
        return 2
    argv = [argv[0]] + args
    try:
        count = convert(argv[1], argv[2], video_dir=video_dir, run_start_ms=run_start_ms)
    except OSError as exc:
        print(f"Không đọc được {argv[1]}: {exc.strerror or exc}", file=sys.stderr)
        return 2
    print(f"flutter_json_to_allure: {count} ca -> {argv[2]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
