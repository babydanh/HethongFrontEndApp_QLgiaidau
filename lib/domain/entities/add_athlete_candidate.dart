enum AddAthleteSource {
  friends('FRIENDS'),
  club('CLUB');

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
