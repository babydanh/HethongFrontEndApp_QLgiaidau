import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _replayJson({Object? overlayEvents, bool withKey = true}) =>
    <String, Object?>{
      'matchId': 'match-1',
      'available': true,
      'reason': null,
      'startedAt': '2026-11-06T10:00:00+07:00',
      'endedAt': '2026-11-06T10:30:00+07:00',
      'durationSec': 90,
      'segments': <Object?>[
        <String, Object?>{
          'name': 'a.mp4',
          'url': 'https://media.example.test/a.mp4',
          'startAt': '2026-11-06T10:00:00+07:00',
          'offsetSec': 0,
          'clipStartSec': 0,
          'durationSec': 90,
        },
      ],
      if (withKey) 'overlayEvents': overlayEvents,
    };

Map<String, Object?> _event(Object? kind, Object? visible, Object? offsetSec) =>
    <String, Object?>{'kind': kind, 'visible': visible, 'offsetSec': offsetSec};

void main() {
  group('MatchReplay.overlayEvents (TC-REPLAYOV)', () {
    test('TC-REPLAYOV-01 parses H2H and BRACKET events with fractional seconds', () {
      final replay = MatchReplay.fromJson(
        _replayJson(
          overlayEvents: <Object?>[
            _event('H2H', true, 12.345),
            _event('BRACKET', false, 40),
          ],
        ),
      );

      expect(replay.overlayEvents, hasLength(2));
      expect(replay.overlayEvents[0].kind, LiveOverlayKind.h2h);
      expect(replay.overlayEvents[0].visible, isTrue);
      expect(replay.overlayEvents[0].offsetSec, 12.345);
      expect(replay.overlayEvents[1].kind, LiveOverlayKind.bracket);
      expect(replay.overlayEvents[1].visible, isFalse);
      expect(replay.overlayEvents[1].offsetSec, 40.0);
    });

    test('TC-REPLAYOV-02 a missing, null or non-list field means no events', () {
      expect(
        MatchReplay.fromJson(_replayJson(withKey: false)).overlayEvents,
        isEmpty,
      );
      expect(
        MatchReplay.fromJson(_replayJson(overlayEvents: null)).overlayEvents,
        isEmpty,
      );
      expect(
        MatchReplay.fromJson(_replayJson(overlayEvents: 'oops')).overlayEvents,
        isEmpty,
      );
    });

    test('TC-REPLAYOV-03 drops malformed entries and keeps the valid ones', () {
      final replay = MatchReplay.fromJson(
        _replayJson(
          overlayEvents: <Object?>[
            _event('XYZ', true, 5),
            _event('H2H', 'yes', 6),
            _event('H2H', true, -1),
            _event('H2H', true, double.nan),
            _event('H2H', true, double.infinity),
            _event('H2H', true, '7'),
            _event('H2H', true, null),
            _event(null, true, 8),
            'not-a-map',
            _event('H2H', true, 20),
          ],
        ),
      );

      expect(replay.overlayEvents, hasLength(1));
      expect(replay.overlayEvents.single.offsetSec, 20.0);
    });

    test('TC-REPLAYOV-04 orders events by offset and the list is read only', () {
      final replay = MatchReplay.fromJson(
        _replayJson(
          overlayEvents: <Object?>[
            _event('BRACKET', true, 50),
            _event('H2H', true, 10),
            _event('H2H', false, 30),
          ],
        ),
      );

      expect(replay.overlayEvents.map((e) => e.offsetSec), [10.0, 30.0, 50.0]);
      expect(() => replay.overlayEvents.clear(), throwsUnsupportedError);
    });

    test('TC-REPLAYOV-04b events with the same offset keep the Backend order', () {
      // A recording gap lands several events on one offset; on then off must stay on then off.
      final replay = MatchReplay.fromJson(
        _replayJson(
          overlayEvents: <Object?>[
            _event('H2H', true, 20),
            _event('H2H', false, 20),
            _event('BRACKET', true, 20),
            _event('H2H', true, 5),
          ],
        ),
      );

      expect(
        replay.overlayEvents.map((e) => '${e.kind.name}:${e.visible}:${e.offsetSec}'),
        ['h2h:true:5.0', 'h2h:true:20.0', 'h2h:false:20.0', 'bracket:true:20.0'],
      );
    });
  });
}
