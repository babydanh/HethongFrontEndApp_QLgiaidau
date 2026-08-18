import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/chat_models.dart';
import 'package:flutter/material.dart';

class ChatReactionDetailSheet extends StatelessWidget {
  final ChatMessageModel message;

  const ChatReactionDetailSheet({super.key, required this.message});

  static Future<void> show(BuildContext context, ChatMessageModel message) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatReactionDetailSheet(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allReactions = message.reactions;
    int totalCount = 0;
    for (final r in allReactions) {
      totalCount += r.count;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Cảm xúc về tin nhắn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalCount cảm xúc',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // Reactions Summary Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allReactions.map((r) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: r.isReacted ? AppTheme.primary.withValues(alpha: 0.12) : colors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: r.isReacted ? AppTheme.primary : colors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '${r.count}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: r.isReacted ? AppTheme.primary : colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Message Preview Strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote_rounded, size: 16, color: colors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message.content.isNotEmpty ? message.content : '[Hình ảnh/Phương tiện]',
                    style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
