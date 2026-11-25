import datetime as dt
import json
import os
import stat
import subprocess
import sys
import tempfile
import textwrap
import unittest
import zipfile
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import allure_archive as aa  # noqa: E402

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "allure_archive.py")
GIT_ENV = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"}


def write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh)


def make_report(root, cases, duration=126000):
    """Report Allure tối thiểu: data/test-cases/*.json, một video mỗi test, widgets/summary.json, history/."""
    os.makedirs(os.path.join(root, "data", "attachments"))
    for i, c in enumerate(cases):
        write_json(os.path.join(root, "data", "test-cases", f"{i}.json"), c)
        with open(os.path.join(root, "data", "attachments", f"{i}.webm"), "wb") as fh:
            fh.write(os.urandom(64))
    write_json(os.path.join(root, "widgets", "summary.json"), {"time": {"duration": duration}})
    write_json(os.path.join(root, "history", "history-trend.json"), [{"data": {"passed": 1}}])
    return root


def case(name, status, spec="a.spec.ts", **extra):
    return {"name": name, "status": status, "fullName": f"{spec} › suite › {name}", **extra}


def entry(project, run_id, created_at, **extra):
    tag = f"{project}-x-{run_id}"
    base = {"project": project, "tag": tag, "run_id": run_id, "run_url": f"https://run/{run_id}",
            "release_url": f"https://rel/{tag}", "created_at": created_at, "branch": "main", "commit": "abc1234",
            "total": 3, "passed": 2, "failed": 1, "broken": 0, "skipped": 0, "flaky": 0, "duration_ms": 61000,
            "report_assets": ["allure-report.zip"], "failed_tests": []}
    return base | extra


def git(*args):
    subprocess.run(["git", *args], check=True, capture_output=True, env=os.environ | GIT_ENV)


def init_bare_remote(tmp, hook=None):
    """Remote git cục bộ có sẵn 1 commit (như repo kho tạo bằng --add-readme)."""
    remote = os.path.join(tmp, "remote.git")
    seed = os.path.join(tmp, "seed")
    git("init", "-q", "--bare", "-b", "main", remote)
    git("clone", "-q", remote, seed)
    with open(os.path.join(seed, "README.md"), "w") as fh:
        fh.write("# kho\n")
    git("-C", seed, "add", "README.md")
    git("-C", seed, "commit", "-q", "-m", "init")
    git("-C", seed, "push", "-q", "origin", "HEAD:main")
    if hook:
        path = os.path.join(remote, "hooks", "pre-receive")
        with open(path, "w") as fh:
            fh.write(hook)
        os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)
    return remote


def remote_index(remote, tmp):
    out = os.path.join(tmp, "check")
    git("clone", "-q", remote, out)
    with open(os.path.join(out, "index.json"), encoding="utf-8") as fh:
        index = json.load(fh)
    with open(os.path.join(out, "README.md"), encoding="utf-8") as fh:
        return index, fh.read()


class SummarizeTest(unittest.TestCase):
    def test_dem_lan_chay_cuoi_bo_retry_an_va_tinh_chap_chon(self):
        with tempfile.TemporaryDirectory() as tmp:
            make_report(os.path.join(tmp, "r"), [
                case("dang nhap", "passed"),
                case("tao giai", "passed", retriesCount=1),          # đạt sau khi chạy lại: chập chờn
                case("tao giai", "failed", hidden=True, retry=True),  # lần thử trước, Allure ẩn
                case("xep lich", "failed", spec="p0/lich.spec.ts", retriesCount=2),
                case("xep lich", "failed", spec="p0/lich.spec.ts", hidden=True, retry=True),
                case("api", "broken", spec="test/e2e/api.spec.ts"),
                case("bo qua", "skipped"),
            ])
            s = aa.summarize(os.path.join(tmp, "r"))
        self.assertEqual((s["total"], s["passed"], s["failed"], s["broken"], s["skipped"], s["flaky"]), (5, 2, 1, 1, 1, 1))
        self.assertEqual(s["duration_ms"], 126000)
        self.assertEqual(s["failed_tests"], [{"name": "api", "spec": "test/e2e/api.spec.ts"},
                                             {"name": "xep lich", "spec": "test/e2e/p0/lich.spec.ts"}])

    def test_report_rong(self):
        with tempfile.TemporaryDirectory() as tmp:
            s = aa.summarize(tmp)
        self.assertEqual((s["total"], s["failed_tests"], s["duration_ms"]), (0, [], 0))


