/// Bộ bóc tách và tự động nhận diện địa chỉ thông minh cho Flutter App
class VietnamAddressParser {
  /// Bỏ dấu tiếng Việt và chuẩn hóa chuỗi
  static String removeVietnameseTones(String str) {
    if (str.isEmpty) return '';
    String result = str.toLowerCase();
    result = result.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    result = result.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    result = result.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    result = result.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    result = result.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    result = result.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    result = result.replaceAll('đ', 'd');
    // Xóa ký tự đặc biệt thừa, giữ lại chữ, số và khoảng trắng
    result = result.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  /// Từ điển bí danh cho các Tỉnh/Thành phố lớn
  static const Map<String, List<String>> provinceAliases = {
    // TP. Hồ Chí Minh
    '79': ['tp hcm', 'tphcm', 'tp ho chi minh', 'ho chi minh', 'hcm', 'sai gon', 'saigon'],
    // Hà Nội
    '01': ['ha noi', 'tp ha noi', 'hn', 'thu do ha noi'],
    // Đà Nẵng
    '48': ['da nang', 'tp da nang', 'dn'],
    // Hải Phòng
    '31': ['hai phong', 'tp hai phong', 'hp'],
    // Cần Thơ
    '92': ['can tho', 'tp can tho', 'ct'],
    // Bà Rịa - Vũng Tàu
    '77': ['ba ria vung tau', 'ba ria', 'vung tau', 'brvt'],
    // Bình Dương
    '74': ['binh duong', 'thu dau mot', 'di an', 'thuan an', 'bd'],
    // Đồng Nai
    '75': ['dong nai', 'bien hoa', 'long khanh'],
    // Thừa Thiên Huế
    '46': ['thua thien hue', 'tp hue', 'hue'],
    // Khánh Hòa
    '56': ['khanh hoa', 'nha trang', 'cam ranh'],
    // Lâm Đồng
    '68': ['lam dong', 'da lat', 'bao loc'],
    // Quảng Ninh
    '22': ['quang ninh', 'ha long', 'cam pha', 'uong bi'],
    // Kiên Giang
    '91': ['kien giang', 'phu quoc', 'rach gia'],
  };

  /// Nhận diện Tỉnh/Thành phố từ chuỗi địa chỉ
  static T? detectProvince<T>({
    required String rawAddress,
    required List<T> provinces,
    required String Function(T) getCode,
    required String Function(T) getName,
    String Function(T)? getFullName,
  }) {
    if (rawAddress.trim().isEmpty || provinces.isEmpty) return null;

    final normalizedAddr = ' ${removeVietnameseTones(rawAddress)} ';

    // 1. Kiểm tra bí danh phổ biến trước (TP.HCM, HN, Đà Nẵng...)
    for (final entry in provinceAliases.entries) {
      final code = entry.key;
      for (final alias in entry.value) {
        final aliasPattern = RegExp('(^|\\s|\\W)$alias(\\s|\\W|)', caseSensitive: false);
        if (aliasPattern.hasMatch(normalizedAddr)) {
          final found = provinces.where((p) => getCode(p).toString() == code).firstOrNull;
          if (found != null) return found;
        }
      }
    }

    // 2. Tìm theo tên đầy đủ và tên chuẩn của từng tỉnh
    final sorted = [...provinces]..sort((a, b) {
        final lenA = (getFullName?.call(a) ?? getName(a)).length;
        final lenB = (getFullName?.call(b) ?? getName(b)).length;
        return lenB.compareTo(lenA);
      });

    for (final p in sorted) {
      final rawName = getName(p);
      final rawFullName = getFullName?.call(p) ?? '';

      final normName = removeVietnameseTones(rawName);
      final normFullName = removeVietnameseTones(rawFullName);

      if (normFullName.isNotEmpty) {
        final pattern = RegExp('(^|\\s|\\W)$normFullName(\\s|\\W|)', caseSensitive: false);
        if (pattern.hasMatch(normalizedAddr)) return p;
      }

      if (normName.length > 2) {
        final pattern = RegExp('(^|\\s|\\W)$normName(\\s|\\W|)', caseSensitive: false);
        if (pattern.hasMatch(normalizedAddr)) return p;
      }
    }

    return null;
  }

  /// Nhận diện Phường/Xã từ chuỗi địa chỉ
  static T? detectWard<T>({
    required String rawAddress,
    required List<T> wards,
    required String Function(T) getCode,
    required String Function(T) getName,
    String Function(T)? getFullName,
  }) {
    if (rawAddress.trim().isEmpty || wards.isEmpty) return null;

    final normalizedAddr = ' ${removeVietnameseTones(rawAddress)} ';

    final sorted = [...wards]..sort((a, b) {
        final lenA = (getFullName?.call(a) ?? getName(a)).length;
        final lenB = (getFullName?.call(b) ?? getName(b)).length;
        return lenB.compareTo(lenA);
      });

    // 1. So khớp có tiền tố rõ ràng như "phuong ...", "xa ...", "p. ...", "x. ...", "tt. ..."
    for (final w in sorted) {
      final normName = removeVietnameseTones(getName(w));
      final normFullName = removeVietnameseTones(getFullName?.call(w) ?? '');

      if (normName.isEmpty) continue;

      final prefixPatterns = [
        RegExp('(?:phuong|xa|thi\\s*tran|p|x|tt)[\\s\\.\\:]+$normName(?:\\s|\\W|)', caseSensitive: false),
        if (normFullName.isNotEmpty) RegExp('(^|\\s|\\W)$normFullName(\\s|\\W|)', caseSensitive: false),
      ];

      for (final pattern in prefixPatterns) {
        if (pattern.hasMatch(normalizedAddr)) {
          return w;
        }
      }
    }

    // 2. So khớp trực tiếp tên phường/xã (đối với tên chữ không phải số thuần túy)
    for (final w in sorted) {
      final normName = removeVietnameseTones(getName(w));
      if (normName.isEmpty || RegExp(r'^\d+$').hasMatch(normName) || normName.length < 3) continue;

      final pattern = RegExp('(^|\\s|\\W)$normName(\\s|\\W|)', caseSensitive: false);
      if (pattern.hasMatch(normalizedAddr)) {
        return w;
      }
    }

    return null;
  }
}
