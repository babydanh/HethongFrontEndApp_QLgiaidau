import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/larix_link.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/facebook_live_ready_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-LARIX-APP-01..06: open the Facebook live stream in Larix Broadcaster with one tap.
const _server = 'rtmps://live-api-s.facebook.com:443/rtmp';
const _key = 'FB-123-0?s_bl=1&s_ps=1&a=b';
const _live = CreatedFacebookLive(
  providerSessionId: '1234567890123456',
  watchUrl: 'https://www.facebook.com/watch/?v=1234567890123456',
  rtmpUrl: _server,
  streamKey: _key,
);

Future<void> _pumpCreated(
  WidgetTester tester,
  Future<bool> Function(Uri uri) launchLink,
) async {
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
              launchLink: launchLink,
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

final _open = find.byKey(const ValueKey('fb-live-larix-open'));

void main() {
  group('buildLarixSetupUrl', () {
    test('TC-LARIX-APP-01 joins server and key with exactly one slash', () {
      for (final server in [_server, '$_server/']) {
        final uri = Uri.parse(buildLarixSetupUrl(server, _key, 'SportO Live')!);
        expect(uri.queryParameters['conn[][url]'], '$_server/$_key');
      }
    });

    test('TC-LARIX-APP-02 keeps a key with ? & = inside one conn[][url] value', () {
      final link = buildLarixSetupUrl(_server, _key, 'SportO Live')!;
      expect(link.startsWith('larix://set/v1?conn[][url]='), isTrue);
      final params = Uri.parse(link).queryParameters;
      expect(params['s_bl'], isNull);
      expect(params['conn[][name]'], 'SportO Live');
      expect(params['conn[][overwrite]'], 'on');
      expect(params['conn[][active]'], 'on');
    });

    test('TC-LARIX-APP-03 returns null when the server or the key is missing', () {
      expect(buildLarixSetupUrl('', _key, 'x'), isNull);
      expect(buildLarixSetupUrl(_server, '   ', 'x'), isNull);
    });
  });

  group('FacebookLiveReadySheet Larix button', () {
    testWidgets('TC-LARIX-APP-04 tap opens the Larix link once, target >= 48dp', (
      tester,
    ) async {
      final launched = <Uri>[];
      await _pumpCreated(tester, (uri) async {
        launched.add(uri);
        return true;
      });
      expect(tester.getSize(_open).height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(_open);
      await tester.tap(_open);
      await tester.pumpAndSettle();
      expect(launched, hasLength(1));
      expect(launched.single.scheme, 'larix');
      expect(launched.single.queryParameters['conn[][url]'], '$_server/$_key');
    });

    testWidgets('TC-LARIX-APP-05 Larix not installed shows a hint instead of failing', (
      tester,
    ) async {
      await _pumpCreated(tester, (_) async => false);
      await tester.ensureVisible(_open);
      await tester.tap(_open);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('TC-LARIX-APP-06 a second tap while launching is ignored', (
      tester,
    ) async {
      final gate = Completer<bool>();
      var calls = 0;
      await _pumpCreated(tester, (_) {
        calls++;
        return gate.future;
      });
      await tester.ensureVisible(_open);
      await tester.tap(_open);
      await tester.pump();
      await tester.tap(_open, warnIfMissed: false);
      await tester.pump();
      expect(calls, 1);
      gate.complete(true);
      await tester.pumpAndSettle();
    });
  });
}
