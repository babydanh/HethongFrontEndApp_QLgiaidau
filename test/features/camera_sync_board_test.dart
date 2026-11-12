import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_camera_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_status_badge.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAM-SYNC-27..28: bảng camera với nút phát trên thẻ trận, 360px và tablet.
class _Venues implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'name': 'Nhà thi đấu',
      'courts': [
        {'id': 'court-1', 'name': 'Sân 1'},
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
          name: 'Camera sân 1',
          mode: 'PULL',
          status: 'OFFLINE',
          courtId: 'court-1',
          playbackUrl: 'https://p.example/x.m3u8',
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Catalog implements IMatchRecordingCatalogRepository {
  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) async => const [
    MatchLivestreamSummary(
      matchId: 'm-live',
      cameraId: 'cam-1',
      streamStatus: MatchStreamStatus.live,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MatchModel _match(String id, String name, {String? courtId}) => MatchModel(
  updatedAt: DateTime(2026, 1, 1),
  id: id,
  round: 1,
  matchNumber: 1,
  team1Id: '$id-a',
  team2Id: '$id-b',
  team1Name: '$name Alpha dài dài dài',
  team2Name: '$name Beta dài dài dài',
  status: 'scheduled',
  bracketPosition: BracketPosition(round: 1, position: 1),
  courtId: courtId,
);

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(_Venues()),
        courtCameraRepositoryProvider.overrideWithValue(_Cameras()),
        matchRecordingCatalogRepositoryProvider.overrideWithValue(_Catalog()),
        managedMatchesWithDivisionProvider.overrideWith(
          (ref, args) => Stream.value([
            _match('m-live', 'Live', courtId: 'court-1'),
            _match('m-free', 'Free'),
          ]),
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
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in const [Size(360, 740), Size(900, 1200)]) {
    testWidgets('TC-CAM-SYNC-27/28 bảng camera ${size.width.toInt()}px: nút phát đúng trạng thái, không tràn', (
      tester,
    ) async {
      await _pump(tester, size);

      expect(tester.takeException(), isNull);
      // Trận đang LIVE ở sân 1 (cả ở danh sách trận và thẻ sân): có Dừng, không MP4.
      expect(find.widgetWithText(OutlinedButton, 'Dừng'), findsWidgets);
      // Trận chưa xếp sân: Bắt đầu khoá, không có MP4 (không camera, không bản ghi).
      final starts = tester.widgetList<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Bắt đầu'),
      );
      expect(starts, isNotEmpty);
      expect(starts.every((button) => button.onPressed == null), isTrue);
      expect(find.widgetWithText(OutlinedButton, 'MP4'), findsNothing);
      // Camera sân OFFLINE hiện badge chữ.
      expect(find.byType(CameraStatusBadge), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });
  }
}
