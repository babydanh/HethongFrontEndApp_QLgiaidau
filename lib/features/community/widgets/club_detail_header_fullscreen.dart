part of '../screens/club_detail_screen.dart';

extension _ClubDetailHeaderFullscreen on _ClubDetailScreenState {
  void _showClubAboutFullScreen(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: colors.bgDark,
          appBar: AppBar(
            backgroundColor: colors.bgDark,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: colors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: Text(
              l10n.club_tabAbout,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: _buildAboutTab(club, colors),
        ),
      ),
    );
  }

  void _showClubGalleryFullScreen(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: colors.bgDark,
          appBar: AppBar(
            backgroundColor: colors.bgDark,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: colors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: Text(
              l10n.club_tabGallery,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: Consumer(
            builder: (context, ref, _) =>
                _buildGalleryTab(club, colors, modalRef: ref),
          ),
        ),
      ),
    );
  }

  void _showClubSettingsFullScreen(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: colors.bgDark,
          appBar: AppBar(
            backgroundColor: colors.bgDark,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: colors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: Text(
              l10n.club_tabSettings,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: _buildSettingsTab(club, colors),
        ),
      ),
    );
  }

  void _showClubTournamentsFullScreen(
    Community club,
    AppColorsExtension colors,
  ) {
    // TEMP-DISABLE-TOURNEY (Yêu cầu 2): tạm ẩn màn hình Giải đấu, hiển thị
    // "Sắp ra mắt" căn giữa màn hình. Muốn bật lại: bỏ comment khối
    // Navigator push _ClubTournamentsFullScreenView bên dưới và xóa khối coming-soon.
    // Navigator.of(context).push(
    //   MaterialPageRoute<void>(
    //     fullscreenDialog: true,
    //     builder: (ctx) => _ClubTournamentsFullScreenView(
    //       club: club,
    //       colors: colors,
    //       clubDetailState: this,
    //     ),
    //   ),
    // );
    _showComingSoonCentered(club, colors);
  }

  // Yêu cầu 2: "Xem thêm" -> Giải đấu -> hiển thị "Sắp ra mắt" căn giữa
  // (vertical + horizontal). Dùng fullscreenDialog để đồng nhất với
  // gallery/settings.
  void _showComingSoonCentered(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: colors.bgDark,
          appBar: AppBar(
            backgroundColor: colors.bgDark,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: colors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: Text(
              l10n.club_tabTournaments,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Text(
              'Sắp ra mắt',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
