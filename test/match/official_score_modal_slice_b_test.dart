import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('official score modal có warning box rõ cho score validation', () {
    final source = File(
      'lib/features/match/widgets/official_score_modal.dart',
    ).readAsStringSync();

    expect(source, contains('ScoreWarningBox'));
    expect(source, contains('state.errorMessage'));
  });

  test('official score modal chọn panel riêng cho Cầu lông và Bóng bàn', () {
    final modal = File(
      'lib/features/match/widgets/official_score_modal.dart',
    ).readAsStringSync();
    final badminton = File(
      'lib/features/match/widgets/badminton_score_panel.dart',
    ).readAsStringSync();
    final tableTennis = File(
      'lib/features/match/widgets/table_tennis_score_panel.dart',
    ).readAsStringSync();

    expect(modal, contains('BadmintonScorePanel'));
    expect(modal, contains('TableTennisScorePanel'));
    expect(badminton, contains('Cầu lông'));
    expect(badminton, contains('RallyScorePanel'));
    expect(tableTennis, contains('Bóng bàn'));
    expect(tableTennis, contains('RallyScorePanel'));
  });
}
