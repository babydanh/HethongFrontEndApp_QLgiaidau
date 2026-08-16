import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_mention_helpers.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_poll_builder.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
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
  static const _mentionLimit = 20;
  static const _maxImages = 10;

  final _textCtrl = TextEditingController();
  final Map<String, CommunityMemberModel> _mentions = {};
  Timer? _searchDebounce;
  MentionInput? _activeMention;
  String? _mentionQuery;

  final List<String> _imageUrls = [];
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
    _pollOptions = [
      TextEditingController(),
      TextEditingController(),
    ];
    _pollOpen = widget.startWithPoll;
    _textCtrl.addListener(_onTextChanged);
    if (widget.startWithImage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImages());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _textCtrl
      ..removeListener(_onTextChanged)
      ..dispose();
    _pollQuestionCtrl.dispose();
    for (final controller in _pollOptions) {
      controller.dispose();
    }
    super.dispose();
  }

  // ── Mention ────────────────────────────────────────────────────────────
  void _onTextChanged() {
    final text = _textCtrl.text;
    final staleIds = _mentions.entries
        .where((entry) => !containsMentionToken(text, entry.value.mentionDisplayName))
        .map((entry) => entry.key)
        .toList(growable: false);
    if (staleIds.isNotEmpty) {
      _mentions.removeWhere((id, _) => staleIds.contains(id));
      if (mounted) setState(() {});
    }
    _activeMention = findActiveMention(text, _textCtrl.selection);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _mentionQuery = _activeMention?.query);
    });
    if (mounted) setState(() {});
  }

  void _insertMentionToken() {
    final selection = _textCtrl.selection;
    final position = selection.isValid ? selection.start : _textCtrl.text.length;
    final text = _textCtrl.text;
    _textCtrl.value = TextEditingValue(
      text: '${text.substring(0, position)}@${text.substring(position)}',
      selection: TextSelection.collapsed(offset: position + 1),
    );
  }

  void _selectMember(CommunityMemberModel member) {
    final input = _activeMention;
    if (input == null || member.userId.isEmpty) return;
    if (_mentions.length >= _mentionLimit && !_mentions.containsKey(member.userId)) {
      _warn('Bạn chỉ có thể gắn tối đa $_mentionLimit thành viên.');
      return;
    }
    final name = member.mentionDisplayName;
    final duplicated = _mentions.entries.any((entry) =>
        entry.key != member.userId &&
        entry.value.mentionDisplayName.toLowerCase() == name.toLowerCase());
    if (duplicated) {
      _warn('CLB có hai thành viên cùng tên. Hãy dùng tên khác để tránh nhầm lẫn.');
      return;
    }
    final text = _textCtrl.text;
    final replacement = '@$name ';
    _textCtrl.value = TextEditingValue(
      text: '${text.substring(0, input.start)}$replacement${text.substring(input.end)}',
      selection: TextSelection.collapsed(offset: input.start + replacement.length),
    );
    _mentions[member.userId] = member;
    setState(() {});
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
        if (mounted) setState(() => _imageUrls.add(url));
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
    // Chỉ gửi mention còn token @tên trong nội dung cuối (khớp web).
    final mentions = _mentions.entries
        .where((entry) => containsMentionToken(body, entry.value.mentionDisplayName))
        .map((entry) => entry.key)
        .toList(growable: false);

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(communityFeedProvider(widget.communityId).notifier)
        .createPost(
          text: body,
          mediaUrls: List.unmodifiable(_imageUrls),
          mentions: List.unmodifiable(mentions),
          poll: poll?.toPayload(),
        );
    if (!mounted) return;
    if (success) {
      final status = ref
          .read(communityFeedProvider(widget.communityId))
          .posts
          .first
          .status;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'PENDING' ? 'Bài viết đang chờ duyệt' : 'Đã đăng lên bảng tin',
          ),
        ),
      );
    } else {
      setState(() => _isSubmitting = false);
      _warn('Đăng bài thất bại. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final searchState = !widget.canMention || _mentionQuery == null
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
            _buildHeader(colors),
            Flexible(child: _buildBody(colors, searchState)),
            _buildActionBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension colors) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'Tạo bài viết',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Đăng',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildBody(
    AppColorsExtension colors,
    AsyncValue<List<CommunityMemberModel>>? searchState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tác giả
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.authorAvatarUrl == null
                  ? null
                  : NetworkImage(widget.authorAvatarUrl!),
              child: widget.authorAvatarUrl == null
                  ? Text(widget.authorName.isNotEmpty
                      ? widget.authorName[0].toUpperCase()
                      : '?')
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ]),
          if (_mentions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSM),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _mentions.values
                    .map((member) => InputChip(
                          avatar: CircleAvatar(
                            backgroundImage: member.mentionAvatarProvider,
                            child: member.mentionAvatarProvider == null
                                ? Text(member.mentionInitial)
                                : null,
                          ),
                          label: Text('@${member.mentionDisplayName}'),
                          onDeleted: () {
                            _mentions.remove(member.userId);
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
              final candidates = searchState?.value ?? const <CommunityMemberModel>[];
              if (_activeMention != null && candidates.isNotEmpty) {
                _selectMember(candidates.first);
              }
            },
            decoration: const InputDecoration(
              hintText: 'Bạn muốn chia sẻ điều gì với các thành viên? (Gõ @ để nhắc tên)',
              border: InputBorder.none,
              counterText: '',
            ),
          ),
          if (_activeMention != null && widget.canMention)
            _MentionSuggestions(
              members: searchState?.value ?? const <CommunityMemberModel>[],
              isLoading: searchState?.isLoading ?? false,
              canManageTags: widget.canManageTags,
              onSelect: _selectMember,
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
              child: _ImagePreviewGrid(
                urls: List.unmodifiable(_imageUrls),
                isUploading: _isUploading,
                onRemove: (url) => setState(() => _imageUrls.remove(url)),
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
              label: Text('Bình chọn', style: TextStyle(fontSize: 13)),
            ),
            if (widget.canMention)
              TextButton.icon(
                onPressed: _insertMentionToken,
                icon: Icon(Icons.alternate_email_rounded,
                    size: 20, color: AppTheme.primary),
                label: const Text('Gắn thẻ', style: TextStyle(fontSize: 13)),
              ),
          ]),
        ),
      );
}

