import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Redesigned cross-table view for round-robin bracket.
/// Displays a styled grid with:
/// - Header row: team names
/// - Cells: score with colored background (win=green, loss=red, draw=amber)
/// - Responsive horizontal scroll
class CrossTableView extends ConsumerWidget {
  final List<MatchModel> matches;
  final String tournamentId;

  const CrossTableView({
    super.key,
    required this.matches,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(standingsProvider(tournamentId));

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return _buildEmptyState(context, 'Chưa có dữ liệu đội thi đấu');
        }

        final teams = standings
            .map((s) => Team(id: s.id, name: s.teamName, createdAt: DateTime.now()))
            .toList();

        // Build score lookup: "team1Id_team2Id" -> score string
        final scores = <String, String>{};
        final scoreStatus = <String, String>{}; // 'win', 'loss', 'draw'
        for (final match in matches) {
          if (match.status == 'completed' || match.status == 'walkover') {
            final key1 = '${match.team1Id}_${match.team2Id}';
            final key2 = '${match.team2Id}_${match.team1Id}';
            scores[key1] = '${match.score1} - ${match.score2}';
            scores[key2] = '${match.score2} - ${match.score1}';
            // Determine status relative to row team
            if (match.score1 > match.score2) {
              scoreStatus[key1] = 'win';
              scoreStatus[key2] = 'loss';
            } else if (match.score1 < match.score2) {
              scoreStatus[key1] = 'loss';
              scoreStatus[key2] = 'win';
            } else {
              scoreStatus[key1] = 'draw';
              scoreStatus[key2] = 'draw';
            }
          }
        }

        const double cellWidth = 90;
        const double rowLabelWidth = 140;

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Row ───
                Row(
                  children: [
                    // Top-left corner cell
                    Container(
                      width: rowLabelWidth,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.colors.bgSurface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppTheme.radiusXL),
                        ),
                        border: Border(
                          right: BorderSide(color: context.colors.border),
                          bottom: BorderSide(color: context.colors.border),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Đội',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    ...teams.map((team) => Container(
                      width: cellWidth,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: context.colors.bgSurface,
                        border: Border(
                          right: BorderSide(color: context.colors.border),
                          bottom: BorderSide(color: context.colors.border),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        team.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    )),
                  ],
                ),
                // ─── Data Rows ───
                ...teams.asMap().entries.map((rowEntry) {
                  final rowIdx = rowEntry.key;
                  final rowTeam = rowEntry.value;
                  final isLastRow = rowIdx == teams.length - 1;
                  return Row(
                    children: [
                      // Row label (team name)
                      Container(
                        width: rowLabelWidth,
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.colors.bgCard,
                          border: Border(
                            right: BorderSide(color: context.colors.border),
                            bottom: isLastRow
                                ? BorderSide(color: context.colors.border)
                                : BorderSide.none,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          rowTeam.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Score cells
                      ...teams.asMap().entries.map((colEntry) {
                        final colIdx = colEntry.key;
                        final colTeam = colEntry.value;
                        final isSelf = rowTeam.id == colTeam.id;

                        // Corner radius for bottom-right
                        final isLastCol = colIdx == teams.length - 1;

                        if (isSelf) {
                          // Diagonal - self cell
                          return Container(
                            width: cellWidth,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.colors.bgSurface.withValues(alpha: 0.5),
                              border: Border(
                                right: BorderSide(color: context.colors.border),
                                bottom: isLastRow
                                    ? BorderSide(color: context.colors.border)
                                    : BorderSide.none,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.minimize_rounded,
                              size: 16,
                              color: context.colors.textMuted.withValues(alpha: 0.5),
                            ),
                          );
                        }

                        final scoreKey = '${rowTeam.id}_${colTeam.id}';
                        final score = scores[scoreKey];
                        final status = scoreStatus[scoreKey];

                        Color? bgColor;
                        Color textColor;
                        if (status == 'win') {
                          bgColor = context.colors.success.withValues(alpha: 0.12);
                          textColor = context.colors.success;
                        } else if (status == 'loss') {
                          bgColor = context.colors.error.withValues(alpha: 0.10);
                          textColor = context.colors.error;
                        } else if (status == 'draw') {
                          bgColor = context.colors.warning.withValues(alpha: 0.12);
                          textColor = context.colors.warning;
                        } else {
                          bgColor = Colors.transparent;
                          textColor = context.colors.textMuted;
                        }

                        BorderRadiusGeometry? borderRadius;
                        if (isLastRow && isLastCol) {
                          borderRadius = const BorderRadius.only(
                            bottomRight: Radius.circular(AppTheme.radiusXL),
                          );
                        }

                        return Container(
                          width: cellWidth,
                          height: 44,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: borderRadius,
                            border: Border(
                              right: BorderSide(color: context.colors.border),
                              bottom: isLastRow
                                  ? BorderSide(color: context.colors.border)
                                  : BorderSide.none,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            score ?? '-',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: score != null ? FontWeight.w700 : FontWeight.w400,
                              color: textColor,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.colors.error),
            const SizedBox(height: 12),
            Text(
              'Lỗi: $e',
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: context.colors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
