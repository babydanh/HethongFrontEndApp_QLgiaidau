import 'package:app_quanly_giaidau/domain/entities/match.dart';

class TennisGamePointDisplay {
  final String team1;
  final String team2;

  const TennisGamePointDisplay(this.team1, this.team2);
}

bool _isTennisMatch(MatchModel match) {
  final candidates = [
    match.sportKey,
    match.sportRules?['kind'],
    match.sportRules?['sport'],
    match.tournamentConfig?['sportKey'],
    match.tournamentConfig?['sport'],
  ];
  return candidates.any(
    (value) => value?.toString().trim().toLowerCase() == 'tennis',
  );
}

TennisGamePointDisplay? readTennisGamePointDisplay(
  MatchModel match, {
  required bool isLive,
}) {
  if (!isLive || !_isTennisMatch(match)) return null;

  final liveState = match.scoreDetails?['liveState'];
  if (liveState is! Map) return null;
  final pointState = liveState['tennisPointState'];
  if (pointState is! Map) return null;

  int parsePoint(dynamic value) {
    if (value is num) return value.toInt().clamp(0, 99).toInt();
    return switch (value?.toString().trim().toUpperCase()) {
      '15' => 1,
      '30' => 2,
      '40' => 3,
      'A' || 'AD' => 4,
      _ => 0,
    };
  }

  final team1Point = parsePoint(pointState['team1Point']);
  final team2Point = parsePoint(pointState['team2Point']);
  if (pointState['mode']?.toString().toLowerCase() == 'tiebreak') {
    return TennisGamePointDisplay('$team1Point', '$team2Point');
  }

  String formatStandardPoint(int point, int opponentPoint) {
    if (point >= 3 && opponentPoint >= 3) {
      if (point == opponentPoint) return '40';
      return point > opponentPoint ? 'Ad' : '40';
    }
    return switch (point) {
      1 => '15',
      2 => '30',
      3 => '40',
      4 => 'Ad',
      _ => '0',
    };
  }

  return TennisGamePointDisplay(
    formatStandardPoint(team1Point, team2Point),
    formatStandardPoint(team2Point, team1Point),
  );
}
