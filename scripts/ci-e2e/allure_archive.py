"""Lưu báo cáo Allure E2E vào GitHub Releases của repo kho PRIVATE, kèm mục lục `index.json` + `README.md`.

  python allure_archive.py history --project qlgd-web-e2e --dest <allure-results>
  python allure_archive.py publish --project qlgd-web-e2e --report <allure-report> [--playwright-report DIR ...]
                                   --run-id .. --run-url .. --branch .. --commit ..
  python allure_archive.py stage   --run-id .. --shard N --results <allure-results> [--playwright-report DIR]
  python allure_archive.py collect --run-id .. --dest <thư mục>
  python allure_archive.py drop-draft --run-id ..

Report, ảnh, video, trace chỉ đi vào repo kho (`--repo`, mặc định
sporto-asia/qlgd-e2e-archive) sau khi đã kiểm repo đó private. Log chỉ in tên tag, link release và số test.
Lượt nhiều shard: mỗi shard `stage` kết quả thô vào release NHÁP `tmp-<run_id>`, job gộp `collect`, `publish`,
rồi `drop-draft` xoá đúng các bản nháp `tmp-<run_id>` của lượt đó.
Cần `gh` đăng nhập bằng GH_TOKEN có quyền ghi repo kho.
"""
import argparse
import base64
import datetime as dt
import glob
import json
import os
import re
import subprocess
import sys
import tempfile
import zipfile

DEFAULT_REPO = "sporto-asia/qlgd-e2e-archive"
PART_LIMIT = int(1.9 * 1024 ** 3)  # GitHub: mỗi asset < 2 GiB
VN_TZ = dt.timezone(dt.timedelta(hours=7))
STORED_EXT = (".webm", ".png", ".jpg", ".jpeg", ".zip", ".mp4", ".gz")
GIT_AUTH = ["-c", "credential.helper=", "-c", "credential.helper=!gh auth git-credential"]
VIEW_HINT = r"python C:\Users\GIGABYTE\.omp\scripts\cloud-test-runner.py xem <run_id|last>"


class ArchiveError(Exception):
    pass


# ---------- đọc report ----------

def spec_of(case, spec_root):
    """fullName của allure-playwright: `<file so với testDir> › describe › test`."""
    first = (case.get("fullName") or "").split(" › ")[0]
    if not first.endswith(".ts") and not first.endswith(".js"):
        return ""
    return first if first.startswith(spec_root.rstrip("/") + "/") else f"{spec_root.rstrip('/')}/{first}"


def summarize(report_dir, spec_root="test/e2e"):
    """Số test theo trạng thái của LẦN CHẠY CUỐI mỗi test (lần retry trước đó Allure đánh dấu hidden)."""
    cases = []
    for f in sorted(glob.glob(os.path.join(report_dir, "data", "test-cases", "*.json"))):
        with open(f, encoding="utf-8") as fh:
            case = json.load(fh)
        if not case.get("hidden"):
            cases.append(case)
    counts = {k: 0 for k in ("passed", "failed", "broken", "skipped")}
    flaky = 0
    failed_tests = []
    for c in cases:
        status = c.get("status")
        if status in counts:
            counts[status] += 1
        if c.get("flaky") or (status == "passed" and (c.get("retriesCount") or 0) > 0):
            flaky += 1
        if status in ("failed", "broken"):
            failed_tests.append({"name": c.get("name") or "", "spec": spec_of(c, spec_root)})
    failed_tests.sort(key=lambda t: (t["spec"], t["name"]))
    duration = 0
    widget = os.path.join(report_dir, "widgets", "summary.json")
    if os.path.exists(widget):
        with open(widget, encoding="utf-8") as fh:
            duration = int(((json.load(fh).get("time") or {}).get("duration")) or 0)
    return {"total": len(cases), **counts, "flaky": flaky, "duration_ms": duration, "failed_tests": failed_tests}


def make_tag(project, run_id, now):
    return f"{project}-{now.astimezone(dt.timezone.utc):%Y%m%d-%H%M}-{run_id}"


