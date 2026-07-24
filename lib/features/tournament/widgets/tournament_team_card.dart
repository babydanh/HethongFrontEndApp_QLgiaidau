import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';

class TournamentTeamCard extends StatefulWidget {
  final Team team;
  final VoidCallback onTap;

  const TournamentTeamCard({
    super.key,
    required this.team,
    required this.onTap,
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final team = widget.team;

    // Check if Doubles (2 or more members or separator ' - ' / ' / ')
    final isDoubles = team.members.length > 1 || team.name.contains(' - ') || team.name.contains(' / ');

    // Extract member names & member info
    final memberNames = team.members.isNotEmpty
        ? team.members
        : (isDoubles ? team.name.split(RegExp(r' - | / ')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [team.name]);

    final memberInfos = team.memberInfos;

    // Real rank tier or seed badge
    final realTierName = (team.group.isNotEmpty &&
            !team.group.toLowerCase().contains('sơ') &&
            !team.group.toLowerCase().contains('nâng') &&
            !team.group.toLowerCase().startsWith('bảng'))
        ? team.group
        : null;

    final seedLabel = team.seed > 0 ? 'Hạt giống #${team.seed}' : null;

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
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            if (isDoubles) {
              setState(() => _isExpanded = !_isExpanded);
            } else {
              widget.onTap();
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // ── HEADER ROW ──
                Row(
                  children: [
                    // Avatar (Single circle for Singles, or Team photo for Doubles)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border.withValues(alpha: 0.6), width: 1.2),
                      ),
                      child: CircleAvatar(
                        radius: 19,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: team.photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  team.photoUrl,
                                  fit: BoxFit.cover,
                                  width: 38,
                                  height: 38,
                                  errorBuilder: (context, error, stackTrace) => Text(
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

                    // Main Info: Name + Real Tier/Seed Badge
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
                                    fontSize: 13,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Real Tier / Seed Badge (ONLY if present from API)
                              if (realTierName != null || seedLabel != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
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

                          // Subtitle: Member list for Doubles (when collapsed)
                          if (isDoubles && !_isExpanded && memberNames.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.people_outline_rounded, size: 12, color: colors.textMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'VĐV: ${memberNames.join(", ")}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Right Chevron Icon (Doubles expands inline, Singles direct tap)
                    if (isDoubles)
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: colors.textMuted,
                        size: 20,
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textMuted,
                        size: 18,
                      ),
                  ],
                ),

                // ── INLINE EXPANDED SECTION (TỤ XUỐNG FOR DOUBLES) ──
                if (isDoubles && _isExpanded) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

                  ...List.generate(memberNames.length, (idx) {
                    final mName = memberNames[idx];
                    final MatchMemberInfo? mInfo = idx < memberInfos.length ? memberInfos[idx] : null;
                    final eloStr = mInfo?.eloPoints != null ? 'Elo: ${mInfo!.eloPoints}' : null;
                    final tierStr = mInfo?.tierName;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFE2E8F0),
                            child: Text(
                              _getInitials(mName),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              mName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Real Elo rating badge
                          if (eloStr != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
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
                            const SizedBox(width: 4),
                          ],

                          // Real Rank Tier badge (if present)
                          if (tierStr != null && tierStr.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tierStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
