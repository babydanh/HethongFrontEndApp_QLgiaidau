# Việc cần làm

- [x] P0 Repository: `searchAddAthleteCandidates`, `addAthletePairs`, `previewRosterImportBatch`, `importRosterBatch` (idempotency key), `addAthleteDirect(email)`.
- [x] P0 Entity: `roster_import.dart`, `AddAthleteSource.email`, `AddAthleteSearchCandidate`, `AddedAthletePair`.
- [x] Tạo artifact change trong repo App (file này).
- [x] P1 Parser: reader, parser (có `notes`), template service, test: 20/20 pass. Chưa có log RED trước code.
- [x] P2 UI: nút Nhập Excel và Tải mẫu, `roster_import_sheet.dart`, tri-state tài khoản, commit chỉ dòng đủ điều kiện, khoá l10n. Chỉ kiểm bằng analyze và tĩnh, chưa chạy trên máy.
- [x] P3 AddAthleteSheet: thêm nhiều tuần tự (theo web), tìm theo email, cặp đôi, khách có email, tự duyệt, nguồn EMAIL, sửa 2 file test. Test 81/81 pass (6 file gộp).
- [x] P4 InteractiveViewer: `constrained: false`, bỏ scroll lồng. Bằng chứng: probe trên bản sao cấu hình. Chưa kiểm trên màn hình thật.
- [x] Test repository: idempotency key ổn định theo nội dung, khác khi nội dung khác; path endpoint mới. 45/45 pass. Chưa có pha RED (implementation có trước test).
- [x] `dart analyze` các file đã sửa: không có lỗi. 1 warning và 2 info đã nêu trong `12-release-evidence.md`.
- [x] Test mới và test liên quan: parser 20/20, repository 45/45, thêm VĐV + hub + live overlay + live score source-text 81/81.
- [x] `flutter build apk --debug --no-pub`: thành công.
- [x] Cài `aa785b1a` (`adb install -r` → Success), mở `MainActivity`: process chạy (PID 32444).
- [x] Cập nhật `12-release-evidence.md` với kết quả build và cài.
- [ ] Xác nhận thủ công (cần user): pan và zoom sơ đồ nhánh đấu; luồng nhập Excel; thêm VĐV theo email và cặp đôi.
- [ ] Commit: chỉ `git add` đúng file của phiên này. Không push.
