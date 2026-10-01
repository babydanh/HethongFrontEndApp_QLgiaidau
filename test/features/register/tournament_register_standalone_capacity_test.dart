import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/register/screens/tournament_register_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
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

/// Socket thật sẽ mở kết nối mạng khi màn hình init; test chỉ cần luồng rỗng.
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

const _profile = UserProfile(
  id: 'user-1',
  fullName: 'Nguyen Van A',
  phoneNumber: '0900000000',
  gender: 'MALE',
);

/// Payload giải đứng một mình như backend trả về: `/divisions` rỗng, còn
/// projection `capacity` cấp GIẢI nằm ngay trên `/tournaments/:id`.
Map<String, dynamic> _standaloneTournament({
  required String format,
  required String name,
  required Map<String, dynamic> capacity,
}) {
  return {
    'id': 'tournament-1',
    'name': name,
    'sport': 'pickleball',
    'format': format,
    'status': 'registration',
    'registrationMode': 'OPEN',
    'maxTeams': 4,
    'maxPlayersPerTeam': format == 'doubles' ? 2 : 1,
    'createdAt': '2026-01-01T00:00:00Z',
    'updatedAt': '2026-01-01T00:00:00Z',
    '_count': {'participants': 8},
    'capacity': capacity,
  };
}

/// Màn hình đăng ký với backend giả: giải KHÔNG có nội dung con nên mọi
/// request `/divisions` trả mảng rỗng và app phải tự dựng nội dung chính.
Future<void> _pumpStandaloneRegister(
  WidgetTester tester, {
  required Map<String, dynamic> Function() tournament,
}) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final data = switch (options.path) {
            '/tournaments/tournament-1' => {'data': tournament()},
            '/tournaments/tournament-1/divisions' => {
              'data': <dynamic>[],
            },
            '/tournaments/tournament-1/sponsors' => {'data': <dynamic>[]},
            '/tournaments/tournament-1/my-registration' => {
              'data': {'registered': false},
            },
            _ => <String, dynamic>{'data': <String, dynamic>{}},
          };
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioClientProvider.overrideWithValue(
          DioClient(tokenManager: _NoTokenManager(), dio: dio),
        ),
        matchSocketServiceProvider.overrideWithValue(_OfflineSocketService()),
        authProvider.overrideWith(_AuthenticatedUser.new),
        userProfileProvider.overrideWith((ref) async => _profile),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const TournamentRegisterScreen(tournamentId: 'tournament-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'a full standalone doubles tournament blocks a new claim',
    (tester) async {
      await _pumpStandaloneRegister(
        tester,
        tournament: () => _standaloneTournament(
          format: 'doubles',
          name: 'Community Doubles Cup',
          capacity: {
            'occupiedTeamSlots': 4,
            'occupiedMemberSlots': 8,
            'maxTeamSlots': 4,
            'isFull': true,
          },
        ),
      );

      final context = tester.element(find.byType(TournamentRegisterScreen));
      final l10n = AppLocalizations.of(context)!;

      // Projection cấp giải phải sống được trong nội dung app tự dựng. Nếu rơi
      // ở khâu dựng, nội dung đôi thiếu projection sẽ không hiện sức chứa và vẫn
      // mở nút bấm — người dùng claim vào giải đã đầy.
      expect(find.text(l10n.registerTeamSlotCount('4/4')), findsOneWidget);
      expect(find.text(l10n.registerDivisionFull), findsWidgets);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        find.widgetWithText(FilledButton, l10n.registerDivisionFull),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a standalone singles tournament shows the projected occupancy',
    (tester) async {
      await _pumpStandaloneRegister(
        tester,
        tournament: () => _standaloneTournament(
          format: 'singles',
          name: 'Community Singles Cup',
          capacity: {
            'occupiedTeamSlots': 2,
            'occupiedMemberSlots': 2,
            'maxTeamSlots': 4,
            'isFull': false,
          },
        ),
      );

      final context = tester.element(find.byType(TournamentRegisterScreen));
      final l10n = AppLocalizations.of(context)!;

      // Nội dung tự dựng không mang _count: mất projection thì đơn sẽ hiện "0/4"
      // dù đã có 2 suất chiếm — số liệu sai hiển thị cho người dùng.
      expect(find.text(l10n.registerTeamSlotCount('0/4')), findsNothing);
      expect(find.text(l10n.registerTeamSlotCount('2/4')), findsOneWidget);
      expect(find.text(l10n.registerDivisionFull), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );
}
