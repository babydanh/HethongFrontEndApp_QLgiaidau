import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Unified TeamRow widget used in bracket diagram match cards.
/// Replaces the former _TeamRow (single_elim_diagram) and _DeTeamRow (double_elim_diagram).
class TeamRow extends StatelessWidget {
  final String name;
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

  const TeamRow({
    super.key,
    required this.name,
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

    // Tính số set thắng thực tế từ các set lẻ
    int? calculatedSetsWon;
    if (sets != null && sets!.isNotEmpty && opponentSets != null && opponentSets!.isNotEmpty) {
      int count = 0;
      for (int i = 0; i < sets!.length; i++) {
        if (i < opponentSets!.length && sets![i] > opponentSets![i]) {
          count++;
        }
      }
      calculatedSetsWon = count;
    }

    final hasSetDetails = sets != null && sets!.isNotEmpty;
    // Nếu có điểm từng set thì số ở bên phải là số SET THẮNG (VD: 2 set), tránh lặp lại điểm set cuối
    final displayFinalScore = isBye
        ? ''
        : (hasSetDetails ? '${calculatedSetsWon ?? (isWinner ? 2 : 0)}' : '$score');

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

            const SizedBox(width: 4),

            // Per-set score boxes (được căn chỉnh độ rộng cố định, thẳng hàng tăm tắp)
            if (hasSetDetails)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(maxSetsCount > 0 ? maxSetsCount : sets!.length, (index) {
                  final s = (index < sets!.length) ? sets![index] : null;
                  return Container(
                    width: 22,
                    height: 18,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: s != null ? colors.bgSurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: s != null ? Border.all(color: colors.border) : null,
                    ),
                    child: Center(
                      child: Text(
                        s != null ? '$s' : '',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),

            const SizedBox(width: 6),

            // Total Score / Sets Won (Cột bên phải hiển thị số Set thắng lớn, gọn gàng)
            SizedBox(
              width: 18,
              child: Text(
                displayFinalScore,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isLive
                      ? colors.error
                      : isWinner
                          ? textColor
                          : colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
