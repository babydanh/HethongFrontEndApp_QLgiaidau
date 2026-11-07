import 'dart:io' show Platform;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'xem.dart';

/// Params every scoring panel in these tests is opened with.
const bamDiemParams = (tournamentId: 'tournament-1', matchId: 'match-1');

/// Match repository that swallows score writes. Extend it in a test file when
/// a panel needs another method (a Fake throws on anything not overridden).
class BamDiemWrites extends Fake implements IMatchRepository {
  @override
  Future<void> updateScoreDetails(
    String tournamentId,
    String matchId, {
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    Map<String, dynamic>? scoreDetailsExtras,
    String? winnerId,
    String? overrideReason,
    int? expectedRevision,
    bool useLiteParticipantAccess = false,
    ({String date, String? time})? playedAt,
  }) async {}
}

/// The real score panel logic, started from a state the test chooses.
class SeededPanel extends ScorePanelNotifier {
  SeededPanel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

/// A LIVE match between "Đội A" and "Đội B" (two players each when [doubles]).
MatchModel bamDiemMatch({bool doubles = false, String status = 'LIVE'}) =>
    MatchModel(
      id: 'match-1',
      tournamentId: 'tournament-1',
      round: 1,
      matchNumber: 1,
      team1Id: 'team-1',
      team2Id: 'team-2',
      team1Name: 'Đội A',
      team2Name: 'Đội B',
      team1Members: doubles ? const ['An', 'Binh'] : const ['An'],
      team2Members: doubles ? const ['Chi', 'Dung'] : const ['Chi'],
      status: status,
      bracketPosition: const BracketPosition(round: 1, position: 1),
      updatedAt: DateTime.utc(2026, 11, 7),
    );

/// Pumps [panel] on a phone-sized surface with the real notifier seeded from
/// [state]. [writes] replaces the match repository; [extra] adds overrides.
Future<void> pumpPanel(
  WidgetTester tester,
  Widget panel,
  ScorePanelState state, {
  bool doubles = false,
  IMatchRepository? writes,
  List<Override> extra = const [],
}) async {
  debugPrintSynchronously('[bam-diem] pumpPanel start');
  // The emulator keeps its real screen: a resized test view makes the engine drop
  // frames, so the screen recording would stay on "Test starting..." for the whole run.
  if (!Platform.isAndroid) {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
  final match = bamDiemMatch(doubles: doubles);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRepositoryProvider.overrideWithValue(writes ?? BamDiemWrites()),
        singleMatchProvider.overrideWith((ref, params) => Stream.value(match)),
        scorePanelNotifierProvider.overrideWith2(
          (arg) => SeededPanel(arg, state),
        ),
        ...extra,
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: panel),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  debugPrintSynchronously('[bam-diem] pumpPanel done');
}

/// Taps the first widget matching [target], then lets the 300 ms live-sync
/// debounce fire so the test never ends with a pending timer.
Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
  debugPrintSynchronously('[bam-diem] tap');
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  debugPrintSynchronously('[bam-diem] tap done');
}

/// Named screenshots on the emulator only: `takeScreenshot` is not available
/// when the same file runs on the desktop test host.
const _probeNoShots = true;

class BamDiemShooter {
  BamDiemShooter(WidgetTester tester, IntegrationTestWidgetsFlutterBinding b)
    : _shooter = XemShooter(tester, b);

  final XemShooter _shooter;

  Future<void> snap(String name) async {
    // Screenshots stay off: converting the surface to an image blanks the screen recording.
    if (!Platform.isAndroid || _probeNoShots) return;
    await _shooter.snap(name);
  }
}
