import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';

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
    List<MatchReplayOverlayEvent> overlayEvents =
        const <MatchReplayOverlayEvent>[],
  }) : segments = List<MatchReplaySegment>.unmodifiable(segments),
       overlayEvents = List<MatchReplayOverlayEvent>.unmodifiable(
         overlayEvents,
       );

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
      overlayEvents: MatchReplayOverlayEvent.parseList(json['overlayEvents']),
    );
  }

  final String matchId;
  final bool available;
  final String? reason;
  final String? startedAt;
  final String? endedAt;
  final int durationSec;
  final List<MatchReplaySegment> segments;

  /// H2H / bracket on-off changes on the replay timeline, ordered by offset.
  /// Empty for a match recorded before the Backend stored them.
  final List<MatchReplayOverlayEvent> overlayEvents;
}

/// One H2H or bracket overlay on/off change placed on the replay timeline by
/// the Backend. [offsetSec] is fractional (unlike a segment's whole seconds).
class MatchReplayOverlayEvent {
  const MatchReplayOverlayEvent({
    required this.kind,
    required this.visible,
    required this.offsetSec,
  });

  static MatchReplayOverlayEvent? tryParse(Map<String, Object?> json) {
    final kind = switch (json['kind']) {
      'H2H' => LiveOverlayKind.h2h,
      'BRACKET' => LiveOverlayKind.bracket,
      _ => null,
    };
    final visible = json['visible'];
    final offsetSec = json['offsetSec'];
    if (kind == null ||
        visible is! bool ||
        offsetSec is! num ||
        !offsetSec.isFinite ||
        offsetSec < 0) {
      return null;
    }
    return MatchReplayOverlayEvent(
      kind: kind,
      visible: visible,
      offsetSec: offsetSec.toDouble(),
    );
  }

  /// A missing or non-list value means no events; malformed entries are
  /// skipped. Ordered by offset, equal offsets keep the Backend's order.
  static List<MatchReplayOverlayEvent> parseList(Object? raw) {
    if (raw is! List) return const <MatchReplayOverlayEvent>[];
    final parsed = <MatchReplayOverlayEvent>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final event = tryParse(_stringKeyedMap(item));
      if (event != null) parsed.add(event);
    }
    // List.sort is not stable, so the original index breaks ties.
    final indexed = [for (var i = 0; i < parsed.length; i++) (i, parsed[i])];
    indexed.sort((a, b) {
      final byOffset = a.$2.offsetSec.compareTo(b.$2.offsetSec);
      return byOffset != 0 ? byOffset : a.$1.compareTo(b.$1);
    });
    return [for (final entry in indexed) entry.$2];
  }

  final LiveOverlayKind kind;
  final bool visible;
  final double offsetSec;
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
