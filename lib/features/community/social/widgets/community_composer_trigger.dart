import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';

/// Ô kích hoạt đăng bài kiểu Facebook: avatar + pill "Bạn đang nghĩ gì?"
/// cùng 2 nút nhanh (Ảnh / Bình chọn) mở composer bottom sheet.
/// Taste: màu phẳng từ AppTheme, không gradient.
class CommunityComposerTrigger extends StatelessWidget {
  final String authorName;
  final String? authorAvatarUrl;
  final VoidCallback onOpen;
  final VoidCallback onOpenWithPoll;
  final VoidCallback onOpenWithImage;

  const CommunityComposerTrigger({
    super.key,
    required this.authorName,
    this.authorAvatarUrl,
    required this.onOpen,
    required this.onOpenWithPoll,
    required this.onOpenWithImage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onOpen,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: authorAvatarUrl == null
                      ? null
                      : NetworkImage(authorAvatarUrl!),
                  child: authorAvatarUrl == null
                      ? Text(authorName.isNotEmpty
                          ? authorName[0].toUpperCase()
                          : '?')
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Bạn đang nghĩ gì?',
                      style: TextStyle(fontSize: 14, color: colors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Divider(height: 1, color: colors.borderLight),
          const SizedBox(height: AppTheme.spacingSM),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.photo_library_outlined,
                  label: 'Ảnh',
                  color: AppTheme.primary,
                  onTap: onOpenWithImage,
                ),
              ),
              Expanded(
                child: _QuickAction(
                  icon: Icons.poll_rounded,
                  label: 'Bình chọn',
                  color: colors.success,
                  onTap: onOpenWithPoll,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
