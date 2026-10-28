import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/pairing.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_athletes_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the writes the athletes tab makes; the presence call can be held
/// open so a second tap lands while the first is in flight.
class _ManagementRepository implements TournamentManagementRepository {
  final presence = <(String, bool)>[];
  final statuses = <(String, String)>[];
  final generates = <(PairingStrategy, String?)>[];
  Completer<void>? presenceGate;
  bool failPresence = false;

  @override
  Future<void> setParticipantPresent(
    String id,
    String participantId,
    bool present,
  ) async {
    presence.add((participantId, present));
    await presenceGate?.future;
    if (failPresence) throw Exception('offline');
  }

  @override
  Future<void> updateParticipantStatus(
    String id,
    String participantId,
    String status,
  ) async {
    statuses.add((participantId, status));
  }

  @override
  Future<PairGenerateResult> pairGenerate(
    String id, {
    required PairingStrategy strategy,
    String? divisionId,
  }) async {
    generates.add((strategy, divisionId));
    return const PairGenerateResult(pairedCount: 2, unpairedCount: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TournamentRepository implements ITournamentRepository {
  _TournamentRepository(this.participants);
  final List<OrganizerOpsParticipant> participants;

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => participants;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _divisions = <Map<String, dynamic>>[
  {'id': 'div-d', 'name': 'Doi Nam', 'matchType': 'DOUBLES'},
  {'id': 'div-s', 'name': 'Don Nam', 'matchType': 'SINGLES'},
];

Tournament _tournament(String status) => Tournament.fromJson({
  'name': 'Giai thu nghiem',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 16,
  'maxPlayersPerTeam': 2,
  'divisions': _divisions,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

const _people = [
  OrganizerOpsParticipant(
    id: 'p-ok',
    teamName: 'Alpha',
    teamStatus: 'COMPLETE',
    isPaid: true,
    entryFee: 100000,
    members: [],
    divisionId: 'div-d',
  ),
  OrganizerOpsParticipant(
    id: 'p-wait',
    teamName: 'Beta',
    teamStatus: 'PENDING_APPROVAL',
    isPaid: false,
    members: [],
    divisionId: 'div-d',
  ),
  OrganizerOpsParticipant(
    id: 'p-partner',
    teamName: 'Gamma',
    teamStatus: 'PENDING_PARTNER',
    isPaid: false,
    members: [],
    divisionId: 'div-d',
  ),
];

Future<void> _pumpPeople(
  WidgetTester tester,
  _ManagementRepository management, {
  String status = 'in_progress',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(
          _TournamentRepository(_people),
        ),
        tournamentManagementRepositoryProvider.overrideWithValue(management),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementPeopleSection(
            tournament: _tournament(status),
            showRegistration: true,
            divisionId: 'div-d',
            embedded: true,
            pairFormat: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpTab(
  WidgetTester tester,
  _ManagementRepository management,
) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        introTeamsProvider(
          'tournament-1',
        ).overrideWith((ref) async => const <Team>[]),
        tournamentDivisionsProvider(
          'tournament-1',
        ).overrideWith((ref) async => _divisions),
        tournamentRepositoryProvider.overrideWithValue(
          _TournamentRepository(_people),
        ),
        tournamentManagementRepositoryProvider.overrideWithValue(management),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentManagementAthletesTab(
              tournament: _tournament('in_progress'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('check-in: a double tap sends one request and flips once', (
    tester,
  ) async {
    final repo = _ManagementRepository()..presenceGate = Completer<void>();
    await _pumpPeople(tester, repo);

    final circle = find.byKey(const ValueKey('participant-checkin-p-ok'));
    await tester.tap(circle);
    await tester.pump();
    await tester.tap(circle);
    await tester.pump();
    repo.presenceGate!.complete();
    await tester.pumpAndSettle();

    expect(repo.presence, [('p-ok', true)]);
    expect(find.byIcon(Icons.check_rounded), findsWidgets);
  });

  testWidgets('check-in: a failed request rolls the circle back and says so', (
    tester,
  ) async {
    final repo = _ManagementRepository()..failPresence = true;
    await _pumpPeople(tester, repo);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

    await tester.tap(find.byKey(const ValueKey('participant-checkin-p-ok')));
    await tester.pumpAndSettle();

    expect(repo.presence, [('p-ok', true)]);
    expect(find.text(l10n.athletePresenceFailed), findsOneWidget);
    // Back to the empty circle: no tick inside the row.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('athlete-team-row-p-ok')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );
  });

  testWidgets('check-in circle is hidden while registration is open', (
    tester,
  ) async {
    await _pumpPeople(tester, _ManagementRepository(), status: 'registration');

    expect(
      find.byKey(const ValueKey('participant-checkin-p-ok')),
      findsNothing,
    );
  });

  testWidgets('pending row: tick approves, cross asks before rejecting', (
    tester,
  ) async {
    final repo = _ManagementRepository();
    await _pumpPeople(tester, repo);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

    await tester.tap(find.byKey(const ValueKey('participant-approve-p-wait')));
    await tester.pumpAndSettle();
    expect(repo.statuses, [('p-wait', 'COMPLETE')]);

    await tester.tap(find.byKey(const ValueKey('participant-reject-p-wait')));
    await tester.pumpAndSettle();
    // Nothing is sent until the confirm dialog is accepted.
    expect(repo.statuses.length, 1);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.tournamentManagementReject),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.statuses.last, ('p-wait', 'REJECTED'));
  });

  testWidgets('search filters rows by team name, case-insensitively', (
    tester,
  ) async {
    await _pumpPeople(tester, _ManagementRepository());

    await tester.enterText(
      find.byKey(const ValueKey('participant-search')),
      'bETa',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('athlete-team-row-p-wait')), findsOneWidget);
    expect(find.byKey(const ValueKey('athlete-team-row-p-ok')), findsNothing);
  });

  testWidgets('Tự ghép asks for a strategy and confirm before generating', (
    tester,
  ) async {
    final repo = _ManagementRepository();
    await _pumpTab(tester, repo);
    await tester.tap(find.byKey(const ValueKey('athlete-division-row-div-d')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('athletes-auto-pair')));
    await tester.pumpAndSettle();
    expect(repo.generates, isEmpty);

    // Cancel: still nothing sent.
    await tester.tap(find.byKey(const ValueKey('auto-pair-cancel')));
    await tester.pumpAndSettle();
    expect(repo.generates, isEmpty);

    await tester.tap(find.byKey(const ValueKey('athletes-auto-pair')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('auto-pair-strategy-eloBalanced')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auto-pair-confirm')));
    await tester.pumpAndSettle();

    expect(repo.generates, [(PairingStrategy.eloBalanced, 'div-d')]);
  });

  testWidgets('check-in switched in the profile sheet updates the header', (
    tester,
  ) async {
    final repo = _ManagementRepository();
    await _pumpTab(tester, repo);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text('${l10n.athletesPresentCount} 0/3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('athlete-division-row-div-d')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('athlete-team-row-p-ok')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('participant-detail-checkin')),
        matching: find.byType(LavishSwitch),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.presence, [('p-ok', true)]);
    expect(find.text('${l10n.athletesPresentCount} 1/3'), findsOneWidget);
  });

  testWidgets('singles division has neither pairing nor auto-pair boxes', (
    tester,
  ) async {
    await _pumpTab(tester, _ManagementRepository());
    await tester.tap(find.byKey(const ValueKey('athlete-division-row-div-s')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('athletes-auto-pair')), findsNothing);
    expect(find.byKey(const ValueKey('athletes-pairing')), findsNothing);
    expect(find.byKey(const ValueKey('athletes-import-excel')), findsOneWidget);
  });
}