class TagTest(unittest.TestCase):
    def test_tag_theo_gio_utc(self):
        vn = dt.datetime(2026, 11, 2, 8, 30, tzinfo=dt.timezone(dt.timedelta(hours=7)))
        tag = aa.make_tag("qlgd-web-e2e", 41300000000, vn)
        self.assertEqual(tag, "qlgd-web-e2e-20261102-0130-41300000000")
        self.assertTrue(aa.tag_pattern("qlgd-web-e2e").match(tag))

    def test_project_khac_cung_tien_to_va_ban_nhap_khong_bi_nhan_nham(self):
        self.assertIsNone(aa.tag_pattern("qlgd-web-e2e").match("qlgd-web-e2e-ui-20261102-0130-1"))
        self.assertIsNone(aa.tag_pattern("qlgd-web-e2e").match("tmp-41300000000"))


class IndexTest(unittest.TestCase):
    def test_trung_run_id_thay_ban_cu_moi_nhat_len_dau(self):
        index = [entry("p", 2, "2026-11-02T01:00:00Z"), entry("p", 1, "2026-11-01T01:00:00Z"),
                 entry("q", 3, "2026-11-01T05:00:00Z")]
        merged = aa.merge_index(index, entry("p", 1, "2026-11-03T01:00:00Z", passed=3, failed=0))
        self.assertEqual([(e["project"], e["run_id"]) for e in merged], [("p", 1), ("p", 2), ("q", 3)])
        self.assertEqual(merged[0]["passed"], 3)

    def test_cung_run_id_khac_project_giu_ca_hai(self):
        merged = aa.merge_index([entry("q", 1, "2026-11-01T01:00:00Z")], entry("p", 1, "2026-11-01T02:00:00Z"))
        self.assertEqual(len(merged), 2)

    def test_readme_nhom_theo_project_moi_nhat_tren_dau_gio_vn(self):
        index = aa.merge_index([], entry("p", 1, "2026-11-01T01:30:00Z"))
        index = aa.merge_index(index, entry("q", 5, "2026-11-01T03:00:00Z"))
        index = aa.merge_index(index, entry("p", 2, "2026-11-02T17:30:00Z", failed=1, broken=2, flaky=1))
        md = aa.render_readme(index)
        p_rows = [l for l in md[md.index("## p"):md.index("## q")].splitlines() if l.startswith("| 20")]
        q_rows = [l for l in md[md.index("## q"):].splitlines() if l.startswith("| 20")]
        self.assertEqual((len(p_rows), len(q_rows)), (2, 1))
        self.assertTrue(p_rows[0].startswith("| 2026-11-03 00:30 |"), p_rows[0])  # 17:30Z = 00:30 hôm sau giờ VN
        self.assertIn("| 2/3/1/3 |", p_rows[0])  # hỏng = failed + broken
        self.assertIn("[2](https://run/2)", p_rows[0])
        self.assertTrue(p_rows[1].startswith("| 2026-11-01 08:30 |"), p_rows[1])
        self.assertIn("cloud-test-runner.py xem", md)


