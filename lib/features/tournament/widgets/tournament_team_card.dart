import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';

class TournamentTeamCard extends StatefulWidget {
  final Team team;
  final Function(String? userId, String memberName)? onMemberTap;

  const TournamentTeamCard({super.key, required this.team, this.onMemberTap});

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final team = widget.team;

    // Check if Doubles
    final isDoubles =
        team.members.length > 1 ||
        team.name.contains(' - ') ||
        team.name.contains(' / ') ||
        team.name.contains(' & ');

    // Member names: for Doubles always split from team name to get 2 players
    final List<String> memberNames = isDoubles
        ? team.name
              .split(RegExp(r' - | / | & '))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : (team.members.isNotEmpty ? team.members : [team.name]);

    final memberInfos = team.memberInfos;

    // Seed or Tier badge
    final realTierName =
        (team.group.isNotEmpty &&
            !team.group.toLowerCase().contains('sơ') &&
            !team.group.toLowerCase().contains('nâng') &&
            !team.group.toLowerCase().startsWith('bảng'))
        ? team.group
        : null;
    final seedLabel = team.seed > 0 ? 'Hạt giống #${team.seed}' : null;

    if (!isDoubles) {
      // ── SINGLES (ĐƠN) LAYOUT: DIRECT PROFILE TAP, NO EXPANSION ──
      final singleInfo = memberInfos.isNotEmpty ? memberInfos.first : null;
      final eloStr = singleInfo?.eloPoints != null
          ? 'Elo: ${singleInfo!.eloPoints}'
          : null;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              widget.onMemberTap?.call(singleInfo?.userId, team.name);
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Athlete Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      child: team.photoUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                team.photoUrl,
                                fit: BoxFit.cover,
                                width: 38,
                                height: 38,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                      _getInitials(team.name),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                              ),
                            )
                          : Text(
                              _getInitials(team.name),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Athlete Name + Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (eloStr != null ||
                            realTierName != null ||
                            seedLabel != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (eloStr != null) ...[
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
                                const SizedBox(width: 6),
                              ],
                              if (realTierName != null || seedLabel != null)
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
                                    realTierName ?? seedLabel!,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row: Team Name + Expand Toggle
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Team Avatar / Double Initials
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 19,
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: team.photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  team.photoUrl,
                                  fit: BoxFit.cover,
                                  width: 38,
                                  height: 38,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                        _getInitials(team.name),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                ),
                              )
                            : Text(
                                _getInitials(team.name),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Team Name & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  team.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (realTierName != null ||
                                  seedLabel != null) ...[
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
                                    realTierName ?? seedLabel!,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isExpanded
                                ? 'Danh sách 2 vận động viên:'
                                : 'VĐV: ${memberNames.join(", ")}',
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
                      child: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: colors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── INLINE ACCORDION BODY: REVEAL 2 MEMBERS DIRECTLY BELOW ──
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
                  final mName = memberNames[idx];
                  final MatchMemberInfo? mInfo = idx < memberInfos.length
                      ? memberInfos[idx]
                      : null;
                  final eloStr = mInfo?.eloPoints != null
                      ? 'Elo: ${mInfo!.eloPoints}'
                      : null;
                  final tierStr = mInfo?.tierName;
                  final isCaptain = idx == 0;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.bgSurface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          widget.onMemberTap?.call(mInfo?.userId, mName);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Member avatar
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
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
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isCaptain
                                              ? const Color(0xFFFCA5A5)
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Text(
                                        isCaptain
                                            ? 'Trưởng nhóm'
                                            : 'Thành viên',
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
                              if (eloStr != null) ...[
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
                              ],

                              // Tier badge
                              if (tierStr != null && tierStr.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
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
    );
  }
}
