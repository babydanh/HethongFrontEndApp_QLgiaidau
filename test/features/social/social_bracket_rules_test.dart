import 'package:app_quanly_giaidau/features/social/widgets/match_tab/social_bracket_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-SOCIAL-BRACKET-APP-05: singles cần ít nhất 2 người', () {
    expect(canSubmitBracket(matchType: 'SINGLES', selectedCount: 2, busy: false), isTrue);
    expect(canSubmitBracket(matchType: 'SINGLES', selectedCount: 1, busy: false), isFalse);
    expect(canSubmitBracket(matchType: 'SINGLES', selectedCount: 0, busy: false), isFalse);
  });

  test('TC-SOCIAL-BRACKET-APP-06: doubles cần số chẵn và ít nhất 4', () {
    expect(canSubmitBracket(matchType: 'DOUBLES', selectedCount: 4, busy: false), isTrue);
    expect(canSubmitBracket(matchType: 'DOUBLES', selectedCount: 8, busy: false), isTrue);
    expect(canSubmitBracket(matchType: 'DOUBLES', selectedCount: 3, busy: false), isFalse);
    expect(canSubmitBracket(matchType: 'DOUBLES', selectedCount: 5, busy: false), isFalse);
    expect(canSubmitBracket(matchType: 'DOUBLES', selectedCount: 2, busy: false), isFalse);
  });

  test('TC-SOCIAL-BRACKET-APP-07: đang gửi thì chặn bấm lần nữa', () {
    expect(canSubmitBracket(matchType: 'SINGLES', selectedCount: 4, busy: true), isFalse);
  });

  test('TC-SOCIAL-BRACKET-APP-08: bốn loại bracket đúng tên khoá Backend', () {
    expect(socialBracketTypes, [
      'SINGLE_ELIMINATION',
      'DOUBLE_ELIMINATION',
      'ROUND_ROBIN',
      'GROUP_STAGE_KNOCKOUT',
    ]);
  });
}
