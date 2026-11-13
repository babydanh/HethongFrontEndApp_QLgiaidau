import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_camera_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_court_info.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_match_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMCOURT-01..: collapsed court cards, court popup, no drag-and-drop,
/// court filter chips.
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
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async => [
    TournamentCameraModel(
      id: 'cam-1',
      name: 'Camera 1',
      mode: 'PULL',
      status: 'LIVE',
      courtId: 'court-1',
      playbackUrl: 'https://p.example/1.m3u8',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Catalog implements IMatchRecordingCatalogRepository {
  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MatchModel _match(
  String id, {
  String status = 'SCHEDULED',
  String courtId = 'court-1',
  DateTime? at,
}) => MatchModel(
  updatedAt: DateTime(2026, 1, 1),
  id: id,
  round: 1,
  matchNumber: 1,
  team1Id: '$id-a',
  team2Id: '$id-b',
  team1Name: 'Alpha $id',
  team2Name: 'Beta $id',
  status: status,
  bracketPosition: BracketPosition(round: 1, position: 1),
  courtId: courtId,
  scheduledTime: at,
);

Widget _app(List<MatchModel> matches) => ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWithValue(_Venues()),
    courtCameraRepositoryProvider.overrideWithValue(_Cameras()),
    matchRecordingCatalogRepositoryProvider.overrideWithValue(_Catalog()),
    managedMatchesWithDivisionProvider.overrideWith(
      (ref, args) => Stream.value(matches),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: const Scaffold(
      body: TournamentManagementCameraSection(tournamentId: 't1'),
    ),
  ),
);

Future<void> _pumpTab(WidgetTester tester, List<MatchModel> matches) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(matches));
  await tester.pumpAndSettle();
}

const _sheet = ValueKey('camera-court-sheet');
const _tile1 = ValueKey('camera-court-tile-court-1');
const _tile2 = ValueKey('camera-court-tile-court-2');

Finder _rowInSheet(String matchId) => find.descendant(
  of: find.byKey(_sheet),
  matching: find.byWidgetPredicate(
    (widget) => widget is CameraMatchRow && widget.match.id == matchId,
  ),
);

void main() {
  testWidgets('TC-CAMCOURT-01 court card is collapsed: no camera line or rows', (
    tester,
  ) async {
    await _pumpTab(tester, [_match('open')]);

    expect(find.byKey(_tile1), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(_tile1), matching: find.text('Sân 1')),
      findsOneWidget,
    );
    expect(find.byType(CameraCourtInfo), findsNothing);
    expect(find.byKey(_sheet), findsNothing);
  });

  testWidgets(
    'TC-CAMCOURT-02 tapping a court opens its popup: open matches above finished',
    (tester) async {
      await _pumpTab(tester, [
        _match('done', status: 'COMPLETED', at: DateTime(2026, 1, 1, 8)),
        _match('open', at: DateTime(2026, 1, 1, 9)),
        _match('other', courtId: 'court-2'),
      ]);

      await tester.tap(find.byKey(_tile1));
      await tester.pumpAndSettle();

      expect(find.byKey(_sheet), findsOneWidget);
      expect(find.byType(CameraCourtInfo), findsOneWidget);
      expect(_rowInSheet('open'), findsOneWidget);
      expect(_rowInSheet('done'), findsOneWidget);
      expect(_rowInSheet('other'), findsNothing);
      expect(
        tester.getTopLeft(_rowInSheet('open')).dy,
        lessThan(tester.getTopLeft(_rowInSheet('done')).dy),
      );
    },
  );

  testWidgets('TC-CAMCOURT-03 no drag-and-drop on the Camera tab', (
    tester,
  ) async {
    await _pumpTab(tester, [_match('open')]);

    expect(find.byType(LongPressDraggable<CourtMatchDragData>), findsNothing);
    expect(find.byType(DragTarget<CourtMatchDragData>), findsNothing);
  });

  testWidgets('TC-CAMCOURT-04 court chip filters the court cards', (
    tester,
  ) async {
    await _pumpTab(tester, [_match('open'), _match('b', courtId: 'court-2')]);
    expect(find.byKey(_tile1), findsOneWidget);
    expect(find.byKey(_tile2), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('camera-court-chip-court-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(_tile1), findsNothing);
    expect(find.byKey(_tile2), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('camera-court-chip-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(_tile1), findsOneWidget);
    expect(find.byKey(_tile2), findsOneWidget);
  });
}
