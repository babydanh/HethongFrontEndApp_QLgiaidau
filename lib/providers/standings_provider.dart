import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/models/standing_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';

/// Provider lấy bảng xếp hạng (standings) cho 1 giải đấu.
/// 
/// Ưu tiên gọi API: GET /api/v1/tournaments/:id/standings
/// Nếu API fail, fallback về tính client-side từ teams + matches.
final standingsProvider = FutureProvider.family<List<Standing>, String>((ref, tournamentId) async {
  // 1. Thử gọi API trước
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/tournaments/$tournamentId/standings');
    if (response.statusCode == 200) {
      final rawData = response.data;
      final dataList = rawData['data'] as List<dynamic>?;

      if (dataList != null && dataList.isNotEmpty) {
        final List<Standing> standings = [];

        for (final groupEntry in dataList) {
          final groupEntryMap = groupEntry as Map<String, dynamic>;
          final groupName = groupEntryMap['groupName'] as String? ?? '';
          final groupStandings = groupEntryMap['standings'] as List<dynamic>? ?? [];

          for (final standingData in groupStandings) {
            final s = standingData as Map<String, dynamic>;
            standings.add(Standing(
              id: s['teamId'] as String? ?? '',
              teamName: s['teamName'] as String? ?? '',
              group: groupName,
              played: s['played'] as int? ?? 0,
              won: s['won'] as int? ?? 0,
              lost: s['lost'] as int? ?? 0,
              drawn: s['drawn'] as int? ?? 0,
              pointsFor: s['pointsFor'] as int? ?? 0,
              pointsAgainst: s['pointsAgainst'] as int? ?? 0,
              pointDifference: s['pointDifference'] as int? ?? 0,
              totalPoints: s['totalPoints'] as int? ?? (s['points'] as int? ?? 0),
            ));
          }
        }

        if (standings.isNotEmpty) {
          return standings;
        }
      }
    }
  } catch (_) {
    // API fail → fallback sang client-side
  }

  // 2. Fallback: tính client-side từ teams + matches
  final teams = await ref.read(teamsProvider(tournamentId).future);
  final matches = await ref.read(matchesProvider(tournamentId).future);

  // Initialize standings map
  final Map<String, Standing> standingsMap = {};
  for (final team in teams) {
    if (team.id != 'BYE') {
      standingsMap[team.id] = Standing(
        id: team.id,
        teamName: team.name,
      );
    }
  }

  // Calculate stats from completed matches
  for (final match in matches) {
    if (StatusHelper.isCompleted(match.status)) {
      final isDraw = match.score1 == match.score2 && match.winnerId.isEmpty;

      // Update Team 1
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
          pointDifference: (current.pointsFor + match.score1) - (current.pointsAgainst + match.score2),
          totalPoints: current.totalPoints + (isWin ? 3 : (isDraw ? 1 : 0)),
        );
      }

      // Update Team 2
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
          pointDifference: (current.pointsFor + match.score2) - (current.pointsAgainst + match.score1),
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
      if (loserId.isNotEmpty && loserId != 'BYE' && standingsMap.containsKey(loserId)) {
        final current = standingsMap[loserId]!;
        standingsMap[loserId] = current.copyWith(
          played: current.played + 1,
          lost: current.lost + 1,
        );
      }
    }
  }

  // Convert to list and sort
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
});
