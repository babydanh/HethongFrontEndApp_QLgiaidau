import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
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

/// Đếm số lần nguồn trận quản lý được đăng ký lại: sau khi lô từ khay chờ ghi
/// xong, màn phải tải lại (spec "Thao tác ghi làm mới nguồn trận quản lý").
class _StreamCounter {
  int builds = 0;
}

class _VenuesRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'Nhà thi đấu',
      'courts': [
        {'id': 'court-1', 'name': 'Sân 1'},
        {'id': 'court-2', 'name': 'Sân 2'},
        {'id': 'court-3', 'name': 'Sân 3'},
        {'id': 'court-4', 'name': 'Sân 4'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrayMatchRepository implements IMatchRepository {
  final calls = <_ScheduleCall>[];

  /// Trễ mỗi lần ghi để test kịp bấm Huỷ khi trận sau đang ghi.
  Duration delay = Duration.zero;

  /// Trận ghi lỗi (ném) — dây chuyền từ khay chờ phải dừng.
  final Set<String> failIds = {};

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
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (failIds.contains(matchId)) {
      throw Exception('ghi lịch lỗi');
    }
    return (scheduledAt: scheduledAt, courtId: courtId, courtName: courtName);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Waiting tray fixture',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'tournamentConfig': {'operatingStart': '07:00', 'operatingEnd': '22:00'},
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

/// Trận chờ: chưa có sân và giờ, thời lượng 30 phút để dây chuyền cách đều.
MatchModel _waitingMatch(String id, int number) => MatchModel.fromJson({
  'id': id,
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': number,
  'status': 'SCHEDULED',
  'team1Name': 'Đội $number A',
  'team2Name': 'Đội $number B',
  'durationMinutes': 30,
}, id);

List<MatchModel> _waitingMatches(int count) => [
  for (var i = 1; i <= count; i++) _waitingMatch('m-wait-$i', i),
];

Future<(_TrayMatchRepository, _StreamCounter)> _pump(
  WidgetTester tester, {
  required List<MatchModel> matches,
}) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = _TrayMatchRepository();
  final counter = _StreamCounter();
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
        managedMatchesWithDivisionProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith((ref) {
          counter.builds++;
          return Stream.value(matches);
        }),
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
  return (repository, counter);
}

/// Cuộn tới widget rồi mới bấm: khay nằm sâu dưới đáy trang, tap trước khi cuộn
/// xong sẽ trượt ra ngoài màn hình.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _pickDropdown(WidgetTester tester, Key key, String label) async {
  final button = find.byKey(key);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-WP-04-04: dồn 5 trận lên Sân 4 lúc 13:00 xếp nối tiếp 30 phút/l trận',
    (tester) async {
      final (repository, counter) = await _pump(
        tester,
        matches: _waitingMatches(5),
      );
      expect(repository.calls, isEmpty);

      // Chạm một chip để tích chọn, chạm lần nữa để bỏ (checkbox).
      final chip1 = find.byKey(const ValueKey('schedule-tray-m-wait-1'));
      await _tapVisible(tester, chip1);
      expect(
        find.descendant(
          of: chip1,
          matching: find.byIcon(Icons.check_box_rounded),
        ),
        findsOneWidget,
      );
      await _tapVisible(tester, chip1);
      expect(
        find.descendant(
          of: chip1,
          matching: find.byIcon(Icons.check_box_rounded),
        ),
        findsNothing,
      );

      // Chọn tất cả: cả 5 chip có dấu tích.
      final toggleAll = find.byKey(const ValueKey('schedule-tray-toggle-all'));
      await _tapVisible(tester, toggleAll);
      expect(
        find.byIcon(Icons.check_box_rounded),
        findsNWidgets(5),
        reason: 'chọn tất cả phải tích đủ 5 trận chờ',
      );
      expect(find.text('Bỏ chọn hết'), findsOneWidget);

      // Chọn sân đích và khung giờ bắt đầu.
      await _pickDropdown(
        tester,
        const ValueKey('schedule-tray-court'),
        'Sân 4',
      );
      await _pickDropdown(
        tester,
        const ValueKey('schedule-tray-start'),
        '13:00',
      );

      final submit = find.byKey(const ValueKey('schedule-tray-submit'));
      expect(find.text('Xếp 5 trận đã chọn vào sân'), findsOneWidget);
      await _tapVisible(tester, submit);
      await tester.pumpAndSettle();

      // 5 trận được xếp nối tiếp trên Sân 4 từ 13:00, mỗi trận 30 phút.
      expect(repository.calls, hasLength(5));
      for (var i = 0; i < 5; i++) {
        final call = repository.calls[i];
        expect(call.matchId, 'm-wait-${i + 1}');
        expect(call.courtId, 'court-4', reason: 'sân đích phải là Sân 4');
        expect(call.courtName, 'Sân 4');
        expect(call.durationMinutes, 30);
        expect(call.scheduledAt!.hour, 13 + (i * 30) ~/ 60);
        expect(call.scheduledAt!.minute, (i * 30) % 60);
      }
      expect(find.textContaining('Đã xếp 5/5 trận nối tiếp.'), findsOneWidget);

      // Ghi xong phải tải lại nguồn trận quản lý (invalidate).
      expect(counter.builds, greaterThan(1), reason: 'phải tải lại nguồn trận');
    },
  );

  testWidgets('huỷ giữa chừng dừng sau trận đang ghi và báo đã xếp i/N', (
    tester,
  ) async {
    final (repository, _) = await _pump(tester, matches: _waitingMatches(3));
    repository.delay = const Duration(milliseconds: 50);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('schedule-tray-toggle-all')),
    );
    final submit = find.byKey(const ValueKey('schedule-tray-submit'));
    await _tapVisible(tester, submit);
    expect(find.text('Đang ghi 0/3'), findsOneWidget);

    // Trận 1 ghi xong, trận 2 đang ghi.
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Đang ghi 1/3'), findsOneWidget);

    // Bấm Huỷ khi trận 2 đang ghi. KHÔNG pumpAndSettle trước bấm: nó đẩy đồng
    // hồ ảo qua hết chuỗi ghi thì nút Huỷ đã biến mất.
    await tester.tap(find.byKey(const ValueKey('schedule-tray-cancel')));

    // Trận 2 kết thúc rồi dây chuyền dừng, trận 3 không được gọi.
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(repository.calls, hasLength(2));
    expect(repository.calls[0].matchId, 'm-wait-1');
    expect(repository.calls[1].matchId, 'm-wait-2');
    expect(
      find.text('Đã xếp 2/3 trận rồi dừng theo yêu cầu huỷ.'),
      findsOneWidget,
    );
  });

  testWidgets('lỗi giữa chừng dừng và báo đã xếp i/N, phần còn lại giữ chọn', (
    tester,
  ) async {
    final (repository, counter) = await _pump(
      tester,
      matches: _waitingMatches(3),
    );
    repository.failIds.add('m-wait-2');

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('schedule-tray-toggle-all')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('schedule-tray-submit')),
    );
    await tester.pumpAndSettle();

    // Trận 1 ghi xong, trận 2 lỗi: dừng, trận 3 không được gọi.
    expect(repository.calls, hasLength(2));
    expect(repository.calls[0].matchId, 'm-wait-1');
    expect(repository.calls[1].matchId, 'm-wait-2');
    expect(
      find.text('Đã xếp 1/3 trận rồi dừng vì có trận chưa xếp được.'),
      findsOneWidget,
    );

    // Hai trận còn lại vẫn đang chọn, xác nhận lại được ngay.
    expect(find.text('Xếp 2 trận đã chọn vào sân'), findsOneWidget);
    // Lỗi cũng phải tải lại nguồn trận quản lý.
    expect(counter.builds, greaterThan(1));
  });

  group('standalone grid tray', () {
    Future<void> pumpGrid(
      WidgetTester tester, {
      required List<MatchModel> matches,
      required Future<bool> Function(MatchModel match) onWrite,
      VoidCallback? onFinished,
    }) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentManagementRepositoryProvider.overrideWithValue(
              _VenuesRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: TournamentScheduleCourtGrid(
                  tournamentId: _tournamentId,
                  matches: matches,
                  scheduleSettings: const {
                    'operatingStart': '07:00',
                    'operatingEnd': '22:00',
                  },
                  onTapMatch: (_) {},
                  onScheduleDrop: (_, _, _, _) {},
                  onScheduleWaitingWrite: (match, _, _, _) => onWrite(match),
                  onWaitingBatchFinished: onFinished,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('batch finish callback still runs when the grid is disposed '
        'after some matches were written', (tester) async {
      var finished = 0;
      final second = Completer<bool>();
      await pumpGrid(
        tester,
        matches: _waitingMatches(2),
        onWrite: (match) =>
            match.id == 'm-wait-1' ? Future.value(true) : second.future,
        onFinished: () => finished++,
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('schedule-tray-toggle-all')),
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('schedule-tray-submit')),
      );
      await tester.pump();

      // Dispose the grid while match 2 is still being written.
      await tester.pumpWidget(const SizedBox.shrink());
      second.complete(true);
      await tester.pump();

      expect(finished, 1, reason: 'the first match was written already');
    });

    testWidgets('cancel button greys out right after it is pressed', (
      tester,
    ) async {
      final gate = Completer<bool>();
      await pumpGrid(
        tester,
        matches: _waitingMatches(2),
        onWrite: (_) => gate.future,
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('schedule-tray-toggle-all')),
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('schedule-tray-submit')),
      );
      await tester.pump();

      final cancel = find.byKey(const ValueKey('schedule-tray-cancel'));
      expect(tester.widget<TextButton>(cancel).onPressed, isNotNull);
      await tester.tap(cancel);
      await tester.pump();
      expect(tester.widget<TextButton>(cancel).onPressed, isNull);

      gate.complete(false);
      await tester.pumpAndSettle();
    });

    testWidgets('a stale selected id does not make a written match stay '
        'selected after a partial failure', (tester) async {
      final all = _waitingMatches(3); // 1 will vanish, 2 and 3 are submitted
      await pumpGrid(
        tester,
        matches: all,
        onWrite: (match) async => match.id != 'm-wait-3',
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('schedule-tray-toggle-all')),
      );

      // Match 1 leaves the waiting list (placed elsewhere) but stays in the
      // raw selection ids.
      await pumpGrid(
        tester,
        matches: all.sublist(1),
        onWrite: (match) async => match.id != 'm-wait-3',
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('schedule-tray-submit')),
      );
      await tester.pumpAndSettle();

      // Match 2 was written, match 3 failed: only match 3 remains selected.
      expect(find.text('Xếp 1 trận đã chọn vào sân'), findsOneWidget);
    });
  });
}
