import 'package:app_quanly_giaidau/core/utils/date_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/match_event.dart';
import 'package:app_quanly_giaidau/domain/entities/penalty.dart';

class SetScore {
  final int score1;
  final int score2;

  const SetScore({required this.score1, required this.score2});

  factory SetScore.fromJson(Map<String, dynamic> json) {
    return SetScore(
      score1: json['score1'] ?? 0,
      score2: json['score2'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'score1': score1, 'score2': score2};
  }
}

class BracketPosition {
  final String bracket;
  final int round;
  final int position;

  const BracketPosition({
    this.bracket = 'winners',
    required this.round,
    required this.position,
  });

  factory BracketPosition.fromJson(Map<String, dynamic> json) {
    return BracketPosition(
      bracket: json['bracket'] ?? 'winners',
      round: json['round'] ?? 1,
      position: json['position'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bracket': bracket,
      'round': round,
      'position': position,
    };
  }
}

class MatchModel {
  final String id;
  final int round;
  final int matchNumber;
  final String team1Id;
  final String team2Id;
  final String team1Name;
  final String team2Name;
  final int score1;
  final int score2;
  final List<SetScore> sets;
  final String winnerId;
  final String loserId;
  final String status;
  final BracketPosition bracketPosition;
  final String nextMatchId;
  final String loserNextMatchId;
  final String court;
  final int? maxScore;
  final bool winByTwo;
  final List<MatchEvent> events;
  final DateTime? scheduledTime;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? timeLimitMinutes;
  final DateTime updatedAt;
  final String? refereeName;
  final List<Penalty> penalties;
  final String? tournamentName;

  const MatchModel({
    required this.id,
    required this.round,
    required this.matchNumber,
    this.team1Id = '',
    this.team2Id = '',
    this.team1Name = 'TBD',
    this.team2Name = 'TBD',
    this.score1 = 0,
    this.score2 = 0,
    this.sets = const [],
    this.winnerId = '',
    this.loserId = '',
    this.status = 'scheduled',
    required this.bracketPosition,
    this.nextMatchId = '',
    this.loserNextMatchId = '',
    this.court = '',
    this.maxScore,
    this.winByTwo = true,
    this.events = const [],
    this.scheduledTime,
    this.startedAt,
    this.completedAt,
    this.timeLimitMinutes,
    required this.updatedAt,
    this.refereeName,
    this.penalties = const [],
    this.tournamentName,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json, String id) {
    return MatchModel(
      id: id,
      round: json['round'] ?? 1,
      matchNumber: json['matchNumber'] ?? 1,
      team1Id: json['team1Id'] ?? '',
      team2Id: json['team2Id'] ?? '',
      team1Name: json['team1Name'] ?? 'TBD',
      team2Name: json['team2Name'] ?? 'TBD',
      score1: json['score1'] ?? 0,
      score2: json['score2'] ?? 0,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((s) => SetScore.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      winnerId: json['winnerId'] ?? '',
      loserId: json['loserId'] ?? '',
      status: json['status'] ?? 'scheduled',
      bracketPosition: json['bracketPosition'] != null
          ? BracketPosition.fromJson(
              json['bracketPosition'] as Map<String, dynamic>,
            )
          : const BracketPosition(round: 1, position: 0),
      nextMatchId: json['nextMatchId'] ?? '',
      loserNextMatchId: json['loserNextMatchId'] ?? '',
      court: json['court'] ?? '',
      maxScore: json['maxScore'] as int?,
      winByTwo: json['winByTwo'] as bool? ?? true,
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      scheduledTime: DateParser.parseDateOptional(json['scheduledTime']),
      startedAt: DateParser.parseDateOptional(json['startedAt']),
      completedAt: DateParser.parseDateOptional(json['completedAt']),
      timeLimitMinutes: json['timeLimitMinutes'] as int?,
      updatedAt: DateParser.parseDate(json['updatedAt']),
      refereeName: json['refereeName'],
      penalties: (json['penalties'] as List<dynamic>?)
              ?.map((p) => Penalty.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      tournamentName: json['tournamentName'] ?? json['tournament']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'matchNumber': matchNumber,
      'team1Id': team1Id,
      'team2Id': team2Id,
      'team1Name': team1Name,
      'team2Name': team2Name,
      'score1': score1,
      'score2': score2,
      'sets': sets.map((s) => s.toJson()).toList(),
      'winnerId': winnerId,
      'loserId': loserId,
      'status': status,
      'bracketPosition': bracketPosition.toJson(),
      'nextMatchId': nextMatchId,
      'loserNextMatchId': loserNextMatchId,
      'court': court,
      'maxScore': maxScore,
      'winByTwo': winByTwo,
      'events': events.map((e) => e.toJson()).toList(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeLimitMinutes': timeLimitMinutes,
      'updatedAt': updatedAt.toIso8601String(),
      if (refereeName != null) 'refereeName': refereeName,
      'penalties': penalties.map((p) => p.toJson()).toList(),
      if (tournamentName != null) 'tournamentName': tournamentName,
    };
  }

  MatchModel copyWith({
    String? id,
    int? round,
    int? matchNumber,
    String? team1Id,
    String? team2Id,
    String? team1Name,
    String? team2Name,
    int? score1,
    int? score2,
    List<SetScore>? sets,
    String? winnerId,
    String? loserId,
    String? status,
    BracketPosition? bracketPosition,
    String? nextMatchId,
    String? loserNextMatchId,
    String? court,
    int? maxScore,
    bool? winByTwo,
    List<MatchEvent>? events,
    DateTime? scheduledTime,
    DateTime? startedAt,
    DateTime? completedAt,
    int? timeLimitMinutes,
    DateTime? updatedAt,
    String? refereeName,
    List<Penalty>? penalties,
    String? tournamentName,
  }) {
    return MatchModel(
      id: id ?? this.id,
      round: round ?? this.round,
      matchNumber: matchNumber ?? this.matchNumber,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      sets: sets ?? this.sets,
      winnerId: winnerId ?? this.winnerId,
      loserId: loserId ?? this.loserId,
      status: status ?? this.status,
      bracketPosition: bracketPosition ?? this.bracketPosition,
      nextMatchId: nextMatchId ?? this.nextMatchId,
      loserNextMatchId: loserNextMatchId ?? this.loserNextMatchId,
      court: court ?? this.court,
      maxScore: maxScore ?? this.maxScore,
      winByTwo: winByTwo ?? this.winByTwo,
      events: events ?? this.events,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      refereeName: refereeName ?? this.refereeName,
      penalties: penalties ?? this.penalties,
      tournamentName: tournamentName ?? this.tournamentName,
    );
  }

  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';
  bool get hasTeams => team1Id.isNotEmpty && team2Id.isNotEmpty;

  @override
  String toString() =>
      'MatchModel(id: $id, round: $round, $team1Name vs $team2Name, $score1-$score2)';
}
