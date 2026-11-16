import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// TC-IOS-GSI-01: the iOS release build has no `.env` Google values, so the
// native Google Sign-In SDK must get its client ID from Info.plist. A missing
// or mismatched ID aborts the app at the first Google login tap.
const _idSuffix = '.apps.googleusercontent.com';
const _schemePrefix = 'com.googleusercontent.apps.';

String? _setting(String xcconfig, String key) {
  final match = RegExp('^$key=(.+)\$', multiLine: true).firstMatch(xcconfig);
  return match?.group(1)?.trim();
}

void main() {
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

  // Info.plist holds literal values (5ed844c1); they must stay in sync with
  // the xcconfig values Flutter code reads at build time.
  for (final name in ['Debug', 'Release']) {
    test('TC-IOS-GSI-01 Info.plist GIDClientID matches $name.xcconfig', () {
      final xcconfig = File('ios/Flutter/$name.xcconfig').readAsStringSync();
      final clientId = _setting(xcconfig, 'GOOGLE_IOS_CLIENT_ID');

      expect(clientId, isNotNull, reason: 'GOOGLE_IOS_CLIENT_ID is missing');
      expect(
        infoPlist,
        matches(
          RegExp(
            '<key>GIDClientID</key>\\s*<string>${RegExp.escape(clientId!)}</string>',
          ),
        ),
      );
    });

    test('TC-IOS-GSI-01 Info.plist URL scheme matches $name.xcconfig', () {
      final xcconfig = File('ios/Flutter/$name.xcconfig').readAsStringSync();
      final reversed = _setting(xcconfig, 'REVERSED_CLIENT_ID');

      expect(reversed, isNotNull, reason: 'REVERSED_CLIENT_ID is missing');
      expect(infoPlist, contains('<string>$reversed</string>'));
    });
  }

  for (final name in ['Debug', 'Release']) {
    test('TC-IOS-GSI-01 $name.xcconfig client ID matches its URL scheme', () {
      final xcconfig = File('ios/Flutter/$name.xcconfig').readAsStringSync();
      final clientId = _setting(xcconfig, 'GOOGLE_IOS_CLIENT_ID');
      final reversed = _setting(xcconfig, 'REVERSED_CLIENT_ID');

      expect(clientId, isNotNull, reason: 'GOOGLE_IOS_CLIENT_ID is missing');
      expect(clientId, endsWith(_idSuffix));
      expect(
        reversed,
        '$_schemePrefix${clientId!.substring(0, clientId.length - _idSuffix.length)}',
      );
    });
  }
}
