import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_stepper.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/step_summary_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tid = 'tournament-1';

Tournament _tournament() => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'divisions': [
    {'id': 'div-1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
  ],
  'registrationStartDate': '2026-10-01T00:00:00Z',
  'registrationEndDate': '2026-10-20T00:00:00Z',
  'startDate': '2026-11-01T00:00:00Z',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tid);

MatchModel _match(String id, {String status = 'SCHEDULED'}) => MatchModel(
  id: id,
  tournamentId: _tid,
  round: 1,
  matchNumber: 1,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  team1Id: 'a$id',
  team2Id: 'b$id',
  team1Name: 'Team A',
  team2Name: 'Team B',
  status: status,
  divisionId: 'div-1',
  updatedAt: DateTime.utc(2026, 1, 1),
);

Future<AppLocalizations> _pumpHub(
  WidgetTester tester, {
  Future<List<OrganizerOpsParticipant>>? participants,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final matches = [_match('m1', status: 'DISPUTED'), _match('m2')];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'manager-1',
            role: 'ORGANIZER',
            roles: ['ORGANIZER', 'ADMIN'],
          ),
        ),
        organizerParticipantsProvider(
          _tid,
        ).overrideWith((ref) => participants ?? Future.value(const [])),
        managedMatchesWithDivisionProvider((
          tournamentId: _tid,
          divisionId: null,
        )).overrideWith((ref) => Stream.value(matches)),
        matchesProvider(_tid).overrideWith((ref) => Stream.value(matches)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: TournamentManagementHubScreen(
          tournament: _tournament(),
          actionRouteBase: '/admin/tournament/$_tid',
          opsWorkspaceRoute: '/organizer/tournaments/$_tid/ops',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(TournamentManagementHubScreen)),
  )!;
}

/// The popup reads participants, then matches, before it opens (async work
/// that schedules no frame), so give the fake clock a few turns to run it
/// before settling the sheet animation.
Future<void> _settleAfterTap(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// The step label inside the progress bar (the header also prints the status).
Finder _stepLabel(String text) => find.descendant(
  of: find.byType(LifecycleStepBar),
  matching: find.text(text),
);

void main() {
  testWidgets('TC-STEP-14 tapping a progress step opens its popup', (
    tester,
  ) async {
    final l10n = await _pumpHub(tester);

    await tester.tap(_stepLabel(l10n.lifecycleStepOpen));
    await _settleAfterTap(tester);

    expect(find.byKey(const ValueKey('step-popup-body')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-STEP-15 "Đi tới" on a dispute opens the whole board', (
    tester,
  ) async {
    final l10n = await _pumpHub(tester);

    await tester.tap(_stepLabel(l10n.lifecycleStepRunning));
    await _settleAfterTap(tester);
    await tester.tap(find.byKey(const ValueKey('step-popup-go-disputed')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('step-popup-body')), findsNothing);
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    // Kết quả sits right after Lịch thi đấu, then Camera, with Cài đặt last.
    expect(tabBar.controller!.index, tabBar.tabs.length - 3);
    final board = tester.widget<ResultsMatchBoard>(
      find.byType(ResultsMatchBoard),
    );
    expect(board.initialFilter, ResultsBoardFilter.all);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-STEP-16 a double tap while loading opens one popup only', (
    tester,
  ) async {
    final gate = Completer<List<OrganizerOpsParticipant>>();
    final l10n = await _pumpHub(tester, participants: gate.future);

    final step = _stepLabel(l10n.lifecycleStepRunning);
    await tester.tap(step);
    await tester.tap(step);
    // Numbers still loading: no popup yet, and the second tap did nothing.
    expect(find.byKey(const ValueKey('step-popup-body')), findsNothing);

    gate.complete(const []);
    await _settleAfterTap(tester);

    expect(find.byKey(const ValueKey('step-popup-body')), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
