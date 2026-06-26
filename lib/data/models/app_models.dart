enum SportType { tennis, badminton, tableTennis, pickleball }

enum TournamentStatus { draft, active, ended }

enum MatchStatus { scheduled, live, completed }

enum MatchEventType { point, foul, yellowCard, redCard, injury, penalty }

enum UserRole { admin, referee, viewer }

class TournamentModel {
  final String id;
  final String name;
  final SportType sport;
  final TournamentStatus status;
  final int teamCount;
  final int maxTeams;
  final String location;
  final DateTime startDate;
  final DateTime endDate;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.sport,
    required this.status,
    required this.teamCount,
    required this.maxTeams,
    required this.location,
    required this.startDate,
    required this.endDate,
  });
}

class MatchModel {
  final String id;
  final String tournamentId;
  final String teamA;
  final String teamB;
  final int scoreA;
  final int scoreB;
  final List<String> setScores;
  final MatchStatus status;
  final String? court;
  final DateTime? scheduledTime;

  const MatchModel({
    required this.id,
    required this.tournamentId,
    required this.teamA,
    required this.teamB,
    this.scoreA = 0,
    this.scoreB = 0,
    this.setScores = const [],
    this.status = MatchStatus.scheduled,
    this.court,
    this.scheduledTime,
  });
}

class MatchEvent {
  final String id;
  final String matchId;
  final MatchEventType type;
  final int? teamIndex;
  final DateTime timestamp;
  final String note;

  const MatchEvent({
    required this.id,
    required this.matchId,
    required this.type,
    this.teamIndex,
    required this.timestamp,
    this.note = "",
  });
}

class TokenModel {
  final String token;
  final UserRole role;
  final String tournamentId;
  final DateTime expiresAt;

  const TokenModel({
    required this.token,
    required this.role,
    required this.tournamentId,
    required this.expiresAt,
  });
}
