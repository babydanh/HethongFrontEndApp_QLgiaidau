part of '../screens/club_detail_screen.dart';

extension _ClubDetailGalleryTab on _ClubDetailScreenState {
  Widget _buildGalleryTab(Community club, AppColorsExtension colors) {
    if (club.visibility.toUpperCase() == 'PRIVATE' && !_isMember) {
      return _buildPrivateLockView(
        icon: Icons.photo_library_rounded,
        title: 'Thư viện hình ảnh riêng tư',
        description:
            'Hình ảnh hoạt động và khoảnh khắc của CLB chỉ dành riêng cho thành viên chính thức.',
        club: club,
        colors: colors,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final galleryAsync = ref.watch(communityGalleryProvider(widget.clubId));
    final isAdmin =
        _myMembership?.role == 'OWNER' ||
        _myMembership?.role == 'ADMIN' ||
        _myMembership?.role == 'MODERATOR';

    return galleryAsync.when(
      data: (images) {
        // Collect all images with metadata
        final List<({String id, String url, String title, bool isSystem})>
        allItems = [
          if (club.logoUrl != null && club.logoUrl!.isNotEmpty)
            (
              id: 'sys-logo',
              url: club.logoUrl!,
              title: l10n.clubDetailClubLogo,
              isSystem: true,
            ),
          if (club.bannerUrl != null && club.bannerUrl!.isNotEmpty)
            (
              id: 'sys-banner',
              url: club.bannerUrl!,
              title: l10n.clubDetailCoverImage,
              isSystem: true,
            ),
          ...images.map(
            (img) => (
              id: img.id,
              url: img.imageUrl,
              title: l10n.clubDetailActivityImage,
              isSystem: false,
            ),
          ),
        ];

        if (allItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: colors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.club_noImages,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.club_gallerySubtitle,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isAddingGalleryImage ? null : _addGalleryImage,
                    icon: _isAddingGalleryImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l10n.clubDetailAddFirstImage),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.clubDetailGalleryTitle(allItems.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      tooltip: l10n.clubDetailAddImage,
                      onPressed: _isAddingGalleryImage
                          ? null
                          : _addGalleryImage,
                      icon: _isAddingGalleryImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0, // Ảnh vuông 1:1
                ),
                itemCount: allItems.length,
                itemBuilder: (context, i) {
                  final item = allItems[i];
                  final resolvedUrl = _resolveImageUrl(item.url);
                  return GestureDetector(
                    onTap: () => _showImagePreview(resolvedUrl),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClubNetworkImage(
                              resolvedUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: colors.bgSurface,
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: colors.textMuted,
                                      size: 28,
                                    ),
                                  ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: colors.bgSurface,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Badge label cho Logo / Banner
                            if (item.isSystem)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            // Nút xoá cho ảnh hoạt động nếu là Admin/Owner
                            if (!item.isSystem && isAdmin)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      _confirmDeleteGalleryImage(item.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () {
        // Nếu đã có data cũ (reload/refresh), không hiển thị loading vô hạn
        final previousData = galleryAsync.value;
        if (previousData != null && previousData.isNotEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        // Chưa có data → hiển thị "Chưa có ảnh" thay vì loading vĩnh viễn
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: colors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.club_noImages,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.club_gallerySubtitle,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        );
      },
      error: (e, st) {
        _log.error('Lỗi tải gallery', e, st);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.club_loadImagesError,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}
