import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_detail.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/team_row.dart';

/// Unified bracket match card used in both single-elim and double-elim diagrams.
/// Replaces the former _BracketMatchCard (single_elim_diagram) and _DeBracketMatchCard (double_elim_diagram).
class BracketMatchCard extends StatelessWidget {
  final MatchModel match;
  final String tournamentId;
  final bool isReferee;
  final bool isReadOnly;
  final bool isGrandFinal;

  const BracketMatchCard({
    super.key,
    required this.match,
    required this.tournamentId,
    required this.isReferee,
    required this.isReadOnly,
    this.isGrandFinal = false,
  });

  void _onTap(BuildContext context) {
    if ((isReferee || !isReadOnly) && (match.isLive || match.isScheduled)) {
      context.push('/live/${match.id}');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 320,
          child: MatchCardDetail(
            match: match,
            isReferee: isReferee,
            isReadOnly: isReadOnly,
            tournamentId: tournamentId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBye1 = match.team1Name == 'BYE' || match.team1Id == 'BYE';
    final isBye2 = match.team2Name == 'BYE' || match.team2Id == 'BYE';

    final isFinal = isGrandFinal || match.nextMatchId.isEmpty;
    final isGrandFinalWinner = isFinal && match.isCompleted;

    Color statusColor = colors.textMuted;
    String statusLabel = 'SẮP ĐẤU';
    Color borderColor = colors.border;
    Color cardBgColor = colors.bgCard;

    if (match.isLive) {
      statusColor = colors.error;
      statusLabel = 'LIVE';
      borderColor = colors.error.withValues(alpha: 0.5);
      cardBgColor = colors.error.withValues(alpha: 0.06);
    } else if (match.isCompleted) {
      statusColor = colors.success;
      statusLabel = 'XONG';
    }

    if (isGrandFinalWinner) {
      borderColor = colors.warning;
      cardBgColor = colors.warning.withValues(alpha: 0.15);
      statusColor = colors.warning;
      statusLabel = 'VÔ ĐỊCH';
    }

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isGrandFinalWinner ? 2.0 : 1.0),
          boxShadow: [
            BoxShadow(
              color: isGrandFinalWinner
                  ? colors.warning.withValues(alpha: 0.2)
                  : colors.textPrimary.withValues(alpha: 0.06),
              blurRadius: isGrandFinalWinner ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Team 1 ──
            Expanded(
              child: TeamRow(
                name: isBye1 ? 'Miễn đấu' : match.team1Name,
                score: match.score1,
                sets: match.sets.isNotEmpty
                    ? match.sets.map((s) => s.score1).toList()
                    : null,
                isWinner: match.isCompleted && match.winnerId == match.team1Id,
                isLive: match.isLive,
                isBye: isBye1,
                isGrandFinalWinner: isGrandFinalWinner,
              ),
            ),
            Divider(height: 1, thickness: 1, color: colors.border),
            // ── Team 2 ──
            Expanded(
              child: TeamRow(
                name: isBye2 ? 'Miễn đấu' : match.team2Name,
                score: match.score2,
                sets: match.sets.isNotEmpty
                    ? match.sets.map((s) => s.score2).toList()
                    : null,
                isWinner: match.isCompleted && match.winnerId == match.team2Id,
                isLive: match.isLive,
                isBye: isBye2,
                isGrandFinalWinner: isGrandFinalWinner,
              ),
            ),
            // ── Footer: status + action ──
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: isGrandFinalWinner
                    ? colors.warning.withValues(alpha: 0.15)
                    : colors.bgSurface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if ((isReferee || !isReadOnly) && match.isLive)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Tính điểm →',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: colors.error,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Xem →',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isGrandFinalWinner
                                ? colors.warning
                                : colors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