def tag_pattern(project):
    return re.compile(rf"^{re.escape(project)}-\d{{8}}-\d{{4}}-\d+$")


# ---------- đóng gói ----------

def zip_dirs(dest_zip, sources):
    """Nén các thư mục `sources` = [(thư mục, tiền tố trong zip)] vào `dest_zip`. Video/ảnh đã nén sẵn thì chỉ chứa."""
    with zipfile.ZipFile(dest_zip, "w", zipfile.ZIP_DEFLATED, allowZip64=True) as zf:
        for src, prefix in sources:
            for root, _, names in os.walk(src):
                for name in sorted(names):
                    path = os.path.join(root, name)
                    arc = os.path.join(prefix, os.path.relpath(path, src)).replace("\\", "/")
                    kind = zipfile.ZIP_STORED if name.lower().endswith(STORED_EXT) else zipfile.ZIP_DEFLATED
                    zf.write(path, arc, compress_type=kind)
    return dest_zip


def split_file(path, limit=PART_LIMIT):
    """File > limit chia thành `<file>.001`, `.002`… (ghép lại bằng cách nối theo thứ tự). Trả danh sách file."""
    size = os.path.getsize(path)
    if size <= limit:
        return [path]
    parts = []
    with open(path, "rb") as src:
        i = 0
        while True:
            i += 1
            part = f"{path}.{i:03d}"
            written = 0
            with open(part, "wb") as out:
                while written < limit:
                    chunk = src.read(min(8 * 1024 * 1024, limit - written))
                    if not chunk:
                        break
                    out.write(chunk)
                    written += len(chunk)
            if written == 0:
                os.remove(part)
                break
            parts.append(part)
            if written < limit:
                break
    os.remove(path)
    return parts


def join_parts(parts, dest):
    with open(dest, "wb") as out:
        for p in sorted(parts):
            with open(p, "rb") as src:
                while chunk := src.read(8 * 1024 * 1024):
                    out.write(chunk)
    return dest


# ---------- mục lục ----------

def merge_index(index, entry):
    """Thêm `entry`, bỏ bản cũ cùng project + run_id (chạy lại cùng run), mới nhất lên đầu."""
    kept = [e for e in index if not (e.get("run_id") == entry["run_id"] and e.get("project") == entry["project"])]
    return sorted(kept + [entry], key=lambda e: e.get("created_at") or "", reverse=True)


def fmt_duration(ms):
    s = int(round((ms or 0) / 1000))
    h, rem = divmod(s, 3600)
    m, s = divmod(rem, 60)
    return f"{h}h{m:02d}m{s:02d}s" if h else f"{m}m{s:02d}s"


def fmt_vn(created_at):
    t = dt.datetime.strptime(created_at, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)
    return t.astimezone(VN_TZ).strftime("%Y-%m-%d %H:%M")


def cell(text):
    return str(text).replace("|", "\\|").replace("\n", " ")


def render_readme(index):
    lines = [
        "# Kho Allure E2E",
        "",
        "Repo PRIVATE: mỗi lượt E2E trên CI là một release (dashboard Allure + video/ảnh/trace của mọi test,",
        "`history.zip` cho biểu đồ xu hướng, `summary.json`). File này và `index.json` do",
        "`allure_archive.py` (CI `cloud-test.yml` của repo Web/App) tự sinh, không sửa tay.",
        "",
        f"Xem một lượt: `{VIEW_HINT}`",
    ]
    for project in sorted({e["project"] for e in index}):
        lines += ["", f"## {project}", "",
                  "| Ngày giờ (giờ VN) | Nhánh @ commit | Đạt/Hỏng/Chập chờn/Tổng | Thời gian | Release | Run |",
                  "|---|---|---|---|---|---|"]
        for e in (x for x in index if x["project"] == project):
            bad = e.get("failed", 0) + e.get("broken", 0)
            lines.append(
                f"| {fmt_vn(e['created_at'])} | {cell(e.get('branch', ''))} @ {cell(e.get('commit', ''))} "
                f"| {e.get('passed', 0)}/{bad}/{e.get('flaky', 0)}/{e.get('total', 0)} | {fmt_duration(e.get('duration_ms'))} "
                f"| [{e['tag']}]({e['release_url']}) | [{e['run_id']}]({e['run_url']}) |")
    return "\n".join(lines) + "\n"


