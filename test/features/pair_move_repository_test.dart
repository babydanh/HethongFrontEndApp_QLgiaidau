import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_pair_move_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/pair_move_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Records the request the repository really builds and answers it with
/// [status] / [body] (the response envelope is the caller's job).
class _Backend {
  _Backend(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final response = Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: body,
          );
          if (status >= 400) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          handler.resolve(response);
        },
      ),
    );
  }

  final List<RequestOptions> requests = <RequestOptions>[];
  int status = 200;
  Object? body;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://api.example.test/api/v1';
  late _Backend backend;
  late ApiPairMoveRepository repository;

  setUpAll(() => dotenv.loadFromString(envString: 'API_BASE_URL=$baseUrl'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    repository = ApiPairMoveRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );
    backend = _Backend(dio);
  });

  group('pairMemberKey', () {
    test(
      'TC-PAIRMOVE-01: account key wins, guest key is trimmed and lowercased',
      () {
        expect(
          pairMemberKey(userId: 'u-1', fullName: 'Ignored', email: 'a@b.c'),
          'account:u-1',
        );
        expect(
          pairMemberKey(fullName: '  Nguyễn A ', email: ' A@Mail.COM '),
          'guest:Nguyễn A|a@mail.com',
        );
        expect(pairMemberKey(fullName: 'Khách'), 'guest:Khách|');
      },
    );
  });

  group('movePairMember', () {
    test(
      'TC-PAIRMOVE-02: posts source, slot target and expected keys',
      () async {
        backend.body = {
          'data': {
            'participantIds': ['p-1', 'p-2'],
          },
        };

        final ids = await repository.movePairMember(
          't-1',
          const PairMoveRequest(
            divisionId: 'div-1',
            sourceParticipantId: 'p-1',
            sourceSlot: 2,
            target: PairMoveTarget.slot('p-2', 1),
            expectedSource: 'account:u-1',
            expectedTarget: 'guest:Khách|',
          ),
        );

        final request = backend.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/tournaments/t-1/pairing/move');
        expect(request.data, {
          'divisionId': 'div-1',
          'source': {'participantId': 'p-1', 'slot': 2},
          'target': {'participantId': 'p-2', 'slot': 1},
          'expected': {'source': 'account:u-1', 'target': 'guest:Khách|'},
        });
        expect(ids, ['p-1', 'p-2']);
      },
    );

    test(
      'TC-PAIRMOVE-03: tray target sends tray true and a null expected target',
      () async {
        backend.body = {
          'data': {
            'participantIds': ['p-1', 'p-9'],
          },
        };

        await repository.movePairMember(
          't-1',
          const PairMoveRequest(
            divisionId: 'div-1',
            sourceParticipantId: 'p-1',
            sourceSlot: 1,
            target: PairMoveTarget.tray(),
            expectedSource: 'account:u-1',
          ),
        );

        final data = backend.requests.single.data as Map<String, dynamic>;
        expect(data['target'], {'tray': true});
        expect(data['expected'], {'source': 'account:u-1', 'target': null});
      },
    );

    test(
      'TC-PAIRMOVE-04: a 409 surfaces as a DioException with that status',
      () async {
        backend
          ..status = 409
          ..body = {'message': 'Danh sách vừa thay đổi, tải lại'};

        await expectLater(
          repository.movePairMember(
            't-1',
            const PairMoveRequest(
              divisionId: 'div-1',
              sourceParticipantId: 'p-1',
              sourceSlot: 1,
              target: PairMoveTarget.tray(),
              expectedSource: 'account:u-1',
            ),
          ),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              409,
            ),
          ),
        );
      },
    );
  });

  group('removePairMember', () {
    test(
      'TC-PAIRMOVE-05: posts slot and expectedKey and reads both ids',
      () async {
        backend.body = {
          'data': {
            'remainingParticipantId': 'p-keep',
            'removedParticipantId': 'p-gone',
          },
        };

        final result = await repository.removePairMember(
          't-1',
          participantId: 'p-1',
          slot: 2,
          expectedKey: 'account:u-2',
        );

        final request = backend.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/tournaments/t-1/pairing/p-1/remove-member');
        expect(request.data, {'slot': 2, 'expectedKey': 'account:u-2'});
        expect(result.remainingParticipantId, 'p-keep');
        expect(result.removedParticipantId, 'p-gone');
      },
    );
  });
}
