/// Kết quả `GET /livestream/matches/{matchId}/stream-info`.
///
/// Thông số do máy media báo về, không phải số App tự đo. [video] null nghĩa là
/// không có số liệu (AQP từ chối/lỗi/timeout hoặc trận không có camera).
class MatchStreamInfoModel {
  const MatchStreamInfoModel({
    required this.matchId,
    required this.available,
    required this.video,
  });

  factory MatchStreamInfoModel.fromJson(Map<String, Object?> json) {
    final rawVideo = json['video'];
    return MatchStreamInfoModel(
      matchId: (json['matchId'] as String?) ?? '',
      available: json['available'] == true,
      video: rawVideo is Map
          ? MatchStreamVideoInfoModel.fromJson(
              Map<String, Object?>.from(rawVideo),
            )
          : null,
    );
  }

  final String matchId;
  final bool available;
  final MatchStreamVideoInfoModel? video;

  /// FPS nguồn do máy media báo. Null khi `available` là false hoặc không có số.
  double? get fps => available ? video?.fps : null;
}

class MatchStreamVideoInfoModel {
  const MatchStreamVideoInfoModel({
    this.codec,
    this.width,
    this.height,
    this.fps,
  });

  factory MatchStreamVideoInfoModel.fromJson(Map<String, Object?> json) {
    final codec = json['codec'];
    return MatchStreamVideoInfoModel(
      codec: codec is String && codec.trim().isNotEmpty ? codec.trim() : null,
      width: _positiveInt(json['width']),
      height: _positiveInt(json['height']),
      fps: _positiveDouble(json['fps']),
    );
  }

  final String? codec;
  final int? width;
  final int? height;
  final double? fps;

  static int? _positiveInt(Object? value) {
    if (value is! num || !value.isFinite || value <= 0) return null;
    return value.toInt();
  }

  static double? _positiveDouble(Object? value) {
    if (value is! num || !value.isFinite || value <= 0) return null;
    return value.toDouble();
  }
}
