/// Port 1-1 từ Web `src/utils/platform-fee.ts` (hàm `getPlatformFeeBreakdown`).
///
/// Luật phí nền tảng tính trên mỗi VĐV:
/// - Lệ phí bằng 0 hoặc tỷ lệ phần trăm không hợp lệ (<= 0) -> không phí (FREE).
/// - Lệ phí >= ngưỡng (mặc định 100.000đ) -> phí = làm tròn(lệ phí x phần trăm / 100).
/// - Lệ phí > 0 nhưng dưới ngưỡng -> phí cố định (mặc định 5.000đ).
library;

import 'dart:math' as math;

/// Ngưỡng lệ phí chuyển sang tính phí theo phần trăm (mặc định của Web).
const int kDefaultPlatformFeeThresholdAmount = 100000;

/// Phí cố định khi lệ phí dưới ngưỡng (mặc định của Web).
const int kDefaultPlatformFeeFixedAmount = 5000;

/// Loại luật phí đang áp dụng, tương ứng 'FREE' | 'PERCENTAGE' | 'FIXED' bên Web.
enum PlatformFeeRuleType { free, percentage, fixed }

/// Kết quả phân tích phí sàn cho một mức lệ phí.
class PlatformFeeBreakdown {
  const PlatformFeeBreakdown({
    required this.entryFee,
    required this.feePerPlayer,
    required this.percentage,
    required this.ruleType,
    required this.thresholdAmount,
    required this.fixedAmount,
  });

  /// Lệ phí gốc / VĐV (đã chuẩn hoá; 0 khi đầu vào không hợp lệ).
  final num entryFee;

  /// Phí sàn thu trên mỗi VĐV.
  final int feePerPlayer;

  /// Tỷ lệ phần trăm phí sàn đã chuẩn hoá (0 khi không áp dụng).
  final double percentage;

  /// Loại luật đang áp dụng cho mức lệ phí này.
  final PlatformFeeRuleType ruleType;

  /// Ngưỡng lệ phí chuyển sang tính theo phần trăm.
  final int thresholdAmount;

  /// Phí cố định khi lệ phí dưới ngưỡng.
  final int fixedAmount;

  /// Phần BTC thực nhận / VĐV sau khi trừ phí sàn (không âm, như Web:
  /// `Math.max(0, entryFee - feePerPlayer)`).
  num get organizerNet => math.max(0, entryFee - feePerPlayer);

  /// Mô tả ngắn bằng tiếng Việt về luật phí đang áp dụng.
  String get description => switch (ruleType) {
    PlatformFeeRuleType.free => 'Không tính phí sàn',
    PlatformFeeRuleType.percentage =>
      'Phí sàn ${_trimDecimal(percentage)}% lệ phí '
          '(lệ phí từ ${_formatVnd(thresholdAmount)})',
    PlatformFeeRuleType.fixed =>
      'Phí sàn cố định ${_formatVnd(fixedAmount)} '
          'khi lệ phí dưới ${_formatVnd(thresholdAmount)}',
  };

  @override
  bool operator ==(Object other) =>
      other is PlatformFeeBreakdown &&
      other.entryFee == entryFee &&
      other.feePerPlayer == feePerPlayer &&
      other.percentage == percentage &&
      other.ruleType == ruleType &&
      other.thresholdAmount == thresholdAmount &&
      other.fixedAmount == fixedAmount;

  @override
  int get hashCode => Object.hash(
    entryFee,
    feePerPlayer,
    percentage,
    ruleType,
    thresholdAmount,
    fixedAmount,
  );
}

/// Chuẩn hoá giá trị về số như `Number(value ?? fallback)` của Web:
/// null -> fallback; số/chuỗi -> parse; không parse được -> null.
double? _parseNum(Object? value, {double? fallback}) {
  if (value == null) return fallback;
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value.toString().trim());
  return parsed;
}

