# Design

## Context

Đo bằng `omp -p --no-session` (hỏi model liệt kê MCP server và tool, cấm gọi tool), 2026-10-15:

- Từ worktree App, `AGENTS.md` ở gốc repo KHÔNG được nạp ban đầu: `.github/copilot-instructions.md` (provider `github`, priority 30) thắng `AGENTS.md` (`agents-md`, priority 10) ở cùng độ sâu (đã kiểm: LOADED thật trong worktree App; thư mục thử có cả hai file chỉ nạp copilot). Khắc phục: `.omp/config.yml` với `disabledExtensions: [context-file:project:copilot-instructions.md]`, loại đúng file đó trước khi dedup (tài liệu omp `context-files.md`, mục "Disabling a single context file"); provider `github` vẫn đóng góp phần khác. Bản đầu dùng `disabledProviders: ["github"]` đã bị thay vì tắt cả provider. Hệ quả: copilot-instructions không còn tự nạp. `D:/Duancanhan/Project_QuanLyGiaiDau/AGENTS.md` cấp dự án không được nạp.
- Dart MCP: session trong worktree (có `.omp/mcp.json`) thấy server `dart` với 23 tool (`mcp__dart_hot_reload`, `mcp__dart_launch_app`, `mcp__dart_widget_inspector`, ...). Session chạy ở thư mục tạm bên ngoài repo chỉ thấy 7 server khác, không có `dart`. Các file JSON cấu hình toàn cục đã kiểm (`~/.omp/agent/*.json`, `~/.omp/*.json`) không có chữ `dart`. Vì vậy Dart MCP đến từ `.omp/mcp.json` của repo này.

Xem proposal.md, mục Why.

## Goals / Non-Goals

**Goals:**
- Một điểm vào ngắn (`AGENTS.md`) và một bản đồ (`docs/README.md`); mỗi loại câu hỏi có đúng một nơi trả lời.
- Chỉ ghi lệnh đã chạy thật và ghi exit code; khoảng trống ghi là khoảng trống.

**Non-Goals:**
- Không viết lại nội dung tài liệu cũ.
- Không thêm script hay công cụ vào repo.

## Decisions

1. **`AGENTS.md` là bảng chỉ đường**: điểm vào ngắn, chi tiết nằm ở tài liệu đích. Không chép luật từ tài liệu khác để tránh tạo nguồn luật thứ hai.
2. **Bản đồ gắn nhãn thay vì di chuyển file**: `chuẩn` / `tham khảo` / `kế hoạch cũ`, cộng nhãn `sự thật` cho code và cấu hình. Không phá link, không đụng file session khác.
3. **Gom theo thư mục cho nhóm lớn**: `.agents/skills/` (66 file) và `.hermes/` được gom một dòng; `test_docs/` tách file kế hoạch khỏi file test case. Thư mục gom không được che file chuẩn: `.agents/skills/flutter-animation/SKILL.md` được nêu riêng.
4. **`.env` không được copy**: worktree mới không có `.env`. Chạy test cần file này thì hỏi người dùng. Lần đo của change này chỉ dùng `.env.example` tạm, rồi xóa.
5. **Dart MCP theo repo**: `.omp/mcp.json` với server `dart` (`--force-roots-fallback`, `--enable cli`, `--enable flutter_app_lifecycle`). Không sửa cấu hình toàn cục.
6. **Ghi đè có phạm vi**: chỉ mục "Change protocol" của `AGENTS.md` cấp dự án được thay bằng OpenSpec; mọi mục khác vẫn áp dụng. File cấp dự án được tham chiếu bằng đường dẫn tuyệt đối, không dùng `../` vì từ worktree `../` trỏ vào thư mục `.worktrees/`.

## Risks / Trade-offs

- **Bản đồ cũ đi khi tài liệu đổi**: `AGENTS.md` yêu cầu sửa `docs/README.md` trong cùng commit khi thêm hay đổi vai trò tài liệu.
- **Nhãn chỉ đúng tại thời điểm viết**: không có công cụ kiểm nội dung văn xuôi, nên nhãn "chuẩn" không chứng minh tài liệu đúng 100%.
- **Test đang đỏ sẵn**: `elo_tier_test.dart` đỏ 9/9 trên `origin/main`. Change này không sửa test; kết quả được ghi là lỗi có sẵn, không ghi là xanh.
- **Lock file lệch**: `flutter pub get` trên worktree mới đổi 7 phiên bản trong `pubspec.lock` đã commit. Change này không commit thay đổi đó.
- **Hiệu quả với agent chưa được chứng minh bằng lý thuyết**: kiểm bằng session omp sạch (`omp -p --no-session`) hỏi các câu điển hình và đối chiếu file agent chọn đọc.
