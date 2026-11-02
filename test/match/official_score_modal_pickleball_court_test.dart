import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
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
    testWidgets('portrait: vertical court, no bottom bar, no big score block', (
      tester,
    ) async {
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
    });

    testWidgets('landscape: horizontal court', (tester) async {
      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));

      final view = tester.widget<PickleballCourtView>(
        find.byType(PickleballCourtView),
      );
      expect(view.axis, Axis.horizontal);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lite shows the court too, as rally', (tester) async {
      await _pump(
        tester,
        sportKey: 'PICKLEBALL',
        lite: true,
        model: SportScoringModel.rallyPointSet,
      );

      expect(find.byType(PickleballCourtPanel), findsOneWidget);
      expect(find.byTooltip('Lose serve'), findsNothing);
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

  group('landscape header', () {
    testWidgets('finished sets share the title row', (tester) async {
      await _pump(
        tester,
        sportKey: 'PICKLEBALL',
        size: const Size(800, 360),
        finishedSets: const [
          SetScoreData(score1: 11, score2: 7, isFinished: true),
        ],
      );

      expect(find.text('Set 1: 11-7'), findsOneWidget);
      // No second strip: the sets are on the title row only.
      final title = tester.getCenter(find.textContaining('VS')).dy;
      expect(
        (tester.getCenter(find.text('Set 1: 11-7')).dy - title).abs(),
        lessThan(20),
      );
    });

    testWidgets('without finished sets the title keeps the whole row', (
      tester,
    ) async {
      await _pump(tester, sportKey: 'PICKLEBALL', size: const Size(800, 360));

      final title = tester.getRect(find.textContaining('VS'));
      final info = tester.getCenter(find.byIcon(Icons.info_outline_rounded));
      // No empty half-row reserved for the sets: the title may use the room.
      expect(title.right, greaterThan(info.dx - 120));
    });

    testWidgets('portrait keeps the strip under the title', (tester) async {
      await _pump(
        tester,
        sportKey: 'PICKLEBALL',
        finishedSets: const [
          SetScoreData(score1: 11, score2: 7, isFinished: true),
        ],
      );

      final title = tester.getCenter(find.textContaining('VS')).dy;
      expect(
        tester.getCenter(find.text('Set 1: 11-7')).dy,
        greaterThan(title + 15),
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
