import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/user_repository.dart';
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

class _FakeUserRepo implements IUserRepository {
  @override
  Future<List<UserSearchResult>> searchUsers(String query) async => const [
    UserSearchResult(id: 'user-42', fullName: 'Nguyen Van Partner'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Community Doubles Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'doublesPairingMode': 'SELF',
  'bracketType': 'single_elimination',
  'status': 'registration',
  'registrationMode': 'APPROVAL',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

DioClient _client(List<RequestOptions> requests) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final isPost = options.method == 'POST';
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': isPost
                    ? {
                        'participant': {'id': 'p-1', 'teamName': 'Doi A'},
                        'entryFee': 0,
                        'teamStatus': 'PENDING_PARTNER',
                        'paymentEligible': false,
                      }
                    : {'registered': false},
              },
            ),
          );
        },
      ),
    );
  return DioClient(tokenManager: _NoTokenManager(), dio: dio);
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
    SharedPreferences.setMockInitialValues({});
  });

  test('UserSearchResult parses a response without email', () {
    final u = UserSearchResult.fromJson({
      'id': 'u1',
      'fullName': 'An',
      'avatarUrl': 'https://x/a.png',
    });
    expect(u.id, 'u1');
    expect(u.fullName, 'An');
    expect(u.avatarUrl, 'https://x/a.png');
  });

  test('registerParticipant sends partnerUserId in the body', () async {
    final requests = <RequestOptions>[];
    await ApiTournamentRepository(_client(requests)).registerParticipant(
      tournamentId: 'tournament-1',
      teamName: 'Doi A',
      partnerUserId: 'user-42',
    );
    final body = requests.single.data as Map;
    expect(body['partnerUserId'], 'user-42');
    expect(body, isNot(contains('partnerEmailOrPhone')));
  });

  test('registerParticipant keeps partnerEmailOrPhone for typed contact',
      () async {
    final requests = <RequestOptions>[];
    await ApiTournamentRepository(_client(requests)).registerParticipant(
      tournamentId: 'tournament-1',
      teamName: 'Doi A',
      partnerEmailOrPhone: ' a@b.vn ',
    );
    final body = requests.single.data as Map;
    expect(body['partnerEmailOrPhone'], 'a@b.vn');
    expect(body, isNot(contains('partnerUserId')));
  });

  testWidgets('doubles screen registers with partnerUserId of picked user',
      (tester) async {
    final requests = <RequestOptions>[];
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          dioClientProvider.overrideWithValue(_client(requests)),
          userRepositoryProvider.overrideWithValue(_FakeUserRepo()),
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
    final l10n = AppLocalizations.of(
      tester.element(find.byType(DoublesRegistrationFlow)),
    )!;

    await tester.tap(find.text(l10n.doublesRegSelfPairing));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      'Doi A',
    );
    await tester.tap(find.text(l10n.doublesRegInviteLater));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(1),
      'Nguyen',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nguyen Van Partner'));
    await tester.pump();
    await tester.tap(find.text(l10n.doublesRegSubmitNext));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final post = requests.firstWhere((r) => r.method == 'POST');
    final body = post.data as Map;
    expect(body['partnerUserId'], 'user-42');
    expect(body, isNot(contains('partnerEmailOrPhone')));
  });
}
