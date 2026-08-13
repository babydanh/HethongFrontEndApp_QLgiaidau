import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Kết quả tạo giải Lite, với URL normalization cho joinUrl/qrPayload.
class LiteTournamentCreateResult {
  const LiteTournamentCreateResult({
    required this.id,
    required this.name,
    required this.status,
    this.inviteCode,
    this.joinUrl,
    this.qrPayload,
  });

  final String id;
  final String name;
  final String status;
  final String? inviteCode;
  final String? joinUrl;
  final String? qrPayload;

  factory LiteTournamentCreateResult.fromJson(Map<String, dynamic> json) {
    return LiteTournamentCreateResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      inviteCode: json['inviteCode']?.toString(),
      joinUrl: json['joinUrl']?.toString(),
      qrPayload: json['qrPayload']?.toString(),
    );
  }

  /// Resolve a potentially-relative URL to absolute.
  /// If [url] already starts with http:// or https://, returns it as-is.
  /// Otherwise prepends the configured [baseUrl] (or the production default).
  static String resolveUrl(String? url, {String? baseUrl}) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final configuredBase =
        baseUrl ??
        (dotenv.isInitialized
            ? dotenv.env['WEB_BASE_URL'] ?? dotenv.env['FRONTEND_URL']
            : null) ??
        'https://sporto.asia';
    // Strip leading slash on base, keep one slash between them
    final cleanBase = configuredBase.endsWith('/')
        ? configuredBase.substring(0, configuredBase.length - 1)
        : configuredBase;
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$cleanBase$cleanPath';
  }

  /// Convenience: the best invite link to display/share.
  /// Prefers joinUrl (resolved absolute), then constructs from inviteCode.
  String get resolvedJoinUrl {
    if (joinUrl != null && joinUrl!.isNotEmpty) {
      return resolveUrl(joinUrl);
    }
    if (inviteCode != null && inviteCode!.isNotEmpty) {
      return resolveUrl('/lite/tournaments/join/$inviteCode');
    }
    return '';
  }

  /// Convenience: QR payload — prefers qrPayload, falls back to resolvedJoinUrl.
  String get resolvedQrPayload {
    if (qrPayload != null && qrPayload!.isNotEmpty) {
      return resolveUrl(qrPayload);
    }
    return resolvedJoinUrl;
  }

  @override
  String toString() =>
      'LiteTournamentCreateResult(id: $id, name: $name, status: $status)';
}
