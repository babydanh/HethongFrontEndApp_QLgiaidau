import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_composer_parts.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_mention_engine.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_mention_helpers.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_poll_builder.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Composer đăng bài kiểu Facebook (bottom sheet), đủ tính năng như web:
/// nội dung + @mention, tối đa 10 ảnh (upload ngay khi chọn), bình chọn
/// (câu hỏi, 2-10 lựa chọn, chọn nhiều, thêm lựa chọn, thời hạn).
class CommunityPostComposerSheet extends ConsumerStatefulWidget {
  final String communityId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool canMention;
  final bool canManageTags;
  final ValueChanged<CommunityMemberModel>? onAssignMemberTags;
  final bool startWithPoll;
  final bool startWithImage;

  const CommunityPostComposerSheet({
    super.key,
    required this.communityId,
    required this.authorName,
    this.authorAvatarUrl,
    this.canMention = false,
    this.canManageTags = false,
    this.onAssignMemberTags,
    this.startWithPoll = false,
    this.startWithImage = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String communityId,
    required String authorName,
    String? authorAvatarUrl,
    bool canMention = false,
    bool canManageTags = false,
    ValueChanged<CommunityMemberModel>? onAssignMemberTags,
    bool startWithPoll = false,
    bool startWithImage = false,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CommunityPostComposerSheet(
          communityId: communityId,
          authorName: authorName,
          authorAvatarUrl: authorAvatarUrl,
          canMention: canMention,
          canManageTags: canManageTags,
          onAssignMemberTags: onAssignMemberTags,
          startWithPoll: startWithPoll,
          startWithImage: startWithImage,
        ),
      );

  @override
  ConsumerState<CommunityPostComposerSheet> createState() =>
      _CommunityPostComposerSheetState();
}

class _CommunityPostComposerSheetState
    extends ConsumerState<CommunityPostComposerSheet> {
  static const _log = AppLogger('PostComposer');
  static const _maxImages = 10;

  final _textCtrl = TextEditingController();
  ComposerMentionEngine? _mentionEngine;
  String? _mentionQuery;

  List<String> _imageUrls = const [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  bool _pollOpen = false;
  final _pollQuestionCtrl = TextEditingController();
  late final List<TextEditingController> _pollOptions;
  bool _allowMultiple = true;
  bool _allowAddOptions = true;
  int _pollExpiryDays = 0;

  @override
  void initState() {
    super.initState();
    _pollOptions = [TextEditingController(), TextEditingController()];
    _pollOpen = widget.startWithPoll;
    _mentionEngine = widget.canMention
        ? ComposerMentionEngine(
            controller: _textCtrl,
            onQueryChanged: (query) {
              if (mounted) setState(() => _mentionQuery = query);
            },
            onWarning: _warn,
          )
        : null;
    _mentionEngine?.start();
    if (widget.startWithImage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImages());
    }
  }

  @override
  void dispose() {
    _mentionEngine?.dispose();
    _textCtrl.dispose();
    _pollQuestionCtrl.dispose();
    for (final controller in _pollOptions) {
      controller.dispose();
    }
    super.dispose();
  }

  void _warn(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Ảnh (tối đa 10, upload ngay) ───────────────────────────────────────
  Future<void> _pickImages() async {
    if (_isUploading || _imageUrls.length >= _maxImages) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    final room = _maxImages - _imageUrls.length;
    if (picked.length > room) {
      _warn('Mỗi bài đăng tối đa $_maxImages ảnh.');
    }
    setState(() => _isUploading = true);
    var failed = 0;
    for (final file in picked.take(room)) {
      try {
        final url = await ref
            .read(communitySocialRepositoryProvider)
            .uploadImage(await file.readAsBytes(), file.name);
        if (mounted) setState(() => _imageUrls = [..._imageUrls, url]);
      } catch (e, stack) {
        failed++;
        _log.error('Upload ảnh composer thất bại', e, stack);
      }
    }
    if (mounted) setState(() => _isUploading = false);
    if (failed > 0 && mounted) _warn('$failed ảnh không tải lên được.');
  }

  // ── Bình chọn ──────────────────────────────────────────────────────────
  CommunityPollDraft? _buildPollDraft() {
    if (!_pollOpen) return null;
    final question = _pollQuestionCtrl.text.trim();
    final options = _pollOptions
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (question.isEmpty || options.length < 2) return null;
    return CommunityPollDraft(
      question: question,
      options: options,
      allowMultipleAnswers: _allowMultiple,
      allowAddOptions: _allowAddOptions,
      expiresAt: _pollExpiryDays > 0
          ? DateTime.now()
              .add(Duration(days: _pollExpiryDays))
              .toIso8601String()
          : null,
    );
  }

  // ── Đăng ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_isSubmitting || _isUploading) return;
    if (_pollOpen && _buildPollDraft() == null) {
      _warn('Bình chọn cần câu hỏi và ít nhất 2 lựa chọn.');
      return;
    }
    final body = _textCtrl.text.trim();
    final poll = _buildPollDraft();
    if (body.isEmpty && _imageUrls.isEmpty && poll == null) {
      _warn('Bài viết cần có nội dung, ảnh hoặc bình chọn.');
      return;
    }
    final mentions =
        _mentionEngine?.validMentionIdsFor(body) ?? const <String>[];

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(communityFeedProvider(widget.communityId).notifier)
        .createPost(
          text: body,
          mediaUrls: _imageUrls,
          mentions: mentions,
          poll: poll?.toPayload(),
        );
    if (!mounted) return;
    if (!success) {
      setState(() => _isSubmitting = false);
      _warn('Đăng bài thất bại. Vui lòng thử lại.');
      return;
    }
    final status =
        ref.read(communityFeedProvider(widget.communityId)).posts.first.status;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          status == 'PENDING' ? 'Bài viết đang chờ duyệt' : 'Đã đăng lên bảng tin',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final searchState = _mentionQuery == null
        ? null
        : ref.watch(communityMemberSearchProvider((
            communityId: widget.communityId,
            query: _mentionQuery!,
          )));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ComposerSheetHeader(
              isSubmitting: _isSubmitting,
              onClose: () => Navigator.of(context).pop(),
              onSubmit: _submit,
            ),
            Flexible(child: _buildBody(colors, searchState)),
            _buildActionBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    AppColorsExtension colors,
    AsyncValue<List<CommunityMemberModel>>? searchState,
  ) {
    final engine = _mentionEngine;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(name: widget.authorName, avatarUrl: widget.authorAvatarUrl),
          if (engine != null && engine.mentionedMembers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSM),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: engine.mentionedMembers
                    .map((member) => InputChip(
                          avatar: CircleAvatar(
                            backgroundImage: member.mentionAvatarProvider,
                            child: member.mentionAvatarProvider == null
                                ? Text(member.mentionInitial)
                                : null,
                          ),
                          label: Text('@${member.mentionDisplayName}'),
                          onDeleted: () {
                            engine.removeMention(member.userId);
                            setState(() {});
                          },
                        ))
                    .toList(growable: false),
              ),
            ),
          TextField(
            controller: _textCtrl,
            autofocus: !widget.startWithImage,
            maxLines: null,
            minLines: 4,
            maxLength: 5000,
            textInputAction: TextInputAction.newline,
            onSubmitted: (_) {
              final candidates =
                  searchState?.value ?? const <CommunityMemberModel>[];
              if (engine != null &&
                  engine.activeMention != null &&
                  candidates.isNotEmpty) {
                engine.selectMember(candidates.first);
                setState(() {});
              }
            },
            decoration: const InputDecoration(
              hintText:
                  'Bạn muốn chia sẻ điều gì với các thành viên? (Gõ @ để nhắc tên)',
              border: InputBorder.none,
              counterText: '',
            ),
          ),
          if (engine != null &&
              engine.activeMention != null &&
              _mentionQuery != null)
            ComposerMentionSuggestions(
              members: searchState?.value ?? const <CommunityMemberModel>[],
              isLoading: searchState?.isLoading ?? false,
              canManageTags: widget.canManageTags,
              onSelect: (member) {
                if (engine.selectMember(member)) setState(() {});
              },
              onTag: widget.onAssignMemberTags == null
                  ? null
                  : (member) {
                      HapticFeedback.selectionClick();
                      widget.onAssignMemberTags!(member);
                    },
            ),
          if (_isUploading || _imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSM),
              child: ComposerImagePreviewGrid(
                urls: _imageUrls,
                isUploading: _isUploading,
                onRemove: (url) =>
                    setState(() => _imageUrls = _imageUrls.where((u) => u != url).toList()),
              ),
            ),
          if (_pollOpen)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSM),
              child: CommunityPollBuilder(
                questionController: _pollQuestionCtrl,
                optionControllers: _pollOptions,
                allowMultipleAnswers: _allowMultiple,
                allowAddOptions: _allowAddOptions,
                expiryDays: _pollExpiryDays,
                onAllowMultipleChanged: (v) => setState(() => _allowMultiple = v),
                onAllowAddOptionsChanged: (v) => setState(() => _allowAddOptions = v),
                onExpiryChanged: (days) => setState(() => _pollExpiryDays = days),
                onAddOption: () =>
                    setState(() => _pollOptions.add(TextEditingController())),
                onRemoveOption: (index) {
                  setState(() {
                    _pollOptions[index].dispose();
                    _pollOptions.removeAt(index);
                  });
                },
                onCancel: () => setState(() => _pollOpen = false),
              ),
            ),
          const SizedBox(height: AppTheme.spacingSM),
        ],
      ),
    );
  }

  Widget _buildActionBar(AppColorsExtension colors) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.borderLight)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            TextButton.icon(
              onPressed: _isUploading ? null : _pickImages,
              icon: Icon(Icons.photo_library_outlined,
                  size: 20, color: AppTheme.primary),
              label: const Text('Ảnh', style: TextStyle(fontSize: 13)),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _pollOpen = !_pollOpen),
              icon: Icon(Icons.poll_rounded,
                  size: 20,
                  color: _pollOpen ? AppTheme.primary : colors.textSecondary),
              label: const Text('Bình chọn', style: TextStyle(fontSize: 13)),
            ),
            if (widget.canMention)
              TextButton.icon(
                onPressed: _mentionEngine?.insertToken,
                icon: Icon(Icons.alternate_email_rounded,
                    size: 20, color: AppTheme.primary),
                label: const Text('Gắn thẻ', style: TextStyle(fontSize: 13)),
              ),
          ]),
        ),
      );
}

class _AuthorRow extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _AuthorRow({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      CircleAvatar(
        radius: 18,
        backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
        child: avatarUrl == null
            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
            : null,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ]);
  }
}
