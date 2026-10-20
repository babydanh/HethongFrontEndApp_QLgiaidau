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

/// Kết quả `GET /livestream/matches/{matchId}/replay`.
class MatchReplay {
  MatchReplay({
    required this.matchId,
    required this.available,
    required this.reason,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    required List<MatchReplaySegment> segments,
  }) : segments = List<MatchReplaySegment>.unmodifiable(segments);

  factory MatchReplay.fromJson(Map<String, Object?> json) {
    final rawSegments = json['segments'];
    final segments = <MatchReplaySegment>[];
    if (rawSegments is List) {
      for (final raw in rawSegments) {
        if (raw is! Map) continue;
        final segment = MatchReplaySegment.tryParse(_stringKeyedMap(raw));
        if (segment != null) segments.add(segment);
      }
    }
    segments.sort((a, b) => a.offsetSec.compareTo(b.offsetSec));
    final declaredDuration = _nonNegativeInt(json['durationSec']);
    final derivedDuration = segments.isEmpty
        ? 0
        : segments.last.offsetSec + segments.last.durationSec;
    final available = json['available'] == true && segments.isNotEmpty;
    return MatchReplay(
      matchId: json['matchId'] is String ? json['matchId']! as String : '',
      available: available,
      reason: available ? null : _replayReason(json['reason']),
      startedAt: _nullableString(json['startedAt']),
      endedAt: _nullableString(json['endedAt']),
      durationSec: available
          ? (declaredDuration < derivedDuration
                ? derivedDuration
                : declaredDuration)
          : 0,
      segments: segments,
    );
  }

  final String matchId;
  final bool available;
  final String? reason;
  final String? startedAt;
  final String? endedAt;
  final int durationSec;
  final List<MatchReplaySegment> segments;
}

class MatchReplaySegment {
  const MatchReplaySegment({
    required this.name,
    required this.url,
    required this.startAt,
    required this.offsetSec,
    required this.clipStartSec,
    required this.durationSec,
  });

  static MatchReplaySegment? tryParse(Map<String, Object?> json) {
    final name = _nullableString(json['name']);
    final url = _safeReplayUrl(json['url']);
    final startAt = _nullableString(json['startAt']);
    final offsetSec = _nonNegativeInt(json['offsetSec']);
    final clipStartSec = _nonNegativeInt(json['clipStartSec']);
    final durationSec = _nonNegativeInt(json['durationSec']);
    if (name == null ||
        url == null ||
        startAt == null ||
        durationSec < 1 ||
        json['offsetSec'] is! num ||
        json['clipStartSec'] is! num ||
        (json['clipStartSec'] as num) < 0 ||
        json['durationSec'] is! num) {
      return null;
    }
    return MatchReplaySegment(
      name: name,
      url: url,
      startAt: startAt,
      offsetSec: offsetSec,
      clipStartSec: clipStartSec,
      durationSec: durationSec,
    );
  }

  final String name;
  final String url;
  final String startAt;
  final int offsetSec;
  final int clipStartSec;
  final int durationSec;
}

String? _nullableString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _safeReplayUrl(Object? value) {
  final raw = _nullableString(value);
  if (raw == null) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return raw;
}

int _nonNegativeInt(Object? value) =>
    value is num && value.isFinite && value >= 0 ? value.toInt() : 0;

String? _replayReason(Object? value) => switch (value) {
  'NOT_FINISHED' => 'NOT_FINISHED',
  'NO_RECORDING' => 'NO_RECORDING',
  _ => null,
};
Map<String, Object?> _stringKeyedMap(Map value) => <String, Object?>{
  for (final entry in value.entries)
    if (entry.key is String) entry.key as String: entry.value,
};
