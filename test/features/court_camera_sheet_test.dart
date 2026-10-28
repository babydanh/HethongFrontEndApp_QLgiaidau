import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake value only; never printed by any assertion message.
const _storedUrl = 'rtsp://camera.example.test/stream';
const _newUrl = 'rtsp://camera.example.test/other';

class _FakeCameraRepository implements ICourtCameraRepository {
  _FakeCameraRepository({required String? initialUrl}) : _url = initialUrl;

  String? _url;
  final writes = <String>[];
  bool failWrites = false;

  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      [
        TournamentCameraModel(
          id: 'camera-1',
          name: 'Camera 1',
          mode: 'PULL',
          status: 'ACTIVE',
          courtId: 'court-1',
          playbackUrl: _url,
        ),
      ];

  @override
  Future<String?> setCourtPlaybackUrl({
    required String tournamentId,
    required String courtId,
    required String playbackUrl,
  }) async {
    if (failWrites) throw Exception('write failed');
    writes.add(playbackUrl);
    _url = playbackUrl.isEmpty ? null : playbackUrl;
    return playbackUrl.isEmpty ? null : 'camera-1';
  }

  @override
  Future<void> assignCamera({
    required String matchId,
    required String cameraId,
  }) async {}

  @override
  Future<CameraLiveStatusModel> getCameraLiveStatus(String cameraId) =>
      throw UnimplementedError();
}

Future<_FakeCameraRepository> _open(
  WidgetTester tester, {
  String? initialUrl,
}) async {
  final repository = _FakeCameraRepository(initialUrl: initialUrl);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [courtCameraRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) {
            // Keeps the camera list loaded, as the venues list does.
            ref.watch(tournamentCamerasProvider('t-1'));
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showCourtCameraSheet(
                    context,
                    tournamentId: 't-1',
                    courtId: 'court-1',
                    courtName: 'Court 1',
                  ),
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repository;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(CourtCameraSheet)))!;

final _field = find.byKey(const ValueKey('court-camera-sheet-url'));

bool _obscured(WidgetTester tester) =>
    tester.widget<TextField>(_field).obscureText;

void main() {
  testWidgets('stored URL is masked until the show button is tapped', (
    tester,
  ) async {
    await _open(tester, initialUrl: _storedUrl);
    final l10n = _l10n(tester);

    expect(
      find.text(l10n.tournamentManagementCourtCameraSheetTitle('Court 1')),
      findsOneWidget,
    );
    expect(_obscured(tester), isTrue);

    await tester.tap(find.text(l10n.tournamentManagementCameraShowUrl));
    await tester.pump();
    expect(_obscured(tester), isFalse);

    await tester.tap(find.text(l10n.tournamentManagementCameraHideUrl));
    await tester.pump();
    expect(_obscured(tester), isTrue);
  });

  testWidgets('save writes the typed URL once and closes the sheet', (
    tester,
  ) async {
    final repository = await _open(tester, initialUrl: _storedUrl);
    final l10n = _l10n(tester);

    await tester.enterText(_field, _newUrl);
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementSave),
    );
    await tester.pumpAndSettle();

    expect(repository.writes.length, 1);
    expect(repository.writes.single == _newUrl, isTrue);
    expect(find.byType(CourtCameraSheet), findsNothing);
  });

  testWidgets('save with an empty field writes nothing', (tester) async {
    final repository = await _open(tester);
    final l10n = _l10n(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementSave),
    );
    await tester.pumpAndSettle();

    expect(repository.writes, isEmpty);
    expect(
      find.text(l10n.tournamentManagementCameraUrlRequired),
      findsOneWidget,
    );
    expect(find.byType(CourtCameraSheet), findsOneWidget);
  });

  testWidgets('failed save keeps the sheet open with a generic message', (
    tester,
  ) async {
    final repository = await _open(tester, initialUrl: _storedUrl);
    repository.failWrites = true;
    final l10n = _l10n(tester);

    await tester.enterText(_field, _newUrl);
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementSave),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CourtCameraSheet), findsOneWidget);
    expect(
      find.text(l10n.tournamentManagementCameraUrlSaveFailed),
      findsOneWidget,
    );
  });

  testWidgets('detach asks for confirmation then writes an empty URL', (
    tester,
  ) async {
    final repository = await _open(tester, initialUrl: _storedUrl);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.tournamentManagementCameraDetach));
    await tester.pumpAndSettle();
    expect(repository.writes, isEmpty);

    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementCameraDetach),
    );
    await tester.pumpAndSettle();

    expect(repository.writes, ['']);
    expect(find.byType(CourtCameraSheet), findsNothing);
  });

  testWidgets('detach is disabled when the court has no camera', (
    tester,
  ) async {
    await _open(tester);
    final l10n = _l10n(tester);

    final detach = find.ancestor(
      of: find.text(l10n.tournamentManagementCameraDetach),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(detach).onPressed, isNull);
  });
}
