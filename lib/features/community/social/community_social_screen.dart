import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_composer.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_post_card.dart';
import 'package:app_quanly_giaidau/features/community/widgets/tag_assign_sheet.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Màn sinh hoạt CLB gọn cho mobile. Có thể mở từ club detail hoặc tab CLB.
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
  ConsumerState<CommunitySocialScreen> createState() => _CommunitySocialScreenState();
}

class _CommunitySocialScreenState extends ConsumerState<CommunitySocialScreen> {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();
  final _selectedImages = <String>[];
  final _mentionIds = <String>[];
  String? _mentionQuery;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future<void>.microtask(() {
      if (mounted) ref.read(communityFeedProvider(widget.communityId).notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 520) {
      ref.read(communityFeedProvider(widget.communityId).notifier).loadMore();
    }
  }

  Future<void> _submitPost() async {
    final notifier = ref.read(communityFeedProvider(widget.communityId).notifier);
    final success = await notifier.createPost(
      text: _composerController.text,
      mediaUrls: List.unmodifiable(_selectedImages),
      mentions: List.unmodifiable(_mentionIds),
    );
    if (!mounted) return;
    if (success) {
      _composerController.clear();
      _selectedImages.clear();
      _mentionIds.clear();
      final createdPost = ref.read(communityFeedProvider(widget.communityId)).posts.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createdPost.status == 'PENDING'
                ? 'Bài viết đang chờ duyệt'
                : 'Đã đăng lên bảng tin',
          ),
        ),
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

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      final url = await ref.read(communitySocialRepositoryProvider).uploadImage(bytes, picked.name);
      if (mounted) setState(() => _selectedImages.add(url));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể tải ảnh lên.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityFeedProvider(widget.communityId));
    final membership = ref.watch(myCommunityMembershipProvider(widget.communityId)).value;
    final socialSettings = ref.watch(communitySocialSettingsProvider(widget.communityId)).value ?? const CommunitySocialSettings(
      postingPolicy: 'OFF',
      commentsEnabled: false,
      chatEnabled: false,
      publicFeed: false,
      memberTaggingPolicy: 'OFF',
    );
    final isPlatformAdmin = ref.watch(authProvider).isAdmin;
    final role = membership?.role.toUpperCase();
    final canManageMemberTags = isPlatformAdmin ||
        (membership?.status.toUpperCase() == 'JOINED' &&
            (role == 'OWNER' || role == 'ADMIN' || role == 'MODERATOR'));
    final isJoined = membership?.status.toUpperCase() == 'JOINED';
    final canPost = isPlatformAdmin ||
        (socialSettings.postingPolicy == 'MEMBERS' && isJoined) ||
        (socialSettings.postingPolicy == 'ADMINS' && canManageMemberTags);
    final canUseMemberTags = canManageMemberTags && socialSettings.memberTaggingPolicy != 'OFF';
    final canMentionMembers = socialSettings.memberTaggingPolicy == 'MEMBERS'
        ? isJoined
        : socialSettings.memberTaggingPolicy == 'ADMINS' && canManageMemberTags;
    final searchState = !canMentionMembers || _mentionQuery == null
        ? null
        : ref.watch(
            communityMemberSearchProvider((
              communityId: widget.communityId,
              query: _mentionQuery!,
            )),
          );

    final feedBody = RefreshIndicator(
      onRefresh: () => ref.read(communityFeedProvider(widget.communityId).notifier).loadInitial(),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(AppTheme.spacingMD, AppTheme.spacingSM, AppTheme.spacingMD, AppTheme.spacingXL),
        children: [
          if (widget.showHeader) ...[
            _CompactHighlights(communityName: widget.communityName),
            const SizedBox(height: AppTheme.spacingSM),
          ],
          if (canPost) CommunityComposer(
            controller: _composerController,
            isSubmitting: state.isSubmitting,
            onSubmit: _submitPost,
            onPickImage: _pickImage,
            imageCount: _selectedImages.length,
            mentionCandidates: searchState?.value ?? const [],
            isSearchingMembers: searchState?.isLoading ?? false,
            memberSearchError: searchState?.hasError == true
                ? 'Không thể tìm thành viên'
                : null,
            onMentionQueryChanged: (query) {
              if (_mentionQuery == query) return;
              setState(() => _mentionQuery = query);
            },
            onMentionsChanged: (ids) => _mentionIds
              ..clear()
              ..addAll(ids),
            onMentionWarning: (message) =>
                ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            ),
            canManageMemberTags: canUseMemberTags,
            onAssignMemberTags:
                canUseMemberTags ? _openMemberTagEditor : null,
          ),
          if (!canPost) _SocialNotice(message: socialSettings.postingPolicy == 'OFF' ? 'CLB đang tắt đăng bài.' : 'Hãy tham gia CLB để đăng bài.'),
          const SizedBox(height: AppTheme.spacingMD),
          if (state.errorMessage != null) _FeedError(message: state.errorMessage!, onRetry: () => ref.read(communityFeedProvider(widget.communityId).notifier).loadInitial()),
          if (state.isLoading && state.posts.isEmpty) const _FeedLoading(),
          if (!state.isLoading && state.errorMessage == null && state.posts.isEmpty) const _FeedEmpty(),
          ...state.posts.map((post) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
            child: CommunityPostCard(
              post: post,
              communityId: widget.communityId,
              commentsEnabled: socialSettings.commentsEnabled,
              onReact: (reaction) => ref
                  .read(communityFeedProvider(widget.communityId).notifier)
                  .reactToPost(post.id, reaction),
            ),
          )),
          if (state.isLoading && state.posts.isNotEmpty)
            const Padding(padding: EdgeInsets.all(AppTheme.spacingMD), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );

    if (!widget.showHeader) {
      return feedBody;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communityName),
        actions: [
          if (socialSettings.chatEnabled) IconButton(
            tooltip: 'Mở trò chuyện CLB',
            onPressed: () => context.push('/club/${widget.communityId}/chat?name=${Uri.encodeComponent(widget.communityName)}'),
            icon: const Icon(Icons.forum_outlined),
          ),
        ],
      ),
      body: feedBody,
      floatingActionButton: socialSettings.chatEnabled ? FloatingActionButton.small(
        tooltip: 'Mở trò chuyện CLB',
        onPressed: () => context.push('/club/${widget.communityId}/chat?name=${Uri.encodeComponent(widget.communityName)}'),
        child: const Icon(Icons.chat_bubble_rounded),
      ) : null,
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
        _Highlight(label: communityName, icon: Icons.groups_rounded, color: AppTheme.primary),
        const _Highlight(label: 'Trận gần đây', icon: Icons.sports_tennis_rounded, color: Color(0xFF8B5CF6)),
        const _Highlight(label: 'Bảng ELO', icon: Icons.leaderboard_rounded, color: Color(0xFFF59E0B)),
      ],
    ),
  );
}

class _Highlight extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Highlight({required this.label, required this.icon, required this.color});

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
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 20), const Spacer(), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))]),
  );
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(AppTheme.spacingXL), child: Center(child: CircularProgressIndicator()));
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXL), child: Center(child: Text('Chưa có bài đăng nào. Hãy chia sẻ điều đầu tiên!')));
}

class _FeedError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FeedError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: const Icon(Icons.cloud_off_rounded), title: Text(message), trailing: TextButton(onPressed: onRetry, child: const Text('Thử lại'))));
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
