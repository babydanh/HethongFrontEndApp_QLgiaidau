## Why
Độ phủ dòng đo được của App là 55,06% (54076/98206). Nhiều repository, notifier và model có logic quyết định (parse JSON lệch dạng, lọc, phân trang, xử lý lỗi/null) mà chưa có test hành vi. Màn hình lớn 0% chủ yếu là UI dựng sẵn, ít rủi ro nghiệp vụ hơn.

## What Changes
- Chỉ thêm/sửa file test trong `test/` (và helper test `test/support/`) cùng tài liệu OpenSpec này.
- Ưu tiên theo rủi ro × dòng chưa phủ: repository API (parse + lỗi) → notifier/provider → model.
- Không sửa code production, `lib/l10n/*`, file sinh. Test chốt nhầm hành vi nghi sai được ghi vào `findings.md` và bỏ qua.

## Impact
- Capability: `test-coverage`. Không đổi hành vi runtime.