/// Port `normalizeNonNegativeInteger`: giữ nguyên số nguyên >= 0, còn lại
/// (null, không parse được, âm, thập phân) trả về fallback.
int _normalizeNonNegativeInteger(Object? value, int fallback) {
  final parsed = _parseNum(value, fallback: fallback.toDouble());
  if (parsed == null || !parsed.isFinite || parsed < 0) return fallback;
  final truncated = parsed.truncateToDouble();
  // Web dùng Number.isSafeInteger (đến 2^53-1); mức phí thực tế luôn nhỏ hơn
  // nhiều nên chỉ cần kiểm tra là số nguyên.
  if (truncated != parsed) return fallback;
  return truncated.toInt();
}

/// Port `Number(entryFee || 0)`: NaN/rỗng/0 -> 0, giữ nguyên các giá trị khác.
/// Bổ sung guard: giá trị không hữu hạn (vô cùng) trả 0 vì Dart `.round()`
/// sẽ ném ngoại lệ trên số vô cùng (JS `Math.round` thì không).
num _normalizeEntryFee(Object? value) {
  if (value == null) return 0;
  final parsed = _parseNum(value);
  if (parsed == null || !parsed.isFinite || parsed == 0) return 0;
  return parsed;
}

/// Port phần chuẩn hoá tỷ lệ: null -> 0; không hợp lệ hoặc <= 0 -> 0.
double _normalizePercentage(Object? value) {
  final parsed = _parseNum(value);
  if (parsed == null || !parsed.isFinite || parsed <= 0) return 0;
  return parsed;
}

/// Port `getPlatformFeeBreakdown` của Web. Web gom ngưỡng và phí cố định vào
/// `PlatformFeeRuleInput`; Dart trải thành tham số đặt tên tương ứng.
PlatformFeeBreakdown getPlatformFeeBreakdown(
  Object? entryFee, {
  Object? platformFeePercentage,
  Object? thresholdAmount,
  Object? fixedAmount,
}) {
  final normalizedEntryFee = _normalizeEntryFee(entryFee);
  final normalizedPercentage = _normalizePercentage(platformFeePercentage);
  final normalizedThresholdAmount = _normalizeNonNegativeInteger(
    thresholdAmount,
    kDefaultPlatformFeeThresholdAmount,
  );
  final normalizedFixedAmount = _normalizeNonNegativeInteger(
    fixedAmount,
    kDefaultPlatformFeeFixedAmount,
  );

  if (normalizedPercentage == 0 || normalizedEntryFee == 0) {
    return PlatformFeeBreakdown(
      entryFee: normalizedEntryFee,
      feePerPlayer: 0,
      percentage: normalizedPercentage,
      ruleType: PlatformFeeRuleType.free,
      thresholdAmount: normalizedThresholdAmount,
      fixedAmount: normalizedFixedAmount,
    );
  }

  if (normalizedEntryFee >= normalizedThresholdAmount) {
    return PlatformFeeBreakdown(
      entryFee: normalizedEntryFee,
      feePerPlayer: (normalizedEntryFee * (normalizedPercentage / 100))
          .round()
          .toInt(),
      percentage: normalizedPercentage,
      ruleType: PlatformFeeRuleType.percentage,
      thresholdAmount: normalizedThresholdAmount,
      fixedAmount: normalizedFixedAmount,
    );
  }

  return PlatformFeeBreakdown(
    entryFee: normalizedEntryFee,
    feePerPlayer: normalizedFixedAmount,
    percentage: normalizedPercentage,
    ruleType: PlatformFeeRuleType.fixed,
    thresholdAmount: normalizedThresholdAmount,
    fixedAmount: normalizedFixedAmount,
  );
}

/// Bỏ đuôi ".0" khi hiển thị số phần trăm nguyên (5.0 -> "5").
String _trimDecimal(num value) => value == value.truncateToDouble()
    ? value.truncate().toString()
    : value.toString();

/// Định dạng tiền tệ kiểu Việt Nam (100000 -> "100.000đ") dùng cho mô tả.
String _formatVnd(num value) =>
    '${value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
