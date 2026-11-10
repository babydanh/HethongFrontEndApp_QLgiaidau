## Why

Người dùng chốt: trọng tài đổi giao bằng tay ở bất kỳ tỉ số nào (đổi đội giao, đổi Giao 1 <-> Giao 2) mà không đổi điểm, và App phải giống hệt Web (spec chung `doi-giao-spec.md`, 2026-11-09). App đã có hai thao tác này (chạm VĐV đội kia -> "Giao bóng cho người này" hoặc kéo trái bóng; chạm người giao -> "Chuyển thành giao N"), nhưng đổi ĐỘI giao bằng trái bóng cần HAI lần hoàn tác: lần đầu chỉ gỡ người giao chỉ định trên sân, lần hai mới trả đội giao. Spec chung yêu cầu mỗi thao tác đổi giao là MỘT bước hoàn tác.

## What Changes

- Đổi đội giao bằng trái bóng / "Giao bóng cho người này" sang đội kia: người giao được chỉ định trên sân KHÔNG ghi vào lịch sử sân nữa (`setServerAfterTeamChange`), vì bước hoàn tác của bảng điểm đã giữ cả sân trước khi đổi. Một lần hoàn tác trả lại đội giao, số giao, cờ mở màn và sân.
- Không đổi luật tự chuyển giao (side-out, mở màn, rally), không đổi khoá dữ liệu `scoreDetails.liveState.sideOutState`.

## Out of scope

- Không thêm nút hiển thị mới trên sân (thao tác đã có qua chạm VĐV và kéo bóng).
- Không sửa Web/Backend.

## Capabilities

### Modified Capabilities
- `pickleball-court-scoring`: đổi giao bằng tay ở mọi tỉ số và hoàn tác một bước.
