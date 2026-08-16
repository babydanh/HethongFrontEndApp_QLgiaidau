import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_mention_helpers.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:flutter/material.dart';

/// Các widget hiển thị dùng chung cho composer đăng bài.

/// Header sheet kiểu Facebook: nút đóng trái, tiêu đề giữa, nút Đăng phải.
class ComposerSheetHeader extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  const ComposerSheetHeader({
    super.key,
    required this.isSubmitting,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
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
                onPressed: onClose,
              ),
              const Expanded(
                child: Text(
                  'Tạo bài viết',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: isSubmitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Đăng',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lưới preview ảnh đã upload: 96x72, nút xóa từng ảnh, ô spinner đang tải.
class ComposerImagePreviewGrid extends StatelessWidget {
  final List<String> urls;
  final bool isUploading;
  final ValueChanged<String> onRemove;

  const ComposerImagePreviewGrid({
    super.key,
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
        ...urls.map((url) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 96,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 96,
                      height: 72,
                      color: colors.bgSurface,
                    ),
                  ),
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
                      child:
                          const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )),
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
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// Danh sách gợi ý thành viên khi gõ @mention.
class ComposerMentionSuggestions extends StatelessWidget {
  final List<CommunityMemberModel> members;
  final bool isLoading;
  final bool canManageTags;
  final ValueChanged<CommunityMemberModel> onSelect;
  final ValueChanged<CommunityMemberModel>? onTag;

  const ComposerMentionSuggestions({
    super.key,
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
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (members.isEmpty) {
      return SizedBox(
        height: 44,
        child: Center(
          child: Text(
            'Không tìm thấy thành viên',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ),
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
        itemBuilder: (context, index) => _SuggestionRow(
          member: members[index],
          canManageTags: canManageTags,
          onSelect: onSelect,
          onTag: onTag,
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final CommunityMemberModel member;
  final bool canManageTags;
  final ValueChanged<CommunityMemberModel> onSelect;
  final ValueChanged<CommunityMemberModel>? onTag;

  const _SuggestionRow({
    required this.member,
    required this.canManageTags,
    required this.onSelect,
    this.onTag,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelect(member),
      onLongPress: canManageTags && onTag != null ? () => onTag!(member) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: member.mentionAvatarProvider,
              child:
                  member.mentionAvatarProvider == null ? Text(member.mentionInitial) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                member.mentionDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            if (member.tags.isNotEmpty)
              MemberTagChip(label: member.tags.first, kind: MemberTagChipKind.bqt),
            if (canManageTags && onTag != null)
              IconButton(
                tooltip: 'Gán nhãn vui',
                icon: const Icon(Icons.sell_outlined, size: 18),
                onPressed: () => onTag!(member),
              ),
          ],
        ),
      ),
    );
  }
}
