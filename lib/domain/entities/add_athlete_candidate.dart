enum AddAthleteSource {
  friends('FRIENDS'),
  club('CLUB'),
  email('EMAIL');

  const AddAthleteSource(this.apiValue);

  final String apiValue;
}

enum FootballRosterRole {
  main('MAIN'),
  reserve('RESERVE');

  const FootballRosterRole(this.apiValue);

  final String apiValue;
}

class AddAthleteCandidate {
  const AddAthleteCandidate({required this.userId, required this.fullName});

  final String userId;
  final String fullName;

  factory AddAthleteCandidate.fromJson(Map<String, dynamic> json) {
    final userId = json['userId']?.toString() ?? '';
    final fullName = json['fullName']?.toString() ?? '';
    if (userId.isEmpty || fullName.trim().isEmpty) {
      throw const FormatException('Candidate response is missing identity.');
    }
    return AddAthleteCandidate(userId: userId, fullName: fullName);
  }
}

class AddAthleteSearchCandidate extends AddAthleteCandidate {
  const AddAthleteSearchCandidate({
    required super.userId,
    required super.fullName,
    required this.email,
    required this.sources,
  });

  final String email;
  final List<AddAthleteSource> sources;

  factory AddAthleteSearchCandidate.fromJson(Map<String, dynamic> json) {
    final base = AddAthleteCandidate.fromJson(json);
    final sources = (json['sources'] as List? ?? const [])
        .map((item) => addAthleteSourceFromApi(item?.toString()))
        .whereType<AddAthleteSource>()
        .toList(growable: false);
    return AddAthleteSearchCandidate(
      userId: base.userId,
      fullName: base.fullName,
      email: json['email']?.toString() ?? '',
      sources: sources,
    );
  }
}

/// Một cặp (hoặc VĐV lẻ chờ đội bạn) trả về từ luồng thêm cặp đôi.
class AddedAthletePair {
  const AddedAthletePair({
    required this.participantId,
    required this.teamStatus,
    required this.userIds,
  });

  final String participantId;

  /// `COMPLETE` khi đủ hai người, `PENDING_PARTNER` khi còn chờ đội bạn.
  final String teamStatus;
  final List<String> userIds;

  bool get isPendingPartner => teamStatus == 'PENDING_PARTNER';

  factory AddedAthletePair.fromJson(Map<String, dynamic> json) {
    final participantId = json['participantId']?.toString() ?? '';
    if (participantId.isEmpty) {
      throw const FormatException('Pair response is missing participant id.');
    }
    return AddedAthletePair(
      participantId: participantId,
      teamStatus: json['teamStatus']?.toString() ?? '',
      userIds: (json['userIds'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

AddAthleteSource? addAthleteSourceFromApi(String? value) {
  for (final source in AddAthleteSource.values) {
    if (source.apiValue == value) return source;
  }
  return null;
}
