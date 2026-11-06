import 'package:flutter/widgets.dart' show StringCharacters;

/// Cùng mẫu với Backend (`users/dto/vn-phone.ts`): `+84` hoặc `0[35789]` + 8 số.
final RegExp _vnPhone = RegExp(r'^(?:\+84|0[35789])\d{8}$');

bool isValidVnPhone(String value) => _vnPhone.hasMatch(value.trim());

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Dựng body `PATCH /users/profile` của màn Sửa hồ sơ.
///
/// - `phoneNumber` chỉ gửi khi không rỗng (Backend từ chối chuỗi rỗng).
/// - `bio` và `address` luôn gửi, kể cả rỗng, để người dùng xóa được.
/// - `gender` không gửi khi bị khóa hoặc chưa chọn ([gender] null).
Map<String, dynamic> buildEditProfilePayload({
  required String fullName,
  required String phone,
  required DateTime? dateOfBirth,
  required String? gender,
  required bool genderLocked,
  required String address,
  required String provinceCode,
  required String bio,
}) {
  final phoneValue = phone.trim();
  return <String, dynamic>{
    'fullName': fullName.trim(),
    if (phoneValue.isNotEmpty) 'phoneNumber': phoneValue,
    if (dateOfBirth != null) 'dateOfBirth': _ymd(dateOfBirth),
    if (!genderLocked && gender != null) 'gender': gender,
    'address': address.trim(),
    if (provinceCode.isNotEmpty) 'provinceCode': provinceCode,
    'bio': bio.trim(),
  };
}

/// Nhãn giới tính của màn Sửa hồ sơ (cũng là giá trị gửi lên; Backend
/// `normalizeProfileGender` chấp nhận cả 'Nam'/'Nữ'/'Khác' lẫn MALE/FEMALE/OTHER).
const String genderLabelMale = 'Nam';
const String genderLabelFemale = 'Nữ';
const String genderLabelOther = 'Khác';

/// Bảng bỏ dấu tiếng Việt dạng dựng sẵn (chữ thường; chữ hoa lấy từ đây).
const _viBaseToVariants = <String, String>{
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<int, String> _viFold = () {
  final map = <int, String>{};
  _viBaseToVariants.forEach((base, variants) {
    for (final r in variants.runes) {
      map[r] = base;
      map[String.fromCharCode(r).toUpperCase().runes.first] = base
          .toUpperCase();
    }
  });
  return map;
}();

final RegExp _combiningMarks = RegExp('[̀-ͯ]');

/// Bỏ dấu tiếng Việt (dựng sẵn lẫn tổ hợp NFD) và Đ/đ -> D/d.
String _foldVietnamese(String value) {
  final out = StringBuffer();
  for (final r in value.replaceAll(_combiningMarks, '').runes) {
    out.write(_viFold[r] ?? String.fromCharCode(r));
  }
  return out.toString();
}

/// Chuẩn hoá giá trị giới tính Backend trả về (MALE/FEMALE/OTHER, hoặc biến
/// thể 'Nam'/'Nữ'/'Khác'/MEN/WOMEN/M/F...) về nhãn của màn. Null khi rỗng hoặc
/// không nhận diện được (không đoán bừa thành 'Nam').
String? normalizeGenderLabel(String? raw) {
  if (raw == null) return null;
  switch (_foldVietnamese(raw.trim()).toUpperCase()) {
    case 'MALE' || 'MEN' || 'NAM' || 'M':
      return genderLabelMale;
    case 'FEMALE' || 'WOMEN' || 'NU' || 'F':
      return genderLabelFemale;
    case 'OTHER' || 'OTHERS' || 'KHAC':
      return genderLabelOther;
    default:
      return null;
  }
}

/// Viết hoa + bỏ dấu tiếng Việt: 'Nguyễn Văn Ánh' -> 'NGUYEN VAN ANH'.
String normalizeBankAccountName(String value) =>
    _foldVietnamese(value).toUpperCase();

/// Ký tự đầu (theo grapheme) viết hoa của [value]; [fallback] khi rỗng.
String firstInitial(String? value, {String fallback = 'U'}) {
  if (value == null || value.isEmpty) return fallback;
  return value.characters.first.toUpperCase();
}
