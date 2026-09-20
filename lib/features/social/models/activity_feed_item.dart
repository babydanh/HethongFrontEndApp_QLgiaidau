import 'package:intl/intl.dart';

enum ActivityFeedType { clubRecruiting, tournamentOpened, personalPickup }

ActivityFeedType activityFeedTypeFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'TOURNAMENT_OPENED':
      return ActivityFeedType.tournamentOpened;
    case 'PERSONAL_PICKUP':
      return ActivityFeedType.personalPickup;
    default:
      return ActivityFeedType.clubRecruiting;
  }
}

class ActivityIdentity {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool verified;

  const ActivityIdentity({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.verified = false,
  });

  factory ActivityIdentity.fromJson(Object? value, {bool verified = false}) {
    final map = _asMap(value);
    return ActivityIdentity(
      id: _string(map['id']),
      name: _string(map['name'], fallback: 'Đang cập nhật'),
      avatarUrl: _nullableString(map['avatarUrl'] ?? map['logoUrl']),
      verified: map['verified'] is bool ? map['verified'] as bool : verified,
    );
  }
}

class ActivityJoinedPlayer {
  final String? userId;
  final String name;
  final String? avatarUrl;

  const ActivityJoinedPlayer({this.userId, required this.name, this.avatarUrl});

  factory ActivityJoinedPlayer.fromJson(Object? value) {
    final map = _asMap(value);
    return ActivityJoinedPlayer(
      userId: _nullableString(map['userId'] ?? map['id']),
      name: _string(map['name'], fallback: 'Người chơi'),
      avatarUrl: _nullableString(map['avatarUrl']),
    );
  }
}

class ActivitySlots {
  final int current;
  final int max;
  final int? feePerSlot;
  final List<ActivityJoinedPlayer> joinedPlayers;

  const ActivitySlots({
    required this.current,
    required this.max,
    this.feePerSlot,
    this.joinedPlayers = const [],
  });

  ActivitySlots copyWith({
    int? current,
    List<ActivityJoinedPlayer>? joinedPlayers,
  }) => ActivitySlots(
    current: current ?? this.current,
    max: max,
    feePerSlot: feePerSlot,
    joinedPlayers: joinedPlayers ?? this.joinedPlayers,
  );

