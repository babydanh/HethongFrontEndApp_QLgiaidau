import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/shared/widgets/app_image_viewer.dart';

class GalleryTab extends StatelessWidget {
  final List<String> galleryImages;
  final String Function(String? url) resolveImageUrl;
  final ScrollController? scrollController;

  const GalleryTab({
    super.key,
    required this.galleryImages,
    required this.resolveImageUrl,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (galleryImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: colors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              l10n.noGalleryImages,
              style: TextStyle(fontSize: 15, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    final resolvedImages = galleryImages.map((img) => resolveImageUrl(img)).toList();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: galleryImages.length,
      itemBuilder: (context, index) {
        final imageUrl = resolvedImages[index];
        return GestureDetector(
          onTap: () {
            AppImageViewer.showGallery(
              context,
              imageUrls: resolvedImages,
              initialIndex: index,
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: colors.bgSurface,
                    child: Icon(Icons.broken_image_outlined, color: colors.textMuted),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: colors.bgSurface,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
