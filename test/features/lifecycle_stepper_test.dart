import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_stepper.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake management repo: fixed fee config, records lifecycle calls.
class _Repo implements TournamentManagementRepository {
  _Repo({this.publishFee = 0});

  final num publishFee;
  var closeCalls = 0;
  var publishCalls = 0;

  @override
  Future<Map<String, dynamic>> getFeesConfig() async => {
    'feeClub': publishFee,
    'feePublicRanked': publishFee,
    'feePublicUnranked': publishFee,
  };

  @override
  Future<Map<String, dynamic>> closeRegistration(String id) async {
    closeCalls++;
    return {};
  }

  @override
  Future<Map<String, dynamic>> publishTournament(String id) async {
    publishCalls++;
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament({
  String status = 'DRAFT',
  Map<String, dynamic>? capacity,
  String name = 'Giải thử',
}) => Tournament.fromJson({
  'name': name,
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 16,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  'capacity': ?capacity,
}, 'tournament-1');

Widget _wrap(Widget child, {_Repo? repo}) => ProviderScope(
  overrides: [
    if (repo != null)
      tournamentManagementRepositoryProvider.overrideWithValue(repo),
  ],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('model', () {
    test(
      'lifecycleStepIndex: 4 bước như Web, nháp chưa sáng, huỷ không có bước',
      () {
        expect(lifecycleStepIndex(AppConstants.statusDraft), -1);
        expect(lifecycleStepIndex(AppConstants.statusUpcoming), 0);
        expect(lifecycleStepIndex(AppConstants.statusRegistration), 0);
        expect(lifecycleStepIndex(AppConstants.statusRegistrationClosed), 1);
        expect(lifecycleStepIndex(AppConstants.statusDrawing), 1);
        expect(lifecycleStepIndex(AppConstants.statusInProgress), 2);
        expect(lifecycleStepIndex(AppConstants.statusCompleted), 3);
        expect(lifecycleStepIndex(AppConstants.statusCancelled), isNull);
      },
    );

    test(
      'lifecycleCapacityFull: theo nội dung, rồi theo capacity cấp giải',
      () {
        final byDivisions = Tournament.fromJson({
          'name': 'A',
          'sport': 'pickleball',
          'status': 'REGISTRATION_OPEN',
          'createdAt': '2026-01-01T00:00:00Z',
          'updatedAt': '2026-01-01T00:00:00Z',
          'divisions': [
            {
              'id': 'd1',
              'name': 'Đôi nam',
              'matchType': 'DOUBLES',
              'maxParticipants': 8,
              '_count': {'participants': 8},
            },
            {
              'id': 'd2',
              'name': 'Đôi nữ',
              'matchType': 'DOUBLES',
              'maxParticipants': 8,
              '_count': {'participants': 8},
            },
          ],
        }, 't1');
        expect(lifecycleCapacityFull(byDivisions), (occupied: 16, max: 16));

        final notFull = Tournament.fromJson({
          'name': 'B',
          'sport': 'pickleball',
          'status': 'REGISTRATION_OPEN',
          'createdAt': '2026-01-01T00:00:00Z',
          'updatedAt': '2026-01-01T00:00:00Z',
          'divisions': [
            {
              'id': 'd1',
              'name': 'Đôi nam',
              'matchType': 'DOUBLES',
              'maxParticipants': 8,
              '_count': {'participants': 7},
            },
          ],
        }, 't2');
        expect(lifecycleCapacityFull(notFull), isNull);

        final byCapacity = _tournament(
          status: 'REGISTRATION_OPEN',
          capacity: {
            'occupiedTeamSlots': 12,
            'maxTeamSlots': 12,
            'isFull': true,
          },
        );
        expect(lifecycleCapacityFull(byCapacity), (occupied: 12, max: 12));
        expect(lifecycleCapacityFull(_tournament()), isNull);
      },
    );
  });

  testWidgets('thanh 4 bước đánh dấu đúng bước hiện tại', (tester) async {
    await tester.pumpWidget(
      _wrap(const LifecycleStepBar(status: AppConstants.statusInProgress)),
    );

    for (final label in [
      'Đăng ký',
      'Lịch thi đấu',
      'Đang thi đấu',
      'Kết thúc',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('lifecycle-step-current')),
        matching: find.text('Đang thi đấu'),
      ),
      findsOneWidget,
    );
    // Two earlier steps are done (check mark); the last one is still ahead.
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
  });

  testWidgets('giải nháp: thanh hiện nhưng không bước nào sáng', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const LifecycleStepBar(status: AppConstants.statusDraft)),
    );

