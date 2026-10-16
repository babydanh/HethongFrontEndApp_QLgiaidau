class MatchStreamControlStateModel {
  const MatchStreamControlStateModel({
    required this.matchId,
    required this.hasCamera,
  });

  final String matchId;
  final bool hasCamera;

  factory MatchStreamControlStateModel.fromJson(Map<String, Object?> json) {
    final matchId = json['matchId'];
    final hasCamera = json['hasCamera'];
    if (matchId is! String || matchId.trim().isEmpty || hasCamera is! bool) {
      throw const FormatException('Invalid match control-state response.');
    }
    return MatchStreamControlStateModel(matchId: matchId, hasCamera: hasCamera);
  }
}

class MatchRecordingDaysModel {
  MatchRecordingDaysModel({required List<String> days})
    : days = List<String>.unmodifiable(days);

  final List<String> days;

  factory MatchRecordingDaysModel.fromJson(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Invalid recording-days response.');
    }

    final days = <String>[];
    final seen = <String>{};
    for (final day in value) {
      if (day is String && _isValidRecordingPeriod(day) && seen.add(day)) {
        days.add(day);
      }
    }
    return MatchRecordingDaysModel(days: days);
  }
}

class MatchRecordingFileModel {
  const MatchRecordingFileModel({required this.name, this.sizeBytes});

  final String name;
  final int? sizeBytes;

  factory MatchRecordingFileModel.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    if (name is! String || !_isSafeRecordingFileName(name)) {
      throw const FormatException('Invalid recording-file response.');
    }

    final size = json['sizeBytes'];
    final sizeBytes = size is int && size >= 0 && size <= 9007199254740991
        ? size
        : null;
    return MatchRecordingFileModel(name: name, sizeBytes: sizeBytes);
  }

  static List<MatchRecordingFileModel> listFromJson(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Invalid recording-files response.');
    }

    final files = <MatchRecordingFileModel>[];
    for (final row in value) {
      if (row is! Map<String, Object?>) continue;
      try {
        files.add(MatchRecordingFileModel.fromJson(row));
      } on FormatException {
        // Discard rows that do not meet the safe filename contract.
      }
    }
    return List<MatchRecordingFileModel>.unmodifiable(files);
  }
}

final _recordingPeriodPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final _unsafeRecordingFileNamePattern = RegExp(r'[<>:"|?*]');
const _recordingDaysInMonth = <int>[
  31,
  28,
  31,
  30,
  31,
  30,
  31,
  31,
  30,
  31,
  30,
  31,
];

bool _isValidRecordingPeriod(String value) {
  final match = _recordingPeriodPattern.firstMatch(value);
  if (match == null) return false;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (year < 1 || month < 1 || month > 12) return false;

  final leapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  final maxDay = month == 2 && leapYear ? 29 : _recordingDaysInMonth[month - 1];
  return day >= 1 && day <= maxDay;
}

bool _isSafeRecordingFileName(String value) {
  if (value.isEmpty || value == '.' || value == '..') return false;
  if (value.contains('/') || value.contains('\\')) return false;
  if (_unsafeRecordingFileNamePattern.hasMatch(value)) return false;
  if (!value.toLowerCase().endsWith('.mp4')) return false;
  for (final codeUnit in value.codeUnits) {
    if (codeUnit < 0x20 || codeUnit == 0x7f) return false;
  }
  return true;
}
