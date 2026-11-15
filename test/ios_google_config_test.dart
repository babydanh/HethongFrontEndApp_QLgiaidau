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

  test('TC-IOS-GSI-01 Info.plist reads GIDClientID from the xcconfig', () {
    expect(
      infoPlist,
      matches(
        RegExp(
          r'<key>GIDClientID</key>\s*<string>\$\(GOOGLE_IOS_CLIENT_ID\)</string>',
        ),
      ),
    );
  });

  test('TC-IOS-GSI-01 Info.plist registers the reversed client ID scheme', () {
    expect(infoPlist, contains(r'<string>$(REVERSED_CLIENT_ID)</string>'));
  });

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
