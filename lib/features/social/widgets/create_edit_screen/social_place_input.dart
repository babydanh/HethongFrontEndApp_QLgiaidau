import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';

/// Từ chỉ đường ở đầu một dòng địa chỉ Việt Nam, đã bỏ dấu. Ở giữa chuỗi thì
/// không tính: "Sân đường Nguyễn Huệ" là tên sân chứ không phải địa chỉ.
final RegExp _streetAddressHead = RegExp(
  r'^(?:duong|pho|ngo|hem|ton dau loi|dai lo|quoc lo)\b'
  r'|^(?:so|nha so|nha|o|ho)\s*\d'
  r'|^\d',
);

/// [text] là nội dung người dùng gõ ở ô "Tên sân hoặc địa chỉ đầy đủ" có phải
/// địa chỉ street-level không.
///
/// Ô đó nhận cả tên sân lẫn địa chỉ, nên khi chọn ghim trên bản đồ mới biết
/// dùng làm gì: text trông là địa chỉ thì giữ nguyên street-level của host,
/// còn lại thì lấy địa chỉ hành chính từ reverse lookup.
///
/// Dấu phẩy là dấu hiệu mạnh nhất vì "Phường Bến Thành, Quận 1" chỉ địa
/// chính; còn từ chỉ đường và số nhà chỉ tính khi đứng đầu chuỗi, vì "Sân
/// đường Nguyễn Huệ" hay "221B" nằm giữa tên sân vẫn là tên sân.
bool looksLikeStreetAddress(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.contains(',')) return true;
  return _streetAddressHead.hasMatch(
    VietnamAddressParser.removeVietnameseTones(trimmed),
  );
}
