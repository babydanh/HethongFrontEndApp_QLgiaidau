import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TournamentTeamCard extends StatefulWidget {
  final Team team;
  final bool isTeamSport;
  final Function(String? userId, String memberName)? onMemberTap;
  final bool showSeed;

  const TournamentTeamCard({
    super.key,
    required this.team,
    this.isTeamSport = false,
    this.onMemberTap,
    this.showSeed = false,
  });

  @override
  State<TournamentTeamCard> createState() => _TournamentTeamCardState();
}

class _TournamentTeamCardState extends State<TournamentTeamCard> {
  bool _isExpanded = false;

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Thông tin roster (elo, hạng) của VĐV, khớp theo userId; khách không có userId.
  MatchMemberInfo? _memberInfoFor(ParticipantPlayer player) {
    final userId = player.userId;
    if (userId == null) return null;
    for (final info in widget.team.memberInfos) {
      if (info.userId == userId) return info;
    }
    return null;
  }

  Future<void> _revealExpandedRow() async {
    if (!mounted || !_isExpanded) return;
    await Scrollable.ensureVisible(
      context,
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: 0.35,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final team = widget.team;

    // Đơn/đôi theo số VĐV (players[]); không suy từ tên đội hay isTeamSport.
    final players = team.players;
    final isDoubles = players.length > 1;
    final memberNames = players.map((p) => p.fullName).toList();

    final seedLabel = widget.showSeed && team.seed > 0
        ? '${l10n.seedLabel} #${team.seed}'
        : null;

    if (!isDoubles) {
      // ── SINGLES (ĐƠN) LAYOUT: DIRECT PROFILE TAP, NO EXPANSION ──
      final singlePlayer = players.isNotEmpty ? players.first : null;
      final singleDisplay = resolveParticipantDisplay(
        teamName: team.name,
        players: players,
        teamOnly: widget.isTeamSport,
      );
      final singleInfo = singlePlayer == null
          ? null
          : _memberInfoFor(singlePlayer);
      final effectiveUserId = singlePlayer?.userId ?? team.userId;
      final eloVal = singleInfo?.eloPoints ?? team.eloPoints ?? 1200;
      final eloStr = '${l10n.eloLabel} $eloVal';

      return Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.border.withValues(alpha: 0.45)),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              widget.onMemberTap?.call(
                effectiveUserId,
                singlePlayer?.fullName ?? '',
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 2),

                  // Singles rows represent a real participant. Show the
                  // roster avatar when the API provides it, falling back to
                  // initials only when the profile has no image.
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                    child: singlePlayer?.avatarUrl?.isNotEmpty == true
                        ? ClipOval(
                            child: Image.network(
                              singlePlayer!.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 36,
                              height: 36,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    _getInitials(singlePlayer.fullName),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                            ),
                          )
                        : Text(
                            _getInitials(singlePlayer?.fullName ?? ''),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Athlete Name + Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (singleDisplay.isTeam)
                          ParticipantLabel(
                            teamName: team.name,
                            players: players,
                            teamOnly: widget.isTeamSport,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          )
                        else
                          Text(
                            singleDisplay.players.isEmpty
                                ? l10n.matchNotDetermined
                                : singleDisplay.players.first.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFBAE6FD),
                                ),
                              ),
                              child: Text(
                                eloStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                            if (seedLabel != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: Text(
                                  seedLabel,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Tooltip(
                              message: team.isPaid
                                  ? 'Đã đóng phí'
                                  : 'Chờ thanh toán',
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: team.isPaid
                                      ? const Color(
                                          0xFF059669,
                                        ).withValues(alpha: 0.12)
                                      : const Color(
                                          0xFFD97706,
                                        ).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: team.isPaid
                                        ? const Color(
                                            0xFF059669,
                                          ).withValues(alpha: 0.4)
                                        : const Color(
                                            0xFFD97706,
                                          ).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Icon(
                                  team.isPaid
                                      ? Icons.check_circle_rounded
                                      : Icons.access_time_rounded,
                                  size: 13,
                                  color: team.isPaid
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chevron right profile indicator
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── DOUBLES (ĐÔI) LAYOUT: INLINE EXPANSION ACCORDION ──
    final headerDisplay = resolveParticipantDisplay(
      teamName: team.name,
      players: players,
      teamOnly: widget.isTeamSport,
    );
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13.5,
      color: colors.textPrimary,
      letterSpacing: -0.2,
    );
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.45)),
        ),
      ),
      child: Column(
        children: [
          // Header Row: Team Name + Expand Toggle
          Semantics(
            button: true,
            expanded: _isExpanded,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 2),

                      // Team Name & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: headerDisplay.isTeam
                                      ? ParticipantLabel(
                                          teamName: team.name,
                                          players: players,
                                          teamOnly: widget.isTeamSport,
                                          style: headerStyle,
                                        )
                                      : Text(
                                          players.isEmpty
                                              ? l10n.matchNotDetermined
                                              : participantLabel(
                                                  teamName: null,
                                                  players: players,
                                                ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: headerStyle,
                                        ),
                                ),
                                if (seedLabel != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFBFDBFE),
                                      ),
                                    ),
                                    child: Text(
                                      seedLabel,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: team.isPaid
                                      ? 'Đã đóng phí'
                                      : 'Chờ thanh toán',
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: team.isPaid
                                          ? const Color(
                                              0xFF059669,
                                            ).withValues(alpha: 0.12)
                                          : const Color(
                                              0xFFD97706,
                                            ).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: team.isPaid
                                            ? const Color(
                                                0xFF059669,
                                              ).withValues(alpha: 0.4)
                                            : const Color(
                                                0xFFD97706,
                                              ).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Icon(
                                      team.isPaid
                                          ? Icons.check_circle_rounded
                                          : Icons.access_time_rounded,
                                      size: 13,
                                      color: team.isPaid
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isExpanded
                                  ? l10n.doublesMemberList
                                  : '${l10n.memberNamesLabel} ${memberNames.join(", ")}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Chevron Indicator
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: MediaQuery.of(context).disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colors.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── INLINE ACCORDION BODY: REVEAL 2 MEMBERS DIRECTLY BELOW ──
          AnimatedSize(
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            onEnd: _isExpanded ? _revealExpandedRow : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(
                      height: 1,
                      color: colors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    child: Column(
                      children: List.generate(memberNames.length, (idx) {
                        final player = players[idx];
                        final mName = player.fullName;
                        final MatchMemberInfo? mInfo = _memberInfoFor(player);
                        final eloVal =
                            mInfo?.eloPoints ?? team.eloPoints ?? 1200;
                        final eloStr = '${l10n.eloLabel} $eloVal';
                        final tierStr = mInfo?.tierName;
                        final isCaptain = idx == 0;
                        final memberAvatar = player.avatarUrl ?? mInfo?.avatarUrl;

                        return Container(
                          margin: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: colors.border.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                widget.onMemberTap?.call(player.userId, mName);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    // Member avatar
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppTheme.primary
                                          .withValues(alpha: 0.15),
                                      child:
                                          (memberAvatar != null &&
                                              memberAvatar.isNotEmpty)
                                          ? ClipOval(
                                              child: Image.network(
                                                memberAvatar,
                                                fit: BoxFit.cover,
                                                width: 28,
                                                height: 28,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Text(
                                                      _getInitials(mName),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppTheme.primary,
                                                      ),
                                                    ),
                                              ),
                                            )
                                          : Text(
                                              _getInitials(mName),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Name + Captain/Member Role Badge
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              mName,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: colors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCaptain
                                                  ? const Color(0xFFFEF2F2)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isCaptain
                                                    ? const Color(0xFFFCA5A5)
                                                    : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            child: Text(
                                              isCaptain
                                                  ? l10n.captainRole
                                                  : l10n.memberRole,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isCaptain
                                                    ? const Color(0xFFDC2626)
                                                    : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Elo badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F9FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFBAE6FD),
                                        ),
                                      ),
                                      child: Text(
                                        eloStr,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),

                                    // Tier badge
                                    if (tierStr != null &&
                                        tierStr.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFDE68A),
                                          ),
                                        ),
                                        child: Text(
                                          tierStr,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],

                                    // Profile chevron arrow
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: colors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
