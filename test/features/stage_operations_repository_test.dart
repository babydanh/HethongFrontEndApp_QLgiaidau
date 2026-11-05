import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_stage_operations_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Records the last request and replies with a fixed status/body.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.statusCode = 200, this.body = const {}});

  final int statusCode;
  final Object body;
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

ApiStageOperationsRepository _repoWith(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiStageOperationsRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test('TC-STAGEOPS-01 finalizeStage POSTs the finalize route with no body', () async {
    final adapter = _Adapter(body: {'data': {'message': 'ok'}});

    await _repoWith(adapter).finalizeStage('t-1', 's-1');

    expect(adapter.method, 'POST');
    expect(adapter.uri!.path, endsWith('/tournaments/t-1/stages/s-1/finalize'));
    expect(adapter.sentBody, isNull);
  });

  test('TC-STAGEOPS-02 advanceStandings POSTs divisionId and stageId and reads the counts', () async {
    final adapter = _Adapter(
      body: {
        'data': {
          'stageIds': ['s-2'],
          'totalMatches': 7,
        },
      },
    );

    final result = await _repoWith(
      adapter,
    ).advanceStandings('t-1', divisionId: 'd-1', stageId: 's-1');

    expect(adapter.method, 'POST');
    expect(adapter.uri!.path, endsWith('/tournaments/t-1/advance-standings'));
    expect(adapter.sentBody, {'divisionId': 'd-1', 'stageId': 's-1'});
    expect(result.stageCount, 1);
    expect(result.totalMatches, 7);
  });

  test('TC-STAGEOPS-03 createPlayoffMatch POSTs stageId and both participant ids', () async {
    final adapter = _Adapter(
      body: {
        'data': {'message': 'ok', 'id': 'm-9'},
      },
    );

    await _repoWith(adapter).createPlayoffMatch(
      't-1',
      stageId: 's-1',
      participant1Id: 'p-1',
      participant2Id: 'p-2',
    );

    expect(adapter.method, 'POST');
    expect(adapter.uri!.path, endsWith('/tournaments/t-1/playoff'));
    expect(adapter.sentBody, {
      'stageId': 's-1',
      'participant1Id': 'p-1',
      'participant2Id': 'p-2',
    });
  });

  test('TC-STAGEOPS-04 cancelDivisionBracket DELETEs the division bracket and reads the counts', () async {
    final adapter = _Adapter(
      body: {
        'data': {'cancelledStages': 2, 'cancelledMatches': 12},
      },
    );

    final result = await _repoWith(
      adapter,
    ).cancelDivisionBracket('t-1', 'd-1');

    expect(adapter.method, 'DELETE');
    expect(
      adapter.uri!.path,
      endsWith('/tournaments/t-1/bracket/divisions/d-1'),
    );
    expect(result.cancelledStages, 2);
    expect(result.cancelledMatches, 12);
  });

  test('TC-STAGEOPS-05 a 409 from the Backend surfaces as a DioException', () async {
    final adapter = _Adapter(
      statusCode: 409,
      body: {'statusCode': 409, 'message': 'conflict'},
    );

    await expectLater(
      _repoWith(adapter).finalizeStage('t-1', 's-1'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          409,
        ),
      ),
    );
  });

  test('TC-STAGEOPS-06 getStages GETs bracket?divisionId and counts matches per stage', () async {
    final adapter = _Adapter(
      body: {
        'data': {
          'stages': [
            {
              'id': 's-2',
              'name': 'Knockout',
              'type': 'single_elimination',
              'order': 2,
              'groups': [
                {
                  'matches': [
                    {'status': 'SCHEDULED'},
                  ],
                },
              ],
            },
            {
              'id': 's-1',
              'name': 'Groups',
              'type': 'ROUND_ROBIN',
              'order': 1,
              'roundConfig': {'tiebreakerMode': 'playoff'},
              'groups': [
                {
                  'matches': [
                    {'status': 'COMPLETED'},
                    {'status': 'SCHEDULED'},
                    {'status': 'ONGOING'},
                    {'status': 'SCHEDULED', 'bracketBranch': 'PLAYOFF'},
                    {'status': 'COMPLETED', 'isBye': true},
                    {'status': 'CANCELLED'},
                  ],
                },
              ],
            },
          ],
        },
      },
    );

    final stages = await _repoWith(adapter).getStages('t-1', divisionId: 'd-1');

    expect(adapter.method, 'GET');
    expect(adapter.uri!.path, endsWith('/tournaments/t-1/bracket'));
    expect(adapter.uri!.queryParameters['divisionId'], 'd-1');
    expect(stages.map((s) => s.id), ['s-1', 's-2']);
    final groups = stages.first;
    expect(groups.isRoundRobin, isTrue);
    expect(groups.playoffTiebreak, isTrue);
    expect(groups.totalMatches, 6);
    // SCHEDULED, ONGOING and the PLAYOFF SCHEDULED are open; byes/done are not.
    expect(groups.openMatches, 3);
    // The PLAYOFF match does not block advancing.
    expect(groups.openGroupMatches, 2);
    expect(groups.hasStartedMatch, isTrue);
    expect(stages.last.type, 'SINGLE_ELIMINATION');
    expect(stages.last.hasStartedMatch, isFalse);
  });
}