def release_notes(entry):
    bad = entry["failed"] + entry["broken"]
    lines = [
        f"**{entry['project']}** · nhánh `{entry['branch']}` @ `{entry['commit']}` · run {entry['run_url']}",
        "",
        f"Đạt {entry['passed']} · Hỏng {bad} (failed {entry['failed']}, broken {entry['broken']}) · "
        f"Chập chờn {entry['flaky']} · Bỏ qua {entry['skipped']} · Tổng {entry['total']} · {fmt_duration(entry['duration_ms'])}",
    ]
    if entry["failed_tests"]:
        lines += ["", "Test hỏng:"] + [f"- `{t['spec'] or '?'}`: {t['name']}" for t in entry["failed_tests"]]
    lines += ["", "Xem: tải `allure-report.zip` (các phần `.001`, `.002`… thì nối theo thứ tự), giải nén, "
                  "`npx allure-commandline open allure-report`. Trace Playwright: `playwright-report.zip`."]
    return "\n".join(lines) + "\n"


# ---------- git / gh ----------

def run(cmd, cwd=None, check=True):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8")
    if check and r.returncode != 0:
        raise ArchiveError(f"{' '.join(cmd[:3])} lỗi (exit {r.returncode}): {r.stderr.strip()[-500:]}")
    return r


def git(args, cwd, check=True):
    return run(["git", *GIT_AUTH, *args], cwd=cwd, check=check)


def git_push(cwd):
    """Trả True nếu push được, False nếu bị từ chối (lượt khác vừa ghi)."""
    return git(["push", "-q", "origin", "HEAD"], cwd, check=False).returncode == 0


def update_index(remote, entry, attempts=5):
    """Clone nông repo kho, gộp `entry` vào index.json, sinh README.md, commit, push. Bị từ chối thì làm lại từ bản
    mới nhất của remote (hai lượt cùng sửa hai file này nên rebase luôn xung đột; sinh lại từ index mới là đúng)."""
    for attempt in range(1, attempts + 1):
        with tempfile.TemporaryDirectory() as tmp:
            repo_dir = os.path.join(tmp, "repo")
            git(["clone", "-q", "--depth", "1", remote, repo_dir], tmp)
            path = os.path.join(repo_dir, "index.json")
            index = []
            if os.path.exists(path):
                with open(path, encoding="utf-8") as fh:
                    index = json.load(fh)
            index = merge_index(index, entry)
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(index, fh, ensure_ascii=False, indent=2)
                fh.write("\n")
            with open(os.path.join(repo_dir, "README.md"), "w", encoding="utf-8") as fh:
                fh.write(render_readme(index))
            git(["add", "index.json", "README.md"], repo_dir)
            git(["-c", "user.name=e2e-archive-bot", "-c", "user.email=e2e-archive-bot@users.noreply.github.com",
                 "commit", "-q", "-m", f"mục lục: {entry['tag']}"], repo_dir)
            if git_push(repo_dir):
                return attempt
            print(f"push mục lục bị từ chối (lần {attempt}/{attempts}), lấy bản mới rồi thử lại")
    raise ArchiveError(f"không push được mục lục sau {attempts} lần")


def gh_api(path, method="GET", fields=None, check=True):
    cmd = ["gh", "api", "-X", method, path]
    for k, v in (fields or {}).items():
        cmd += ["-F" if isinstance(v, bool) else "-f", f"{k}={str(v).lower() if isinstance(v, bool) else v}"]
    r = run(cmd, check=check)
    return json.loads(r.stdout) if r.returncode == 0 and r.stdout.strip() else None


