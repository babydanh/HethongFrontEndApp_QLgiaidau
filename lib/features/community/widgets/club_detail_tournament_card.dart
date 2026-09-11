part of '../screens/club_detail_screen.dart';

extension _ClubDetailTournamentCard on _ClubDetailScreenState {
  Widget _buildTourneyCard(
    CommunityTournamentModel t,
    Community club,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final normalizedStatus = StatusHelper.normalizeTournamentStatus(t.status);
    final statusLabel = StatusHelper.getTournamentStatusLabel(normalizedStatus);
    final statusColor = StatusHelper.getTournamentStatusColor(
      normalizedStatus,
      context,
    );
    final isQuick = t.isLite;
    // Ảnh đại diện banner: giải đấu bannerUrl/logoUrl -> fallback sang club bannerUrl/logoUrl
    final effectiveImageUrl =
        (t.bannerUrl != null && t.bannerUrl!.trim().isNotEmpty)
        ? t.bannerUrl!.trim()
        : ((t.logoUrl != null && t.logoUrl!.trim().isNotEmpty)
              ? t.logoUrl!.trim()
              : ((club.bannerUrl != null && club.bannerUrl!.trim().isNotEmpty)
                    ? club.bannerUrl!.trim()
                    : ((club.logoUrl != null && club.logoUrl!.trim().isNotEmpty)
                          ? club.logoUrl!.trim()
                          : '')));

    final resolvedImageUrl = _resolveImageUrl(effectiveImageUrl);
    final hasImage = resolvedImageUrl.isNotEmpty;

    final sportLabel = t.categoryName.isNotEmpty
        ? t.categoryName
        : (t.sport.isNotEmpty ? l10n.sportDisplayName(t.sport) : '');

    final formatLabel = t.format.isNotEmpty
        ? l10n.formatDisplayName(t.format)
        : '';

    return InkWell(
      onTap: () => context.push('/intro/${t.id}'),
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
            // Banner ảnh phía trên card
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      resolvedImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _bannerGradient(AppTheme.primary, '🏆'),
                    )
                  else
                    _bannerGradient(AppTheme.primary, '🏆'),
                  // Overlay chuyển màu mờ nhẹ để đọc text tốt hơn
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  // Badges góc trên trái: Trạng thái & Loại giải
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (t.tournamentType == 'CLUB'
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF2563EB))
                                        .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.tournamentType == 'CLUB'
                                    ? l10n.clubDetailClubTournamentBadge
                                    : l10n.clubDetailOpenTournamentBadge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isQuick)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  size: 11,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  l10n.clubDetailLiteBadge,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Bottom strip trên banner: Thể thao / Môn thi
                  if (sportLabel.isNotEmpty)
                    Positioned(
                      left: 10,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sports_tennis_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sportLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Phần nội dung thông tin chi tiết giải đấu
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên giải đấu
                  Text(
                    t.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: colors.textPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Tag hình thức / phân hạng
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (formatLabel.isNotEmpty)
                        _tournamentBadge(formatLabel, colors.textSecondary),
                      if (t.isRanked)
                        _tournamentBadge(
                          l10n.clubDetailRankedBadge,
                          const Color(0xFF0284C7),
                        ),
                      if (t.parentId != null)
                        _tournamentBadge(
                          l10n.clubDetailSeriesBadge,
                          const Color(0xFF7C3AED),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Ngày thi đấu
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
                          DateFormatterUtils.formatTournamentDateRange(
                            t.startDate,
                            t.endDate,
                            fallback: l10n.club_noTournaments,
                          ),
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

                  // Địa điểm thi đấu (nếu có)
                  if (t.locationAddress != null &&
                      t.locationAddress!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t.locationAddress!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: colors.border.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 10),

                  // Footer: Số đội / Lệ phí và nút Xem chi tiết
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 15,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.club_teamCount(t.teamCount, t.maxTeams),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('•', style: TextStyle(color: colors.textMuted)),
                          const SizedBox(width: 10),
                          Text(
                            t.entryFee > 0
                                ? '${t.entryFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ'
                                : l10n.freePrice,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: t.entryFee > 0
                                  ? const Color(0xFF10B981)
                                  : colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.exploreDetails,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: AppTheme.primary,
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
