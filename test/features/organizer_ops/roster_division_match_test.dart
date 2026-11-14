import 'package:flutter_test/flutter_test.dart';

import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_division_match.dart';

void main() {
  group('TC-ROSTERLIST-01 so khớp tên nội dung', () {
    test('foldName bỏ dấu, chữ thường và gộp khoảng trắng', () {
      expect(foldName('  Đơn   NAM '), 'don nam');
    });

    test('divisionLabelMatches khớp cùng bộ từ khác thứ tự', () {
      expect(divisionLabelMatches('Nam đơn', 'Đơn nam'), isTrue);
    });

    test('divisionLabelMatches không khớp nội dung đôi với đơn', () {
      expect(divisionLabelMatches('Đôi nam', 'Đơn nam'), isFalse);
    });

    test('inferMatchType nhận ra đôi nam nữ và đơn', () {
      expect(
        inferMatchType('Đôi hỗn hợp', anyRowHasPlayer2: false),
        'MIXED_DOUBLES',
      );
      expect(inferMatchType('Đơn nam', anyRowHasPlayer2: false), 'SINGLES');
    });
  });
}
