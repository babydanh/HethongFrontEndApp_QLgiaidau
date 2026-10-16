/// Chọn các trận cùng giai đoạn với trận đang live để vẽ sơ đồ nhánh.
///
/// Provider nạp mọi trận của nội dung (vòng bảng lẫn loại trực tiếp) trong một
/// danh sách, và `round` của hai giai đoạn trùng số. Gom theo round mà không
/// lọc sẽ đặt vòng bảng và nhánh loại trực tiếp chung cột.
library;

import 'package:app_quanly_giaidau/domain/entities/match.dart';

String? _stageKey(String? raw) {
  final key = raw?.trim().toUpperCase();
  return (key == null || key.isEmpty) ? null : key;
}

/// Giữ các trận có cùng `stageType` với [current].
///
/// Không lọc khi trận hiện tại không có `stageType`, hoặc không trận nào trong
/// [matches] có `stageType` (dữ liệu cũ), để không làm rỗng sơ đồ.
List<MatchModel> liveBracketScope(
  List<MatchModel> matches,
  MatchModel current,
) {
  final stage = _stageKey(current.stageType);
  if (stage == null) return matches;
  if (matches.every((m) => _stageKey(m.stageType) == null)) return matches;
  return matches.where((m) => _stageKey(m.stageType) == stage).toList();
}
