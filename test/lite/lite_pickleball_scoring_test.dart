import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_api_adapter.dart';

class _UnusedMatchSocketService implements MatchSocketService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _sideOutConfig = {
  'kind': 'PICKLEBALL_SIDE_OUT',
  'scoringModel': 'PICKLEBALL_SIDE_OUT',
};
const _rallyConfig = {
  'kind': 'PICKLEBALL_RALLY',
  'scoringModel': 'RALLY_POINT_SET',
};

Map<String, dynamic> _matchJson({
  Map<String, dynamic>? matchConfig,
  String tournamentModel = 'RALLY_POINT_SET',
}) => {
  'id': 'match-1',
  'tournamentId': 'tournament-1',
  'status': 'LIVE',
  'sportRules': {
    'mode': 'LITE',
    'kind': 'PICKLEBALL',
    'scoringModel': tournamentModel,
  },
  'matchConfig': ?matchConfig,
};

ApiMatchRepository _repository(FakeApiAdapter adapter) =>
    ApiMatchRepository(fakeDioClient(adapter), _UnusedMatchSocketService());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('TC-LMT-APP-01 matchConfig overrides the tournament scoring', () {
    test('side-out match config beats a rally tournament, mode LITE stays', () {
      final rules = withMatchConfigScoring({
        'mode': 'LITE',
        'kind': 'PICKLEBALL',
        'scoringModel': 'RALLY_POINT_SET',
      }, _sideOutConfig);

      expect(
        resolveSportConfig(rules).scoringModel,
        SportScoringModel.pickleballSideOut,
      );
      expect(isLiteScoringMode(sportRules: rules), isTrue);
    });

    test('rally match config beats a side-out tournament', () {
      final rules = withMatchConfigScoring({
        'mode': 'LITE',
        'kind': 'PICKLEBALL',
        'scoringModel': 'PICKLEBALL_SIDE_OUT',
      }, _rallyConfig);

      expect(
        resolveSportConfig(rules).scoringModel,
        SportScoringModel.rallyPointSet,
      );
    });

    test('no kind / scoringModel (duration only) leaves the rules alone', () {
      final rules = {'mode': 'LITE'};
      expect(
        withMatchConfigScoring(rules, {'durationMinutes': 30}),
        same(rules),
      );
      expect(withMatchConfigScoring(null, null), isNull);
    });

    test('MatchModel.fromJson reads the match config on top of the rules', () {
      final match = MatchModel.fromJson(
        _matchJson(matchConfig: _sideOutConfig),
        'match-1',
      );

      expect(
        resolveSportConfig(match.sportRules).scoringModel,
        SportScoringModel.pickleballSideOut,
      );
      expect(match.sportRules?['mode'], 'LITE');
    });

    test('a socket payload without matchConfig keeps the previous flag', () {
      final merged = carryMatchConfigScoring(
        incoming: {'mode': 'LITE', 'kind': 'PICKLEBALL'},
        previous: {
          'mode': 'LITE',
          'kind': 'PICKLEBALL_SIDE_OUT',
          'scoringModel': 'PICKLEBALL_SIDE_OUT',
        },
      );

      expect(
        resolveSportConfig(merged).scoringModel,
        SportScoringModel.pickleballSideOut,
      );
      expect(isLiteScoringMode(sportRules: merged), isTrue);
    });
  });

  group('TC-LMT-APP-02 setPickleballScoring', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('PATCHes the scoring and parses the saved match config', () async {
      final adapter = FakeApiAdapter({
        'PATCH /matches/match-1/pickleball-scoring': FakeReply(200, {
          'data': _matchJson(matchConfig: _sideOutConfig),
        }),
      });

      final match = await _repository(
        adapter,
      ).setPickleballScoring('match-1', SportScoringModel.pickleballSideOut);

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.body, {'scoring': 'SIDE_OUT'});
      expect(
        resolveSportConfig(match.sportRules).scoringModel,
        SportScoringModel.pickleballSideOut,
      );
    });

    test('rally sends RALLY', () async {
      final adapter = FakeApiAdapter({
        'PATCH /matches/match-1/pickleball-scoring': FakeReply(200, {
          'data': _matchJson(
            matchConfig: _rallyConfig,
            tournamentModel: 'PICKLEBALL_SIDE_OUT',
          ),
        }),
      });

      await _repository(
        adapter,
      ).setPickleballScoring('match-1', SportScoringModel.rallyPointSet);

      expect(adapter.requests.single.body, {'scoring': 'RALLY'});
    });

    test('throws the backend message when the server refuses', () async {
      final adapter = FakeApiAdapter({
        'PATCH /matches/match-1/pickleball-scoring': const FakeReply(400, {
          'message': 'Trận đã có điểm',
        }),
      });

      await expectLater(
        _repository(
          adapter,
        ).setPickleballScoring('match-1', SportScoringModel.rallyPointSet),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Trận đã có điểm'),
          ),
        ),
      );
    });
  });
}
