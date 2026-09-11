part of '../screens/club_detail_screen.dart';

extension _ClubDetailHeaderAppBar on _ClubDetailScreenState {
  Widget _buildSliverAppBar(
    Community club,
    AppColorsExtension colors,
    Color sColor,
    String emoji,
    double topPadding,
    AppLocalizations l10n,
  ) {
    final bannerUrl = _resolveImageUrl(club.bannerUrl);
    final logoUrl = _resolveImageUrl(club.logoUrl);
    final bool hasBanner = bannerUrl.isNotEmpty;
    Widget fallbackBanner() {
      if (logoUrl.isEmpty) return _bannerGradient(sColor, emoji);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        color: isDark ? const Color(0xFF16233A) : const Color(0xFFE8EEFB),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Center(
          child: ClubNetworkImage(
            logoUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _bannerGradient(sColor, emoji),
          ),
        ),
      );
    }

    final totalBannerHeight = _bannerHeight + topPadding;

    return SliverAppBar(
      pinned: true,
      primary: true,
      toolbarHeight: 44.0,
      expandedHeight: totalBannerHeight,
      elevation: 0,
      backgroundColor: _isCollapsed ? colors.bgCard : Colors.transparent,
      leading: _isCollapsed
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colors.textPrimary,
                size: 22,
              ),
              onPressed: () => context.pop(),
              splashRadius: 20,
            )
          : Padding(
              padding: const EdgeInsets.all(4),
              child: _buildCircleOverlayButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            ),
      title: _isCollapsed
          ? Text(
              club.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      actions: _isCollapsed
          ? [
              IconButton(
                icon: Icon(
                  Icons.search_rounded,
                  color: colors.textPrimary,
                  size: 22,
                ),
                onPressed: () => context.push(
                  '/club/${club.id}/search?name=${Uri.encodeComponent(club.name)}',
                ),
                splashRadius: 20,
              ),
              if (_myMembership?.status == 'JOINED')
                IconButton(
                  icon: Icon(
                    Icons.forum_outlined,
                    color: colors.textPrimary,
                    size: 22,
                  ),
                  onPressed: _isOpeningClubChat
                      ? null
                      : () => _openClubChat(club),
                  splashRadius: 20,
                ),
              const SizedBox(width: 4),
            ]
          : [
              _buildCircleOverlayButton(
                icon: Icons.search_rounded,
                onTap: () => context.push(
                  '/club/${club.id}/search?name=${Uri.encodeComponent(club.name)}',
                ),
              ),
              if (_myMembership?.status == 'JOINED') ...[
                const SizedBox(width: 8),
                _buildCircleChatButton(club, colors, l10n),
              ],
              const SizedBox(width: 16),
            ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasBanner
            ? ClubNetworkImage(
                bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallbackBanner(),
              )
            : fallbackBanner(),
      ),
    );
  }
}
