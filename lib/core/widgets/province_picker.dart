import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Mapping tỉnh/thành Việt Nam theo mã code.
///
/// Backend dùng mã code (VD: '79' = TP.HCM, '01' = Hà Nội).
/// Xem bảng `provinces` trong database schema.
class ProvinceData {
  final String code;
  final String name;

  const ProvinceData({required this.code, required this.name});

  static const List<ProvinceData> all = [
    ProvinceData(code: '01', name: 'Hà Nội'),
    ProvinceData(code: '02', name: 'Hà Giang'),
    ProvinceData(code: '04', name: 'Cao Bằng'),
    ProvinceData(code: '06', name: 'Bắc Kạn'),
    ProvinceData(code: '08', name: 'Tuyên Quang'),
    ProvinceData(code: '10', name: 'Lào Cai'),
    ProvinceData(code: '11', name: 'Điện Biên'),
    ProvinceData(code: '12', name: 'Lai Châu'),
    ProvinceData(code: '14', name: 'Sơn La'),
    ProvinceData(code: '15', name: 'Yên Bái'),
    ProvinceData(code: '17', name: 'Hoà Bình'),
    ProvinceData(code: '19', name: 'Thái Nguyên'),
    ProvinceData(code: '20', name: 'Lạng Sơn'),
    ProvinceData(code: '22', name: 'Quảng Ninh'),
    ProvinceData(code: '24', name: 'Bắc Giang'),
    ProvinceData(code: '25', name: 'Phú Thọ'),
    ProvinceData(code: '26', name: 'Vĩnh Phúc'),
    ProvinceData(code: '27', name: 'Bắc Ninh'),
    ProvinceData(code: '30', name: 'Hải Dương'),
    ProvinceData(code: '31', name: 'Hải Phòng'),
    ProvinceData(code: '33', name: 'Hưng Yên'),
    ProvinceData(code: '34', name: 'Thái Bình'),
    ProvinceData(code: '35', name: 'Hà Nam'),
    ProvinceData(code: '36', name: 'Nam Định'),
    ProvinceData(code: '37', name: 'Ninh Bình'),
    ProvinceData(code: '38', name: 'Thanh Hóa'),
    ProvinceData(code: '40', name: 'Nghệ An'),
    ProvinceData(code: '42', name: 'Hà Tĩnh'),
    ProvinceData(code: '44', name: 'Quảng Bình'),
    ProvinceData(code: '45', name: 'Quảng Trị'),
    ProvinceData(code: '46', name: 'Thừa Thiên Huế'),
    ProvinceData(code: '48', name: 'Đà Nẵng'),
    ProvinceData(code: '49', name: 'Quảng Nam'),
    ProvinceData(code: '51', name: 'Quảng Ngãi'),
    ProvinceData(code: '52', name: 'Bình Định'),
    ProvinceData(code: '54', name: 'Phú Yên'),
    ProvinceData(code: '56', name: 'Khánh Hòa'),
    ProvinceData(code: '58', name: 'Ninh Thuận'),
    ProvinceData(code: '60', name: 'Bình Thuận'),
    ProvinceData(code: '62', name: 'Kon Tum'),
    ProvinceData(code: '64', name: 'Gia Lai'),
    ProvinceData(code: '66', name: 'Đắk Lắk'),
    ProvinceData(code: '67', name: 'Đắk Nông'),
    ProvinceData(code: '68', name: 'Lâm Đồng'),
    ProvinceData(code: '70', name: 'Bình Phước'),
    ProvinceData(code: '72', name: 'Tây Ninh'),
    ProvinceData(code: '74', name: 'Bình Dương'),
    ProvinceData(code: '75', name: 'Đồng Nai'),
    ProvinceData(code: '77', name: 'Bà Rịa - Vũng Tàu'),
    ProvinceData(code: '79', name: 'TP. Hồ Chí Minh'),
    ProvinceData(code: '80', name: 'Long An'),
    ProvinceData(code: '82', name: 'Tiền Giang'),
    ProvinceData(code: '83', name: 'Bến Tre'),
    ProvinceData(code: '84', name: 'Trà Vinh'),
    ProvinceData(code: '86', name: 'Vĩnh Long'),
    ProvinceData(code: '87', name: 'Đồng Tháp'),
    ProvinceData(code: '89', name: 'An Giang'),
    ProvinceData(code: '91', name: 'Kiên Giang'),
    ProvinceData(code: '92', name: 'Cần Thơ'),
    ProvinceData(code: '93', name: 'Hậu Giang'),
    ProvinceData(code: '94', name: 'Sóc Trăng'),
    ProvinceData(code: '95', name: 'Bạc Liêu'),
    ProvinceData(code: '96', name: 'Cà Mau'),
  ];

  /// Tìm province theo code.
  static ProvinceData? fromCode(String code) {
    try {
      return all.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Tìm province gần đúng theo tên.
  static ProvinceData? fromName(String name) {
    final lower = name.toLowerCase().trim();
    try {
      return all.firstWhere(
        (p) => p.name.toLowerCase().contains(lower) || lower.contains(p.name.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Dropdown chọn tỉnh/thành theo mã code.
class ProvincePicker extends StatelessWidget {
  final String? selectedCode;
  final ValueChanged<String?> onChanged;
  final AppColorsExtension colors;

  const ProvincePicker({
    super.key,
    this.selectedCode,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCode != null && ProvinceData.fromCode(selectedCode!) != null
              ? selectedCode
              : ProvinceData.all.first.code,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: colors.textMuted),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
          dropdownColor: colors.bgSurface,
          items: ProvinceData.all.map((p) {
            return DropdownMenuItem(
              value: p.code,
              child: Text('${p.name} (${p.code})'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
