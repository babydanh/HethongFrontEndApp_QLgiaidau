@AGENTS.md

# Claude Code (bổ sung cho AGENTS.md)

- Việc mới làm trong worktree riêng: `git-wt switch -c <việc> --base origin/main --no-cd -y` (skill `git-worktree-lanes`). Không `checkout`/`switch` trong thư mục repo chính.
- Plan và thay đổi: OpenSpec `openspec/changes/<id>/`, dừng chờ người dùng nói apply. Repo này KHÔNG dùng `workflow/harness/new-change.ps1` hay `changes/<id>/` trong `CLAUDE.md` cấp `Project_QuanLyGiaiDau/`.
- E2E chạy trên cloud (`cloud-test-runner.py`), không chạy E2E trên máy. Test ở máy chỉ cho file liên quan (`flutter test --no-pub <file>`, lệnh trong AGENTS.md).
- Gộp qua `merge-lane.py`. Repo App KHÔNG có deploy production: push `main` chỉ đưa code lên GitHub (CI chạy analyze/test), không deploy gì. Nên sau khi cổng đạt (`--check` exit 0) thì chạy luôn `--push`, không cần hỏi người dùng. Không tự chạy deploy iOS (chỉ `workflow_dispatch` bằng tay). Luật "push `main` = deploy production" chỉ áp cho Web/Backend.
- Không đọc, không chép `.env*`, secret, credential (đã chặn trong `.claude/settings.json`).
