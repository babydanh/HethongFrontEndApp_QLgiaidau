# Handoff: E2E nhiều tài khoản cho mọi module App + Allure
<!-- Đọc file này TRƯỚC khi làm tiếp nhánh. Cập nhật TRƯỚC khi báo xong, fast-handoff, hoặc hết phiên. -->
Cập nhật: 2026-11-14 · bởi: claude · nhánh: app-e2e-nhieu-tai-khoan · OpenSpec: app-e2e-nhieu-tai-khoan

## Mục tiêu
Người dùng đã duyệt plan và nói làm A-Z (coi như đã "apply"): làm hết `tasks.md` từ 0.1 tới 3.3. Kết quả: 8 file `integration_test/multi_*` chạy xanh trên cloud (trừ ca `skip: 'BUG-...'`), E2E App có báo cáo Allure lưu ở kho private, danh sách lỗi sản phẩm ghi ở `design.md`. Chi tiết: `proposal.md`, `design.md`, `tasks.md` cùng thư mục.

## Trạng thái
- Xong: plan OpenSpec (proposal, design, spec, tasks) đã `openspec validate --strict`.
- Đang dở: chưa viết code nào.
- Tiếp theo:
  1. Nhóm 0 (Allure, repo `babydanh/agent-orchestrator`) và nhóm 1 (hợp đồng chung, repo App) độc lập, làm song song được.
  2. Sau 1.2: 8 chuỗi 2.1–2.8 chạy song song (subagent, mỗi chuỗi một worktree con từ nhánh này).
  3. Nhóm 3: gộp, cập nhật tài liệu, chạy lại 8 file trên cloud.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Kiểm job `test-app-e2e` có Allure không | Không có | Job chỉ chạy `flutter test --reporter expanded ... | tee app-e2e-report/flutter-test.log`; job Web dùng `scripts/e2e/allure_archive.py publish --project qlgd-web-e2e` với `GH_TOKEN: ${{ secrets.GH_PAT }}` (test-runner.yml ~dòng 440–540), làm theo đó |

## Ràng buộc đang có
- Repo orchestrator **public**: KHÔNG thêm `upload-artifact` cho Allure, ảnh, `flutter-test.json` (có base64 ảnh). Allure chỉ vào kho private `babydanh/qlgd-e2e-archive`. (nguồn: người dùng, skill cloud-test-runner)
- Không in, không chép mật khẩu `kE2ePassword` trong `integration_test/support/backend_api.dart` ra log, PR, commit message. Không đưa secret/PII vào test. (nguồn: người dùng)
- Change này chỉ viết test + Allure, KHÔNG sửa code sản phẩm trong `lib/`. Ca đỏ vì lỗi app: giữ `expect`, đánh dấu `skip: 'BUG-<id>: ...'`, ghi vào bảng Phát hiện. Không bọc `if (finder.evaluate().isNotEmpty)` cho xanh giả. (nguồn: spec)
- Không sửa 4 file `organizer_*_journey_test.dart`. Không thêm package. (nguồn: proposal)
- E2E chỉ chạy trên GitHub Actions (`cloud-test-runner.py run --target app-e2e --app-ref <nhánh đã push> --specs integration_test/<file>`), không chạy emulator trên máy. Tối đa 3 vòng sửa cho cùng một lỗi rồi dừng, ghi lại. (nguồn: luật dự án)
- Nếu máy không có `~/.omp/scripts/cloud-test-runner.py` hoặc token dispatch: dùng `gh workflow run test-runner.yml -R babydanh/agent-orchestrator --ref <ref> -f ...` theo input của workflow, và `gh run watch`/`gh run view --log` để đọc kết quả.
- Commit hẹp (`git add <file>`), không `git add -A`, không `Co-Authored-By`. Không đụng file generated (`linux/`, `macos/`, `windows/` plugin registrant). Push nhánh `cloud/...`, mở PR vào `main` cho repo App; orchestrator cũng qua PR vào `main` (repo đó không deploy, tự gộp được sau khi 0.2 có lượt chạy chứng minh). App không có deploy production: gộp PR App sau khi 3.3 đạt.
- `dart format` chỉ file mình tạo/sửa. `flutter analyze --no-pub <file>` cho từng file mới.

## Ràng buộc thay đổi lần này
- Thêm: nhóm 0 (Allure, được sửa job `test-app-e2e` của orchestrator, trước đây ghi ngoài phạm vi); chuỗi G (khám phá/xem) và H (ma trận quyền API); `integration_test/COVERAGE.md`.
- Bỏ: dòng "không đổi workflow test-runner.yml" ở Out of scope.

## Câu hỏi còn mở
- không. Ngã rẽ thì tự chọn phương án ít rủi ro nhất và ghi vào file này + mô tả PR.
