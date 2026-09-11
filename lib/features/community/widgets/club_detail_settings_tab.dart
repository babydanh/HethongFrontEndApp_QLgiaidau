part of '../screens/club_detail_screen.dart';

extension _ClubDetailSettingsTab on _ClubDetailScreenState {
  Widget _buildSettingsTab(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(userProfileProvider).asData?.value.id;
    final isCreator = club.ownerId != null && club.ownerId == currentUserId;
    final isOwner =
        isCreator || club.myRole == 'OWNER' || _myMembership?.role == 'OWNER';
    final isAdmin =
        isOwner ||
        club.myRole == 'ADMIN' ||
        club.myRole == 'MODERATOR' ||
        _myMembership?.role == 'ADMIN' ||
        _myMembership?.role == 'MODERATOR';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Thông tin CLB
        _settingsSectionHeader(l10n.club_sectionInfo, colors),
        const SizedBox(height: 8),
        _settingsTile(
          icon: Icons.edit_rounded,
          title: l10n.club_editInfo,
          subtitle: l10n.club_editInfoSubtitle,
          color: AppTheme.primary,
          onTap: isAdmin
              ? () => context.push('/club/${widget.clubId}/edit')
              : null,
        ),
        if (isAdmin) ...[
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.tune_rounded,
            title: l10n.club_manageClub,
            subtitle: l10n.club_manageClubSubtitle,
            color: AppTheme.primary,
            onTap: () =>
                context.push('/club/${widget.clubId}/manage', extra: isOwner),
          ),
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.forum_outlined,
            title: l10n.clubDetailSocialSettings,
            subtitle: l10n.clubDetailSocialSettingsSubtitle,
            color: AppTheme.primary,
            onTap: () async {
              final updated = await CommunitySocialSettingsSheet.show(
                context,
                repository: ref.read(communityRepositoryProvider),
                communityId: widget.clubId,
              );
              if (updated != null && mounted) {
                ref.invalidate(communitySocialSettingsProvider(widget.clubId));
                _updateClubState(() {
                  _socialSettingsFuture = Future.value(updated);
                });
              }
            },
          ),
        ],
        const SizedBox(height: 20),

        // Hình thức tham gia
        _settingsSectionHeader(l10n.club_joinModeSection, colors),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.how_to_reg_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.club_joinModeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      club.joinMode == 'OPEN'
                          ? l10n.club_joinModeOpen
                          : club.joinMode == 'APPROVAL'
                          ? l10n.club_joinModeApproval
                          : l10n.club_joinModeInvite,
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Trạng thái & Tóm tắt nhanh (đồng bộ sidebar web)
        _settingsSectionHeader(l10n.clubDetailQuickStatus, colors),
        const SizedBox(height: 8),
        _buildQuickStatusCard(club, colors),
        const SizedBox(height: 20),

        // Thống kê
        _settingsSectionHeader(l10n.club_statsSection, colors),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _settingsStatBox(
                l10n.club_membersLabel,
                '${club.memberCount}',
                Icons.people_rounded,
                AppTheme.primary,
                colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _settingsStatBox(
                l10n.club_sportLabel,
                club.sports.isNotEmpty ? club.sports.first : l10n.club_noSport,
                Icons.sports_rounded,
                const Color(0xFF059669),
                colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _settingsStatBox(
                l10n.club_statusLabel,
                club.status == 'ACTIVE' ? l10n.club_active : l10n.club_pending,
                Icons.circle_rounded,
                club.status == 'ACTIVE'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _settingsStatBox(
                l10n.club_createdAt,
                club.createdAt.isNotEmpty
                    ? club.createdAt.substring(0, 10)
                    : '---',
                Icons.calendar_today_rounded,
                colors.textMuted,
                colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Hành động nguy hiểm (chỉ OWNER)
        if (_myMembership?.role == 'OWNER') ...[
          _settingsSectionHeader(l10n.club_dangerSection, colors),
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.delete_forever_rounded,
            title: l10n.club_deleteClub,
            subtitle: l10n.club_deleteSubtitle,
            color: colors.error,
            onTap: () => _showDeleteClubDialog(club, colors),
          ),
        ],
      ],
    );
  }

  /// Tóm tắt nhanh như sidebar web: trạng thái, chế độ hiển thị, phòng chat.
}
