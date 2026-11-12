import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/logic/social_add_people.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_avatar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialDetailsTab extends StatelessWidget {
  const SocialDetailsTab({
    super.key,
    required this.session,
    required this.isHost,
    required this.onContactHost,
    required this.onFindPlayers,
    this.onEditLocation,
    this.viewerFooter,
  });

  final SocialSessionModel session;
  final bool isHost;
  final VoidCallback onContactHost;
  final VoidCallback onFindPlayers;

  /// Host-only: tapping the location opens the edit form (set when the place
  /// is still "Quyết định sau").
  final VoidCallback? onEditLocation;
  final Widget? viewerFooter;

  @override
  Widget build(BuildContext context) {
    final session = this.session;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = session.status.toUpperCase() == 'COMPLETED';
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Host: logo CLB (hoặc ảnh/chữ cái đầu của host) + nhãn Host.
                _HostCard(session: session),
                const SizedBox(height: 18),

                // Người tham gia thật (host đứng đầu), không ô giả.
                _ParticipantsPreview(session: session),
                const SizedBox(height: 6),

                // 'Liên hệ BTC' link
                GestureDetector(
                  onTap: () => onContactHost(),
                  child: const Text(
                    'Liên hệ BTC',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Date & Time Row (IMG2)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 22,
                      color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.fullDateTimeDisplay,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${session.durationHours} giờ',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 4. Location Row (IMG2)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 24,
                      color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: onEditLocation,
                            child: Text(
                              session.isLocationDeferred
                                  ? session.venueName
                                  : session.venueName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary, // Blue location name
                                decoration: onEditLocation == null
                                    ? null
                                    : TextDecoration.underline,
                              ),
                            ),
                          ),
                          if (!session.isLocationDeferred) ...[
                            const SizedBox(height: 4),
                            Text(
                              session.venueAddress,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: colors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (session.latitude != null &&
                              session.longitude != null)
                            TextButton.icon(
                              icon: const Icon(Icons.directions_outlined),
                              label: const Text('Chỉ đường'),
                              onPressed: () async {
                                final lat = session.latitude!;
                                final lng = session.longitude!;
                                final uri =
                                    Theme.of(context).platform ==
                                        TargetPlatform.iOS
                                    ? Uri.parse(
                                        'https://maps.apple.com/?daddr=$lat,$lng',
                                      )
                                    : Uri.parse(
                                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                                      );
                                try {
                                  final opened = await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!opened && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Không mở được ứng dụng bản đồ.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Không mở được ứng dụng bản đồ.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          // const SizedBox(height: 4),
                          // Text(
                          //   '${session.distanceKm.toStringAsFixed(1)} km từ Nhà',
                          //   style: TextStyle(
                          //     fontSize: 13,
                          //     color: colors.textMuted,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 5. Play Format Row (IMG2)
                Row(
                  children: [
                    Icon(
                      Icons.sports_tennis_outlined,
                      size: 22,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      session.playFormat,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 6. Price Row (IMG2)
                Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 22,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: 14),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Mỗi người · ',
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: currencyFormatter.format(
                              session.pricePerSlot,
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── LOWER PART: LƯU Ý / GHI CHÚ (IMG3) ───
                if (session.notes.trim().isNotEmpty) ...[
                  Divider(color: colors.border, thickness: 1),
                  const SizedBox(height: 16),

                  Text(
                    'Lưu ý',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: SelectableText(
                      session.notes,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: colors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ), // đóng SingleChildScrollView
        ), // đóng Expanded
        if (isHost && !isCompleted)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => onFindPlayers(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                  child: const Text(
                    'Tìm thêm người chơi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        if (!isHost && viewerFooter != null) viewerFooter!,
      ],
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({required this.session});
  final SocialSessionModel session;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final host = session.participants.where((p) => p.isHost).firstOrNull;
    final hasClub = session.community != null;
    final title = session.hostClubName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? colors.bgCard : colors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.success.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Row(
        children: [
          SocialAvatar(
            name: title,
            imageUrl: hasClub ? session.hostClubAvatar : host?.avatarUrl,
            isHost: true,
            userId: hasClub || host == null || host.isGuest
                ? null
                : host.userId,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if (hasClub && host != null)
                  Text(
                    'Host: ${host.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SocialHostChip(),
        ],
      ),
    );
  }
}

class _ParticipantsPreview extends StatelessWidget {
  const _ParticipantsPreview({required this.session});
  final SocialSessionModel session;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The host card above already shows the host, so the row lists the others.
    final preview = previewParticipants([
      for (final p in session.participants)
        if (!p.isHost) p,
    ]);
    return Row(
      children: [
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in preview.shown)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SocialAvatar(
                      name: p.name,
                      imageUrl: p.avatarUrl,
                      size: 40,
                      isHost: p.isHost,
                      userId: p.isGuest ? null : p.userId,
                    ),
                  ),
                if (preview.overflow > 0)
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.borderLight,
                    ),
                    child: Text(
                      '+${preview.overflow}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${session.currentSlots}/${session.maxSlots}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
