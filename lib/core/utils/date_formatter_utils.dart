import 'package:intl/intl.dart';

class DateFormatterUtils {
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatTimeWithSeconds(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatFileTime(DateTime date) {
    return DateFormat('yyyyMMdd').format(date);
  }
}