def ensure_repo(repo):
    """Repo kho phải tồn tại, PRIVATE và có ít nhất một commit (release cần commit để gắn tag)."""
    r = run(["gh", "api", f"repos/{repo}"], check=False)
    if r.returncode != 0:
        if "Not Found" not in r.stdout + r.stderr:
            raise ArchiveError(f"không đọc được repo kho {repo}: {r.stderr.strip()[-300:]}")
        print(f"repo kho {repo} chưa có, tạo PRIVATE")
        run(["gh", "repo", "create", repo, "--private", "--add-readme",
             "--description", "Kho Allure E2E (private): report, video, trace mọi lượt CI"])
        r = run(["gh", "api", f"repos/{repo}"])
    info = json.loads(r.stdout)
    if not info.get("private"):
        raise ArchiveError(f"từ chối: repo kho {repo} KHÔNG private, không tải report lên")
    if run(["gh", "api", f"repos/{repo}/commits?per_page=1"], check=False).returncode != 0:
        gh_api(f"repos/{repo}/contents/README.md", "PUT",
               {"message": "khởi tạo kho", "content": base64.b64encode(b"# Kho Allure E2E\n").decode()})
    return info


def releases(repo, pages=3):
    out = []
    for page in range(1, pages + 1):
        batch = gh_api(f"repos/{repo}/releases?per_page=100&page={page}") or []
        out += batch
        if len(batch) < 100:
            break
    return out


def download_asset(repo, asset, dest):
    with open(dest, "wb") as fh:
        r = subprocess.run(["gh", "api", "-H", "Accept: application/octet-stream",
                            f"repos/{repo}/releases/assets/{asset['id']}"], stdout=fh, stderr=subprocess.PIPE)
    if r.returncode != 0:
        raise ArchiveError(f"tải {asset['name']} lỗi: {r.stderr.decode(errors='replace').strip()[-300:]}")
    return dest


def upload_asset(repo, release_id, path):
    name = os.path.basename(path)
    r = run(["gh", "api", "-X", "POST", "-H", "Content-Type: application/octet-stream", "--input", path,
             f"https://uploads.github.com/repos/{repo}/releases/{release_id}/assets?name={name}"], check=False)
    if r.returncode != 0:
        raise ArchiveError(f"tải lên {name} lỗi: {r.stderr.strip()[-300:]}")


def drafts_of(repo, run_id):
    return [r for r in releases(repo) if r.get("draft") and r.get("tag_name") == f"tmp-{run_id}"]


# ---------- lệnh ----------

def cmd_history(a):
    pattern = tag_pattern(a.project)
    r = run(["gh", "api", f"repos/{a.repo}"], check=False)
    if r.returncode != 0:
        print(f"chưa đọc được repo kho {a.repo}, bỏ qua history")
        return 0
    cands = [x for x in releases(a.repo, pages=2)
             if not x.get("draft") and pattern.match(x.get("tag_name", ""))
             and any(asset["name"] == "history.zip" for asset in x.get("assets", []))]
    if not cands:
        print(f"chưa có release nào của {a.project}, bỏ qua history")
        return 0
    latest = max(cands, key=lambda x: x.get("created_at") or "")
    asset = next(x for x in latest["assets"] if x["name"] == "history.zip")
    with tempfile.TemporaryDirectory() as tmp:
        zpath = download_asset(a.repo, asset, os.path.join(tmp, "history.zip"))
        os.makedirs(a.dest, exist_ok=True)
        with zipfile.ZipFile(zpath) as zf:
            zf.extractall(a.dest)  # zip chứa thư mục history/
    print(f"history: lấy từ {latest['tag_name']} vào {os.path.join(a.dest, 'history')}")
    return 0


def write_output(key, value):
    path = os.environ.get("GITHUB_OUTPUT")
    if path:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(f"{key}={value}\n")


def step_summary(text):
    """Tóm tắt của job (public): chỉ số test, tên tag, link release, không nội dung report."""
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(text + "\n")


