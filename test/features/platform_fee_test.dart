import 'package:app_quanly_giaidau/features/tournament/utils/platform_fee.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test port Dart của `getPlatformFeeBreakdown` (Web:
/// `src/utils/platform-fee.ts`) — mọi ca số dưới đây bám sát công thức Web.
void main() {
  group('getPlatformFeeBreakdown', () {
    test('lệ phí 0 -> miễn phí dù có tỷ lệ phần trăm', () {
      final breakdown = getPlatformFeeBreakdown(0, platformFeePercentage: 5);
      expect(breakdown.feePerPlayer, 0);
      expect(breakdown.percentage, 5);
      expect(breakdown.ruleType, PlatformFeeRuleType.free);
      expect(breakdown.organizerNet, 0);
    });

    test('tỷ lệ null / 0 / không hợp lệ -> miễn phí', () {
      for (final percentage in [null, 0, -3, 'abc', '']) {
        final breakdown = getPlatformFeeBreakdown(
          200000,
          platformFeePercentage: percentage,
        );
        expect(breakdown.feePerPlayer, 0, reason: 'percentage: $percentage');
        expect(breakdown.ruleType, PlatformFeeRuleType.free);
      }
    });

    test('lệ phí >= ngưỡng mặc định 100000 -> phí theo phần trăm', () {
      // Web: Math.round(200000 * 5 / 100) = 10000.
      final breakdown = getPlatformFeeBreakdown(
        200000,
        platformFeePercentage: 5,
      );
      expect(breakdown.feePerPlayer, 10000);
      expect(breakdown.ruleType, PlatformFeeRuleType.percentage);
      expect(breakdown.percentage, 5);
      expect(breakdown.thresholdAmount, 100000);
      expect(breakdown.organizerNet, 190000);
    });

    test('lệ phí đúng bằng ngưỡng -> vẫn tính theo phần trăm (>=)', () {
      final breakdown = getPlatformFeeBreakdown(
        100000,
        platformFeePercentage: 5,
      );
      expect(breakdown.feePerPlayer, 5000);
      expect(breakdown.ruleType, PlatformFeeRuleType.percentage);
    });

    test('làm tròn: 99999 x 3% = 2999.97 -> 3000', () {
      final breakdown = getPlatformFeeBreakdown(
        99999,
        platformFeePercentage: 3,
        thresholdAmount: 50000,
      );
      expect(breakdown.feePerPlayer, 3000);
      expect(breakdown.ruleType, PlatformFeeRuleType.percentage);
    });

    test('lệ phí dưới ngưỡng -> phí cố định mặc định 5000', () {
      // Web: 50000 < 100000 -> FIXED, feePerPlayer = fixedAmount mặc định.
      final breakdown = getPlatformFeeBreakdown(
        50000,
        platformFeePercentage: 5,
      );
      expect(breakdown.feePerPlayer, 5000);
      expect(breakdown.fixedAmount, 5000);
      expect(breakdown.ruleType, PlatformFeeRuleType.fixed);
      expect(breakdown.organizerNet, 45000);
    });

    test('phí cố định lớn hơn lệ phí -> BTC nhận 0 (không âm)', () {
      final breakdown = getPlatformFeeBreakdown(
        3000,
        platformFeePercentage: 5,
        fixedAmount: 5000,
      );
      expect(breakdown.feePerPlayer, 5000);
      expect(breakdown.organizerNet, 0);
    });

    test('ngưỡng và phí cố định truyền bằng chuỗi số -> vẫn dùng được', () {
      final breakdown = getPlatformFeeBreakdown(
        50000,
        platformFeePercentage: '5',
        thresholdAmount: '30000',
        fixedAmount: '7000',
      );
      // 50000 >= 30000 -> phần trăm: 50000 * 5% = 2500.
      expect(breakdown.thresholdAmount, 30000);
      expect(breakdown.fixedAmount, 7000);
      expect(breakdown.feePerPlayer, 2500);
      expect(breakdown.ruleType, PlatformFeeRuleType.percentage);
    });

    test('ngưỡng / phí cố định không hợp lệ -> dùng mặc định của Web', () {
      for (final bad in ['abc', -5, 1.5, '']) {
        final breakdown = getPlatformFeeBreakdown(
          200000,
          platformFeePercentage: 5,
          thresholdAmount: bad,
          fixedAmount: bad,
        );
        expect(breakdown.thresholdAmount, 100000, reason: 'threshold: $bad');
        expect(breakdown.fixedAmount, 5000, reason: 'fixed: $bad');
      }
    });

    test('ngưỡng bằng 0 -> mọi lệ phí dương tính theo phần trăm', () {
      // 1 x 5% = 0.05 -> làm tròn 0 (Math.round(0.05) = 0 bên Web).
      final breakdown = getPlatformFeeBreakdown(
        1,
        platformFeePercentage: 5,
        thresholdAmount: 0,
      );
      expect(breakdown.ruleType, PlatformFeeRuleType.percentage);
      expect(breakdown.feePerPlayer, 0);
      expect(breakdown.organizerNet, 1);
    });

    test('lệ phí vào bằng chuỗi -> parse như Number() của Web', () {
      final breakdown = getPlatformFeeBreakdown(
        '200000',
        platformFeePercentage: '5',
      );
      expect(breakdown.entryFee, 200000);
      expect(breakdown.feePerPlayer, 10000);
    });

    test('giá trị == và description tiếng Việt', () {
      final a = getPlatformFeeBreakdown(200000, platformFeePercentage: 5);
      final b = getPlatformFeeBreakdown(200000, platformFeePercentage: 5);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.description, contains('5%'));
      expect(
        getPlatformFeeBreakdown(50000, platformFeePercentage: 5).description,
        contains('5.000đ'),
      );
      expect(
        getPlatformFeeBreakdown(0, platformFeePercentage: 5).description,
        'Không tính phí sàn',
      );
    });
  });
}
