part of '../screens/club_detail_screen.dart';

extension _ClubDetailHeaderAppBar on _ClubDetailScreenState {
  Widget _buildSliverAppBar(
      Community club,
      AppColorsExtension colors,
      Color sColor,
      String emoji,
      double topPadding,
      AppLocalizations l10n, {
        required bool isClubAdmin,
      }) {
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

    // ĐỊNH NGHĨA STYLE ICON CHỐNG MỜ & CHỐNG CHÓI (GIỐNG FACEBOOK)
    // Khi chưa cuộn: Màu trắng đục 100% kèm đổ bóng đen mờ để luôn nổi bật trên nền ảnh bìa sáng/tối.
    // Khi đã cuộn thu nhỏ: Trở về màu mặc định của theme hệ thống (hoặc màu tương phản với colors.bgDark).
    final List<Shadow>? iconShadows = _isCollapsed
        ? null
        : [
      Shadow(
        offset: const Offset(0, 1),
        blurRadius: 4.0,
        color: Colors.black.withValues(alpha: 0.5),
      ),
    ];

    final Color currentIconColor = _isCollapsed ? colors.textPrimary : Colors.white;

    return SliverAppBar(
      pinned: true,
      primary: true,
      toolbarHeight: 44.0,
      expandedHeight: totalBannerHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: _isCollapsed ? colors.bgDark : Colors.transparent,

      // GIẢI PHÁP 1: Ép cấu hình IconTheme để triệt tiêu hoàn toàn độ mờ (opacity) mặc định từ SliverAppBar
      iconTheme: IconThemeData(
        color: currentIconColor,
        opacity: 1.0,
      ),

      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: currentIconColor, // Ép màu đục 100%
          size: 22,
          shadows: iconShadows,    // Đổ bóng chống lóa khi đè lên ảnh bìa sáng màu
        ),
        onPressed: () => context.pop(),
        splashRadius: 20,
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
      actions: [
        IconButton(
          icon: Icon(
            Icons.search_outlined,
            color: currentIconColor,
            size: 22,
            shadows: iconShadows,
          ),
          onPressed: () => context.push(
            '/club/${club.id}/search?name=${Uri.encodeComponent(club.name)}',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          splashRadius: 18,
        ),
        if (isClubAdmin)
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: currentIconColor,
              size: 22,
              shadows: iconShadows,
            ),
            tooltip: l10n.club_tabSettings,
            onPressed: () => _showClubSettingsFullScreen(club, colors),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            splashRadius: 18,
          ),
        if (_myMembership?.status == 'JOINED')
          IconButton(
            icon: _isOpeningClubChat
                ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textPrimary,
              ),
            )
                : Icon(
              Icons.chat_bubble_outline,
              color: currentIconColor, // Sử dụng biến màu đồng bộ thay vì ép cứng colors.textPrimary lúc mở rộng
              size: 22,
              shadows: iconShadows,
            ),
            onPressed: _isOpeningClubChat
                ? null
                : () => _openClubChat(club),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            splashRadius: 18,
          ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            hasBanner
                ? ClubNetworkImage(
              bannerUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  fallbackBanner(),
            )
                : fallbackBanner(),
            // Camera icon trên ảnh bìa khi là Admin (không dùng circle)
            if (isClubAdmin)
              Positioned(
                bottom: 10,
                right: 2,
                child: IconButton(
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                  tooltip: 'Đổi ảnh bìa',
                  padding: EdgeInsets.zero,
                  constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
                  splashRadius: 18,
                  onPressed: () =>
                      _showChangePhotoOptions(club: club, isLogo: false),
                ),
              ),
            // Bo tròn 2 góc trên của card thông tin đè lên chân banner
            Positioned(
              bottom: -1,
              left: 0,
              right: 0,
              height: 15,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