def cmd_publish(a):
    now = dt.datetime.now(dt.timezone.utc).replace(microsecond=0) if not a.now else \
        dt.datetime.strptime(a.now, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)
    stats = summarize(a.report, a.spec_root)
    bad = stats["failed"] + stats["broken"]
    # In số trước: lưu kho lỗi thì log vẫn có kết quả test.
    counts = f"đạt {stats['passed']}, hỏng {bad}, chập chờn {stats['flaky']}, tổng {stats['total']}"
    print(f"E2E {a.project}: {counts}")
    step_summary(f"**E2E {a.project}**: {counts}")
    if not os.path.isdir(a.report) or stats["total"] == 0:
        raise ArchiveError(f"report {a.report} rỗng, không lưu kho")
    tag = make_tag(a.project, a.run_id, now)
    release_url = f"https://github.com/{a.repo}/releases/tag/{tag}"
    with tempfile.TemporaryDirectory() as tmp:
        report_parts = split_file(zip_dirs(os.path.join(tmp, "allure-report.zip"), [(a.report, "allure-report")]),
                                  a.part_limit)
        files = list(report_parts)
        history = os.path.join(a.report, "history")
        if os.path.isdir(history):
            files.append(zip_dirs(os.path.join(tmp, "history.zip"), [(history, "history")]))
        pw_dirs = [d for d in (a.playwright_report or []) if os.path.isdir(d)]
        if pw_dirs:
            # Nhiều shard (shards/shard-N/playwright-report): mỗi shard một thư mục con có index.html riêng.
            sources = [(pw_dirs[0], "playwright-report")] if len(pw_dirs) == 1 else \
                [(d, f"playwright-report/{os.path.basename(os.path.dirname(os.path.abspath(d)))}") for d in pw_dirs]
            files += split_file(zip_dirs(os.path.join(tmp, "playwright-report.zip"), sources), a.part_limit)
        entry = {
            "project": a.project, "tag": tag, "run_id": int(a.run_id), "run_url": a.run_url,
            "release_url": release_url, "created_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "branch": a.branch, "commit": a.commit[:7],
            "total": stats["total"], "passed": stats["passed"], "failed": stats["failed"], "broken": stats["broken"],
            "skipped": stats["skipped"], "flaky": stats["flaky"], "duration_ms": stats["duration_ms"],
            "report_assets": [os.path.basename(p) for p in report_parts],
            "failed_tests": stats["failed_tests"],
        }
        summary = os.path.join(tmp, "summary.json")
        with open(summary, "w", encoding="utf-8") as fh:
            json.dump(entry, fh, ensure_ascii=False, indent=2)
        files.append(summary)
        notes = os.path.join(tmp, "notes.md")
        with open(notes, "w", encoding="utf-8") as fh:
            fh.write(release_notes(entry))
        ensure_repo(a.repo)
        run(["gh", "release", "create", tag, "-R", a.repo, "--title", tag, "--notes-file", notes, *files])
        size = sum(os.path.getsize(f) for f in files)
    print(f"Lưu kho: {tag} ({size / 1024 ** 2:.1f} MB) {release_url}")
    step_summary(f"Lưu kho: [{tag}]({release_url}) (repo private, {size / 1024 ** 2:.1f} MB)")
    write_output("release_url", release_url)
    write_output("tag", tag)
    update_index(a.index_remote or f"https://github.com/{a.repo}.git", entry)
    print("Mục lục: đã cập nhật index.json + README.md")
    return 0


def cmd_stage(a):
    if not os.path.isdir(a.results):
        raise ArchiveError(f"không có {a.results}, shard này không có kết quả để gộp")
    ensure_repo(a.repo)
    found = drafts_of(a.repo, a.run_id)
    if found:
        rel = found[0]
    else:
        rel = gh_api(f"repos/{a.repo}/releases", "POST",
                     {"tag_name": f"tmp-{a.run_id}", "name": f"tmp-{a.run_id} (nháp, xoá sau khi gộp)", "draft": True,
                      "body": f"Kết quả thô các shard của run {a.run_id}; job gộp xoá bản nháp này."})
    existing = {x["name"]: x["id"] for x in rel.get("assets", [])}
    with tempfile.TemporaryDirectory() as tmp:
        files = split_file(zip_dirs(os.path.join(tmp, f"shard-{a.shard}-allure-results.zip"),
                                    [(a.results, "allure-results")]), a.part_limit)
        if a.playwright_report and os.path.isdir(a.playwright_report):
            files += split_file(zip_dirs(os.path.join(tmp, f"shard-{a.shard}-playwright-report.zip"),
                                         [(a.playwright_report, "playwright-report")]), a.part_limit)
        for f in files:
            name = os.path.basename(f)
            if name in existing:  # chạy lại cùng run: thay bản cũ
                gh_api(f"repos/{a.repo}/releases/assets/{existing[name]}", "DELETE")
            upload_asset(a.repo, rel["id"], f)
    print(f"shard {a.shard}: đã đẩy {len(files)} file vào release nháp tmp-{a.run_id}")
    return 0


