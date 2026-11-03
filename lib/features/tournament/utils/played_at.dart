/// Wall-clock moment an organiser reports for a match: `date` is YYYY-MM-DD,
/// `time` is HH:mm or null when not entered. Mirrors the Web `PlayedAt`.
typedef PlayedAt = ({String date, String? time});

final _inputPattern = RegExp(
  r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\s+(\d{1,2}):(\d{2}))?$',
);

String _two(int value) => value.toString().padLeft(2, '0');

String _isoDate(DateTime day) =>
    '${day.year}-${_two(day.month)}-${_two(day.day)}';

/// Parses "dd/mm/yyyy" or "dd/mm/yyyy HH:mm"; null when it is not a real date
/// and time.
PlayedAt? parsePlayedAt(String input) {
  final match = _inputPattern.firstMatch(input.trim());
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  final hourText = match.group(4);
  if (hourText == null) return (date: _isoDate(parsed), time: null);
  final hour = int.parse(hourText);
  final minute = int.parse(match.group(5)!);
  if (hour > 23 || minute > 59) return null;
  return (date: _isoDate(parsed), time: '${_two(hour)}:${_two(minute)}');
}

/// Text-field form of a stored value; empty when the date is unreadable.
String formatPlayedAt(PlayedAt value) {
  final parts = value.date.split('-');
  if (parts.length != 3) return '';
  final text = '${parts[2]}/${parts[1]}/${parts[0]}';
  return value.time == null ? text : '$text ${value.time}';
}

/// Initial value of the field: what the match stores, else today with no time
/// (an hour is never guessed).
PlayedAt seedPlayedAt({
  required String? playedDate,
  required String? playedTime,
  required DateTime today,
}) {
  if (playedDate != null && playedDate.isNotEmpty) {
    return (date: playedDate, time: playedTime);
  }
  return (date: _isoDate(today), time: null);
}