class SplitTest(unittest.TestCase):
    def test_chia_va_ghep_lai_dung_noi_dung(self):
        with tempfile.TemporaryDirectory() as tmp:
            data = os.urandom(2500)
            path = os.path.join(tmp, "allure-report.zip")
            with open(path, "wb") as fh:
                fh.write(data)
            parts = aa.split_file(path, limit=1000)
            self.assertEqual([os.path.basename(p) for p in parts],
                             ["allure-report.zip.001", "allure-report.zip.002", "allure-report.zip.003"])
            self.assertTrue(all(os.path.getsize(p) <= 1000 for p in parts))
            with open(aa.join_parts(parts, os.path.join(tmp, "joined.zip")), "rb") as fh:
                self.assertEqual(fh.read(), data)

    def test_dung_boi_so_cua_gioi_han_khong_sinh_phan_rong(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "x.zip")
            with open(path, "wb") as fh:
                fh.write(b"a" * 2000)
            self.assertEqual(len(aa.split_file(path, limit=1000)), 2)

    def test_file_bang_gioi_han_giu_nguyen(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "x.zip")
            with open(path, "wb") as fh:
                fh.write(b"a" * 1000)
            self.assertEqual(aa.split_file(path, limit=1000), [path])


class UpdateIndexTest(unittest.TestCase):
    def setUp(self):
        patcher = mock.patch.dict(os.environ, GIT_ENV)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_push_bi_tu_choi_mot_lan_thi_thu_lai(self):
        with tempfile.TemporaryDirectory() as tmp:
            marker = os.path.join(tmp, "rejected-once")
            remote = init_bare_remote(tmp, f"#!/bin/sh\n[ -f '{marker}' ] && exit 0\ntouch '{marker}'\nexit 1\n")
            attempts = aa.update_index(remote, entry("p", 7, "2026-11-01T01:00:00Z"))
            index, readme = remote_index(remote, tmp)
        self.assertEqual(attempts, 2)
        self.assertEqual([e["run_id"] for e in index], [7])
        self.assertIn("[7](https://run/7)", readme)

    def test_luot_khac_ghi_chen_giua_chung_khong_mat_dong_nao(self):
        with tempfile.TemporaryDirectory() as tmp:
            remote = init_bare_remote(tmp)
            real_push = aa.git_push
            calls = []

            def push_after_rival(cwd):
                if not calls:  # lượt song song push mục lục của nó ngay trước lượt này
                    calls.append("rival")
                    aa.update_index(remote, entry("p", 8, "2026-11-01T02:00:00Z"))
                calls.append(cwd)
                return real_push(cwd)

            with mock.patch.object(aa, "git_push", side_effect=push_after_rival):
                aa.update_index(remote, entry("p", 9, "2026-11-01T03:00:00Z"))
            index, _ = remote_index(remote, tmp)
        self.assertEqual([e["run_id"] for e in index], [9, 8])

    def test_tu_choi_mai_thi_bao_loi_sau_5_lan(self):
        with tempfile.TemporaryDirectory() as tmp:
            counter = os.path.join(tmp, "count")
            remote = init_bare_remote(tmp, f"#!/bin/sh\necho x >> '{counter}'\nexit 1\n")
            with self.assertRaises(aa.ArchiveError):
                aa.update_index(remote, entry("p", 1, "2026-11-01T01:00:00Z"))
            with open(counter) as fh:
                self.assertEqual(len(fh.readlines()), 5)


FAKE_GH = textwrap.dedent("""\
    #!/usr/bin/env python3
    import json, os, shutil, sys
    args = sys.argv[1:]
    rec = os.environ["FAKE_GH_REC"]
    with open(os.path.join(rec, "calls.txt"), "a") as fh:
        fh.write(" ".join(args) + "\\n")
    if args[:2] == ["release", "create"]:
        out = os.path.join(rec, "release")
        os.makedirs(out, exist_ok=True)
        for a in args:
            if os.path.isfile(a) and not a.endswith("notes.md"):
                shutil.copy(a, out)
    elif args[0] == "api" and args[-1].endswith("/commits?per_page=1"):
        print("[{}]")
    elif args[0] == "api":
        print(json.dumps({"private": os.environ["FAKE_GH_PRIVATE"] == "1"}))
""")