    expect(find.text('Đăng ký'), findsOneWidget);
    expect(find.byKey(const ValueKey('lifecycle-step-current')), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets(
    'giải mở đăng ký: một nút kế tiếp là Đóng đăng ký, có thanh bước',
    (tester) async {
      _tallView(tester);
      await tester.pumpWidget(
        _wrap(
          TournamentLifecycleCard(
            tournament: _tournament(status: 'REGISTRATION_OPEN'),
          ),
          repo: _Repo(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LifecycleStepBar), findsOneWidget);
      expect(find.text('Đóng đăng ký'), findsOneWidget);
      expect(find.text('Công bố giải đấu'), findsNothing);
    },
  );

  testWidgets('đủ N/N đội: cảnh báo kèm nút đóng đăng ký chạy đúng hành động', (
    tester,
  ) async {
    _tallView(tester);
    final repo = _Repo();
    await tester.pumpWidget(
      _wrap(
        TournamentLifecycleCard(
          tournament: _tournament(
            status: 'REGISTRATION_OPEN',
            capacity: {
              'occupiedTeamSlots': 16,
              'maxTeamSlots': 16,
              'isFull': true,
            },
          ),
        ),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã đủ 16/16 đội'), findsOneWidget);
    // The banner has no button of its own: the one primary button closes.
    await tester.tap(find.text('Đóng đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(repo.closeCalls, 1);

    // "Nhắc sau" ẩn cảnh báo.
    await tester.tap(find.byKey(const ValueKey('lifecycle-full-remind')));
    await tester.pumpAndSettle();
    expect(find.text('Đã đủ 16/16 đội'), findsNothing);
  });

  testWidgets(
    'nhóm Khác: chia sẻ và xoá giải gọi đúng callback, ẩn khi không truyền',
    (tester) async {
      await tester.pumpWidget(
        _wrap(TournamentLifecycleCard(tournament: _tournament())),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('lifecycle-share')), findsNothing);
      expect(find.byKey(const ValueKey('lifecycle-delete')), findsNothing);

      var shared = 0;
      var deleted = 0;
      await tester.pumpWidget(
        _wrap(
          TournamentLifecycleCard(
            tournament: _tournament(),
            onShare: () => shared++,
            onDelete: () => deleted++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lifecycle-share')));
      await tester.tap(find.byKey(const ValueKey('lifecycle-delete')));
      expect((shared, deleted), (1, 1));
    },
  );

  testWidgets('chưa đủ đội: không có cảnh báo', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(
      _wrap(
        TournamentLifecycleCard(
          tournament: _tournament(
            status: 'REGISTRATION_OPEN',
            capacity: {
              'occupiedTeamSlots': 10,
              'maxTeamSlots': 16,
              'isFull': false,
            },
          ),
        ),
        repo: _Repo(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã đủ 16/16 đội'), findsNothing);
  });

  testWidgets('TC-LIFE-10 đã đóng đăng ký: hai nút gọn cạnh nhau, không dòng chú thích', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(
      _wrap(
        TournamentLifecycleCard(
          tournament: _tournament(status: AppConstants.statusRegistrationClosed),
        ),
        repo: _Repo(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Các điều khiển này'), findsNothing);

    final start = find.ancestor(
      of: find.text('Khai mạc giải'),
      matching: find.byType(FilledButton),
    );
    final reopen = find.ancestor(
      of: find.text('Mở lại đăng ký'),
      matching: find.byType(OutlinedButton),
    );
    // The visible slab is the button's Material; the tap area around it stays 48.
    for (final button in [start, reopen]) {
      final slab = find.descendant(of: button, matching: find.byType(Material));
      expect(tester.getSize(slab.first).height, lessThanOrEqualTo(38));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
    }
    expect(
      tester.getTopLeft(start).dy,
      tester.getTopLeft(reopen).dy,
      reason: 'the two buttons share one row',
    );
  });

  testWidgets('nháp còn phí công bố: nút Công bố bị khoá kèm lý do và số phí', (
    tester,
  ) async {
    _tallView(tester);
    final repo = _Repo(publishFee: 200000);
    await tester.pumpWidget(
      _wrap(TournamentLifecycleCard(tournament: _tournament()), repo: repo),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Công bố giải đấu'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('200.000'), findsOneWidget);
    expect(find.textContaining('phí công bố'), findsOneWidget);
    expect(repo.publishCalls, 0);
  });

  testWidgets(
    'nháp không có phí công bố: nút Công bố bấm được, không có lý do',
    (tester) async {
      _tallView(tester);
      await tester.pumpWidget(
        _wrap(
          TournamentLifecycleCard(tournament: _tournament()),
          repo: _Repo(),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Công bố giải đấu'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
      expect(
        find.byKey(const ValueKey('lifecycle-publish-blocked')),
        findsNothing,
      );
    },
  );

  group('xoá giải phải gõ lại tên', () {
    /// Opens the dialog; the returned holder receives the dialog result.
    Future<List<bool?>> open(WidgetTester tester) async {
      final result = <bool?>[];
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open'),
              onPressed: () async => result.add(
                await showDeleteTournamentDialog(
                  context,
                  tournamentName: 'Giải Mùa Hè',
                ),
              ),
              child: const Text('mở'),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('gõ sai tên: nút Xóa bị khoá', (tester) async {
      await open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('delete-tournament-name')),
        'Giải khác',
      );
      await tester.pump();

      final confirm = tester.widget<FilledButton>(
        find.byKey(const ValueKey('delete-tournament-confirm')),
      );
      expect(confirm.onPressed, isNull);
    });

    testWidgets('gõ đúng tên: nút Xóa bật và trả về true', (tester) async {
      final result = await open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('delete-tournament-name')),
        ' Giải Mùa Hè ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('delete-tournament-confirm')));
      await tester.pumpAndSettle();

      expect(result, [true]);
    });
  });
}
