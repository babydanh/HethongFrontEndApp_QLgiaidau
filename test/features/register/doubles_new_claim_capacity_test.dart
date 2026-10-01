import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
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
  'maxTeams': 4,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

/// Nội dung đôi đã đầy suất, đúng projection server trả về.
TournamentDivisionOption _fullDivision() => TournamentDivisionOption.fromJson({
  'id': 'division-1',
  'name': 'Doubles A',
  'matchType': 'DOUBLES',
  'maxParticipants': 4,
  'capacity': {'occupiedTeamSlots': 4, 'maxTeamSlots': 4, 'isFull': true},
});

TournamentDivisionOption _openDivision() => TournamentDivisionOption.fromJson({
  'id': 'division-1',
  'name': 'Doubles A',
  'matchType': 'DOUBLES',
  'maxParticipants': 4,
  'capacity': {'occupiedTeamSlots': 2, 'maxTeamSlots': 4, 'isFull': false},
});

Future<List<RequestOptions>> _pumpDoublesFlow(
  WidgetTester tester, {
  required TournamentDivisionOption division,
  Map<String, dynamic>? registeredParticipant,
}) async {
  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (options.method == 'POST') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {
                    'participant': {'id': 'participant-1'},
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
                  'registered': registeredParticipant != null,
                  'paymentEligible': false,
                  'participant': registeredParticipant ?? <String, dynamic>{},
                },
              },
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
        registerTournamentProvider(
          (id: 'tournament-1', invite: null),
        ).overrideWith((ref) async => _tournament()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: DoublesRegistrationFlow(
          tournamentId: 'tournament-1',
          division: division,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'a new doubles claim into a full division is blocked before posting',
    (tester) async {
      final requests = await _pumpDoublesFlow(
        tester,
        division: _fullDivision(),
      );

      final context = tester.element(find.byType(DoublesRegistrationFlow));
      final l10n = AppLocalizations.of(context)!;
      final submit = find.widgetWithText(FilledButton, l10n.doublesRegSubmitNext);

      expect(submit, findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
    },
  );

  testWidgets(
    'a new doubles claim into a division with room still submits',
    (tester) async {
      await _pumpDoublesFlow(
        tester,
        division: _openDivision(),
      );
      final context = tester.element(find.byType(DoublesRegistrationFlow));
      final l10n = AppLocalizations.of(context)!;
      final submit = find.widgetWithText(FilledButton, l10n.doublesRegSubmitNext);

      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    },
  );

  testWidgets(
    'an already registered player keeps the status flow in a full division',
    (tester) async {
      // Người ĐÃ có đơn không đi qua bước "tạo đơn" nữa, nên gate suất đội
      // không được chặn luồng trạng thái / thanh toán / rút lui của họ.
      final requests = await _pumpDoublesFlow(
        tester,
        division: _fullDivision(),
        registeredParticipant: {
          'id': 'participant-1',
          'tournamentDivisionId': 'division-1',
          'teamName': 'Saved Pair',
          'teamStatus': 'PENDING_APPROVAL',
          'isPaid': false,
          'members': <dynamic>[],
        },
      );

      final context = tester.element(find.byType(DoublesRegistrationFlow));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.doublesRegStatusPendingApproval), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, l10n.doublesRegSubmitNext),
        findsNothing,
      );
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
    },
  );
}
