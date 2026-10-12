class HomeFeaturedTournament {
  final String id;
  final String name;
  final String? bannerUrl;
  final String? sport;
  final String? status;
  final String? registrationStatus;

  const HomeFeaturedTournament({
    required this.id,
    required this.name,
    this.bannerUrl,
    this.sport,
    this.status,
    this.registrationStatus,
  });

  factory HomeFeaturedTournament.fromJson(Map<String, dynamic> json) {
    return HomeFeaturedTournament(
      id: _requiredHomeString(json, 'id'),
      name: _requiredHomeString(json, 'name'),
      bannerUrl: _optionalHomeString(json['bannerUrl']),
      sport: _optionalHomeString(json['sport']),
      status: _optionalHomeString(json['status']),
      registrationStatus: _optionalHomeString(json['registrationStatus']),
    );
  }
}

class HomeTournamentFinals {
  final String id;
  final String name;
  final String? logoUrl;
  final String? status;
  final List<HomeFinalMatch> matches;

  const HomeTournamentFinals({
    required this.id,
    required this.name,
    this.logoUrl,
    this.status,
    required this.matches,
  });

  factory HomeTournamentFinals.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'];
    return HomeTournamentFinals(
      id: _requiredHomeString(json, 'id'),
      name: _requiredHomeString(json, 'name'),
      logoUrl: _optionalHomeString(json['logoUrl']),
      status: _optionalHomeString(json['status']),
      matches: rawMatches is List
          ? rawMatches
                .whereType<Map>()
                .map(
                  (match) =>
                      HomeFinalMatch.fromJson(Map<String, dynamic>.from(match)),
                )
                .toList(growable: false)
          : const <HomeFinalMatch>[],
    );
  }
}

class HomeFinalMatch {
  final String id;
  final String? divisionId;
  final String? divisionName;
  final String? stageName;
  final int roundNumber;
  final int lastRoundNumber;
  final String branch;
  final int? leg;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<HomeSetScore> scoreSets;
  final HomeFinalTeam team1;
  final HomeFinalTeam team2;

  const HomeFinalMatch({
    required this.id,
    this.divisionId,
    this.divisionName,
    this.stageName,
    required this.roundNumber,
    required this.lastRoundNumber,
    required this.branch,
    this.leg,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    required this.scoreSets,
    required this.team1,
    required this.team2,
  });

  factory HomeFinalMatch.fromJson(Map<String, dynamic> json) {
    return HomeFinalMatch(
      id: _requiredHomeString(json, 'id'),
      divisionId: _optionalHomeString(json['divisionId']),
      divisionName: _optionalHomeString(json['divisionName']),
      stageName: _optionalHomeString(json['stageName']),
      roundNumber: _homeInt(json['roundNumber']),
      lastRoundNumber: _homeInt(json['lastRoundNumber']),
      branch: _optionalHomeString(json['bracketBranch']) ?? '',
      leg: json['leg'] == null ? null : _homeInt(json['leg']),
      status: _requiredHomeString(json, 'status'),
      scheduledAt: _homeDate(json['scheduledAt']),
      startedAt: _homeDate(json['startedAt']),
      completedAt: _homeDate(json['completedAt']),
      scoreSets: _homeList(
        json['scoreSets'],
      ).map(HomeSetScore.fromJson).toList(growable: false),
      team1: HomeFinalTeam.fromJson(_homeMap(json['team1'])),
      team2: HomeFinalTeam.fromJson(_homeMap(json['team2'])),
    );
  }
}

class HomeSetScore {
  final int team1;
  final int team2;

  const HomeSetScore({required this.team1, required this.team2});

  factory HomeSetScore.fromJson(Map<String, dynamic> json) => HomeSetScore(
    team1: _homeInt(json['team1']),
    team2: _homeInt(json['team2']),
  );
}

class HomeTeamMember {
  final String name;
  final String? avatarUrl;

  const HomeTeamMember({required this.name, this.avatarUrl});

  factory HomeTeamMember.fromJson(Map<String, dynamic> json) => HomeTeamMember(
    name: _requiredHomeString(json, 'name'),
    avatarUrl: _optionalHomeString(json['avatarUrl']),
  );
}

class HomeFinalTeam {
  final String id;
  final String name;
  final String? logoUrl;
  final List<HomeTeamMember> members;

  const HomeFinalTeam({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.members,
  });

  factory HomeFinalTeam.fromJson(Map<String, dynamic> json) {
    return HomeFinalTeam(
      id: _requiredHomeString(json, 'id'),
      name: _requiredHomeString(json, 'name'),
      logoUrl: _optionalHomeString(json['logoUrl']),
      members: _homeList(
        json['members'],
      ).map(HomeTeamMember.fromJson).toList(growable: false),
    );
  }
}

class HomeProjection {
  final List<HomeFeaturedTournament> featuredTournaments;
  final List<HomeTournamentFinals> tournaments;

  const HomeProjection({
    required this.featuredTournaments,
    required this.tournaments,
  });

  HomeProjection get completedOnly => HomeProjection(
    featuredTournaments: featuredTournaments
        .where((tournament) => tournament.status?.toUpperCase() == 'COMPLETED')
        .toList(growable: false),
    tournaments: tournaments
        .where((tournament) => tournament.status?.toUpperCase() == 'COMPLETED')
        .toList(growable: false),
  );

  factory HomeProjection.fromJson(Map<String, dynamic> json) {
    return HomeProjection(
      featuredTournaments: _homeList(
        json['featuredTournaments'],
      ).map(HomeFeaturedTournament.fromJson).toList(growable: false),
      tournaments: _homeList(
        json['tournaments'],
      ).map(HomeTournamentFinals.fromJson).toList(growable: false),
    );
  }
}

List<Map<String, dynamic>> _homeList(Object? value) => value is List
    ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const <Map<String, dynamic>>[];

Map<String, dynamic> _homeMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

String _requiredHomeString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Home projection field "$key" is missing.');
  }
  return value;
}

String? _optionalHomeString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value;
}

int _homeInt(Object? value) =>
    value is int ? value : int.tryParse('$value') ?? 0;

DateTime? _homeDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
