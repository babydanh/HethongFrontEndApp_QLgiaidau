import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
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

Tournament _tournament() => Tournament.fromJson({
  'name': 'Community Doubles Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'registration',
  'registrationMode': 'OPEN',
  'maxTeams': 4,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

UserProfile _profile() => const UserProfile(
  id: 'user-1',
  fullName: 'Nguyen Van A',
  phoneNumber: '0900000000',
  gender: 'MALE',

);

/// Projection `capacity` đúng như backend trả về cho nội dung đôi.
Map<String, dynamic> _doublesDivision({
  String? status,
  double? occupiedTeamSlots,
  bool? isFull,
  int participantRows = 4,
}) {
  return {
    'id': 'division-1',
    'name': 'Doubles A',
    'matchType': 'DOUBLES',
    'genderRestriction': 'MIXED',
    if (status != null) 'status': status,
    'maxParticipants': 4,
    '_count': {'participants': participantRows},
    if (occupiedTeamSlots != null)
      'capacity': {
        'occupiedTeamSlots': occupiedTeamSlots,
        'occupiedMemberSlots': occupiedTeamSlots * 2,
        'maxTeamSlots': 4,
        'isFull': isFull,
      },
  };
}

Future<List<String>> _pumpRegisterScreen(
  WidgetTester tester, {
  required Map<String, dynamic> division,
  bool alreadyRegistered = false,
  /// false = dừng ở frame trước post-frame auto-select.
  /// Khi `_selectedDiv` còn null, capacity gate phải dùng division hoạt động
  /// duy nhất, không lấy phần tử đầu danh sách.
  bool settle = true,
}) async {
  final requests = <String>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add('${options.method} ${options.path}');
          final data = switch (options.path) {
            '/tournaments/tournament-1/divisions' => {'data': [division]},
            '/tournaments/tournament-1/my-registration' => {
              'data': {
                'registered': alreadyRegistered,
                if (alreadyRegistered) 'paymentEligible': true,
                if (alreadyRegistered)
                  'participant': {
                    'id': 'participant-1',
                    'tournamentDivisionId': division['id'],
                    'teamStatus': 'COMPLETE',
                    'isPaid': false,
                  },
              },
            },
            _ => <String, dynamic>{'data': <String, dynamic>{}},
          };
          handler.resolve(
            Response<dynamic>(requestOptions: options, data: data),
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
        userProfileProvider.overrideWith((ref) async => _profile()),
        registerTournamentProvider(
          (id: 'tournament-1', invite: null),
        ).overrideWith((ref) async => _tournament()),
        tournamentProvider(
          'tournament-1',
        ).overrideWith((ref) => Stream<Tournament?>.value(_tournament())),
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byType(FilledButton).evaluate().isNotEmpty) break;
    }
    expect(
      find.byType(FilledButton),
      findsOneWidget,
      reason: 'form đăng ký không được dựng lên',
    );
  }
  return requests;
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'a cancelled division is not implicitly selected for registration',
    (tester) async {
      final requests = await _pumpRegisterScreen(
        tester,
        division: _doublesDivision(status: 'CANCELLED'),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        requests.where((request) => request.startsWith('POST ')),
        isEmpty,
      );
    },
  );

  testWidgets(
    'four unpaired doubles athletes show 2 / 4 team slots and keep the submit enabled',
    (tester) async {
      await _pumpRegisterScreen(
        tester,
        division: _doublesDivision(occupiedTeamSlots: 2, isFull: false),
      );

      final context = tester.element(find.byType(TournamentRegisterScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.registerTeamSlotCount('2/4')), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(find.text(l10n.registerDivisionFull), findsNothing);
    },
  );

  testWidgets(
    'a full doubles division disables new registration',
    (tester) async {
      await _pumpRegisterScreen(
        tester,
        division: _doublesDivision(
          occupiedTeamSlots: 4,
          isFull: true,
          participantRows: 8,
        ),
      );

      final context = tester.element(find.byType(TournamentRegisterScreen));
      final l10n = AppLocalizations.of(context)!;

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
    'a doubles division without a capacity projection shows no occupancy and stays open',
    (tester) async {
      await _pumpRegisterScreen(
        tester,
        division: _doublesDivision(),
      );

      final context = tester.element(find.byType(TournamentRegisterScreen));
      final l10n = AppLocalizations.of(context)!;

      // 4 hồ sơ KHÔNG được hiện thành "4/4 suất đội" rồi chặn nhầm.
      expect(find.text(l10n.registerTeamSlotCount('4/4')), findsNothing);
      expect(find.text(l10n.registerDivisionFull), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'the full gate holds before the implicit single division is auto-selected',
    (tester) async {
      await _pumpRegisterScreen(
        tester,
        division: _doublesDivision(
          occupiedTeamSlots: 4,
          isFull: true,
          participantRows: 8,
        ),
        settle: false,
      );

      // Frame này `_selectedDiv` còn null; gate sức chứa vẫn phải nhắm đúng
      // division hoạt động duy nhất trước khi post-frame callback chạy.
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      // Dừng giữa animation nên còn timer của flutter_animate và thẻ đếm ngược
      // treo; tháo cây rồi settle để chúng được huỷ trước khi test kết thúc.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'an already registered player keeps the status card when the division is full',
    (tester) async {
      await _pumpRegisterScreen(
        tester,
        division: _doublesDivision(
          occupiedTeamSlots: 4,
          isFull: true,
          participantRows: 8,
        ),
        alreadyRegistered: true,
      );

      final context = tester.element(find.byType(TournamentRegisterScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.registerStatusCompleteUnpaid), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
  );
}
