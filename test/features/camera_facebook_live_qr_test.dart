import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/rtmp_url.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/facebook_live_ready_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// TC-RTMP-QR-APP-01..05: the Facebook live QR is the plain RTMP address, shown right away.
const _server = 'rtmps://live-api-s.facebook.com:443/rtmp';
const _key = 'FB-123-0?s_bl=1&s_ps=1&a=b';
const _live = CreatedFacebookLive(
  providerSessionId: '1234567890123456',
  watchUrl: 'https://www.facebook.com/watch/?v=1234567890123456',
  rtmpUrl: _server,
  streamKey: _key,
);

Future<void> _pumpCreated(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => FacebookLiveReadySheet.show(
              context,
              live: _live,
              cameraName: 'Camera A',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('buildPlainRtmpUrl', () {
    test('TC-RTMP-QR-APP-01 joins server and key with one slash, keeps ? & = raw', () {
      for (final server in [_server, '$_server/', ' $_server/ ']) {
        expect(buildPlainRtmpUrl(server, ' $_key '), '$_server/$_key');
      }
    });

    test('TC-RTMP-QR-APP-02 returns null when the server or the key is missing', () {
      expect(buildPlainRtmpUrl('', _key), isNull);
      expect(buildPlainRtmpUrl(_server, '   '), isNull);
    });
  });

  group('FacebookLiveReadySheet QR code', () {
    testWidgets('TC-RTMP-QR-APP-03 shows the RTMP QR without a tap', (tester) async {
      await _pumpCreated(tester);
      expect(find.byKey(const ValueKey('fb-live-qr')), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('TC-RTMP-QR-APP-04 the toggle hides and shows the QR code', (tester) async {
      await _pumpCreated(tester);
      final toggle = find.byKey(const ValueKey('fb-live-qr-toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('TC-RTMP-QR-APP-05 no Larix button or text is offered', (tester) async {
      await _pumpCreated(tester);
      expect(find.byKey(const ValueKey('fb-live-larix-open')), findsNothing);
      expect(find.textContaining('Larix'), findsNothing);
    });
  });
}
