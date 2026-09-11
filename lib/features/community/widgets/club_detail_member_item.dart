part of '../screens/club_detail_screen.dart';

extension _ClubDetailMemberItem on _ClubDetailScreenState {
  Widget _buildMemberItem(
    CommunityMemberModel m,
    AppColorsExtension colors,
    bool isAdmin,
    int? memberElo, {
    int? rankIndex,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isOwner = m.role == 'OWNER';
    final isCurrentOwner = _myMembership?.role == 'OWNER';
    final canViewProfile = m.userId.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          bottom: BorderSide(color: colors.borderLight, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          if (rankIndex != null) ...[
            Container(
              width: 28,
              alignment: Alignment.centerLeft,
              child: Text(
                '#$rankIndex',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: rankIndex == 1
                      ? const Color(0xFFEAB308)
                      : rankIndex == 2
                      ? const Color(0xFF94A3B8)
                      : rankIndex == 3
                      ? const Color(0xFFD97706)
                      : colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          GestureDetector(
            onTap: canViewProfile
                ? () => _showMemberProfile(
                    m.userId,
                    m.userFullName,
                    m.userAvatarUrl,
                  )
                : null,
            child: _buildUserAvatar(
              name: m.userFullName,
              avatarUrl: m.userAvatarUrl,
              radius: 20,
              fallbackColor: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: canViewProfile
                  ? () => _showMemberProfile(
                      m.userId,
                      m.userFullName,
                      m.userAvatarUrl,
                    )
                  : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.userFullName ?? l10n.club_membersLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (memberElo != null)
                        EloTierBadge(elo: memberElo, scale: 0.75),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (memberElo != null)
                        Text(
                          '$memberElo ELO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      if (m.role != 'MEMBER') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? Colors.amber.withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOwner ? l10n.club_owner : l10n.club_admin,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isOwner
                                  ? Colors.amber.shade800
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // P2C.5 — pills tag BQT (màu preset, tint như web) + streak cạnh tên.
                  if (m.tags.isNotEmpty || !m.streak.isEmpty) ...[
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final presets = ref
                            .watch(communityTagPresetsProvider(widget.clubId))
                            .asData
                            ?.value;
                        return Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            ...m.tags.map(
                              (tag) => PresetTagChip(
                                label: tag,
                                color: presets == null
                                    ? null
                                    : resolvePresetColor(presets, tag),
                                style: PresetTagChipStyle.tint,
                              ),
                            ),
                            if (!m.streak.isEmpty)
                              StreakChip(
                                type: m.streak.type,
                                count: m.streak.count,
                                label: m.streak.label,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Menu quản lý (OWNER/ADMIN thấy, nhưng không thể tự kick chính mình)
          if (isAdmin && !isOwner && m.userId != _myMembership?.userId)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colors.textMuted,
                size: 20,
              ),
              color: colors.bgSurface,
              onSelected: (action) =>
                  _handleMemberAction(action, m, colors, memberElo ?? 1000),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'promote_admin',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.club_setAdmin,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'promote_mod',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.club_setMod,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (m.role != 'MEMBER')
                  PopupMenuItem(
                    value: 'demote',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.club_demoteToMember,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (isCurrentOwner)
                  PopupMenuItem(
                    value: 'transfer_owner',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Chuyển chủ sở hữu',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'adjust_elo',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.military_tech_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('Chỉnh ELO', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'assign_tags',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sell_rounded,
                        size: 16,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.memberTagMenu,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'kick',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_remove_rounded,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.club_kickFromClub,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'ban',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.block_rounded,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Cấm khỏi câu lạc bộ',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
