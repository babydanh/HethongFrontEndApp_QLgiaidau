// Quản lý vòng (leg) của chuỗi giải và việc gắn/gỡ giải vào vòng, đối chiếu
// Backend `OrganizerSeriesController` (`/organizer/series/:id/legs...`) và
// các GET công khai `/series/:id/legs`, `/series/:id/legs/:legId/events`.

int _toInt(Object? value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

DateTime? _toDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

/// Một vòng của chuỗi (`series_legs`).
class SeriesLegRecord {
  const SeriesLegRecord({
    required this.id,
    required this.name,
    required this.order,
    this.startDate,
    this.endDate,
    this.status = 'UPCOMING',
    this.directEntrySlots = 2,
    this.wildcardSlots = 16,
  });

  factory SeriesLegRecord.fromJson(Map<String, dynamic> json) =>
      SeriesLegRecord(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        order: _toInt(json['order'], 1),
        startDate: _toDate(json['startDate']),
        endDate: _toDate(json['endDate']),
        status: json['status']?.toString() ?? 'UPCOMING',
        directEntrySlots: _toInt(json['directEntrySlots'], 2),
        wildcardSlots: _toInt(json['wildcardSlots'], 16),
      );

  final String id;
  final String name;
  final int order;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int directEntrySlots;
  final int wildcardSlots;
}

/// Một giải đã gắn vào vòng (`series_events` + tên giải).
class SeriesLegEvent {
  const SeriesLegEvent({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.order,
    this.region,
    this.pointMultiplier = 1,
  });

  /// Backend trả mỗi dòng là `{event, tournament}`; chấp nhận cả dạng phẳng.
  factory SeriesLegEvent.fromJson(Map<String, dynamic> json) {
    final event = json['event'] is Map<String, dynamic>
        ? json['event'] as Map<String, dynamic>
        : json;
    final tournament = json['tournament'] is Map<String, dynamic>
        ? json['tournament'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final multiplier = event['pointMultiplier'];
    return SeriesLegEvent(
      id: event['id']?.toString() ?? '',
      tournamentId: event['tournamentId']?.toString() ?? '',
      tournamentName: tournament['name']?.toString() ?? '',
      order: _toInt(event['order'], 1),
      region: event['region']?.toString(),
      pointMultiplier: multiplier is num ? multiplier.toDouble() : 1,
    );
  }

  final String id;
  final String tournamentId;
  final String tournamentName;
  final int order;
  final String? region;
  final double pointMultiplier;
}

/// Nội dung form thêm/sửa vòng (`CreateLegDto`).
class SeriesLegInput {
  const SeriesLegInput({
    required this.name,
    required this.order,
    this.startDate,
    this.endDate,
    this.directEntrySlots = 2,
    this.wildcardSlots = 16,
  });

  final String name;
  final int order;
  final DateTime? startDate;
  final DateTime? endDate;
  final int directEntrySlots;
  final int wildcardSlots;

  static String _iso(DateTime date) => date.toUtc().toIso8601String();

  /// Body `POST`: ngày trống thì bỏ khóa.
  Map<String, dynamic> toCreateJson() => <String, dynamic>{
    'name': name,
    'order': order,
    if (startDate != null) 'startDate': _iso(startDate!),
    if (endDate != null) 'endDate': _iso(endDate!),
    'directEntrySlots': directEntrySlots,
    'wildcardSlots': wildcardSlots,
  };

  /// Body `PATCH`: ngày trống gửi `null` để Backend xóa ngày cũ.
  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
    'name': name,
    'order': order,
    'startDate': startDate == null ? null : _iso(startDate!),
    'endDate': endDate == null ? null : _iso(endDate!),
    'directEntrySlots': directEntrySlots,
    'wildcardSlots': wildcardSlots,
  };
}

/// Nội dung gắn giải vào vòng (`LinkEventDto`).
class SeriesLinkInput {
  const SeriesLinkInput({
    required this.tournamentId,
    required this.order,
    this.region,
    this.pointMultiplier,
  });

  final String tournamentId;
  final int order;
  final String? region;
  final double? pointMultiplier;

  Map<String, dynamic> toJson() {
    final trimmedRegion = region?.trim() ?? '';
    return <String, dynamic>{
      'tournamentId': tournamentId,
      'order': order,
      if (trimmedRegion.isNotEmpty) 'region': trimmedRegion,
      if (pointMultiplier != null) 'pointMultiplier': pointMultiplier,
    };
  }
}

abstract class SeriesLegsRepository {
  Future<List<SeriesLegRecord>> getLegs(String seriesId);

  Future<List<SeriesLegEvent>> getLegEvents(String seriesId, String legId);

  Future<void> createLeg(String seriesId, SeriesLegInput input);

  Future<void> updateLeg(String seriesId, String legId, SeriesLegInput input);

  Future<void> deleteLeg(String seriesId, String legId);

  Future<void> linkTournament(
    String seriesId,
    String legId,
    SeriesLinkInput input,
  );

  Future<void> unlinkTournament(String seriesId, String legId, String eventId);
}
