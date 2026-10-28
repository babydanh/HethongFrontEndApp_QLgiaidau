import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_schedule_dialog.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tid = 'tour-1';

/// Value the dialog resolved to in the last `_open` run.
bool? _result;

class _Call {
  _Call({required this.courtId, required this.clear, this.scheduledAt});
  final String? courtId;
  final Set<MatchScheduleField> clear;
  final DateTime? scheduledAt;
}

class _FakeMatchRepo extends Fake implements IMatchRepository {
  final calls = <_Call>[];
  Completer<MatchScheduleSnapshot>? gate;
  Object? failure;

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
    calls.add(_Call(courtId: courtId, clear: clear, scheduledAt: scheduledAt));
    final failure = this.failure;
    if (failure != null) throw failure;
    final gate = this.gate;
    if (gate != null) return gate.future;
    return (scheduledAt: scheduledAt, courtId: courtId, courtName: courtName);
  }
}

class _FakeManagementRepo extends Fake
    implements TournamentManagementRepository {
  _FakeManagementRepo(this.venues);
  final List<Map<String, dynamic>> venues;

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => venues;
}

MatchModel _match({
  String status = 'SCHEDULED',
  DateTime? scheduledTime,
  String? courtId,
}) {
  return MatchModel(
    id: 'm1',
    tournamentId: _tid,
    round: 1,
    matchNumber: 1,
    bracketPosition: const BracketPosition(round: 1, position: 1),
    team1Id: 'a',
    team2Id: 'b',
    status: status,
    scheduledTime: scheduledTime,
    courtId: courtId,
    updatedAt: DateTime(2026, 1, 1),
  );
}

const _venues = <Map<String, dynamic>>[
  {
    'courts': [
      {'id': 'c1', 'name': 'Sân 1'},
      {'id': 'c2', 'name': 'Sân 2'},
    ],
  },
];

Future<void> Function() _open(
  WidgetTester tester,
  _FakeMatchRepo repo,
  MatchModel match, {
  List<Map<String, dynamic>> venues = _venues,
}) {
  return () async {
    _result = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchRepositoryProvider.overrideWithValue(repo),
          tournamentManagementRepositoryProvider.overrideWithValue(
            _FakeManagementRepo(venues),
          ),
          tournamentProvider(_tid).overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => _result = await showMatchScheduleDialog(
                  context,
                  tournamentId: _tid,
                  match: match,
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
  };
}

void main() {
  testWidgets('save sends one update with the chosen court and closes true', (
    tester,
  ) async {
    final repo = _FakeMatchRepo();
    await _open(tester, repo, _match())();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.courtId, 'c1');
    expect(repo.calls.single.scheduledAt, isNotNull);
    expect(find.text('Xếp lịch trận'), findsNothing);
    expect(_result, isTrue);
  });

  testWidgets('double tap on save sends a single request', (tester) async {
    final repo = _FakeMatchRepo()..gate = Completer();
    await _open(tester, repo, _match())();

    await tester.tap(find.text('Lưu'));
    await tester.pump();
    await tester.tap(find.text('Lưu'), warnIfMissed: false);
    await tester.pump();

    expect(repo.calls, hasLength(1));
    repo.gate!.complete((scheduledAt: null, courtId: null, courtName: null));
    await tester.pumpAndSettle();
  });

  testWidgets('a failed save keeps the dialog open with a friendly error', (
    tester,
  ) async {
    final repo = _FakeMatchRepo()
      ..failure = DioException(requestOptions: RequestOptions(path: '/x'));
    await _open(tester, repo, _match())();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Xếp lịch trận'), findsOneWidget);
    expect(find.textContaining('DioException'), findsNothing);
    // The save button is usable again so the organiser can retry.
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(repo.calls, hasLength(2));
  });

  testWidgets(
    'clear schedule sends the clear set, only for a scheduled match',
    (tester) async {
      final repo = _FakeMatchRepo();
      await _open(
        tester,
        repo,
        _match(scheduledTime: DateTime(2026, 5, 1, 9), courtId: 'c2'),
      )();

      await tester.tap(find.text('Gỡ lịch'));
      await tester.pumpAndSettle();

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.clear, {
        MatchScheduleField.courtId,
        MatchScheduleField.courtName,
        MatchScheduleField.scheduledAt,
      });
    },
  );

  testWidgets('an unscheduled match has no clear button', (tester) async {
    await _open(tester, _FakeMatchRepo(), _match())();
    expect(find.text('Gỡ lịch'), findsNothing);
  });

  testWidgets('a locked match does not open the dialog', (tester) async {
    final repo = _FakeMatchRepo();
    await _open(tester, repo, _match(status: 'COMPLETED'))();
    expect(find.text('Xếp lịch trận'), findsNothing);
  });

  testWidgets('a tournament without courts shows the message, not the form', (
    tester,
  ) async {
    await _open(tester, _FakeMatchRepo(), _match(), venues: const [])();
    expect(find.text('Lưu'), findsNothing);
    expect(find.textContaining('chưa có sân'), findsOneWidget);
  });
}
