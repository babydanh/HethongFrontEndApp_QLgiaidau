# Proposal

## Why

Run `39122493011` (app ref `b0e41bb6`, orchestrator `886ac23`): ca VĐV đơn gửi đăng ký khi chưa tick "Đồng ý hiển thị kết quả và điểm ELO", và server trả `400` (`POST /tournaments/:id/register`, `flutter-test.log` dòng 92–93). Giải là giải có xếp hạng: form hiện khối đồng ý (`t.isRanked`), backend yêu cầu `rankingConsent === true` cho giải có xếp hạng.

Cổng kiểm tra phía client (`tournament_register_screen.dart`, `_submit`, dòng ~627: `tournament?.isRanked == true && !_rankingConsent` → SnackBar, không gửi) đã không chặn được. Nguyên nhân:

- Form lấy giải từ `registerTournamentProvider((id, invite))` (`build`, dòng ~871).
- `_submit` lấy giải từ `tournamentProvider(id)` bằng `.asData?.value` (dòng ~559–562). Đây là provider khác, và `AsyncValue.asData` trả `null` khi `AsyncLoading`, kể cả khi đã có dữ liệu cũ (Riverpod 3.3.2, `lib/src/core/async_value.dart:132-134`). Khi provider chưa có dữ liệu hoặc đang tải lại, `tournament` là `null`, cổng bị bỏ qua và request đi với `rankingConsent: false`.

Màn đăng ký đôi (`doubles_registration_screen.dart`, dòng ~528–536) có cùng kiểu: đọc giải bằng `.asData?.value` từ đúng provider mà UI dùng, và gửi `rankingConsent: tournament?.isRanked == true` (dòng ~590). Khi provider đang tải lại, payload đôi gửi `rankingConsent: false` cho giải có xếp hạng, cùng nguyên nhân.

Lỗi này cũng làm cổng giới tính theo nội dung (`genderRestriction`, dòng ~586) đọc sai nguồn, cùng nguyên nhân.

## What Changes

- `lib/features/register/screens/tournament_register_screen.dart`, `_submit`: đọc giải bằng đúng provider và key mà `build` dùng (`registerTournamentProvider((id, invite))`), dùng `.value` (giữ dữ liệu cũ khi tải lại). Dùng chung cho cổng đồng ý xếp hạng và cổng giới tính, có chú thích tại chỗ.
- `lib/features/register/screens/doubles_registration_screen.dart`, `_submit`: đổi `.asData?.value` thành `.value` cho cùng provider đang đọc, để `rankingConsent` của payload đôi không về `false` khi giải đang tải lại.
- Hành vi người dùng: khi giải có xếp hạng và chưa tick đồng ý, màn đơn hiện thông báo `registerRankingConsentRequired` và không gửi request. Trước đây request vẫn đi và server từ chối bằng 400.

### Out of scope (KHÔNG làm)

- Không đổi `tournamentForTeam` (`tournament_register_screen.dart`, dòng ~665–668, cũng đọc `tournamentProvider.asData`) và đọc hồ sơ `userAsync.asData?.value` (dòng ~557–558 và ~1633, cổng thiếu họ tên/SĐT/giới tính): cùng kiểu `asData` nhưng chưa có bằng chứng lỗi trong log. Ghi nhận để kiểm tra sau.
- Không đổi `_registrationTeamStatus`/post-success đọc `t` (dòng ~736).
- Không đổi thông điệp, giao diện, hay quy tắc backend.
- Không sửa backend (chỉ đọc để xác nhận quy tắc `rankingConsent`).
