/// Giải đã nối fanpage Facebook chưa (`GET .../facebook-live/connection`).
class FacebookLiveConnection {
  const FacebookLiveConnection({
    required this.communityId,
    required this.connected,
    this.pageName,
  });

  final String? communityId;
  final bool connected;
  final String? pageName;

  factory FacebookLiveConnection.fromJson(Map<String, Object?> json) {
    final page = json['pageName'];
    final community = json['communityId'];
    return FacebookLiveConnection(
      communityId: community is String && community.isNotEmpty
          ? community
          : null,
      connected: json['connected'] == true,
      pageName: page is String && page.isNotEmpty ? page : null,
    );
  }
}

/// Live vừa tạo (`POST .../facebook-live`). [streamKey] là bí mật: chỉ giữ
/// trong state màn hình, không log, không lưu, không đưa vào URL.
class CreatedFacebookLive {
  const CreatedFacebookLive({
    required this.providerSessionId,
    required this.watchUrl,
    required this.rtmpUrl,
    required this.streamKey,
  });

  final String providerSessionId;
  final String watchUrl;
  final String rtmpUrl;
  final String streamKey;

  factory CreatedFacebookLive.fromJson(Map<String, Object?> json) {
    String text(String key) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      throw FormatException('Missing $key in Facebook live response.');
    }

    return CreatedFacebookLive(
      providerSessionId: text('providerSessionId'),
      watchUrl: text('watchUrl'),
      rtmpUrl: text('rtmpUrl'),
      streamKey: text('streamKey'),
    );
  }

  @override
  String toString() => 'CreatedFacebookLive($providerSessionId)';
}

/// Tạo live Facebook cho camera. Tách khỏi `ICourtCameraRepository` vì hợp đồng
/// đó cam kết không có khoá phát nào đi qua nó.
abstract class IFacebookCameraLiveRepository {
  Future<FacebookLiveConnection> getConnection(String tournamentId);

  /// Idempotent ở Backend: bấm lại trả đúng live đang chờ.
  Future<CreatedFacebookLive> createLive(String tournamentId);

  /// URL OAuth để mở bằng trình duyệt ngoài.
  Future<Uri> getConnectUrl(String communityId);
}
