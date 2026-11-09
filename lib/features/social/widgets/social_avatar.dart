import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';

/// Avatar tròn: ảnh thật nếu có, không thì chữ cái đầu. [isHost] gắn huy hiệu
/// vương miện góc dưới như nhãn "Host" của Web.
class SocialAvatar extends StatelessWidget {
  const SocialAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
    this.isHost = false,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool isHost;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = imageUrl?.trim() ?? '';
    final fallback = Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
    );
    return Semantics(
      label: isHost ? '$name, Host' : name,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.success.withValues(alpha: 0.25),
                  border: isHost
                      ? Border.all(color: AppTheme.primary, width: 2)
                      : null,
                ),
                child: ClipOval(
                  child: url.isEmpty
                      ? fallback
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => fallback,
                        ),
                ),
              ),
            ),
            if (isHost)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: size * 0.26,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn chữ "Host" dưới tên người tham gia.
class SocialHostChip extends StatelessWidget {
  const SocialHostChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Host',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
