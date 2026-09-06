import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Sport-tech match card — dùng cho cả 3 trạng thái: live / scheduled / completed
class LiveMatchCardV2 extends StatefulWidget {
  final MatchModel match;
  final bool isLive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const LiveMatchCardV2({
    super.key,
    required this.match,
    this.isLive = false,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  State<LiveMatchCardV2> createState() => _LiveMatchCardV2State();
}

class _LiveMatchCardV2State extends State<LiveMatchCardV2> {
  @override
  Widget build(BuildContext context) {
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardScore = widget.isLive
        ? widget.match.currentLiveScore
        : SetScore(score1: widget.match.score1, score2: widget.match.score2);

    final cardBorder = widget.isLive
        ? Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            width: 1.2,
          )
        : Border.all(color: colors.border.withValues(alpha: 0.6), width: 1);

    final cardShadow = widget.isLive
        ? [
            BoxShadow(
              color: const Color(
                0xFFEF4444,
              ).withValues(alpha: isDark ? 0.12 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: cardBorder,
              boxShadow: cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Status Bar ───
                if (widget.isLive) _buildLiveBar(context),
                if (widget.isCompleted) _buildCompletedBar(context),
                if (!widget.isLive && !widget.isCompleted)
                  _buildScheduledBar(context),

                // ─── Main Score Area ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Team 1
                      Expanded(
                        child: _buildTeamSide(
                          context,
                          teamName: widget.match.team1Name,
                          teamLogoUrl: widget.match.team1LogoUrl,
                          members: widget.match.team1MemberInfos,
                          score: cardScore.score1,
                          isWinner:
                              widget.isCompleted &&
                              widget.match.winnerId == widget.match.team1Id,
                          isLeading:
                              widget.isLive &&
                              cardScore.score1 > cardScore.score2,
                          alignment: CrossAxisAlignment.start,
                        ),
                      ),

                      // Central Score & VS Box
                      _buildCenterDivider(context, l10n),

                      // Team 2
                      Expanded(
                        child: _buildTeamSide(
                          context,
                          teamName: widget.match.team2Name,
                          teamLogoUrl: widget.match.team2LogoUrl,
                          members: widget.match.team2MemberInfos,
                          score: cardScore.score2,
                          isWinner:
                              widget.isCompleted &&
                              widget.match.winnerId == widget.match.team2Id,
                          isLeading:
                              widget.isLive &&
                              cardScore.score2 > cardScore.score1,
                          alignment: CrossAxisAlignment.end,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Set Scores (nếu có) ───
                if (widget.match.scoreHistory.isNotEmpty)
                  _buildSetScores(context),

                // ─── Bottom Info ───
                if (widget.match.scheduledTime != null ||
                    widget.match.refereeName != null)
                  _buildBottomInfo(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courtName = TournamentLocationFormatter.matchShortCourt(
      widget.match.court,
    );
    final roundName = MatchRoundLabel.formatRound(
      match: widget.match,
      short: true,
      l10n: l10n,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF450A0A).withValues(alpha: 0.4)
            : const Color(0xFFFEF2F2),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                : const Color(0xFFFEE2E2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Live Pulse Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                      width: 5.5,
                      height: 5.5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.7, end: 1.25, duration: 750.ms),
                const SizedBox(width: 5),
                Text(
                  l10n.matchLiveStatus.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (roundName.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              roundName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colors.textSecondary,
              ),
            ),
          ],
          const Spacer(),
          if (courtName.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: context.colors.border.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 11,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    courtName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (widget.match.maxScore != null)
            Text(
              l10n.liveMatchMaxScore(widget.match.maxScore!),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final courtName = TournamentLocationFormatter.matchShortCourt(
      widget.match.court,
    );
    final roundName = MatchRoundLabel.formatRound(
      match: widget.match,
      short: true,
      l10n: l10n,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: colors.success.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 11,
                  color: colors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.liveMatchCompletedStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: colors.success,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          if (roundName.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              roundName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
          const Spacer(),
          if (courtName.isNotEmpty)
            Text(
              courtName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduledBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final roundName = MatchRoundLabel.formatRound(
      match: widget.match,
      short: true,
      l10n: l10n,
    );
    final courtName = TournamentLocationFormatter.matchShortCourt(
      widget.match.court,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: colors.textMuted),
          const SizedBox(width: 5),
          Text(
            l10n.liveMatchScheduledStatus.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: colors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          if (roundName.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '•  $roundName',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
          ],
          const Spacer(),
          if (courtName.isNotEmpty)
            Text(
              courtName,
              style: TextStyle(fontSize: 10, color: colors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterDivider(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Text(
              l10n.matchVsLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSide(
    BuildContext context, {
    required String teamName,
    required String? teamLogoUrl,
    required List<MatchMemberInfo> members,
    required int score,
    required bool isWinner,
    required bool isLeading,
    required CrossAxisAlignment alignment,
  }) {
    final colors = context.colors;
    final memberLabel = members.length == 2
        ? members
              .map((member) => _lastNameWord(member.fullName))
              .where((name) => name.isNotEmpty)
              .join(' / ')
        : '';
    final displayLabel = members.length == 2 && memberLabel.isNotEmpty
        ? memberLabel
        : teamName;

    final scoreColor = widget.isLive
        ? (isLeading ? const Color(0xFFDC2626) : colors.textPrimary)
        : (isWinner ? colors.success : colors.textPrimary);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        _buildMemberAvatars(
          context,
          teamName: teamName,
          teamLogoUrl: teamLogoUrl,
          members: members,
          isWinner: isWinner,
          isLeading: isLeading,
          alignment: alignment,
        ),
        const SizedBox(height: 8),
        Text(
          displayLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isWinner || isLeading
                ? FontWeight.w800
                : FontWeight.w600,
            color: isWinner
                ? colors.success
                : (isLeading ? const Color(0xFFDC2626) : colors.textPrimary),
            height: 1.25,
          ),
          textAlign: alignment == CrossAxisAlignment.start
              ? TextAlign.left
              : TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // Score typography with tabular numbers
        Text(
          '$score',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: scoreColor,
            height: 1.05,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAvatars(
    BuildContext context, {
    required String teamName,
    required String? teamLogoUrl,
    required List<MatchMemberInfo> members,
    required bool isWinner,
    required bool isLeading,
    required CrossAxisAlignment alignment,
  }) {
    final colors = context.colors;
    final displayMembers = members.length == 2
        ? members
        : const <MatchMemberInfo>[];

    final borderColor = isWinner
        ? colors.success
        : (isLeading ? const Color(0xFFEF4444) : colors.border);

    final fallbackInitial = teamName.isNotEmpty
        ? teamName[0].toUpperCase()
        : '?';

    Widget avatar({String? url, required String initial}) {
      return Container(
        width: displayMembers.length >= 2 ? 34 : 38,
        height: displayMembers.length >= 2 ? 34 : 38,
        decoration: BoxDecoration(
          color: colors.bgSurface,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: isWinner || isLeading ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: url != null && url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover)
            : Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isWinner
                        ? colors.success
                        : (isLeading
                              ? const Color(0xFFDC2626)
                              : colors.textPrimary),
                  ),
                ),
              ),
      );
    }

    if (displayMembers.length == 2) {
      final m1 = displayMembers[0];
      final m2 = displayMembers[1];
      return SizedBox(
        width: 56,
        height: 34,
        child: Stack(
          alignment: alignment == CrossAxisAlignment.start
              ? Alignment.centerLeft
              : Alignment.centerRight,
          children: [
            Positioned(
              left: alignment == CrossAxisAlignment.start ? 0 : null,
              right: alignment == CrossAxisAlignment.end ? 0 : null,
              child: avatar(
                url: m1.avatarUrl,
                initial: m1.fullName.isNotEmpty
                    ? m1.fullName[0].toUpperCase()
                    : '?',
              ),
            ),
            Positioned(
              left: alignment == CrossAxisAlignment.start ? 20 : null,
              right: alignment == CrossAxisAlignment.end ? 20 : null,
              child: avatar(
                url: m2.avatarUrl,
                initial: m2.fullName.isNotEmpty
                    ? m2.fullName[0].toUpperCase()
                    : '?',
              ),
            ),
          ],
        ),
      );
    }

    return avatar(url: teamLogoUrl, initial: fallbackInitial);
  }

  Widget _buildSetScores(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.4)),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          for (int i = 0; i < widget.match.scoreHistory.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Text(
                'S${i + 1}: ${widget.match.scoreHistory[i].score1} - ${widget.match.scoreHistory[i].score2}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomInfo(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.match.scheduledTime != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.match.scheduledTime!.hour.toString().padLeft(2, '0')}:${widget.match.scheduledTime!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          if (widget.match.refereeName != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_rounded, size: 12, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'TT: ${widget.match.refereeName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  String _lastNameWord(String fullName) {
    final words = fullName.trim().split(' ');
    return words.isNotEmpty ? words.last : fullName;
  }
}
