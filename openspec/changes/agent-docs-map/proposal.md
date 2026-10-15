# Proposal

## Why

Repo App Flutter không có `AGENTS.md` ở gốc và không có chỗ nào nói "muốn biết X thì đọc file nào". Luật làm việc nằm rải rác: `.github/copilot-instructions.md` (chỉ cho animation), `.agents/` (66 file skill dùng chung, không phải luật dự án), 80 file `.md` theo dõi có lẫn kế hoạch cũ (`.hermes/plans/`, `test_docs/`). Session agent phải tự dò, dễ coi kế hoạch cũ là mô tả hệ thống. Chạy thử đo được hai điều cần ghi lại: worktree mới không chạy được `flutter test` (thiếu `.env`, file gitignored mà `pubspec.yaml` khai báo làm asset), và `test/core/utils/elo_tier_test.dart` đang đỏ 9/9 sẵn có trên `origin/main`.

## What Changes

- Thêm `AGENTS.md` ở gốc repo App (≤ 40 dòng): đường đọc trước, lệnh đã chạy thật, quy ước code thật, ranh giới (`.env`, push `main`), trỏ tới `docs/README.md`. Ghi rõ trong repo này OpenSpec thay mục "Change protocol" của `AGENTS.md` cấp dự án.
- Thêm `docs/README.md`: bản đồ "câu hỏi → file" gắn nhãn chuẩn / tham khảo / kế hoạch cũ, phủ 80 file `.md` đang được git theo dõi, kèm bảng lệnh đã chạy thật và kết quả.
- Khởi tạo OpenSpec (`openspec init --tools oh-my-pi --language vi`) với `openspec/config.yaml` có bối cảnh Flutter và luật riêng; giữ nguyên khối `operations` như repo Web.
- Thêm `.omp/mcp.json` khai báo Dart MCP cho riêng repo này (server `dart`).

### Out of scope (KHÔNG làm)

- Không sửa code trong `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock`, CI hay schema; không sửa test đang đỏ `elo_tier_test.dart`.
- Không di chuyển, đổi tên, sửa hay xóa tài liệu và file cũ (`changes/`, `.hermes/`, `test_docs/`, file scratch ở gốc).
- Không tạo `.env`, không copy `.env` từ repo chính.
- Không chạy toàn bộ test và không `flutter analyze` toàn repo trong change này.
- Không áp cho Backend hay Web; không sửa `AGENTS.md` cấp dự án.

## Capabilities

### New Capabilities

(không có: thay đổi chỉ gồm tài liệu cho agent và cấu hình, `skip_specs: true`)

### Modified Capabilities

(không có)

## Impact

- File mới: `AGENTS.md`, `docs/README.md`, `openspec/` (config, thư mục `changes/` và `specs/` với `.gitkeep`), `.omp/` (6 skill và 6 command OpenSpec cho oh-my-pi, cùng `.omp/mcp.json`).
- Agent: mọi session omp mở trong repo App nạp `AGENTS.md`. Dart MCP chỉ xuất hiện khi cwd là repo này (đã đo, xem design.md).
- Repo khác: không ảnh hưởng Backend API hay Web; không đổi endpoint hay field nào.
- Deploy: thay đổi chỉ là tài liệu và cấu hình agent, không nằm trong bản build. `deploy-ios.yml` chỉ có `workflow_dispatch`, nên gộp vào `main` không tự kích hoạt build iOS.
