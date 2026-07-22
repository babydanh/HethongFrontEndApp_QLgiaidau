import 'package:app_quanly_giaidau/core/utils/date_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/match_event.dart';
import 'package:app_quanly_giaidau/domain/entities/penalty.dart';

class SetScore {
  final int score1;
  final int score2;

  const SetScore({required this.score1, required this.score2});

  factory SetScore.fromJson(Map<String, dynamic> json) {
    return SetScore(score1: json['score1'] ?? 0, score2: json['score2'] ?? 0);
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
    return {'bracket': bracket, 'round': round, 'position': position};
  }
}

class MatchMemberInfo {
  final String? userId;
  final String fullName;
  final int? eloPoints;
  final String? tierName;

  const MatchMemberInfo({
    this.userId,
    required this.fullName,
    this.eloPoints,
    this.tierName,
  });

  factory MatchMemberInfo.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : null;
    final ranking = json['ranking'] is Map<String, dynamic>
        ? json['ranking'] as Map<String, dynamic>
        : null;
    final rank = json['rank'] is Map<String, dynamic>
        ? json['rank'] as Map<String, dynamic>
        : null;
    final tier = json['tier'] is Map<String, dynamic>
        ? json['tier'] as Map<String, dynamic>
        : null;

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final fullName =
        json['fullName']?.toString() ??
        json['name']?.toString() ??
        user?['fullName']?.toString() ??
        user?['name']?.toString() ??
        '';

