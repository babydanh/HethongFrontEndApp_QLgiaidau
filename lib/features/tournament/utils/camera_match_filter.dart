import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Một chặng của giải (vd "Bảng A • Lượt 1", "Tứ kết") và số trận thuộc chặng.
typedef CameraStage = ({String label, int count});

/// Bộ lọc trận ở tab Camera: ô tìm, chặng (bảng/lượt/vòng playoff), công tắc
/// "Chưa có cam".
class CameraMatchFilter {
  const CameraMatchFilter({
    this.query = '',
    this.stage,
    this.onlyNoCamera = false,
  });

  final String query;

  /// Nhãn chặng đang chọn; null = tất cả.
  final String? stage;
  final bool onlyNoCamera;

  bool get isActive => query.trim().isNotEmpty || stage != null || onlyNoCamera;

  CameraMatchFilter copyWith({
    String? query,
    String? Function()? stage,
    bool? onlyNoCamera,
  }) => CameraMatchFilter(
    query: query ?? this.query,
    stage: stage == null ? this.stage : stage(),
    onlyNoCamera: onlyNoCamera ?? this.onlyNoCamera,
  );
}

const _accentFold = {
  'a': 'àáảãạăằắẳẵặâầấẩẫậäå',
  'e': 'èéẻẽẹêềếểễệë',
  'i': 'ìíỉĩịîï',
  'o': 'òóỏõọôồốổỗộơờớởỡợöø',
  'u': 'ùúủũụưừứửữựûü',
  'y': 'ỳýỷỹỵÿ',
  'd': 'đ',
};

final Map<String, String> _foldMap = {
  for (final entry in _accentFold.entries)
    for (final rune in entry.value.runes) String.fromCharCode(rune): entry.key,
};

/// Chữ thường, bỏ dấu tiếng Việt (kể cả đ→d), bỏ khoảng trắng hai đầu.
String _fold(String value) {
  final buffer = StringBuffer();
  for (final rune in value.trim().toLowerCase().runes) {
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final char = String.fromCharCode(rune);
    buffer.write(_foldMap[char] ?? char);
  }
  return buffer.toString();
}

/// Các chặng có trong [matches] theo thứ tự xuất hiện, không trùng, kèm số
/// trận. [stageOf] cho nhãn chặng của một trận.
List<CameraStage> cameraMatchStages(
  List<MatchModel> matches,
  String Function(MatchModel match) stageOf,
) {
  final counts = <String, int>{};
  for (final match in matches) {
    counts.update(stageOf(match), (count) => count + 1, ifAbsent: () => 1);
  }
  return [
    for (final entry in counts.entries) (label: entry.key, count: entry.value),
  ];
}

/// Lọc [matches] theo chặng, ô tìm (nhãn 2 bên hoặc mã trận) và "chưa có cam".
/// Trận chưa gán sân không bao giờ tính là "chưa có cam". Giữ nguyên thứ tự.
List<MatchModel> filterCameraMatches({
  required List<MatchModel> matches,
  required String Function(MatchModel match) labelOf,
  required String Function(MatchModel match) stageOf,
  required bool Function(String courtId) hasCameraOnCourt,
  String query = '',
  String? stage,
  bool onlyNoCamera = false,
}) {
  final needle = _fold(query);
  return matches
      .where((match) {
        if (stage != null && stageOf(match) != stage) return false;
        if (onlyNoCamera) {
          final courtId = match.courtId;
          if (courtId == null || courtId.isEmpty) return false;
          if (hasCameraOnCourt(courtId)) return false;
        }
        if (needle.isEmpty) return true;
        return _fold(labelOf(match)).contains(needle) ||
            _fold(match.matchCode ?? '').contains(needle);
      })
      .toList(growable: false);
}
