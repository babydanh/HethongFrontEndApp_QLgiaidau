part of '../screens/club_detail_screen.dart';

extension _ClubDetailGalleryAdd on _ClubDetailScreenState {
  Future<void> _addGalleryImage() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    _updateClubState(() => _isAddingGalleryImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final repo = ref.read(communityRepositoryProvider);
      final imageUrl = await ref
          .read(communitySocialRepositoryProvider)
          .uploadImage(bytes, picked.name);
      await repo.addGalleryItem(widget.clubId, imageUrl: imageUrl);
      ref.invalidate(communityGalleryProvider(widget.clubId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailGalleryAdded)));
      }
    } catch (e, stack) {
      _log.error('Lỗi thêm ảnh gallery', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailGalleryAddError)));
      }
    } finally {
      _updateClubState(() => _isAddingGalleryImage = false);
    }
  }
}
