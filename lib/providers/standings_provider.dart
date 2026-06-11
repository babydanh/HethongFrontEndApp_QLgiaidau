import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/data/models/standing_model.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';

final standingsProvider = Provider.family<AsyncValue<List<Standing>>, String>((ref, tournamentId) {
  final teamsAsync = ref.watch(teamsProvider(tournamentId));
  final matchesAsync = ref.watch(matchesProvider(tournamentId));

  if (teamsAsync is AsyncLoading || matchesAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (teamsAsync.hasError) {
    return AsyncValue.error(teamsAsync.error!, teamsAsync.stackTrace!);
  }
  if (matchesAsync.hasError) {
    return AsyncValue.error(matchesAsync.error!, matchesAsync.stackTrace!);
  }

  final teams = teamsAsync.value ?? [];
  final matches = matchesAsync.value ?? [];

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
      // Walkovers usually count as a 3-0 win or similar, but let's just award points and 1 win.
      // Usually standard is a 1-0 or 3-0 win depending on sport. Let's just award the 3 points.
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
      return b.totalPoints.compareTo(a.totalPoints); // Descending points
    }
    if (a.pointDifference != b.pointDifference) {
      return b.pointDifference.compareTo(a.pointDifference); // Descending GD
    }
    return b.pointsFor.compareTo(a.pointsFor); // Descending GF
  });

  return AsyncValue.data(standingsList);
});
