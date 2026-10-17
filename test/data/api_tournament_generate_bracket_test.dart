import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/core/utils/bracket_generation_summary.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Ghi lại request gửi đi (method, path, body JSON) và trả về một response cố định.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Object body;
  String? method;
  String? path;
  Map<String, dynamic>? sentBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
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

ApiTournamentRepository _repoWith(_CapturingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiTournamentRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('ITournamentRepository.generateBracket', () {
    test(
      'POSTs generate-bracket with divisionId, RANDOM and allowReset false',
      () async {
        final adapter = _CapturingAdapter(
          statusCode: 200,
          body: {
            'data': {
              'unpairedNames': ['An'],
              'autoPaired': [
                {
                  'participantId': 'p1',
                  'memberNames': ['Bình', 'Cường'],
                },
              ],
            },
          },
        );

        final result = await _repoWith(adapter).generateBracket(
          't-1',
          divisionId: 'd-1',
          seedingType: 'RANDOM',
        );

        expect(adapter.method, 'POST');
        expect(adapter.path, endsWith('/tournaments/t-1/generate-bracket'));
        expect(adapter.sentBody, {
          'divisionId': 'd-1',
          'seedingType': 'RANDOM',
          'allowReset': false,
        });
        expect(bracketUnpairedNames(result), ['An']);
        expect(bracketAutoPairedLabels(result), ['Bình & Cường']);
      },
    );

    test(
      'omits divisionId for multi-division tournaments and tolerates missing fields',
      () async {
        final adapter = _CapturingAdapter(statusCode: 200, body: {});

        final result = await _repoWith(
          adapter,
        ).generateBracket('t-1', seedingType: 'RANDOM');

        expect(adapter.sentBody, {
          'seedingType': 'RANDOM',
          'allowReset': false,
        });
        expect(bracketUnpairedNames(result), isEmpty);
        expect(bracketAutoPairedLabels(result), isEmpty);
      },
    );

    test('surfaces a 400 from the server as DioException', () async {
      final adapter = _CapturingAdapter(
        statusCode: 400,
        body: {'message': 'Vui lòng chọn nội dung để tạo sơ đồ.'},
      );

      await expectLater(
        _repoWith(adapter).generateBracket('t-1', seedingType: 'RANDOM'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
