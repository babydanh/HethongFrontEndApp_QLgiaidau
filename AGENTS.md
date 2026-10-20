# AGENTS.md — App Flutter Quản Lý Giải Đấu

Flutter (Dart ^3.10.3) + Riverpod 3 + go_router 17 + Dio; package `app_quanly_giaidau`.
omp chỉ tự nạp file này (gốc repo) và `AGENTS.md` toàn cục. `D:/Duancanhan/Project_QuanLyGiaiDau/AGENTS.md` cấp dự án KHÔNG tự nạp: mở nó khi việc đụng an toàn dữ liệu, báo cáo cuối, hoặc DB map (mục 11).

## Đọc trước khi làm

1. `docs/README.md`: bản đồ "câu hỏi → file" và nhãn chuẩn / tham khảo / kế hoạch cũ. Đừng tin tài liệu nhãn "kế hoạch cũ".
2. Animation, transition, chuyển động: đọc `.agents/skills/flutter-animation/SKILL.md` và `.github/copilot-instructions.md` trước. File thứ hai KHÔNG tự nạp ở repo này (`.omp/config.yml` tắt đúng file đó để `AGENTS.md` được nạp).
3. Chuỗi hiển thị: `lib/l10n/app_vi.arb` (template) và `app_en.arb`; key phải có ở cả hai, rồi `flutter gen-l10n`. Không sửa tay `lib/l10n/app_localizations*.dart` (code sinh).

## Lệnh (kết quả thật: docs/README.md)

- Test một file: `flutter test --no-pub test/<đường dẫn>_test.dart`. Cần `.env` (xem Ranh giới).
- Phân tích tĩnh chỉ trên thư mục đã sửa: `flutter analyze --no-pub lib/<thư mục>`. Không chạy toàn repo trong lượt thường.
- Bộ test đầy đủ, E2E, test nặng: KHÔNG chạy cục bộ; theo skill `cloud-test-runner` (GitHub Actions).

## Quy ước code thật

- State: Riverpod. `ProviderScope` ở `lib/main.dart`; provider ở `lib/providers/`, wiring ở `lib/core/di/`.
- Route: một `GoRouter` ở `lib/core/router/app_router.dart`.
- Gọi API: `lib/data/repositories/api/api_*.dart` dùng `DioClient` (`lib/core/services/dio_client.dart`), implement interface ở `lib/domain/repositories/`.
- Không thêm package khi không được yêu cầu.
- Skill omp có sẵn: flutter-fix-layout-issues, flutter-add-widget-test, flutter-add-integration-test, dart-fix-runtime-errors, flutter-architect, pixel-perfect-responsive.

## Ranh giới

- `.env` là secret, gitignored: KHÔNG đọc, KHÔNG in, KHÔNG copy từ repo chính. Worktree mới không có `.env`; cần chạy app hoặc test cần file này thì hỏi người dùng.
- Agent chỉ được gộp và push `main` qua `merge-lane.py --push` sau khi các cổng kiểm tra đạt; không push `main` trực tiếp. Deploy iOS/App Store chỉ chạy bằng tay qua `workflow_dispatch` của `.github/workflows/deploy-ios.yml`; push `main` không tự deploy iOS.
- Repo này chưa có workflow test trên GitHub Actions (chỉ `.github/workflows/deploy-ios.yml`).

## Kế hoạch và thay đổi

- OpenSpec (từ 2026-10-15, cùng Web/Backend): thay đổi mới ở `openspec/changes/<id>/` qua `/opsx-propose` → dừng chờ người dùng nói apply → `/opsx-apply` → `/opsx-archive`. KHÔNG tạo `*_PLAN.md` / `*_SPEC.md` ở `docs/` hay thư mục cha.
- Trong repo này OpenSpec thay mục "Change protocol" của `AGENTS.md` cấp dự án; các mục khác vẫn áp dụng.
- Làm trong worktree riêng (skill `git-worktree-lanes`); gộp bằng `merge-lane.py <worktree> --check "python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py"`.
- Thêm hay đổi vai trò một tài liệu: sửa `docs/README.md` trong cùng commit.
