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

  /// Compact form for small cards: the last two normalised parts of the
  /// tournament location (e.g. "Phường 10, Thành phố Hồ Chí Minh"), like the
  /// Web. Uses the same parts as [tournamentFullLocation], so a stale
  /// `locationConfig` snapshot is never mixed in.
  static String tournamentShortLocation(Tournament tournament) {
    final parts = _tournamentLocationParts(tournament);
    if (parts.length > 2) return parts.sublist(parts.length - 2).join(', ');
    return parts.join(', ');
  }

  static String tournamentFullLocation(Tournament tournament) =>
      _tournamentLocationParts(tournament).join(', ');

  static String tournamentFullLocationOr(
    Tournament tournament,
    String fallback,
  ) {
    final full = tournamentFullLocation(tournament);
    return full.isEmpty ? fallback : full;
  }

  /// Two display lines of the tournament location: the venue (or first part)
  /// and the address that follows it. Empty strings when there is no data.
  static ({String title, String subtitle}) tournamentLocationLines(
    Tournament tournament,
  ) {
    final parts = _tournamentLocationParts(tournament);
    if (parts.isEmpty) return (title: '', subtitle: '');
    final venueName = tournament.venueName?.trim() ?? '';
    final titleParts = venueName.isEmpty ? 1 : _uniqueParts([venueName]).length;
    return (
      title: venueName.isEmpty ? parts.first : venueName,
      subtitle: parts.skip(titleParts).join(', '),
    );
  }

  static List<String> _tournamentLocationParts(Tournament tournament) =>
      tournamentLocationParts(
        venueName: tournament.venueName,
        locationAddress: tournament.locationAddress,
        city: tournament.city,
        legacyLocation: tournament.locationConfig,
      );

  // Same precedence as the Web: the venue / address of the tournament is what
  // is shown; the older `locationConfig` snapshot is only a fallback and is
  // never mixed in (it can hold text typed before a saved venue was picked).
  static List<String> tournamentLocationParts({
    String? venueName,
    String? locationAddress,
    String? city,
    Map<String, dynamic>? legacyLocation,
  }) {
    final own = _uniqueParts([venueName, locationAddress, city]);
    if (own.isNotEmpty) return own;
    return _uniqueParts([
      legacyLocation?['venueName']?.toString(),
      legacyLocation?['address']?.toString(),
      legacyLocation?['ward']?.toString(),
      legacyLocation?['district']?.toString(),
      legacyLocation?['province']?.toString(),
      legacyLocation?['display']?.toString(),
    ]);
  }

  static String matchCourtLabel(String? courtName) => courtName?.trim() ?? '';

  /// Formats a neat, compact court/venue name for match card badges.
  static String matchShortCourt(String? courtName, {String? venueName}) {
    final raw = (courtName != null && courtName.trim().isNotEmpty)
        ? courtName.trim()
        : (venueName?.trim() ?? '');
    if (raw.isEmpty) return '';

    var clean = raw;
    // Clean long common prefixes
    clean = clean.replaceAll(RegExp(r'\bNhà thi đấu\b', caseSensitive: false), 'NTĐ');
    clean = clean.replaceAll(RegExp(r'\bSân vận động\b', caseSensitive: false), 'SVĐ');
    clean = clean.replaceAll(RegExp(r'\bCâu lạc bộ\b', caseSensitive: false), 'CLB');
    clean = clean.replaceAll(RegExp(r'\bTrung tâm TDTT\b', caseSensitive: false), 'TT TDTT');

    // If text has address parts separated by commas, only keep the first 1-2 parts
    if (clean.contains(',')) {
      clean = clean.split(',').first.trim();
    }
    return clean;
  }

  /// Court, court address, then the tournament venue / address / city. The
  /// legacy `locationConfig` snapshot is used only when nothing else exists.
  static String matchFullLocation({
    required Tournament tournament,
    String? courtName,
    String? courtAddress,
  }) {
    final parts = _uniqueParts([
      courtName,
      courtAddress,
      tournament.venueName,
      tournament.locationAddress,
      tournament.city,
    ]);
    if (parts.isNotEmpty) return parts.join(', ');
    return _tournamentLocationParts(tournament).join(', ');
  }

  /// Same rule when only the match payload is at hand: the court (which
  /// already falls back to the tournament venue name) and its address; the
  /// snapshot in `tournamentConfig.location` is a fallback for old records.
  static String matchFullLocationFromConfig({
    required String? courtName,
    required String? courtAddress,
    Map<String, dynamic>? tournamentConfig,
  }) {
    final parts = _uniqueParts([courtName, courtAddress]);
    if (parts.isNotEmpty) return parts.join(', ');
    final rawLocation = tournamentConfig?['location'];
    return tournamentLocationParts(
      legacyLocation: rawLocation is Map
          ? Map<String, dynamic>.from(rawLocation)
          : null,
    ).join(', ');
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
