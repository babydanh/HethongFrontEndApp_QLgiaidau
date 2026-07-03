import 'package:app_quanly_giaidau/core/utils/date_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

class TournamentRefereeInvite {
  final String refereeId;
  final String tournamentId;
  final String tournamentName;
  final String tournamentStatus;
  final String categoryName;
  final DateTime? assignedAt;
  final String status;

  const TournamentRefereeInvite({
    required this.refereeId,
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentStatus,
    required this.categoryName,
    required this.assignedAt,
    required this.status,
  });

  factory TournamentRefereeInvite.fromJson(Map<String, dynamic> json) {
    return TournamentRefereeInvite(
      refereeId: json['refereeId']?.toString() ?? '',
      tournamentId: json['tournamentId']?.toString() ?? '',
      tournamentName: json['tournamentName']?.toString() ?? 'Giải đấu',
      tournamentStatus: json['tournamentStatus']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      assignedAt: DateParser.parseDateOptional(json['assignedAt']),
      status: json['status']?.toString() ?? 'INVITED',
    );
  }

  bool get isPending => status.toUpperCase() == 'INVITED';
}

class TournamentAssignedMatch {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final String categoryName;
  final String stageName;
  final String groupName;
  final int roundNumber;
  final int matchOrder;
  final String status;
  final DateTime? scheduledAt;
  final String courtName;
  final String? participant1Name;
  final String? participant2Name;

  const TournamentAssignedMatch({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.categoryName,
    required this.stageName,
    required this.groupName,
    required this.roundNumber,
    required this.matchOrder,
    required this.status,
    required this.scheduledAt,
    required this.courtName,
    required this.participant1Name,
    required this.participant2Name,
  });

  factory TournamentAssignedMatch.fromJson(Map<String, dynamic> json) {
    return TournamentAssignedMatch(
      id: json['id']?.toString() ?? '',
      tournamentId: json['tournamentId']?.toString() ?? '',
      tournamentName: json['tournamentName']?.toString() ?? 'Giải đấu',
      categoryName: json['categoryName']?.toString() ?? '',
      stageName: json['stageName']?.toString() ?? '',
      groupName: json['groupName']?.toString() ?? '',
      roundNumber: _toInt(json['roundNumber']) ?? 1,
      matchOrder: _toInt(json['matchOrder']) ?? 1,
      status: json['status']?.toString() ?? 'SCHEDULED',
      scheduledAt: DateParser.parseDateOptional(json['scheduledAt']),
      courtName: json['courtName']?.toString() ?? '',
      participant1Name: json['participant1Name']?.toString(),
      participant2Name: json['participant2Name']?.toString(),
    );
  }

  String get matchLabel => 'Trận $matchOrder';

  String get participantLabel {
    final player1 = participant1Name?.trim();
    final player2 = participant2Name?.trim();
    if ((player1 == null || player1.isEmpty) && (player2 == null || player2.isEmpty)) {
      return 'Chờ xác định cặp đấu';
    }
    return '${player1?.isNotEmpty == true ? player1 : 'Chờ đội 1'} vs ${player2?.isNotEmpty == true ? player2 : 'Chờ đội 2'}';
  }
}

class TournamentWorkspace {
  final List<Tournament> organizedTournaments;
  final List<Tournament> participatingTournaments;
  final List<Tournament> coOrganizerTournaments;
  final List<TournamentRefereeInvite> refereeInvites;
  final List<TournamentRefereeInvite> refereeTournaments;
  final List<TournamentAssignedMatch> refereeMatches;

  const TournamentWorkspace({
    this.organizedTournaments = const [],
    this.participatingTournaments = const [],
    this.coOrganizerTournaments = const [],
    this.refereeInvites = const [],
    this.refereeTournaments = const [],
    this.refereeMatches = const [],
  });

  factory TournamentWorkspace.fromJson(Map<String, dynamic> json) {
    List<Tournament> parseTournaments(String key) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((item) => Tournament.fromJson(item, item['id']?.toString() ?? ''))
          .where((item) => item.id.isNotEmpty)
          .toList();
    }

    List<TournamentRefereeInvite> parseInvites(String key) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(TournamentRefereeInvite.fromJson)
          .toList();
    }

    List<TournamentAssignedMatch> parseMatches() {
      final raw = json['refereeMatches'] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(TournamentAssignedMatch.fromJson)
          .toList();
    }

    return TournamentWorkspace(
      organizedTournaments: parseTournaments('organizedTournaments'),
      participatingTournaments: parseTournaments('participatingTournaments'),
      coOrganizerTournaments: parseTournaments('coOrganizerTournaments'),
      refereeInvites: parseInvites('refereeInvites'),
      refereeTournaments: parseInvites('refereeTournaments'),
      refereeMatches: parseMatches(),
    );
  }

  static const empty = TournamentWorkspace();

  List<Tournament> get visibleTournaments {
    final map = <String, Tournament>{};
    for (final tournament in [
      ...organizedTournaments,
      ...coOrganizerTournaments,
      ...participatingTournaments,
    ]) {
      map.putIfAbsent(tournament.id, () => tournament);
    }
    return map.values.toList();
  }

  int get pendingInviteCount => refereeInvites.where((invite) => invite.isPending).length;

  int get activeRoleCount {
    var count = 0;
    if (organizedTournaments.isNotEmpty) count++;
    if (coOrganizerTournaments.isNotEmpty) count++;
    if (refereeTournaments.isNotEmpty) count++;
    if (participatingTournaments.isNotEmpty) count++;
    return count;
  }

  bool get hasAnyData =>
      visibleTournaments.isNotEmpty ||
      refereeInvites.isNotEmpty ||
      refereeTournaments.isNotEmpty ||
      refereeMatches.isNotEmpty;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}
