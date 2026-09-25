import 'dart:async';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_management_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late ApiTournamentManagementRepository repository;
  final requests = <RequestOptions>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    requests.clear();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    repository = ApiTournamentManagementRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final responseData = options.path.endsWith('/venues')
              ? <String, dynamic>{
                  'data': [
                    {'id': 'venue-1', 'name': 'Court Hall'},
                  ],
                }
              : <String, dynamic>{
                  'data': {'success': true},
                };
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: responseData,
            ),
          );
        },
      ),
    );
  });

  test('venue read unwraps envelope and targets canonical route', () async {
    final venues = await repository.getVenues('tournament-1');

    expect(venues, [
      {'id': 'venue-1', 'name': 'Court Hall'},
    ]);
    expect(requests.single.method, 'GET');
    expect(requests.single.path, '/tournaments/tournament-1/venues');
  });

  test(
    'payout sends exact backend keys without emitting bank data to print',
    () async {
      final printed = <String>[];
      await runZoned(
        () => repository.requestPayout(
          tournamentId: 'tournament-1',
          bankName: 'Example Bank',
          bankAccountNumber: 'sensitive-account-number',
          bankAccountName: 'Sensitive Account Name',
          amountRequested: 25000,
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => printed.add(line),
        ),
      );

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/payments/payout');
      expect(request.data, {
        'tournamentId': 'tournament-1',
        'bankName': 'Example Bank',
        'bankAccountNumber': 'sensitive-account-number',
        'bankAccountName': 'Sensitive Account Name',
        'amountRequested': 25000,
      });
      expect(printed.join('\n'), isNot(contains('sensitive-account-number')));
      expect(printed.join('\n'), isNot(contains('Sensitive Account Name')));
    },
  );

  test(
    'participant approval uses canonical status route and payload',
    () async {
      await repository.updateParticipantStatus(
        'tournament-1',
        'participant-1',
        'COMPLETE',
      );

      expect(requests.single.method, 'PATCH');
      expect(
        requests.single.path,
        '/tournaments/tournament-1/participants/participant-1',
      );
      expect(requests.single.data, {'status': 'COMPLETE'});
    },
  );

  test('division creation omits the web client-only endDate field', () async {
    await repository.createDivision('tournament-1', {
      'name': 'Open Doubles',
      'matchType': 'DOUBLES',
      'endDate': '2026-12-31',
    });

    expect(requests.single.method, 'POST');
    expect(requests.single.path, '/tournaments/tournament-1/divisions');
    expect(requests.single.data, {
      'name': 'Open Doubles',
      'matchType': 'DOUBLES',
    });
  });
}
