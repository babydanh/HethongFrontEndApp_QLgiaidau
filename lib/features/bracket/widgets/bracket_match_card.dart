import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_detail.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_card_parts.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_score_entry_chooser.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';

/// Match card of the full-screen single / double elimination diagrams. Looks
/// like the cards of the paged board in the tab (header with code, court, LIVE
/// and time; tinted winner; "Miễn đấu" for a BYE side) and keeps what the
/// organizer needs here: tap / drag a side to move players, double tap to open
/// the match in operations.
class BracketMatchCard extends StatelessWidget {
  final MatchModel match;
  final String tournamentId;
  final bool isReferee;
  final bool isReadOnly;
  final bool canScoreMatch;
  final bool isSlotEditable;
  final BracketSlotDragData? selectedSlot;
  final ValueChanged<BracketSlotDragData>? onSlotTap;
  final BracketSlotDropCallback? onSlotDrop;
  final ValueChanged<MatchModel>? onDoubleTapMatch;

  const BracketMatchCard({
    super.key,
    required this.match,
    required this.tournamentId,
    required this.isReferee,
    required this.isReadOnly,
    this.canScoreMatch = false,
    this.isSlotEditable = false,
    this.selectedSlot,
    this.onSlotTap,
    this.onSlotDrop,
    this.onDoubleTapMatch,
  });

  void _onTap(BuildContext context) {
    if (canScoreMatch && match.hasTeams && !match.isBye) {
      MatchScoreEntryChooser.show(
        context,
        match: match,
        tournamentId: tournamentId,
      );
      return;
    }
    // A match card is a public/viewing entry point. Open the live match for
    // every tournament type, including Super Lite. The referee desk remains
    // available from the explicit scoring action in the detail view.
    if (match.isLive || match.isScheduled) {
      context.push(NavigationHelper.getLiveMatchRoute(tournamentId, match.id));
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

  /// "+12" / "-8" rating change of the team's player, once Elo was applied.
  String? _eloDelta(List<MatchMemberInfo> members) {
    if (!match.isCompleted ||
        match.eloStatus.toUpperCase() != 'APPLIED' ||
        match.eloDelta.isEmpty) {
      return null;
    }
    for (final member in members) {
      final userId = member.userId;
      if (userId == null || userId.isEmpty) continue;
      final delta = match.eloDelta[userId];
      if (delta != null) return '${delta > 0 ? '+' : ''}$delta';
    }
    return null;
  }

  Widget _buildSlotRow(BuildContext context, int side) {
    final l10n = AppLocalizations.of(context)!;
    final participantId = side == 1 ? match.team1Id : match.team2Id;
    final teamName = side == 1 ? match.team1Name : match.team2Name;
    final isBye = teamName == 'BYE' || participantId == 'BYE';
    final label = isBye
        ? l10n.bracketBye
        : participantLabel(
            teamName: matchSideTeamName(match, side),
            players: matchSidePlayers(match, side),
            teamOnly: isFootballMatch(match),
            abbreviated: true,
          );
    final dragData = BracketSlotDragData(
      matchId: match.id,
      slot: side == 1 ? 'participant1' : 'participant2',
      participantId: participantId,
      isBye: isBye,
      // Backend treats a BYE match as unplayed even though it is COMPLETED.
      isLocked: !match.isScheduled && !match.isBye,
      label: label,
    );
    final row = BracketSideRow(
      match: match,
      side: side,
      isBye: isBye,
      eloDelta: _eloDelta(
        side == 1 ? match.team1MemberInfos : match.team2MemberInfos,
      ),
    );
    if (!isSlotEditable || onSlotDrop == null || onSlotTap == null) return row;
    final isSelected = selectedSlot == dragData;
    final canDrag = dragData.hasParticipant && !dragData.isLocked;

    return DragTarget<BracketSlotDragData>(
      key: ValueKey('bracket-slot-${match.id}-${dragData.slot}'),
      onWillAcceptWithDetails: (details) =>
          bracketSlotOperation(details.data, dragData) != null,
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
            delay: bracketDragDelay,
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
                        label,
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
    return GestureDetector(
      onTap: isSlotEditable ? null : () => _onTap(context),
      onDoubleTap: onDoubleTapMatch == null
          ? null
          : () => onDoubleTapMatch!(match),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: match.isLive ? colors.error : colors.border,
          ),
        ),
        child: Column(
          children: [
            // The header opens the match (score / detail) even while the
            // sides below are busy with slot editing.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onTap(context),
              child: BracketCardHeader(match: match),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSlotRow(context, 1),
                  _buildSlotRow(context, 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
