import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Records the last request and replies with a fixed status/body.
/// With [networkError] set it fails like a dropped connection (no response).
class _Adapter implements HttpClientAdapter {
  _Adapter({this.statusCode = 200, this.body = const {}, this.networkError});

  final int statusCode;
  final Object body;
  final bool? networkError;
  String? method;
  Uri? uri;
  Map<String, dynamic>? sentBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    uri = options.uri;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        <int>[],
        (acc, chunk) => acc..addAll(chunk),
      );
      if (bytes.isNotEmpty) {
        sentBody = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      }
    }
    if (networkError == true) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiTournamentRepository _repoWith(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiTournamentRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
  );
}

const _draft = SwissRoundDraftRequest(
  divisionId: 'd-1',
  stageId: 's-1',
  pairs: [(participant1Id: 'p1', participant2Id: 'p2')],
  byeParticipantId: 'p3',
);

Future<SwissApiException> _caught(Future<Object?> call) async {
  try {
    await call;
  } on SwissApiException catch (e) {
    return e;
  }
  fail('expected SwissApiException');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('swissPreview', () {
    test('POSTs divisionId and stageId and unwraps response.data', () async {
      final adapter = _Adapter(
        body: {
          'data': {
            'roundNumber': 2,
            'totalRounds': 4,
            'pairs': [
              {'board': 1, 'participant1Id': 'p1', 'participant2Id': 'p2'},
            ],
            'byeParticipantId': 'p3',
            'sitOutParticipantIds': <String>[],
            'participants': [
              {
                'id': 'p1',
                'teamName': 'An',
                'logoUrl': null,
                'seed': 1,
                'totalPoints': 3,
                'buchholz': 0,
                'hadBye': false,
              },
            ],
            'warnings': [
              {
                'type': 'REMATCH',
                'participantIds': ['p1', 'p2'],
                'round': 1,
              },
            ],
          },
        },
      );

      final preview = await _repoWith(
        adapter,
      ).swissPreview('t-1', divisionId: 'd-1', stageId: 's-1');

      expect(adapter.method, 'POST');
      expect(adapter.uri!.path, endsWith('/tournaments/t-1/swiss/preview'));
      expect(adapter.sentBody, {'divisionId': 'd-1', 'stageId': 's-1'});
      expect(preview.roundNumber, 2);
      expect(preview.pairs.single.participant2Id, 'p2');
      expect(preview.byeParticipantId, 'p3');
      expect(preview.warnings.single.type, 'REMATCH');
    });

    test('omits stageId when null', () async {
      final adapter = _Adapter(body: {'data': {}});
      await _repoWith(adapter).swissPreview('t-1', divisionId: 'd-1');
      expect(adapter.sentBody, {'divisionId': 'd-1'});
    });

    test('maps 409 SWISS_ROUND_INCOMPLETE to SwissApiException', () async {
      final adapter = _Adapter(
        statusCode: 409,
        body: {'statusCode': 409, 'code': 'SWISS_ROUND_INCOMPLETE'},
      );
      final e = await _caught(
        _repoWith(adapter).swissPreview('t-1', divisionId: 'd-1'),
      );
      expect(e.status, 409);
      expect(e.code, 'SWISS_ROUND_INCOMPLETE');
    });
  });

  group('swissValidate', () {
    test('POSTs the draft and parses valid/errors/warnings', () async {
      final adapter = _Adapter(
        body: {
          'data': {
            'valid': false,
            'errors': [
              {
                'code': 'DUPLICATE_PARTICIPANT',
                'participantIds': ['p1'],
              },
            ],
            'warnings': <Object>[],
          },
        },
      );

      final result = await _repoWith(adapter).swissValidate('t-1', _draft);

      expect(adapter.method, 'POST');
      expect(adapter.uri!.path, endsWith('/tournaments/t-1/swiss/validate'));
      expect(adapter.sentBody, _draft.toJson());
      expect(adapter.sentBody!.containsKey('confirmWarnings'), isFalse);
      expect(result.valid, isFalse);
      expect(result.errors.single.code, 'DUPLICATE_PARTICIPANT');
    });
  });

  group('swissNextRound', () {
    test('POSTs without confirmWarnings by default', () async {
      final adapter = _Adapter(
        statusCode: 201,
        body: {
          'data': {
            'roundNumber': 3,
            'matchIds': ['m1', 'm2'],
          },
        },
      );

      final result = await _repoWith(adapter).swissNextRound('t-1', _draft);

      expect(adapter.method, 'POST');
      expect(adapter.uri!.path, endsWith('/tournaments/t-1/swiss/next-round'));
      expect(adapter.sentBody, _draft.toJson());
      expect(adapter.sentBody!.containsKey('confirmWarnings'), isFalse);
      expect(result.roundNumber, 3);
      expect(result.matchIds, ['m1', 'm2']);
    });

    test('sends confirmWarnings true when asked', () async {
      final adapter = _Adapter(
        statusCode: 201,
        body: {
          'data': {'roundNumber': 3, 'matchIds': <String>[]},
        },
      );
      await _repoWith(
        adapter,
      ).swissNextRound('t-1', _draft, confirmWarnings: true);
      expect(adapter.sentBody!['confirmWarnings'], isTrue);
    });

    test('409 SWISS_WARNINGS_UNCONFIRMED carries the warnings', () async {
      final adapter = _Adapter(
        statusCode: 409,
        body: {
          'statusCode': 409,
          'code': 'SWISS_WARNINGS_UNCONFIRMED',
          'warnings': [
            {
              'type': 'SCORE_GAP',
              'participantIds': ['p1', 'p2'],
              'gap': 4,
            },
          ],
        },
      );
      final e = await _caught(_repoWith(adapter).swissNextRound('t-1', _draft));
      expect(e.status, 409);
      expect(e.code, 'SWISS_WARNINGS_UNCONFIRMED');
      expect(e.warnings.single.type, 'SCORE_GAP');
      expect(e.warnings.single.gap, 4);
    });

    test('409 SWISS_ROUND_EXISTS', () async {
      final adapter = _Adapter(
        statusCode: 409,
        body: {'statusCode': 409, 'code': 'SWISS_ROUND_EXISTS'},
      );
      final e = await _caught(_repoWith(adapter).swissNextRound('t-1', _draft));
      expect(e.status, 409);
      expect(e.code, 'SWISS_ROUND_EXISTS');
    });

    test('400 SWISS_INVALID_PAIRING', () async {
      final adapter = _Adapter(
        statusCode: 400,
        body: {'statusCode': 400, 'code': 'SWISS_INVALID_PAIRING'},
      );
      final e = await _caught(_repoWith(adapter).swissNextRound('t-1', _draft));
      expect(e.status, 400);
      expect(e.code, 'SWISS_INVALID_PAIRING');
    });

    test('a dropped connection becomes SwissApiException without status', () async {
      final adapter = _Adapter(networkError: true);
      final e = await _caught(_repoWith(adapter).swissNextRound('t-1', _draft));
      expect(e.status, isNull);
      expect(e.code, isNull);
    });
  });

  group('swissUndoRound', () {
    test('POSTs to rounds/:round/undo and returns the undone round', () async {
      final adapter = _Adapter(
        body: {
          'data': {'roundNumber': 3},
        },
      );

      final round = await _repoWith(
        adapter,
      ).swissUndoRound('t-1', 3, divisionId: 'd-1', stageId: 's-1');

      expect(adapter.method, 'POST');
      expect(
        adapter.uri!.path,
        endsWith('/tournaments/t-1/swiss/rounds/3/undo'),
      );
      expect(adapter.sentBody, {'divisionId': 'd-1', 'stageId': 's-1'});
      expect(round, 3);
    });

    test('409 SWISS_ROUND_STARTED', () async {
      final adapter = _Adapter(
        statusCode: 409,
        body: {'statusCode': 409, 'code': 'SWISS_ROUND_STARTED'},
      );
      final e = await _caught(
        _repoWith(adapter).swissUndoRound('t-1', 3, divisionId: 'd-1'),
      );
      expect(e.code, 'SWISS_ROUND_STARTED');
    });
  });

  group('getSwissStage', () {
    test('reads the first SWISS stage with its roundConfig', () async {
      final adapter = _Adapter(
        body: {
          'data': {
            'stages': [
              {'id': 'rr', 'type': 'ROUND_ROBIN'},
              {
                'id': 's-1',
                'type': 'SWISS',
                'roundConfig': {
                  'swiss': {
                    'totalRounds': 5,
                    'tiebreakOrder': ['BUCHHOLZ', 'SEED'],
                    'firstRoundPairing': 'RANDOM',
                  },
                },
              },
            ],
          },
        },
      );

      final stage = await _repoWith(
        adapter,
      ).getSwissStage('t-1', divisionId: 'd-1');

      expect(adapter.method, 'GET');
      expect(adapter.uri!.path, endsWith('/tournaments/t-1/bracket'));
      expect(adapter.uri!.queryParameters, {'divisionId': 'd-1'});
      expect(stage!.stageId, 's-1');
      expect(stage.config.totalRounds, 5);
      expect(stage.config.tiebreakOrder, [
        SwissTiebreak.buchholz,
        SwissTiebreak.seed,
      ]);
      expect(stage.config.firstRoundPairing, 'RANDOM');
    });

    test('fills defaults when roundConfig.swiss is missing', () async {
      final adapter = _Adapter(
        body: {
          'data': {
            'stages': [
              {'id': 's-1', 'type': 'swiss'},
            ],
          },
        },
      );
      final stage = await _repoWith(adapter).getSwissStage('t-1');
      expect(stage!.config.tiebreakOrder, SwissConfig.defaultTiebreakOrder);
      expect(stage.config.firstRoundPairing, 'SEED');
    });

    test('returns null when there is no SWISS stage', () async {
      final adapter = _Adapter(
        body: {
          'data': {
            'stages': [
              {'id': 'rr', 'type': 'ROUND_ROBIN'},
            ],
          },
        },
      );
      expect(await _repoWith(adapter).getSwissStage('t-1'), isNull);
    });

    test('returns null for an empty payload', () async {
      expect(await _repoWith(_Adapter(body: {})).getSwissStage('t-1'), isNull);
    });
  });

  group('updateStageRoundConfig', () {
    test('PATCHes roundConfig to /stages/:stageId', () async {
      final adapter = _Adapter(body: {'data': {}});

      await _repoWith(adapter).updateStageRoundConfig('t-1', 's-1', {
        'swiss': {'totalRounds': 5},
      });

      expect(adapter.method, 'PATCH');
      expect(adapter.uri!.path, endsWith('/tournaments/t-1/stages/s-1'));
      expect(adapter.sentBody, {
        'roundConfig': {
          'swiss': {'totalRounds': 5},
        },
      });
    });
  });
}
