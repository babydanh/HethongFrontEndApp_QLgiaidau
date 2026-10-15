import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/schedule_fullscreen_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 't-1';
const _divisionId = 'd-1';

typedef _ScheduleCall = ({
  String tournamentId,
  String matchId,
  String? courtId,
  String? courtName,
  DateTime? scheduledAt,
  int? durationMinutes,
  Set<MatchScheduleField> clear,
});

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

class _MatchRepository implements IMatchRepository {
  final calls = <_ScheduleCall>[];

  /// Lệch giờ mà server tự áp dụng, mô phỏng việc dời trận khi trùng lịch.
  Duration serverShift = Duration.zero;

  /// Kế hoạch trả về cho xem trước xếp tự động.
  SchedulePlanPreview? plan;

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
    calls.add((
      tournamentId: tournamentId,
      matchId: matchId,
      courtId: courtId,
      courtName: courtName,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      clear: clear,
    ));
    if (clear.isNotEmpty) {
      return (scheduledAt: null, courtId: null, courtName: null);
    }
    return (
      scheduledAt: scheduledAt?.add(serverShift),
      courtId: courtId,
      courtName: courtName,
    );
  }

  @override
  Future<SchedulePlanPreview> previewSchedulePlan(
    String tournamentId, {
    required DateTime day,
    required List<String> courtIds,
    required List<String> matchIds,
    required DateTime windowStart,
    required DateTime windowEnd,
    required int durationMinutes,
    int minimumStartIntervalMinutes = 15,
    int changeoverMinutes = 0,
  }) async =>
      plan ??
      const SchedulePlanPreview(
        durationMinutes: 60,
        assignments: [],
        skipped: [],
        eligibleCount: 0,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Ops schedule drop fixture',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'tournamentConfig': {'operatingStart': '07:00', 'operatingEnd': '08:00'},
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

/// Trận chưa xếp lịch: không có sân, không có giờ -> nằm trong khay.
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

/// Trận đã xếp sân và giờ, nằm trong lưới. Thời lượng mặc định 15 phút.
MatchModel _scheduledMatch({
  required String id,
  required DateTime at,
  int durationMinutes = 15,
}) => MatchModel.fromJson({
  'id': id,
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': 2,
  'status': 'SCHEDULED',
  'team1Name': 'Đội $id A',
  'team2Name': 'Đội $id B',
  'courtId': 'court-1',
  'courtName': 'Sân 1',
  'scheduledTime': at.toUtc().toIso8601String(),
  'durationMinutes': durationMinutes,
}, id);

Future<_MatchRepository> _pump(
  WidgetTester tester, {
  List<MatchModel>? matches,
}) async {
  tester.view.physicalSize = const Size(720, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = _MatchRepository();
  final tournament = _tournament();
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
        matchesWithDivisionProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith(
          (ref) => Stream.value(matches ?? <MatchModel>[_waitingMatch()]),
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

void main() {
  testWidgets('a waiting match sits in the tray and can be dropped on a slot', (
    tester,
  ) async {
    final repository = await _pump(tester);

    // Trận chưa xếp lịch nằm trong khay để kéo.
    final trayItem = find.byKey(const ValueKey('schedule-tray-m-wait'));
    expect(trayItem, findsOneWidget);
    expect(repository.calls, isEmpty);

    final target = find.byKey(const ValueKey('schedule-slot-Sân 1-2'));
    expect(target, findsOneWidget);
    expect(target.hitTestable(), findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(trayItem));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(1));
    final call = repository.calls.single;
    expect(call.matchId, 'm-wait');
    // Phải ghi cả id sân lẫn tên sân: lưới hiển thị theo tên, API cần id.
    expect(call.courtId, 'court-1');
    expect(call.courtName, 'Sân 1');
    expect(call.scheduledAt, isNotNull);
    // Ô thứ 2 = 07:00 + 30 phút, giữ nguyên ngày đang xem.
    expect(call.scheduledAt!.hour, 7);
    expect(call.scheduledAt!.minute, 30);
  });

  testWidgets('a scheduled match is not in the tray', (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('schedule-tray-m-wait')), findsOneWidget);
    // Chỉ trận chưa xếp mới vào khay.
    expect(find.byKey(const ValueKey('schedule-tray-m-live')), findsNothing);
  });

  testWidgets('bulk scheduling lives in the fullscreen workspace only', (
    tester,
  ) async {
    final repository = await _pump(tester);
    expect(repository.calls, isEmpty);

    // Lưới trong tab không có chọn vùng: nhấn giữ rồi kéo không sinh nút xếp lô.
    final inlineStart = tester.getCenter(
      find.byKey(const ValueKey('schedule-slot-Sân 1-0')),
    );
    final inlineGesture = await tester.startGesture(inlineStart);
    await tester.pump(const Duration(milliseconds: 700));
    await inlineGesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('schedule-slot-Sân 1-2'))),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await inlineGesture.up();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('schedule-bulk-schedule-button')),
      findsNothing,
    );

    // Mở không gian toàn màn hình rồi chọn vùng và xác nhận ở đó.
    await tester.tap(find.byKey(const ValueKey('court-grid-fullscreen')));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleFullscreenScreen), findsOneWidget);

    final start = tester.getCenter(
      find.byKey(const ValueKey('schedule-slot-Sân 1-0')),
    );
    final end = tester.getCenter(
      find.byKey(const ValueKey('schedule-slot-Sân 1-2')),
    );
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(end);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    final bulk = find.byKey(const ValueKey('schedule-bulk-schedule-button'));
    expect(bulk, findsOneWidget);
    expect(bulk.hitTestable(), findsOneWidget, reason: 'nút phải nằm trong vùng chạm');
    expect(
      tester.widget<FilledButton>(bulk).onPressed,
      isNotNull,
      reason: 'còn ô trống thì nút phải bật',
    );
    await tester.tap(bulk);
    await tester.pumpAndSettle();

    // Một trận trong khay -> ghi vào ô đầu của vùng, đúng sân và đúng giờ mở cửa.
    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.matchId, 'm-wait');
    expect(repository.calls.single.courtId, 'court-1');
    expect(repository.calls.single.courtName, 'Sân 1');
    expect(repository.calls.single.scheduledAt!.hour, 7);
    expect(repository.calls.single.scheduledAt!.minute, 0);
  });

  testWidgets('the fullscreen button opens a real fullscreen workspace', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(ScheduleFullscreenScreen), findsNothing);

    final button = find.byKey(const ValueKey('court-grid-fullscreen'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Không gian toàn màn hình là màn riêng, có lưới bên trong.
    expect(find.byType(ScheduleFullscreenScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ScheduleFullscreenScreen),
        matching: find.byType(ScheduleGrid),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('schedule-fullscreen-close')));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleFullscreenScreen), findsNothing);
  });

  testWidgets('tapping an empty cell offers waiting matches and schedules the pick there', (
    tester,
  ) async {
    final repository = await _pump(
      tester,
      matches: [
        _waitingMatch(),
        _scheduledMatch(id: 'm-sched', at: DateTime(2026, 6, 1, 7)),
      ],
    );

    final cell = find.byKey(const ValueKey('schedule-slot-Sân 1-2'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();

    expect(find.text('Xếp trận vào Sân 1 lúc 07:30'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schedule-picker-m-wait')));
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(1));
    final call = repository.calls.single;
    expect(call.matchId, 'm-wait');
    expect(call.courtId, 'court-1');
    expect(call.courtName, 'Sân 1');
    expect(
      call.scheduledAt!.isAtSameMomentAs(DateTime(2026, 6, 1, 7, 30)),
      isTrue,
    );
  });

  testWidgets('a scheduled card opens the quick sheet and Gỡ lịch clears only court and time', (
    tester,
  ) async {
    final repository = await _pump(
      tester,
      matches: [
        _waitingMatch(),
        _scheduledMatch(id: 'm-sched', at: DateTime(2026, 6, 1, 7)),
      ],
    );

    final card = find.byKey(const ValueKey('schedule-match-m-sched'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Xếp nhanh'), findsOneWidget);
    await tester.tap(find.text('Gỡ lịch'));
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(1));
    final call = repository.calls.single;
    expect(call.matchId, 'm-sched');
    // Gỡ lịch chỉ xoá sân và giờ; không gửi thời lượng hay trường khác.
    expect(call.clear, {
      MatchScheduleField.courtId,
      MatchScheduleField.courtName,
      MatchScheduleField.scheduledAt,
    });
    expect(call.durationMinutes, isNull);
  });

  testWidgets('a quick edit that overlaps another match on the same court is refused', (
    tester,
  ) async {
    final repository = await _pump(
      tester,
      matches: [
        _scheduledMatch(id: 'm-first', at: DateTime(2026, 6, 1, 7, 45)),
        _scheduledMatch(id: 'm-second', at: DateTime(2026, 6, 1, 7, 30)),
      ],
    );

    // Kéo dài m-second lên 30 phút thì chồng lên m-first lúc 07:45.
    final card = find.byKey(const ValueKey('schedule-match-m-second'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 phút').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu Thay Đổi'));
    await tester.pumpAndSettle();

    expect(find.text('Trùng sân và giờ với trận khác.'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('a slot the server moved tells the organizer', (tester) async {
    final repository = await _pump(
      tester,
      matches: [
        _waitingMatch(),
        _scheduledMatch(id: 'm-sched', at: DateTime(2026, 6, 1, 7)),
      ],
    );
    // Server dời trận 15 phút so với yêu cầu.
    repository.serverShift = const Duration(minutes: 15);

    final cell = find.byKey(const ValueKey('schedule-slot-Sân 1-2'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-picker-m-wait')));
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(1));
    expect(find.textContaining('Máy chủ đã dời 1 trận'), findsOneWidget);
  });

  testWidgets('⚡ auto schedule shows a draft on the grid and writes it only when applied', (
    tester,
  ) async {
    final repository = await _pump(
      tester,
      matches: [
        _waitingMatch(),
        _scheduledMatch(id: 'm-sched', at: DateTime(2026, 6, 1, 7)),
      ],
    );
    repository.plan = SchedulePlanPreview(
      durationMinutes: 45,
      assignments: [
        (
          matchId: 'm-wait',
          courtId: 'court-1',
          scheduledAt: DateTime(2026, 6, 1, 7, 45),
        ),
      ],
      skipped: const [],
      eligibleCount: 1,
    );

    final auto = find.byKey(const ValueKey('schedule-auto-button'));
    await tester.ensureVisible(auto);
    await tester.tap(auto);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem trước'));
    await tester.pumpAndSettle();

    // Xem trước chỉ hiện bản nháp, chưa ghi gì xuống server.
    expect(repository.calls, isEmpty);
    final apply = find.byKey(const ValueKey('schedule-draft-apply'));
    expect(apply, findsOneWidget);
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(1));
    final call = repository.calls.single;
    expect(call.matchId, 'm-wait');
    expect(call.courtId, 'court-1');
    expect(
      call.scheduledAt!.isAtSameMomentAs(DateTime(2026, 6, 1, 7, 45)),
      isTrue,
    );
    // Ghi đúng thời lượng mà máy chủ đã dùng để tính khung giờ.
    expect(call.durationMinutes, 45);
  });

  testWidgets('dragging a scheduled card onto another asks first, then swaps both', (
    tester,
  ) async {
    final repository = await _pump(
      tester,
      matches: [
        _scheduledMatch(id: 'm-a', at: DateTime(2026, 6, 1, 7)),
        _scheduledMatch(id: 'm-b', at: DateTime(2026, 6, 1, 7, 30)),
      ],
    );

    final from = tester.getCenter(
      find.byKey(const ValueKey('schedule-match-m-a')),
    );
    final to = tester.getCenter(
      find.byKey(const ValueKey('schedule-match-m-b')),
    );
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(to);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Đổi chỗ hai trận?'), findsOneWidget);
    expect(repository.calls, isEmpty);
    await tester.tap(find.text('Đổi chỗ'));
    await tester.pumpAndSettle();

    // Đổi chỗ có thể gồm bước gỡ trận đích để tránh trùng lịch; chỉ kiểm tra
    // trạng thái cuối của hai trận: mỗi trận nằm ở ô của trận kia.
    expect(repository.calls.map((call) => call.matchId).toSet(), {'m-a', 'm-b'});
    final finalA = repository.calls.lastWhere((call) => call.matchId == 'm-a');
    final finalB = repository.calls.lastWhere((call) => call.matchId == 'm-b');
    expect(
      finalA.scheduledAt!.isAtSameMomentAs(DateTime(2026, 6, 1, 7, 30)),
      isTrue,
    );
    expect(
      finalB.scheduledAt!.isAtSameMomentAs(DateTime(2026, 6, 1, 7)),
      isTrue,
    );
  });
}
