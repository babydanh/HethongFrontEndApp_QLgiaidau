import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/add_athlete_candidate.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'tournament-1';
const _divisionId = 'division-1';

Tournament _tournament(
  String status, {
  Map<String, dynamic>? sportRules,
  double? entryFee,
}) => Tournament.fromJson({
  'name': 'Roster Cup',
  'sport': 'pickleball',
  'format': 'singles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 16,
  'entryFee': entryFee,
  'sportRules': sportRules,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

class _TournamentRepository implements ITournamentRepository {
  @override
  Future<Map<String, dynamic>> generateBracket(
    String tournamentId, {
    String? divisionId,
    required String seedingType,
    bool allowReset = false,
  }) => throw UnimplementedError();
  _TournamentRepository(this.tournament, this.participants);

  final Tournament tournament;
  final List<OrganizerOpsParticipant> participants;

  @override
  Stream<Tournament?> watch(String id) => Stream.value(tournament);

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => participants;

  @override
  Future<List<OrganizerOpsReferee>> getTournamentReferees(
    String tournamentId,
  ) async => const [];

  @override
  Future<List<OrganizerOpsAuditEntry>> getOpsAuditLogs(
    String tournamentId, {
    String? divisionId,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

typedef _CandidateLoader =
    Future<List<AddAthleteCandidate>> Function(
      AddAthleteSource source,
      String? query,
      String? participantId,
    );

class _TournamentManagementRepository
    implements TournamentManagementRepository {
  _TournamentManagementRepository({
    _CandidateLoader? candidateLoader,
    this.failAutoApprove = false,
    this.failCandidateAdd = false,
    this.candidateAdditionGate,
    this.directError,
    this.directErrorsByName = const {},
  }) : _candidateLoader =
           candidateLoader ??
           ((source, query, participantId) async =>
               const <AddAthleteCandidate>[]);

  final _CandidateLoader _candidateLoader;
  final bool failAutoApprove;
  final bool failCandidateAdd;
  final Completer<void>? candidateAdditionGate;
  final Object? directError;
  final Map<String, Object> directErrorsByName;
  final emailSearches = <String?>[];
  final candidateRequests = <Map<String, Object?>>[];
  final candidateAdditions = <Map<String, Object?>>[];
  final directNames = <String>[];
  final directCalls = <Map<String, Object?>>[];
  final statusUpdates = <Map<String, String>>[];

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];

  @override
  Future<List<AddAthleteCandidate>> listAddAthleteCandidates(
    String id, {
    required AddAthleteSource source,
    String? query,
    String? participantId,
  }) {
    candidateRequests.add({
      'source': source,
      'query': query,
      'participantId': participantId,
    });
    return _candidateLoader(source, query, participantId);
  }

  @override
  Future<String> addAthleteCandidate(
    String id, {
    required AddAthleteSource source,
    required String userId,
    String? tournamentDivisionId,
    String? participantId,
    FootballRosterRole? role,
  }) async {
    candidateAdditions.add({
      'source': source,
      'userId': userId,
      'tournamentDivisionId': tournamentDivisionId,
      'participantId': participantId,
      'role': role,
    });
    if (candidateAdditionGate != null) await candidateAdditionGate!.future;
    if (failCandidateAdd) throw TimeoutException('candidate add timed out');
    return 'participant-added';
  }

  @override
  Future<String> addAthleteDirect(
    String id, {
    required String name,
    String? email,
    String? phone,
    String? notes,
    double? elo,
    String? eloSource,
    String? tournamentDivisionId,
  }) async {
    directNames.add(name);
    directCalls.add({
      'name': name,
      'email': email,
      'phone': phone,
      'notes': notes,
      'elo': elo,
      'eloSource': eloSource,
      'tournamentDivisionId': tournamentDivisionId,
    });
    final byName = directErrorsByName[name];
    if (byName != null) throw byName;
    final error = directError;
    if (error != null) throw error;
    return 'participant-direct';
  }

  @override
  Future<List<AddAthleteSearchCandidate>> searchAddAthleteCandidates(
    String id, {
    String? name,
    String? email,
    String? participantId,
  }) async {
    emailSearches.add(email);
    return const <AddAthleteSearchCandidate>[];
  }

  @override
  Future<void> updateParticipantStatus(
    String id,
    String participantId,
    String status,
  ) async {
    statusUpdates.add({'participantId': participantId, 'status': status});
    if (failAutoApprove) throw StateError('status update failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(
  String status, {
  List<OrganizerOpsParticipant> participants =
      const <OrganizerOpsParticipant>[],
  _TournamentManagementRepository? managementRepository,
  Map<String, dynamic>? sportRules,
  double? entryFee,
  double? divisionEntryFee,
  double? effectiveEntryFee,
  String matchType = 'SINGLES',
  void Function()? onReadModelLoad,
  OrganizerOpsView? view,
}) {
  final tournament = _tournament(
    status,
    sportRules: sportRules,
    entryFee: entryFee,
  );
  final management = managementRepository ?? _TournamentManagementRepository();
  final readModel = OrganizerOpsReadModel(
    participants: participants,
    referees: const [],
    auditEntries: const [],
  );

  return ProviderScope(
    overrides: [
      tournamentRepositoryProvider.overrideWithValue(
        _TournamentRepository(tournament, participants),
      ),
      tournamentManagementRepositoryProvider.overrideWithValue(management),
      tournamentProvider(
        _tournamentId,
      ).overrideWith((ref) => Stream<Tournament?>.value(tournament)),
      tournamentDivisionsProvider(_tournamentId).overrideWith(
        (ref) async => [
          {
            'id': _divisionId,
            'name': 'Open',
            'matchType': matchType,
            if (divisionEntryFee != null) 'entryFee': divisionEntryFee,
            if (effectiveEntryFee != null)
              'effectiveEntryFee': effectiveEntryFee,
          },
        ],
      ),
      managedMatchesWithDivisionProvider((
        tournamentId: _tournamentId,
        divisionId: _divisionId,
      )).overrideWith((ref) => Stream.value(const [])),
      organizerOpsReadModelProvider((
        tournamentId: _tournamentId,
        divisionId: _divisionId,
      )).overrideWith((ref) async {
        onReadModelLoad?.call();
        return readModel;
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OrganizerOpsScreen(
        tournamentId: _tournamentId,
        initialDivisionId: _divisionId,
        view: view,
      ),
    ),
  );
}

Future<void> _openRoster(WidgetTester tester) async {
  final context = tester.element(find.byType(OrganizerOpsScreen));
  final l10n = AppLocalizations.of(context)!;
  final rosterTab = find.text(l10n.opsRoster).first;
  await tester.ensureVisible(rosterTab);
  await tester.tap(rosterTab);
  await tester.pumpAndSettle();
}

void _useMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
}

Future<void> _openAddAthlete(
  WidgetTester tester, {
  bool accountsTab = true,
}) async {
  await _openRoster(tester);
  final action = find.text('Thêm VĐV').first;
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  if (!accountsTab) return;
  await tester.tap(find.text('Bạn bè & CLB'));
  // Candidate loads may still be pending, so settle with fixed pumps.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('writable roster has a separate add-athlete action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OrganizerOpsScreen));
    final l10n = AppLocalizations.of(context)!;
    final rosterTab = find.text(l10n.opsRoster).first;
    await tester.ensureVisible(rosterTab);
    await tester.tap(rosterTab);
    await tester.pumpAndSettle();

    expect(find.text('Thêm VĐV'), findsOneWidget);
  });

  testWidgets('locked roster view shows roster without the ops chip strip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app('IN_PROGRESS', view: OrganizerOpsView.roster),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OrganizerOpsScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text('Thêm VĐV'), findsOneWidget);
    expect(find.text(l10n.opsMatches), findsNothing);
    expect(find.text(l10n.opsBracket), findsNothing);
  });

  testWidgets('read-only roster does not expose the add action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app('COMPLETED'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OrganizerOpsScreen));
    final l10n = AppLocalizations.of(context)!;
    final rosterTab = find.text(l10n.opsRoster).first;
    await tester.ensureVisible(rosterTab);
    await tester.tap(rosterTab);
    await tester.pumpAndSettle();

    expect(find.text('Thêm VĐV'), findsNothing);
  });

  testWidgets('add-athlete action is not placed in the camera tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(OrganizerOpsScreen));
    final l10n = AppLocalizations.of(context)!;
    final cameraTab = find.text(l10n.opsCamera);
    await tester.ensureVisible(cameraTab);
    await tester.tap(cameraTab);
    await tester.pumpAndSettle();

    expect(find.text('Thêm VĐV'), findsNothing);
  });
  testWidgets('add-athlete sheet stays bounded on a wide viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);

    final sheet = find.byKey(const ValueKey('add-athlete-sheet'));
    expect(tester.getSize(sheet).width, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard inset leaves breathing room above the sheet', (
    tester,
  ) async {
    _useMobileViewport(tester);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('add-athlete-sheet')),
    );
    expect(sheetRect.bottom, lessThanOrEqualTo(580));
    expect(sheetRect.top, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('merges FRIENDS and CLUB candidates without duplicates', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository(
      candidateLoader: (source, query, participantId) async => switch (source) {
        AddAthleteSource.friends => const [
          AddAthleteCandidate(userId: 'shared', fullName: 'Shared athlete'),
          AddAthleteCandidate(userId: 'friend', fullName: 'Friend athlete'),
        ],
        AddAthleteSource.club => const [
          AddAthleteCandidate(userId: 'shared', fullName: 'Club duplicate'),
          AddAthleteCandidate(userId: 'club', fullName: 'Club athlete'),
        ],
        AddAthleteSource.email => const <AddAthleteCandidate>[],
      },
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Shared athlete'), findsOneWidget);
    expect(find.text('Club duplicate'), findsNothing);
    expect(find.text('Friend athlete'), findsOneWidget);
    expect(find.text('Club athlete'), findsOneWidget);
    final l10n = AppLocalizations.of(
      tester.element(find.byKey(const ValueKey('add-athlete-sheet'))),
    )!;
    expect(find.text(l10n.opsAddAthleteFriends), findsNWidgets(2));
    expect(find.text(l10n.opsAddAthleteClub), findsNWidgets(2));
    expect(repository.candidateRequests.map((request) => request['source']), [
      AddAthleteSource.friends,
      AddAthleteSource.club,
    ]);
  });

  testWidgets('a stale candidate response cannot replace a newer search', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final oldFriends = Completer<List<AddAthleteCandidate>>();
    final oldClub = Completer<List<AddAthleteCandidate>>();
    final repository = _TournamentManagementRepository(
      candidateLoader: (source, query, participantId) {
        if (query == null || query.isEmpty) {
          return source == AddAthleteSource.friends
              ? oldFriends.future
              : oldClub.future;
        }
        return Future.value(
          query == 'Newest' && source == AddAthleteSource.friends
              ? const [
                  AddAthleteCandidate(
                    userId: 'new',
                    fullName: 'Newest athlete',
                  ),
                ]
              : const <AddAthleteCandidate>[],
        );
      },
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);

    await tester.enterText(
      find.byKey(const ValueKey('add-athlete-search')),
      'Newest',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Newest athlete'), findsOneWidget);

    oldFriends.complete(const [
      AddAthleteCandidate(userId: 'old', fullName: 'Old athlete'),
    ]);
    oldClub.complete(const <AddAthleteCandidate>[]);
    await tester.pumpAndSettle();

    expect(find.text('Newest athlete'), findsOneWidget);
    expect(find.text('Old athlete'), findsNothing);
  });
  testWidgets('name search waits for two characters and ignores stale query results', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final initialFriends = Completer<List<AddAthleteCandidate>>();
    final initialClub = Completer<List<AddAthleteCandidate>>();
    final repository = _TournamentManagementRepository(
      candidateLoader: (source, query, participantId) {
        if (query == null || query.isEmpty) {
          return source == AddAthleteSource.friends
              ? initialFriends.future
              : initialClub.future;
        }
        return Future.value(
          query == 'Al' && source == AddAthleteSource.friends
              ? const [
                  AddAthleteCandidate(
                    userId: 'latest',
                    fullName: 'Latest athlete',
                  ),
                ]
              : const <AddAthleteCandidate>[],
        );
      },
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    expect(repository.candidateRequests, hasLength(2));

    final search = find.byKey(const ValueKey('add-athlete-search'));
    await tester.enterText(search, 'A');
    initialFriends.complete(const [
      AddAthleteCandidate(userId: 'stale', fullName: 'Stale initial'),
    ]);
    initialClub.complete(const <AddAthleteCandidate>[]);
    await tester.pump();
    expect(find.text('Stale initial'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(repository.candidateRequests, hasLength(2));

    await tester.enterText(search, '@x');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(repository.candidateRequests, hasLength(2));

    await tester.enterText(search, 'Al');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(repository.candidateRequests, hasLength(4));
    expect(
      repository.candidateRequests.skip(2).map((request) => request['query']),
      everyElement('Al'),
    );
    expect(find.text('Latest athlete'), findsOneWidget);
  });

  testWidgets('account candidate requires selection before footer add', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository(
      candidateLoader: (source, query, participantId) async =>
          source == AddAthleteSource.friends
          ? const [
              AddAthleteCandidate(userId: 'selected', fullName: 'Selected'),
            ]
          : const [],
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final candidate = find.byKey(
      const ValueKey('add-athlete-candidate-select-selected'),
    );
    final submit = find.byKey(
      const ValueKey('add-athlete-candidate-submit'),
    );
    expect(tester.getSize(candidate).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(submit).height, greaterThanOrEqualTo(44));
    expect(repository.candidateAdditions, isEmpty);

    await tester.tap(candidate);
    await tester.pump();
    expect(repository.candidateAdditions, isEmpty);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.candidateAdditions, hasLength(1));
    expect(repository.candidateAdditions.single['userId'], 'selected');
  });

  testWidgets('candidate submission prevents duplicate taps', (tester) async {
    _useMobileViewport(tester);
    final gate = Completer<void>();
    final repository = _TournamentManagementRepository(
      candidateLoader: (source, query, participantId) async =>
          source == AddAthleteSource.friends
          ? const [
              AddAthleteCandidate(userId: 'locked', fullName: 'Locked athlete'),
            ]
          : const [],
      candidateAdditionGate: gate,
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final candidate = find.byKey(
      const ValueKey('add-athlete-candidate-select-locked'),
    );
    final action = find.byKey(
      const ValueKey('add-athlete-candidate-submit'),
    );
    await tester.tap(candidate);
    await tester.pump();
    await tester.tap(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pump();

    expect(repository.candidateAdditions, hasLength(1));
    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.candidateAdditions, hasLength(1));
    expect(repository.statusUpdates, isEmpty);
  });
  testWidgets('route pop cannot dismiss sheet during candidate submission', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final gate = Completer<void>();
    final repository = _TournamentManagementRepository(
      candidateLoader: (source, query, participantId) async =>
          source == AddAthleteSource.friends
          ? const [
              AddAthleteCandidate(
                userId: 'barrier',
                fullName: 'Barrier athlete',
              ),
            ]
          : const [],
      candidateAdditionGate: gate,
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('add-athlete-candidate-select-barrier')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('add-athlete-candidate-submit')),
    );
    await tester.pump();
    expect(repository.candidateAdditions, hasLength(1));
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('add-athlete-close')))
          .onPressed,
      isNull,
    );

    final sheetContext = tester.element(
      find.byKey(const ValueKey('add-athlete-sheet')),
    );
    await Navigator.of(sheetContext).maybePop();
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('add-athlete-sheet')), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-athlete-sheet')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('add-athlete-close')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('add-athlete-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-athlete-sheet')), findsNothing);
  });

  testWidgets('drag cannot dismiss sheet during candidate submission', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final gate = Completer<void>();
    final repository = _TournamentManagementRepository(
      candidateLoader: (source, query, participantId) async =>
          source == AddAthleteSource.friends
          ? const [
              AddAthleteCandidate(userId: 'drag', fullName: 'Drag athlete'),
            ]
          : const [],
      candidateAdditionGate: gate,
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('add-athlete-candidate-select-drag')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('add-athlete-candidate-submit')),
    );
    await tester.pump();
    expect(repository.candidateAdditions, hasLength(1));

    final sheetTop = tester
        .getTopLeft(find.byKey(const ValueKey('add-athlete-sheet')))
        .dy;
    await tester.dragFrom(Offset(180, sheetTop + 16), const Offset(0, 800));
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const ValueKey('add-athlete-sheet')), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('football additions require an existing team and explicit role', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final team = OrganizerOpsParticipant(
      id: 'team-participant',
      teamName: 'Blue team',
      teamStatus: 'PENDING_APPROVAL',
      isPaid: false,
      members: const [],
      footballTeamId: 'football-team',
    );
    final repository = _TournamentManagementRepository(
      candidateLoader: (source, query, participantId) async =>
          source == AddAthleteSource.friends
          ? const [
              AddAthleteCandidate(
                userId: 'football-candidate',
                fullName: 'Football athlete',
              ),
            ]
          : const [],
    );
    await tester.pumpWidget(
      _app(
        'REGISTRATION_OPEN',
        participants: [team],
        managementRepository: repository,
        sportRules: const {'kind': 'FOOTBALL'},
        entryFee: 0,
      ),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);

    expect(find.text('Nhập tên'), findsNothing);
    expect(repository.candidateRequests, isEmpty);
    final teamPicker = find.byKey(const ValueKey('add-athlete-team'));
    await tester.ensureVisible(teamPicker);
    await tester.tap(teamPicker);
    await tester.pumpAndSettle();
    final teamOption = find.text('Blue team').last;
    await tester.ensureVisible(teamOption);
    await tester.tap(teamOption);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Football athlete'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey('add-athlete-candidate-select-football-candidate'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('add-athlete-candidate-main')),
    );
    await tester.pumpAndSettle();

    expect(repository.candidateAdditions.single, {
      'source': AddAthleteSource.friends,
      'userId': 'football-candidate',
      'tournamentDivisionId': null,
      'participantId': 'team-participant',
      'role': FootballRosterRole.main,
    });
    expect(repository.statusUpdates, isEmpty);
  });

  testWidgets('direct-name entry rejects blank and overlong names', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository();
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    final directTab = find.text('Nhập tên');
    await tester.ensureVisible(directTab);
    await tester.tap(directTab);
    await tester.pumpAndSettle();
    final nameField = find.byKey(const ValueKey('add-athlete-direct-name'));
    await tester.ensureVisible(nameField);
    await tester.tap(find.byKey(const ValueKey('add-athlete-direct-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên vận động viên.'), findsOneWidget);
    expect(repository.directNames, isEmpty);
    final emailField = find.byKey(const ValueKey('add-athlete-direct-email'));
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'an.nguyen@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('add-athlete-direct-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên vận động viên.'), findsOneWidget);
    expect(repository.directNames, isEmpty);
    await tester.enterText(nameField, List.filled(256, 'A').join());
    await tester.pump();

    expect(find.text('Tên không được vượt quá 255 ký tự.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-athlete-direct-submit')));
    await tester.pumpAndSettle();

    expect(repository.directNames, isEmpty);
  });

  testWidgets('auto-approval failure is not reported as success', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository(failAutoApprove: true);
    await tester.pumpWidget(
      _app('REGISTRATION_OPEN', managementRepository: repository, entryFee: 0),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    final directTab = find.text('Nhập tên');
    await tester.ensureVisible(directTab);
    await tester.tap(directTab);
    await tester.pumpAndSettle();
    final nameField = find.byKey(const ValueKey('add-athlete-direct-name'));
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Direct athlete');
    await tester.tap(find.byKey(const ValueKey('add-athlete-direct-submit')));
    await tester.pumpAndSettle();

    expect(repository.directNames, ['Direct athlete']);
    expect(repository.statusUpdates.single['status'], 'COMPLETE');
    expect(
      find.text(
        'Đã thêm vận động viên nhưng tự động duyệt thất bại. Hãy kiểm tra danh sách trước khi đổi trạng thái.',
      ),
      findsOneWidget,
    );
    expect(find.text('Đã thêm vận động viên.'), findsNothing);
  });

  testWidgets('positive entry fees do not trigger auto-approval', (
    tester,
  ) async {
    _useMobileViewport(tester);
    var readModelLoads = 0;
    final repository = _TournamentManagementRepository();
    await tester.pumpWidget(
      _app(
        'REGISTRATION_OPEN',
        managementRepository: repository,
        effectiveEntryFee: 100,
        onReadModelLoad: () => readModelLoads++,
      ),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    final directTab = find.text('Nhập tên');
    await tester.ensureVisible(directTab);
    await tester.tap(directTab);
    await tester.pumpAndSettle();
    final nameField = find.byKey(const ValueKey('add-athlete-direct-name'));
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, '  Paid athlete  ');
    await tester.tap(find.byKey(const ValueKey('add-athlete-direct-submit')));
    await tester.pumpAndSettle();

    expect(repository.directNames, ['Paid athlete']);
    expect(readModelLoads, greaterThan(1));
    expect(repository.statusUpdates, isEmpty);
  });

  testWidgets('uncertain candidate submission refreshes but never retries', (
    tester,
  ) async {
    _useMobileViewport(tester);
    var readModelLoads = 0;
    final repository = _TournamentManagementRepository(
      failCandidateAdd: true,
      candidateLoader: (source, query, participantId) async =>
          source == AddAthleteSource.friends
          ? const [
              AddAthleteCandidate(userId: 'uncertain', fullName: 'Uncertain'),
            ]
          : const [],
    );
    await tester.pumpWidget(
      _app(
        'IN_PROGRESS',
        managementRepository: repository,
        onReadModelLoad: () => readModelLoads++,
      ),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('add-athlete-candidate-select-uncertain')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('add-athlete-candidate-submit')),
    );
    await tester.pumpAndSettle();

    expect(repository.candidateAdditions, hasLength(1));
    expect(readModelLoads, greaterThan(1));
    expect(
      find.text(
        'Chưa xác định được kết quả. Danh sách đã được làm mới; hãy kiểm tra trước khi thử lại.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('guest email owned by an account offers to find that account', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository(
      directError: _conflict('EMAIL_BELONGS_TO_ACCOUNT'),
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await _submitGuest(tester, 'An Nguyen', 'an.nguyen@example.com');

    expect(find.text('Email này là tài khoản Sporto'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('add-athlete-find-account')),
      findsOneWidget,
    );
    expect(find.text('An Nguyen'), findsOneWidget);
    expect(find.text('an.nguyen@example.com'), findsOneWidget);
    expect(
      find.text(
        'Chưa xác định được kết quả. Danh sách đã được làm mới; hãy kiểm tra trước khi thử lại.',
      ),
      findsNothing,
    );
  });

  testWidgets('find-account button switches tab and searches that email', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository(
      directError: _conflict('EMAIL_BELONGS_TO_ACCOUNT'),
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await _submitGuest(tester, 'An Nguyen', 'an.nguyen@example.com');
    final button = find.byKey(const ValueKey('add-athlete-find-account'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    final search = tester.widget<TextField>(
      find.byKey(const ValueKey('add-athlete-search')),
    );
    expect(search.controller?.text, 'an.nguyen@example.com');
    expect(repository.emailSearches, ['an.nguyen@example.com']);
    expect(find.byKey(const ValueKey('add-athlete-direct-name')), findsNothing);
  });
  _addAthleteMultiTests();
  _addAthleteLayoutTests();
}

void _addAthleteLayoutTests() {
  testWidgets('sheet opens on the Nhập tên tab, listed before Bạn bè & CLB', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();
    await _openAddAthlete(tester, accountsTab: false);

    expect(
      find.byKey(const ValueKey('add-athlete-direct-name')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('add-athlete-search')), findsNothing);
    final direct = tester.getTopLeft(find.text('Nhập tên')).dx;
    final accounts = tester.getTopLeft(find.text('Bạn bè & CLB')).dx;
    expect(direct, lessThan(accounts));
  });

  testWidgets('direct-entry fields share one height and the score row splits evenly', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();
    await _openAddAthlete(tester, accountsTab: false);

    Size sizeOf(String key) =>
        tester.getSize(find.byKey(ValueKey(key)).first);
    final name = sizeOf('add-athlete-direct-name');
    final email = sizeOf('add-athlete-direct-email');
    final phone = sizeOf('add-athlete-direct-phone');
    final score = sizeOf('add-athlete-direct-score');
    final source = sizeOf('add-athlete-score-source');

    expect(email.height, name.height);
    expect(phone.height, name.height);
    expect(score.height, name.height);
    expect(source.height, name.height);
    expect(score.width, source.width);
    expect(phone.width, name.width);
  });

  testWidgets('filled direct-entry fields keep one height next to the type picker', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();
    await _openAddAthlete(tester, accountsTab: false);
    await _fillDirect(
      tester,
      name: 'An Nguyen',
      email: 'an@example.com',
      phone: '0900000000',
      score: '1500',
    );

    Size sizeOf(String key) => tester.getSize(find.byKey(ValueKey(key)).first);
    final name = sizeOf('add-athlete-direct-name');
    expect(sizeOf('add-athlete-direct-email').height, name.height);
    expect(sizeOf('add-athlete-direct-phone').height, name.height);
    expect(sizeOf('add-athlete-direct-score').height, name.height);
    expect(sizeOf('add-athlete-score-source').height, name.height);

    // Real fonts grow a box once its label floats; a picker always has a value,
    // so every box keeps its label above the value to stay level with it.
    for (final key in [
      'add-athlete-direct-name',
      'add-athlete-direct-email',
      'add-athlete-direct-phone',
      'add-athlete-direct-score',
      'add-athlete-score-source',
    ]) {
      final decorator = tester.widget<InputDecorator>(
        find
            .descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(InputDecorator),
            )
            .first,
      );
      expect(
        decorator.decoration.floatingLabelBehavior,
        FloatingLabelBehavior.always,
        reason: key,
      );
    }
  });
}

