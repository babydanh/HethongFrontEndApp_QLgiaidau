import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// TC-SENTRY-CI-01: a release build only reports errors when CI hands the DSN
// to the app as a compile-time define (`String.fromEnvironment`), and native
// iOS crashes only become readable once the dSYMs reach the error tracker.
void main() {
  final workflow = File('.github/workflows/deploy-ios.yml').readAsStringSync();

  test('TC-SENTRY-CI-01 both iOS builds read the Sentry defines file', () {
    final builds = RegExp(
      r'flutter build (?:ios|ipa)[^\n]*',
    ).allMatches(workflow).map((m) => m.group(0)!).toList();

    expect(builds, hasLength(2));
    for (final line in builds) {
      expect(line, contains('--dart-define-from-file=ci_defines.json'));
    }
  });

  test('TC-SENTRY-CI-01 the DSN comes from a secret, never from the file', () {
    expect(workflow, contains(r'${{ secrets.SENTRY_DSN }}'));
    expect(workflow, isNot(matches(RegExp(r'https://[0-9a-f]{16,}@'))));
  });

  test('TC-SENTRY-CI-01 dSYMs are uploaded best-effort with a pinned CLI', () {
    final start = workflow.indexOf('name: Upload dSYMs');
    expect(start, greaterThan(-1), reason: 'dSYM upload step is missing');

    final step = workflow.substring(start);
    expect(step, contains('continue-on-error: true'));
    expect(step, contains(r'${{ secrets.SENTRY_AUTH_TOKEN }}'));
    expect(
      step,
      matches(RegExp(r'@sentry/cli@2\.\d+\.\d+ debug-files upload')),
    );
  });
}
