import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Ô kích hoạt đăng bài chuẩn phong cách Facebook:
/// - Toàn chiều rộng (full-width), không bo góc viền hộp ngoài lơ lửng.
/// - Avatar tròn sắc nét (hoặc chữ cái đầu đẹp mắt có fallback).
/// - Thanh input pill màu xám nhạt `Bạn đang nghĩ gì?`.
/// - Đường kẻ mỏng và các nút hành động nhanh bên dưới (Ảnh, Bình chọn).
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanAvatarUrl = authorAvatarUrl?.trim();
    final hasAvatar = cleanAvatarUrl != null && cleanAvatarUrl.isNotEmpty;
    final initial = (authorName.trim().isNotEmpty ? authorName.trim()[0] : 'U')
        .toUpperCase();

    return Container(
      color: colors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: onOpen,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: colors.borderLight.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.network(
                            cleanAvatarUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackAvatar(initial),
                          )
                        : _buildFallbackAvatar(initial),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A3B3C)
                          : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      l10n.communityComposerTriggerHint,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey[300]
                            : const Color(0xFF65676B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 0.8, color: colors.borderLight),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.photo_library_rounded,
                  label: l10n.communityComposerPhoto,
                  color: const Color(0xFF45BD62), // Xanh lá phong cách Facebook
                  onTap: onOpenWithImage,
                ),
              ),
              Container(height: 18, width: 1, color: colors.borderLight),
              Expanded(
                child: _QuickAction(
                  icon: Icons.poll_rounded,
                  label: l10n.communityComposerPoll,
                  color: const Color(
                    0xFFF7B125,
                  ), // Vàng cam phong cách Facebook
                  onTap: onOpenWithPoll,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
