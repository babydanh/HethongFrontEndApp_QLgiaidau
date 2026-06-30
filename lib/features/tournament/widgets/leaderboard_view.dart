import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';

class LeaderboardView extends StatelessWidget {
  final List<Standing> standings;
  final String selectedDivision;

  const LeaderboardView({
    super.key,
    required this.standings,
    required this.selectedDivision,
  });

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: context.colors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Bảng xếp hạng",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Chưa có dữ liệu thi đấu",
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: standings.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        }
        return _buildStandingRow(context, standings[index - 1], index);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              "#",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "ĐỘI",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          _statHeader("P", colors),
          _statHeader("W", colors),
          _statHeader("D", colors),
          _statHeader("L", colors),
          _statHeader("GD", colors),
          _statHeader("PTS", colors, isHighlight: true),
        ],
      ),
    );
  }

  Widget _statHeader(String text, AppColorsExtension colors, {bool isHighlight = false}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isHighlight ? const Color(0xFF2979FF) : colors.textMuted,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStandingRow(BuildContext context, Standing standing, int rank) {
    final colors = context.colors;
    final isTop3 = rank <= 3;
    Color rankColor;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = colors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3
              ? rankColor.withValues(alpha: 0.3)
              : colors.border.withValues(alpha: 0.5),
        ),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Row(
              children: [
                if (isTop3)
                  Icon(
                    Icons.emoji_events,
                    size: 18,
                    color: rankColor,
                  )
                else
                  Text(
                    "$rank",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              standing.teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                color: colors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          _statCell(standing.played.toString(), colors),
          _statCell(standing.won.toString(), colors),
          _statCell(standing.drawn.toString(), colors),
          _statCell(standing.lost.toString(), colors),
          _statCell((standing.pointDifference > 0 ? "+" : "") + standing.pointDifference.toString(), colors),
          _statCell(standing.totalPoints.toString(), colors, isHighlight: true),
        ],
      ),
    );
  }

  Widget _statCell(String text, AppColorsExtension colors, {bool isHighlight = false}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          color: isHighlight ? const Color(0xFF2979FF) : colors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}
