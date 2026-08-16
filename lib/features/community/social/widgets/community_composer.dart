import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_mention_helpers.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact composer that keeps presentation of a visible @name separate from
/// the user id delivered to the post API.
class CommunityComposer extends StatefulWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback? onPickImage;
  final int imageCount;
  final List<CommunityMemberModel> mentionCandidates;
  final bool isSearchingMembers;
  final String? memberSearchError;
  final ValueChanged<String?> onMentionQueryChanged;
  final ValueChanged<List<String>> onMentionsChanged;
  final ValueChanged<String>? onMentionWarning;
  final VoidCallback? onCreatePoll;
  final bool canManageMemberTags;
  final ValueChanged<CommunityMemberModel>? onAssignMemberTags;

  const CommunityComposer({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    required this.mentionCandidates,
    required this.isSearchingMembers,
    required this.onMentionQueryChanged,
    required this.onMentionsChanged,
    this.onMentionWarning,
    this.onCreatePoll,
    this.onPickImage,
    this.imageCount = 0,
    this.memberSearchError,
    this.canManageMemberTags = false,
    this.onAssignMemberTags,
  });

  @override
  State<CommunityComposer> createState() => _CommunityComposerState();
}

class _CommunityComposerState extends State<CommunityComposer> {
  static const _mentionLimit = 20;
  final Map<String, CommunityMemberModel> _mentions = {};
  Timer? _searchDebounce;
  MentionInput? _activeMention;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant CommunityComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final staleIds = _mentions.entries
        .where(
          (entry) => !containsMentionToken(text, entry.value.mentionDisplayName),
        )
        .map((entry) => entry.key)
        .toList(growable: false);
    if (staleIds.isNotEmpty) {
      for (final id in staleIds) {
        _mentions.remove(id);
      }
      widget.onMentionsChanged(List.unmodifiable(_mentions.keys));
      if (mounted) setState(() {});
    }

