import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_camera_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMGON-01..06: compact Camera tab — one-row court chips, match rows with
/// a visible Bật cam / Tắt cam button, no redundant court chip in the pool,
/// read-only note.
class _Venues implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'name': 'Nhà thi đấu',
      'courts': [
        {'id': 'court-1', 'name': 'Sân 1'},
        {'id': 'court-2', 'name': 'Sân 2'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cameras implements ICourtCameraRepository {
  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      const [
        TournamentCameraModel(
          id: 'cam-1',
          name: 'Camera 1',
          mode: 'PULL',
          status: 'IDLE',
          courtId: 'court-1',
          playbackUrl: 'https://p.example/1.m3u8',
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Admin implements ICameraAdminRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Serves [live] match ids as LIVE and records start/stop commands.
class _Catalog implements IMatchRecordingCatalogRepository {
  _Catalog({this.live = const {}});

  final Set<String> live;
  final commands = <String>[];

  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) async => [
    for (final id in live)
      MatchLivestreamSummary(
        matchId: id,
        cameraId: 'cam-1',
        streamStatus: MatchStreamStatus.live,
      ),
  ];

  @override
  Future<MatchStreamCommandResult> startMatchStream(String matchId) async {
    commands.add('start:$matchId');
    return const MatchStreamCommandResult(streamStatus: MatchStreamStatus.live);
  }

  @override
  Future<MatchStreamCommandResult> stopMatchStream(String matchId) async {
    commands.add('stop:$matchId');
    return const MatchStreamCommandResult(streamStatus: MatchStreamStatus.idle);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MatchModel _match(String id, {String courtId = 'court-1'}) => MatchModel(
  updatedAt: DateTime(2026, 1, 1),
  id: id,
  round: 1,
  matchNumber: 1,
  team1Id: '$id-a',
  team2Id: '$id-b',
  team1Name: 'Alpha $id',
  team2Name: 'Beta $id',
  status: 'SCHEDULED',
  bracketPosition: BracketPosition(round: 1, position: 1),
  courtId: courtId,
);

Future<void> _pump(
  WidgetTester tester,
  List<MatchModel> matches, {
  _Catalog? catalog,
  bool readOnly = false,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(_Venues()),
        courtCameraRepositoryProvider.overrideWithValue(_Cameras()),
        cameraAdminRepositoryProvider.overrideWithValue(_Admin()),
        matchRecordingCatalogRepositoryProvider.overrideWithValue(
          catalog ?? _Catalog(),
        ),
        managedMatchesWithDivisionProvider.overrideWith(
          (ref, args) => Stream.value(matches),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementCameraSection(
            tournamentId: 't1',
            readOnly: readOnly,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _toggle(String matchId) =>
    find.byKey(ValueKey('camera-match-toggle-$matchId'));

Future<void> _openCourtOne(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('camera-court-tile-court-1')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-CAMGON-01 court chips share one horizontal scroll row', (
    tester,
  ) async {
    await _pump(tester, [_match('a')]);

    final scroller = find.ancestor(
      of: find.byKey(const ValueKey('camera-court-chip-all')),
      matching: find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      ),
    );
    expect(scroller, findsOneWidget);
    expect(
      find.descendant(
        of: scroller,
        matching: find.byKey(const ValueKey('camera-court-chip-court-2')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-CAMGON-02 pool rows do not repeat the "Chưa có sân" chip', (
    tester,
  ) async {
    await _pump(tester, [_match('free', courtId: '')]);

    expect(find.textContaining('Alpha free'), findsOneWidget);
    expect(find.text('Chưa có sân'), findsNothing);
  });

  testWidgets(
    'TC-CAMGON-03 a match with a camera offers Bật cam and starts it',
    (tester) async {
      final catalog = _Catalog();
      await _pump(tester, [_match('a')], catalog: catalog);
      await _openCourtOne(tester);

      expect(_toggle('a'), findsOneWidget);
      expect(
        find.descendant(of: _toggle('a'), matching: find.text('Bật cam')),
        findsOneWidget,
      );
      await tester.tap(_toggle('a'));
      await tester.pumpAndSettle();
      expect(catalog.commands, ['start:a']);
    },
  );

  testWidgets('TC-CAMGON-04 a LIVE match shows Tắt cam and stops it', (
    tester,
  ) async {
    final catalog = _Catalog(live: {'a'});
    await _pump(tester, [_match('a')], catalog: catalog);
    await _openCourtOne(tester);

    expect(
      find.descendant(of: _toggle('a'), matching: find.text('Tắt cam')),
      findsOneWidget,
    );
    await tester.tap(_toggle('a'));
    await tester.pumpAndSettle();
    expect(catalog.commands, ['stop:a']);
  });

  testWidgets('TC-CAMGON-05 no toggle without a camera or when read-only', (
    tester,
  ) async {
    // Pool match has no court, so no camera to switch on.
    await _pump(tester, [_match('free', courtId: '')]);
    expect(_toggle('free'), findsNothing);

    await _pump(tester, [_match('a')], readOnly: true);
    await _openCourtOne(tester);
    expect(_toggle('a'), findsNothing);
  });

  testWidgets('TC-CAMGON-06 read-only tab explains why there is no + button', (
    tester,
  ) async {
    await _pump(tester, [_match('a')], readOnly: true);
    expect(find.byKey(const ValueKey('camTabReadOnlyNote')), findsOneWidget);
    expect(find.text('Chỉ xem'), findsOneWidget);

    await _pump(tester, [_match('a')]);
    expect(find.byKey(const ValueKey('camTabReadOnlyNote')), findsNothing);
  });
}