Future<void> _openDirectTab(WidgetTester tester) async {
  final directTab = find.text('Nhập tên');
  await tester.ensureVisible(directTab);
  await tester.tap(directTab);
  await tester.pumpAndSettle();
}

Future<void> _fillDirect(
  WidgetTester tester, {
  String? name,
  String? email,
  String? phone,
  String? score,
  String? notes,
}) async {
  Future<void> enter(String key, String? value) async {
    if (value == null) return;
    final field = find.byKey(ValueKey(key));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  await enter('add-athlete-direct-name', name);
  await enter('add-athlete-direct-email', email);
  await enter('add-athlete-direct-phone', phone);
  await enter('add-athlete-direct-score', score);
  await enter('add-athlete-direct-notes', notes);
}

Future<void> _pickDupr(WidgetTester tester) async {
  await _tapKey(tester, 'add-athlete-score-source');
  await tester.tap(find.text('DUPR').last);
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void _addAthleteMultiTests() {
  testWidgets('header shows only the title, no description or tournament line', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);

    expect(
      find.text(
        'Tìm bạn bè, thành viên CLB hoặc nhập tên cho nội dung cá nhân hay đôi.',
      ),
      findsNothing,
    );
    expect(find.textContaining('· Open'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('add-athlete-sheet')),
        matching: find.text('Thêm VĐV'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('direct entry posts phone, notes and a typed DUPR score', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository();
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await _openDirectTab(tester);
    await _fillDirect(
      tester,
      name: 'An Nguyen',
      email: 'an.nguyen@example.com',
      phone: '0900000000',
      score: '4,5',
      notes: 'Left-handed',
    );
    await _pickDupr(tester);
    await _tapKey(tester, 'add-athlete-direct-submit');

    expect(repository.directCalls, hasLength(1));
    final call = repository.directCalls.single;
    expect(call['name'], 'An Nguyen');
    expect(call['email'], 'an.nguyen@example.com');
    expect(call['phone'], '0900000000');
    expect(call['notes'], 'Left-handed');
    expect(call['elo'], 4.5);
    expect(call['eloSource'], 'DUPR');
  });

  testWidgets('a score that is not a number or out of range is blocked', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository();
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await _openDirectTab(tester);
    await _fillDirect(tester, name: 'An Nguyen', score: 'abc');
    await _tapKey(tester, 'add-athlete-direct-submit');
    expect(find.text('Điểm phải là số.'), findsOneWidget);
    expect(repository.directCalls, isEmpty);

    await _pickDupr(tester);
    await _fillDirect(tester, score: '9');
    await _tapKey(tester, 'add-athlete-direct-submit');
    expect(find.text('Điểm DUPR phải từ 1 đến 8.'), findsOneWidget);
    expect(repository.directCalls, isEmpty);
  });

  testWidgets('queued athletes are sent one by one, oldest first', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository();
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await _openDirectTab(tester);
    await _fillDirect(tester, name: 'An Nguyen', email: 'an@example.com');
    await _tapKey(tester, 'add-athlete-direct-queue');
    await _fillDirect(tester, name: 'Binh Tran', email: 'binh@example.com');

    expect(find.text('Thêm (2)'), findsOneWidget);
    await _tapKey(tester, 'add-athlete-direct-submit');

    expect(repository.directNames, ['An Nguyen', 'Binh Tran']);
    expect(find.byKey(const ValueKey('add-athlete-draft-1')), findsNothing);
  });

  testWidgets('newest queued athlete sits on top and can be removed', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await _openDirectTab(tester);
    await _fillDirect(tester, name: 'An Nguyen');
    await _tapKey(tester, 'add-athlete-direct-queue');
    await _fillDirect(tester, name: 'Binh Tran');
    await _tapKey(tester, 'add-athlete-direct-queue');

    final first = tester.getTopLeft(find.text('Binh Tran')).dy;
    final second = tester.getTopLeft(find.text('An Nguyen')).dy;
    expect(first, lessThan(second));
    await _tapKey(tester, 'add-athlete-draft-remove-2');
    expect(find.text('Binh Tran'), findsNothing);
    expect(find.text('An Nguyen'), findsOneWidget);
  });

  testWidgets('queueing a duplicate email is refused', (tester) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(_app('IN_PROGRESS'));
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await _openDirectTab(tester);
    await _fillDirect(tester, name: 'An Nguyen', email: 'an@example.com');
    await _tapKey(tester, 'add-athlete-direct-queue');
    await _fillDirect(tester, name: 'Binh Tran', email: 'AN@example.com');
    await _tapKey(tester, 'add-athlete-direct-queue');

    expect(find.text('VĐV này đã có trong danh sách đang chọn.'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-athlete-draft-2')), findsNothing);
  });

  testWidgets('a rejected queued athlete stays with the reason', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final repository = _TournamentManagementRepository(
      directErrorsByName: {'Binh Tran': _conflict('EMAIL_ALREADY_IN_DIVISION')},
    );
    await tester.pumpWidget(
      _app('IN_PROGRESS', managementRepository: repository),
    );
    await tester.pumpAndSettle();
    await _openAddAthlete(tester);
    await _openDirectTab(tester);
    await _fillDirect(tester, name: 'An Nguyen', email: 'an@example.com');
    await _tapKey(tester, 'add-athlete-direct-queue');
    await _fillDirect(tester, name: 'Binh Tran', email: 'binh@example.com');
    await _tapKey(tester, 'add-athlete-direct-queue');
    await _tapKey(tester, 'add-athlete-direct-submit');

    expect(repository.directNames, ['An Nguyen', 'Binh Tran']);
    expect(find.text('An Nguyen'), findsNothing);
    expect(find.text('Binh Tran'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-athlete-draft-2')), findsOneWidget);
    expect(
      find.textContaining('Đã thêm 1 VĐV; thất bại: 1'),
      findsOneWidget,
    );
  });
}

DioException _conflict(String code) {
  final options = RequestOptions(path: '/tournaments/t/add-athletes/direct');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: 409,
      data: {'statusCode': 409, 'code': code, 'message': 'conflict'},
    ),
  );
}

Future<void> _submitGuest(
  WidgetTester tester,
  String name,
  String email,
) async {
  final directTab = find.text('Nhập tên');
  await tester.ensureVisible(directTab);
  await tester.tap(directTab);
  await tester.pumpAndSettle();
  final nameField = find.byKey(const ValueKey('add-athlete-direct-name'));
  await tester.ensureVisible(nameField);
  await tester.enterText(nameField, name);
  await tester.enterText(
    find.byKey(const ValueKey('add-athlete-direct-email')),
    email,
  );
  await tester.tap(find.byKey(const ValueKey('add-athlete-direct-submit')));
  await tester.pumpAndSettle();
}
