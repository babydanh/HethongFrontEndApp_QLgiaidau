import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_icon_widget.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_scoreboard.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

class _Referee extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.referee);
}

class _EchoCourtRepository extends Fake implements IMatchRepository {
  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async => MatchModel.fromJson({
    'id': matchId,
    'tournamentId': 'tournament-1',
    'status': 'LIVE',
    'scoreDetails': {'courtState': courtState},
  }, matchId);
}

class _FakeScorePanel extends ScorePanelNotifier {
  _FakeScorePanel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

SportConfig _config(SportRuleKind kind, SportScoringModel model, bool open) =>
    SportConfig(
      kind: kind,
      scoringModel: model,
      isOpenScoring: open,
      bestOf: 3,
      setsToWin: 2,
      pointsPerSet: 11,
      mustWinByTwo: true,
      maxPoints: 0,
      tiebreakAt: 0,
    );

MatchModel _match(String sportKey) => MatchModel.fromJson({
  'id': 'match-1',
  'tournamentId': 'tournament-1',
  'status': 'LIVE',
  'sport': sportKey,
  'team1Members': ['Lan Anh', 'Minh'],
  'team2Members': ['Bảo', 'Hà'],
}, 'match-1');

const _context = CourtContext(
  score1: 4,
  score2: 2,
  isDoubles: true,
  team1PlayerCount: 2,
  team2PlayerCount: 2,
  servingTeam: 1,
  serverNumber: 1,
  scoringMode: CourtScoringMode.sideOut,
  setIndex: 0,
  targetPoints: 11,
  isDecidingSet: false,
);

Future<void> _pump(
  WidgetTester tester, {
  required String sportKey,
  SportRuleKind kind = SportRuleKind.pickleball,
  SportScoringModel model = SportScoringModel.pickleballSideOut,
  bool lite = false,
  List<SetScoreData> finishedSets = const [],
  Size size = const Size(360, 780),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final match = _match(sportKey);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_Referee.new),
        singleMatchProvider.overrideWith((ref, params) => Stream.value(match)),
        tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        pickleballCourtContextProvider.overrideWith((ref, params) => _context),
        scorePanelNotifierProvider.overrideWith2(
          (arg) => _FakeScorePanel(
            arg,
            ScorePanelState(
              config: _config(kind, model, lite),
              isLite: lite,
              pickleball: const PickleballServeState(),
              rally: const RallySetState(currentP1: 4, currentP2: 2),
              finishedSets: finishedSets,
            ),
          ),
        ),
        matchRepositoryProvider.overrideWithValue(_EchoCourtRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme.copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showOfficialScoreModal(
                  context,
                  tournamentId: _params.tournamentId,
                  matchId: _params.matchId,
                  match: match,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pickleball scores on the court', () {
    testWidgets(
      'portrait: same scoreboard stacked, no bottom bar, no big score block',
      (tester) async {
        await _pump(tester, sportKey: 'PICKLEBALL');

        final view = tester.widget<PickleballCourtView>(
          find.byType(PickleballCourtView),
        );
        expect(view.axis, Axis.vertical);
        // The bottom bar of the other sports is gone: its chips and buttons.
        expect(find.byType(FilterChip), findsNothing);
        expect(find.text('Override'), findsNothing);
        expect(find.text('Force win'), findsNothing);
        expect(find.text('FINISH SET'), findsNothing);
        // Each score is drawn once, inside the court.
        expect(find.text('4'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets('landscape: horizontal court', (tester) async {
      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));

      final view = tester.widget<PickleballCourtView>(
        find.byType(PickleballCourtView),
      );
      expect(view.axis, Axis.horizontal);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lite shows the court too, with the one serve button', (
      tester,
    ) async {
      await _pump(
        tester,
        sportKey: 'PICKLEBALL',
        lite: true,
        model: SportScoringModel.rallyPointSet,
      );

      expect(find.byType(PickleballCourtPanel), findsOneWidget);
      expect(find.byTooltip('Change serve'), findsOneWidget);
    });

    testWidgets('TC-LMT-APP-07 Lite match info shows the scoring rule in use', (
      tester,
    ) async {
      await _pump(tester, sportKey: 'PICKLEBALL', lite: true);

      await tester.tap(find.byTooltip('Match Information'));
      await tester.pumpAndSettle();

      expect(find.text('Pickleball side-out'), findsOneWidget);
      // The dialog title row overflows with the wide test font only.
      expect(tester.takeException(), isA<FlutterError>());
    });
  });

  group('TC-COURT-10 swipe on the court does not slide the tabs', () {
    for (final size in const [Size(360, 780), Size(800, 360)]) {
      testWidgets('pressing a player and moving keeps Scoring open $size', (
        tester,
      ) async {
        await _pump(tester, sportKey: 'PICKLEBALL', size: size);
        final tabs = DefaultTabController.of(
          tester.element(find.byType(TabBarView)),
        );

        // Move sideways before the long-press delay: the grab is not armed
        // yet, so the tab view must not take the swipe either.
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('L. Anh')),
        );
        await gesture.moveBy(const Offset(-150, 0));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveBy(const Offset(-150, 0));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(tabs.index, 0);
        expect(tabs.animation!.value, 0);
      });
    }

    testWidgets('the Penalties tab still opens by tapping its label', (
      tester,
    ) async {
      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));
      final tabs = DefaultTabController.of(
        tester.element(find.byType(TabBarView)),
      );

      await tester.tap(find.text('Penalties'));
      await tester.pumpAndSettle();

      expect(tabs.index, 1);
    });
  });

  testWidgets('rotating the screen keeps the court panel State', (
    tester,
  ) async {
    await _pump(tester, sportKey: 'PICKLEBALL');
    final before = tester.state(find.byType(PickleballCourtPanel));
    final tabs = tester.widget<TabBar>(find.byType(TabBar)).controller;

    tester.view.physicalSize = const Size(800, 360);
    await tester.pumpAndSettle();

    // Same State object: a drag or a save in progress survives the rotation.
    expect(
      identical(tester.state(find.byType(PickleballCourtPanel)), before),
      isTrue,
    );
    expect(
      tester.widget<PickleballCourtView>(find.byType(PickleballCourtView)).axis,
      Axis.horizontal,
    );
    expect(
      identical(tester.widget<TabBar>(find.byType(TabBar)).controller, tabs),
      isTrue,
    );
  });

  group('pickleball header', () {
    for (final size in const [Size(640, 360), Size(390, 800)]) {
      testWidgets('no names title; info and close sit on the tab row $size', (
        tester,
      ) async {
        await _pump(tester, sportKey: 'PICKLEBALL', size: size);

        // The names are already on the court, so no title row repeats them.
        expect(find.textContaining('VS'), findsNothing);
        final tabs = tester.getRect(find.byType(TabBar));
        final info = tester.getCenter(find.byIcon(Icons.info_outline_rounded));
        final close = tester.getCenter(find.byIcon(Icons.close_rounded));
        expect((info.dy - tabs.center.dy).abs(), lessThan(20));
        expect((close.dy - tabs.center.dy).abs(), lessThan(20));
        expect(info.dx, lessThan(close.dx));
        // The tabs keep a usable width next to the two buttons.
        expect(tabs.width, greaterThan(size.width * 0.4));
      });
    }

    testWidgets('wide landscape: tabs, info and close sit right of END', (
      tester,
    ) async {
      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));

      expect(find.textContaining('VS'), findsNothing);
      final end = tester.getRect(find.text('END'));
      final tabs = tester.getRect(find.byType(TabBar));
      final info = tester.getCenter(find.byIcon(Icons.info_outline_rounded));
      final close = tester.getCenter(find.byIcon(Icons.close_rounded));
      // Same row as END, no row of their own above the court.
      expect((tabs.center.dy - end.center.dy).abs(), lessThan(12));
      expect(tabs.left, greaterThan(end.right));
      expect(info.dx, greaterThan(tabs.center.dx));
      expect(close.dx, greaterThan(info.dx));
      expect(close.dx, lessThan(800));
    });

    testWidgets('wide landscape: tabs, info, close and END all take taps', (
      tester,
    ) async {
      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));

      // The overlay row sits on top of the court: nothing may be covered.
      for (final target in [
        find.text('Scoring'),
        find.text('Penalties'),
        find.text('END'),
        find.byIcon(Icons.info_outline_rounded),
        find.byIcon(Icons.close_rounded),
      ]) {
        expect(target.hitTestable(), findsOneWidget);
      }
    });

    testWidgets('wide landscape: penalties page fits one screen, no scroll', (
      tester,
    ) async {
      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));
      await tester.tap(find.text('Penalties'));
      await tester.pumpAndSettle();

      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(TabBarView),
              matching: find.byType(Scrollable),
            )
            .last,
      );
      expect(scroll.position.maxScrollExtent, 0);
      expect(find.text('Record penalty').hitTestable(), findsOneWidget);
    });

    testWidgets(
      'TC-CBD-PB-06 wide landscape: the court runs to both screen edges',
      (tester) async {
        // The phone reports a 46.8dp inset on the camera side (left or right)
        // and on top.
        const inset = FakeViewPadding(top: 47, left: 47, right: 47);
        tester.view.viewPadding = inset;
        tester.view.padding = inset;
        await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));

        final court = tester.getRect(find.byKey(courtSurfaceKey));
        expect(court.left, 0);
        expect(court.right, 800);
      },
    );

    testWidgets('TC-CBD-PB-06 wide landscape: controls stay clear of the '
        'camera hole on both sides', (tester) async {
      const inset = FakeViewPadding(top: 47, left: 47, right: 47);
      tester.view.viewPadding = inset;
      tester.view.padding = inset;
      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));

      // The corner mark of the top row is the control nearest the left edge.
      final mark = tester.getRect(find.byType(SportIconWidget));
      expect(mark.left, greaterThanOrEqualTo(47));
      // The bottom bar buttons sit inside both insets.
      for (final tip in ['Add point for team 1', 'Add point for team 2']) {
        final plus = tester.getRect(find.byTooltip(tip));
        expect(plus.left, greaterThanOrEqualTo(47), reason: tip);
        expect(plus.right, lessThanOrEqualTo(800 - 47), reason: tip);
      }
    });

    testWidgets('wide landscape: no margin above or below the scoreboard', (
      tester,
    ) async {
      // Only the status bar inset stays on top; the system bars are hidden.
      const inset = FakeViewPadding(top: 47);
      tester.view.viewPadding = inset;
      tester.view.padding = inset;
      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));

      final board = tester.getRect(find.byType(CourtScoreboard));
      expect(board.top, 47);
      expect(board.bottom, 360);
    });

    testWidgets('wide landscape hides the system bars, portrait restores', (
      tester,
    ) async {
      final modes = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
            modes.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));
      expect(modes.last, 'SystemUiMode.immersiveSticky');

      tester.view.physicalSize = const Size(390, 800);
      await tester.pumpAndSettle();
      expect(modes.last, 'SystemUiMode.edgeToEdge');
    });

    testWidgets('landscape: finished sets share the tab row', (tester) async {
      await _pump(
        tester,
        sportKey: 'PICKLEBALL',
        size: const Size(800, 360),
        finishedSets: const [
          SetScoreData(score1: 11, score2: 7, isFinished: true),
        ],
      );

      expect(find.text('Set 1: 11-7'), findsOneWidget);
      final tabs = tester.getRect(find.byType(TabBar));
      expect(
        (tester.getCenter(find.text('Set 1: 11-7')).dy - tabs.center.dy).abs(),
        lessThan(20),
      );
    });

    testWidgets('portrait: no empty-sets row, court runs edge to edge', (
      tester,
    ) async {
      await _pump(tester, sportKey: 'PICKLEBALL');

      expect(find.text('Chưa chốt set nào'), findsNothing);
      final court = tester.getRect(find.byType(PickleballCourtView));
      expect(court.left, 0);
      expect(court.right, tester.getSize(find.byType(Scaffold).first).width);
    });

    testWidgets('portrait keeps the strip above the tabs', (tester) async {
      await _pump(
        tester,
        sportKey: 'PICKLEBALL',
        finishedSets: const [
          SetScoreData(score1: 11, score2: 7, isFinished: true),
        ],
      );

      expect(
        tester.getCenter(find.text('Set 1: 11-7')).dy,
        lessThan(tester.getRect(find.byType(TabBar)).top),
      );
    });
  });

  testWidgets('other sports keep the shared bottom bar', (tester) async {
    await _pump(
      tester,
      sportKey: 'BADMINTON',
      kind: SportRuleKind.badminton,
      model: SportScoringModel.rallyPointSet,
    );

    expect(find.byType(PickleballCourtView), findsNothing);
    expect(find.byType(FilterChip), findsOneWidget);
    expect(find.text('Override'), findsOneWidget);
  });
}
