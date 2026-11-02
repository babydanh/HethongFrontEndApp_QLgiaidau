import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';

/// Comment box of the viewer live screen: one rounded block with the text field
/// and the send button inside. Guests get a "log in" button instead of send.
class LiveCommentInput extends StatelessWidget {
  const LiveCommentInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.canPost,
    required this.sending,
    required this.onSend,
    required this.onLogin,
    required this.loginLabel,
  });

  final TextEditingController controller;
  final String hint;
  final bool canPost;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onLogin;
  final String loginLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: TextField(
                  controller: controller,
                  enabled: canPost && !sending,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            if (!canPost)
              TextButton(
                onPressed: onLogin,
                child: Text(
                  loginLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              )
            else
              IconButton(
                // Null while sending so a double tap cannot post twice.
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: AppTheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}
