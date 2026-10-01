import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';

/// Một bình luận trong "Phòng thảo luận" của trận đấu trực tiếp.
///
/// Avatar và tên hiển thị là **một** control duy nhất: chạm vào bất kỳ đâu
/// trên dòng bình luận cũng dẫn tới hồ sơ người viết, với hover preview trên
/// web/desktop và bottom sheet trên điện thoại — cùng hành vi với mọi avatar
/// khác trong app (xem [UserProfileTapTarget]).
class MatchDiscussionMessage extends StatelessWidget {
  const MatchDiscussionMessage({
    super.key,
    required this.userId,
    required this.name,
    required this.text,
    required this.timeLabel,
    this.avatarUrl,
  });

  /// Blank when the feed could not resolve the author to a real account; the
  /// row then stays readable but inert instead of being a dead control.
  final String userId;
  final String name;
  final String text;
  final String timeLabel;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: UserProfileTapTarget(
        userId: userId,
        name: name,
        imageUrl: avatarUrl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 44px keeps the target reachable on touch while the artwork
            // stays at its original 32px.
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: RankAvatar(imageUrl: avatarUrl, name: name, size: 32),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: TextStyle(fontSize: 10, color: colors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
