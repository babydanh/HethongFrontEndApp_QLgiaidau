import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _replayJson({Object? scoreEvents, bool withKey = true}) =>
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
      if (withKey) 'scoreEvents': scoreEvents,
    };

Map<String, Object?> _event(
  Object? offsetSec,
  Object? p1,
  Object? p2, [
  Object? details = const <String, Object?>{},
]) => <String, Object?>{
  'offsetSec': offsetSec,
  'p1SetsWon': p1,
  'p2SetsWon': p2,
  'scoreDetails': details,
};

void main() {
  group('MatchReplay.scoreEvents (TC-SCOREREPLAY-APP)', () {
    test('TC-SCOREREPLAY-APP-01 parses offset, sets won and scoreDetails', () {
      final replay = MatchReplay.fromJson(
        _replayJson(
          scoreEvents: <Object?>[
            _event(12.345, 1, 0, <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{
                  'team1Score': 11,
                  'team2Score': 7,
                  'isFinished': true,
                },
              ],
            }),
          ],
        ),
      );

      expect(replay.scoreEvents, hasLength(1));
      final event = replay.scoreEvents.single;
      expect(event.offsetSec, 12.345);
      expect(event.p1SetsWon, 1);
      expect(event.p2SetsWon, 0);
      final sets = event.scoreDetails['sets'] as List;
      expect((sets.single as Map)['team1Score'], 11);
    });

    test('TC-SCOREREPLAY-APP-02 a missing, null or non-list field means no events', () {
      expect(
        MatchReplay.fromJson(_replayJson(withKey: false)).scoreEvents,
        isEmpty,
      );
      expect(
        MatchReplay.fromJson(_replayJson(scoreEvents: null)).scoreEvents,
        isEmpty,
      );
      expect(
        MatchReplay.fromJson(_replayJson(scoreEvents: 'oops')).scoreEvents,
        isEmpty,
      );
      expect(
        MatchReplay.fromJson(_replayJson(scoreEvents: <Object?>[])).scoreEvents,
        isEmpty,
      );
    });

    test('TC-SCOREREPLAY-APP-03 drops malformed entries and keeps the valid ones', () {
      final replay = MatchReplay.fromJson(
        _replayJson(
          scoreEvents: <Object?>[
            _event(-1, 0, 0),
            _event(double.nan, 0, 0),
            _event(double.infinity, 0, 0),
            _event('7', 0, 0),
            _event(null, 0, 0),
            _event(5, 1.5, 0),
            _event(5, '1', 0),
            _event(5, 0, null),
            _event(5, -1, 0),
            _event(5, 0, 0, 'not-an-object'),
            _event(5, 0, 0, null),
            'not-a-map',
            _event(20, 2, 1),
          ],
        ),
      );

      expect(replay.scoreEvents, hasLength(1));
      expect(replay.scoreEvents.single.offsetSec, 20.0);
      expect(replay.scoreEvents.single.p1SetsWon, 2);
    });

    test('TC-SCOREREPLAY-APP-04 orders by offset, ties keep Backend order, list is read only', () {
      final replay = MatchReplay.fromJson(
        _replayJson(
          scoreEvents: <Object?>[
            _event(50, 2, 0),
            _event(10, 0, 0),
            _event(30, 1, 0),
            _event(30, 1, 1),
          ],
        ),
      );

      expect(
        replay.scoreEvents.map((e) => '${e.offsetSec}:${e.p1SetsWon}-${e.p2SetsWon}'),
        ['10.0:0-0', '30.0:1-0', '30.0:1-1', '50.0:2-0'],
      );
      expect(() => replay.scoreEvents.clear(), throwsUnsupportedError);
      expect(
        () => replay.scoreEvents.first.scoreDetails['x'] = 1,
        throwsUnsupportedError,
      );
    });
  });
}
