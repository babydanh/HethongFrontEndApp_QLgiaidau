import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Standalone standings view for round-robin / group-stage tournaments.
/// Extracted from BracketViewScreen._buildStandingsView.
class StandingsView extends ConsumerWidget {
  final List<MatchModel> matches;
  final String tournamentId;
  final String? divisionId;

  const StandingsView({
    super.key,
    required this.matches,
    required this.tournamentId,
    this.divisionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final standingsAsync = ref.watch(
      standingsWithDivisionProvider((
        tournamentId: tournamentId,
        divisionId: divisionId,
      )),
    );
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));
    final tournament = tournamentAsync.value;
    final isGsknockout =
        tournament?.bracketType == AppConstants.bracketGroupStageKnockout;
    final isFootball =
        (tournament?.sport.toLowerCase() == 'football' ||
            tournament?.sport.toLowerCase() == 'bóng đá' ||
            tournament?.sport.toLowerCase() == 'soccer') ||
        matches.any((match) {
          final kind = match.sportRules?['kind']?.toString().toUpperCase();
          final sport = match.sportKey?.toLowerCase();
          return kind == 'FOOTBALL' || sport == 'football' || sport == 'soccer';
        });

    // Map tên đội với groupName từ matches thuộc Vòng Bảng
    final teamGroupMap = <String, String>{};
    final groupStageMatches = matches.where((m) {
      final stage = (m.stageName ?? '').toUpperCase();
      final group = (m.groupName ?? '').toUpperCase();
      if (stage.contains('PLAYOFF') || stage.contains('KNOCKOUT')) return false;
      return group.isNotEmpty ||
          stage.contains('BẢNG') ||
          stage.contains('GROUP') ||
          stage.contains('ROUND ROBIN');
    }).toList();

    for (final m in groupStageMatches) {
      if (m.groupName != null && m.groupName!.isNotEmpty) {
        if (m.team1Name.isNotEmpty && m.team1Name != 'TBD') {
          teamGroupMap[m.team1Name] = m.groupName!;
        }
        if (m.team2Name.isNotEmpty && m.team2Name != 'TBD') {
          teamGroupMap[m.team2Name] = m.groupName!;
        }
      }
    }

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return Center(child: Text(l10n.standings_empty));
        }

        // Nhóm standings theo Group
        final groupedStandings = <String, List<dynamic>>{};
        for (final st in standings) {
          final groupName =
              (st.group.isNotEmpty ? st.group : teamGroupMap[st.teamName]) ??
              l10n.crossTableDefaultGroup;
          groupedStandings.putIfAbsent(groupName, () => []).add(st);
        }

        final groupsList = groupedStandings.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.standings_title(groupsList.length),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: groupsList.length,
              itemBuilder: (context, gIdx) {
                final gName = groupsList[gIdx];
                final gStandings = groupedStandings[gName]!;
                final advancingCount = isGsknockout
                    ? (gStandings.length / 2).ceil()
                    : 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: context.colors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          border: Border(
                            bottom: BorderSide(color: context.colors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              gName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              l10n.standings_groupTeams(gStandings.length),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                            fontSize: 12,
                          ),
                          dataTextStyle: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                          ),
                          columns: isFootball
                              ? [
                                  DataColumn(label: Text(l10n.standings_rank)),
                                  DataColumn(label: Text(l10n.standings_team)),
                                  DataColumn(
                                    label: Text(l10n.standings_playedShort),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_wonShort),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_drawnShort),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_lostShort),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_pointsForShort),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      l10n.standings_pointsAgainstShort,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_differenceShort),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_pointsShort),
                                  ),
                                ]
                              : [
                                  DataColumn(label: Text(l10n.standings_rank)),
                                  DataColumn(
                                    label: Text(l10n.standings_teamAthletes),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_matches),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_winsShort),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_lossesShort),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_points),
                                  ),
                                  DataColumn(
                                    label: Text(l10n.standings_difference),
                                  ),
                                ],
                          rows: List.generate(gStandings.length, (index) {
                            final st = gStandings[index];
                            final isAdvancing =
                                isGsknockout && index < advancingCount;
                            final cells = isFootball
                                ? [
                                    DataCell(Text('${st.played}')),
                                    DataCell(Text('${st.won}')),
                                    DataCell(Text('${st.drawn}')),
                                    DataCell(Text('${st.lost}')),
                                    DataCell(Text('${st.pointsFor}')),
                                    DataCell(Text('${st.pointsAgainst}')),
                                    DataCell(
                                      Text(
                                        '${st.pointDifference > 0 ? '+' : ''}${st.pointDifference}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${st.totalPoints}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ]
                                : [
                                    DataCell(Text('${st.played}')),
                                    DataCell(Text('${st.won}')),
                                    DataCell(Text('${st.lost}')),
                                    DataCell(
                                      Text(
                                        '${st.totalPoints}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${st.pointDifference > 0 ? '+' : ''}${st.pointDifference}',
                                      ),
                                    ),
                                  ];
                            return DataRow(
                              color: isAdvancing
                                  ? WidgetStateProperty.all(
                                      context.colors.success.withValues(
                                        alpha: 0.06,
                                      ),
                                    )
                                  : null,
                              cells: [
                                DataCell(
                                  isAdvancing
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.colors.success
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: context.colors.success
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: context.colors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : Text('${index + 1}'),
                                ),
                                DataCell(
                                  Text(
                                    st.teamName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...cells,
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.standings_error(e.toString))),
    );
  }
}
