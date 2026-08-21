import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ChatPollDialog extends StatefulWidget {
  const ChatPollDialog({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ChatPollDialog(),
    );
  }

  @override
  State<ChatPollDialog> createState() => _ChatPollDialogState();
}

class _ChatPollDialogState extends State<ChatPollDialog> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultiple = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) return;
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n!.chatPollValidationError)));
      return;
    }

    Navigator.pop(context, {
      'question': question,
      'options': options,
      'allowMultipleAnswers': _allowMultiple,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.poll_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n!.chatPollCreateTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Question Input
              TextField(
                controller: _questionController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: l10n!.chatPollQuestionHint,
                  hintStyle: TextStyle(color: colors.textMuted),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF242526)
                      : const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n!.chatPollOptionsLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              // Options List
              ..._optionControllers.asMap().entries.map((entry) {
                final idx = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: l10n!.chatPollOptionHint(idx + 1),
                            hintStyle: TextStyle(color: colors.textMuted),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF242526)
                                : const Color(0xFFF0F2F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: colors.error,
                            size: 20,
                          ),
                          onPressed: () => _removeOption(idx),
                        ),
                    ],
                  ),
                );
              }),
              if (_optionControllers.length < 10)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text(
                    l10n!.chatPollAddOption,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 8),
              // Multiple Answers Switch
              SwitchListTile.adaptive(
                title: Text(
                  l10n!.chatPollAllowMultiple,
                  style: const TextStyle(fontSize: 14),
                ),
                value: _allowMultiple,
                onChanged: (v) => setState(() => _allowMultiple = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n!.chatPollSubmit,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
