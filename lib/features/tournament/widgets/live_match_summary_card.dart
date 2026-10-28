import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _liveRed = Color(0xFFE11D48);
const _scoreColumnMaxWidth = 120.0;

/// Compact card for a match that is being played right now: pulsing red dot,
/// round, optional match code, both sides, the open set score with the set
/// history, and "time · court". The whole card opens the live room; [onScore]
/// (organisers only) adds a single score-entry button.
class LiveMatchSummaryCard extends StatelessWidget {
  const LiveMatchSummaryCard({
    super.key,
    required this.match,
    required this.roundLabel,
    required this.onTap,
    this.matchCode,
    this.onScore,
  });

  final MatchModel match;
  final String roundLabel;
  final VoidCallback onTap;

  /// Display code such as `#V1602`; hidden when null or blank.
  final String? matchCode;

  /// Null hides the score-entry button (everyone except organisers).
  final VoidCallback? onScore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 3,
                width: double.infinity,
                child: ColoredBox(color: _liveRed),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header(context),
                    const SizedBox(height: 8),
                    _body(context),
                    _footer(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final colors = context.colors;
    final code = matchCode?.trim() ?? '';
    return Row(
      children: [
        const _PulsingDot(),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            roundLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        const Spacer(),
        if (code.isNotEmpty)
          Text(
            code,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final colors = context.colors;
    final current = match.currentLiveScore;
    final history = match.scoreHistory;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _side(context, 1, CrossAxisAlignment.start)),
          // Capped so the set chips wrap instead of squeezing the names.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _scoreColumnMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${current.score1} - ${current.score2}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: _liveRed,
                    ),
                  ),
                  if (history.length > 1) ...[
                    const SizedBox(height: 6),
                    _setChips(context, history),
                  ],
                ],
              ),
            ),
          ),
          Expanded(child: _side(context, 2, CrossAxisAlignment.end)),
        ],
      ),
    );
  }

  Widget _side(BuildContext context, int side, CrossAxisAlignment align) {
    return ParticipantLabel(
      teamName: matchSideTeamName(match, side),
      players: matchSidePlayers(match, side),
      teamOnly: isFootballMatch(match),
      compact: true,
      crossAxisAlignment: align,
      textAlign: align == CrossAxisAlignment.end
          ? TextAlign.end
          : TextAlign.start,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.colors.textPrimary,
      ),
    );
  }

  Widget _setChips(BuildContext context, List<SetScore> history) {
    final colors = context.colors;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < history.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: i == history.length - 1
                  ? _liveRed.withValues(alpha: 0.12)
                  : colors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${history[i].score1}-${history[i].score2}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: i == history.length - 1
                    ? _liveRed
                    : colors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    final colors = context.colors;
    final info = _timeAndCourt();
    // Only reserve the tall row when the score button needs the tap target.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: onScore != null ? 40 : 28),
      child: Row(
        children: [
          if (info.isNotEmpty) ...[
            Icon(Icons.schedule_rounded, size: 14, color: colors.textMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                info,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onScore != null)
            IconButton(
              onPressed: onScore,
              tooltip: AppLocalizations.of(context)!.resultsBoard_enterScore,
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: colors.textPrimary,
              ),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
        ],
      ),
    );
  }

  /// "08:40 · Sân 3" with only the parts that exist.
  String _timeAndCourt() {
    final time = match.scheduledTime;
    final court = TournamentLocationFormatter.matchShortCourt(
      match.court.isNotEmpty ? match.court : match.courtName,
    );
    return [
      if (time != null) DateFormat('HH:mm').format(time.toLocal()),
      if (court.isNotEmpty) court,
    ].join(' · ');
  }
}

/// Red dot that pulses; static when the platform asks to reduce motion.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(_controller),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: _liveRed,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
