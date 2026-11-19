import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_editor_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sporto_cam_download.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAM-APP-APP-01..05: SportO Cam download buttons in the add-camera sheet.
final _android = find.byKey(const ValueKey('sporto-cam-download-android'));
final _ios = find.byKey(const ValueKey('sporto-cam-download-ios'));

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  test(
    'TC-CAM-APP-APP-01 a phone gets only its own store, anything else gets both',
    () {
      expect(sportoCamStoresFor(TargetPlatform.android), [
        SportoCamStore.android,
      ]);
      expect(sportoCamStoresFor(TargetPlatform.iOS), [SportoCamStore.ios]);
      expect(sportoCamStoresFor(TargetPlatform.windows), [
        SportoCamStore.android,
        SportoCamStore.ios,
      ]);
    },
  );

  test(
    'TC-CAM-APP-APP-02 links point at the SportO Cam listings, not the main SportO app',
    () {
      final play = Uri.parse(sportoCamStoreUrls[SportoCamStore.android]!);
      expect(play.host, 'play.google.com');
      expect(play.queryParameters['id'], 'vn.vnvar.sportocam');
      final apple = Uri.parse(sportoCamStoreUrls[SportoCamStore.ios]!);
      expect(apple.host, 'apps.apple.com');
      expect(apple.path, endsWith('/id6813012756'));
    },
  );

  testWidgets('TC-CAM-APP-APP-03 tapping a button opens that store link', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _host(
        SportoCamDownload(
          platform: TargetPlatform.windows,
          openUrl: (uri) async => opened.add(uri),
        ),
      ),
    );
    expect(_android, findsOneWidget);
    expect(_ios, findsOneWidget);

    await tester.tap(_ios);
    await tester.pump();
    await tester.tap(_android);
    await tester.pump();

    expect(opened.map((uri) => uri.host), [
      'apps.apple.com',
      'play.google.com',
    ]);
  });

  testWidgets('TC-CAM-APP-APP-04 an iPhone sees only the App Store button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SportoCamDownload(
          platform: TargetPlatform.iOS,
          openUrl: (uri) async {},
        ),
      ),
    );
    expect(_ios, findsOneWidget);
    expect(_android, findsNothing);
    expect(find.text('Download on the App Store'), findsOneWidget);
  });

  testWidgets(
    'TC-CAM-APP-APP-05 the add-camera sheet shows the buttons on the phone tab only',
    (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CameraEditorSheet.show(
                context,
                courts: const [
                  TournamentCourtRef(
                    id: 'court-1',
                    name: 'Court 1',
                    venueName: 'Hall',
                  ),
                ],
                onSubmit: (value) async {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // flutter_test runs as Android, so the phone tab offers the Google Play button.
      expect(_android, findsOneWidget);
      expect(_ios, findsNothing);

      await tester.tap(find.byKey(const ValueKey('camera-source-live')));
      await tester.pumpAndSettle();
      expect(_android, findsNothing);
    },
  );
}
