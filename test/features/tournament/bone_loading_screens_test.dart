import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/public_bracket_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/standings_view.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_venues_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/matches_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _tid = 'loading-t';
const _did = 'loading-d';

class _NeverVenues implements TournamentManagementRepository {
  final completer = Completer<List<Map<String, dynamic>>>();

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) => completer.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cameras implements ICourtCameraRepository {
  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      const [];

  @override
  Future<CameraLiveStatusModel> getCameraLiveStatus(String cameraId) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stream không bao giờ phát: provider ở trạng thái loading mãi mãi.
Stream<T> _never<T>() => StreamController<T>().stream;

Future<void> _pump(
  WidgetTester tester,
  Widget body, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: body),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void _expectSkeletonOnly(WidgetTester tester) {
  expect(find.byType(SkeletonScope), findsWidgets);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('MatchesTab loading shows match skeletons, no spinner', (
    tester,
  ) async {
    await _pump(
      tester,
      const MatchesTab(tournamentId: _tid),
      overrides: [
        matchesProvider(_tid).overrideWith((ref) => _never<List<MatchModel>>()),
      ],
    );

    _expectSkeletonOnly(tester);
  });

  testWidgets('ResultsTab loading shows podium skeleton, no spinner', (
    tester,
  ) async {
    await _pump(
      tester,
      const ResultsTab(
        tournamentId: _tid,
        selectedDivisionId: _did,
        selectedDivision: 'Division',
        matchType: 'DOUBLES',
      ),
      overrides: [
        tournamentResultProvider((
          tournamentId: _tid,
          divisionId: _did,
        )).overrideWith((ref) => _never<Map<String, dynamic>>()),
        matchesProvider.overrideWith((ref, id) => _never<List<MatchModel>>()),
      ],
    );

    _expectSkeletonOnly(tester);
  });

  testWidgets('PublicBracketLoader loading shows bracket skeleton', (
    tester,
  ) async {
    await _pump(
      tester,
      const SingleChildScrollView(
        child: PublicBracketLoader(tournamentId: _tid, divisionId: _did),
      ),
      overrides: [
        bracketMatchesWithDivisionProvider((
          tournamentId: _tid,
          divisionId: _did,
        )).overrideWith((ref) => _never<List<MatchModel>>()),
      ],
    );

    _expectSkeletonOnly(tester);
  });

  testWidgets('StandingsView loading shows standings skeleton', (tester) async {
    await _pump(
      tester,
      const StandingsView(
        matches: <MatchModel>[],
        tournamentId: _tid,
        divisionId: _did,
      ),
      overrides: [
        standingsWithDivisionProvider((
          tournamentId: _tid,
          divisionId: _did,
        )).overrideWith((ref) => _never<List<Standing>>()),
        tournamentProvider(_tid).overrideWith((ref) => _never<Tournament?>()),
      ],
    );

    _expectSkeletonOnly(tester);
  });

  testWidgets('CrossTableView loading shows standings skeleton', (tester) async {
    await _pump(
      tester,
      const CrossTableView(
        matches: <MatchModel>[],
        tournamentId: _tid,
        divisionId: _did,
      ),
      overrides: [
        standingsWithDivisionProvider((
          tournamentId: _tid,
          divisionId: _did,
        )).overrideWith((ref) => _never<List<Standing>>()),
      ],
    );

    _expectSkeletonOnly(tester);
  });

  testWidgets('Venues section loading shows list skeleton, no spinner', (
    tester,
  ) async {
    await _pump(
      tester,
      const TournamentManagementVenuesSection(tournamentId: _tid),
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(
          _NeverVenues(),
        ),
        courtCameraRepositoryProvider.overrideWithValue(_Cameras()),
      ],
    );

    _expectSkeletonOnly(tester);
  });
}
