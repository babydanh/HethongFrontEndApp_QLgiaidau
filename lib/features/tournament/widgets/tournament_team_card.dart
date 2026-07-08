import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgCard,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.bgCard,
              colors.bgCard.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: colors.bgSurface,
                child: team.photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          team.photoUrl,
                          fit: BoxFit.cover,
                          width: 52,
                          height: 52,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 24,
                            color: colors.textMuted,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.group,
                        size: 24,
                        color: Color(0xFF2979FF),
                      ),
              ),
            ),
            const SizedBox(height: 12),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "${team.members.length} VĐV",
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: team.isApproved
                    ? colors.success.withValues(alpha: 0.1)
                    : colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: team.isApproved
                      ? colors.success.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                team.approvalLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: team.isApproved ? colors.success : colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
