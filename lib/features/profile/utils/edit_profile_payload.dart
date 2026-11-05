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
