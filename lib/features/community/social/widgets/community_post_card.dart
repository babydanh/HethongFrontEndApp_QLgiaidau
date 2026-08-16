import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_poll_widget.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_tournament_preview.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_comment_sheet.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/shared/widgets/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityPostCard extends ConsumerWidget {
  final CommunityPostModel post;
  final String communityId;
  final ValueChanged<String>? onReact;
  final bool commentsEnabled;
  final VoidCallback? onDelete;
  final String currentUserId;
  final bool canModerateComments;
  final VoidCallback? onCommentUpdated;
  final VoidCallback? onAuthorTap;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.communityId,
    this.onReact,
    this.commentsEnabled = true,
    this.onDelete,
    this.currentUserId = '',
    this.canModerateComments = false,
    this.onCommentUpdated,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: colors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: AppTheme.primaryLight,
                    backgroundImage: post.authorAvatarUrl == null
                        ? null
                        : NetworkImage(post.authorAvatarUrl!),
                    child: post.authorAvatarUrl == null
                        ? Text(
                            post.authorName.characters.first.toUpperCase(),
                            style: const TextStyle(color: AppTheme.primaryDark),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(builder: (context) {
                        // Tag CLB cạnh tên tác giả (tối đa 2, như web CommunityPostCard).
                        final presets = ref
                            .watch(communityTagPresetsProvider(communityId))
                            .asData
                            ?.value;
                        final member = ref
                            .watch(communityMemberDirectoryProvider(communityId))
                            .asData
                            ?.value[post.authorId];
                        final tags = (member?.tags ?? const <String>[]).take(2).toList();
                        return Wrap(
                          spacing: 5,
                          runSpacing: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: onAuthorTap,
                              child: Text(
                                post.authorName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            ...tags.map(
                              (tag) => PresetTagChip(
                                label: tag,
                                color: presets == null
                                    ? null
                                    : resolvePresetColor(presets, tag),
                              ),
                            ),
                          ],
                        );
                      }),
                      Text(
                        _relativeTime(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  Icon(Icons.push_pin_rounded, size: 18, color: colors.info),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Xóa bài viết',
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.error,
                    ),
                  ),
                IconButton(
                  tooltip: 'Tuỳ chọn bài đăng',
                  onPressed: () => _showPostActions(context),
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSM),
              Text(post.text, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (post.status == 'PENDING') ...[
              const SizedBox(height: AppTheme.spacingSM),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  'Bài viết đang chờ ban quản trị duyệt.',
                  style: TextStyle(
                    color: colors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (post.tournamentId != null) ...[
              const SizedBox(height: AppTheme.spacingSM),
              CommunityTournamentPreview(post: post),
              /* Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GIẢI ĐẤU CLB',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                          ),
                          Text(
                            post.tournamentName ?? 'Giải đấu Câu lạc bộ',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryDark),
                  ],
                ),
              ), */
            ],
            if (post.poll != null) ...[
              const SizedBox(height: AppTheme.spacingSM),
              CommunityPollWidget(communityId: communityId, poll: post.poll!),
            ],
            if (post.topicTags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSM),
              Wrap(
                spacing: AppTheme.spacingXS,
                runSpacing: AppTheme.spacingXS,
                children: post.topicTags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppTheme.primaryLight,
                        labelStyle: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: GestureDetector(
                  onTap: () => _showMediaGallery(context),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        post.mediaUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => ColoredBox(
                          color: colors.bgSurface,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      if (post.mediaUrls.length > 1)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                '1/${post.mediaUrls.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingSM),
            Row(
              children: [
                IconButton(
                  tooltip: 'Cổ vũ',
                  visualDensity: VisualDensity.compact,
                  onPressed: onReact == null ? null : () => onReact!('CHEER'),
                  icon: Icon(
                    post.viewerReaction == 'CHEER'
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: post.viewerReaction == 'CHEER'
                        ? colors.error
                        : colors.textMuted,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${post.reactionCount}',
                  style: TextStyle(color: colors.textMuted),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                if (commentsEnabled)
                  IconButton(
                    tooltip: 'Bình luận',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showComments(context, ref),
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ),
                if (commentsEnabled) ...[
                  const SizedBox(width: 5),
                  Text(
                    '${post.commentCount}',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showComments(BuildContext context, WidgetRef ref) async {
    final comments = await ref
        .read(communitySocialRepositoryProvider)
        .getComments(communityId, post.id);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => CommunityCommentSheet(
        communityId: communityId,
        postId: post.id,
        initialPage: comments,
        currentUserId: currentUserId,
        canModerate: canModerateComments,
        onCommentUpdated: onCommentUpdated,
      ),
    );
  }

  Future<void> _showPostActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Báo cáo bài viết'),
          onTap: () => Navigator.pop(sheetContext, 'report'),
        ),
      ),
    );
    if (!context.mounted || action != 'report') return;
    await ReportSheet.show(
      context,
      targetId: post.id,
      targetType: 'community_post',
    );
  }

  Future<void> _showMediaGallery(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            PageView.builder(
              itemCount: post.mediaUrls.length,
              itemBuilder: (context, index) => InteractiveViewer(
                child: Image.network(
                  post.mediaUrls[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime? value) {
    if (value == null) return 'Vừa đăng';
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 1) return 'Vừa đăng';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inDays < 1) return '${difference.inHours} giờ trước';
    return '${difference.inDays} ngày trước';
  }
}
