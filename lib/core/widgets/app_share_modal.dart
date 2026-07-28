import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class AppShareModal {
  static void show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String webUrl,
    String? imageUrl,
    String? badgeText,
  }) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                const Icon(Icons.share_rounded, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Chia sẻ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Preview Card (Simulating Meta OG Preview)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgDark.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildPreviewImage(imageUrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (badgeText != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share Actions Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareActionButton(
                  context: ctx,
                  icon: Icons.copy_rounded,
                  color: const Color(0xFF3B82F6),
                  label: 'Sao chép link',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: webUrl));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép liên kết vào bộ nhớ tạm!'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                ),
                _shareActionButton(
                  context: ctx,
                  icon: Icons.send_rounded,
                  color: const Color(0xFF059669),
                  label: 'Chia sẻ qua App',
                  onTap: () {
                    Navigator.pop(ctx);
                    SharePlus.instance.share(
                      ShareParams(
                        text: '$title\n$subtitle\n\nXem chi tiết tại: $webUrl',
                      ),
                    );
                  },
                ),
                _shareActionButton(
                  context: ctx,
                  icon: Icons.qr_code_2_rounded,
                  color: const Color(0xFFF59E0B),
                  label: 'Mã QR',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showQrDialog(context, title, webUrl);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _shareActionButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static void _showQrDialog(BuildContext context, String title, String url) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: colors.bgCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mã QR Chia Sẻ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép liên kết!')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Sao chép link'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPreviewImage(String? url) {
    if (url == null || url.trim().isEmpty) {
      return SvgPicture.network(
        "https://giaidau.vnvar.com/vndcsport.svg",
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const Icon(
          Icons.emoji_events_rounded,
          color: AppTheme.primary,
          size: 24,
        ),
      );
    }
    final resolved = _resolveImageUrl(url);
    if (resolved.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        resolved,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const Icon(
          Icons.emoji_events_rounded,
          color: AppTheme.primary,
          size: 24,
        ),
      );
    }
    return Image.network(
      resolved,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => SvgPicture.network(
        "https://giaidau.vnvar.com/vndcsport.svg",
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const Icon(
          Icons.emoji_events_rounded,
          color: AppTheme.primary,
          size: 24,
        ),
      ),
    );
  }

  static String _resolveImageUrl(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }
    if (url.startsWith("/")) {
      return "https://qlgiaidau.esports.vn$url";
    }
    return "https://qlgiaidau.esports.vn/$url";
  }
}
