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

    return Container(
      color: colors.bgCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (Avatar, Author, Tags, Time, Actions) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryLight,
                    backgroundImage: post.authorAvatarUrl == null
                        ? null
                        : NetworkImage(post.authorAvatarUrl!),
                    child: post.authorAvatarUrl == null
                        ? Text(
                            post.authorName.characters.first.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final presets = ref
                              .watch(communityTagPresetsProvider(communityId))
                              .asData
                              ?.value;
                          final member = ref
                              .watch(
                                communityMemberDirectoryProvider(communityId),
                              )
                              .asData
                              ?.value[post.authorId];
                          final memberRole = member?.role
                              .toString()
                              .toUpperCase();
                          final tags = (member?.tags ?? const <String>[])
                              .take(2)
                              .toList();
                          return Wrap(
                            spacing: 6,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: onAuthorTap,
                                child: Text(
                                  post.authorName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                      ),
                                ),
                              ),
                              if (memberRole == 'OWNER')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Chủ CLB',
                                    style: TextStyle(
                                      color: AppTheme.primaryDark,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else if (memberRole == 'ADMIN' ||
                                  memberRole == 'MODERATOR')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.info.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'BQT',
                                    style: TextStyle(
                                      color: colors.info,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
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
                        },
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _relativeTime(post.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.textMuted,
                                  fontSize: 12,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.public_rounded,
                            size: 12,
                            color: colors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.push_pin_rounded,
                      size: 18,
                      color: colors.info,
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Xóa bài viết',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: colors.error,
                    ),
                  ),
                IconButton(
                  tooltip: 'Tuỳ chọn bài đăng',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showPostActions(context),
                  icon: Icon(Icons.more_horiz_rounded, color: colors.textMuted),
                ),
              ],
            ),
          ),

          // ── Text Content with Rich Mentions & Hashtags ──
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildRichText(post.text, context, colors),
            ),

          // ── Pending Approval Notice ──
          if (post.status == 'PENDING')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: colors.warning.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: 16,
                      color: colors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bài viết đang chờ ban quản trị duyệt.',
                        style: TextStyle(
                          color: colors.warning,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Tournament Preview ──
          if (post.tournamentId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: CommunityTournamentPreview(post: post),
            ),

          // ── Poll Widget ──
          if (post.poll != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: CommunityPollWidget(
                communityId: communityId,
                poll: post.poll!,
                tournamentId: post.tournamentId,
                tournamentInviteCode: post.tournamentInviteCode,
              ),
            ),

          // ── Topic Tags ──
          if (post.topicTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Wrap(
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
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ),

          // ── Edge-to-Edge Media / Photo Preview (Full width like Facebook) ──
          if (post.mediaUrls.isNotEmpty)
            GestureDetector(
              onTap: () => _showMediaGallery(context),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      post.mediaUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: colors.bgSurface,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 36),
                        ),
                      ),
                    ),
                    if (post.mediaUrls.length > 1)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.collections_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '1/${post.mediaUrls.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // ── Reaction & Comment Summary (Facebook Count Row) ──
          if (post.reactionCount > 0 || post.commentCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (post.reactionCount > 0)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.reactionCount}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  if (post.commentCount > 0)
                    Text(
                      '${post.commentCount} bình luận',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

          // ── Facebook-style Action Buttons Bar (Yêu thích & Bình luận) ──
          Divider(
            height: 1,
            thickness: 0.8,
            color: colors.borderLight.withValues(alpha: 0.6),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onReact == null ? null : () => onReact!('CHEER'),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            post.viewerReaction == 'CHEER'
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 19,
                            color: post.viewerReaction == 'CHEER'
                                ? const Color(0xFFEF4444)
                                : colors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Yêu thích',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: post.viewerReaction == 'CHEER'
                                  ? const Color(0xFFEF4444)
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (commentsEnabled)
                  Expanded(
                    child: InkWell(
                      onTap: () => _showComments(context, ref),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Bình luận',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
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

  Widget _buildRichText(
    String text,
    BuildContext context,
    AppColorsExtension colors,
  ) {
    final regex = RegExp(
      r'(@[^\s@#]+(?:\s+[^\s@#]+)*|#[a-zA-Z0-9_\u00C0-\u1EF9]+)',
    );
    final matches = regex.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.45,
          color: colors.textPrimary,
        ),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: colors.textPrimary,
            ),
          ),
        );
      }
      final token = match.group(0)!;
      final isMention = token.startsWith('@');
      spans.add(
        TextSpan(
          text: token,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w700,
            color: isMention ? AppTheme.primary : AppTheme.primaryDark,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: colors.textPrimary,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
