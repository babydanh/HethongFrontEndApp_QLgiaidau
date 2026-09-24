import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';

class SocialParticipantsTab extends StatelessWidget {
  const SocialParticipantsTab({
    super.key,
    required this.session,
    required this.isHost,
    required this.onAddParticipant,
  });
  final SocialSessionModel session;
  final bool isHost;
  final ValueChanged<int> onAddParticipant;

  @override
  Widget build(BuildContext context) {
    final session = this.session;
    final colors = context.colors;
    final host =
        session.participants.where((p) => p.isHost).firstOrNull ??
        SocialParticipantModel(
          id: 'host_default',
          name: 'Sơn Bảo',
          initials: 'SB',
          skillLevel: session.skillLevel,
          isHost: true,
          status: 'Người tổ chức',
          joinedAt: DateTime.now(),
        );

    final totalSlots = session.maxParticipants;
    final confirmedCount = session.participants.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ─── 1. NGƯỜI TỔ CHỨC ───
        Text(
          'NGƯỜI TỔ CHỨC • 1',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.success.withValues(alpha: 0.25),
                      border: Border.all(
                        color: colors.success.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        host.initials,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                host.name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: 14),

        // ─── 2. XÁC NHẬN THAM GIA Header & More icon ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XÁC NHẬN THAM GIA • $confirmedCount/$totalSlots',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colors.textSecondary,
                size: 22,
              ),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Sort dropdown
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sắp xếp: Xác nhận gần đây',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ─── 3. GRID 4 COLUMNS (Ảnh 3 Reclub) ───
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: totalSlots,
          itemBuilder: (context, index) {
            if (index < session.participants.length) {
              final p = session.participants[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.isHost
                          ? colors.success.withValues(alpha: 0.25)
                          : AppTheme.primaryLight.withValues(alpha: 0.35),
                      border: Border.all(
                        color: p.isHost
                            ? colors.success.withValues(alpha: 0.6)
                            : AppTheme.primary.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        p.initials,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              );
            } else {
              // Empty slot with '+' icon
              return InkWell(
                onTap: isHost ? () => onAddParticipant(index + 1) : null,
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.bgSurface,
                        border: Border.all(color: colors.border, width: 1.5),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 26,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Slot ${index + 1}',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
