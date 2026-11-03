import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_end_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock repository cho sheet kết thúc giải: ghi nhận id mỗi lần gọi
/// `complete-tournament` (POST /tournaments/:id/complete).
class _EndRepository
    implements TournamentManagementRepository, TournamentLifecycleRepository {
  final completedIds = <String>[];
  Object? completeError;

  @override
  Future<Map<String, dynamic>> completeTournament(String id) async {
    completedIds.add(id);
    if (completeError != null) throw completeError!;
    return const {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _inProgressTournament() => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'IN_PROGRESS',
  'prizeDescription': '<p>Winner takes a <b>trophy</b></p>',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'divisions': [
    {'id': 'div-1', 'name': 'Đôi Nam', 'matchType': 'DOUBLES'},
    {'id': 'div-2', 'name': 'Đôi Nữ', 'matchType': 'DOUBLES'},
  ],
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

MatchModel _match(
  String id, {
  String status = 'SCHEDULED',
  String? divisionId,
  String team1 = 'Team A',
  String team2 = 'Team B',
  bool isBye = false,
}) => MatchModel(
  id: id,
  round: 1,
  matchNumber: 1,
  team1Name: team1,
  team2Name: team2,
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime(2026, 1, 1),
  divisionId: divisionId,
  isBye: isBye,
);

Map<String, dynamic> _award(int rank, String teamName) => {
  'rank': rank,
  'participant': {'participantId': 'p-$rank', 'teamName': teamName},
};

/// Trang quản lý giải với tài khoản organizer thuần (không vai ADMIN) — đúng
/// đối tượng được mở khoá kết thúc giải theo change quan-ly-giai-web-parity.
Widget _organizerApp(
  _EndRepository repository,
  List<MatchModel> matches, {
  List<Map<String, dynamic>> awards = const [],
}) => ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'organizer-1',
            role: 'ORGANIZER',
            roles: ['ORGANIZER'],
          ),
        ),
        tournamentManagementRepositoryProvider.overrideWithValue(repository),
        matchesProvider(
          'tournament-1',
        ).overrideWith((ref) => Stream.value(matches)),
        tournamentResultProvider((
          tournamentId: 'tournament-1',
          divisionId: null,
        )).overrideWith((ref) => Stream.value({'awards': awards})),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: TournamentManagementHubScreen(
          tournament: _inProgressTournament(),
          actionRouteBase: '/organizer/tournaments/tournament-1/manage',
          opsWorkspaceRoute: '/organizer/tournaments/tournament-1/ops',
        ),
      ),
    );

/// Mở sheet kết thúc giải từ menu overflow của hub.
Future<void> _openEndSheet(
  WidgetTester tester,
  _EndRepository repository,
  List<MatchModel> matches, {
  List<Map<String, dynamic>> awards = const [],
}) async {
  await tester.pumpWidget(_organizerApp(repository, matches, awards: awards));
  await tester.pumpAndSettle();
  final l10n = AppLocalizations.of(
    tester.element(find.byType(TournamentManagementHubScreen)),
  )!;
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.endTournament));
  await tester.pumpAndSettle();
}

