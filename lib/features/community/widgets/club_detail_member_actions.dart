part of '../screens/club_detail_screen.dart';

extension _ClubDetailMemberActions on _ClubDetailScreenState {
  Future<void> _handleMemberAction(
    String action,
    CommunityMemberModel m,
    AppColorsExtension colors,
    int currentElo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(communityRepositoryProvider);
    try {
      switch (action) {
        case 'promote_admin':
          await repo.updateMemberRole(
            widget.clubId,
            m.userId.isNotEmpty ? m.userId : m.id,
            'ADMIN',
          );
          break;
        case 'promote_mod':
          await repo.updateMemberRole(
            widget.clubId,
            m.userId.isNotEmpty ? m.userId : m.id,
            'MODERATOR',
          );
          break;
        case 'demote':
          await repo.updateMemberRole(
            widget.clubId,
            m.userId.isNotEmpty ? m.userId : m.id,
            'MEMBER',
          );
          break;
        case 'transfer_owner':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: colors.bgCard,
              title: const Text('Chuyển quyền Chủ sở hữu'),
              content: Text(
                'Bạn có chắc chắn muốn chuyển quyền Chủ sở hữu CLB cho ${m.userFullName ?? "thành viên này"}? Hành động này sẽ hạ vai trò của bạn xuống Quản trị viên.',
                style: TextStyle(color: colors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.matchesCancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Xác nhận chuyển',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
          if (confirm != true) return;
          await repo.updateMemberRole(
            widget.clubId,
            m.userId.isNotEmpty ? m.userId : m.id,
            'OWNER',
          );
          break;
        case 'adjust_elo':
          await MemberEloAdjustSheet.show(
            context,
            communityId: widget.clubId,
            userId: m.userId,
            memberName: m.userFullName ?? 'Thành viên',
            currentElo: currentElo,
            onSuccess: () {
              ref.invalidate(communityRankingsProvider(widget.clubId));
            },
          );
          ref.invalidate(communityRankingsProvider(widget.clubId));
          return;
        case 'kick':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: colors.bgCard,
              title: Text(l10n.club_deleteMemberTitle),
              content: Text(
                l10n.club_deleteMemberConfirm(m.userFullName ?? ''),
                style: TextStyle(color: colors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.matchesCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    l10n.delete,
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ],
            ),
          );
          if (confirm != true) return;
          await repo.removeMember(widget.clubId, m.userId);
          break;
        case 'ban':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: colors.bgCard,
              title: const Text('Cấm thành viên khỏi CLB'),
              content: Text(
                'Bạn có chắc muốn cấm ${m.userFullName ?? "thành viên này"} khỏi câu lạc bộ? Họ sẽ không thể xem hoặc tham gia lại.',
                style: TextStyle(color: colors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.matchesCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Cấm thành viên',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
          if (confirm != true) return;
          await repo.banMember(widget.clubId, m.userId);
          break;
        case 'assign_tags':
          // P2C.5 — gán tag BQT (bottom sheet tự đồng bộ member list sau khi lưu).
          await _openTagAssignSheet(m);
          break;
      }
      ref.invalidate(communityMembersProvider(widget.clubId));
      ref.invalidate(communityMembersFeedProvider(widget.clubId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.club_updatedMember),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clubDetailMemberActionError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// P2C.5 — Mở bottom sheet gán tag BQT; lưu qua repository rồi đồng bộ member list.
}
