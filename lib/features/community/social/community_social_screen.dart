import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_composer_trigger.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_post_composer_sheet.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_post_card.dart';
import 'package:app_quanly_giaidau/features/community/widgets/tag_assign_sheet.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Màn sinh hoạt CLB gọn cho mobile. Có thể mở từ club detail hoặc tab CLB.
/// Đăng bài qua composer bottom sheet kiểu Facebook (đủ tính năng như web).
class CommunitySocialScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;
  final bool showHeader;

  const CommunitySocialScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    this.showHeader = true,
  });

  @override
  ConsumerState<CommunitySocialScreen> createState() =>
      _CommunitySocialScreenState();
}

class _CommunitySocialScreenState extends ConsumerState<CommunitySocialScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted)
        ref
            .read(communityFeedProvider(widget.communityId).notifier)
            .loadInitial();
    });
  }

  /// Gắn controller riêng vào ListView bên trong NestedScrollView sẽ phá vỡ
  /// phối hợp scroll (2 list scroll riêng). Dùng notification để loadMore —
  /// hoạt động cả standalone lẫn nhúng trong club detail.
  bool _onFeedScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 520) {
      ref.read(communityFeedProvider(widget.communityId).notifier).loadMore();
    }
    return false;
  }

  void _openComposer({
    bool startWithPoll = false,
    bool startWithImage = false,
  }) {
    final membership = ref
        .read(myCommunityMembershipProvider(widget.communityId))
        .asData
        ?.value;
    final isPlatformAdmin = ref.read(authProvider).isAdmin;
    final role = membership?.role.toUpperCase();
    final isJoined = membership?.status.toUpperCase() == 'JOINED';
    final canManageMemberTags =
        isPlatformAdmin ||
        (isJoined &&
            (role == 'OWNER' || role == 'ADMIN' || role == 'MODERATOR'));
    final settings = ref
        .read(communitySocialSettingsProvider(widget.communityId))
        .asData
        ?.value;
    final canMention = settings == null
        ? isJoined
        : (settings.memberTaggingPolicy == 'MEMBERS'
              ? isJoined
              : settings.memberTaggingPolicy == 'ADMINS' &&
                    canManageMemberTags);
    CommunityPostComposerSheet.show(
      context,
      communityId: widget.communityId,
      authorName: ref.read(userProfileProvider).asData?.value.fullName ?? 'Bạn',
      authorAvatarUrl: ref.read(userProfileProvider).asData?.value.avatarUrl,
      canMention: canMention,
      canManageTags: canManageMemberTags,
      onAssignMemberTags: _openMemberTagEditor,
      startWithPoll: startWithPoll,
      startWithImage: startWithImage,
    );
  }

  Future<void> _confirmDeletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: const Text(
          'Bài viết sẽ bị xóa khỏi bảng tin. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(communitySocialRepositoryProvider)
          .deletePost(widget.communityId, postId);
      await ref
          .read(communityFeedProvider(widget.communityId).notifier)
          .loadInitial();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa bài viết.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa bài viết.')),
        );
    }
  }

  Future<void> _openMemberTagEditor(CommunityMemberModel member) async {
    final repo = ref.read(communityRepositoryProvider);
    final presets = await repo.getTagPresets(widget.communityId);
    if (!mounted) return;
    await TagAssignSheet.show(
      context,
      memberName: member.userFullName?.trim().isNotEmpty == true
          ? member.userFullName!.trim()
          : (member.userEmail?.split('@').first ?? 'Thành viên'),
      currentTags: member.tags,
      presets: presets,
      onSave: (tags) async {
        await repo.updateMemberTags(
          widget.communityId,
          member.userId.isNotEmpty ? member.userId : member.id,
          tags,
        );
        ref.invalidate(communityMembersProvider(widget.communityId));
        ref.invalidate(communityMemberSearchProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityFeedProvider(widget.communityId));
    final membership = ref
        .watch(myCommunityMembershipProvider(widget.communityId))
        .value;
    final profile = ref.watch(userProfileProvider).asData?.value;
    final currentUserId = profile?.id ?? '';
    final currentAvatarUrl = profile?.avatarUrl?.trim();
    final currentAuthorName = (profile?.fullName?.isNotEmpty == true
        ? profile!.fullName!
        : 'Bạn').trim();
    final socialSettings =
        ref.watch(communitySocialSettingsProvider(widget.communityId)).value ??
        const CommunitySocialSettings(
          postingPolicy: 'OFF',
          commentsEnabled: false,
          chatEnabled: false,
          publicFeed: false,
          memberTaggingPolicy: 'OFF',
        );
    final isPlatformAdmin = ref.watch(authProvider).isAdmin;
    final role = membership?.role.toUpperCase();
    final canManageMemberTags =
        isPlatformAdmin ||
        (membership?.status.toUpperCase() == 'JOINED' &&
            (role == 'OWNER' || role == 'ADMIN' || role == 'MODERATOR'));
    final isJoined = membership?.status.toUpperCase() == 'JOINED';
    final isModerator =
        isPlatformAdmin ||
        (isJoined &&
            (role == 'OWNER' || role == 'ADMIN' || role == 'MODERATOR'));
    final canPost =
        isPlatformAdmin ||
        (socialSettings.postingPolicy == 'MEMBERS' && isJoined) ||
        (socialSettings.postingPolicy == 'ADMINS' && canManageMemberTags);

    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    final feedBody = Container(
      color: canvasColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onFeedScroll,
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(communityFeedProvider(widget.communityId).notifier)
              .loadInitial(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXL),
            children: [
              if (widget.showHeader) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _CompactHighlights(communityName: widget.communityName),
                ),
              ],
              if (canPost)
                Container(
                  color: colors.bgCard,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CommunityComposerTrigger(
                    authorName: currentAuthorName,
                    authorAvatarUrl: currentAvatarUrl,
                    onOpen: () => _openComposer(),
                    onOpenWithPoll: () => _openComposer(startWithPoll: true),
                    onOpenWithImage: () => _openComposer(startWithImage: true),
                  ),
                ),
              if (!canPost)
                Container(
                  color: colors.bgCard,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: _SocialNotice(
                    message: socialSettings.postingPolicy == 'OFF'
                        ? 'CLB đang tắt đăng bài.'
                        : 'Hãy tham gia CLB để đăng bài.',
                  ),
                ),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _FeedError(
                    message: state.errorMessage!,
                    onRetry: () => ref
                        .read(communityFeedProvider(widget.communityId).notifier)
                        .loadInitial(),
                  ),
                ),
              if (state.isLoading && state.posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: _FeedLoading(),
                ),
              if (!state.isLoading &&
                  state.errorMessage == null &&
                  state.posts.isEmpty)
                Container(
                  color: colors.bgCard,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const _FeedEmpty(),
                ),
              ...state.posts.map(
                (post) => CommunityPostCard(
                  post: post,
                  communityId: widget.communityId,
                  commentsEnabled: socialSettings.commentsEnabled,
                  onReact: (reaction) => ref
                      .read(communityFeedProvider(widget.communityId).notifier)
                      .reactToPost(post.id, reaction),
                  currentUserId: currentUserId,
                  canModerateComments: isModerator,
                  onCommentUpdated: () => ref
                      .read(communityFeedProvider(widget.communityId).notifier)
                      .loadInitial(),
                  onAuthorTap: post.authorId.isEmpty
                      ? null
                      : () => context.push(
                          '/profile/user/${post.authorId}?communityId=${widget.communityId}'),
                  onDelete:
                      (currentUserId.isNotEmpty &&
                          (post.authorId == currentUserId || isModerator))
                      ? () => _confirmDeletePost(post.id)
                      : null,
                ),
              ),
              if (state.isLoading && state.posts.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppTheme.spacingMD),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );

    if (!widget.showHeader) {
      return feedBody;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communityName),
        actions: [
          if (socialSettings.chatEnabled)
            IconButton(
              tooltip: 'Mở trò chuyện CLB',
              onPressed: () => context.push(
                '/club/${widget.communityId}/chat?name=${Uri.encodeComponent(widget.communityName)}',
              ),
              icon: const Icon(Icons.forum_outlined),
            ),
        ],
      ),
      body: feedBody,
      floatingActionButton: socialSettings.chatEnabled
          ? FloatingActionButton.small(
              tooltip: 'Mở trò chuyện CLB',
              onPressed: () => context.push(
                '/club/${widget.communityId}/chat?name=${Uri.encodeComponent(widget.communityName)}',
              ),
              child: const Icon(Icons.chat_bubble_rounded),
            )
          : null,
    );
  }
}