/// Taps the confirm button of the "are you sure" dialog.
Future<void> _confirmDialog(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(l10n.lifecycleEndConfirm),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-WP-01-03: còn trận LIVE — nút kết thúc bị chặn, liệt kê trận LIVE, hạng mục chặn và "X/Y"',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1300);
      tester.view.devicePixelRatio = 1;
      final repository = _EndRepository();
      // 3 trận có thật (2 xong, 1 LIVE) + 1 trận BYE không được tính.
      await _openEndSheet(tester, repository, [
        _match('m-1', status: 'COMPLETED', divisionId: 'div-1'),
        _match('m-2', status: 'COMPLETED', divisionId: 'div-1'),
        _match(
          'm-3',
          status: 'ONGOING',
          divisionId: 'div-1',
          team1: 'Team C',
          team2: 'Team D',
        ),
        _match('m-4', isBye: true, divisionId: 'div-1'),
      ]);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LifecycleEndSheet)),
      )!;

      // Checklist "trận đã xong X/Y" — BYE không đếm, chưa xong hết nên "Chưa đạt".
      expect(find.text(l10n.lifecycleEndCheckMatches(2, 3)), findsOneWidget);
      expect(find.text(l10n.lifecycleEndCheckLive(1)), findsOneWidget);
      expect(find.text(l10n.lifecycleEndNotPassed), findsNWidgets(2));

      // Liệt kê đúng trận đang LIVE kèm hạng mục còn trận LIVE.
      expect(
        find.byKey(const ValueKey('lifecycle-end-live-m-3')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.lifecycleEndLiveMatch('Team C', 'Team D')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('lifecycle-end-blocking-divisions')),
        findsOneWidget,
      );
      expect(find.text('Đôi Nam'), findsOneWidget);

      // Còn trận LIVE: nút kết thúc bị khoá và chưa gọi API.
      final confirm = tester.widget<FilledButton>(
        find.byKey(const ValueKey('lifecycle-end-confirm')),
      );
      expect(confirm.onPressed, isNull);
      expect(repository.completedIds, isEmpty);
    },
  );

  testWidgets(
    'TC-WP-01-04: organizer không phải admin thấy và kết thúc được — gọi complete cho đúng giải',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1300);
      tester.view.devicePixelRatio = 1;
      final repository = _EndRepository();
      // Chưa xong hết trận (1/2) nhưng không còn trận LIVE: Web vẫn cho kết thúc.
      await _openEndSheet(tester, repository, [
        _match('m-1', status: 'COMPLETED', divisionId: 'div-1'),
        _match('m-2', status: 'SCHEDULED', divisionId: 'div-1'),
      ]);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LifecycleEndSheet)),
      )!;
      expect(find.text(l10n.lifecycleEndCheckMatches(1, 2)), findsOneWidget);

      // Nút kết thúc bật được (organizer được phép — backend chốt quyền).
      final confirm = tester.widget<FilledButton>(
        find.byKey(const ValueKey('lifecycle-end-confirm')),
      );
      expect(confirm.onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('lifecycle-end-confirm')));
      await tester.pumpAndSettle();
      await _confirmDialog(tester, l10n);

      expect(repository.completedIds, ['tournament-1']);
      expect(find.byType(LifecycleEndSheet), findsNothing);
      expect(find.text(l10n.tournamentEnded), findsOneWidget);
    },
  );

  testWidgets(
    'sheet kết thúc hiển thị nguyên văn lỗi server (ví dụ 403 từ chối quyền)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1300);
      tester.view.devicePixelRatio = 1;
      const serverMessage = 'Bạn không có quyền kết thúc giải đấu này';
      final request = RequestOptions(
        path: '/tournaments/tournament-1/complete',
      );
      final repository = _EndRepository()
        ..completeError = DioException(
          requestOptions: request,
          response: Response<dynamic>(
            requestOptions: request,
            statusCode: 403,
            data: const {'message': serverMessage},
          ),
        );
      await _openEndSheet(tester, repository, [
        _match('m-1', status: 'COMPLETED', divisionId: 'div-1'),
      ]);

      await tester.tap(find.byKey(const ValueKey('lifecycle-end-confirm')));
      await tester.pumpAndSettle();
      await _confirmDialog(
        tester,
        AppLocalizations.of(tester.element(find.byType(LifecycleEndSheet)))!,
      );

      // Lỗi 403 hiển thị nguyên văn trong sheet, sheet không tự đóng.
      expect(find.text(serverMessage), findsOneWidget);
      expect(find.byType(LifecycleEndSheet), findsOneWidget);
    },
  );

  testWidgets('shows the podium, the prize text and the conditions block', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    await _openEndSheet(
      tester,
      _EndRepository(),
      [_match('m-1', status: 'COMPLETED', divisionId: 'div-1')],
      awards: [_award(2, 'Team B'), _award(1, 'Team A'), _award(3, 'Team C')],
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LifecycleEndSheet)),
    )!;

    for (final entry in const {1: 'Team A', 2: 'Team B', 3: 'Team C'}.entries) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('lifecycle-end-podium-${entry.key}')),
          matching: find.text(entry.value),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.text(l10n.lifecycleEndPrizesTitle.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Winner takes a trophy'), findsOneWidget);
    expect(
      find.text(l10n.lifecycleEndConditionsTitle.toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('lifecycle-end-blocked-reason')),
      findsNothing,
    );
  });

  testWidgets('TC-POP-02 podium label colours follow the medal tone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    await _openEndSheet(
      tester,
      _EndRepository(),
      [_match('m-1', status: 'COMPLETED', divisionId: 'div-1')],
      awards: [_award(2, 'Team B'), _award(1, 'Team A'), _award(3, 'Team C')],
    );

    HSLColor inkOf(String name) =>
        HSLColor.fromColor(tester.widget<Text>(find.text(name)).style!.color!);

    // Gold and bronze are warm (red to orange-brown), silver is a neutral slate.
    for (final warm in [inkOf('Team A'), inkOf('Team C')]) {
      expect(warm.hue, inInclusiveRange(10, 40));
    }
    expect(inkOf('Team B').saturation, lessThan(0.3));
  });

  testWidgets('without results the podium slots stay empty, no crash', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    await _openEndSheet(tester, _EndRepository(), [
      _match('m-1', status: 'COMPLETED', divisionId: 'div-1'),
    ]);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LifecycleEndSheet)),
    )!;

    expect(find.text(l10n.lifecycleEndPodiumEmpty), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a live match shows a red reason and keeps the button grey', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    await _openEndSheet(tester, _EndRepository(), [
      _match('m-1', status: 'ONGOING', divisionId: 'div-1'),
    ]);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LifecycleEndSheet)),
    )!;

    expect(find.text(l10n.lifecycleEndBlockedReason(1)), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('lifecycle-end-confirm')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('cancelling the confirmation dialog does not complete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    final repository = _EndRepository();
    await _openEndSheet(tester, repository, [
      _match('m-1', status: 'COMPLETED', divisionId: 'div-1'),
    ]);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LifecycleEndSheet)),
    )!;

    await tester.tap(find.byKey(const ValueKey('lifecycle-end-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.lifecycleEndConfirmDialogMessage), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.tournamentManagementCancel),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.completedIds, isEmpty);
    expect(find.byType(LifecycleEndSheet), findsOneWidget);
  });
}
