import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';

/// Vị trí cục bộ tương ứng với thời gian trên timeline toàn trận.
class MatchReplayPosition {
  const MatchReplayPosition({
    required this.segmentIndex,
    required this.offsetSec,
  });

  final int segmentIndex;
  final int offsetSec;

  @override
  bool operator ==(Object other) =>
      other is MatchReplayPosition &&
      other.segmentIndex == segmentIndex &&
      other.offsetSec == offsetSec;

  @override
  int get hashCode => Object.hash(segmentIndex, offsetSec);
}

/// Ánh xạ thời gian chung sang segment/offset mà không phụ thuộc vào UI.
MatchReplayPosition? matchReplayPositionAt(
  List<MatchReplaySegment> segments,
  int globalSeconds,
) {
  if (segments.isEmpty) return null;
  final time = globalSeconds < 0 ? 0 : globalSeconds;
  for (var index = 0; index < segments.length; index++) {
    final segment = segments[index];
    final end = segment.offsetSec + segment.durationSec;
    if (time >= segment.offsetSec && time < end) {
      return MatchReplayPosition(
        segmentIndex: index,
        offsetSec: time - segment.offsetSec,
      );
    }
    if (time < segment.offsetSec) {
      // Estimate có thể tạo gap ngắn; map vị trí gap tới đầu segment kế tiếp.
      return MatchReplayPosition(segmentIndex: index, offsetSec: 0);
    }
  }
  final lastIndex = segments.length - 1;
  return MatchReplayPosition(
    segmentIndex: lastIndex,
    offsetSec: segments.last.durationSec,
  );
}

int matchReplayGlobalSeconds(
  MatchReplayPosition position,
  List<MatchReplaySegment> segments,
) {
  if (position.segmentIndex < 0 || position.segmentIndex >= segments.length) {
    return 0;
  }
  final segment = segments[position.segmentIndex];
  final offset = position.offsetSec.clamp(0, segment.durationSec).toInt();
  return segment.offsetSec + offset;
}

/// Media offset for a timeline-relative segment position.
int matchReplayMediaSeconds(MatchReplaySegment segment, int elapsedSeconds) {
  final elapsed = elapsedSeconds.clamp(0, segment.durationSec).toInt();
  return segment.clipStartSec + elapsed;
}

/// A segment is finished at its estimated boundary, even if the file continues.
bool matchReplaySegmentReachedEnd(
  MatchReplaySegment segment,
  int mediaSeconds,
) => mediaSeconds >= segment.clipStartSec + segment.durationSec;

int matchReplayElapsedSeconds(MatchReplaySegment segment, int mediaSeconds) =>
    (mediaSeconds - segment.clipStartSec).clamp(0, segment.durationSec).toInt();

/// Which overlays are on at [seconds] of the replay timeline: for each kind the
/// last event at or before [seconds] decides, and no event means off. Input
/// order does not matter; on equal offsets the later entry wins.
({bool h2h, bool bracket}) matchReplayOverlayAt(
  List<MatchReplayOverlayEvent> events,
  num seconds,
) {
  var h2h = false;
  var bracket = false;
  var h2hAt = -1.0;
  var bracketAt = -1.0;
  for (final event in events) {
    if (event.offsetSec > seconds) continue;
    if (event.kind == LiveOverlayKind.h2h) {
      if (event.offsetSec < h2hAt) continue;
      h2hAt = event.offsetSec;
      h2h = event.visible;
    } else {
      if (event.offsetSec < bracketAt) continue;
      bracketAt = event.offsetSec;
      bracket = event.visible;
    }
  }
  return (h2h: h2h, bracket: bracket);
}
