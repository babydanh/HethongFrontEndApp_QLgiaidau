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

/// TC-WP-04-06 — Cảnh báo VĐV trùng giờ (task 4.4): sau thao tác ghi (thả trận
/// vào ô lưới) mà một VĐV có hai trận cùng giờ trên hai sân, App hiện sheet
/// cảnh báo liệt kê hai trận, hai sân và tên VĐV trùng (spec MODIFIED
/// "Thao tác ghi làm mới nguồn trận quản lý", scenario "VĐV bị xếp trùng giờ").
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
        {'id': 'court-2', 'name': 'Sân 2'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MatchRepository implements IMatchRepository {
  _MatchRepository(this.matches);

  /// Danh sách trận "server" đang lưu: updateSchedule ghi vào đây để lần đọc
  /// nguồn sau ghi (invalidate) thấy đúng vị trí mới.
  List<Map<String, dynamic>> matches;

  @override
  Stream<List<MatchModel>> watchManagedByTournament(
    String tournamentId, {
    String? divisionId,
  }) async* {
    yield [
      for (final json in matches)
        MatchModel.fromJson(json, json['id'] as String),
    ];
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
    if (clear.isEmpty) {
      for (var i = 0; i < matches.length; i++) {
        if (matches[i]['id'] == matchId) {
          matches[i] = {
            ...matches[i],
            'courtId': courtId,
            'courtName': courtName,
            'scheduledTime': scheduledAt?.toUtc().toIso8601String(),
            'durationMinutes': durationMinutes ?? 30,
          };
        }
      }
    }
    return (scheduledAt: scheduledAt, courtId: courtId, courtName: courtName);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Conflicts fixture',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'tournamentConfig': {'operatingStart': '07:00', 'operatingEnd': '10:00'},
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

/// Trận chờ trong khay, cùng VĐV "p-a" (Đội A) với trận đã xếp trên Sân 1.
Map<String, dynamic> _waitingJson(String participantId) => {
  'id': 'm-wait',
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'participant1Id': participantId,
  'team1Name': 'Đội A',
  'team2Name': 'Đội B',
};

Map<String, dynamic> _scheduledJson() => {
  'id': 'm-fixed',
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': 2,
  'status': 'SCHEDULED',
  'participant1Id': 'p-a',
  'team1Name': 'Đội A',
  'team2Name': 'Đội C',
  'courtId': 'court-1',
  'courtName': 'Sân 1',
  'scheduledTime': DateTime(2026, 10, 26, 8, 0).toUtc().toIso8601String(),
  'durationMinutes': 30,
};

Future<_MatchRepository> _pump(
  WidgetTester tester, {
  required String waitingParticipantId,
}) async {
  // Cao hơn mặc định: lưới 12 ô (07:00-10:00) + khay chờ phải cùng nằm trong
  // viewport để kéo-thả từ khay trúng ô lưới.
  tester.view.physicalSize = const Size(720, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = _MatchRepository([
    _scheduledJson(),
    _waitingJson(waitingParticipantId),
  ]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream<Tournament?>.value(_tournament())),
        tournamentDivisionsProvider(_tournamentId).overrideWith(
          (ref) async => [
            {'id': _divisionId, 'name': 'Open', 'matchType': 'DOUBLES'},
          ],
        ),
        managedMatchesWithDivisionProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith(
          (ref) => repository.watchManagedByTournament(_tournamentId),
        ),
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

/// Kéo trận chờ từ khay thả vào ô [slotKey] của lưới.
Future<void> _dropWaitingChip(WidgetTester tester, Key slotKey) async {
  final trayItem = find.byKey(const ValueKey('schedule-tray-m-wait'));
  expect(trayItem, findsOneWidget);
  final target = find.byKey(slotKey);
  expect(target, findsOneWidget);
  final gesture = await tester.startGesture(tester.getCenter(trayItem));
  await tester.pump(const Duration(milliseconds: 700));
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-WP-04-06: thả trận làm VĐV trùng giờ hai sân — hiện sheet cảnh báo đủ trận/sân/giờ/VĐV',
    (tester) async {
      final repository = await _pump(tester, waitingParticipantId: 'p-a');

      // Ô 08:15 của Sân 2 (07:00 mở cửa, bước 15 phút -> ô thứ 5).
      await _dropWaitingChip(tester, const ValueKey('schedule-slot-Sân 2-5'));

      // Sheet cảnh báo hiện sau thao tác ghi, liệt kê đủ 2 trận.
      expect(find.text('Cảnh báo trùng lịch thi đấu (2 trận)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('schedule-conflict-group-m-fixed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('schedule-conflict-group-m-wait')),
        findsOneWidget,
      );
      // Dòng cảnh báo nêu đúng VĐV trùng, sân và giờ của trận kia.
      expect(
        find.textContaining('cũng đang có lịch đấu tại Sân 2 lúc 08:15'),
        findsOneWidget,
      );
      expect(
        find.textContaining('cũng đang có lịch đấu tại Sân 1 lúc 08:00'),
        findsOneWidget,
      );
      expect(find.textContaining('Đội A'), findsWidgets);
    },
  );

  testWidgets('thả trận không trùng ai — không mở sheet cảnh báo', (
    tester,
  ) async {
    // VĐV khác (p-z) không trùng trận đã xếp.
    await _pump(tester, waitingParticipantId: 'p-z');

    await _dropWaitingChip(tester, const ValueKey('schedule-slot-Sân 2-5'));

    expect(find.textContaining('Cảnh báo trùng lịch thi đấu'), findsNothing);
  });
}
