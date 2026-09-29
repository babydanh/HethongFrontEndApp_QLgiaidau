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

  /// Tiền tố loại đơn vị hành chính đứng đầu tên tỉnh/thành mà API gắn vào,
  /// đã bỏ dấu: "Thành phố Hà Nội", "Tỉnh An Giang", "TP. Hồ Chí Minh".
  static final RegExp _provinceTypePrefix =
      RegExp(r'^(?:thanh pho|thi xa|tp|tinh)\s+');

  /// Khoá `code_name` của tỉnh/thành — đúng kiểu slug mà catalogue dùng:
  /// "Thành phố Hà Nội" → "ha_noi", "Tỉnh An Giang" → "an_giang",
  /// "TP. Hồ Chí Minh" → "ho_chi_minh".
  ///
  /// [provinceAliases] khoá theo hàm này chứ không theo mã số: mã số đổi
  /// theo từng đợt sáp xếp (Hà Nội là "01" ở dữ liệu cũ, "1" ở v2) còn tên
  /// thì không, nên bảng bí danh không còn đường để lệch với catalogue. Tỉnh
  /// nào chưa có trong catalogue thì mọi bí danh của nó rơi vào hư không chứ
  /// không trỏ nhầm sang tỉnh khác.
  static String provinceKey(String provinceName) =>
      removeVietnameseTones(provinceName)
          .replaceFirst(_provinceTypePrefix, '')
          .trim()
          .replaceAll(' ', '_');

  /// Từ điển bí danh cho các Tỉnh/Thành phố lớn, khoá theo [provinceKey].
  ///
  /// Mỗi bí danh phải đủ riêng để không khớp nhầm vào tên đường: "hue" hợp
  /// với "Thành phố Huế" nhưng cũng là chữ cuối của "Nguyễn Huệ" nên đã bỏ,
  /// và các tên thành phố trong tỉnh ("biên hoa" = Đại lộ Biên Hòa, "di an" =
  /// Đường Dĩ An) cũng vậy. Chữ viết tắt hợp ("hcm", "hn", "brvt") thì an toàn
  /// vì không phải từ tiếng Việt nào.
  static const Map<String, List<String>> provinceAliases = {
    // TP. Hồ Chí Minh
    'ho_chi_minh': [
      'tp hcm',
      'tphcm',
      'tp ho chi minh',
      'ho chi minh',
      'hcm',
      'sai gon',
      'saigon',
    ],
    // Hà Nội
    'ha_noi': ['ha noi', 'tp ha noi', 'hn', 'thu do ha noi'],
    // Đà Nẵng
    'da_nang': ['da nang', 'tp da nang', 'dn'],
    // Hải Phòng
    'hai_phong': ['hai phong', 'tp hai phong', 'hp'],
    // Cần Thơ
    'can_tho': ['can tho', 'tp can tho', 'ct'],
    // Bà Rịa - Vũng Tàu
    'ba_ria_vung_tau': ['ba ria vung tau', 'ba ria', 'vung tau', 'brvt'],
    // Bình Dương ("di an" bỏ: "Dĩ An" vừa là thành phố trong tỉnh vừa là tên
    // đường ở Bình Dương và Đồng Nai)
    'binh_duong': ['binh duong', 'thu dau mot', 'thuan an', 'bd'],
    // Đồng Nai ("bien hoa" bỏ: "Đại lộ Biên Hòa" là con đường bận nhất nước,
    // chạy ngang TP.HCM — tên đường chứ không phải tỉnh)
    'dong_nai': ['dong nai', 'long khanh'],
    // Huế ("hue" bỏ: "Nguyễn Huệ" là phố lớn ở Huế, Bình Dương, Nha Trang,
    // Vinh, Hà Nội)
    'hue': ['thua thien hue', 'tp hue'],
    // Khánh Hòa
    'khanh_hoa': ['khanh_hoa', 'nha trang', 'cam ranh'],
    // Lâm Đồng ("bao loc" bỏ: tên thành phố trong tỉnh, dễ trùng tên đường
    // ở tỉnh khác)
    'lam_dong': ['lam dong', 'da lat'],
    // Quảng Ninh
    'quang_ninh': ['quang ninh', 'ha long', 'cam pha', 'uong bi'],
    // Kiên Giang
    'kien_giang': ['kien giang', 'phu quoc', 'rach gia'],
  };

  /// Chữ chỉ đường ở đầu một dòng địa chỉ, đã bỏ dấu. Chỉ tính khi đứng đầu
  /// dòng vì "pho" trong "thanh pho ho chi minh" là chữ trong tên tỉnh chứ
  /// không phải tên phố.
  static const String _roadMarker = r'(?:duong|pho|ngo|hem|ton dau loi|dai lo)';

  /// Đầu một dòng địa chỉ: chữ chỉ đường, số nhà ("221B", "Số 5", "Nhà số 12")
  /// — những thứ theo sau chúng trong cùng dòng là tên đường, không phải
  /// tên tỉnh hay tên phường.
  static final RegExp _addressLineHead = RegExp(
    '^(?:$_roadMarker)\\s|^(?:so|nha so|nha|o|ho)\\s*\\d|^\\d',
  );

  /// Các dòng của [rawAddress] (cắt ở dấu phẩy) có thể chứa tên tỉnh hoặc
  /// tên phường mà host gõ tay, tức là mọi dòng trừ dòng địa chỉ.
  ///
  /// Đây là chỗ chặn lớp lỗi "tên đường cướp tỉnh/phường": "hue" trong
  /// "Đường Nguyễn Huệ" hay "Hai Bà Trưng" trong "221B Hai Bà Trưng" đều nằm
  /// trong dòng địa chỉ nên không được so khớp tên tỉnh hay tên phường. Cắt
  /// dòng trên chuỗi gốc chứ không trên chuỗi đã bỏ dấu, vì
  /// [removeVietnameseTones] thay cả dấu phẩy bằng khoảng trắng.
  static List<String> _localityLines(String rawAddress) => rawAddress
      .split(',')
      .map(removeVietnameseTones)
      .where((line) => line.isNotEmpty && !_addressLineHead.hasMatch(line))
      .toList(growable: false);

  /// Bí danh của một tỉnh theo đúng cách [detectProvince] tra: theo tên
  /// catalogue đang có, không theo mã số. Ô tìm kiếm của danh sách tỉnh dùng
  /// đường này để nhận cùng cách viết mà vùng đã áp dụng được nhận ra.
  static List<String> provinceAliasesOf(String provinceName) =>
      provinceAliases[provinceKey(provinceName)] ?? const <String>[];

  /// Index tỉnh/thành theo [provinceKey], tự sinh từ chính tên catalogue.
  static Map<String, T> _provincesByKey<T>(
    List<T> provinces,
    String Function(T) getName,
    String Function(T)? getFullName,
  ) {
    final byKey = <String, T>{};
    for (final province in provinces) {
      for (final raw in [getName(province), getFullName?.call(province) ?? '']) {
        final key = provinceKey(raw);
        if (key.isNotEmpty) byKey.putIfAbsent(key, () => province);
      }
    }
    return byKey;
  }

  /// Nhận diện Tỉnh/Thành phố từ chuỗi địa chỉ.
  ///
  /// [getCode] không còn tham gia tra bí danh — bảng bí danh khoá theo tên tỉnh
  /// nên mã số không quyết định kết quả nữa — nhưng vẫn giữ để chữ ký khớp
  /// với [detectWard].
  static T? detectProvince<T>({
    required String rawAddress,
    required List<T> provinces,
    required String Function(T) getCode,
    required String Function(T) getName,
    String Function(T)? getFullName,
  }) {
    if (rawAddress.trim().isEmpty || provinces.isEmpty) return null;

    final normalizedAddr = ' ${removeVietnameseTones(rawAddress)} ';

    // 1. Kiểm tra bí danh phổ biến trước (TP.HCM, HN, Đà Nẵng...), chỉ trong
    //    dòng không phải dòng địa chỉ.
    final byKey = _provincesByKey(provinces, getName, getFullName);
    final aliasLines = _localityLines(rawAddress);
    final aliasAddr =
        aliasLines.isEmpty ? '' : ' ${aliasLines.join(' , ')} ';
    for (final entry in provinceAliases.entries) {
      final target = byKey[entry.key];
      if (target == null) continue;
      for (final alias in entry.value) {
        final aliasPattern = RegExp('(^|\\s|\\W)$alias(\\s|\\W|)', caseSensitive: false);
        if (aliasPattern.hasMatch(aliasAddr)) {
          return target;
        }
      }
    }

    // 2. Tìm theo tên đầy đủ và tên chuẩn của từng tỉnh — tên chính thức
    //    ("Thành phố Hà Nội") thì hiếm khi nằm trong tên đường nên so khớp
    //    trên cả dòng địa chỉ, không chặn như lớp bí danh.
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

  /// Tiền tố loại đơn vị hành chính cấp xã mà API gắn vào tên ("Phường Bến
  /// Thành", "Xã Cẩm Phế", "Thị Trấn Vạn Hồng"), đã bỏ dấu. Đây là các từ
  /// loại, không tính viết tắt "p.", "x.", "tt." mà host gõ tay hay dùng.
  static final RegExp _unitTypePrefix = RegExp(
    r'^(?:phuong|xa|thi tran|dac khu)\s+',
  );

  /// Tên phường/xã đã bỏ dấu và bỏ tiền tố loại: "Phường Bến Thành" thành
  /// "ben thanh". Một chỗ duy nhất biết tiền tố loại là gì, để cách so khớp
  /// tên phường với cách host gõ tay không lệch nhau.
  static String localityName(String wardName) =>
      removeVietnameseTones(wardName).replaceFirst(_unitTypePrefix, '').trim();

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

    // Ưu tiên tên dài: tên cụ thể thắng tên chung.
    final sorted = [...wards]..sort((a, b) {
        final lenA = localityName(getFullName?.call(a) ?? getName(a)).length;
        final lenB = localityName(getFullName?.call(b) ?? getName(b)).length;
        return lenB.compareTo(lenA);
      });

    // 1. So khớp có tiền tố rõ ràng như "phuong ...", "xa ...", "p. ...", "x. ...", "tt. ..."
    for (final w in sorted) {
      // So khớp theo tên phường đã bỏ tiền tố: host gõ "Bãy Hiến" cũng ra.
      final normName = localityName(getName(w));
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

    // 2. So khớp trực tiếp tên phường/xã (đối với tên chữ không phải số thuần
    //    túy) — nhưng chỉ trong dòng không phải dòng địa chỉ. "Hai Bà Trưng"
    //    vừa là tên đường ở Hà Nội vừa là tên phường, nên "221B Hai Bà Trưng"
    //    không được thắt phường; phường mà host nói rõ ("Phường Bến Thành",
    //    "P. Thạch Thành") thì đã thắng ở bước 1.
    final bareLines = _localityLines(rawAddress);
    final bareAddr = bareLines.isEmpty ? '' : ' ${bareLines.join(' , ')} ';
    for (final w in sorted) {
      final normName = localityName(getName(w));
      if (normName.isEmpty || RegExp(r'^\d+$').hasMatch(normName) || normName.length < 3) continue;

      final pattern = RegExp('(^|\\s|\\W)$normName(\\s|\\W|)', caseSensitive: false);
      if (pattern.hasMatch(bareAddr)) {
        return w;
      }
    }

    return null;
  }
}
