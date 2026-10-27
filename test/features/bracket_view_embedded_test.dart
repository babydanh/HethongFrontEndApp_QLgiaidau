import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/single_elim_diagram.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'embedded-bracket-fixture';
const _divisionId = 'division-a';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _tournament() => Tournament(
  id: _tournamentId,
  name: 'Embedded bracket fixture',
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
  divisions: [
    TournamentDivision(
      id: _divisionId,
      name: 'Đôi Nam Nữ',
      matchType: 'DOUBLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
      participantCount: 6,
    ),
  ],
);

MatchModel _knockout(String id, {required int round, int position = 0}) =>
    MatchModel.fromJson({
      'id': id,
      'tournamentId': _tournamentId,
      'divisionId': _divisionId,
      'round': round,
      'matchNumber': position + 1,
      'status': 'SCHEDULED',
      'team1Name': 'Đội $id-A',
      'team2Name': 'Đội $id-B',
      'nextMatchId': '',
      'stageType': 'SINGLE_ELIMINATION',
      'bracketPosition': {
        'bracket': 'winners',
        'round': round,
        'position': position,
      },
    }, id);

/// Default mirrors the management hub: the embedded screen sits in a sliver
/// inside the page's own vertical scroll view. [home] overrides the host.
Widget _hubHost(Widget screen) => CustomScrollView(
  key: const Key('hub-page-scroll'),
  slivers: [SliverToBoxAdapter(child: screen)],
);

Finder _frame420(Finder diagram) => find.ancestor(
  of: diagram,
  matching: find.byWidgetPredicate((w) => w is SizedBox && w.height == 420),
);

Future<void> _pumpEmbedded(
  WidgetTester tester, {
  Widget Function(Widget screen)? host,
  bool isEmbedded = true,
  bool isLite = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final matches = [
    for (var i = 0; i < 4; i++) _knockout('r1-$i', round: 1, position: i),
    for (var i = 0; i < 2; i++) _knockout('r2-$i', round: 2, position: i),
    _knockout('r3-0', round: 3),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider.overrideWith(
          (ref, id) => Stream.value(_tournament()),
        ),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(matches),
        ),
        standingsWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const []),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: (host ?? _hubHost)(
            BracketViewScreen(
              tournamentId: _tournamentId,
              divisionId: _divisionId,
              isEmbedded: isEmbedded,
              isLite: isLite,
              canEditBracket: true,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nhúng trong hub: bỏ banner mô tả, chỉ còn ô tìm kiếm và sơ đồ', (
    tester,
  ) async {
    await _pumpEmbedded(tester);
    final l10n = lookupAppLocalizations(const Locale('vi'));

    expect(find.text(l10n.bracketView_knockoutTitle), findsNothing);
    expect(
      find.text(l10n.bracketView_singleEliminationDescription),
      findsNothing,
    );
    expect(find.text(l10n.bracketView_knockoutMap), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(SingleElimDiagram), findsOneWidget);
  });

  testWidgets(
    'nhúng trong hub: sơ đồ cuộn ngang, cao theo sơ đồ (không khung 420)',
    (tester) async {
      await _pumpEmbedded(tester);
      final diagram = find.byType(SingleElimDiagram);

      expect(tester.widget<SingleElimDiagram>(diagram).scrollOnly, isTrue);
      expect(_frame420(diagram), findsNothing);

      final horizontal = find.descendant(
        of: diagram,
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
        ),
      );
      expect(horizontal, findsOneWidget);
      final position = tester.state<ScrollableState>(horizontal).position;
      expect(position.maxScrollExtent, greaterThan(0));

      await tester.drag(diagram, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
    },
  );

  testWidgets('màn riêng (không nhúng): giữ banner và khung sơ đồ 420', (
    tester,
  ) async {
    await _pumpEmbedded(tester, isEmbedded: false, host: (screen) => screen);
    final l10n = lookupAppLocalizations(const Locale('vi'));
    final diagram = find.byType(SingleElimDiagram);

    expect(find.text(l10n.bracketView_knockoutTitle), findsWidgets);
    expect(tester.widget<SingleElimDiagram>(diagram).scrollOnly, isFalse);
    expect(_frame420(diagram), findsOneWidget);
  });

  testWidgets('Lite nhúng trong khung cao cố định: giữ banner và khung 420', (
    tester,
  ) async {
    await _pumpEmbedded(
      tester,
      isLite: true,
      host: (screen) => Column(children: [Expanded(child: screen)]),
    );
    final l10n = lookupAppLocalizations(const Locale('vi'));
    final diagram = find.byType(SingleElimDiagram);

    expect(find.text(l10n.bracketView_knockoutTitle), findsWidgets);
    expect(tester.widget<SingleElimDiagram>(diagram).scrollOnly, isFalse);
    expect(_frame420(diagram), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
