import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ô kích hoạt đăng bài chuẩn phong cách Facebook:
/// - Toàn chiều rộng (full-width), không bo góc viền hộp ngoài lơ lửng.
/// - Avatar tròn sắc nét (hoặc chữ cái đầu đẹp mắt có fallback).
/// - Thanh input pill màu xám nhạt `Bạn đang nghĩ gì?`.
/// - Đường kẻ mỏng và các nút hành động nhanh bên dưới (Ảnh, Bình chọn).
class CommunityComposerTrigger extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanAvatarUrl = authorAvatarUrl?.trim();
    // The trigger always shows the signed-in author: /users/profile carries
    // no ELO, so the ring comes from the best ranking like the Profile tab.
    final rank = ref.watch(myBestRankingProvider);

    return Container(
      color: colors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 1. Avatar - Nhấn vào mở Profile Pop-up
          GestureDetector(
            onTap: onAvatarTap ?? onOpen,
            behavior: HitTestBehavior.opaque,
            child: RankAvatar(
              imageUrl: cleanAvatarUrl,
              name: authorName.trim().isEmpty ? 'U' : authorName,
              elo: rank?.eloPoints ?? 0,
              tierName: rank?.tierName,
              tierSource: rank?.tierSource,
              tierAvailable: rank?.tierAvailable,
              matchesPlayed: rank?.matchesPlayed ?? 0,
              size: 36,
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
}
