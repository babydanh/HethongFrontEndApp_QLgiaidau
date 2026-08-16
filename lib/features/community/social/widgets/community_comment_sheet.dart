import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityCommentSheet extends ConsumerStatefulWidget {
  final String communityId;
  final String postId;
  final CommunityCommentPage initialPage;
  final String currentUserId;
  final bool canModerate;
  final VoidCallback? onCommentUpdated;

  const CommunityCommentSheet({
    super.key,
    required this.communityId,
    required this.postId,
    required this.initialPage,
    this.currentUserId = '',
    this.canModerate = false,
    this.onCommentUpdated,
  });

  @override
  ConsumerState<CommunityCommentSheet> createState() =>
      _CommunityCommentSheetState();
}

class _CommunityCommentSheetState extends ConsumerState<CommunityCommentSheet> {
  final _controller = TextEditingController();
  late List<CommunityCommentModel> _comments;
  String? _cursor;
  String? _replyTo;
  bool _busy = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _comments = [...widget.initialPage.items];
    _cursor = widget.initialPage.nextCursor;
    _hasMore = widget.initialPage.hasMore;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_busy || !_hasMore) return;
    setState(() => _busy = true);
    try {
      final page = await ref
          .read(communitySocialRepositoryProvider)
          .getComments(widget.communityId, widget.postId, cursor: _cursor);
      if (mounted) {
        setState(() {
          _comments = [..._comments, ...page.items];
          _cursor = page.nextCursor;
          _hasMore = page.hasMore;
        });
      }
    } catch (_) {
      if (mounted) _showMessage('Không thể tải thêm bình luận.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final comment = await ref
          .read(communitySocialRepositoryProvider)
          .createComment(
            widget.communityId,
            widget.postId,
            body: body,
            parentId: _replyTo,
          );
      if (mounted) {
        setState(() {
          _comments = [..._comments, comment];
          _controller.clear();
          _replyTo = null;
        });
        widget.onCommentUpdated?.call();
      }
    } catch (_) {
      if (mounted) _showMessage('Không thể gửi bình luận.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CommunityCommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bình luận?'),
        content: const Text('Bình luận sẽ bị xóa khỏi bài viết.'),
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
    if (confirmed != true || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(communitySocialRepositoryProvider)
          .deleteComment(widget.communityId, comment.id);
      if (mounted)
        setState(() => _comments.removeWhere((item) => item.id == comment.id));
      widget.onCommentUpdated?.call();
    } catch (_) {
      if (mounted) _showMessage('Không thể xóa bình luận.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMD,
          AppTheme.spacingMD,
          AppTheme.spacingMD,
          AppTheme.spacingSM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bình luận',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppTheme.spacingMD),
                      child: Text('Chưa có bình luận.'),
                    ),
                  ..._comments.map(
                    (comment) => Padding(
                      padding: EdgeInsets.only(
                        left: comment.parentId == null ? 0 : AppTheme.spacingMD,
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(comment.authorName),
                        subtitle: Text(comment.body),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip: 'Trả lời',
                              onPressed: () =>
                                  setState(() => _replyTo = comment.id),
                              icon: const Icon(Icons.reply_outlined, size: 18),
                            ),
                            if (comment.authorId == widget.currentUserId ||
                                widget.canModerate)
                              IconButton(
                                tooltip: 'Xóa',
                                onPressed: () => _delete(comment),
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: colors.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_hasMore)
                    TextButton(
                      onPressed: _busy ? null : _loadMore,
                      child: Text(_busy ? 'Đang tải...' : 'Xem thêm bình luận'),
                    ),
                ],
              ),
            ),
            if (_replyTo != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _replyTo = null),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Hủy trả lời'),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: _replyTo == null
                          ? 'Viết bình luận…'
                          : 'Viết câu trả lời…',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : _submit,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
