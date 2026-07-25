import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';

final standingsProvider =
    FutureProvider.family<List<Standing>, String>((ref, tournamentId) {
  return ref.watch(standingsWithDivisionProvider((
    tournamentId: tournamentId,
    divisionId: null,
  )).future);
});

final standingsWithDivisionProvider = FutureProvider.family<
    List<Standing>, ({String tournamentId, String? divisionId})>((ref, params) async {
  final apiStandings = await _fetchApiStandings(
    ref,
    params.tournamentId,
    divisionId: params.divisionId,
  );
  if (apiStandings.isNotEmpty) {
    return apiStandings;
  }

  return _calculateClientStandings(
    ref,
    params.tournamentId,
    divisionId: params.divisionId,
  );
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

  final standingsMap = <String, Standing>{};
  for (final team in teams) {
    if (team.id != 'BYE') {
      standingsMap[team.id] = Standing(id: team.id, teamName: team.name);
    }
  }

  for (final match in matches) {
    if (StatusHelper.isCompleted(match.status)) {
      final isDraw = match.score1 == match.score2 && match.winnerId.isEmpty;

      if (standingsMap.containsKey(match.team1Id)) {
        final current = standingsMap[match.team1Id]!;
        final isWin = match.winnerId == match.team1Id;
        final isLoss = !isWin && !isDraw;

        standingsMap[match.team1Id] = current.copyWith(
          played: current.played + 1,
          won: current.won + (isWin ? 1 : 0),
          lost: current.lost + (isLoss ? 1 : 0),
          drawn: current.drawn + (isDraw ? 1 : 0),
          pointsFor: current.pointsFor + match.score1,
          pointsAgainst: current.pointsAgainst + match.score2,
          pointDifference: (current.pointsFor + match.score1) -
              (current.pointsAgainst + match.score2),
          totalPoints: current.totalPoints + (isWin ? 3 : (isDraw ? 1 : 0)),
        );
      }

      if (standingsMap.containsKey(match.team2Id)) {
        final current = standingsMap[match.team2Id]!;
        final isWin = match.winnerId == match.team2Id;
        final isLoss = !isWin && !isDraw;

        standingsMap[match.team2Id] = current.copyWith(
          played: current.played + 1,
          won: current.won + (isWin ? 1 : 0),
          lost: current.lost + (isLoss ? 1 : 0),
          drawn: current.drawn + (isDraw ? 1 : 0),
          pointsFor: current.pointsFor + match.score2,
          pointsAgainst: current.pointsAgainst + match.score1,
          pointDifference: (current.pointsFor + match.score2) -
              (current.pointsAgainst + match.score1),
          totalPoints: current.totalPoints + (isWin ? 3 : (isDraw ? 1 : 0)),
        );
      }
    } else if (StatusHelper.isWalkover(match.status)) {
      final winnerId = match.winnerId;
      if (winnerId.isNotEmpty && standingsMap.containsKey(winnerId)) {
        final current = standingsMap[winnerId]!;
        standingsMap[winnerId] = current.copyWith(
          played: current.played + 1,
          won: current.won + 1,
          totalPoints: current.totalPoints + 3,
        );
      }

      final loserId = match.loserId;
      if (loserId.isNotEmpty &&
          loserId != 'BYE' &&
          standingsMap.containsKey(loserId)) {
        final current = standingsMap[loserId]!;
        standingsMap[loserId] = current.copyWith(
          played: current.played + 1,
          lost: current.lost + 1,
        );
      }
    }
  }

  final standingsList = standingsMap.values.toList();
  standingsList.sort((a, b) {
    if (a.totalPoints != b.totalPoints) {
      return b.totalPoints.compareTo(a.totalPoints);
    }
    if (a.pointDifference != b.pointDifference) {
      return b.pointDifference.compareTo(a.pointDifference);
    }
    return b.pointsFor.compareTo(a.pointsFor);
  });

  return standingsList;
}
