import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';

class _TierStyle {
  final String label;
  final Color bg;
  final Color text;
  final Color border;
  const _TierStyle({
    required this.label,
    required this.bg,
    required this.text,
    required this.border,
  });
}

_TierStyle? _getTierStyle(Team team) {
  final group = team.group.toLowerCase().trim();
  
  if (group.contains('sơ cấp') || group.contains('tập sự') || group.contains('hạng c')) {
    return const _TierStyle(
      label: 'Sơ cấp',
      bg: Color(0xFFEFF6FF),
      text: Color(0xFF1D4ED8),
      border: Color(0xFFBFDBFE),
    );
  } else if (group.contains('trung cấp') || group.contains('hạng b')) {
    return const _TierStyle(
      label: 'Trung cấp',
      bg: Color(0xFF2563EB),
      text: Colors.white,
      border: Color(0xFF1D4ED8),
    );
  } else if (group.contains('nâng cao') || group.contains('hạng a') || group.contains('pro')) {
    return const _TierStyle(
      label: 'Nâng cao',
      bg: Color(0xFF1E3A8A),
      text: Colors.white,
      border: Color(0xFF1E3A8A),
    );
  } else if (group.contains('chuyên nghiệp') || group.contains('master') || group.contains('gold')) {
    return const _TierStyle(
      label: 'Chuyên nghiệp',
      bg: Color(0xFFFEF3C7),
      text: Color(0xFFB45309),
      border: Color(0xFFFDE68A),
    );
  } else if (team.seed > 0) {
    return _TierStyle(
      label: 'Hạt giống #${team.seed}',
      bg: const Color(0xFFF1F5F9),
      text: const Color(0xFF475569),
      border: const Color(0xFFE2E8F0),
    );
  }

  // Nếu API không cung cấp Rank/Tier/Seed thật -> Tuyệt đối không hiển thị badge fake!
  return null;
}

class TournamentTeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const TournamentTeamCard({
    super.key,
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tierStyle = _getTierStyle(team);

    final isDoubles = team.members.length > 1 || team.name.contains(' - ') || team.name.contains(' / ');

    String? subtitleText;
    IconData subtitleIcon = Icons.apartment_rounded;

    if (isDoubles) {
      final membersStr = team.members.isNotEmpty ? team.members.join(', ') : '';
      if (membersStr.isNotEmpty && membersStr != team.name) {
        subtitleText = 'VĐV: $membersStr';
        subtitleIcon = Icons.people_outline_rounded;
      } else if (team.group.isNotEmpty && !team.group.toLowerCase().contains('sơ') && !team.group.toLowerCase().contains('nâng')) {
        subtitleText = 'CLB ${team.group}';
        subtitleIcon = Icons.apartment_rounded;
      }
    } else {
      // Đơn: Chỉ hiện CLB nếu có thông tin CLB thật, không lặp lại tên VĐV
      if (team.group.isNotEmpty &&
          team.group.toLowerCase() != team.name.toLowerCase() &&
          !team.group.toLowerCase().startsWith('bảng')) {
        subtitleText = 'CLB ${team.group}';
        subtitleIcon = Icons.apartment_rounded;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
        child: Row(
          children: [
            // Circular Avatar Image
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1.2),
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
                            team.name.isNotEmpty ? team.name[0].toUpperCase() : 'VĐV',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        team.name.isNotEmpty ? team.name[0].toUpperCase() : 'VĐV',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // Main Info: Name + Tier Badge (if real) + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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

                      // Tier Badge Pill (ONLY IF REAL API DATA EXISTS)
                      if (tierStyle != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: tierStyle.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tierStyle.border),
                          ),
                          child: Text(
                            tierStyle.label,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: tierStyle.text,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Optional Subtitle (Doubles members / Real Club)
                  if (subtitleText != null && subtitleText.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          subtitleIcon,
                          size: 12,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            subtitleText,
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

            // Right Chevron Icon
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
