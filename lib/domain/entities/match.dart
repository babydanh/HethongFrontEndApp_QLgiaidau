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
  final String? avatarUrl;

  const MatchMemberInfo({
    this.userId,
    required this.fullName,
    this.eloPoints,
    this.tierName,
    this.avatarUrl,
  });

  factory MatchMemberInfo.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final user = json['user'];
    return MatchMemberInfo(
      userId:
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          (user is Map ? user['id']?.toString() : null),
      fullName:
          json['fullName']?.toString() ??
          json['full_name']?.toString() ??
          (profile is Map ? profile['fullName']?.toString() : null) ??
          (user is Map ? user['fullName']?.toString() : null) ??
          json['name']?.toString() ??
          'Vận động viên',
      eloPoints: json['eloPoints'] is num
          ? (json['eloPoints'] as num).toInt()
          : int.tryParse(json['eloPoints']?.toString() ?? ''),
      tierName: json['tierName']?.toString() ?? json['tier_name']?.toString(),
      avatarUrl:
          json['avatarUrl']?.toString() ??
          json['avatar_url']?.toString() ??
          json['photoUrl']?.toString() ??
          json['photo_url']?.toString() ??
          (profile is Map ? profile['avatarUrl']?.toString() ?? profile['avatar_url']?.toString() : null) ??
          (user is Map ? user['avatarUrl']?.toString() ?? user['avatar_url']?.toString() : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      'fullName': fullName,
      if (eloPoints != null) 'eloPoints': eloPoints,
      if (tierName != null) 'tierName': tierName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
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
  final String courtAddress;
  final int? maxScore;
  final bool winByTwo;
  final List<MatchEvent> events;
  final DateTime? scheduledTime;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? timeLimitMinutes;
  final DateTime updatedAt;
  /// Monotonic version from backend (optimistic lock + realtime ordering, NOTE-7).
  final int? revision;
  final String? refereeName;
  final String? refereeId;
  final List<Penalty> penalties;
  final String? tournamentName;
  final String? sportKey;
  final Map<String, dynamic>? tournamentConfig;
  // Sport-specific fields — từ BE JSONB
  final Map<String, dynamic>? sportRules;
  final Map<String, dynamic>? scoreDetails;
  final int? setsToWin;
  final List<String>? team1Members;
  final List<String>? team2Members;
  final List<MatchMemberInfo> team1MemberInfos;
  final List<MatchMemberInfo> team2MemberInfos;
  /// Ranking value for the whole team. For doubles this is pairRanks.eloPoints.
  final int? team1EloPoints;
  final int? team2EloPoints;

  final String? groupName;
  final String? stageName;
  final String? stageType;

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
    this.revision,
    this.refereeName,
    this.refereeId,
    this.penalties = const [],
    this.tournamentName,
    this.sportKey,
    this.tournamentConfig,
    this.sportRules,
    this.scoreDetails,
    this.setsToWin,
    this.team1Members = const [],
    this.team2Members = const [],
    this.team1MemberInfos = const [],
    this.team2MemberInfos = const [],
    this.team1EloPoints,
    this.team2EloPoints,
    this.groupName,
    this.stageName,
    this.stageType,
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
          ? (participant['rosters'] ?? participant['members']) as List<dynamic>?
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
    int? participantElo(dynamic participant) {
      if (participant is! Map) return null;
      final value = participant['eloPoints'];
      return value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
    }

    final scoreDetails = json['scoreDetails'] is Map
        ? Map<String, dynamic>.from(json['scoreDetails'] as Map)
        : null;
    final rawPenalties = json['penalties'] is List
        ? json['penalties'] as List<dynamic>
        : scoreDetails?['penalties'] is List
        ? scoreDetails!['penalties'] as List<dynamic>
        : <dynamic>[];

    List<SetScore> parsedSets = [];
    if (json['sets'] is List && (json['sets'] as List).isNotEmpty) {
      parsedSets = (json['sets'] as List)
          .map((s) => SetScore.fromJson(s as Map<String, dynamic>))
          .toList();
    } else if (scoreDetails != null && scoreDetails['scores'] is List) {
      parsedSets = (scoreDetails['scores'] as List).map((s) {
        if (s is Map) {
          final t1 = s['team1Score'] ?? s['score1'] ?? 0;
          final t2 = s['team2Score'] ?? s['score2'] ?? 0;
          return SetScore(
            score1: t1 is num ? t1.toInt() : int.tryParse(t1.toString()) ?? 0,
            score2: t2 is num ? t2.toInt() : int.tryParse(t2.toString()) ?? 0,
          );
        }
        return const SetScore(score1: 0, score2: 0);
      }).toList();
    }

    return MatchModel(
      id: id,
      round: json['round'] ?? 1,
      matchNumber: json['matchNumber'] ?? 1,
      team1Id: json['team1Id']?.toString() ??
          json['participant1Id']?.toString() ??
          (json['participant1'] is Map ? json['participant1']['id']?.toString() : null) ??
          '',
      team2Id: json['team2Id']?.toString() ??
          json['participant2Id']?.toString() ??
          (json['participant2'] is Map ? json['participant2']['id']?.toString() : null) ??
          '',
      team1Name: json['team1Name'] ?? 'TBD',
      team2Name: json['team2Name'] ?? 'TBD',
      score1: json['score1'] ?? 0,
      score2: json['score2'] ?? 0,
      sets: parsedSets,
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
      revision: json['revision'] as int?,
      refereeId: json['refereeId']?.toString(),
      penalties: rawPenalties
          .whereType<Map>()
          .map((p) => Penalty.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      tournamentName: json['tournamentName'] ?? json['tournament']?['name'],
      sportKey:
          json['sport']?.toString() ?? json['tournament']?['sport']?.toString(),
      // Sport-specific: từ tournament sportRules hoặc matchConfig
      sportRules: json['tournament'] is Map
          ? (json['tournament'] as Map)['sportRules'] as Map<String, dynamic>?
          : json['sportRules'] as Map<String, dynamic>?,
      tournamentConfig: json['tournament'] is Map &&
              (json['tournament'] as Map)['tournamentConfig'] is Map
          ? Map<String, dynamic>.from(
              (json['tournament'] as Map)['tournamentConfig'] as Map,
            )
          : null,
      scoreDetails: scoreDetails,
      setsToWin: json['setsToWin'] as int?,
      team1Members: team1MemberInfos.map((m) => m.fullName).toList(),
      team2Members: team2MemberInfos.map((m) => m.fullName).toList(),
      team1MemberInfos: team1MemberInfos,
      team2MemberInfos: team2MemberInfos,
      team1EloPoints: participantElo(json['participant1']),
      team2EloPoints: participantElo(json['participant2']),
      groupName:
          json['groupName']?.toString() ??
          json['group_name']?.toString() ??
          (json['group'] is Map
              ? json['group']['name']?.toString()
              : json['group']?.toString()),
      stageName:
          json['stageName']?.toString() ??
          json['stage_name']?.toString() ??
          json['stage']?.toString() ??
          json['stageType']?.toString(),
      stageType:
          json['stageType']?.toString() ??
          json['stage_type']?.toString() ??
          (json['stage'] is Map ? json['stage']['type']?.toString() : null),
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
      if (revision != null) 'revision': revision,
      if (refereeName != null) 'refereeName': refereeName,
      if (refereeId != null) 'refereeId': refereeId,
      'penalties': penalties.map((p) => p.toJson()).toList(),
      if (tournamentName != null) 'tournamentName': tournamentName,
      if (sportKey != null) 'sport': sportKey,
      'team1Members': team1Members,
      'team2Members': team2Members,
      'team1MemberInfos': team1MemberInfos.map((m) => m.toJson()).toList(),
      'team2MemberInfos': team2MemberInfos.map((m) => m.toJson()).toList(),
      if (team1EloPoints != null) 'team1EloPoints': team1EloPoints,
      if (team2EloPoints != null) 'team2EloPoints': team2EloPoints,
      if (groupName != null) 'groupName': groupName,
      if (stageName != null) 'stageName': stageName,
      if (stageType != null) 'stageType': stageType,
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
    int? revision,
    String? refereeName,
    String? refereeId,
    List<Penalty>? penalties,
    String? tournamentName,
    String? sportKey,
    Map<String, dynamic>? tournamentConfig,
    Map<String, dynamic>? sportRules,
    Map<String, dynamic>? scoreDetails,
    int? setsToWin,
    List<String>? team1Members,
    List<String>? team2Members,
    List<MatchMemberInfo>? team1MemberInfos,
    List<MatchMemberInfo>? team2MemberInfos,
    int? team1EloPoints,
    int? team2EloPoints,
    String? groupName,
    String? stageName,
    String? stageType,
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
      revision: revision ?? this.revision,
      refereeName: refereeName ?? this.refereeName,
      refereeId: refereeId ?? this.refereeId,
      penalties: penalties ?? this.penalties,
      tournamentName: tournamentName ?? this.tournamentName,
      sportKey: sportKey ?? this.sportKey,
      tournamentConfig: tournamentConfig ?? this.tournamentConfig,
      sportRules: sportRules ?? this.sportRules,
      scoreDetails: scoreDetails ?? this.scoreDetails,
      setsToWin: setsToWin ?? this.setsToWin,
      team1Members: team1Members ?? this.team1Members,
      team2Members: team2Members ?? this.team2Members,
      team1MemberInfos: team1MemberInfos ?? this.team1MemberInfos,
      team2MemberInfos: team2MemberInfos ?? this.team2MemberInfos,
      team1EloPoints: team1EloPoints ?? this.team1EloPoints,
      team2EloPoints: team2EloPoints ?? this.team2EloPoints,
      groupName: groupName ?? this.groupName,
      stageName: stageName ?? this.stageName,
      stageType: stageType ?? this.stageType,
      isBye: isBye ?? this.isBye,
    );
  }

  String get normalizedStatus => status.trim().toUpperCase();

  // The API has historically returned both enum casing and legacy aliases.
  // Keep these predicates as the single source of truth for every surface.
  bool get isLive => const {
        'LIVE',
        'ONGOING',
        'IN_PROGRESS',
      }.contains(normalizedStatus);
  bool get isCompleted => const {
        'COMPLETED',
        'FINISHED',
        'DONE',
        'ENDED',
        'WALKOVER',
        'RETIRED',
        'DISQUALIFIED',
      }.contains(normalizedStatus) || completedAt != null;
  bool get isScheduled => const {
        'SCHEDULED',
        'PENDING',
        'NOT_STARTED',
      }.contains(normalizedStatus);
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
