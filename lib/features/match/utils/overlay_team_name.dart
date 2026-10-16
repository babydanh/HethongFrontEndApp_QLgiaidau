/// Rút gọn tên đội/VĐV để hiện trên overlay bảng điểm — bản port từ web
/// (`shortTeamName` trong `LiveScoreboardOverlay.tsx`), giữ đúng cách viết tắt
/// để app và web nhìn giống nhau.
///
/// - Một người: `Trịnh Quang Minh` → `T. MINH`
/// - Đôi: `Việt Mỹ 2 · Việt Mỹ` → `V. 2 / V. MỸ`
///   (dấu phân cách nhận `·`, `•`, `/`, `&`, hoặc gạch ngang có khoảng trắng)
library;

final RegExp _whitespace = RegExp(r'\s+');
final RegExp _pairSeparators = RegExp(r'\s*[·•/&]\s*');
final RegExp _spacedHyphen = RegExp(r'\s+-\s+');

/// Viết tắt tên một người: chữ cái đầu của từ đầu + từ cuối, in hoa.
String shortenSinglePerson(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final words = trimmed.split(_whitespace).where((w) => w.isNotEmpty).toList();
  if (words.length <= 1) return trimmed.toUpperCase();
  final initial = words.first[0].toUpperCase();
  return '$initial. ${words.last.toUpperCase()}';
}

/// Viết tắt tên đội: nếu là cặp (đôi) thì viết tắt từng người và nối bằng ` / `.
String shortTeamName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return '';

  var pair = trimmed.split(_pairSeparators).where((p) => p.isNotEmpty).toList();
  if (pair.length < 2 && _spacedHyphen.hasMatch(trimmed)) {
    pair = trimmed.split(_spacedHyphen).where((p) => p.isNotEmpty).toList();
  }
  if (pair.length >= 2) {
    return '${shortenSinglePerson(pair[0])} / ${shortenSinglePerson(pair[1])}';
  }
  return shortenSinglePerson(trimmed);
}
