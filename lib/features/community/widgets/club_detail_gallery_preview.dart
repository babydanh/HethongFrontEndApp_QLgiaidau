part of '../screens/club_detail_screen.dart';

extension _ClubDetailGalleryPreview on _ClubDetailScreenState {
  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ClubNetworkImage(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.black,
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGalleryImage(String imageId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.clubDetailDeleteImageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(l10n.clubDetailDeleteImageDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(communityRepositoryProvider);
                await repo.removeGalleryItem(widget.clubId, imageId);
                ref.invalidate(communityGalleryProvider(widget.clubId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.clubDetailGalleryRemoved)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.clubDetailGalleryRemoveError)),
                  );
                }
              }
            },
            child: Text(l10n.clubDetailDeleteAction),
          ),
        ],
      ),
    );
  }
}
