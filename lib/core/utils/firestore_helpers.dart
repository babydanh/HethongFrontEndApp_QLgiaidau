import 'package:cloud_firestore/cloud_firestore.dart';

/// Mixin chứa các helper chuyển đổi giữa Firestore types và Dart types.
///
/// Mục đích: DRY — tránh lặp code Timestamp ↔ DateTime trong mọi repository.
/// Tất cả Firebase repositories nên `with FirestoreHelpers`.
///
/// Lưu ý: Chỉ dùng trong data layer (repositories), KHÔNG dùng trong models
/// vì models phải độc lập khỏi Firebase.
mixin FirestoreHelpers {
  /// Chuyển dynamic value (Timestamp, String, int) thành DateTime.
  /// Fallback về DateTime.now() nếu không parse được.
  DateTime timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  /// Chuyển dynamic value thành DateTime? (nullable).
  /// Trả về null nếu value là null hoặc không parse được.
  DateTime? timestampToDateTimeOptional(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// Chuyển DateTime thành Timestamp cho Firestore.
  Timestamp dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  /// Chuyển các field DateTime trong Map data thành Timestamp.
  /// [fields] — danh sách tên field cần chuyển.
  /// [optionalFields] — danh sách tên field nullable cần chuyển.
  Map<String, dynamic> convertDateTimesToTimestamps(
    Map<String, dynamic> data, {
    List<String> fields = const [],
    List<String> optionalFields = const [],
  }) {
    final result = Map<String, dynamic>.from(data);

    for (final field in fields) {
      final value = result[field];
      if (value is DateTime) {
        result[field] = Timestamp.fromDate(value);
      } else if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          result[field] = Timestamp.fromDate(parsed);
        }
      }
    }

    for (final field in optionalFields) {
      final value = result[field];
      if (value == null) {
        result.remove(field);
        continue;
      }
      if (value is DateTime) {
        result[field] = Timestamp.fromDate(value);
      } else if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          result[field] = Timestamp.fromDate(parsed);
        }
      }
    }

    return result;
  }

  /// Chuyển các field Timestamp trong Firestore data thành DateTime.
  /// Dùng trước khi gọi Model.fromJson().
  Map<String, dynamic> convertTimestampsToDateTimes(
    Map<String, dynamic> data, {
    List<String> fields = const [],
    List<String> optionalFields = const [],
  }) {
    final result = Map<String, dynamic>.from(data);

    for (final field in fields) {
      if (result[field] is Timestamp) {
        result[field] = (result[field] as Timestamp).toDate();
      }
    }

    for (final field in optionalFields) {
      if (result[field] is Timestamp) {
        result[field] = (result[field] as Timestamp).toDate();
      }
    }

    return result;
  }
}
