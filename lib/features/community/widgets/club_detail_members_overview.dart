part of '../screens/club_detail_screen.dart';

extension _ClubDetailMembersOverview on _ClubDetailScreenState {
  Widget _buildMembersTab(Community club, AppColorsExtension colors) {
    if (club.visibility.toUpperCase() == 'PRIVATE' && !_isMember) {
      return _buildPrivateLockView(
        icon: Icons.people_rounded,
        title: 'Danh sách thành viên riêng tư',
        description:
            'CLB này đặt chế độ riêng tư. Hãy tham gia CLB để xem danh sách thành viên và kết nối giao lưu.',
        club: club,
        colors: colors,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final membersFeed = ref.watch(communityMembersFeedProvider(widget.clubId));
    final currentUserId = ref.watch(userProfileProvider).asData?.value.id;
    final isCreator = club.ownerId != null && club.ownerId == currentUserId;
    final isAdmin =
        isCreator ||
        club.myRole == 'OWNER' ||
        club.myRole == 'ADMIN' ||
        club.myRole == 'MODERATOR' ||
        _myMembership?.role == 'OWNER' ||
        _myMembership?.role == 'ADMIN' ||
        _myMembership?.role == 'MODERATOR';
    final joinRequestsAsync = isAdmin
        ? ref.watch(joinRequestsProvider(widget.clubId))
        : const AsyncValue.data(<CommunityMemberModel>[]);
    final rankingsAsync = ref.watch(communityRankingsProvider(widget.clubId));
    final memberEloMap = <String, int>{};
    final rankedMemberIds = <String>{};
    rankingsAsync.whenData((rankings) {
      for (final r in rankings) {
        if (r.userId.isNotEmpty) {
          memberEloMap[r.userId] = r.eloPoints;
          rankedMemberIds.add(r.userId);
        }
      }
    });

    if (membersFeed.isLoading && membersFeed.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (membersFeed.errorMessage != null && membersFeed.members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.club_loadListError,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => ref
                  .read(communityMembersFeedProvider(widget.clubId).notifier)
                  .loadInitial(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (membersFeed.members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.club_noMembers,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final approvedMembers = membersFeed.members;
    final List<CommunityMemberModel> displayMembers = List.of(approvedMembers);
    if (_memberSortMode == 'elo') {
      displayMembers.sort((a, b) {
        final eloA = memberEloMap[a.userId] ?? -999999;
        final eloB = memberEloMap[b.userId] ?? -999999;
        final cmp = eloB.compareTo(eloA);
        if (cmp != 0) return cmp;
        return (a.userFullName ?? '').compareTo(b.userFullName ?? '');
      });
    }

    final membersNotifier = ref.read(
      communityMembersFeedProvider(widget.clubId).notifier,
    );
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical &&
            membersFeed.hasMore &&
            membersFeed.nextCursor != null &&
            !membersFeed.isLoading &&
            notification.metrics.extentAfter <= 520) {
          unawaited(membersNotifier.loadMore());
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: membersNotifier.loadInitial,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildJoinRequestsSection(joinRequestsAsync, colors),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Sắp xếp:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () =>
                        _updateClubState(() => _memberSortMode = 'role'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _memberSortMode == 'role'
                            ? AppTheme.primary
                            : colors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _memberSortMode == 'role'
                              ? AppTheme.primary
                              : colors.border,
                        ),
                      ),
                      child: Text(
                        'Chức vụ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _memberSortMode == 'role'
                              ? Colors.white
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () =>
                        _updateClubState(() => _memberSortMode = 'elo'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _memberSortMode == 'elo'
                            ? AppTheme.primary
                            : colors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _memberSortMode == 'elo'
                              ? AppTheme.primary
                              : colors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 13,
                            color: _memberSortMode == 'elo'
                                ? Colors.amber
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Elo giảm dần',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _memberSortMode == 'elo'
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...displayMembers.map(
              (m) => _buildMemberItem(
                m,
                colors,
                isAdmin,
                rankedMemberIds.contains(m.userId)
                    ? memberEloMap[m.userId]
                    : null,
                rankIndex: _memberSortMode == 'elo'
                    ? (displayMembers.indexOf(m) + 1)
                    : null,
              ),
            ),
            if (membersFeed.isLoading && approvedMembers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đang tải thêm thành viên…',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            if (membersFeed.errorMessage != null && approvedMembers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  membersFeed.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
