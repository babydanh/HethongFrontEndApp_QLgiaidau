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

class _LiveMatchCardV2State extends State<LiveMatchCardV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _hasLiveAnim = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLive) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _pulseAnim = Tween<double>(
        begin: 0.85,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
      _hasLiveAnim = true;
    }
  }

  @override
  void dispose() {
    if (_hasLiveAnim) _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    // Team 1
                    Expanded(
                      child: _buildTeamSide(
                        context,
                        teamName: widget.match.team1Name,
                        teamLogoUrl: widget.match.team1LogoUrl,
                        members: widget.match.team1MemberInfos,
                        score: widget.match.score1,
                        isWinner:
                            widget.isCompleted &&
                            widget.match.winnerId == widget.match.team1Id,
                        alignment: CrossAxisAlignment.start,
                      ),
                    ),

                    // VS Divider
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.matchVsLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MatchRoundLabel.formatRound(
                            match: widget.match,
                            short: true,
                            l10n: l10n,
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textMuted,
                          ),
                        ),
                        if (TournamentLocationFormatter.matchShortCourt(widget.match.court).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            TournamentLocationFormatter.matchShortCourt(widget.match.court),
                            style: TextStyle(
                              fontSize: 9,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Team 2
                    Expanded(
                      child: _buildTeamSide(
                        context,
                        teamName: widget.match.team2Name,
                        teamLogoUrl: widget.match.team2LogoUrl,
                        members: widget.match.team2MemberInfos,
                        score: widget.match.score2,
                        isWinner:
                            widget.isCompleted &&
                            widget.match.winnerId == widget.match.team2Id,
                        alignment: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Set Scores (nếu có) ───
              if (widget.match.sets.isNotEmpty) _buildSetScores(context),

              // ─── Bottom Info ───
              if (widget.match.scheduledTime != null ||
                  widget.match.refereeName != null)
                _buildBottomInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFEE2E2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.7, end: 1.1, duration: 800.ms),
                const SizedBox(width: 4),
                Text(
                  l10n.matchLiveStatus,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (widget.match.maxScore != null)
            Text(
              l10n.liveMatchMaxScore(widget.match.maxScore!),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.success,
            context.colors.success.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            l10n.liveMatchCompletedStatus,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 11,
            color: context.colors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.liveMatchScheduledStatus,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.colors.textMuted,
              letterSpacing: 1.5,
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
    required CrossAxisAlignment alignment,
  }) {
    final memberLabel = members.length == 2
        ? members
            .map((member) => _lastNameWord(member.fullName))
            .where((name) => name.isNotEmpty)
            .join(' / ')
        : '';
    final displayLabel = members.length == 2 && memberLabel.isNotEmpty
        ? memberLabel
        : teamName;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        _buildMemberAvatars(
          context,
          teamName: teamName,
          teamLogoUrl: teamLogoUrl,
          members: members,
          isWinner: isWinner,
          alignment: alignment,
        ),
        const SizedBox(height: 8),
        // Singles keep the team name; doubles show each member's final name word.
        Text(
          displayLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            color: isWinner
                ? context.colors.success
                : context.colors.textPrimary,
          ),
          textAlign: alignment == CrossAxisAlignment.start
              ? TextAlign.left
              : TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // Score
        Text(
          '$score',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: widget.isLive
                ? context.colors.textPrimary
                : isWinner
                ? context.colors.success
                : context.colors.textPrimary,
            height: 1.1,
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
    required CrossAxisAlignment alignment,
  }) {
    final displayMembers = members.length == 2
        ? members
        : const <MatchMemberInfo>[];
    final borderColor = isWinner ? context.colors.success : context.colors.border;
    final fallbackInitial = teamName.isNotEmpty ? teamName[0].toUpperCase() : '?';

    Widget avatar({String? url, required String initial}) {
      return Container(
        width: displayMembers.length >= 2 ? 32 : 36,
        height: displayMembers.length >= 2 ? 32 : 36,
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isWinner ? 2 : 1),
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
                        ? context.colors.success
                        : context.colors.textPrimary,
                  ),
                ),
              ),
      );
    }

    if (displayMembers.length == 2) {
      final m1 = displayMembers[0];
      final m2 = displayMembers[1];
      return SizedBox(
        width: 52,
        height: 32,
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
                initial: m1.fullName.isNotEmpty ? m1.fullName[0].toUpperCase() : '?',
              ),
            ),
            Positioned(
              left: alignment == CrossAxisAlignment.start ? 20 : null,
              right: alignment == CrossAxisAlignment.end ? 20 : null,
              child: avatar(
                url: m2.avatarUrl,
                initial: m2.fullName.isNotEmpty ? m2.fullName[0].toUpperCase() : '?',
              ),
            ),
          ],
        ),
      );
    }

    return avatar(
      url: teamLogoUrl,
      initial: fallbackInitial,
    );
  }

  Widget _buildSetScores(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(
          top: BorderSide(
            color: context.colors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < widget.match.sets.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.bgCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: context.colors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'S${i + 1}: ${widget.match.sets[i].score1}-${widget.match.sets[i].score2}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.match.scheduledTime != null)
            Text(
              '${widget.match.scheduledTime!.hour.toString().padLeft(2, '0')}:${widget.match.scheduledTime!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textMuted,
              ),
            )
          else
            const SizedBox.shrink(),
          if (widget.match.refereeName != null)
            Text(
              'TT: ${widget.match.refereeName}',
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textMuted,
              ),
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
