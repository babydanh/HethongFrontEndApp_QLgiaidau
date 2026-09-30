
/// Kết quả `GET /livestream/matches/{matchId}/playback`.
///
/// [playbackUrl] là nguồn phát trực tiếp mà web đang phát; null nghĩa là trận chưa
/// bắt đầu phát, hoặc sân chưa khai URL.
class MatchPlaybackModel {
  const MatchPlaybackModel({
    required this.matchId,
    required this.streamStatus,
    required this.playbackUrl,
    required this.cameraName,
  });

  factory MatchPlaybackModel.fromJson(Map<String, Object?> json) {
    return MatchPlaybackModel(
      matchId: (json['matchId'] as String?) ?? '',
      streamStatus: _toStreamStatus(json['streamStatus']),
      playbackUrl: _trimOrNull(json['playbackUrl']),
      cameraName: _trimOrNull(json['cameraName']),
    );
  }

  final String matchId;
  final StreamStatus streamStatus;
  final String? playbackUrl;
  final String? cameraName;

  bool get isLive => streamStatus == StreamStatus.live;
  bool get hasStream => playbackUrl != null && playbackUrl!.isNotEmpty;

  static String? _trimOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static StreamStatus _toStreamStatus(Object? value) => switch (value) {
        'LIVE' => StreamStatus.live,
        'OFFLINE' => StreamStatus.offline,
        'ERROR' => StreamStatus.error,
        _ => StreamStatus.idle,
      };
}

enum StreamStatus { idle, live, offline, error }
