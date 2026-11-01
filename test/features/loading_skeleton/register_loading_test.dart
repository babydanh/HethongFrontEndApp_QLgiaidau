import 'dart:async';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/register/screens/doubles_registration_screen.dart';
import 'package:app_quanly_giaidau/features/register/screens/tournament_register_screen.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loading_harness.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _OfflineSocketService extends MatchSocketService {
  _OfflineSocketService() : super(tokenManager: _NoTokenManager());

  @override
  Future<void> connect(String? matchId, {bool joinMatch = true}) async {}

  @override
  void joinTournament(String tournamentId) {}
}

class _AuthenticatedUser extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

/// Only `getDivisions` is reached by the screen in these states.
class _HangingDivisionsRepository extends Fake
    implements ITournamentRepository {
  @override
  Future<List<TournamentDivisionOption>> getDivisions(String tournamentId) =>
      Completer<List<TournamentDivisionOption>>().future;
}

final _tournament = Tournament(
  id: 'tournament-1',
  name: 'Community Doubles Cup',
  sport: 'pickleball',
  format: 'doubles',
  bracketType: 'single_elimination',
  status: 'registration',
  adminToken: 'a',
  refereeToken: 'r',
  viewerToken: 'v',
  creatorId: 'creator',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Dio whose `my-registrations` answers at once with no registrations.
final _answeringDioOverride = dioClientProvider.overrideWithValue(
  DioClient(
    tokenManager: _NoTokenManager(),
    dio: Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {'data': <dynamic>[]},
            ),
          ),
        ),
      ),
  ),
);

void _expectSkeletonNotSpinner(WidgetTester tester) {
  expect(find.byType(SkeletonScope), findsWidgets);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
    SharedPreferences.setMockInitialValues({});
  });

  final common = <Override>[
    matchSocketServiceProvider.overrideWithValue(_OfflineSocketService()),
    authProvider.overrideWith(_AuthenticatedUser.new),
  ];
  final pendingTournament = registerTournamentProvider.overrideWith(
    (ref, params) => Completer<Tournament?>().future,
  );
  final loadedTournament = registerTournamentProvider.overrideWith(
    (ref, params) async => _tournament,
  );

  testWidgets('register screen: tournament loading shows skeleton', (
    tester,
  ) async {
    await pumpLoading(
      tester,
      const TournamentRegisterScreen(tournamentId: 'tournament-1'),
      overrides: [...common, pendingDioOverride, pendingTournament],
    );
    _expectSkeletonNotSpinner(tester);
  });

  testWidgets('register screen: checking existing registration shows skeleton', (
    tester,
  ) async {
    await pumpLoading(
      tester,
      const TournamentRegisterScreen(tournamentId: 'tournament-1'),
      overrides: [...common, pendingDioOverride, loadedTournament],
    );
    _expectSkeletonNotSpinner(tester);
  });

  testWidgets('register screen: divisions loading shows skeleton', (
    tester,
  ) async {
    await pumpLoading(
      tester,
      const TournamentRegisterScreen(tournamentId: 'tournament-1'),
      overrides: [
        ...common,
        _answeringDioOverride,
        loadedTournament,
        tournamentRepositoryProvider.overrideWithValue(
          _HangingDivisionsRepository(),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 300));
    _expectSkeletonNotSpinner(tester);
  });

  testWidgets('doubles registration: tournament loading shows skeleton', (
    tester,
  ) async {
    await pumpLoading(
      tester,
      const DoublesRegistrationFlow(
        tournamentId: 'tournament-1',
        division: TournamentDivisionOption(id: 'd1', name: 'Doubles'),
      ),
      overrides: [...common, pendingDioOverride, pendingTournament],
    );
    _expectSkeletonNotSpinner(tester);
  });
}