class _ImagePreviewGrid extends StatelessWidget {
  final List<String> urls;
  final bool isUploading;
  final ValueChanged<String> onRemove;

  const _ImagePreviewGrid({
    required this.urls,
    required this.isUploading,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...urls.map((url) => Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url,
                    width: 96, height: 72, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 96, height: 72, color: colors.bgSurface)),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => onRemove(url),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.bgDark.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ])),
        if (isUploading)
          Container(
            width: 96,
            height: 72,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderLight),
            ),
            child: const Center(
              child: SizedBox.square(
                  dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
      ],
    );
  }
}

class _MentionSuggestions extends StatelessWidget {
  final List<CommunityMemberModel> members;
  final bool isLoading;
  final bool canManageTags;
  final ValueChanged<CommunityMemberModel> onSelect;
  final ValueChanged<CommunityMemberModel>? onTag;

  const _MentionSuggestions({
    required this.members,
    required this.isLoading,
    required this.canManageTags,
    required this.onSelect,
    this.onTag,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (isLoading) {
      return const SizedBox(
          height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (members.isEmpty) {
      return SizedBox(
        height: 44,
        child: Center(
            child: Text('Không tìm thấy thành viên',
                style: TextStyle(color: colors.textMuted, fontSize: 12))),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.borderLight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: members.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderLight),
        itemBuilder: (context, index) {
          final member = members[index];
          return InkWell(
            onTap: () => onSelect(member),
            onLongPress: canManageTags && onTag != null ? () => onTag!(member) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: member.mentionAvatarProvider,
                  child: member.mentionAvatarProvider == null
                      ? Text(member.mentionInitial)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(member.mentionDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                if (member.tags.isNotEmpty)
                  MemberTagChip(
                      label: member.tags.first, kind: MemberTagChipKind.bqt),
                if (canManageTags && onTag != null)
                  IconButton(
                    tooltip: 'Gán nhãn vui',
                    icon: const Icon(Icons.sell_outlined, size: 18),
                    onPressed: () => onTag!(member),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
