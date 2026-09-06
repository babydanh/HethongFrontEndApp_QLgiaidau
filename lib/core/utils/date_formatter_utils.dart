import 'package:intl/intl.dart';

class DateFormatterUtils {
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time.toLocal());
  }

  static String formatTimeWithSeconds(DateTime time) {
    return DateFormat('HH:mm:ss').format(time.toLocal());
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  static String formatFileTime(DateTime date) {
    return DateFormat('yyyyMMdd').format(date.toLocal());
  }

  static String formatTournamentDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(dateStr.trim());
    if (parsed == null) return dateStr;
    final local = parsed.toLocal();
    if (local.hour == 0 && local.minute == 0) {
      return DateFormat('dd/MM/yyyy').format(local);
    }
    return DateFormat('HH:mm - dd/MM/yyyy').format(local);
  }

  static String formatTournamentDateRange(String? startStr, String? endStr, {String fallback = ''}) {
    final start = formatTournamentDate(startStr);
    final end = formatTournamentDate(endStr);
    if (start.isEmpty && end.isEmpty) return fallback;
    if (start.isNotEmpty && end.isNotEmpty && start != end) {
      return '$start - $end';
    }
    return start.isNotEmpty ? start : end;
  }
}
