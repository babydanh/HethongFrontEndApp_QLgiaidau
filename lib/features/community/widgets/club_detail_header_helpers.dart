part of '../screens/club_detail_screen.dart';

extension _ClubDetailHeaderHelpers on _ClubDetailScreenState {
  Widget _buildMetaDot(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '·',
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildClubAvatar({
    required String logoUrl,
    required AppColorsExtension colors,
    required Color sColor,
    required String emoji,
    required bool isClubAdmin,
    required Community club,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: isClubAdmin
              ? () => _showChangePhotoOptions(club: club, isLogo: true)
              : null,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: colors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: colors.bgCard, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: logoUrl.isNotEmpty
                  ? ClubNetworkImage(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _logoSportBg(sColor, emoji),
                    )
                  : _logoSportBg(sColor, emoji),
            ),
          ),
        ),
        // Camera icon overlay cho avatar khi là Admin (Yêu cầu 1)
        if (isClubAdmin)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () =>
                  _showChangePhotoOptions(club: club, isLogo: true),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  border: Border.all(color: colors.bgCard, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderActions(
    Community club,
    AppColorsExtension colors,
    bool isClubAdmin,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(userProfileProvider).asData?.value.id;
    final isCreator = club.ownerId != null && club.ownerId == currentUserId;
    final isOwner =
        isCreator || club.myRole == 'OWNER' || _myMembership?.role == 'OWNER';

    if (_isMember || isClubAdmin) {
      final hasInvite = club.visibility.toUpperCase() == 'PUBLIC';
      return Row(
        children: [
          // Nút Quản lý (nếu isAdmin) hoặc Đã tham gia (nếu member thường) (Yêu cầu 3)
          Expanded(
            child: SizedBox(
              height: 36,
              child: isClubAdmin
                  ? FilledButton.icon(
                      onPressed: () => context.push(
                        '/club/${club.id}/manage',
                        extra: isOwner,
                      ),
                      icon: const Icon(
                        Icons.shield_outlined,
                        size: 16,
                      ),
                      label: Text(
                        l10n.club_manageClub,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    )
                  : OutlinedButton(
                      onPressed: _isJoinLoading
                          ? null
                          : () => _showMemberOptionsSheet(context, club),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.bgSurface,
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isJoinLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Color(0xFF059669),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.club_joined,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                ),
                              ],
                            ),
                    ),
            ),
          ),
          if (hasInvite) ...[
            const SizedBox(width: 10),
            // Nút Mời (height 36, radius 10, nhãn 'Mời')
            Expanded(
              child: SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: () {
                    AppShareModal.show(
                      context: context,
                      title: club.name,
                      subtitle:
                          '${club.locationAddress ?? l10n.vietnam} • ${l10n.club_memberCount(club.memberCount)}',
                      webUrl: 'https://sporto.asia/communities/${club.id}',
                      imageUrl: club.logoUrl ?? club.bannerUrl,
                      badgeText: l10n.club_badge,
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                  label: const Text(
                    'Mời',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isClubAdmin ? colors.bgSurface : AppTheme.primary,
                    foregroundColor: isClubAdmin ? colors.textPrimary : Colors.white,
                    side: isClubAdmin ? BorderSide(color: colors.border) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      // Chưa tham gia / Đang chờ duyệt (Full width button)
      return SizedBox(
        width: double.infinity,
        height: 36,
        child: FilledButton.icon(
          onPressed: _isJoinLoading ? null : () => _handleJoinAction(club),
          icon: _isJoinLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(_getJoinIcon(), size: 15),
          label: Text(
            _getJoinLabel(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _getJoinBgColor(),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
  }

  Widget _bannerGradient(Color c, String emoji) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Taste: màu phẳng, không gradient.
    return Container(
      color: isDark ? const Color(0xFF16233A) : const Color(0xFFE8EEFB),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: SvgPicture.asset(
            AppConstants.logoFullSvg,
            width: 220,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _logoSportBg(Color c, String emoji) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      child: Center(
        child: SvgPicture.asset(AppConstants.logoFullSvg, fit: BoxFit.contain),
      ),
    );
  }
}
