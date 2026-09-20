part of '../screens/club_detail_screen.dart';

extension _ClubDetailHeaderInfo on _ClubDetailScreenState {
  Widget _buildClubInfoSection(
    Community club,
    AppColorsExtension colors,
    Color sColor, {
    required bool isClubAdmin,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final sportLabel = club.sports.isNotEmpty
        ? l10n.sportDisplayName(club.sports.first.trim())
        : l10n.club_sportFallback.toUpperCase();
    final hasLogo = _resolveImageUrl(club.logoUrl).isNotEmpty;

    return Container(
      color: colors.bgCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chỉ chừa chỗ cho avatar khi CLB thật sự có logo.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasLogo) const SizedBox(width: 84 + 12),
              // Thông tin CLB bên phải
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _showClubAboutFullScreen(club, colors),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                club.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                  height: 1.1,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              AppIcons.chevronRight,
                              size: 14,
                              color: colors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              club.visibility.toUpperCase() == 'PRIVATE'
                                  ? AppIcons.lock
                                  : AppIcons.globe,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              club.visibility.toUpperCase() == 'PRIVATE'
                                  ? l10n.clubDetailPrivateVisibility
                                  : l10n.rank_public,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        _buildMetaDot(colors),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.users,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l10n.club_memberCount(club.memberCount),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        _buildMetaDot(colors),
                        Text(
                          sportLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: sColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if ((club.locationAddress ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            AppIcons.mapPin,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              club.locationAddress!,
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
            ],
          ),
          // Hàng nút hành động bên dưới cụm avatar + thông tin
          const SizedBox(height: 12),
          _buildHeaderActions(club, colors, isClubAdmin),
        ],
      ),
    );
  }
}