    _activeMention = findActiveMention(text, widget.controller.selection);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) widget.onMentionQueryChanged(_activeMention?.query);
    });
    if (mounted) setState(() {});
  }

  void _startMention() {
    final selection = widget.controller.selection;
    final position = selection.isValid ? selection.start : widget.controller.text.length;
    final text = widget.controller.text;
    widget.controller.value = TextEditingValue(
      text: '${text.substring(0, position)}@${text.substring(position)}',
      selection: TextSelection.collapsed(offset: position + 1),
    );
  }

  void _selectMember(CommunityMemberModel member) {
    final input = _activeMention;
    if (input == null || member.userId.isEmpty) return;
    if (_mentions.length >= _mentionLimit &&
        !_mentions.containsKey(member.userId)) {
      widget.onMentionWarning?.call(
        'Bạn chỉ có thể gắn tối đa $_mentionLimit thành viên.',
      );
      return;
    }
    final name = member.mentionDisplayName;
    final hasDuplicateVisibleName = _mentions.entries.any(
      (entry) =>
          entry.key != member.userId &&
          entry.value.mentionDisplayName.toLowerCase() == name.toLowerCase(),
    );
    if (hasDuplicateVisibleName) {
      widget.onMentionWarning?.call(
        'CLB có hai thành viên cùng tên. Hãy dùng tên khác để tránh nhầm lẫn.',
      );
      return;
    }
    final text = widget.controller.text;
    final replacement = '@$name ';
    final next = '${text.substring(0, input.start)}$replacement${text.substring(input.end)}';
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: input.start + replacement.length),
    );
    _mentions[member.userId] = member;
    widget.onMentionsChanged(List.unmodifiable(_mentions.keys));
    setState(() {});
  }

  void _openTagEditor(CommunityMemberModel member) {
    if (!widget.canManageMemberTags || widget.onAssignMemberTags == null) return;
    HapticFeedback.selectionClick();
    widget.onAssignMemberTags!(member);
  }

  @override
  Widget build(BuildContext context) {
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
          children: [
            if (_mentions.isNotEmpty) _MentionChips(members: _mentions.values.toList(growable: false), canManageTags: widget.canManageMemberTags, onTag: _openTagEditor),
            TextField(
              controller: widget.controller,
              minLines: 2,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) {
                if (_activeMention != null && widget.mentionCandidates.isNotEmpty) {
                  _selectMember(widget.mentionCandidates.first);
                }
              },
              decoration: const InputDecoration(
                hintText: 'Chia sẻ điều gì đó với CLB… Gõ @ để nhắc tên',
                border: InputBorder.none,
              ),
            ),
            if (_activeMention != null) _MentionSuggestions(
              members: widget.mentionCandidates,
              isLoading: widget.isSearchingMembers,
              errorMessage: widget.memberSearchError,
              canManageTags: widget.canManageMemberTags,
              onSelect: _selectMember,
              onTag: _openTagEditor,
            ),
            const Divider(height: AppTheme.spacingMD),
            Row(children: [
              TextButton.icon(onPressed: widget.onPickImage, icon: const Icon(Icons.photo_library_outlined, size: 19), label: Text(widget.imageCount > 0 ? 'Ảnh ${widget.imageCount}' : 'Ảnh')),
              TextButton.icon(onPressed: _startMention, icon: const Icon(Icons.alternate_email_rounded, size: 19), label: const Text('Gắn thẻ')),
              const Spacer(),
              FilledButton(
                onPressed: widget.isSubmitting ? null : widget.onSubmit,
                child: widget.isSubmitting ? const SizedBox.square(dimension: 17, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Đăng'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MentionChips extends StatelessWidget {
  final List<CommunityMemberModel> members;
  final bool canManageTags;
  final ValueChanged<CommunityMemberModel> onTag;
  const _MentionChips({required this.members, required this.canManageTags, required this.onTag});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: members.map((member) => ActionChip(
          avatar: CircleAvatar(backgroundImage: member.mentionAvatarProvider, child: member.mentionAvatarProvider == null ? Text(member.mentionInitial) : null),
          label: Text('@${member.mentionDisplayName}'),
          onPressed: canManageTags ? () => onTag(member) : null,
          tooltip: canManageTags ? 'Nhấn để gán nhãn thành viên' : null,
        )).toList(growable: false),
      ),
    ),
  );
}

class _MentionSuggestions extends StatelessWidget {
  final List<CommunityMemberModel> members;
  final bool isLoading;
  final String? errorMessage;
  final bool canManageTags;
  final ValueChanged<CommunityMemberModel> onSelect;
  final ValueChanged<CommunityMemberModel> onTag;
  const _MentionSuggestions({required this.members, required this.isLoading, required this.canManageTags, required this.onSelect, required this.onTag, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = isLoading
        ? const SizedBox(height: 58, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        : errorMessage != null
            ? SizedBox(height: 52, child: Center(child: Text('Chưa thể tìm thành viên', style: TextStyle(color: colors.textMuted))))
            : members.isEmpty
                ? SizedBox(height: 52, child: Center(child: Text('Không tìm thấy thành viên', style: TextStyle(color: colors.textMuted))))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: colors.borderLight),
                    itemBuilder: (context, index) => _MemberSuggestion(member: members[index], canManageTags: canManageTags, onSelect: onSelect, onTag: onTag),
                  );
    return Container(
      constraints: const BoxConstraints(maxHeight: 226),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(AppTheme.radiusMedium), border: Border.all(color: colors.borderLight)),
      child: content,
    );
  }
}

class _MemberSuggestion extends StatelessWidget {
  final CommunityMemberModel member;
  final bool canManageTags;
  final ValueChanged<CommunityMemberModel> onSelect;
  final ValueChanged<CommunityMemberModel> onTag;
  const _MemberSuggestion({required this.member, required this.canManageTags, required this.onSelect, required this.onTag});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onSelect(member),
    onLongPress: canManageTags ? () => onTag(member) : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSM, vertical: 7),
      child: Row(children: [
        CircleAvatar(radius: 17, backgroundImage: member.mentionAvatarProvider, child: member.mentionAvatarProvider == null ? Text(member.mentionInitial) : null),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.mentionDisplayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (member.tags.isNotEmpty) Wrap(spacing: 4, children: member.tags.take(2).map((tag) => MemberTagChip(label: tag, kind: MemberTagChipKind.bqt)).toList(growable: false)),
        ])),
        if (canManageTags) IconButton(tooltip: 'Gán nhãn vui', onPressed: () => onTag(member), icon: const Icon(Icons.sell_outlined, size: 19)),
      ]),
    ),
  );
}
