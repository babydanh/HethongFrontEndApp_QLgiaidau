import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
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

  @override
  Future<void> updateSchedule(
    String tournamentId,
    String matchId, {
    String? courtName,
    String? courtAddress,
    String? courtId,
    String? refereeId,
    DateTime? scheduledAt,
  }) async {
    calls.add((
      tournamentId: tournamentId,
      matchId: matchId,
      courtId: courtId,
      courtName: courtName,
      scheduledAt: scheduledAt,
    ));
  }

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

Future<_MatchRepository> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(720, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final matches = _MatchRepository();
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
        )).overrideWith((ref) => Stream.value([_waitingMatch()])),
        tournamentManagementRepositoryProvider.overrideWithValue(
          _VenuesRepository(),
        ),
        matchRepositoryProvider.overrideWithValue(matches),
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
  return matches;
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
}
