import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_venues_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake value only; the tests assert it never appears in the list.
const _fakeUrl = 'rtsp://camera.example.test/stream';

class _VenuesRepository implements TournamentManagementRepository {
  final removedCourts = <String>[];

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'North Hall',
      'locationAddress': '12 Lake Road',
      'isDefault': true,
      'courts': [
        {'id': 'court-1', 'name': 'Court 1'},
        {'id': 'court-2', 'name': 'Court 2'},
      ],
    },
  ];

  @override
  Future<void> removeCourt(String id, String venueId, String courtId) async {
    removedCourts.add(courtId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CameraRepository implements ICourtCameraRepository {
  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      [
        const TournamentCameraModel(
          id: 'camera-1',
          name: 'Camera 1',
          mode: 'PULL',
          status: 'ACTIVE',
          courtId: 'court-1',
          playbackUrl: _fakeUrl,
        ),
      ];

  @override
  Future<String?> setCourtPlaybackUrl({
    required String tournamentId,
    required String courtId,
    required String playbackUrl,
  }) async => null;

  @override
  Future<void> assignCamera({
    required String matchId,
    required String cameraId,
  }) async {}

  @override
  Future<CameraLiveStatusModel> getCameraLiveStatus(String cameraId) =>
      throw UnimplementedError();
}

Future<_VenuesRepository> _pump(
  WidgetTester tester, {
  bool editFirstVenue = false,
}) async {
  final venues = _VenuesRepository();
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(venues),
        courtCameraRepositoryProvider.overrideWithValue(_CameraRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TournamentManagementVenuesSection(
            tournamentId: 't-1',
            editFirstVenue: editFirstVenue,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return venues;
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
  tester.element(find.byType(TournamentManagementVenuesSection)),
)!;

void main() {
  testWidgets('TC-EDIT-04 editFirstVenue opens the default venue editor at once', (
    tester,
  ) async {
    await _pump(tester, editFirstVenue: true);

    expect(find.widgetWithText(TextField, 'North Hall'), findsOneWidget);
    expect(find.widgetWithText(TextField, '12 Lake Road'), findsOneWidget);
  });

  testWidgets('without editFirstVenue no editor is opened', (tester) async {
    await _pump(tester);

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('each court is one row with a camera status and no URL', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text('Court 1'), findsOneWidget);
    expect(find.text('Court 2'), findsOneWidget);
    expect(
      find.text(l10n.tournamentManagementCourtCameraAttached),
      findsOneWidget,
    );
    expect(
      find.text(l10n.tournamentManagementCourtCameraNotAttached),
      findsOneWidget,
    );
    // No URL field, no URL text and no delete chip next to the court name.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(InputChip), findsNothing);
    expect(find.textContaining('camera.example.test'), findsNothing);
  });

  testWidgets('edit opens the camera sheet with a masked URL', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('court-edit-court-1')));
    await tester.pumpAndSettle();

    expect(find.byType(CourtCameraSheet), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('court-camera-sheet-url')),
    );
    expect(field.obscureText, isTrue);
  });

  testWidgets('removing a court goes through the menu and a confirmation', (
    tester,
  ) async {
    final venues = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('court-menu-court-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementRemove));
    await tester.pumpAndSettle();
    // Dialog is up; nothing is removed until it is confirmed.
    expect(venues.removedCourts, isEmpty);

    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementRemove),
    );
    await tester.pumpAndSettle();

    expect(venues.removedCourts, ['court-2']);
  });
}
