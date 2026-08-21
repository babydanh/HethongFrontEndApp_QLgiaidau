import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_team_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TeamsTab extends StatefulWidget {
  final List<Team> teams;
  final String selectedDivision;
  final String? selectedDivisionId;
  final ScrollController? scrollController;

  const TeamsTab({
    super.key,
    required this.teams,
    required this.selectedDivision,
    this.selectedDivisionId,
    this.scrollController,
  });

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (widget.teams.isEmpty) {
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

    final matched = widget.teams.where((t) {
      if (widget.selectedDivisionId != null && widget.selectedDivisionId!.isNotEmpty &&
          t.divisionId.isNotEmpty) {
        return t.divisionId == widget.selectedDivisionId;
      }
      return getDivision(t) == widget.selectedDivision;
    }).toList();
    final isAllDivisions = widget.selectedDivision == l10n.filterAll ||
        widget.selectedDivision == "all" ||
        widget.selectedDivision.isEmpty;
    // Never fall back to another division when the selected division has no teams.
    final divisionTeams = isAllDivisions ? widget.teams : matched;

    // Apply real-time search query filtering by team name or member names
    final query = _searchQuery.trim().toLowerCase();
    final filteredTeams = query.isEmpty
        ? divisionTeams
        : divisionTeams.where((t) {
            if (t.name.toLowerCase().contains(query)) return true;
            if (t.members.any((m) => m.toLowerCase().contains(query))) return true;
            if (t.memberInfos.any((m) => m.fullName.toLowerCase().contains(query))) return true;
            return false;
          }).toList();

    final grouped = <String, List<Team>>{};
    for (var t in filteredTeams) {
      final div = getDivision(t);
      grouped.putIfAbsent(div, () => []).add(t);
    }
    final sortedDivisions = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderLight),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên đội hoặc thành viên...',
                hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
                prefixIcon: Icon(Icons.search, size: 18, color: colors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 16, color: colors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),

        if (filteredTeams.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            child: Center(
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'Không tìm thấy kết quả phù hợp với "$_searchQuery"'
                    : l10n.noTeamsFound,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ListView(
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
          ),
      ],
    );
  }
}
