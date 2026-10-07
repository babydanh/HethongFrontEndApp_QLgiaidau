class HomeFeaturedTournament {
  final String id;
  final String name;
  final String? bannerUrl;
  final String? sport;
  final String? registrationStatus;

  const HomeFeaturedTournament({
    required this.id,
    required this.name,
    this.bannerUrl,
    this.sport,
    this.registrationStatus,
  });

  factory HomeFeaturedTournament.fromJson(Map<String, dynamic> json) {
    return HomeFeaturedTournament(
      id: _requiredHomeString(json, 'id'),
      name: _requiredHomeString(json, 'name'),
      bannerUrl: _optionalHomeString(json['bannerUrl']),
      sport: _optionalHomeString(json['sport']),
      registrationStatus: _optionalHomeString(json['registrationStatus']),
    );
  }
}

class HomeTournamentFinals {
  final String id;
  final String name;
  final List<HomeFinalMatch> matches;

  const HomeTournamentFinals({
    required this.id,
    required this.name,
    required this.matches,
  });

  factory HomeTournamentFinals.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'];
    return HomeTournamentFinals(
      id: _requiredHomeString(json, 'id'),
      name: _requiredHomeString(json, 'name'),
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
  final int roundNumber;
  final String branch;
  final int? leg;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int team1Sets;
  final int team2Sets;
  final HomeFinalTeam team1;
  final HomeFinalTeam team2;

  const HomeFinalMatch({
    required this.id,
    this.divisionId,
    this.divisionName,
    required this.roundNumber,
    required this.branch,
    this.leg,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    required this.team1Sets,
    required this.team2Sets,
    required this.team1,
    required this.team2,
  });

  factory HomeFinalMatch.fromJson(Map<String, dynamic> json) {
    final score = _homeMap(json['score']);
    return HomeFinalMatch(
      id: _requiredHomeString(json, 'id'),
      divisionId: _optionalHomeString(json['divisionId']),
      divisionName: _optionalHomeString(json['divisionName']),
      roundNumber: _homeInt(json['roundNumber']),
      branch: _optionalHomeString(json['bracketBranch']) ?? '',
      leg: json['leg'] == null ? null : _homeInt(json['leg']),
      status: _requiredHomeString(json, 'status'),
      scheduledAt: _homeDate(json['scheduledAt']),
      startedAt: _homeDate(json['startedAt']),
      completedAt: _homeDate(json['completedAt']),
      team1Sets: _homeInt(score['team1']),
      team2Sets: _homeInt(score['team2']),
      team1: HomeFinalTeam.fromJson(_homeMap(json['team1'])),
      team2: HomeFinalTeam.fromJson(_homeMap(json['team2'])),
    );
  }
}

class HomeFinalTeam {
  final String id;
  final String name;
  final String? logoUrl;

  const HomeFinalTeam({required this.id, required this.name, this.logoUrl});

  factory HomeFinalTeam.fromJson(Map<String, dynamic> json) {
    return HomeFinalTeam(
      id: _requiredHomeString(json, 'id'),
      name: _requiredHomeString(json, 'name'),
      logoUrl: _optionalHomeString(json['logoUrl']),
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
