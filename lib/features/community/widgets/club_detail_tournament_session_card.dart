part of '../screens/club_detail_screen.dart';

extension _ClubDetailTournamentSessionCard on _ClubDetailScreenState {
  Widget _buildSessionCard(
    ClubMatchSessionModel session,
    Community club,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Phân tích trạng thái
    final (
      badgeBg,
      badgeBorder,
      badgeTextColor,
      statusDotColor,
      statusText,
    ) = switch (session.status) {
      'OPEN' => (
        const Color(0xFFECFDF5),
        const Color(0xFF6EE7B7),
        const Color(0xFF047857),
        const Color(0xFF10B981),
        l10n.clubMatchSessionStatusOpen,
      ),
      'LIVE' => (
        const Color(0xFFFEF2F2),
        const Color(0xFFFCA5A5),
        const Color(0xFFB91C1C),
        const Color(0xFFEF4444),
        l10n.clubMatchSessionStatusLive,
      ),
      'CLOSED' => (
        const Color(0xFFF1F5F9),
        const Color(0xFFCBD5E1),
        const Color(0xFF334155),
        const Color(0xFF64748B),
        l10n.clubMatchSessionStatusClosed,
      ),
      'ENDED' => (
        const Color(0xFFF1F5F9),
        const Color(0xFFE2E8F0),
        const Color(0xFF64748B),
        const Color(0xFF94A3B8),
        l10n.clubMatchSessionStatusEnded,
      ),
      'CANCELLED' => (
        const Color(0xFFFEF2F2),
        const Color(0xFFFECACA),
        const Color(0xFFDC2626),
        const Color(0xFFEF4444),
        l10n.clubMatchSessionStatusCancelled,
      ),
      _ => (
        const Color(0xFFF1F5F9),
        const Color(0xFFCBD5E1),
        const Color(0xFF475569),
        const Color(0xFF64748B),
        session.status,
      ),
    };

    // Sport name & visual theme
    final sportName = club.sports.isNotEmpty ? club.sports.first : 'Thể thao';
    final sportLower = sportName.toLowerCase();

    final (bannerGradient, sportWatermarkText, sportIconData) = () {
      if (sportLower.contains('pickleball')) {
        return (
          const [Color(0xFF10B981), Color(0xFF0D9488), Color(0xFF0891B2)],
          'PICKLEBALL',
          Icons.sports_tennis_rounded,
        );
      }
      if (sportLower.contains('cầu lông') ||
          sportLower.contains('badminton') ||
          sportLower.contains('lông')) {
        return (
          const [Color(0xFF2563EB), Color(0xFF4F46E5), Color(0xFF0284C7)],
          'BADMINTON',
          Icons.sports_tennis_rounded,
        );
      }
      if (sportLower.contains('tennis') || sportLower.contains('quần vợt')) {
        return (
          const [Color(0xFFF59E0B), Color(0xFFEA580C), Color(0xFFE11D48)],
          'TENNIS',
          Icons.sports_tennis_rounded,
        );
      }
      if (sportLower.contains('bóng đá') ||
          sportLower.contains('football') ||
          sportLower.contains('soccer')) {
        return (
          const [Color(0xFF10B981), Color(0xFF059669), Color(0xFF0284C7)],
          'FOOTBALL',
          Icons.sports_soccer_rounded,
        );
      }
      if (sportLower.contains('bóng bàn') ||
          sportLower.contains('ping') ||
          sportLower.contains('table tennis')) {
        return (
          const [Color(0xFFF43F5E), Color(0xFFEC4899), Color(0xFF9333EA)],
          'PING PONG',
          Icons.sports_tennis_rounded,
        );
      }
      return (
        const [Color(0xFF0D9488), Color(0xFF0284C7), Color(0xFF4F46E5)],
        'SESSION',
        Icons.sports_tennis_rounded,
      );
    }();

    String dateStr = '';
    if (session.startAt != null) {
      final s = session.startAt!;
      dateStr =
          '${s.day.toString().padLeft(2, '0')}/${s.month.toString().padLeft(2, '0')}/${s.year} ${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
    }

    final isSessionClosed =
        session.status == 'CLOSED' || session.status == 'ENDED';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClubMatchSessionDetailPage(session: session),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ClubSessionAthleticBanner(
              isDark: isDark,
              isSessionClosed: isSessionClosed,
              bannerGradient: bannerGradient,
              sportWatermarkText: sportWatermarkText,
              sportIconData: sportIconData,
              sportName: sportName,
              badgeBg: badgeBg,
              badgeBorder: badgeBorder,
              badgeTextColor: badgeTextColor,
              statusDotColor: statusDotColor,
              statusText: statusText,
            ),

            // ─── Body Card Info ───
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên buổi giao lưu
                  Text(
                    session.resolvedName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Tag hình thức: Có ELO / Không ELO, Ghép tự do, Lặp định kỳ
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: session.isRanked
                              ? const Color(0xFF0284C7)
                              : colors.bgSurface,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: session.isRanked
                                ? const Color(0xFF0284C7)
                                : colors.border,
                          ),
                        ),
                        child: Text(
                          session.isRanked
                              ? l10n.clubMatchSessionRankedShort
                              : l10n.clubMatchSessionUnrankedShort,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: session.isRanked
                                ? Colors.white
                                : colors.textMuted,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          'Ghép tự do',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      if (session.isRecurring)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0D9488,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(
                                0xFF0D9488,
                              ).withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Text(
                            'Lặp định kỳ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Meta info: Ngày giờ bắt đầu
                  if (dateStr.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Meta info: Số người tham gia & số trận
                  Row(
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 14,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${session.participantCount ?? 0}/${session.maxParticipants} người tham gia',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (session.matchCount != null &&
                          session.matchCount! > 0) ...[
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: colors.textMuted)),
                        const SizedBox(width: 8),
                        Text(
                          '${session.matchCount} trận',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: colors.border.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 10),

                  // Footer: Miễn phí & Nút Vào buổi giao lưu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.freePrice,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Vào buổi giao lưu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Color(0xFF0D9488),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
