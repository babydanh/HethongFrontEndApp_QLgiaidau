import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

final standingsProvider = StreamProvider.family<List<Standing>, String>((ref, tournamentId) async* {
  final asyncVal = ref.watch(standingsWithDivisionProvider((
    tournamentId: tournamentId,
    divisionId: null,
  )));
  if (asyncVal.hasValue) {
    yield asyncVal.requireValue;
  } else if (asyncVal.hasError) {
    throw asyncVal.error!;
  } else {
    yield await ref.watch(standingsWithDivisionProvider((
      tournamentId: tournamentId,
      divisionId: null,
    )).future);
  }
});

final standingsWithDivisionProvider = StreamProvider.family<
    List<Standing>, ({String tournamentId, String? divisionId})>((ref, params) async* {
  while (true) {
    final apiStandings = await _fetchApiStandings(
      ref,
      params.tournamentId,
      divisionId: params.divisionId,
    );
    if (apiStandings.isNotEmpty) {
      yield apiStandings;
    } else {
      yield await _calculateClientStandings(
        ref,
        params.tournamentId,
        divisionId: params.divisionId,
      );
    }
    await Future<void>.delayed(const Duration(seconds: 30));
  }
});

Future<List<Standing>> _fetchApiStandings(
  Ref ref,
  String tournamentId, {
  String? divisionId,
}) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get(
      '/tournaments/$tournamentId/standings',
      queryParameters: divisionId != null ? {'divisionId': divisionId} : null,
    );
    if (response.statusCode != 200) return const [];

    final rawData = response.data;
    final data = rawData is Map<String, dynamic> ? rawData['data'] : null;

    if (data is List<dynamic>) {
      return _parseLegacyGroupedStandings(data);
    }

    if (data is Map<String, dynamic>) {
      return _parseBracketStandings(data);
    }
  } catch (_) {
    // Fallback to client-side calculation below.
  }
  return const [];
}

List<Standing> _parseLegacyGroupedStandings(List<dynamic> dataList) {
  final standings = <Standing>[];
  for (final groupEntry in dataList) {
    if (groupEntry is! Map<String, dynamic>) continue;
    final groupName = groupEntry['groupName'] as String? ?? '';
    final groupStandings = groupEntry['standings'] as List<dynamic>? ?? [];

    for (final standingData in groupStandings) {
      if (standingData is! Map<String, dynamic>) continue;
      standings.add(_standingFromApi(standingData, groupName: groupName));
    }
  }
  return standings;
}

List<Standing> _parseBracketStandings(Map<String, dynamic> data) {
  final groups = data['groups'] as List<dynamic>? ?? [];
  final groupNamesById = <String, String>{};
  for (final group in groups) {
    if (group is! Map<String, dynamic>) continue;
    final id = group['id']?.toString();
    if (id == null || id.isEmpty) continue;
    groupNamesById[id] = group['name']?.toString() ?? '';
  }

  final standingsData = data['standings'] as List<dynamic>? ?? [];
  return standingsData.whereType<Map<String, dynamic>>().map((s) {
    final groupId = s['groupId']?.toString() ?? '';
    return _standingFromApi(
      s,
      groupName: groupNamesById[groupId] ?? '',
    );
  }).toList();
}

