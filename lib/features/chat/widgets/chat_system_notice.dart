import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';

/// A server notice in the message list (`type: SYSTEM`, e.g. "An joined"):
/// small, centered, no bubble and no message menu.
class ChatSystemNotice extends StatelessWidget {
  const ChatSystemNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.bgCard.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: colors.textMuted),
        ),
      ),
    );
  }
}
