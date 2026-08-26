import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

/// Chuẩn hóa cách hiển thị địa điểm theo từng ngữ cảnh, đồng bộ với web.
///
/// Không thay đổi dữ liệu địa chỉ đã lưu hoặc payload API. Các hàm ở đây chỉ
/// định dạng cho UI:
/// - Tournament summary: phường/quận/thành phố ngắn gọn.
/// - Match list: chỉ tên sân.
/// - Match/live detail: địa điểm đầy đủ.
class TournamentLocationFormatter {
  const TournamentLocationFormatter._();

  static String tournamentShortLocation(Tournament tournament) {
    final location = tournament.locationConfig;
    final structuredParts = _uniqueParts([
      location?['ward']?.toString(),
      location?['district']?.toString(),
      (location?['province'] ?? tournament.city)?.toString(),
    ]);

    if (structuredParts.length >= 2) {
      return structuredParts.join(', ');
    }

    final raw =
        (location?['display'] ??
                location?['address'] ??
                tournament.locationAddress ??
                tournament.city ??
                '')
            .toString()
            .trim();
    if (raw.isNotEmpty) {
      final parts = _uniqueParts(raw.split(','));
      if (parts.length > 2) return parts.sublist(parts.length - 2).join(', ');
      if (parts.isNotEmpty) return parts.join(', ');
    }

    return tournamentFullLocation(tournament);
  }

  static String tournamentFullLocation(Tournament tournament) {
    final location = tournament.locationConfig;
    return _uniqueParts([
      tournament.venueName,
      tournament.locationAddress,
      location?['display']?.toString(),
      location?['venueName']?.toString(),
      location?['address']?.toString(),
      location?['ward']?.toString(),
      location?['district']?.toString(),
      location?['province']?.toString(),
      tournament.city,
    ]).join(', ');
  }

  static String matchCourtLabel(String? courtName) => courtName?.trim() ?? '';

  static String matchFullLocation({
    required Tournament tournament,
    String? courtName,
    String? courtAddress,
  }) {
    final location = tournament.locationConfig;
    return _uniqueParts([
      courtName,
      courtAddress,
      tournament.venueName,
      tournament.locationAddress,
      location?['display']?.toString(),
      location?['venueName']?.toString(),
      location?['address']?.toString(),
      location?['ward']?.toString(),
      location?['district']?.toString(),
      location?['province']?.toString(),
      tournament.city,
    ]).join(', ');
  }

  static String matchFullLocationFromConfig({
    required String? courtName,
    required String? courtAddress,
    Map<String, dynamic>? tournamentConfig,
  }) {
    final rawLocation = tournamentConfig?['location'];
    final location = rawLocation is Map
        ? Map<String, dynamic>.from(rawLocation)
        : null;
    return _uniqueParts([
      courtName,
      courtAddress,
      location?['display']?.toString(),
      location?['venueName']?.toString(),
      location?['address']?.toString(),
      location?['ward']?.toString(),
      location?['district']?.toString(),
      location?['province']?.toString(),
    ]).join(', ');
  }

  static String _normalizeKey(String input) {
    var s = input.trim().toLowerCase();
    // Strip trailing punctuation
    s = s.replaceAll(RegExp(r'[\.,;]+$'), '').trim();

    // Map common Vietnamese metropolitan province names
    if (s == 'thành phố hồ chí minh' ||
        s == 'tp. hồ chí minh' ||
        s == 'tp hồ chí minh' ||
        s == 'tp.hcm' ||
        s == 'tp hcm' ||
        s == 'tphcm' ||
        s == 'hồ chí minh') {
      return 'tp_hcm';
    }
    if (s == 'thành phố hà nội' ||
        s == 'tp. hà nội' ||
        s == 'tp hà nội' ||
        s == 'tp.hn' ||
        s == 'tphn' ||
        s == 'hà nội') {
      return 'tp_hn';
    }
    if (s == 'thành phố đà nẵng' ||
        s == 'tp. đà nẵng' ||
        s == 'tp đà nẵng' ||
        s == 'đà nẵng') {
      return 'tp_danang';
    }
    if (s == 'thành phố hải phòng' ||
        s == 'tp. hải phòng' ||
        s == 'hải phòng') {
      return 'tp_haiphong';
    }
    if (s == 'thành phố cần thơ' ||
        s == 'tp. cần thơ' ||
        s == 'cần thơ') {
      return 'tp_cantho';
    }

    // Strip administrative prefixes for comparison
    return s
        .replaceFirst(
          RegExp(
            r'^(thành phố|tỉnh|quận|huyện|thị xã|phường|xã|tp\.|tp|q\.|h\.|tx\.|p\.|x\.)\s+',
          ),
          '',
        )
        .trim();
  }

  static List<String> _uniqueParts(Iterable<String?> values) {
    final result = <String>[];
    final seenKeys = <String>{};

    for (final value in values) {
      if (value == null || value.trim().isEmpty) continue;
      for (final piece in value.split(',')) {
        var trimmed = piece.trim();
        // Remove trailing punctuation
        trimmed = trimmed.replaceAll(RegExp(r'[\.,;]+$'), '').trim();
        if (trimmed.isEmpty) continue;

        final normKey = _normalizeKey(trimmed);
        if (normKey.isEmpty) continue;

        if (seenKeys.contains(normKey)) continue;

        // Check if any existing result item already contains this text or vice versa
        final isSubsumed = result.any((existing) {
          final normExisting = _normalizeKey(existing);
          return normExisting == normKey ||
              normExisting.contains(normKey) && normKey.length > 5;
        });

        if (!isSubsumed) {
          seenKeys.add(normKey);
          result.add(trimmed);
        }
      }
    }

    return result;
  }
}
