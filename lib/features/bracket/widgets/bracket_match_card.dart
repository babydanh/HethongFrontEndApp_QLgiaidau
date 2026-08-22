import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_detail.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/team_row.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Unified bracket match card used in both single-elim and double-elim diagrams.
/// Replaces the former _BracketMatchCard (single_elim_diagram) and _DeBracketMatchCard (double_elim_diagram).
class BracketMatchCard extends StatelessWidget {
  final MatchModel match;
  final String tournamentId;
  final bool isReferee;
  final bool isReadOnly;
  final bool isGrandFinal;
  final bool isSlotEditable;
  final BracketSlotDragData? selectedSlot;
  final ValueChanged<BracketSlotDragData>? onSlotTap;
  final BracketSlotDropCallback? onSlotDrop;

  const BracketMatchCard({
    super.key,
    required this.match,
    required this.tournamentId,
    required this.isReferee,
    required this.isReadOnly,
    this.isGrandFinal = false,
    this.isSlotEditable = false,
    this.selectedSlot,
    this.onSlotTap,
    this.onSlotDrop,
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
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SizedBox(
            width: 320,
            child: MatchCardDetail(
              match: match,
              isReferee: isReferee,
              isReadOnly: isReadOnly,
              tournamentId: tournamentId,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotRow({
    required BuildContext context,
    required String name,
    required String? logoUrl,
    required int score,
    required List<int>? sets,
    required List<int>? opponentSets,
    required int maxSetsCount,
    required bool isWinner,
    required bool isLive,
    required bool isBye,
    required bool isGrandFinalWinner,
    required String slot,
    required String participantId,
  }) {
    final row = TeamRow(
      name: name,
      logoUrl: logoUrl,
      score: score,
      sets: sets,
      opponentSets: opponentSets,
      maxSetsCount: maxSetsCount,
      isWinner: isWinner,
      isLive: isLive,
      isBye: isBye,
      isGrandFinalWinner: isGrandFinalWinner,
    );
    if (!isSlotEditable || onSlotDrop == null || onSlotTap == null) return row;

    final dragData = BracketSlotDragData(
      matchId: match.id,
      slot: slot,
      participantId: participantId,
      isBye: isBye,
    );
    final isSelected = selectedSlot == dragData;
    final canDrag = dragData.hasParticipant;

    return DragTarget<BracketSlotDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data != dragData &&
          details.data.hasParticipant &&
          !dragData.isBye,
      onAcceptWithDetails: (details) => onSlotDrop!(details.data, dragData),
      builder: (context, candidates, rejected) {
        final isDropTarget = candidates.isNotEmpty;
        final colors = context.colors;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: isDropTarget
                ? AppTheme.primary.withValues(alpha: 0.14)
                : isSelected
                ? AppTheme.primary.withValues(alpha: 0.09)
                : null,
            border: Border.all(
              color: isDropTarget || isSelected
                  ? AppTheme.primary
                  : Colors.transparent,
              width: isDropTarget || isSelected ? 1.5 : 0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: LongPressDraggable<BracketSlotDragData>(
            data: dragData,
            maxSimultaneousDrags: canDrag ? 1 : 0,
            feedback: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(
                  width: 220,
                  height: 40,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary, width: 1.5),
                    boxShadow: const [
                      BoxShadow(blurRadius: 12, color: Colors.black26),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.38, child: row),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canDrag || dragData.canReceiveMove
                  ? () => onSlotTap!(dragData)
                  : null,
              child: row,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isBye1 = match.team1Name == 'BYE' || match.team1Id == 'BYE';
    final isBye2 = match.team2Name == 'BYE' || match.team2Id == 'BYE';

    final isFinal = isGrandFinal || match.nextMatchId.isEmpty;
    final isGrandFinalWinner = isFinal && match.isCompleted;

    Color statusColor = colors.textMuted;
    String statusLabel = l10n.bracketStatusUpcoming;
    Color borderColor = colors.border;
    Color cardBgColor = colors.bgCard;

    if (match.isLive) {
      statusColor = colors.error;
      statusLabel = l10n.bracketStatusLive;
      borderColor = colors.error.withValues(alpha: 0.5);
      cardBgColor = colors.error.withValues(alpha: 0.06);
    } else if (match.isCompleted) {
      statusColor = colors.success;
      statusLabel = l10n.bracketStatusCompleted;
    }

    if (isGrandFinalWinner) {
      borderColor = colors.warning;
      cardBgColor = colors.warning.withValues(alpha: 0.15);
      statusColor = colors.warning;
      statusLabel = l10n.bracketStatusChampion;
    }

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isGrandFinalWinner ? 2.0 : 1.0,
          ),
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
              child: _buildSlotRow(
                context: context,
                name: isBye1 ? l10n.bracketBye : match.team1Name,
                logoUrl: isBye1 ? null : match.team1LogoUrl,
                score: match.score1,
                sets: match.sets.isNotEmpty
                    ? match.sets.map((s) => s.score1).toList()
                    : null,
                opponentSets: match.sets.isNotEmpty
                    ? match.sets.map((s) => s.score2).toList()
                    : null,
                maxSetsCount: match.sets.length,
                isWinner: match.isCompleted && match.winnerId == match.team1Id,
                isLive: match.isLive,
                isBye: isBye1,
                isGrandFinalWinner: isGrandFinalWinner,
                slot: 'participant1',
                participantId: match.team1Id,
              ),
            ),
            Divider(height: 1, thickness: 1, color: colors.border),
            // ── Team 2 ──
            Expanded(
              child: _buildSlotRow(
                context: context,
                name: isBye2 ? l10n.bracketBye : match.team2Name,
                logoUrl: isBye2 ? null : match.team2LogoUrl,
                score: match.score2,
                sets: match.sets.isNotEmpty
                    ? match.sets.map((s) => s.score2).toList()
                    : null,
                opponentSets: match.sets.isNotEmpty
                    ? match.sets.map((s) => s.score1).toList()
                    : null,
                maxSetsCount: match.sets.length,
                isWinner: match.isCompleted && match.winnerId == match.team2Id,
                isLive: match.isLive,
                isBye: isBye2,
                isGrandFinalWinner: isGrandFinalWinner,
                slot: 'participant2',
                participantId: match.team2Id,
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
                        l10n.bracketScoreAction,
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
                        l10n.bracketViewAction,
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
