import 'package:app_quanly_giaidau/core/utils/dupr_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('duprLimitOptions', () {
    test('runs 2.0 to 6.0 in 0.5 steps', () {
      expect(duprLimitOptions.first, 2.0);
      expect(duprLimitOptions.last, 6.0);
      expect(duprLimitOptions, hasLength(9));
      expect(duprLimitOptions[1], 2.5);
    });
  });

  group('checkDuprAgainstLimit', () {
    test('no limit is ok, even without a rating', () {
      expect(
        checkDuprAgainstLimit(value: null, minDupr: null, maxDupr: null),
        DuprLimitStatus.ok,
      );
      expect(
        checkDuprAgainstLimit(value: 9, minDupr: null, maxDupr: null),
        DuprLimitStatus.ok,
      );
    });

    test('limit with no rating is missing', () {
      expect(
        checkDuprAgainstLimit(value: null, minDupr: 3.0, maxDupr: null),
        DuprLimitStatus.missing,
      );
      expect(
        checkDuprAgainstLimit(value: null, minDupr: null, maxDupr: 3.5),
        DuprLimitStatus.missing,
      );
    });

    test('bounds are inclusive', () {
      expect(
        checkDuprAgainstLimit(value: 3.0, minDupr: 3.0, maxDupr: 3.5),
        DuprLimitStatus.ok,
      );
      expect(
        checkDuprAgainstLimit(value: 3.5, minDupr: 3.0, maxDupr: 3.5),
        DuprLimitStatus.ok,
      );
    });

    test('outside the range', () {
      expect(
        checkDuprAgainstLimit(value: 3.62, minDupr: 3.0, maxDupr: 3.5),
        DuprLimitStatus.aboveMax,
      );
      expect(
        checkDuprAgainstLimit(value: 2.99, minDupr: 3.0, maxDupr: 3.5),
        DuprLimitStatus.belowMin,
      );
    });

    test('one-sided limits', () {
      expect(
        checkDuprAgainstLimit(value: 2.0, minDupr: 3.0, maxDupr: null),
        DuprLimitStatus.belowMin,
      );
      expect(
        checkDuprAgainstLimit(value: 7.0, minDupr: 3.0, maxDupr: null),
        DuprLimitStatus.ok,
      );
      expect(
        checkDuprAgainstLimit(value: 4.0, minDupr: null, maxDupr: 3.5),
        DuprLimitStatus.aboveMax,
      );
    });
  });

  group('formatDuprRange', () {
    test('three shapes and null', () {
      expect(formatDuprRange(3.0, 3.5), '3.0 – 3.5');
      expect(formatDuprRange(null, 3.5), '≤ 3.5');
      expect(formatDuprRange(3.0, null), '≥ 3.0');
      expect(formatDuprRange(null, null), isNull);
    });
  });

  group('pickDuprFromRatings', () {
    test('empty list gives null', () {
      expect(pickDuprFromRatings(const []), isNull);
    });

    test('API source wins over SELF regardless of order', () {
      expect(
        pickDuprFromRatings([
          {'source': 'SELF', 'value': 3.1},
          {'source': 'API', 'value': '3.4'},
        ]),
        3.4,
      );
    });

    test('falls back to SELF when no API row', () {
      expect(
        pickDuprFromRatings([
          {'source': 'SELF', 'value': 3.1},
        ]),
        3.1,
      );
    });

    test('ignores rows without a usable value', () {
      expect(
        pickDuprFromRatings([
          {'source': 'API', 'value': null},
          {'source': 'SELF', 'value': '3.2'},
        ]),
        3.2,
      );
    });
  });

  group('parseDuprRating / isValidDuprRating', () {
    test('accepts dot and comma decimals inside 1.0 to 8.0', () {
      expect(parseDuprRating('3.5'), 3.5);
      expect(parseDuprRating('3,5'), 3.5);
      expect(parseDuprRating(' 3.62 '), 3.62);
      expect(parseDuprRating('1'), 1.0);
      expect(parseDuprRating('8.00'), 8.0);
    });

    test('rejects empty, out of range, junk and more than 2 decimals', () {
      for (final text in ['', ' ', '.', '3.', '0.9', '8.01', '9', 'abc', '3.621', '-3', '3..5']) {
        expect(parseDuprRating(text), isNull, reason: '"$text"');
      }
    });

    test('isValidDuprRating mirrors the range and decimal rule', () {
      expect(isValidDuprRating(1.0), isTrue);
      expect(isValidDuprRating(8.0), isTrue);
      expect(isValidDuprRating(3.62), isTrue);
      expect(isValidDuprRating(0.99), isFalse);
      expect(isValidDuprRating(8.5), isFalse);
      expect(isValidDuprRating(3.621), isFalse);
      expect(isValidDuprRating(double.nan), isFalse);
      expect(isValidDuprRating(double.infinity), isFalse);
    });
  });

  group('formatDuprRating', () {
    test('1 to 2 decimals, float noise removed', () {
      expect(formatDuprRating(3), '3.0');
      expect(formatDuprRating(3.5), '3.5');
      expect(formatDuprRating(3.62), '3.62');
      expect(formatDuprRating(3.4999999), '3.5');
      expect(formatDuprRating(3.10), '3.1');
    });
  });
}
