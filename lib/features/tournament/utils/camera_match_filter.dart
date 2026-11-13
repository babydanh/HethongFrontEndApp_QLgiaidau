import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// Bộ lọc trận ở tab Camera: ô tìm, vòng, công tắc "Chưa có cam".
class CameraMatchFilter {
  const CameraMatchFilter({
    this.query = '',
    this.round,
    this.onlyNoCamera = false,
  });

  final String query;

  /// Null = tất cả vòng.
  final int? round;
  final bool onlyNoCamera;

  bool get isActive => query.trim().isNotEmpty || round != null || onlyNoCamera;

  CameraMatchFilter copyWith({
    String? query,
    int? Function()? round,
    bool? onlyNoCamera,
  }) => CameraMatchFilter(
    query: query ?? this.query,
    round: round == null ? this.round : round(),
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

/// Các `round` có trong [matches], tăng dần, không trùng.
List<int> cameraMatchRounds(List<MatchModel> matches) =>
    (matches.map((match) => match.round).toSet().toList()..sort());

/// Lọc [matches] theo vòng, ô tìm (nhãn 2 bên hoặc mã trận) và "chưa có cam".
/// Trận chưa gán sân không bao giờ tính là "chưa có cam". Giữ nguyên thứ tự.
List<MatchModel> filterCameraMatches({
  required List<MatchModel> matches,
  required String Function(MatchModel match) labelOf,
  required bool Function(String courtId) hasCameraOnCourt,
  String query = '',
  int? round,
  bool onlyNoCamera = false,
}) {
  final needle = _fold(query);
  return matches
      .where((match) {
        if (round != null && match.round != round) return false;
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
