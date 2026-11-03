import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_edit_popup.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements ITournamentRepository {
  _Repository({this.updateError});

  final Object? updateError;
  Map<String, dynamic>? payload;
  int updateCalls = 0;

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    updateCalls++;
    if (updateError != null) throw updateError!;
    payload = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ManagementRepository implements TournamentManagementRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament({String status = 'REGISTRATION_CLOSED'}) =>
    Tournament.fromJson({
      'name': 'Direct date regression',
      'sport': 'pickleball',
      'format': 'singles',
      'bracketType': 'single_elimination',
      'status': status,
      'visibility': 'PUBLIC',
      'tournamentConfig': {'registrationMode': 'OPEN'},
      'registrationStartDate': '2098-01-01T00:00:00Z',
      'registrationEndDate': '2099-01-01T10:30:00Z',
      'startDate': '2099-06-01T00:00:00Z',
      'endDate': '2099-07-01T00:00:00Z',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    }, 'tournament-1');

/// Pumps a page with one button that opens the popup of [focus], as the
/// overview does, and taps it.
Future<_Repository> _open(
  WidgetTester tester,
  TournamentManagementFocus focus, {
  Object? updateError,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _Repository(updateError: updateError);
  final tournament = _tournament();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(repository),
        tournamentManagementRepositoryProvider.overrideWithValue(
          _ManagementRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTournamentEditPopup(
                context,
                tournament: tournament,
                focus: focus,
                opsWorkspaceRoute: '/ops',
                actionRouteBase: '/manage',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repository;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.text('open')))!;

void main() {
  testWidgets(
    'TC-DATEDIRECT-01: a date row opens the picker at once, with no form around it',
    (tester) async {
      await _open(tester, TournamentManagementFocus.tournamentClosing);
      final l10n = _l10n(tester);

      // The picker is up; nothing else of the old popup is drawn.
      expect(find.text(l10n.socialPlaceConfirm), findsOneWidget);
      expect(find.text(l10n.tournamentManagementSave), findsNothing);
      expect(find.text(l10n.tournamentManagementRegistrationClosedHint), findsNothing);
    },
  );

  testWidgets(
    'TC-DATEDIRECT-02: confirming the picker saves the date alone, even when registration is closed',
    (tester) async {
      final repository = await _open(
        tester,
        TournamentManagementFocus.tournamentClosing,
      );
      final l10n = _l10n(tester);

      await tester.tap(find.text('23:59'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.socialPlaceConfirm));
      await tester.pumpAndSettle();

      expect(repository.payload?.keys, unorderedEquals(['endDate']));
      expect(find.byType(TournamentManagementSectionScreen), findsNothing);
      expect(find.text(l10n.tournamentManagementSaved), findsOneWidget);
    },
  );

  testWidgets(
    'TC-DATEDIRECT-03: a frozen registration date says why and closes, no picker',
    (tester) async {
      final repository = await _open(
        tester,
        TournamentManagementFocus.registrationOpens,
      );
      final l10n = _l10n(tester);

      expect(find.text(l10n.tournamentManagementRegistrationClosedHint), findsOneWidget);
      expect(find.text(l10n.socialPlaceConfirm), findsNothing);
      expect(find.byType(TournamentManagementSectionScreen), findsNothing);
      expect(repository.updateCalls, 0);
    },
  );

  testWidgets(
    'TC-DATEDIRECT-04: a refused save shows the error and never leaves an invisible popup behind',
    (tester) async {
      final repository = await _open(
        tester,
        TournamentManagementFocus.tournamentClosing,
        updateError: Exception('refused'),
      );
      final l10n = _l10n(tester);

      await tester.tap(find.text('23:59'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.socialPlaceConfirm));
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 1);
      expect(find.text(l10n.tournamentManagementSaveError), findsOneWidget);
      expect(find.byType(TournamentManagementSectionScreen), findsNothing);
      // The page underneath is usable again.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.socialPlaceConfirm), findsOneWidget);
    },
  );

  testWidgets(
    'TC-DATEDIRECT-05: cancelling the picker closes everything and saves nothing',
    (tester) async {
      final repository = await _open(
        tester,
        TournamentManagementFocus.registrationDeadline,
      );
      final l10n = _l10n(tester);

      await tester.tap(find.text(l10n.socialPlaceCancel));
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 0);
      expect(find.byType(TournamentManagementSectionScreen), findsNothing);
    },
  );
}
