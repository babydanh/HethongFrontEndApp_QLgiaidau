import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:intl/intl.dart';

class SocialDetailsTab extends StatelessWidget {
  const SocialDetailsTab({
    super.key,
    required this.session,
    required this.isHost,
    required this.onContactHost,
    required this.onFindPlayers,
  });

  final SocialSessionModel session;
  final bool isHost;
  final VoidCallback onContactHost;
  final VoidCallback onFindPlayers;

  @override
  Widget build(BuildContext context) {
    final session = this.session;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                // ─── UPPER PART (IMG2) ───

                // 1. Club Host Banner Card (Light green background matching IMG2)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.bgCard
                        : colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.success.withValues(
                        alpha: isDark ? 0.3 : 0.2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Club Logo Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.black26 : Colors.white,
                          border: Border.all(color: colors.success, width: 1.5),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.sports_tennis_rounded,
                            size: 22,
                            color: colors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Host Club Name only
                      Expanded(
                        child: Text(
                          session.hostClubName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Participants Avatars Row & 'Liên hệ BTC' (IMG2)
                Row(
                  children: [
                    // Host Avatar Circle (e.g. MQ)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.success.withValues(alpha: 0.25),
                      ),
                      child: Center(
                        child: Text(
                          'MQ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Empty Slot Circles (Dashed/Grey border circles)
                    for (int i = 0; i < 3; i++)
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.bgSurface,
                        ),
                      ),

                    // '+4' Counter Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.borderLight,
                      ),
                      child: const Center(
                        child: Text(
                          '+4',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                          Text(
                            session.venueName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary, // Blue location name
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.venueAddress,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
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
        if (isHost)
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
      ],
    );
  }
}
