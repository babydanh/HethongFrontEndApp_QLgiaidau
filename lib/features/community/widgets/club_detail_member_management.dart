part of '../screens/club_detail_screen.dart';

extension _ClubDetailMemberManagement on _ClubDetailScreenState {
  Future<void> _openTagAssignSheet(CommunityMemberModel m) async {
    final repo = ref.read(communityRepositoryProvider);
    final presets = await repo.getTagPresets(widget.clubId);
    if (!mounted) return;
    await TagAssignSheet.show(
      context,
      memberName: m.userFullName ?? '',
      currentTags: m.tags,
      presets: presets,
      onSave: (tags) async {
        await repo.updateMemberTags(
          widget.clubId,
          m.userId.isNotEmpty ? m.userId : m.id,
          tags,
        );
        ref.invalidate(communityMembersProvider(widget.clubId));
        ref.invalidate(communityMembersFeedProvider(widget.clubId));
      },
    );
  }

  Widget _buildJoinRequestsSection(
    AsyncValue<List<CommunityMemberModel>> joinRequestsAsync,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return joinRequestsAsync.when(
      data: (requests) {
        final pending = requests.where((r) => r.status == 'PENDING').toList();
        if (pending.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.club_joinRequests(pending.length),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...pending.map((req) => _buildJoinRequestCard(req, colors)),
            const SizedBox(height: 16),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 12),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (context, error) => const SizedBox.shrink(),
    );
  }

  Widget _buildJoinRequestCard(
    CommunityMemberModel req,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            child: Text(
              (req.userFullName?.isNotEmpty == true
                      ? req.userFullName![0]
                      : '?')
                  .toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.userFullName ?? l10n.dashboard_user,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.club_pendingApproval,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              try {
                await ref
                    .read(communityRepositoryProvider)
                    .reviewJoinRequest(
                      widget.clubId,
                      req.userId.isNotEmpty ? req.userId : req.id,
                      'APPROVE',
                    );
                ref.invalidate(joinRequestsProvider(widget.clubId));
                ref.invalidate(communityMembersProvider(widget.clubId));
                ref.invalidate(communityMembersFeedProvider(widget.clubId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.club_approvedMember),
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
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.club_approve,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              try {
                await ref
                    .read(communityRepositoryProvider)
                    .reviewJoinRequest(
                      widget.clubId,
                      req.userId.isNotEmpty ? req.userId : req.id,
                      'REJECT',
                    );
                ref.invalidate(joinRequestsProvider(widget.clubId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.club_rejected),
                      backgroundColor: Colors.orange,
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
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                l10n.club_reject,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 4: ẢNH (Gallery)
  // ════════════════════════════════════
}