Standing _standingFromApi(
  Map<String, dynamic> s, {
  required String groupName,
}) {
  final pointsFor = _asInt(s['pointsFor']);
  final pointsAgainst = _asInt(s['pointsAgainst']);
  return Standing(
    id: (s['teamId'] ?? s['participantId'] ?? s['id'])?.toString() ?? '',
    teamName: s['teamName']?.toString() ?? '',
    group: groupName,
    played: _asInt(s['played']),
    won: _asInt(s['won']),
    lost: _asInt(s['lost']),
    drawn: _asInt(s['drawn'] ?? s['draws']),
    pointsFor: pointsFor,
    pointsAgainst: pointsAgainst,
    pointDifference: _asInt(
      s['pointDifference'],
      fallback: pointsFor - pointsAgainst,
    ),
    totalPoints: _asInt(s['totalPoints'] ?? s['points']),
  );
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Future<List<Standing>> _calculateClientStandings(
  Ref ref,
  String tournamentId, {
  String? divisionId,
}) async {
  final teams = await ref.read(teamsProvider(tournamentId).future);
  final matches = await ref.read(matchesWithDivisionProvider((
    tournamentId: tournamentId,
    divisionId: divisionId,
  )).future);

  var winPoints = 3;
  var drawPoints = 1;
  var lossPoints = 0;
  for (final match in matches) {
    final rules = match.sportRules;
    final scoring = rules?['scoring'] is Map
        ? Map<String, dynamic>.from(rules!['scoring'] as Map)
        : rules;
    if (scoring == null) continue;
    final win = scoring['winPoints'];
    final draw = scoring['drawPoints'];
    final loss = scoring['lossPoints'];
    if (win is num) winPoints = win.toInt();
    if (draw is num) drawPoints = draw.toInt();
    if (loss is num) lossPoints = loss.toInt();
    break;
  }

  final standingsMap = <String, Standing>{};
  for (final team in teams) {
    if (team.id != 'BYE') {
      standingsMap[team.id] = Standing(id: team.id, teamName: team.name);
    }
  }

  for (final match in matches) {
    if (match.status.toLowerCase() != 'completed') continue;

    final football = match.scoreDetails?['football'];
    final footballMap = football is Map
        ? Map<String, dynamic>.from(football)
        : null;
    final team1Pts = footballMap == null
        ? match.sets.fold(0, (sum, s) => sum + s.score1)
        : _asInt(footballMap['team1Goals'] ?? footballMap['p1Goals']);
    final team2Pts = footballMap == null
        ? match.sets.fold(0, (sum, s) => sum + s.score2)
        : _asInt(footballMap['team2Goals'] ?? footballMap['p2Goals']);
    final team1Id = match.team1Id;
    final team2Id = match.team2Id;
    if (team1Id.isNotEmpty &&
        team1Id != 'BYE' &&
        standingsMap.containsKey(team1Id)) {
      final current = standingsMap[team1Id]!;
      standingsMap[team1Id] = current.copyWith(
        pointsFor: current.pointsFor + team1Pts,
        pointsAgainst: current.pointsAgainst + team2Pts,
      );
    }
    if (team2Id.isNotEmpty &&
        team2Id != 'BYE' &&
        standingsMap.containsKey(team2Id)) {
      final current = standingsMap[team2Id]!;
      standingsMap[team2Id] = current.copyWith(
        pointsFor: current.pointsFor + team2Pts,
        pointsAgainst: current.pointsAgainst + team1Pts,
      );
    }

    if (team1Id.isEmpty ||
        team2Id.isEmpty ||
        team1Id == 'BYE' ||
        team2Id == 'BYE' ||
        !standingsMap.containsKey(team1Id) ||
        !standingsMap.containsKey(team2Id)) {
      continue;
    }

    final winnerId = match.winnerId;
    final team1Won =
        winnerId == team1Id || (winnerId.isEmpty && team1Pts > team2Pts);
    final team2Won =
        winnerId == team2Id || (winnerId.isEmpty && team2Pts > team1Pts);
    final team1 = standingsMap[team1Id]!;
    final team2 = standingsMap[team2Id]!;
    if (team1Won) {
      standingsMap[team1Id] = team1.copyWith(
        played: team1.played + 1,
        won: team1.won + 1,
        totalPoints: team1.totalPoints + winPoints,
      );
      standingsMap[team2Id] = team2.copyWith(
        played: team2.played + 1,
        lost: team2.lost + 1,
        totalPoints: team2.totalPoints + lossPoints,
      );
    } else if (team2Won) {
      standingsMap[team2Id] = team2.copyWith(
        played: team2.played + 1,
        won: team2.won + 1,
        totalPoints: team2.totalPoints + winPoints,
      );
      standingsMap[team1Id] = team1.copyWith(
        played: team1.played + 1,
        lost: team1.lost + 1,
        totalPoints: team1.totalPoints + lossPoints,
      );
    } else {
      standingsMap[team1Id] = team1.copyWith(
        played: team1.played + 1,
        drawn: team1.drawn + 1,
        totalPoints: team1.totalPoints + drawPoints,
      );
      standingsMap[team2Id] = team2.copyWith(
        played: team2.played + 1,
        drawn: team2.drawn + 1,
        totalPoints: team2.totalPoints + drawPoints,
      );
    }
  }

  for (final entry in standingsMap.entries) {
    final current = entry.value;
    standingsMap[entry.key] = current.copyWith(
      pointDifference: current.pointsFor - current.pointsAgainst,
    );
  }

  final standingsList = standingsMap.values.toList();
  standingsList.sort((a, b) {
    if (a.totalPoints != b.totalPoints) {
      return b.totalPoints.compareTo(a.totalPoints);
    }
    if (a.pointDifference != b.pointDifference) {
      return b.pointDifference.compareTo(a.pointDifference);
    }
    if (a.pointsFor != b.pointsFor) {
      return b.pointsFor.compareTo(a.pointsFor);
    }
    if (a.won != b.won) return b.won.compareTo(a.won);
    return a.id.compareTo(b.id);
  });

  return standingsList;
}
