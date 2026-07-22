import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Unified TeamRow widget used in bracket diagram match cards.
/// Replaces the former _TeamRow (single_elim_diagram) and _DeTeamRow (double_elim_diagram).
class TeamRow extends StatelessWidget {
  final String name;
  final int score;
  final List<int>? sets;
  final bool isWinner;
  final bool isLive;
  final bool isBye;
  final bool isGrandFinalWinner;
  final TextStyle? nameStyle;
  final double rowHeight;

  const TeamRow({
    super.key,
    required this.name,
    required this.score,
    required this.isWinner,
    required this.isLive,
    required this.isBye,
    this.sets,
    this.isGrandFinalWinner = false,
    this.nameStyle,
    this.rowHeight = 24,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color indicatorColor = Colors.transparent;
    Color rowBgColor = Colors.transparent;
    Color textColor = colors.textSecondary;

    if (isGrandFinalWinner && isWinner) {
      indicatorColor = colors.warning;
      rowBgColor = colors.warning.withValues(alpha: 0.15);
      textColor = colors.warning;
    } else if (isWinner) {
      indicatorColor = colors.success;
      rowBgColor = colors.success.withValues(alpha: 0.08);
      textColor = colors.success;
    } else if (isBye) {
      indicatorColor = colors.info;
      rowBgColor = colors.info.withValues(alpha: 0.08);
      textColor = colors.info;
    }

    return Container(
      height: rowHeight + 8, // padding top+bottom = 4+4
      color: rowBgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Winner indicator bar
            Container(
              width: 3,
              height: rowHeight,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            // Team name
            Expanded(
              child: Text(
                name,
                style: nameStyle ??
                    TextStyle(
                      fontSize: 11,
                      fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
                      color: isWinner
                          ? textColor
                          : (isBye ? colors.textMuted : colors.textSecondary),
                      fontStyle: isBye ? FontStyle.italic : FontStyle.normal,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Set scores
            if (sets != null)
              ...sets!.map((s) => Container(
                    margin: const EdgeInsets.only(left: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      '$s',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                  )),
            const SizedBox(width: 6),
            // Total score
            Text(
              isBye ? '' : '$score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isLive
                    ? colors.error
                    : isWinner
                        ? textColor
                        : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
