import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

const _sideOutContext = CourtContext(
  score1: 0,
  score2: 0,
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

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

/// Echo courtState như server và ghi lại mọi lần ghi.
class _EchoCourtRepository extends Fake implements IMatchRepository {
  final requests = <Map<String, dynamic>>[];

  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async {
    requests.add(courtState);
    return MatchModel.fromJson({
      'id': matchId,
      'tournamentId': 'tournament-1',
      'status': 'LIVE',
      'scoreDetails': {'courtState': courtState},
    }, matchId);
  }
}

MatchModel _match() => MatchModel.fromJson({
  'id': 'match-1',
  'tournamentId': 'tournament-1',
  'status': 'LIVE',
  'team1Members': ['Lan Anh', 'Minh'],
  'team2Members': ['Bảo', 'Hà'],
}, 'match-1');

Future<void> _pumpPanel(
  WidgetTester tester, {
  required bool canScore,
  required IMatchRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        singleMatchProvider.overrideWith((ref, params) => Stream.value(_match())),
        pickleballCourtContextProvider.overrideWith(
          (ref, params) => _sideOutContext,
        ),
        matchRepositoryProvider.overrideWithValue(repository),
      ],
      child: _app(PickleballCourtPanel(params: _params, canScore: canScore)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the serving player cell is announced as serving', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final layout = resolveCourtLayout(const CourtState(), _sideOutContext);

    await tester.pumpWidget(
      ProviderScope(
        child: _app(
          PickleballCourtView(
            layout: layout,
            team1Players: const ['Lan Anh', 'Minh'],
            team2Players: const ['Bảo', 'Hà'],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp('Serving · can score')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('⚙ is hidden without a settings callback and opens the sheet', (
    tester,
  ) async {
    final layout = resolveCourtLayout(const CourtState(), _sideOutContext);
    var opened = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: _app(
          PickleballCourtView(
            layout: layout,
            team1Players: const [],
            team2Players: const [],
          ),
        ),
      ),
    );
    expect(find.byTooltip('Court settings'), findsNothing);

    await tester.pumpWidget(
      ProviderScope(
        child: _app(
          PickleballCourtView(
            layout: layout,
            team1Players: const [],
            team2Players: const [],
            onOpenSettings: () => opened++,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Court settings'));
    expect(opened, 1);
  });

  testWidgets('the panel shows ⚙ only to users who can score', (tester) async {
    await _pumpPanel(
      tester,
      canScore: false,
      repository: _EchoCourtRepository(),
    );
    expect(find.byTooltip('Court settings'), findsNothing);

    await _pumpPanel(
      tester,
      canScore: true,
      repository: _EchoCourtRepository(),
    );
    expect(find.byTooltip('Court settings'), findsOneWidget);
  });

  testWidgets('the settings sheet swaps ends and saves the court', (
    tester,
  ) async {
    final repository = _EchoCourtRepository();
    await _pumpPanel(tester, canScore: true, repository: repository);
    final writesBeforeSheet = repository.requests.length;

    await tester.tap(find.byTooltip('Court settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch ends now'));
    await tester.pumpAndSettle();

    expect(repository.requests.length, writesBeforeSheet + 1);
    expect(repository.requests.last['endsOverride'], isNotNull);
  });
}
