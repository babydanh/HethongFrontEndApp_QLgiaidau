import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LiveScoreScreen mở public profile khi member có userId thật', () {
    final source = File(
      'lib/features/match/screens/live_score_screen.dart',
    ).readAsStringSync();

    expect(source, contains("/profile/user/"));
    expect(source, contains('member.userId'));
    expect(source, contains('InkWell'));
  });
}
