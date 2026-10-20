import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';

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
