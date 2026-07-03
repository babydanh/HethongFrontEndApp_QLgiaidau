import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

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
      _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
      );
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
    final card = _buildCard(context);
    if (widget.isLive) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnim.value,
          child: child,
        ),
        child: card,
      );
    }
    return card;
  }

  Widget _buildCard(BuildContext context) {
    final borderColor = widget.isLive
        ? context.colors.error
        : widget.isCompleted
            ? context.colors.success
            : context.colors.border;
    final borderWidth = widget.isLive ? 2.0 : 1.0;
    final glowColor = widget.isLive
        ? context.colors.error.withValues(alpha: 0.15)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
                        score: widget.match.score1,
                        isWinner: widget.isCompleted &&
                            widget.match.winnerId == widget.match.team1Id,
                        alignment: CrossAxisAlignment.start,
                      ),
                    ),

                    // VS Divider
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'V${widget.match.round}',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.textMuted,
                          ),
                        ),
                        if (widget.match.court.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.match.court,
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
                        score: widget.match.score2,
                        isWinner: widget.isCompleted &&
                            widget.match.winnerId == widget.match.team2Id,
                        alignment: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Set Scores (nếu có) ───
              if (widget.match.sets.isNotEmpty)
                _buildSetScores(context),

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        gradient: context.liveGradient,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 800.ms,
                color: Colors.white.withValues(alpha: 0.3),
              ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          if (widget.match.maxScore != null) ...[
            const SizedBox(width: 12),
            Text(
              'Điểm tối đa: ${widget.match.maxScore}',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedBar(BuildContext context) {
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
            'HOÀN THÀNH',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(
          bottom: BorderSide(color: context.colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded, size: 11, color: context.colors.textMuted),
          const SizedBox(width: 6),
          Text(
            'SẮP DIỄN RA',
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
    required int score,
    required bool isWinner,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        // Team avatar circle
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isWinner
                  ? context.colors.success
                  : context.colors.border,
              width: isWinner ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isWinner
                    ? context.colors.success
                    : context.colors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Team name
        Text(
          teamName,
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

  Widget _buildSetScores(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.match.sets.map((set) {
          final isSet1Winner = set.score1 > set.score2;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${set.score1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSet1Winner ? FontWeight.w800 : FontWeight.w500,
                    color: isSet1Winner
                        ? context.colors.success
                        : context.colors.textSecondary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '-',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
                Text(
                  '${set.score2}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        !isSet1Winner ? FontWeight.w800 : FontWeight.w500,
                    color: !isSet1Winner
                        ? context.colors.success
                        : context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          if (widget.match.refereeName != null &&
              widget.match.refereeName!.isNotEmpty) ...[
            Icon(Icons.person_outline_rounded,
                size: 12, color: context.colors.textMuted),
            const SizedBox(width: 4),
            Text(
              widget.match.refereeName!,
              style: TextStyle(
                fontSize: 10,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (widget.match.scheduledTime != null) ...[
            Icon(Icons.access_time_rounded,
                size: 12, color: context.colors.textMuted),
            const SizedBox(width: 4),
            Text(
              '${widget.match.scheduledTime!.hour.toString().padLeft(2, '0')}:${widget.match.scheduledTime!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: context.colors.textMuted,
              ),
            ),
          ],
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: context.colors.textMuted),
        ],
      ),
    );
  }
}
