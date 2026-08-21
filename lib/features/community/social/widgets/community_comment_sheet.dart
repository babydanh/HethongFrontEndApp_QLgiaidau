import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
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
  final _focusNode = FocusNode();
  late List<CommunityCommentModel> _comments;
  final Set<String> _likedComments = <String>{};
  String? _cursor;
  String? _replyTo;
  String? _replyAuthorName;
  bool _busy = false;
  bool _hasMore = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _comments = [...widget.initialPage.items];
    _cursor = widget.initialPage.nextCursor;
    _hasMore = widget.initialPage.hasMore;
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _canSend) {
        setState(() => _canSend = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    final l10n = AppLocalizations.of(context)!;
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
      if (mounted) _showMessage(l10n.communityComment_loadMoreError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
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
          _replyAuthorName = null;
          _canSend = false;
        });
        _focusNode.unfocus();
        widget.onCommentUpdated?.call();
      }
    } catch (_) {
      if (mounted) _showMessage(l10n.communityComment_submitError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startReply(CommunityCommentModel comment) {
    setState(() {
      _replyTo = comment.id;
      _replyAuthorName = comment.authorName;
      final mentionPrefix = '@${comment.authorName} ';
      if (!_controller.text.startsWith(mentionPrefix)) {
        _controller.text = '$mentionPrefix${_controller.text}';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    });
    _focusNode.requestFocus();
  }

  void _toggleLike(String commentId) {
    setState(() {
      if (_likedComments.contains(commentId)) {
        _likedComments.remove(commentId);
      } else {
        _likedComments.add(commentId);
      }
    });
  }

  Future<void> _delete(CommunityCommentModel comment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.communityComment_deleteTitle),
        content: Text(l10n.communityComment_deleteDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.communityComment_delete),
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
      if (mounted) {
        setState(() {
          final deletedIds = {comment.id};
          for (final c in _comments) {
            if (c.parentId == comment.id) deletedIds.add(c.id);
          }
          _comments.removeWhere((item) => deletedIds.contains(item.id));
        });
      }
      widget.onCommentUpdated?.call();
    } catch (_) {
      if (mounted) _showMessage(l10n.communityComment_deleteError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  String _relativeTime(DateTime? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null) return l10n.communityComment_justNow;
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 1) return l10n.communityComment_justNow;
    if (difference.inHours < 1) return l10n.communityComment_minutes(difference.inMinutes);
    if (difference.inDays < 1) return l10n.communityComment_hours(difference.inHours);
    if (difference.inDays < 7) return l10n.communityComment_days(difference.inDays);
    return '${value.day}/${value.month}';
  }

  /// Parse text for @mentions and #hashtags, highlighting them like web
  Widget _buildRichCommentText(String text, BuildContext context, AppColorsExtension colors) {
    final regex = RegExp(r'(@[^\s@#]+(?:\s+[^\s@#]+)*|#[a-zA-Z0-9_\u00C0-\u1EF9]+)');
    final matches = regex.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(fontSize: 14, height: 1.35, color: colors.textPrimary),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(fontSize: 14, height: 1.35, color: colors.textPrimary),
        ));
      }
      final token = match.group(0)!;
      final isMention = token.startsWith('@');
      spans.add(TextSpan(
        text: token,
        style: TextStyle(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: isMention ? AppTheme.primary : AppTheme.primaryDark,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(fontSize: 14, height: 1.35, color: colors.textPrimary),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final presets = ref.watch(communityTagPresetsProvider(widget.communityId)).asData?.value;
    final memberDirectory = ref.watch(communityMemberDirectoryProvider(widget.communityId)).asData?.value;

    // Group comments into root comments and nested replies
    final rootComments = _comments.where((c) => c.parentId == null).toList();
    final repliesMap = <String, List<CommunityCommentModel>>{};
    for (final c in _comments) {
      if (c.parentId != null) {
        repliesMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag Handle ──
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: colors.borderLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // ── Header (Title + Count + Close Button) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 8, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.communityComment_title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                      ),
                    ),
                    if (_comments.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_comments.length}',
                          style: const TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      tooltip: l10n.communityComment_close,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, size: 20, color: colors.textMuted),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 0.8,
                color: colors.borderLight.withValues(alpha: 0.6),
              ),

              // ── Comment List (Threaded Facebook Bubbles) ──
              Flexible(
                child: _comments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 44,
                                color: colors.textMuted.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.communityComment_empty,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.communityComment_emptyHint,
                                style: TextStyle(
                                  color: colors.textMuted.withValues(alpha: 0.7),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: rootComments.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == rootComments.length) {
                            return Center(
                              child: TextButton.icon(
                                onPressed: _busy ? null : _loadMore,
                                icon: _busy
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.expand_more_rounded, size: 16),
                                label: Text(
                                  _busy ? l10n.communityComment_loading : l10n.communityComment_loadMore,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          }

                          final comment = rootComments[index];
                          final childReplies = repliesMap[comment.id] ?? const [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCommentItem(
                                comment: comment,
                                isReply: false,
                                bubbleColor: bubbleColor,
                                memberDirectory: memberDirectory,
                                presets: presets,
                                colors: colors,
                                l10n: l10n,
                              ),
                              // Render child replies indented
                              if (childReplies.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 36, top: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: childReplies
                                        .map(
                                          (reply) => _buildCommentItem(
                                            comment: reply,
                                            isReply: true,
                                            bubbleColor: bubbleColor,
                                            memberDirectory: memberDirectory,
                                            presets: presets,
                                            colors: colors,
                                            l10n: l10n,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),

              // ── Reply Indicator Banner ──
              if (_replyTo != null)
                Container(
                  width: double.infinity,
                  color: isDark ? const Color(0xFF242526) : const Color(0xFFE4E6EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  child: Row(
                    children: [
                      const Icon(Icons.reply_rounded, size: 15, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.communityComment_replyingTo(
                            _replyAuthorName ?? l10n.communityComment_title.toLowerCase(),
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _replyTo = null;
                          _replyAuthorName = null;
                        }),
                        child: Icon(Icons.close_rounded, size: 16, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),

              // ── Facebook-style Input Bar at Bottom ──
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  border: Border(
                    top: BorderSide(
                      color: colors.borderLight.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Current User Avatar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, right: 8),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppTheme.primaryLight,
                        backgroundImage: profile?.avatarUrl == null
                            ? null
                            : NetworkImage(profile!.avatarUrl!),
                        child: profile?.avatarUrl == null
                            ? Builder(
                                builder: (_) {
                                  final name = profile?.fullName?.trim() ?? '';
                                  final initial = name.isNotEmpty
                                      ? name.characters.first.toUpperCase()
                                      : 'B';
                                  return Text(
                                    initial,
                                    style: const TextStyle(
                                      color: AppTheme.primaryDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    ),

                    // Pill TextField Container
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _replyTo == null
                                ? l10n.communityComment_write
                                : l10n.communityComment_replyHint(
                                    _replyAuthorName ?? l10n.communityComment_member,
                                  ),
                            hintStyle: TextStyle(
                              color: colors.textMuted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Send Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: IconButton(
                        tooltip: l10n.communityComment_send,
                        visualDensity: VisualDensity.compact,
                        onPressed: (_canSend && !_busy) ? _submit : null,
                        icon: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: _canSend ? AppTheme.primary : colors.textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem({
    required CommunityCommentModel comment,
    required bool isReply,
    required Color bubbleColor,
    required Map<String, dynamic>? memberDirectory,
    required List<CommunityTagPreset>? presets,
    required AppColorsExtension colors,
    required AppLocalizations l10n,
  }) {
    final member = memberDirectory?[comment.authorId];
    final memberRole = member?.role?.toString().toUpperCase();
    final tags = (member?.tags is List ? (member!.tags as List).map((t) => t.toString()).toList() : const <String>[]).take(2).toList();
    final isLiked = _likedComments.contains(comment.id);

    return Padding(
      padding: EdgeInsets.only(top: isReply ? 4 : 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author Avatar ──
          GestureDetector(
            onTap: comment.authorId.isEmpty
                ? null
                : () => UserProfileBottomSheet.show(
                    context,
                    userId: comment.authorId,
                    communityId: widget.communityId,
                    initialFullName: comment.authorName,
                    initialAvatarUrl: comment.authorAvatarUrl,
                  ),
            child: CircleAvatar(
              radius: isReply ? 14 : 18,
              backgroundColor: AppTheme.primaryLight,
              backgroundImage: comment.authorAvatarUrl == null
                  ? null
                  : NetworkImage(comment.authorAvatarUrl!),
              child: comment.authorAvatarUrl == null
                  ? Text(
                      comment.authorName.characters.first.toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: isReply ? 10.5 : 13,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),

          // ── Speech Bubble + Action Row ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Bubble Box ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Name, Role Badges & Tags
                      Wrap(
                        spacing: 5,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: comment.authorId.isEmpty
                                ? null
                                : () => UserProfileBottomSheet.show(
                                    context,
                                    userId: comment.authorId,
                                    communityId: widget.communityId,
                                    initialFullName: comment.authorName,
                                    initialAvatarUrl: comment.authorAvatarUrl,
                                  ),
                            child: Text(
                              comment.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          // Role Badge (Chủ nhiệm / BQT)
                          if (memberRole == 'OWNER')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.communityComment_owner,
                                style: TextStyle(
                                  color: AppTheme.primaryDark,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else if (memberRole == 'ADMIN' || memberRole == 'MODERATOR')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: colors.info.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.communityComment_admin,
                                style: TextStyle(
                                  color: colors.info,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          // Custom Preset Tags
                          ...tags.map(
                            (tag) => PresetTagChip(
                              label: tag,
                              color: presets == null
                                  ? null
                                  : resolvePresetColor(presets, tag),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Comment Rich Body
                      _buildRichCommentText(comment.body, context, colors),
                    ],
                  ),
                ),

                // ── Actions Below Bubble (Time, Thích, Trả lời, Xóa) ──
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4, bottom: 2),
                  child: Row(
                    children: [
                      Text(
                        _relativeTime(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => _toggleLike(comment.id),
                        child: Text(
                          l10n.communityComment_like,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isLiked ? AppTheme.primary : colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => _startReply(comment),
                        child: Text(
                          l10n.communityComment_reply,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      if (comment.authorId == widget.currentUserId ||
                          widget.canModerate) ...[
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => _delete(comment),
                          child: Text(
                            l10n.communityComment_delete,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.error,
                            ),
                          ),
                        ),
                      ],
                      if (isLiked) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_rounded, size: 8.5, color: Colors.white),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '1',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
