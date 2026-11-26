import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/services/manage_role_access.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_api_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
    );
    SharedPreferences.setMockInitialValues({});
  });

  ApiTournamentRepository repoFor(FakeApiAdapter adapter) =>
      ApiTournamentRepository(fakeDioClient(adapter));

  test(
    'TC-REF-MODE-APP-05 reads manageRole from the manage detail request',
    () async {
      final adapter = FakeApiAdapter({
        'GET /tournaments/t-1': const FakeReply(200, {
          'data': {'id': 't-1', 'manageRole': 'REFEREE'},
        }),
      });

      final role = await repoFor(adapter).getManageRole('t-1');

      expect(role, ManageRole.referee);
      expect(adapter.requests.single.query['manage'], 'true');
    },
  );

  test(
    'TC-REF-MODE-APP-06 a payload without manageRole is a manager',
    () async {
      final adapter = FakeApiAdapter({
        'GET /tournaments/t-1': const FakeReply(200, {
          'data': {'id': 't-1'},
        }),
      });

      expect(await repoFor(adapter).getManageRole('t-1'), ManageRole.manager);
    },
  );

  test(
    'TC-REF-MODE-APP-06c a body without a data object is an error, not a manager',
    () {
      final adapter = FakeApiAdapter({
        'GET /tournaments/t-1': const FakeReply(200, {'data': null}),
      });

      expect(
        repoFor(adapter).getManageRole('t-1'),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('TC-REF-MODE-APP-06b a 403 reaches the caller as a DioException', () {
    final adapter = FakeApiAdapter({
      'GET /tournaments/t-1': const FakeReply(403, {'message': 'Forbidden'}),
    });

    expect(
      repoFor(adapter).getManageRole('t-1'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          403,
        ),
      ),
    );
  });
}
