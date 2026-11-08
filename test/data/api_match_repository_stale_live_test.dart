import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _SilentSocketService extends Fake implements MatchSocketService {}

/// Returns one fixed `/matches` page.
class _PageAdapter implements HttpClientAdapter {
  _PageAdapter(this.matches);

  final List<Map<String, dynamic>> matches;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'data': matches,
        'meta': {'hasMore': false, 'nextCursor': null},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiMatchRepository _repositoryWith(List<Map<String, dynamic>> matches) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = _PageAdapter(matches);
  return ApiMatchRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
    _SilentSocketService(),
  );
}

Map<String, dynamic> _match(
  String id, {
  Map<String, dynamic> extra = const {},
}) => {
  'id': id,
  'tournamentId': 'tournament-1',
  'status': 'ONGOING',
  'roundNumber': 1,
  'matchOrder': 3,
  'updatedAt': '2026-10-19T09:38:56.232Z',
  ...extra,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test(
    'TC-SLM-APP-09 API parser keeps isStaleLive and lastActivityAt, older payload reads false/null',
    () async {
      final repository = _repositoryWith([
        _match(
          'm-1',
          extra: {
            'isStaleLive': true,
            'lastActivityAt': '2026-10-19T01:00:00.000Z',
          },
        ),
        _match('m-2'),
      ]);

      final matches = await repository.getAllByTournament('tournament-1');

      expect(matches.map((m) => m.isStaleLive), [true, false]);
      expect(
        matches.first.lastActivityAt!.isAtSameMomentAs(
          DateTime.utc(2026, 10, 19, 1),
        ),
        isTrue,
      );
      expect(matches.last.lastActivityAt, isNull);
    },
  );
}