def cmd_collect(a):
    found = drafts_of(a.repo, a.run_id)
    assets = [x for rel in found for x in rel.get("assets", [])]
    if not assets:
        raise ArchiveError(f"release nháp tmp-{a.run_id} không có kết quả shard nào")
    groups = {}
    for asset in assets:
        m = re.match(r"^(shard-(\d+)-(allure-results|playwright-report)\.zip)(\.\d{3})?$", asset["name"])
        if m:
            groups.setdefault(m.group(1), []).append(asset)
    with tempfile.TemporaryDirectory() as tmp:
        for zname, parts in sorted(groups.items()):
            shard, kind = re.match(r"^shard-(\d+)-(.+)\.zip$", zname).groups()
            paths = [download_asset(a.repo, p, os.path.join(tmp, p["name"])) for p in parts]
            zpath = paths[0] if len(paths) == 1 and paths[0].endswith(".zip") else \
                join_parts(paths, os.path.join(tmp, zname))
            with zipfile.ZipFile(zpath) as zf:
                zf.extractall(os.path.join(a.dest, f"shard-{shard}"))
    print(f"gộp: {len({z.split('-')[1] for z in groups})} shard từ release nháp tmp-{a.run_id}")
    return 0


def cmd_drop_draft(a):
    found = drafts_of(a.repo, a.run_id)
    for rel in found:
        gh_api(f"repos/{a.repo}/releases/{rel['id']}", "DELETE")
    print(f"đã xoá {len(found)} release nháp tmp-{a.run_id}")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=DEFAULT_REPO)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("history")
    p.add_argument("--project", required=True)
    p.add_argument("--dest", required=True)
    p.set_defaults(fn=cmd_history)

    p = sub.add_parser("publish")
    p.add_argument("--project", required=True)
    p.add_argument("--report", required=True)
    p.add_argument("--playwright-report", action="append")
    p.add_argument("--run-id", required=True)
    p.add_argument("--run-url", required=True)
    p.add_argument("--branch", required=True)
    p.add_argument("--commit", required=True)
    p.add_argument("--spec-root", default="test/e2e")
    p.add_argument("--now", help=argparse.SUPPRESS)
    p.add_argument("--part-limit", type=int, default=PART_LIMIT, help=argparse.SUPPRESS)
    p.add_argument("--index-remote", help=argparse.SUPPRESS)  # test: remote git cục bộ thay cho GitHub
    p.set_defaults(fn=cmd_publish)

    p = sub.add_parser("stage")
    p.add_argument("--run-id", required=True)
    p.add_argument("--shard", required=True)
    p.add_argument("--results", required=True)
    p.add_argument("--playwright-report")
    p.add_argument("--part-limit", type=int, default=PART_LIMIT, help=argparse.SUPPRESS)
    p.set_defaults(fn=cmd_stage)

    p = sub.add_parser("collect")
    p.add_argument("--run-id", required=True)
    p.add_argument("--dest", required=True)
    p.set_defaults(fn=cmd_collect)

    p = sub.add_parser("drop-draft")
    p.add_argument("--run-id", required=True)
    p.set_defaults(fn=cmd_drop_draft)

    a = ap.parse_args(argv)
    try:
        return a.fn(a)
    except ArchiveError as e:
        print(f"::warning::Lưu kho Allure lỗi ({a.cmd}): {e}")
        step_summary(f"⚠️ Lưu kho Allure lỗi ({a.cmd}), xem log bước này")
        return 1


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    sys.exit(main())