class _CompactHighlights extends StatelessWidget {
  final String communityName;
  const _CompactHighlights({required this.communityName});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _Highlight(
          label: communityName,
          icon: Icons.groups_rounded,
          color: AppTheme.primary,
        ),
        const _Highlight(
          label: 'Trận gần đây',
          icon: Icons.sports_tennis_rounded,
          color: Color(0xFF8B5CF6),
        ),
        const _Highlight(
          label: 'Bảng ELO',
          icon: Icons.leaderboard_rounded,
          color: Color(0xFFF59E0B),
        ),
      ],
    ),
  );
}

class _Highlight extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Highlight({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 118,
    margin: const EdgeInsets.only(right: AppTheme.spacingSM),
    padding: const EdgeInsets.all(AppTheme.spacingSM),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(color: color.withValues(alpha: .25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const Spacer(),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppTheme.spacingXL),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXL),
    child: Center(
      child: Text('Chưa có bài đăng nào. Hãy chia sẻ điều đầu tiên!'),
    ),
  );
}

class _FeedError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FeedError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.cloud_off_rounded),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('Thử lại')),
    ),
  );
}

class _SocialNotice extends StatelessWidget {
  final String message;
  const _SocialNotice({required this.message});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.info_outline_rounded),
      title: Text(message),
    ),
  );
}
