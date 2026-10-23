import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DivisionRepository implements TournamentManagementRepository {
  _DivisionRepository(this.division);

  final Map<String, dynamic> division;
  final configPayloads = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async => [
    division,
  ];

  @override
  Future<Map<String, dynamic>> updateDivisionConfig(
    String id,
    String divisionId,
    Map<String, dynamic> payload,
  ) async {
    configPayloads.add(payload);
    return division;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament(String status) => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 8,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

const _openDivision = <String, dynamic>{
  'id': 'div-1',
  'name': 'Đôi nam',
  'matchType': 'DOUBLES',
  'bracketType': 'SINGLE_ELIMINATION',
  'registrationOpen': true,
  'effectiveIsRegistrationLocked': false,
  'effectiveRegistrationEndDate': null,
};

Future<AppLocalizations> _pump(
  WidgetTester tester,
  String status,
  _DivisionRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementDivisionsSection(
            tournament: _tournament(status),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(TournamentManagementDivisionsSection)),
  )!;
}

void main() {
  testWidgets(
    'TC-APP-DIVLOCK-01: an in-progress tournament can still lock one division',
    (tester) async {
      final repository = _DivisionRepository(_openDivision);
      final l10n = await _pump(tester, 'IN_PROGRESS', repository);

      // Còn mở mà không có hạn: thẻ nhắc để BTC tự khoá.
      expect(
        find.text(
          '${l10n.tournamentManagementDivisionRegistrationOpen} · ${l10n.tournamentManagementDivisionNoDeadline}',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.tournamentManagementDivisionLockRegistration),
      );
      await tester.pumpAndSettle();

      expect(repository.configPayloads, [
        {'isRegistrationLocked': true},
      ]);
    },
  );

  testWidgets(
    'TC-APP-DIVLOCK-02: a locked division reopens while registration is closed',
    (tester) async {
      final repository = _DivisionRepository({
        ..._openDivision,
        'registrationOpen': false,
        'effectiveIsRegistrationLocked': true,
      });
      final l10n = await _pump(tester, 'REGISTRATION_CLOSED', repository);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.tournamentManagementDivisionUnlockRegistration),
      );
      await tester.pumpAndSettle();

      expect(repository.configPayloads, [
        {'isRegistrationLocked': false},
      ]);
    },
  );

  testWidgets(
    'TC-APP-DIVLOCK-03: a completed tournament does not toggle registration',
    (tester) async {
      final repository = _DivisionRepository(_openDivision);
      final l10n = await _pump(tester, 'COMPLETED', repository);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.tournamentManagementDivisionLockRegistration),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(repository.configPayloads, isEmpty);
    },
  );
}
