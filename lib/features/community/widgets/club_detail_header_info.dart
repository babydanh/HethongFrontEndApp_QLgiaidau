part of '../screens/club_detail_screen.dart';

extension _ClubDetailHeaderInfo on _ClubDetailScreenState {
  Widget _buildClubInfoSection(
    Community club,
    AppColorsExtension colors,
    Color sColor,
    String emoji, {
    required bool isClubAdmin,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final sportLabel = club.sports.isNotEmpty
        ? l10n.sportDisplayName(club.sports.first.trim())
        : l10n.club_sportFallback.toUpperCase();

    return Container(
      color: colors.bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng chứa Avatar và Nút nằm đè lên chân ảnh bìa
          Stack(
            clipBehavior: Clip.none,
            children: [
              const SizedBox(height: 48, width: double.infinity),
              Positioned(
                top: -36,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 84), // chừa chỗ cho avatar overlay
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildHeaderActions(club, colors, isClubAdmin),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Thông tin CLB
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _showClubAboutFullScreen(club, colors),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            club.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              height: 1.16,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      Icon(
                        club.visibility.toUpperCase() == 'PRIVATE'
                            ? Icons.lock_outline_rounded
                            : Icons.public_outlined,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        club.visibility.toUpperCase() == 'PRIVATE'
                            ? l10n.clubDetailPrivateVisibility
                            : l10n.rank_public,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildMetaDot(colors),
                      Icon(
                        Icons.group_outlined,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.club_memberCount(club.memberCount),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildMetaDot(colors),
                      Text(
                        sportLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: sColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if ((club.locationAddress ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          club.locationAddress!,
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
