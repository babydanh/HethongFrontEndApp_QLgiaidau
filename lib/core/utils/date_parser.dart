/// Mixin chứa các hàm parse DateTime dùng chung cho tất cả Data Models.
///
/// Mục đích: DRY — tránh lặp `_parseDate()` giống nhau trong mọi model.
///
/// Cách dùng:
/// ```dart
/// class Tournament with DateParser {
///   factory Tournament.fromJson(Map<String, dynamic> json, String id) {
///     return Tournament(
///       createdAt: DateParser.parseDate(json['createdAt']),
///       updatedAt: DateParser.parseDateOptional(json['updatedAt']),
///     );
///   }
/// }
/// ```
///
/// Lưu ý: Các hàm đều là static để có thể dùng trong factory constructor.
class DateParser {
  const DateParser._();

  /// Parse dynamic value thành DateTime.
  /// Hỗ trợ: DateTime, String (ISO 8601), int (milliseconds epoch).
  /// Fallback: DateTime.now()
  static DateTime parseDate(dynamic date) {
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
    return DateTime.now();
  }

  /// Parse dynamic value thành DateTime? (nullable).
  /// Trả về null nếu value là null hoặc không parse được.
  static DateTime? parseDateOptional(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date);
    if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
    return null;
  }
}
