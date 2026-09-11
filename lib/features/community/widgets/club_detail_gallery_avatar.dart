part of '../screens/club_detail_screen.dart';

extension _ClubDetailGalleryAvatar on _ClubDetailScreenState {
  Widget _buildUserAvatar({
    required String? name,
    required String? avatarUrl,
    required double radius,
    required Color fallbackColor,
  }) {
    final initial = (name?.trim().isNotEmpty == true ? name!.trim()[0] : '?')
        .toUpperCase();
    final url = avatarUrl?.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: fallbackColor.withValues(alpha: 0.1),
      child: url == null || url.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: fallbackColor,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.7,
              ),
            )
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: fallbackColor,
                      fontWeight: FontWeight.w800,
                      fontSize: radius * 0.7,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ════════════════════════════════════
  //  TAB 6: CÀI ĐẶT (Settings)
  // ════════════════════════════════════
}
