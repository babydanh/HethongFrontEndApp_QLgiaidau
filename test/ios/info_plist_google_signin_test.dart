import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _iosClientId =
    '581793214855-skbscd9le4ug3lvr44av36iv7q9oqac5.apps.googleusercontent.com';
const _webClientId =
    '581793214855-kl77ogsngavgd3e4vr5dtvpo9qelmv5s.apps.googleusercontent.com';
const _reversedIosClientId =
    'com.googleusercontent.apps.581793214855-skbscd9le4ug3lvr44av36iv7q9oqac5';

void main() {
  // Google Sign-In aborts the iOS process when GIDClientID or the reversed
  // client id URL scheme is missing (App Review 2.1(a), build 35).
  final plist = File('ios/Runner/Info.plist').readAsStringSync();

  bool hasKey(String key, String value) => RegExp(
    '<key>$key</key>\s*<string>${RegExp.escape(value)}</string>',
  ).hasMatch(plist);

  group('TC-GSI-01 ios/Runner/Info.plist Google Sign-In config', () {
    test('declares GIDClientID with the iOS OAuth client', () {
      expect(hasKey('GIDClientID', _iosClientId), isTrue);
    });

    test('declares GIDServerClientID with the web OAuth client', () {
      expect(hasKey('GIDServerClientID', _webClientId), isTrue);
    });

    test('registers the reversed iOS client id as a URL scheme', () {
      expect(plist.contains('<string>$_reversedIosClientId</string>'), isTrue);
    });

    test('has no unresolved REVERSED_CLIENT_ID build variable', () {
      expect(plist.contains(r'$(REVERSED_CLIENT_ID)'), isFalse);
    });
  });
}
