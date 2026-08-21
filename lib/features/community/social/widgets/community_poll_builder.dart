import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Dữ liệu bình chọn sẽ gửi kèm bài đăng (khớp CreatePollDto backend/web).
class CommunityPollDraft {
  final String question;
  final List<String> options;
  final bool allowMultipleAnswers;
  final bool allowAddOptions;
  final String? expiresAt;

  const CommunityPollDraft({
    required this.question,
    required this.options,
    required this.allowMultipleAnswers,
    required this.allowAddOptions,
    this.expiresAt,
  });

  Map<String, dynamic> toPayload() => {
        'question': question,
        'options': options,
        'allowMultipleAnswers': allowMultipleAnswers,
        'allowAddOptions': allowAddOptions,
        if (expiresAt != null) 'expiresAt': expiresAt,
      };
}

/// Panel tạo bình chọn trong composer — đồng bộ web (CommunityPostComposer):
/// câu hỏi (1-300), 2-10 lựa chọn, cho chọn nhiều / thêm lựa chọn, thời hạn.
/// Stateless: toàn bộ state do sheet sở hữu, widget chỉ hiển thị.
class CommunityPollBuilder extends StatelessWidget {
  static const minOptions = 2;
  static const maxOptions = 10;
  static const expiryChoices = [0, 1, 3, 7, 14, 30];

  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final bool allowMultipleAnswers;
  final bool allowAddOptions;
  final int expiryDays;
  final ValueChanged<bool> onAllowMultipleChanged;
  final ValueChanged<bool> onAllowAddOptionsChanged;
  final ValueChanged<int> onExpiryChanged;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final VoidCallback onCancel;

  const CommunityPollBuilder({
    super.key,
    required this.questionController,
    required this.optionControllers,
    required this.allowMultipleAnswers,
    required this.allowAddOptions,
    required this.expiryDays,
    required this.onAllowMultipleChanged,
    required this.onAllowAddOptionsChanged,
    required this.onExpiryChanged,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        // Taste: màu phẳng nhẹ, không gradient.
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.communityPollBuilder_title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.communityPollBuilder_cancel, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          TextField(
            controller: questionController,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: l10n.communityPollBuilder_questionLabel,
              hintText: l10n.communityPollBuilder_questionHint,
              isDense: true,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          ...optionControllers.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text('${entry.key + 1}.',
                            style: TextStyle(
                                fontSize: 12, color: colors.textSecondary)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          maxLength: 150,
                          decoration: InputDecoration(
                            hintText: l10n.communityPollBuilder_optionHint(entry.key + 1),
                            isDense: true,
                            counterText: '',
                          ),
                        ),
                      ),
                      if (optionControllers.length > CommunityPollBuilder.minOptions)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: colors.textMuted),
                          onPressed: () => onRemoveOption(entry.key),
                        ),
                    ],
                  ),
                ),
              ),
          if (optionControllers.length < CommunityPollBuilder.maxOptions)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddOption,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.communityPollBuilder_addOption, style: const TextStyle(fontSize: 13)),
              ),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.communityPollBuilder_allowMultiple,
                style: TextStyle(fontSize: 13)),
            value: allowMultipleAnswers,
            onChanged: onAllowMultipleChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.communityPollBuilder_allowAddOptions,
                style: TextStyle(fontSize: 13)),
            value: allowAddOptions,
            onChanged: onAllowAddOptionsChanged,
          ),
          Row(
            children: [
              Expanded(
                child: Text(l10n.communityPollBuilder_expiry,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              ),
              DropdownButton<int>(
                value: expiryDays,
                underline: const SizedBox.shrink(),
                items: expiryChoices
                    .map((days) => DropdownMenuItem(
                          value: days,
                          child: Text(
                            days == 0 ? l10n.communityPollBuilder_noLimit : l10n.communityPollBuilder_days(days),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onExpiryChanged(value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
