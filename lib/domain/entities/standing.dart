import 'package:app_quanly_giaidau/core/participants/participant_display.dart';

class Standing {
  final String id;
  final String teamName;
  final String group;
  final int played;
  final int won;
  final int lost;
  final int drawn;
  final int pointsFor;
  final int pointsAgainst;
  final int pointDifference;
  final int totalPoints;
  final List<ParticipantPlayer> players;

  /// Swiss only: Backend rank (1-based) and tiebreak values; null/0 elsewhere.
  final int? rank;
  final double buchholz;
  final double buchholzCut1;
  final double sonnebornBerger;

  const Standing({
    required this.id,
    required this.teamName,
    this.group = '',
    this.played = 0,
    this.won = 0,
    this.lost = 0,
    this.drawn = 0,
    this.pointsFor = 0,
    this.pointsAgainst = 0,
    this.pointDifference = 0,
    this.totalPoints = 0,
    this.players = const [],
    this.rank,
    this.buchholz = 0,
    this.buchholzCut1 = 0,
    this.sonnebornBerger = 0,
  });

  factory Standing.fromJson(Map<String, dynamic> json, String id) {
    final participant = json['participant'] is Map
        ? Map<String, dynamic>.from(json['participant'] as Map)
        : json;
    return Standing(
      id: id,
      teamName: normalizeParticipantText(
        (participant['teamName'] ?? json['teamName'])?.toString(),
      ),
      players: toParticipantPlayers(participant),
      group: json['group'] ?? '',
      played: json['played'] ?? 0,
      won: json['won'] ?? 0,
      lost: json['lost'] ?? 0,
      drawn: json['drawn'] ?? 0,
      pointsFor: json['pointsFor'] ?? 0,
      pointsAgainst: json['pointsAgainst'] ?? 0,
      pointDifference: json['pointDifference'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      rank: (json['rank'] as num?)?.toInt(),
      buchholz: (json['buchholz'] as num?)?.toDouble() ?? 0,
      buchholzCut1: (json['buchholzCut1'] as num?)?.toDouble() ?? 0,
      sonnebornBerger: (json['sonnebornBerger'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamName': teamName,
      'group': group,
      'played': played,
      'won': won,
      'lost': lost,
      'drawn': drawn,
      'pointsFor': pointsFor,
      'pointsAgainst': pointsAgainst,
      'pointDifference': pointDifference,
      'totalPoints': totalPoints,
    };
  }

  Standing copyWith({
    String? id,
    String? teamName,
    String? group,
    int? played,
    int? won,
    int? lost,
    int? drawn,
    int? pointsFor,
    int? pointsAgainst,
    int? pointDifference,
    int? totalPoints,
    List<ParticipantPlayer>? players,
    int? rank,
    double? buchholz,
    double? buchholzCut1,
    double? sonnebornBerger,
  }) {
    return Standing(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      group: group ?? this.group,
      played: played ?? this.played,
      won: won ?? this.won,
      lost: lost ?? this.lost,
      drawn: drawn ?? this.drawn,
      pointsFor: pointsFor ?? this.pointsFor,
      pointsAgainst: pointsAgainst ?? this.pointsAgainst,
      pointDifference: pointDifference ?? this.pointDifference,
      totalPoints: totalPoints ?? this.totalPoints,
      players: players ?? this.players,
      rank: rank ?? this.rank,
      buchholz: buchholz ?? this.buchholz,
      buchholzCut1: buchholzCut1 ?? this.buchholzCut1,
      sonnebornBerger: sonnebornBerger ?? this.sonnebornBerger,
    );
  }

  @override
  String toString() =>
      'Standing($teamName: $totalPoints pts, W$won-D$drawn-L$lost)';
}