# The fake `gh` is an extension-less POSIX script: Windows cannot run it from PATH and would call the real gh
# (it tried `gh repo create o/kho` against GitHub on 2026-11-25). Run this class on Linux only.
@unittest.skipIf(os.name == "nt", "fake gh is POSIX-only; on Windows the real gh would run")
class PublishCliTest(unittest.TestCase):
    def run_publish(self, tmp, private):
        bindir, rec = os.path.join(tmp, "bin"), os.path.join(tmp, "rec")
        os.makedirs(bindir)
        os.makedirs(rec)
        gh = os.path.join(bindir, "gh")
        with open(gh, "w") as fh:
            fh.write(FAKE_GH)
        os.chmod(gh, 0o755)
        report = make_report(os.path.join(tmp, "allure-report"), [
            case("dang nhap", "passed"), case("tao giai", "passed"), case("xep lich", "failed", spec="p0/lich.spec.ts")])
        pw = os.path.join(tmp, "playwright-report")
        os.makedirs(pw)
        open(os.path.join(pw, "index.html"), "w").close()
        remote = init_bare_remote(tmp)
        out = os.path.join(tmp, "gh-output")
        env = os.environ | GIT_ENV | {"PATH": bindir + os.pathsep + os.environ["PATH"], "FAKE_GH_REC": rec,
                                      "FAKE_GH_PRIVATE": "1" if private else "0", "GITHUB_OUTPUT": out}
        r = subprocess.run([sys.executable, SCRIPT, "--repo", "o/kho", "publish", "--project", "qlgd-web-e2e",
                            "--report", report, "--playwright-report", pw, "--run-id", "41300000000",
                            "--run-url", "https://github.com/o/orch/actions/runs/41300000000", "--branch", "main",
                            "--commit", "e349b86f00", "--now", "2026-11-02T01:30:00Z", "--index-remote", remote],
                           capture_output=True, text=True, encoding="utf-8", env=env)
        return r, rec, remote, out

    def test_publish_tao_release_dung_hop_dong_va_cap_nhat_muc_luc(self):
        with tempfile.TemporaryDirectory() as tmp:
            r, rec, remote, out = self.run_publish(tmp, private=True)
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
            rel = os.path.join(rec, "release")
            self.assertEqual(sorted(os.listdir(rel)),
                             ["allure-report.zip", "history.zip", "playwright-report.zip", "summary.json"])
            with open(os.path.join(rel, "summary.json"), encoding="utf-8") as fh:
                summary = json.load(fh)
            self.assertEqual(summary, {
                "project": "qlgd-web-e2e", "tag": "qlgd-web-e2e-20261102-0130-41300000000", "run_id": 41300000000,
                "run_url": "https://github.com/o/orch/actions/runs/41300000000",
                "release_url": "https://github.com/o/kho/releases/tag/qlgd-web-e2e-20261102-0130-41300000000",
                "created_at": "2026-11-02T01:30:00Z", "branch": "main", "commit": "e349b86",
                "total": 3, "passed": 2, "failed": 1, "broken": 0, "skipped": 0, "flaky": 0, "duration_ms": 126000,
                "report_assets": ["allure-report.zip"],
                "failed_tests": [{"name": "xep lich", "spec": "test/e2e/p0/lich.spec.ts"}]})
            with zipfile.ZipFile(os.path.join(rel, "allure-report.zip")) as zf:
                self.assertEqual(len([n for n in zf.namelist() if n.endswith(".webm")]), 3)
            with zipfile.ZipFile(os.path.join(rel, "history.zip")) as zf:
                self.assertIn("history/history-trend.json", zf.namelist())
            index, readme = remote_index(remote, tmp)
            self.assertEqual(index, [summary])
            self.assertIn("| 2026-11-02 08:30 | main @ e349b86 | 2/1/0/3 |", readme)
            with open(out, encoding="utf-8") as fh:
                self.assertIn(f"release_url={summary['release_url']}", fh.read())
            self.assertNotIn("xep lich", r.stdout)  # log public chỉ có số và link, không tên test

    def test_repo_kho_khong_private_thi_khong_tai_len(self):
        with tempfile.TemporaryDirectory() as tmp:
            r, rec, _, _ = self.run_publish(tmp, private=False)
            self.assertEqual(r.returncode, 1)
            self.assertFalse(os.path.exists(os.path.join(rec, "release")))
            self.assertIn("KHÔNG private", r.stdout)


if __name__ == "__main__":
    unittest.main()
