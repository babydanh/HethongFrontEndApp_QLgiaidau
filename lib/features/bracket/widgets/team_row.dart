import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Unified TeamRow widget used in bracket diagram match cards.
/// Replaces the former _TeamRow (single_elim_diagram) and _DeTeamRow (double_elim_diagram).
class TeamRow extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final int score;
  final List<int>? sets;
  final List<int>? opponentSets;
  final bool isWinner;
  final bool isLive;
  final bool isBye;
  final bool isGrandFinalWinner;
  final TextStyle? nameStyle;
  final double rowHeight;
  final int maxSetsCount;
  final Widget? trailing;

  const TeamRow({
    super.key,
    required this.name,
    this.logoUrl,
    required this.score,
    required this.isWinner,
    required this.isLive,
    required this.isBye,
    this.sets,
    this.opponentSets,
    this.isGrandFinalWinner = false,
    this.nameStyle,
    this.rowHeight = 24,
    this.maxSetsCount = 0,
    this.trailing,
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

    final hasSetDetails = sets != null && sets!.isNotEmpty;

    return Container(
      height: rowHeight + 8,
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

            if (logoUrl != null && logoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ClipOval(
                  child: Image.network(
                    logoUrl!,
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),

            // Team name
            Expanded(
              child: Text(
                name,
                style:
                    nameStyle ??
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

            const SizedBox(width: 4),

            // Hiển thị các ô điểm từng set S1, S2, S3... theo đúng cài đặt
            if (hasSetDetails)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  maxSetsCount > 0 ? maxSetsCount : sets!.length,
                  (index) {
                    final s = (index < sets!.length) ? sets![index] : null;
                    final oppS =
                        (opponentSets != null && index < opponentSets!.length)
                        ? opponentSets![index]
                        : null;
                    final isSetWon = s != null && oppS != null && s > oppS;
                    return Container(
                      width: 24,
                      height: 20,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: s != null
                            ? (isSetWon
                                  ? colors.success.withValues(alpha: 0.15)
                                  : colors.bgSurface)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: s != null
                            ? Border.all(
                                color: isSetWon
                                    ? colors.success.withValues(alpha: 0.5)
                                    : colors.border,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          s != null ? '$s' : '',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSetWon
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isSetWon
                                ? colors.success
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (!isBye)
              Container(
                width: 24,
                height: 20,
                margin: const EdgeInsets.only(left: 3),
                decoration: BoxDecoration(
                  color: isWinner
                      ? colors.success.withValues(alpha: 0.15)
                      : colors.bgSurface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isWinner
                        ? colors.success.withValues(alpha: 0.5)
                        : colors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isWinner ? FontWeight.w900 : FontWeight.w600,
                      color: isWinner ? colors.success : colors.textSecondary,
                    ),
                  ),
                ),
              ),

            if (trailing != null) ...[const SizedBox(width: 3), trailing!],
          ],
        ),
      ),
    );
  }
}
