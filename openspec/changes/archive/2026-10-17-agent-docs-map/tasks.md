# Tasks

## 1. Bản đồ, luật agent, Dart MCP

- [x] 1.1 Viết `docs/README.md`: bảng "câu hỏi → file" cho mọi file `.md` đang được git theo dõi, gắn nhãn chuẩn / tham khảo / kế hoạch cũ, gom `.agents/skills/` theo thư mục. Xong khi: script so `git ls-files '*.md'` với bản đồ không còn file thiếu (80/80) và mọi đường dẫn trong bản đồ tồn tại.
- [x] 1.2 Viết `AGENTS.md` ở gốc repo (≤ 40 dòng): đường đọc trước, lệnh, quy ước code thật, ranh giới, trỏ tới `docs/README.md`, phạm vi ghi đè "Change protocol". Xong khi: `wc -l AGENTS.md` ≤ 40 và mọi lệnh trong file có kết quả thật ở task 2.1.
- [x] 1.3 Tạo `.omp/mcp.json` với server `dart` đúng cấu hình đã giao. Xong khi: session omp sạch trong worktree liệt kê server `dart` và tool `mcp__dart_*`; session ở thư mục ngoài repo không có `dart`.

## 2. Kiểm chứng

- [x] 2.1 Chạy từng lệnh ghi trong `AGENTS.md` và `docs/README.md`, ghi exit code thật vào `docs/README.md` mục "Lệnh": `flutter test --no-pub test/core/utils/elo_tier_test.dart`, `flutter analyze --no-pub lib/core/utils`, `flutter gen-l10n`, `openspec validate --all --strict`. Xong khi: mỗi lệnh có kết quả thật; test đỏ sẵn có được ghi là lỗi có sẵn kèm số test fail, không ghi là pass.
- [x] 2.2 Kiểm bằng session omp sạch: `omp -p --no-session` trong worktree với 4 câu hỏi (state/route, thêm chuỗi hiển thị, gọi API Backend, nơi ghi kế hoạch mới). Xong khi: câu trả lời trỏ đúng file theo bản đồ ở 4/4 câu.
- [x] 2.3 Task cuối: chạy `flutter analyze --no-pub lib/core/utils` (thư mục đã sửa) và `flutter test --no-pub test/core/utils/elo_tier_test.dart` (test liên quan), rồi chạy `python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py`. Xong khi: analyze exit 0; test ghi đúng số fail sẵn có; gate chạy xong và kết quả được ghi vào báo cáo.

## Sau khi gộp (không theo dõi bằng checkbox)

- `openspec archive agent-docs-map --skip-specs` sau khi người dùng duyệt kết quả thí điểm.