  factory ActivitySlots.fromJson(Object? value) {
    final map = _asMap(value);
    final rawPlayers = map['joinedPlayers'];
    return ActivitySlots(
      current: _int(map['current']),
      max: _int(map['max']),
      feePerSlot: _nullableInt(map['feePerSlot']),
      joinedPlayers: rawPlayers is List
          ? rawPlayers
                .map(ActivityJoinedPlayer.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class ActivityTournamentInfo {
  final String id;
  final int remainingSlots;
  final int totalSlots;
  final String? bannerUrl;

  const ActivityTournamentInfo({
    required this.id,
    required this.remainingSlots,
    required this.totalSlots,
    this.bannerUrl,
  });

  factory ActivityTournamentInfo.fromJson(Object? value) {
    final map = _asMap(value);
    return ActivityTournamentInfo(
      id: _string(map['id']),
      remainingSlots: _int(map['remainingSlots']),
      totalSlots: _int(map['totalSlots']),
      bannerUrl: _nullableString(map['bannerUrl']),
    );
  }
}

class ActivityVenue {
  final String name;
  final String? address;
  final String? courtName;

  const ActivityVenue({required this.name, this.address, this.courtName});

  factory ActivityVenue.fromJson(Object? value) {
    final map = _asMap(value);
    return ActivityVenue(
      name: _string(map['name']),
      address: _nullableString(map['address']),
      courtName: _nullableString(map['courtName']),
    );
  }
}

class ActivityFeedItem {
  final String id;
  final ActivityFeedType type;
  final String? clubMatchSessionId;
  final String? tournamentId;
  final String sport;
  final String sportTier;
  final String playDate;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String location;
  final String title;
  final String description;
  final String? bannerUrl;
  final List<String> imageUrls;
  final ActivityIdentity? club;
  final ActivityIdentity? host;
  final ActivitySlots? slots;
  final ActivityTournamentInfo? tournament;
  final ActivityVenue? venue;
  final bool isJoined;

  const ActivityFeedItem({
    required this.id,
    required this.type,
    required this.sport,
    required this.sportTier,
    required this.playDate,
    required this.location,
    required this.title,
    required this.description,
    this.clubMatchSessionId,
    this.tournamentId,
    this.startDateTime,
    this.endDateTime,
    this.bannerUrl,
    this.imageUrls = const [],
    this.club,
    this.host,
    this.slots,
    this.tournament,
    this.venue,
    this.isJoined = false,
  });

  bool get isPersonal => type == ActivityFeedType.personalPickup;
  String get startTime => _formatTime(startDateTime);
  String get endTime => _formatTime(endDateTime);
  String get typeLabel => switch (type) {
    ActivityFeedType.personalPickup => 'GIAO LƯU CÁ NHÂN',
    ActivityFeedType.tournamentOpened => 'GIẢI ĐẤU ĐANG MỞ',
    ActivityFeedType.clubRecruiting => 'CLB ĐANG TUYỂN',
  };
  String get hostName => host?.name ?? club?.name ?? 'SportO';
  String get feeLabel => slots?.feePerSlot == null
      ? 'Theo thỏa thuận'
      : '${NumberFormat('#,###', 'vi_VN').format(slots!.feePerSlot)}đ/slot';

  ActivityFeedItem copyWith({bool? isJoined, ActivitySlots? slots}) =>
      ActivityFeedItem(
        id: id,
        type: type,
        clubMatchSessionId: clubMatchSessionId,
        tournamentId: tournamentId,
        sport: sport,
        sportTier: sportTier,
        playDate: playDate,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: location,
        title: title,
        description: description,
        bannerUrl: bannerUrl,
        imageUrls: imageUrls,
        club: club,
        host: host,
        slots: slots ?? this.slots,
        tournament: tournament,
        venue: venue,
        isJoined: isJoined ?? this.isJoined,
      );

  factory ActivityFeedItem.fromClubJson(Map<String, dynamic> json) {
    final community = _asMap(json['community']);
    final type = activityFeedTypeFromString(json['type']);
    final start = _dateWithDate(json['startTime'], json['playDate']);
    final end = _dateWithDate(json['endTime'], json['playDate']);
    final playDate = _dateKey(json['playDate'], start);
    final tournament = json['tournament'] == null
        ? null
        : ActivityTournamentInfo.fromJson(json['tournament']);
    return ActivityFeedItem(
      id: _string(json['id']),
      type: type,
      clubMatchSessionId: _nullableString(json['clubMatchSessionId']),
      tournamentId: _nullableString(json['tournamentId']) ?? tournament?.id,
      sport: _string(json['sport'], fallback: 'Thể thao'),
      sportTier: _string(json['sportTier'], fallback: 'Mọi trình độ'),
      playDate: playDate,
      startDateTime: start,
      endDateTime: end,
      location: _string(json['location'], fallback: 'Đang cập nhật địa điểm'),
      title: _string(json['title'], fallback: 'Hoạt động thể thao'),
      description: _cleanDescription(json['description']),
      bannerUrl: tournament?.bannerUrl,
      club: ActivityIdentity.fromJson(
        community,
        verified: json['verified'] == true,
      ),
      host: json['host'] == null
          ? null
          : ActivityIdentity.fromJson(json['host']),
      slots: json['slots'] == null
          ? null
          : ActivitySlots.fromJson(json['slots']),
      tournament: tournament,
      venue: json['venue'] == null
          ? null
          : ActivityVenue.fromJson(json['venue']),
    );
  }

  factory ActivityFeedItem.fromPersonalJson(Map<String, dynamic> json) {
    final start = _dateWithDate(json['startTime'], json['playDate']);
    final end = _dateWithDate(json['endTime'], json['playDate']);
    final host = ActivityIdentity.fromJson(json['personalHost']);
    final players = json['joinedPlayers'];
    final slots = ActivitySlots(
      current: _int(json['currentSlots']),
      max: _int(json['maxSlots']),
      feePerSlot: _nullableInt(json['feePerSlot']),
      joinedPlayers: players is List
          ? players.map(ActivityJoinedPlayer.fromJson).toList(growable: false)
          : const [],
    );
    return ActivityFeedItem(
      id: _string(json['id']),
      type: ActivityFeedType.personalPickup,
      sport: _string(json['sport'], fallback: 'Thể thao'),
      sportTier: _string(json['sportTier'], fallback: 'Mọi trình độ'),
      playDate: _dateKey(json['playDate'], start),
      startDateTime: start,
      endDateTime: end,
      location: _string(json['location'], fallback: 'Đang cập nhật địa điểm'),
      title: _string(json['title'], fallback: 'Giao lưu cá nhân'),
      description: _cleanDescription(json['description']),
      imageUrls: _strings(json['imageUrls']),
      host: host,
      slots: slots,
      isJoined: json['isJoined'] == true,
    );
  }
}

Map<String, dynamic> _asMap(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : const <String, dynamic>{};

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
int? _nullableInt(Object? value) =>
    value == null ? null : int.tryParse(value.toString());

List<String> _strings(Object? value) => value is List
    ? value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false)
    : const [];

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

DateTime? _dateWithDate(Object? rawTime, Object? rawDate) {
  final parsed = _date(rawTime);
  if (parsed != null) return parsed;
  final time = rawTime?.toString().trim() ?? '';
  final date = _date(rawDate);
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time);
  if (date == null || match == null) return null;
  return DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
}

String _dateKey(Object? raw, DateTime? fallback) {
  final value = raw?.toString() ?? '';
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return value;
  final date = fallback ?? DateTime.tryParse(value);
  if (date == null) return '';
  return DateFormat('yyyy-MM-dd').format(date.toLocal());
}

String _formatTime(DateTime? value) =>
    value == null ? '' : DateFormat('HH:mm').format(value.toLocal());

String _cleanDescription(Object? value) => (value?.toString() ?? '')
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
