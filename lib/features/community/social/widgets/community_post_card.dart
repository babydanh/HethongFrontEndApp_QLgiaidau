import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityPostCard extends ConsumerWidget {
  final CommunityPostModel post;
  final String communityId;
  final ValueChanged<String>? onReact;
  final bool commentsEnabled;

  const CommunityPostCard({super.key, required this.post, required this.communityId, this.onReact, this.commentsEnabled = true});

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
                CircleAvatar(
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
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        _relativeTime(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  Icon(Icons.push_pin_rounded, size: 18, color: colors.info),
                IconButton(
                  tooltip: 'Tuỳ chọn bài đăng',
                  onPressed: () {},
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            if (post.topicTags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSM),
              Wrap(
                spacing: AppTheme.spacingXS,
                runSpacing: AppTheme.spacingXS,
                children: post.topicTags.map((tag) => Chip(
                  label: Text('#$tag'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppTheme.primaryLight,
                  labelStyle: const TextStyle(color: AppTheme.primaryDark, fontSize: 12),
                  side: BorderSide.none,
                )).toList(),
              ),
            ],
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    post.mediaUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: colors.bgSurface,
                      child: const Center(child: Icon(Icons.broken_image_outlined)),
                    ),
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
                    post.viewerReaction == 'CHEER' ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 18,
                    color: post.viewerReaction == 'CHEER' ? colors.error : colors.textMuted,
                  ),
                ),
                const SizedBox(width: 5),
                Text('${post.reactionCount}', style: TextStyle(color: colors.textMuted)),
                const SizedBox(width: AppTheme.spacingSM),
                if (commentsEnabled) IconButton(
                  tooltip: 'Bình luận',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showComments(context, ref),
                  icon: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: colors.textMuted),
                ),
                if (commentsEnabled) ...[
                  const SizedBox(width: 5),
                  Text('${post.commentCount}', style: TextStyle(color: colors.textMuted)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showComments(BuildContext context, WidgetRef ref) async {
    final comments = await ref.read(communitySocialRepositoryProvider).getComments(communityId, post.id);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CommentSheet(
        communityId: communityId,
        postId: post.id,
        comments: comments,
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

class _CommentSheet extends ConsumerStatefulWidget {
  final String communityId;
  final String postId;
  final List<CommunityCommentModel> comments;

  const _CommentSheet({required this.communityId, required this.postId, required this.comments});

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  late List<CommunityCommentModel> _comments;

  @override
  void initState() {
    super.initState();
    _comments = [...widget.comments];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await ref.read(communitySocialRepositoryProvider).createComment(widget.communityId, widget.postId, body: body);
      if (mounted) setState(() { _comments = [..._comments, comment]; _controller.clear(); });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể gửi bình luận.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spacingMD, AppTheme.spacingMD, AppTheme.spacingMD, AppTheme.spacingSM),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Bình luận', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppTheme.spacingSM),
        if (_comments.isEmpty) const Padding(padding: EdgeInsets.all(AppTheme.spacingMD), child: Text('Chưa có bình luận.'))
        else ..._comments.map((comment) => ListTile(dense: true, title: Text(comment.authorName), subtitle: Text(comment.body))),
        Row(children: [
          Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'Viết bình luận…'))),
          IconButton(onPressed: _sending ? null : _submit, icon: const Icon(Icons.send_rounded)),
        ]),
      ]),
    ),
  );
}
