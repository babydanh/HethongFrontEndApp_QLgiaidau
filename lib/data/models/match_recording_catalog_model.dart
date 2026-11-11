/// Trạng thái phát của trận. `ENDED` cũ quy về [idle] như Web; giá trị lạ là null.
enum MatchStreamStatus {
  idle,
  live,
  offline,
  error;

  static MatchStreamStatus? parse(Object? value) => switch (value) {
    'IDLE' || 'ENDED' => idle,
    'LIVE' => live,
    'OFFLINE' => offline,
    'ERROR' => error,
    _ => null,
  };
}

/// Trạng thái ghi MP4, độc lập với trạng thái phát.
enum MatchRecordingStatus {
  recording,
  stopped,
  pending;

  static MatchRecordingStatus? parse(Object? value) => switch (value) {
    'RECORDING' => recording,
    'STOPPED' => stopped,
    'PENDING' => pending,
    _ => null,
  };
}

class MatchStreamControlStateModel {
  const MatchStreamControlStateModel({
    required this.matchId,
    required this.hasCamera,
    this.hasRecording = false,
    this.streamStatus,
  });

  final String matchId;
  final bool hasCamera;

  /// True when the match was streamed and its recordings are still readable,
  /// independent of the camera currently assigned. Missing = false (old API).
  final bool hasRecording;

  /// Null khi không có camera hoặc server trả trạng thái lạ.
  final MatchStreamStatus? streamStatus;

  /// Có camera mà trạng thái không nhận ra thì không đoán nút "Bắt đầu".
  bool get canToggleStream => hasCamera && streamStatus != null;

  factory MatchStreamControlStateModel.fromJson(Map<String, Object?> json) {
    final matchId = json['matchId'];
    final hasCamera = json['hasCamera'];
    if (matchId is! String || matchId.trim().isEmpty || hasCamera is! bool) {
      throw const FormatException('Invalid match control-state response.');
    }
    return MatchStreamControlStateModel(
      matchId: matchId,
      hasCamera: hasCamera,
      hasRecording: json['hasRecording'] == true,
      streamStatus: hasCamera
          ? MatchStreamStatus.parse(json['streamStatus'])
          : null,
    );
  }
}

/// Kết quả `POST /livestream/matches/{id}/start|stop`.
class MatchStreamCommandResult {
  const MatchStreamCommandResult({
    this.streamStatus,
    this.recordingStatus,
    this.publishUrl,
  });

  final MatchStreamStatus? streamStatus;
  final MatchRecordingStatus? recordingStatus;

  /// Chỉ có khi start trả `publish` (camera PUSH); PULL thì null.
  final String? publishUrl;

  /// start: `{livestream{streamStatus}, publish, recordingStatus}`.
  factory MatchStreamCommandResult.fromStartJson(Map<String, Object?> json) {
    final livestream = json['livestream'];
    final publish = json['publish'];
    final url = publish is Map ? publish['url'] : null;
    return MatchStreamCommandResult(
      streamStatus: MatchStreamStatus.parse(
        livestream is Map ? livestream['streamStatus'] : null,
      ),
      recordingStatus: MatchRecordingStatus.parse(json['recordingStatus']),
      publishUrl: url is String && url.trim().isNotEmpty ? url : null,
    );
  }

  /// stop: bản ghi livestream phẳng kèm `recordingStatus`.
  factory MatchStreamCommandResult.fromStopJson(Map<String, Object?> json) {
    return MatchStreamCommandResult(
      streamStatus: MatchStreamStatus.parse(json['streamStatus']),
      recordingStatus: MatchRecordingStatus.parse(json['recordingStatus']),
    );
  }
}

/// Một dòng của `GET /livestream/tournaments/{id}/matches`.
class MatchLivestreamSummary {
  const MatchLivestreamSummary({
    required this.matchId,
    this.cameraId,
    this.streamStatus,
    this.hasRecording = false,
  });

  final String matchId;
  final String? cameraId;
  final MatchStreamStatus? streamStatus;
  final bool hasRecording;

  /// Trận được gán camera riêng (như Web: `match.cameraId`).
  bool get hasCamera => cameraId != null;
  bool get isLive => streamStatus == MatchStreamStatus.live;

  static MatchLivestreamSummary? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final matchId = value['matchId'];
    if (matchId is! String || matchId.trim().isEmpty) return null;
    final cameraId = value['cameraId'];
    return MatchLivestreamSummary(
      matchId: matchId,
      cameraId: cameraId is String && cameraId.isNotEmpty ? cameraId : null,
      streamStatus: MatchStreamStatus.parse(value['streamStatus']),
      hasRecording: value['hasRecording'] == true,
    );
  }

  static List<MatchLivestreamSummary> listFromJson(Object? value) {
    if (value is! List) {
      throw const FormatException('Invalid match-livestreams response.');
    }
    return List<MatchLivestreamSummary>.unmodifiable([
      for (final row in value) ?tryFromJson(row),
    ]);
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

/// Kết quả `GET /livestream/matches/{matchId}/recordings/playlist?period=`.
///
/// [segments] đã lọc: chỉ giữ đoạn có URL https tuyệt đối và tên tệp thuần,
/// giữ đúng thứ tự server trả về.
class MatchRecordingPlaylist {
  MatchRecordingPlaylist({
    required this.period,
    required List<MatchRecordingSegment> segments,
  }) : segments = List<MatchRecordingSegment>.unmodifiable(segments);

  final String period;
  final List<MatchRecordingSegment> segments;

  factory MatchRecordingPlaylist.fromJson(
    Object? value, {
    required String period,
  }) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Invalid recording-playlist response.');
    }
    final rows = value['segments'];
    if (rows is! List<dynamic>) {
      throw const FormatException('Invalid recording-playlist segments.');
    }

    final segments = <MatchRecordingSegment>[];
    for (final row in rows) {
      if (row is! Map<String, Object?>) continue;
      final segment = MatchRecordingSegment.tryFromJson(row);
      if (segment != null) segments.add(segment);
    }
    return MatchRecordingPlaylist(period: period, segments: segments);
  }
}

/// Một đoạn MP4 trong danh sách phát lại. [startAt] null khi server không có giờ.
class MatchRecordingSegment {
  const MatchRecordingSegment({
    required this.name,
    required this.startAt,
    required this.url,
  });

  final String name;
  final DateTime? startAt;
  final Uri url;

  /// Trả null nếu đoạn không an toàn: URL không phải https tuyệt đối, hoặc tên
  /// tệp có `/`, `\`, `..` hay ký tự điều khiển.
  static MatchRecordingSegment? tryFromJson(Map<String, Object?> json) {
    final name = json['name'];
    if (name is! String || !_isSafeRecordingFileName(name)) return null;

    final rawUrl = json['url'];
    if (rawUrl is! String) return null;
    final url = Uri.tryParse(rawUrl.trim());
    if (url == null ||
        !url.isAbsolute ||
        url.scheme != 'https' ||
        url.host.isEmpty) {
      return null;
    }

    final rawStart = json['startAt'];
    final startAt = rawStart is String ? DateTime.tryParse(rawStart) : null;
    return MatchRecordingSegment(name: name, startAt: startAt, url: url);
  }
}
