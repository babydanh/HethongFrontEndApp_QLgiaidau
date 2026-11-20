import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _json({
  Object? externalUrl,
  bool withKey = true,
  bool available = true,
  List<Object?> segments = const <Object?>[],
}) => <String, Object?>{
  'matchId': 'match-1',
  'available': available,
  'reason': available ? null : 'NO_RECORDING',
  'startedAt': '2026-11-06T10:00:00+07:00',
  'endedAt': '2026-11-06T10:30:00+07:00',
  'durationSec': 0,
  'segments': segments,
  if (withKey) 'externalUrl': externalUrl,
};

void main() {
  group('MatchReplay.externalUrl (TC-FBREPLAY-APP)', () {
    test('TC-FBREPLAY-APP-01 a replay with only a watch link is available', () {
      final replay = MatchReplay.fromJson(
        _json(externalUrl: 'https://www.facebook.com/watch/?v=1234567890'),
      );

      expect(replay.available, isTrue);
      expect(replay.segments, isEmpty);
      expect(
        replay.externalUrl,
        'https://www.facebook.com/watch/?v=1234567890',
      );
    });

    test('TC-FBREPLAY-APP-02 no link and no segments stays unavailable', () {
      final replay = MatchReplay.fromJson(_json(externalUrl: null));

      expect(replay.available, isFalse);
      expect(replay.externalUrl, isNull);
    });

    test(
      'TC-FBREPLAY-APP-03 an older Backend without the key still parses',
      () {
        final replay = MatchReplay.fromJson(_json(withKey: false));

        expect(replay.available, isFalse);
        expect(replay.externalUrl, isNull);
      },
    );

    test('TC-FBREPLAY-APP-04 blank or non-string link is ignored', () {
      expect(
        MatchReplay.fromJson(_json(externalUrl: '   ')).externalUrl,
        isNull,
      );
      expect(MatchReplay.fromJson(_json(externalUrl: 42)).externalUrl, isNull);
    });

    test(
      'TC-FBREPLAY-APP-05 backend says unavailable: the link does not revive it',
      () {
        final replay = MatchReplay.fromJson(
          _json(
            available: false,
            externalUrl: 'https://www.facebook.com/watch/?v=1234567890',
          ),
        );

        expect(replay.available, isFalse);
      },
    );
  });
}
