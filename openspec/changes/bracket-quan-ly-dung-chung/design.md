## Phương án đã chọn: A — mở rộng bracket mới thành bản có thể sửa

Hai màn quản lý và trang công khai cùng gọi `PlayoffDoubleElimView`. Chế độ sửa bật bằng tham số `editing`; không có `editing` thì hành vi y như hiện tại (chỉ xem).

### Đã loại
- **B. Giữ bản cũ cho chế độ sửa:** nhanh nhưng vẫn hai bracket, bản cũ không mượt và không đẹp như bản mới; trái với yêu cầu "bỏ cũ".
- **C. Copy bản mới thành bản sửa riêng:** trùng code, sửa giao diện phải sửa hai nơi.

### Quyết định người dùng (Lavish, 2026-11-06)
Người dùng trả lời "làm dùng chung" ⇒ phương án A. Các câu còn lại lấy theo mặc định đề xuất: màn toàn màn hình dùng chung view 2 vòng mỗi trang; bấm thẻ ở màn quản lý giữ luồng cũ; nút "Chấm điểm" là chip nhỏ ở dòng đầu thẻ.

## Kiến trúc

| Khối | Tệp | Vai trò |
|---|---|---|
| `BracketSlotRow` | `widgets/bracket_slot_row.dart` (mới) | Bọc một hàng VĐV: `DragTarget` + `LongPressDraggable` (giữ 140ms, `bracketDragDelay`) + chạm-chạm + khóa ô. Nhận `child` là nội dung hàng nên thẻ tự vẽ. Chuyển nguyên logic từ `BracketMatchCard._buildSlotRow`. |
| `openBracketMatch` | `widgets/bracket_match_tap.dart` (mới) | Hàm chuyển nguyên `BracketMatchCard._onTap`: chọn kiểu chấm điểm / vào live / popup chi tiết. |
| `_BracketCard` | `widgets/playoff_bracket_board.dart` | Thêm tham số `editing`, `selectedSlot`, hàng BYE, viền vàng chung kết, ELO, chip chấm điểm, nhấn thu nhẹ. |
| `BracketEdgePager` | `widgets/bracket_edge_pager.dart` (mới) | Hai vùng mép khi đang kéo; giữ 450ms thì gọi `onPrev`/`onNext`. |
| `PlayoffDoubleElimView` | `widgets/playoff_double_elim_view.dart` | Giữ `_selectedSlot`, `_isUpdating`, `_handleSlotTap`, `_handleSlotDrop` (chuyển từ `SingleElimDiagram`), truyền xuống bảng; nối `BracketEdgePager` với `select()`. |
| Màn quản lý | `bracket_view_screen.dart`, `bracket_diagram_screen.dart` | Thay hai nhánh `DoubleElimDiagram`/`SingleElimDiagram` bằng một `PlayoffDoubleElimView`. |

### Chữ ký chung

```dart
class BracketEditing {
  const BracketEditing({required this.onSlotDrop, this.isUpdating = false});
  final BracketSlotDropCallback onSlotDrop; // từ BracketSlotEditingScope
  final bool isUpdating;
}

class BracketSlotRow extends StatelessWidget {
  const BracketSlotRow({
    super.key,
    required this.match,
    required this.slot,            // 'participant1' | 'participant2'
    required this.label,           // tên hiển thị khi kéo
    required this.child,
    this.selectedSlot,
    this.onSlotTap,
    this.onSlotDrop,
  });
}

void openBracketMatch(
  BuildContext context, {
  required MatchModel match,
  required String tournamentId,
  required bool canScoreMatch,
  required bool isReferee,
  required bool isReadOnly,
});

// PlayoffDoubleElimView thêm:
//   final BracketEditing? editing;
//   final ValueChanged<MatchModel>? onMatchTap;      // mặc định mở showGroupMatchSheet
//   final ValueChanged<MatchModel>? onDoubleTapMatch;
```

## Chuyển động

Tối đa 260ms, chỉ animate transform/opacity, mỗi thẻ có `RepaintBoundary`, controller khai báo ngoài `build` và dispose, đọc `MediaQuery.disableAnimationsOf` (true ⇒ vào thẳng trạng thái cuối). Trạng thái nghiệp vụ (đã chọn, đang cập nhật, kết quả thả) không chờ animation xong; animation bị hủy giữa chừng không để ô bị khóa.

| Tình huống | Chuyển động | Thời lượng · đường cong |
|---|---|---|
| Lật vòng | Giữ cửa sổ trượt+mờ hiện có; thêm chỉ báo vòng trượt | 260ms · easeOutCubic |
| Nhấc VĐV | Phóng 1.04, đổ bóng, `HapticFeedback.selectionClick`; ô gốc mờ 38% | 140ms · easeOut |
| Ô nhận thả | Nền xanh nhạt, viền, phóng 1.02 | 140ms |
| Thả xong | `AnimatedSwitcher` theo `participantId`: tên cũ trượt ra, tên mới trượt vào; thẻ mờ nhẹ khi `isUpdating` | 200ms · easeOutCubic |
| Kéo tới mép | Vệt sáng mép hiện dần; 450ms thì lật trang | 120ms hiện, 260ms lật |
| Có người thắng | Đường nối tô xanh chạy (TweenAnimationBuilder), nền hàng thắng hiện dần, tick bật nảy | 300ms · easeOutBack cho tick |
| Trận live | Chấm đỏ nhấp nháy chậm, chỉ khi `match.isLive` | 1,2s lặp |
| Vào lần đầu | Thẻ hiện lần lượt theo cột, trễ 40ms mỗi cột, chỉ lần dựng đầu | 220ms · easeOutCubic |
| Nhấn thẻ | Thu 0.98 | 90ms |

## Rủi ro và cách xử lý

- **SWAP qua nhiều vòng:** cửa sổ chỉ có 2 vòng; xử lý bằng `BracketEdgePager`. Khay chờ nằm trên cửa sổ nên luôn thả được vào ô đang thấy.
- **Vuốt ngang:** cửa sổ 2 vòng luôn vừa chiều ngang nên không còn cuộn ngang; vuốt ngang trên bracket chuyển tab như chỗ khác. Kéo thả vẫn cần giữ 140ms nên không tranh với vuốt.
- **Trang công khai phải không đổi hành vi:** không truyền `editing` ⇒ không dựng `DragTarget`/`LongPressDraggable`; test công khai hiện có phải vẫn xanh.
- **Gộp:** hai nhánh khác sửa `bracket_view_screen.dart` ở dòng ~13 và 461–468; thay đổi ở đây chỉ chạm khoảng dòng 1455–1477 và import. Nhánh nền `playoff-2-vong-moi-trang` chưa lên `main`.
- **Chưa kiểm trên máy thật:** kéo thả và chuyển động chỉ chứng minh được một phần bằng widget test; cần điện thoại kết nối để xem bằng mắt.
