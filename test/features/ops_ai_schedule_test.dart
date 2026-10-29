import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-WP-04-07/08 (task 4.5): nút "AI xếp lịch" trên lưới, bản nháp AI dùng
/// lại thanh "Áp dụng / Huỷ" của xếp tự động, 404 ẩn mục AI mà lưới vẫn dùng được.
const _tournamentId = 't-1';
const _divisionId = 'd-1';

class _VenuesRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'Nhà thi đấu',
      'courts': [
        {'id': 'court-1', 'name': 'Sân 1'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AiCall {
  _AiCall({
    required this.command,
    required this.courtIds,
    required this.divisionId,
    required this.windowStart,
    required this.windowEnd,
  });

  final String command;
  final List<String> courtIds;
  final String? divisionId;
  final DateTime windowStart;
  final DateTime windowEnd;
}

class _MatchRepository implements IMatchRepository {
  final aiCalls = <_AiCall>[];
  final writes = <String>[];

  /// Kế hoạch AI trả về; [aiError] ưu tiên hơn nếu có.
  AiSchedulePlan? aiPlan;
  Object? aiError;

  @override
  Stream<List<MatchModel>> watchManagedByTournament(
    String tournamentId, {
    String? divisionId,
  }) => Stream.value(const []);

  @override
  Future<AiSchedulePlan> previewScheduleWithAi(
    String tournamentId, {
    required String command,
    required DateTime day,
    required List<String> courtIds,
    required DateTime windowStart,
    required DateTime windowEnd,
    String? divisionId,
    int gridIncrementMinutes = 15,
    String? locale,
  }) async {
    aiCalls.add(
      _AiCall(
        command: command,
        courtIds: courtIds,
        divisionId: divisionId,
        windowStart: windowStart,
        windowEnd: windowEnd,
      ),
    );
    final error = aiError;
    if (error != null) throw error;
    return aiPlan!;
  }

  @override
  Future<MatchScheduleSnapshot> updateSchedule(
    String tournamentId,
    String matchId, {
    String? courtName,
    String? courtAddress,
    String? courtId,
    String? refereeId,
    DateTime? scheduledAt,
    int? durationMinutes,
    Set<MatchScheduleField> clear = const {},
  }) async {
    writes.add(matchId);
    return (scheduledAt: scheduledAt, courtId: courtId, courtName: courtName);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament({String status = 'in_progress'}) => Tournament.fromJson({
  'name': 'Ops AI schedule fixture',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': status,
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'tournamentConfig': {'operatingStart': '07:00', 'operatingEnd': '12:00'},
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

MatchModel _waitingMatch() => MatchModel.fromJson({
  'id': 'm-wait',
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': 'Đội A',
  'team2Name': 'Đội B',
}, 'm-wait');

AiSchedulePlan _plan({List<String> matchIds = const ['m-wait']}) =>
    AiSchedulePlan(
      needsReview: false,
      explanation: 'Vòng 1 từ 8h',
      plan: SchedulePlanPreview(
        durationMinutes: 30,
        assignments: [
          for (final id in matchIds)
            (
              matchId: id,
              courtId: 'court-1',
              scheduledAt: DateTime(2026, 6, 1, 8),
            ),
        ],
        skipped: const [],
        eligibleCount: matchIds.length,
      ),
    );

Future<_MatchRepository> _pump(
  WidgetTester tester, {
  String status = 'in_progress',
}) async {
  tester.view.physicalSize = const Size(720, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = _MatchRepository();
  final tournament = _tournament(status: status);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream<Tournament?>.value(tournament)),
        tournamentDivisionsProvider(_tournamentId).overrideWith(
          (ref) async => [
            {'id': _divisionId, 'name': 'Open', 'matchType': 'DOUBLES'},
          ],
        ),
        managedMatchesWithDivisionProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith((ref) => Stream.value(<MatchModel>[_waitingMatch()])),
        tournamentManagementRepositoryProvider.overrideWithValue(
          _VenuesRepository(),
        ),
        matchRepositoryProvider.overrideWithValue(repository),
        organizerOpsReadModelProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith(
          (ref) async => const OrganizerOpsReadModel(
            participants: [],
            referees: [],
            auditEntries: [],
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OrganizerOpsScreen(
          tournamentId: _tournamentId,
          initialDivisionId: _divisionId,
          view: OrganizerOpsView.matches,
          initialMatchesView: OrganizerOpsMatchesView.grid,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

final _aiButton = find.byKey(const ValueKey('schedule-ai-button'));

/// The AI and auto entries live in the ⋯ menu of the schedule toolbar.
Future<void> _openScheduleMenu(WidgetTester tester) async {
  final more = find.byKey(const ValueKey('schedule-more-button'));
  await tester.ensureVisible(more);
  await tester.tap(more);
  await tester.pumpAndSettle();
}

Future<void> _openAndPreview(WidgetTester tester, String command) async {
  await _openScheduleMenu(tester);
  await tester.tap(_aiButton);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('ai-schedule-command')),
    command,
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('ai-schedule-preview')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'an AI plan shows as a draft on the grid and is written only when applied',
    (tester) async {
      final repository = await _pump(tester);
      repository.aiPlan = _plan();

      await _openAndPreview(tester, 'vòng 1 từ 8h');

      final call = repository.aiCalls.single;
      expect(call.command, 'vòng 1 từ 8h');
      expect(call.courtIds, ['court-1']);
      expect(call.divisionId, _divisionId);
      expect(call.windowEnd.difference(call.windowStart).inHours, 5);
      // Xem trước chỉ hiện bản nháp, chưa ghi gì xuống server.
      expect(repository.writes, isEmpty);
      final apply = find.byKey(const ValueKey('schedule-draft-apply'));
      expect(apply, findsOneWidget);

      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();

      expect(repository.writes, ['m-wait']);
    },
  );

  testWidgets(
    'a 404 from the AI route hides the AI entry while the rest of the grid keeps working',
    (tester) async {
      final repository = await _pump(tester);
      repository.aiError = const AiScheduleUnavailableException();

      await _openAndPreview(tester, 'vòng 1 từ 8h');

      await _openScheduleMenu(tester);
      expect(_aiButton, findsNothing);
      expect(
        find.byKey(const ValueKey('schedule-auto-button')),
        findsOneWidget,
      );
      expect(
        find.text('AI xếp lịch chưa dùng được trên máy chủ này.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a plan that matches no waiting match shows no draft and keeps the sheet open',
    (tester) async {
      final repository = await _pump(tester);
      repository.aiPlan = _plan(matchIds: const ['unknown-match']);

      await _openAndPreview(tester, 'vòng 1 từ 8h');

      expect(find.textContaining('AI chưa xếp được trận nào'), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule-draft-apply')), findsNothing);
      expect(find.byKey(const ValueKey('ai-schedule-command')), findsOneWidget);
    },
  );

  testWidgets('a finished tournament is read-only and offers no AI entry', (
    tester,
  ) async {
    await _pump(tester, status: 'COMPLETED');
    await _openScheduleMenu(tester);

    expect(_aiButton, findsNothing);
  });
}
