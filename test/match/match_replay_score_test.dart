import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_replay_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

MatchReplayScoreEvent _e(double at, int p1, int p2) => MatchReplayScoreEvent(
  offsetSec: at,
  p1SetsWon: p1,
  p2SetsWon: p2,
  scoreDetails: const <String, dynamic>{},
);

void main() {
  final events = <MatchReplayScoreEvent>[
    _e(10, 0, 0),
    _e(30, 1, 0),
    _e(50, 1, 1),
  ];

  group('matchReplayScoreAt (TC-SCOREREPLAY-APP)', () {
    test('TC-SCOREREPLAY-APP-05 before the first event there is no score yet', () {
      expect(matchReplayScoreAt(events, 0), isNull);
      expect(matchReplayScoreAt(events, 9.9), isNull);
    });

    test('TC-SCOREREPLAY-APP-06 exactly on an event, that event counts', () {
      expect(matchReplayScoreAt(events, 10), same(events[0]));
      expect(matchReplayScoreAt(events, 30), same(events[1]));
    });

    test('TC-SCOREREPLAY-APP-07 between two events the earlier one holds', () {
      expect(matchReplayScoreAt(events, 29.9), same(events[0]));
      expect(matchReplayScoreAt(events, 40), same(events[1]));
    });

    test('TC-SCOREREPLAY-APP-08 after the last event the last one holds', () {
      expect(matchReplayScoreAt(events, 50), same(events[2]));
      expect(matchReplayScoreAt(events, 5000), same(events[2]));
    });

    test('TC-SCOREREPLAY-APP-09 no events means no score', () {
      expect(matchReplayScoreAt(const <MatchReplayScoreEvent>[], 10), isNull);
    });

    test('TC-SCOREREPLAY-APP-10 seeking back picks the earlier score again', () {
      expect(matchReplayScoreAt(events, 60), same(events[2]));
      expect(matchReplayScoreAt(events, 35), same(events[1]));
    });

    test('TC-SCOREREPLAY-APP-11 unordered input and equal offsets resolve by order', () {
      final unordered = <MatchReplayScoreEvent>[events[2], events[0], events[1]];
      expect(matchReplayScoreAt(unordered, 40), same(events[1]));

      final sameOffset = <MatchReplayScoreEvent>[_e(20, 1, 0), _e(20, 1, 1)];
      expect(matchReplayScoreAt(sameOffset, 20), same(sameOffset[1]));
    });
  });
}
