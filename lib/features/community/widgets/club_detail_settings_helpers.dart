part of '../screens/club_detail_screen.dart';

extension _ClubDetailSettingsHelpers on _ClubDetailScreenState {
  Widget _buildQuickStatusCard(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final visibilityLabel = club.visibility == 'PUBLIC'
        ? l10n.rank_public
        : club.visibility == 'RESTRICTED'
        ? l10n.clubDetailRestrictedVisibility
        : l10n.clubDetailPrivateVisibility;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _quickStatusRow(
            colors,
            icon: Icons.bolt_rounded,
            label: l10n.clubDetailStatus,
            value: l10n.clubDetailActiveStatus,
            valueColor: colors.success,
          ),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
          _quickStatusRow(
            colors,
            icon: Icons.visibility_outlined,
            label: l10n.clubDetailVisibility,
            value: visibilityLabel,
          ),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
          FutureBuilder<CommunitySocialSettings>(
            future: _socialSettingsFuture ??= ref
                .read(communityRepositoryProvider)
                .getSocialSettings(widget.clubId),
            builder: (context, snapshot) {
              final chatEnabled = snapshot.data?.chatEnabled ?? true;
              return _quickStatusRow(
                colors,
                icon: Icons.chat_bubble_outline_rounded,
                label: l10n.clubDetailInternalChat,
                value: chatEnabled
                    ? l10n.clubDetailChatOpen
                    : l10n.clubDetailChatClosed,
                valueColor: chatEnabled ? colors.success : colors.textMuted,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _quickStatusRow(
    AppColorsExtension colors, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsSectionHeader(String title, AppColorsExtension colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: colors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _settingsStatBox(
    String label,
    String value,
    IconData icon,
    Color color,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
        ],
      ),
    );
  }
}
