import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_team_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TeamsTab extends StatelessWidget {
  final List<Team> teams;
  final String selectedDivision;
  final ScrollController? scrollController;

  const TeamsTab({
    super.key,
    required this.teams,
    required this.selectedDivision,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: colors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              l10n.noTeamsJoined,
              style: TextStyle(fontSize: 15, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    String getDivision(Team t) => t.group.isNotEmpty ? t.group : l10n.otherDivision;

    final matched = teams.where((t) => getDivision(t) == selectedDivision).toList();
    final filteredTeams = (selectedDivision == l10n.filterAll || selectedDivision == "all" || selectedDivision.isEmpty)
        ? teams
        : (matched.isEmpty ? teams : matched);

    final grouped = <String, List<Team>>{};
    for (var t in filteredTeams) {
      final div = getDivision(t);
      grouped.putIfAbsent(div, () => []).add(t);
    }
    final sortedDivisions = grouped.keys.toList()..sort();

    if (filteredTeams.isEmpty) {
      return Center(
        child: Text(
          l10n.noTeamsFound,
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
      children: sortedDivisions.map((division) {
        final teamsInDiv = grouped[division]!;
        final isFemale = division.contains("Nữ");
        final isMale = division.contains("Nam");
        final themeColor = isFemale
            ? const Color(0xFFE91E63)
            : isMale
            ? const Color(0xFF2196F3)
            : AppTheme.primary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    division,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${teamsInDiv.length}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Cards with inline expansion for Doubles and direct tap for Singles
            ...teamsInDiv.map((team) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TournamentTeamCard(
                team: team,
                onMemberTap: (userId, memberName) {
                  if (userId != null && userId.isNotEmpty) {
                    context.push('/profile/user/$userId');
                  } else {
                    context.push('/profile');
                  }
                },
              ),
            )),
          ],
        );
      }).toList(),
    );
  }
}
