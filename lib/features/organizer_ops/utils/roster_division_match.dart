const Set<String> _doublesMatchTypes = {'DOUBLES', 'MIXED_DOUBLES'};

/// Dấu tiếng Việt quy về chữ cái gốc, để so khớp tên nội dung không phân biệt dấu.
const Map<String, String> _accentBases = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

/// Chuẩn hóa tên nội dung: bỏ khoảng trắng thừa, chữ thường, bỏ dấu.
String foldName(String value) {
  var result = value.trim().toLowerCase();
  for (final entry in _accentBases.entries) {
    for (final accented in entry.value.split('')) {
      result = result.replaceAll(accented, entry.key);
    }
  }
  return result.replaceAll(RegExp(r'\s+'), ' ');
}

bool isDoublesType(String matchType) =>
    _doublesMatchTypes.contains(matchType.trim().toUpperCase());

/// Tokens chữ-số của tên hạng mục đã chuẩn hóa (`foldName`), dùng để suy luận
/// kiểu thi đấu và giới tính từ tên trong file.
Set<String> _nameTokens(String value) => foldName(
  value,
).split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toSet();

/// Cùng bộ từ, bất kể thứ tự (port `divisionLabelMatches` của web,
/// `rosterLayout.ts`): `Nam đơn` khớp `Đơn nam`, còn `Đôi nam` và `Nam` không
/// khớp `Đơn nam`. Dùng cho khớp tên hạng mục của dòng lẫn tái dùng khi tạo.
bool divisionLabelMatches(String label, String divisionName) {
  final labelTokens = _nameTokens(label);
  final nameTokens = _nameTokens(divisionName);
  if (labelTokens.isEmpty || labelTokens.length != nameTokens.length) {
    return false;
  }
  return nameTokens.containsAll(labelTokens);
}

/// Suy kiểu thi đấu cho hạng mục mới từ tên trong file (port
/// `inferDivisionMatchType` của web, `pairLayout` web tương đương việc các dòng
/// có VĐV 2): "hỗn hợp"/mixed/nam+nữ → đôi nam nữ, có "đôi"/doubles hoặc có
/// dòng VĐV 2 → đôi, còn lại → đơn.
String inferMatchType(String label, {required bool anyRowHasPlayer2}) {
  final folded = ' ${foldName(label)} ';
  final tokens = _nameTokens(label);
  if (folded.contains(' hon hop ') ||
      tokens.contains('mixed') ||
      (tokens.contains('nam') && tokens.contains('nu'))) {
    return 'MIXED_DOUBLES';
  }
  if (tokens.contains('doi') ||
      tokens.contains('doubles') ||
      tokens.contains('double') ||
      anyRowHasPlayer2) {
    return 'DOUBLES';
  }
  return 'SINGLES';
}

/// Giới tính tên hạng mục tuyên bố (port `inferDivisionGender` của web);
/// null khi tên không nói gì (`Đôi Linh Hoạt`, `Doubles`) — hạng mục mở cho
/// mọi giới tính.
String? inferGender(String label) {
  final folded = ' ${foldName(label)} ';
  final tokens = _nameTokens(label);
  final male =
      tokens.contains('nam') ||
      tokens.contains('men') ||
      tokens.contains('male');
  final female =
      tokens.contains('nu') ||
      tokens.contains('women') ||
      tokens.contains('female');
  if (folded.contains(' hon hop ') ||
      tokens.contains('mixed') ||
      (male && female)) {
    return 'MIXED';
  }
  if (male) return 'MALE';
  if (female) return 'FEMALE';
  return null;
}
