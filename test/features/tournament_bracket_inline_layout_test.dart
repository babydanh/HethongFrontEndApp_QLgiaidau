import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/double_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/single_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'bracket-inline-fixture';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _tournament() => Tournament(
  id: _tournamentId,
  name: 'Bracket inline fixture',
  sport: 'pickleball',
  format: 'DOUBLES',
  bracketType: 'single_elimination',
  status: 'in_progress',
  visibility: 'PUBLIC',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'fixture-owner',
  maxTeams: 16,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  divisions: const [
    TournamentDivision(
      id: 'division-a',
      name: 'Đôi Nam Nữ',
      matchType: 'DOUBLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
      participantCount: 6,
    ),
    TournamentDivision(
      id: 'division-b',
      name: 'Đơn nam',
      matchType: 'SINGLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
      participantCount: 0,
    ),
  ],
);

MatchModel _match(
  String id, {
  required int round,
  required int position,
  String nextMatchId = '',
  String divisionId = 'division-a',
  String bracket = 'winners',
  String? stageType,
}) => MatchModel.fromJson({
  'id': id,
  'tournamentId': _tournamentId,
  'divisionId': divisionId,
  'round': round,
  'matchNumber': position + 1,
  'status': 'SCHEDULED',
  'team1Name': 'Đội $id-A',
  'team2Name': 'Đội $id-B',
  'nextMatchId': nextMatchId,
  'bracketPosition': {'bracket': bracket, 'round': round, 'position': position},
  'stageType': ?stageType,
}, id);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pump(WidgetTester tester, {List<MatchModel>? matchList}) async {
  final matches =
      matchList ??
      [
        _match('m1', round: 1, position: 0, nextMatchId: 'm3'),
        _match('m2', round: 1, position: 1, nextMatchId: 'm3'),
        _match('m3', round: 2, position: 0),
      ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentIntroWithInviteProvider.overrideWith(
          (ref, params) async => _tournament(),
        ),
        tournamentDivisionsProvider.overrideWith(
          (ref, tournamentId) async => const <Map<String, dynamic>>[],
        ),
        introTeamsProvider.overrideWith(
          (ref, tournamentId) async => const <Team>[],
        ),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        matchesProvider.overrideWith(
          (ref, tournamentId) => Stream.value(const []),
        ),
        bracketMatchesProvider.overrideWith(
          (ref, tournamentId) => Stream.value(const []),
        ),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(
            params.divisionId == 'division-a' ? matches : const <MatchModel>[],
          ),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: '', fullName: 'Guest'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const TournamentIntroScreen(tournamentId: _tournamentId),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final tab = find.widgetWithText(Tab, 'Bảng đấu');
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> _tapRow(WidgetTester tester, String name) async {
  final row = find.text(name);
  // Hàng có thể nằm sau banner/tab bar; đưa vào vùng bấm được trước khi chạm.
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  expect(row.hitTestable(), findsOneWidget, reason: 'row "$name" phải bấm được');
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first division is open on entry with its bracket right below', (
    tester,
  ) async {
    _phone(tester);
    await _pump(tester);

    // Row đầu mở sẵn (hành vi của màn): sơ đồ hiện ngay, không cần chạm.
    final diagram = find.byType(SingleElimDiagram);
    expect(diagram, findsOneWidget);

    // Sơ đồ nằm sát ngay dưới row, không bắt cuộn xuống tìm.
    final rowRect = tester.getRect(find.text('Đôi Nam Nữ'));
    final diagramRect = tester.getRect(diagram);
    expect(diagramRect.top, greaterThanOrEqualTo(rowRect.bottom - 1));
    expect(diagramRect.top - rowRect.bottom, lessThan(48));

    // Chỉ bracket: không banner, ô tìm, bộ lọc, thẻ vòng.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Vòng Knockout'), findsNothing);
    expect(find.text('Sơ đồ Knockout'), findsNothing);
    expect(find.byIcon(Icons.account_tree_rounded), findsNothing);
  });

  testWidgets('tapping the open division closes it, tapping again reopens', (
    tester,
  ) async {
    _phone(tester);
    await _pump(tester);
    expect(find.byType(SingleElimDiagram), findsOneWidget);

    await _tapRow(tester, 'Đôi Nam Nữ');
    expect(find.byType(SingleElimDiagram), findsNothing);

    await _tapRow(tester, 'Đôi Nam Nữ');
    expect(find.byType(SingleElimDiagram), findsOneWidget);
  });

  testWidgets('opening a division without matches does not keep another bracket', (
    tester,
  ) async {
    _phone(tester);
    await _pump(tester);

    await _tapRow(tester, 'Đơn nam');

    // Nội dung "Đơn nam" chưa có trận: sơ đồ của "Đôi Nam Nữ" biến mất khỏi
    // trang, không rò sang row khác.
    expect(find.byType(SingleElimDiagram), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed rows stay below an open bracket', (tester) async {
    _phone(tester);
    await _pump(tester);

    final diagramRect = tester.getRect(find.byType(SingleElimDiagram));
    final otherRect = tester.getRect(find.text('Đơn nam'));
    expect(otherRect.top, greaterThanOrEqualTo(diagramRect.bottom - 1));
  });

  testWidgets('horizontal drag pans the bracket instead of switching tab', (
    tester,
  ) async {
    _phone(tester);
    await _pump(tester);

    final diagram = find.byType(SingleElimDiagram);
    final horizontal = find.descendant(
      of: diagram,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.right,
      ),
    );
    final state = tester.state<ScrollableState>(horizontal.first);
    expect(state.position.maxScrollExtent, greaterThan(0));

    await tester.drag(diagram, const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(state.position.pixels, greaterThan(0));
    final bar = tester.widget<TabBar>(find.byType(TabBar).first);
    expect((bar.tabs[bar.controller!.index] as Tab).text, 'Bảng đấu');
  });

  testWidgets('horizontal drag on a double-elim card pans it inside the tab', (
    tester,
  ) async {
    _phone(tester);
    await _pump(
      tester,
      matchList: [
        for (var i = 0; i < 8; i++)
          _match('w1$i', round: 1, position: i, nextMatchId: 'w2${i ~/ 2}'),
        for (var i = 0; i < 4; i++)
          _match('w2$i', round: 2, position: i, nextMatchId: 'w3${i ~/ 2}'),
        for (var i = 0; i < 2; i++)
          _match('w3$i', round: 3, position: i, nextMatchId: 'w40'),
        _match('w40', round: 4, position: 0),
        for (var i = 0; i < 4; i++)
          _match(
            'l1$i',
            round: 1,
            position: i,
            bracket: 'losers',
            stageType: 'DOUBLE_ELIMINATION',
          ),
      ],
    );

    final diagram = find.byType(DoubleElimDiagram);
    expect(diagram, findsOneWidget);
    final horizontal = tester.state<ScrollableState>(
      find
          .descendant(
            of: diagram,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.right,
            ),
          )
          .first,
    );
    expect(horizontal.position.maxScrollExtent, greaterThan(0));

    final card = find.text('Đội w10-A');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.dragFrom(tester.getCenter(card), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(horizontal.position.pixels, greaterThan(0));
    final bar = tester.widget<TabBar>(find.byType(TabBar).first);
    expect((bar.tabs[bar.controller!.index] as Tab).text, 'Bảng đấu');
  });
}
