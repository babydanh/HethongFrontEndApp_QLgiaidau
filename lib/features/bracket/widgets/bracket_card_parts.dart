import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_match_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pieces of one bracket match card, shared by the paged board in the tab and
/// the full-screen diagram so both look the same.

/// Cap for the LIVE tag + time on the card header so the code keeps its room.
const double _headerRightMaxWidth = 96;

/// Score of [side] per set. Unlike the finished-only group lines it also
/// returns the sets of a live match, so the card can show the running score.
List<String> bracketSideScores(MatchModel match, int side) {
  if (!isFootballMatch(match) && match.sets.isNotEmpty) {
    return [for (final s in match.sets) '${side == 1 ? s.score1 : s.score2}'];
  }
  return groupSideScores(match, side);
}

/// Width of one score cell; narrower once a match runs past three sets so the
/// names keep their room.
double bracketScoreCellWidth(int cells) => cells > 3 ? 16 : 20;

/// Match code, or "#number" when the backend gave none.
String bracketMatchCode(MatchModel match) {
  final code = (match.matchCode ?? '').trim();
  return code.isEmpty ? '#${match.matchNumber}' : code;
}

/// "TK01 · Sân 2" on the left, a LIVE tag and "09:30 08/11" on the right.
class BracketCardHeader extends StatelessWidget {
  const BracketCardHeader({super.key, required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = groupMatchStatus(context, match);
    final court = (match.courtName ?? '').trim();
    final time = match.scheduledTime;
    final timeText = time == null
        ? ''
        : DateFormat('HH:mm dd/MM').format(time.toLocal());
    final muted = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: colors.textMuted,
    );
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: bracketMatchCode(match),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if (court.isNotEmpty) TextSpan(text: ' · $court'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ),
        if (match.isLive || timeText.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _headerRightMaxWidth),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (match.isLive) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: status.color,
                      ),
                    ),
                  ],
                  if (timeText.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(timeText, style: muted),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One side of a match: the team / players, then the score per set. The winner
/// of a finished match gets a soft primary tint, a bold name with a tick and a
/// primary score. An empty side reads "Miễn đấu" (BYE match) or "N/A".
class BracketSideRow extends StatelessWidget {
  const BracketSideRow({
    super.key,
    required this.match,
    required this.side,
    this.isBye = false,
    this.placeholder,
    this.eloDelta,
  });

  final MatchModel match;

  /// 1 or 2.
  final int side;

  /// This side is a BYE slot even though the match carries a "BYE" name.
  final bool isBye;

  /// Shown instead of "N/A" on an empty, non-BYE side (the seed label).
  final Widget? placeholder;

  /// "+12" / "-8" rating change, shown after the name when set.
  final String? eloDelta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final teamName = isBye ? null : matchSideTeamName(match, side);
    final players = isBye
        ? const <ParticipantPlayer>[]
        : matchSidePlayers(match, side);
    final won =
        match.isCompleted &&
        match.winnerId.isNotEmpty &&
        match.winnerId == (side == 1 ? match.team1Id : match.team2Id);
    final scores = bracketSideScores(match, side);
    final empty = teamName == null && players.isEmpty;
    final waiting = match.isBye || isBye
        ? l10n.bracketBye
        : l10n.playoff_slotNA;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: won ? AppTheme.primary.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: empty
                  ? (placeholder ??
                        Text(
                          waiting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textMuted,
                          ),
                        ))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ParticipantSideLines(
                            teamName: teamName,
                            players: players,
                            teamOnly: isFootballMatch(match),
                            won: won,
                          ),
                        ),
                        if (eloDelta != null) _EloChip(delta: eloDelta!),
                      ],
                    ),
            ),
          ),
          for (final score in scores)
            SizedBox(
              width: bracketScoreCellWidth(scores.length),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  score,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: won ? FontWeight.w900 : FontWeight.w700,
                    color: won ? AppTheme.primary : colors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EloChip extends StatelessWidget {
  const _EloChip({required this.delta});

  final String delta;

  @override
  Widget build(BuildContext context) {
    final negative = delta.startsWith('-');
    final color = negative ? const Color(0xFFDC2626) : const Color(0xFF059669);
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: 0.28), width: 0.6),
        ),
        child: Text(
          delta,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: color,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
