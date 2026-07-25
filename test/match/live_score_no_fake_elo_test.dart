import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LiveScoreScreen không sinh ELO giả từ hash tên người chơi', () {
    final source = File(
      'lib/features/match/screens/live_score_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('_getEloForName')));
    expect(source, isNot(contains('hash.abs() %')));
  });
}
