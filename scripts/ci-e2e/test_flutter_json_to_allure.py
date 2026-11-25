import base64
import glob
import json
import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import flutter_json_to_allure as fa  # noqa: E402

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "flutter_json_to_allure.py")
SUITE = "/home/runner/work/app/integration_test/demo_test.dart"
PNG = b"\x89PNG\r\n\x1a\n" + bytes(range(256)) * 5  # nhị phân giả, đủ dài để chia nhiều đoạn


def chunks(data, size=800):
    # Giống chunkBase64 trong integration_test/support/shot.dart.
    enc = base64.b64encode(data).decode()
    step = size - size % 4
    return [enc[i:i + step] for i in range(0, len(enc), step)]


def shot_lines(name, data):
    out = [f"[[SHOT-BEGIN {name} {len(data)}]]"]
    out += [f"[[SHOT {name} {i}]] {c}" for i, c in enumerate(chunks(data))]
    out.append(f"[[SHOT-END {name}]]")
    return out


def ev_start(tid, name, suite_id=0, skip=False, reason=None, t=0):
    return {"type": "testStart", "time": t, "test": {
        "id": tid, "name": name, "suiteID": suite_id, "groupIDs": [],
        "metadata": {"skip": skip, "skipReason": reason}, "line": 1, "column": 1}}


def ev_done(tid, result="success", hidden=False, skipped=False, t=0):
    return {"type": "testDone", "time": t, "testID": tid, "result": result, "hidden": hidden, "skipped": skipped}


def ev_print(tid, msg, t=0):
    return {"type": "print", "time": t, "testID": tid, "messageType": "print", "message": msg}


def fixture_events():
    ev = [
        {"type": "start", "time": 0, "protocolVersion": "0.1.1", "runnerVersion": "1.26.0", "pid": 1},
        {"type": "suite", "time": 1, "suite": {"id": 0, "platform": "vm", "path": SUITE}},
        ev_start(1, f"loading {SUITE}", t=2),
        ev_done(1, hidden=True, t=3),
        {"type": "group", "time": 4, "group": {"id": 2, "suiteID": 0, "parentID": None, "name": "", "testCount": 3}},
        ev_start(3, "(setUpAll)", t=5),
        ev_done(3, hidden=True, t=6),
        ev_start(4, "TC-MULTI-A-01 đăng nhập đạt", t=10),
        ev_print(4, "log thường không phải ảnh", t=11),
    ]
    ev += [ev_print(4, line, t=12) for line in shot_lines("buoc1", PNG)]
    ev.append(ev_done(4, t=100))
    ev += [
        ev_start(5, "TC-MULTI-A-02 đỏ", t=110),
        {"type": "error", "time": 120, "testID": 5, "error": "Expected: <1>\n  Actual: <2>",
         "stackTrace": "package:test_api expect\nintegration_test/demo_test.dart 30:5", "isFailure": True},
        ev_done(5, result="failure", t=130),
        ev_start(6, "ca bỏ qua", skip=True, reason="BUG-REF-01", t=140),
        ev_done(6, skipped=True, t=141),
        ev_start(7, "ca lỗi hạ tầng", t=150),
        {"type": "error", "time": 160, "testID": 7, "error": "SocketException", "stackTrace": "st", "isFailure": False},
        ev_done(7, result="error", t=170),
        {"type": "done", "time": 200, "success": False},
    ]
    return ev


def write_events(path, events, extra_lines=()):
    with open(path, "w", encoding="utf-8") as fh:
        for line in extra_lines:
            fh.write(line + "\n")
        for e in events:
            fh.write(json.dumps(e) + "\n")


class ConvertTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.src = os.path.join(self.tmp.name, "flutter-test.json")
        self.out = os.path.join(self.tmp.name, "allure-results")

    def results(self):
        res = {}
        for p in glob.glob(os.path.join(self.out, "*-result.json")):
            with open(p, encoding="utf-8") as fh:
                r = json.load(fh)
            res[r["name"]] = r
        return res

    def convert(self, events, extra_lines=()):
        write_events(self.src, events, extra_lines)
        return fa.convert(self.src, self.out)

    def attachment_bytes(self, att):
        with open(os.path.join(self.out, att["source"]), "rb") as fh:
            return fh.read()

    def test_one_result_per_visible_test_with_status(self):
        self.convert(fixture_events())
        res = self.results()
        self.assertEqual(
            sorted(res), ["TC-MULTI-A-01 đăng nhập đạt", "TC-MULTI-A-02 đỏ", "ca bỏ qua", "ca lỗi hạ tầng"])
        self.assertEqual(res["TC-MULTI-A-01 đăng nhập đạt"]["status"], "passed")
        self.assertEqual(res["TC-MULTI-A-02 đỏ"]["status"], "failed")
        self.assertEqual(res["ca bỏ qua"]["status"], "skipped")
        self.assertEqual(res["ca lỗi hạ tầng"]["status"], "broken")

    def test_hidden_and_loading_cases_are_dropped(self):
        self.convert(fixture_events())
        names = " ".join(self.results())
        self.assertNotIn("loading", names)
        self.assertNotIn("setUpAll", names)

    def test_failed_loading_case_is_kept_as_broken(self):
        events = [
            {"type": "suite", "time": 1, "suite": {"id": 0, "platform": "vm", "path": SUITE}},
            ev_start(1, f"loading {SUITE}", t=2),
            {"type": "error", "time": 3, "testID": 1, "error": "Compilation failed", "stackTrace": "", "isFailure": False},
            ev_done(1, result="error", hidden=True, t=4),
        ]
        self.convert(events)
        res = self.results()
        self.assertEqual(len(res), 1)
        self.assertEqual(next(iter(res.values()))["status"], "broken")

    def test_failure_details_and_times(self):
        self.convert(fixture_events())
        r = self.results()["TC-MULTI-A-02 đỏ"]
        self.assertIn("Expected: <1>", r["statusDetails"]["message"])
        self.assertIn("demo_test.dart 30:5", r["statusDetails"]["trace"])
        self.assertEqual(r["stop"] - r["start"], 20)  # 130 - 110 ms
        self.assertEqual(r["fullName"], "TC-MULTI-A-02 đỏ")

    def test_skip_reason_goes_to_status_details(self):
        self.convert(fixture_events())
        self.assertIn("BUG-REF-01", self.results()["ca bỏ qua"]["statusDetails"]["message"])

    def test_labels_suite_and_story(self):
        self.convert(fixture_events())
        res = self.results()
        labels = {x["name"]: x["value"] for x in res["TC-MULTI-A-01 đăng nhập đạt"]["labels"]}
        self.assertEqual(labels["suite"], "integration_test/demo_test.dart")
        self.assertEqual(labels["story"], "TC-MULTI-A-01")
        no_tc = {x["name"] for x in res["ca bỏ qua"]["labels"]}
        self.assertIn("suite", no_tc)
        self.assertNotIn("story", no_tc)

    def test_chunked_screenshot_becomes_png_attachment(self):
        self.convert(fixture_events())
        r = self.results()["TC-MULTI-A-01 đăng nhập đạt"]
        self.assertEqual(len(r["attachments"]), 1)
        att = r["attachments"][0]
        self.assertEqual(att["name"], "buoc1")
        self.assertEqual(att["type"], "image/png")
        self.assertTrue(att["source"].endswith("-attachment.png"))
        self.assertEqual(self.attachment_bytes(att), PNG)

    def test_chunks_are_joined_by_index_not_arrival_order(self):
        lines = shot_lines("dao", PNG)
        begin, body, end = lines[0], lines[1:-1], lines[-1]
        shuffled = [begin] + list(reversed(body)) + [end]
        self.convert([ev_start(1, "đảo")] + [ev_print(1, x) for x in shuffled] + [ev_done(1)])
        self.assertEqual(self.attachment_bytes(self.results()["đảo"]["attachments"][0]), PNG)

    def test_two_shots_in_one_test_keep_order(self):
        events = [ev_start(1, "hai ảnh")]
        events += [ev_print(1, x) for x in shot_lines("a", b"AAAA") + shot_lines("b", b"BBBB")]
        events.append(ev_done(1))
        self.convert(events)
        atts = self.results()["hai ảnh"]["attachments"]
        self.assertEqual([a["name"] for a in atts], ["a", "b"])
        self.assertEqual([self.attachment_bytes(a) for a in atts], [b"AAAA", b"BBBB"])

    def test_simple_single_line_shot_format(self):
        events = [ev_start(1, "một dòng"), ev_print(1, "[[SHOT cuoi]]" + base64.b64encode(PNG).decode()),
                  ev_done(1)]
        self.convert(events)
        self.assertEqual(self.attachment_bytes(self.results()["một dòng"]["attachments"][0]), PNG)

    def test_multiline_print_message_is_split(self):
        msg = "\n".join(shot_lines("gop", PNG))
        self.convert([ev_start(1, "gộp"), ev_print(1, msg), ev_done(1)])
        self.assertEqual(self.attachment_bytes(self.results()["gộp"]["attachments"][0]), PNG)

    def test_truncated_screenshot_is_not_attached(self):
        lines = shot_lines("hong", PNG)
        del lines[2:4]  # mất đoạn giữa và dòng END
        events = [ev_start(1, "mất đoạn")] + [ev_print(1, x) for x in lines] + [ev_done(1)]
        self.convert(events)
        self.assertEqual(self.results()["mất đoạn"]["attachments"], [])

    def test_interleaved_tests_keep_their_own_shots(self):
        events = [ev_start(1, "a"), ev_start(2, "b")]
        events += [ev_print(1, x) for x in shot_lines("sa", b"AAA")]
        events += [ev_print(2, x) for x in shot_lines("sb", b"BBB")]
        events += [ev_done(1), ev_done(2)]
        self.convert(events)
        res = self.results()
        self.assertEqual([x["name"] for x in res["a"]["attachments"]], ["sa"])
        self.assertEqual([x["name"] for x in res["b"]["attachments"]], ["sb"])

    def test_non_json_lines_are_ignored(self):
        self.convert(fixture_events(), extra_lines=["Running Gradle task 'assembleDebug'...", "{bad json"])
        self.assertEqual(len(self.results()), 4)

    def test_uuids_unique_and_history_id_stable(self):
        self.convert(fixture_events())
        first = self.results()
        ids = [r["uuid"] for r in first.values()]
        self.assertEqual(len(set(ids)), len(ids))
        hist = {n: r["historyId"] for n, r in first.items()}
        self.convert(fixture_events())
        self.assertEqual({n: r["historyId"] for n, r in self.results().items()}, hist)


class CliTest(unittest.TestCase):
    def test_exit_0_even_with_failed_cases(self):
        with tempfile.TemporaryDirectory() as tmp:
            src, out = os.path.join(tmp, "r.json"), os.path.join(tmp, "out")
            write_events(src, fixture_events())
            p = subprocess.run([sys.executable, SCRIPT, src, out], capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertEqual(len(glob.glob(os.path.join(out, "*-result.json"))), 4)
            self.assertEqual(len(glob.glob(os.path.join(out, "*-attachment.png"))), 1)
            self.assertNotIn(chunks(PNG)[0][:40], p.stdout + p.stderr)  # không in nội dung ảnh

    def test_exit_2_when_input_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = subprocess.run([sys.executable, SCRIPT, os.path.join(tmp, "none.json"), os.path.join(tmp, "o")],
                               capture_output=True, text=True)
            self.assertEqual(p.returncode, 2)


if __name__ == "__main__":
    unittest.main()
