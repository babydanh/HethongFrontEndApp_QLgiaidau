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
  final VoidCallback onOpenWithImage;
  final VoidCallback? onAvatarTap;

  const CommunityComposerTrigger({
    super.key,
    required this.authorName,
    this.authorAvatarUrl,
    required this.onOpen,
    required this.onOpenWithImage,
    this.onAvatarTap,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          // 1. Avatar - Nhấn vào mở Profile Pop-up
          GestureDetector(
            onTap: onAvatarTap ?? onOpen,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: colors.borderLight.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                        cleanAvatarUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackAvatar(initial),
                      )
                    : _buildFallbackAvatar(initial),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Thanh input "Bạn đang nghĩ gì?"
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3B3C)
                      : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.communityComposerTriggerHint,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark
                        ? Colors.grey[300]
                        : const Color(0xFF65676B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 3. Nút Ảnh ở bên phải cuối (chuẩn phong cách Facebook mobile gọn)
          IconButton(
            onPressed: onOpenWithImage,
            icon: const Icon(
              Icons.photo_library_rounded,
              color: Color(0xFF45BD62), // Màu xanh lá biểu tượng ảnh Facebook
              size: 24,
            ),
            tooltip: l10n.communityComposerPhoto,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
          fontSize: 14,
        ),
      ),
    );
  }
}
