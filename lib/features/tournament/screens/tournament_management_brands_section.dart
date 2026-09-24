import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class TournamentManagementBrandsSection extends ConsumerStatefulWidget {
  const TournamentManagementBrandsSection({
    super.key,
    required this.tournament,
  });
  final Tournament tournament;

  @override
  ConsumerState<TournamentManagementBrandsSection> createState() =>
      _TournamentManagementBrandsSectionState();
}

class _TournamentManagementBrandsSectionState
    extends ConsumerState<TournamentManagementBrandsSection> {
  String? _logoUrl;
  String? _bannerUrl;
  bool _isBusy = false;
  String? _error;
  late Future<List<String>> _galleryFuture;

  @override
  void initState() {
    super.initState();
    _galleryFuture = ref
        .read(tournamentManagementRepositoryProvider)
        .getGallery(widget.tournament.id);
    _logoUrl = widget.tournament.logoUrl;
    _bannerUrl = widget.tournament.bannerUrl;
  }

  void _reload() {
    setState(() {
      _error = null;
      _galleryFuture = ref
          .read(tournamentManagementRepositoryProvider)
          .getGallery(widget.tournament.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TournamentManagementSectionCard(
          title: l10n.tournamentManagementBrandAssets,
          subtitle: l10n.tournamentManagementBrandAssetsDescription,
          child: Column(
            children: [
              _BrandImageTile(
                label: l10n.tournamentManagementLogo,
                url: _logoUrl,
                icon: Icons.emoji_events_outlined,
                isBusy: _isBusy,
                actionLabel: l10n.tournamentManagementUploadLogo,
                onUpload: () => _uploadBrandImage(isLogo: true),
              ),
              const SizedBox(height: 12),
              _BrandImageTile(
                label: l10n.tournamentManagementBanner,
                url: _bannerUrl,
                icon: Icons.panorama_outlined,
                isBusy: _isBusy,
                actionLabel: l10n.tournamentManagementUploadBanner,
                onUpload: () => _uploadBrandImage(isLogo: false),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.tournamentManagementSaveError,
                  style: TextStyle(color: colors.error),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        TournamentManagementSectionCard(
          title: l10n.tournamentManagementGallery,
          subtitle: l10n.tournamentManagementGalleryDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isBusy ? null : _addGalleryImage,
                  icon: _isBusy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.tournamentManagementAddImage),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.tournamentManagementSaveError,
                  style: TextStyle(color: colors.error),
                ),
              ],
              const SizedBox(height: 12),
              FutureBuilder<List<String>>(
                future: _galleryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError)
                    return TournamentManagementError(onRetry: _reload);
                  final images = snapshot.data ?? const <String>[];
                  if (images.isEmpty)
                    return TournamentManagementEmpty(
                      title: l10n.tournamentManagementGalleryEmpty,
                      subtitle:
                          l10n.tournamentManagementGalleryEmptyDescription,
                      icon: Icons.photo_library_outlined,
                    );
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 700
                          ? 4
                          : constraints.maxWidth >= 430
                          ? 3
                          : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.05,
                        ),
                        itemCount: images.length,
                        itemBuilder: (context, index) => _GalleryImageTile(
                          url: images[index],
                          onRemove: _isBusy
                              ? null
                              : () => _removeGalleryImage(index),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _uploadBrandImage({required bool isLogo}) async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (picked == null || !mounted) return;
      final url = await ref
          .read(communitySocialRepositoryProvider)
          .uploadImage(await picked.readAsBytes(), picked.name);
      await ref.read(tournamentRepositoryProvider).update(
        widget.tournament.id,
        {isLogo ? 'logoUrl' : 'bannerUrl': url},
      );
      setState(() {
        if (isLogo) {
          _logoUrl = url;
        } else {
          _bannerUrl = url;
        }
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLogo
                  ? l10n.tournamentManagementLogoSaved
                  : l10n.tournamentManagementBannerSaved,
            ),
          ),
        );
    } catch (_) {
      if (mounted) setState(() => _error = 'upload');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _addGalleryImage() async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (picked == null || !mounted) return;
      final url = await ref
          .read(communitySocialRepositoryProvider)
          .uploadImage(await picked.readAsBytes(), picked.name);
      await ref
          .read(tournamentManagementRepositoryProvider)
          .addGalleryImage(widget.tournament.id, url);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tournamentManagementGalleryImageAdded)),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'upload');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _removeGalleryImage(int index) async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementRemoveImage,
      message: l10n.tournamentManagementRemoveImageConfirm,
      confirmLabel: l10n.tournamentManagementRemove,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .removeGalleryImage(widget.tournament.id, index);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tournamentManagementGalleryImageRemoved)),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'remove');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}

class _BrandImageTile extends StatelessWidget {
  const _BrandImageTile({
    required this.label,
    required this.url,
    required this.icon,
    required this.isBusy,
    required this.actionLabel,
    required this.onUpload,
  });
  final String label;
  final String? url;
  final IconData icon;
  final bool isBusy;
  final String actionLabel;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 76,
              height: 64,
              child: url?.trim().isNotEmpty == true
                  ? Image.network(
                      resolveTournamentManagementImageUrl(url!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Icon(icon, color: colors.textMuted, size: 30),
                    )
                  : Icon(icon, color: colors.textMuted, size: 30),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: isBusy ? null : onUpload,
            tooltip: actionLabel,
            icon: const Icon(Icons.upload_rounded),
          ),
        ],
      ),
    );
  }
}

class _GalleryImageTile extends StatelessWidget {
  const _GalleryImageTile({required this.url, required this.onRemove});
  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            resolveTournamentManagementImageUrl(url),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: colors.bgSurface,
              child: Icon(Icons.broken_image_outlined, color: colors.textMuted),
            ),
          ),
          PositionedDirectional(
            top: 4,
            end: 4,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(18),
              child: IconButton(
                onPressed: onRemove,
                tooltip: AppLocalizations.of(
                  context,
                )!.tournamentManagementRemoveImage,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
