import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_replay_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

MatchReplayOverlayEvent _e(LiveOverlayKind kind, bool visible, double at) =>
    MatchReplayOverlayEvent(kind: kind, visible: visible, offsetSec: at);

void main() {
  final h2hWindow = <MatchReplayOverlayEvent>[
    _e(LiveOverlayKind.h2h, true, 30),
    _e(LiveOverlayKind.h2h, false, 50),
  ];

  group('matchReplayOverlayAt (TC-REPLAYOV)', () {
    test('TC-REPLAYOV-05 on from the on event up to the off event', () {
      expect(matchReplayOverlayAt(h2hWindow, 29.9).h2h, isFalse);
      expect(matchReplayOverlayAt(h2hWindow, 30).h2h, isTrue);
      expect(matchReplayOverlayAt(h2hWindow, 40).h2h, isTrue);
      expect(matchReplayOverlayAt(h2hWindow, 49.9).h2h, isTrue);
      expect(matchReplayOverlayAt(h2hWindow, 50).h2h, isFalse);
      expect(matchReplayOverlayAt(h2hWindow, 500).h2h, isFalse);
    });

    test('TC-REPLAYOV-06 seeking back into the window turns it on again', () {
      expect(matchReplayOverlayAt(h2hWindow, 70).h2h, isFalse);
      expect(matchReplayOverlayAt(h2hWindow, 40).h2h, isTrue);
    });

    test('TC-REPLAYOV-07 no events means nothing is on', () {
      final state = matchReplayOverlayAt(const <MatchReplayOverlayEvent>[], 10);
      expect(state.h2h, isFalse);
      expect(state.bracket, isFalse);
    });

    test('TC-REPLAYOV-08 H2H and bracket are decided independently', () {
      final events = <MatchReplayOverlayEvent>[
        _e(LiveOverlayKind.h2h, true, 10),
        _e(LiveOverlayKind.bracket, true, 20),
        _e(LiveOverlayKind.h2h, false, 30),
      ];

      expect(matchReplayOverlayAt(events, 15), (h2h: true, bracket: false));
      expect(matchReplayOverlayAt(events, 25), (h2h: true, bracket: true));
      expect(matchReplayOverlayAt(events, 35), (h2h: false, bracket: true));
    });

    test('TC-REPLAYOV-09 unordered input and equal offsets resolve by order', () {
      final unordered = <MatchReplayOverlayEvent>[
        _e(LiveOverlayKind.h2h, false, 50),
        _e(LiveOverlayKind.h2h, true, 30),
      ];
      expect(matchReplayOverlayAt(unordered, 40).h2h, isTrue);

      // Same offset: the later entry wins, as the Backend sends them in time order.
      final sameOffset = <MatchReplayOverlayEvent>[
        _e(LiveOverlayKind.h2h, true, 20),
        _e(LiveOverlayKind.h2h, false, 20),
      ];
      expect(matchReplayOverlayAt(sameOffset, 20).h2h, isFalse);
    });
  });
}
