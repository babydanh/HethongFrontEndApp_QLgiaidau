# Flutter App — VI / EN Localization (l10n) Guidelines

1. **Tệp nguồn (Source of Truth)**:
   - `lib/l10n/app_vi.arb` (Tiếng Việt)
   - `lib/l10n/app_en.arb` (English)

2. **Quy tắc bắt buộc**:
   - Mọi chuỗi hiển thị trên UI PHẢI được định nghĩa trong cả 2 tệp `.arb`.
   - Không được hardcode chuỗi text trực tiếp trong file `.dart`.
   - Trong Widget, luôn sử dụng `final l10n = AppLocalizations.of(context)!;` hoặc `context.l10n`.
   - Sau khi cập nhật file `.arb`, chạy `flutter analyze` để xác thực 0 lỗi.
