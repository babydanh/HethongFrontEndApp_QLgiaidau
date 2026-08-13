import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';

/// P2C.5 — Bottom sheet gán tag BQT cho thành viên (OWNER/MODERATOR).
/// Replace toàn bộ khi lưu; mảng rỗng = xoá hết. Tối đa 5 tag, mỗi tag ≤ 24 ký tự.
/// Màu/spacing từ AppTheme, chuỗi từ AppConstants — không hardcode.
class TagAssignSheet extends StatefulWidget {
  final String memberName;
  final List<String> currentTags;

  /// Trả về khi lưu thành công; ném exception khi thất bại → sheet giữ nguyên
  /// và hiển thị lỗi.
  final Future<void> Function(List<String> tags) onSave;

  const TagAssignSheet({
    super.key,
    required this.memberName,
    required this.currentTags,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String memberName,
    required List<String> currentTags,
    required Future<void> Function(List<String> tags) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TagAssignSheet(
        memberName: memberName,
        currentTags: currentTags,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TagAssignSheet> createState() => _TagAssignSheetState();
}

class _TagAssignSheetState extends State<TagAssignSheet> {
  static final RegExp _tagPattern = RegExp(
    r'^[\p{L}\p{N} _-]+$',
    unicode: true,
  );

  late final List<String> _tags = List.of(widget.currentTags);
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;

    if (_tags.length >= AppConstants.memberTagMax) {
      setState(() => _error = AppConstants.memberTagMaxReached);
      return;
    }
    if (value.length > AppConstants.memberTagMaxLength) {
      setState(() => _error = AppConstants.memberTagTooLong);
      return;
    }
    if (!_tagPattern.hasMatch(value)) {
      setState(() => _error = AppConstants.memberTagInvalid);
      return;
    }
    if (_tags.any((t) => t.toLowerCase() == value.toLowerCase())) {
      setState(() => _error = AppConstants.memberTagDuplicate);
      return;
    }

    setState(() {
      _tags.add(value);
      _controller.clear();
      _error = null;
    });
  }

  void _addSuggestedTag(String tag) {
    _controller.text = tag;
    _addTag();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(List.unmodifiable(_tags));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppConstants.memberTagSaveError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxReached = _tags.length >= AppConstants.memberTagMax;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXL),
          ),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.sell_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppConstants.memberTagAssignTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${AppConstants.memberTagAssignDesc} '
              '(${widget.memberName})',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            // Tags hiện có
            if (_tags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppConstants.memberTagEmpty,
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags.map((tag) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MemberTagChip(label: tag, kind: MemberTagChipKind.bqt),
                      InkWell(
                        onTap: _saving
                            ? null
                            : () => setState(() {
                                _tags.remove(tag);
                                _error = null;
                              }),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            if (!maxReached)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: AppConstants.memberTagSuggestions
                    .where(
                      (tag) => !_tags.any(
                        (current) => current.toLowerCase() == tag.toLowerCase(),
                      ),
                    )
                    .map(
                      (tag) => ActionChip(
                        label: Text(tag),
                        onPressed: _saving ? null : () => _addSuggestedTag(tag),
                      ),
                    )
                    .toList(growable: false),
              ),
            if (!maxReached) const SizedBox(height: 12),
            // Input thêm tag
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_saving && !maxReached,
                    maxLength: AppConstants.memberTagMaxLength + 8,
                    onSubmitted: (_) => _addTag(),
                    onChanged: (_) => setState(() => _error = null),
                    decoration: InputDecoration(
                      hintText: maxReached
                          ? AppConstants.memberTagMaxReached
                          : AppConstants.memberTagAddHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                      ),
                      counterText: '',
                      isDense: true,
                      filled: true,
                      fillColor: colors.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed:
                        (_saving ||
                            maxReached ||
                            _controller.text.trim().isEmpty)
                        ? null
                        : _addTag,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    ),
                    child: Text(
                      AppConstants.memberTagAdd,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                AppConstants.memberTagCounter(
                  _tags.length,
                  AppConstants.memberTagMax,
                ),
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  _saving
                      ? AppConstants.memberTagSaving
                      : AppConstants.memberTagSave,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
