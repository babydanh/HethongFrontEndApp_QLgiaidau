import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/features/register/screens/doubles_registration_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Community Doubles Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'registration',
  'registrationMode': 'APPROVAL',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

void main() {
  testWidgets(
    'submit then reload restores pending status without fake division',
    (tester) async {
      dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
      SharedPreferences.setMockInitialValues({});
      final requests = <RequestOptions>[];
      final persistedParticipant = <String, dynamic>{};
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              if (options.method == 'POST') {
                persistedParticipant.addAll({
                  'id': 'participant-1',
                  'teamName': 'Saved Pair',
                  'teamStatus': 'PENDING_APPROVAL',
                  'members': <dynamic>[],
                  'isPaid': false,
                });
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'data': {
                        'participant': persistedParticipant,
                        'entryFee': 0,
                        'teamStatus': 'PENDING_APPROVAL',
                        'isWaitlisted': false,
                        'paymentEligible': false,
                      },
                    },
                  ),
                );
                return;
              }

              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': {
                      'registered': persistedParticipant.isNotEmpty,
                      'paymentEligible': false,
                      'participant': persistedParticipant,
                    },
                  },
                ),
              );
            },
          ),
        );
      final dioClient = DioClient(tokenManager: _NoTokenManager(), dio: dio);
      final result = await tester.runAsync(
        () => ApiTournamentRepository(dioClient).registerParticipant(
          tournamentId: 'tournament-1',
          teamName: 'Saved Pair',
          divisionId: 'default_tournament-1',
          doublesPairingMode: 'ORGANIZER',
        ),
      );
      expect(result?.teamStatus, 'PENDING_APPROVAL');
      expect(requests.single.method, 'POST');
      expect(requests.single.data, isNot(contains('divisionId')));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioClientProvider.overrideWithValue(dioClient),
            registerTournamentProvider((
              id: 'tournament-1',
              invite: null,
            )).overrideWith((ref) async => _tournament()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const DoublesRegistrationFlow(
              tournamentId: 'tournament-1',
              division: TournamentDivisionOption(
                id: 'default_tournament-1',
                name: 'Community Doubles Cup',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(DoublesRegistrationFlow));
      final l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.doublesRegStatusPendingApproval), findsOneWidget);
      expect(find.text(l10n.doublesRegSubmitNext), findsNothing);
      expect(requests, hasLength(2));
      expect(requests[1].method, 'GET');
      expect(requests[1].queryParameters, isNot(contains('divisionId')));
    },
  );
}