    return MatchMemberInfo(
      userId:
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          user?['id']?.toString(),
      fullName: fullName,
      eloPoints: parseInt(
        json['eloPoints'] ??
            json['elo'] ??
            json['elo_points'] ??
            ranking?['eloPoints'] ??
            ranking?['elo'] ??
            rank?['eloPoints'],
      ),
      tierName:
          json['tierName']?.toString() ??
          ranking?['tierName']?.toString() ??
          rank?['tierName']?.toString() ??
          tier?['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (userId != null) 'userId': userId,
    'fullName': fullName,
    if (eloPoints != null) 'eloPoints': eloPoints,
    if (tierName != null) 'tierName': tierName,
  };
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
  final String courtAddress;
  final int? maxScore;
  final bool winByTwo;
  final List<MatchEvent> events;
  final DateTime? scheduledTime;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? timeLimitMinutes;
  final DateTime updatedAt;
  final String? refereeName;
  final String? refereeId;
  final List<Penalty> penalties;
  final String? tournamentName;
  final String? sportKey;
  // Sport-specific fields — từ BE JSONB
  final Map<String, dynamic>? sportRules;
  final Map<String, dynamic>? scoreDetails;
  final int? setsToWin;
  final List<String>? team1Members;
  final List<String>? team2Members;
  final List<MatchMemberInfo> team1MemberInfos;
  final List<MatchMemberInfo> team2MemberInfos;

  /// True nếu đây là trận BYE (miễn đấu) do backend đánh dấu
  final bool isBye;

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
    this.courtAddress = '',
    this.maxScore,
    this.winByTwo = true,
    this.events = const [],
    this.scheduledTime,
    this.startedAt,
    this.completedAt,
    this.timeLimitMinutes,
    required this.updatedAt,
    this.refereeName,
    this.refereeId,
    this.penalties = const [],
    this.tournamentName,
    this.sportKey,
    this.sportRules,
    this.scoreDetails,
    this.setsToWin,
    this.team1Members = const [],
    this.team2Members = const [],
    this.team1MemberInfos = const [],
    this.team2MemberInfos = const [],
    this.isBye = false,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json, String id) {
    List<MatchMemberInfo> parseMemberInfos(
      dynamic explicitMembers,
      dynamic participant,
    ) {
      final source = explicitMembers is List
          ? explicitMembers
          : participant is Map<String, dynamic>
          ? participant['rosters'] as List<dynamic>?
          : null;
      if (source == null) return const [];
      return source
          .map((entry) {
            if (entry is String) return MatchMemberInfo(fullName: entry);
            if (entry is Map<String, dynamic>) {
              return MatchMemberInfo.fromJson(entry);
            }
            if (entry is Map) {
              return MatchMemberInfo.fromJson(Map<String, dynamic>.from(entry));
            }
            return MatchMemberInfo(fullName: entry.toString());
          })
          .where((member) => member.fullName.trim().isNotEmpty)
          .toList();
    }

    final team1MemberInfos = parseMemberInfos(
      json['team1MemberInfos'] ?? json['team1Members'],
      json['participant1'],
    );
    final team2MemberInfos = parseMemberInfos(
      json['team2MemberInfos'] ?? json['team2Members'],
      json['participant2'],
    );

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
      sets:
          (json['sets'] as List<dynamic>?)
              ?.map((s) => SetScore.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      winnerId: json['winnerId'] ?? '',
      loserId: json['loserId'] ?? '',
      status: (json['status'] as String?)?.toLowerCase() ?? 'scheduled',
      bracketPosition: json['bracketPosition'] != null
          ? BracketPosition.fromJson(
              json['bracketPosition'] as Map<String, dynamic>,
            )
          : const BracketPosition(round: 1, position: 0),
      nextMatchId: json['nextMatchId'] ?? '',
      loserNextMatchId: json['loserNextMatchId'] ?? '',
      court: json['court']?.toString() ?? json['courtName']?.toString() ?? '',
      courtAddress:
          json['courtAddress']?.toString() ??
          json['court_address']?.toString() ??
          '',
      maxScore: json['maxScore'] as int?,
      winByTwo: json['winByTwo'] as bool? ?? true,
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      scheduledTime: DateParser.parseDateOptional(json['scheduledTime']),
      startedAt: DateParser.parseDateOptional(json['startedAt']),
      completedAt: DateParser.parseDateOptional(json['completedAt']),
      timeLimitMinutes: json['timeLimitMinutes'] as int?,
      updatedAt: DateParser.parseDate(json['updatedAt']),
      refereeName: json['refereeName'],
      refereeId: json['refereeId']?.toString(),
      penalties:
          (json['penalties'] as List<dynamic>?)
              ?.map((p) => Penalty.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      tournamentName: json['tournamentName'] ?? json['tournament']?['name'],
      sportKey:
          json['sport']?.toString() ?? json['tournament']?['sport']?.toString(),
      // Sport-specific: từ tournament sportRules hoặc matchConfig
      sportRules: json['tournament'] is Map
          ? (json['tournament'] as Map)['sportRules'] as Map<String, dynamic>?
          : json['sportRules'] as Map<String, dynamic>?,
      scoreDetails: json['scoreDetails'] as Map<String, dynamic>?,
      setsToWin: json['setsToWin'] as int?,
      team1Members: team1MemberInfos.map((m) => m.fullName).toList(),
      team2Members: team2MemberInfos.map((m) => m.fullName).toList(),
      team1MemberInfos: team1MemberInfos,
      team2MemberInfos: team2MemberInfos,
      isBye: json['isBye'] ?? json['is_bye'] ?? false,
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
      if (courtAddress.isNotEmpty) 'courtAddress': courtAddress,
      'maxScore': maxScore,
      'winByTwo': winByTwo,
      'events': events.map((e) => e.toJson()).toList(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeLimitMinutes': timeLimitMinutes,
      'updatedAt': updatedAt.toIso8601String(),
      if (refereeName != null) 'refereeName': refereeName,
      if (refereeId != null) 'refereeId': refereeId,
      'penalties': penalties.map((p) => p.toJson()).toList(),
      if (tournamentName != null) 'tournamentName': tournamentName,
      if (sportKey != null) 'sport': sportKey,
      'team1Members': team1Members,
      'team2Members': team2Members,
      'team1MemberInfos': team1MemberInfos.map((m) => m.toJson()).toList(),
      'team2MemberInfos': team2MemberInfos.map((m) => m.toJson()).toList(),
      'isBye': isBye,
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
    String? courtAddress,
    int? maxScore,
    bool? winByTwo,
    List<MatchEvent>? events,
    DateTime? scheduledTime,
    DateTime? startedAt,
    DateTime? completedAt,
    int? timeLimitMinutes,
    DateTime? updatedAt,
    String? refereeName,
    String? refereeId,
    List<Penalty>? penalties,
    String? tournamentName,
    String? sportKey,
    Map<String, dynamic>? sportRules,
    Map<String, dynamic>? scoreDetails,
    int? setsToWin,
    List<String>? team1Members,
    List<String>? team2Members,
    List<MatchMemberInfo>? team1MemberInfos,
    List<MatchMemberInfo>? team2MemberInfos,
    bool? isBye,
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
      courtAddress: courtAddress ?? this.courtAddress,
      maxScore: maxScore ?? this.maxScore,
      winByTwo: winByTwo ?? this.winByTwo,
      events: events ?? this.events,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      refereeName: refereeName ?? this.refereeName,
      refereeId: refereeId ?? this.refereeId,
      penalties: penalties ?? this.penalties,
      tournamentName: tournamentName ?? this.tournamentName,
      sportKey: sportKey ?? this.sportKey,
      sportRules: sportRules ?? this.sportRules,
      scoreDetails: scoreDetails ?? this.scoreDetails,
      setsToWin: setsToWin ?? this.setsToWin,
      team1Members: team1Members ?? this.team1Members,
      team2Members: team2Members ?? this.team2Members,
      team1MemberInfos: team1MemberInfos ?? this.team1MemberInfos,
      team2MemberInfos: team2MemberInfos ?? this.team2MemberInfos,
      isBye: isBye ?? this.isBye,
    );
  }

  bool get isLive =>
      status == 'live' || status == 'ongoing' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';
  bool get isWalkover => status == 'walkover';
  bool get hasTeams => team1Id.isNotEmpty && team2Id.isNotEmpty;
  bool get isByeMatch =>
      (isBye == true) ||
      team1Name == 'BYE' ||
      team2Name == 'BYE' ||
      team1Id == 'BYE' ||
      team2Id == 'BYE';
  bool get isFullByeMatch =>
      (isBye == true) &&
      (team1Id.isEmpty || team1Name == 'BYE') &&
      (team2Id.isEmpty || team2Name == 'BYE');

  @override
  String toString() =>
      'MatchModel(id: $id, round: $round, $team1Name vs $team2Name, $score1-$score2)';
}
