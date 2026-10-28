import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sponsors_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class TournamentManagementSponsorsSection extends ConsumerStatefulWidget {
  const TournamentManagementSponsorsSection({
    super.key,
    required this.tournamentId,
  });
  final String tournamentId;

  @override
  ConsumerState<TournamentManagementSponsorsSection> createState() =>
      _TournamentManagementSponsorsSectionState();
}

class _TournamentManagementSponsorsSectionState
    extends ConsumerState<TournamentManagementSponsorsSection> {
  List<TournamentSponsor>? _items;
  Object? _loadError;
  bool _isBusy = false;
  bool _mutationFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads the list from the server; the previous rows stay on screen until
  /// the new ones land, so a toggle or a drag never blanks the list.
  Future<void> _load() async {
    try {
      final rows = await ref
          .read(tournamentManagementRepositoryProvider)
          .getSponsors(widget.tournamentId);
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loadError = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  void _retry() {
    setState(() => _loadError = null);
    _load();
  }

  /// Runs one write behind the busy flag (no double taps), then re-reads the
  /// list so the server stays the truth even when the write failed.
  Future<void> _mutate(Future<void> Function() write) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _mutationFailed = false;
    });
    try {
      await write();
    } on Object {
      if (mounted) setState(() => _mutationFailed = true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null && _loadError != null) {
      return TournamentManagementError(error: _loadError, onRetry: _retry);
    }
    if (items == null) return const Center(child: CircularProgressIndicator());
    return LavishSurface(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildTopBar(context, items),
          if (_mutationFailed) _buildMutationError(context),
          if (items.isEmpty) _buildEmpty(context) else ..._buildBody(items),
        ],
      ),
    );
  }

  /// Design `.bar` right action: "+ Add" in the accent colour, 14px / 800.
  Widget _buildTopBar(BuildContext context, List<TournamentSponsor> items) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 0),
        child: TextButton.icon(
          onPressed: _isBusy ? null : () => _openEditor(items),
          style: TextButton.styleFrom(
            foregroundColor: LavishColors.accent,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.tournamentManagementAddSponsorShort),
        ),
      ),
    );
  }

  Widget _buildMutationError(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
    child: Text(
      AppLocalizations.of(context)!.tournamentManagementActionError,
      style: const TextStyle(fontSize: 13, color: LavishColors.bad),
    ),
  );

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManagementEmpty(
      title: l10n.tournamentManagementSponsorsEmpty,
      subtitle: l10n.tournamentManagementSponsorsEmptyDescription,
      icon: Icons.handshake_outlined,
    );
  }

  List<Widget> _buildBody(List<TournamentSponsor> items) {
    final l10n = AppLocalizations.of(context)!;
    return [
      ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: (oldIndex, newIndex) =>
            _reorder(items, oldIndex, newIndex),
        children: [
          for (var index = 0; index < items.length; index++)
            _buildRow(items, index),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: LavishButton(
          kind: LavishButtonKind.outline,
          label: l10n.tournamentManagementSponsorPreview,
          onPressed: () => _openPreview(items),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Text(
          l10n.tournamentManagementSponsorHint,
          style: TextStyle(fontSize: 13, color: LavishColors.of(context).muted),
        ),
      ),
    ];
  }

  Widget _buildRow(List<TournamentSponsor> items, int index) {
    final sponsor = items[index];
    return Dismissible(
      key: ValueKey('sponsor-row-${sponsor.id}'),
      direction: sponsor.isArchived || _isBusy
          ? DismissDirection.none
          : DismissDirection.endToStart,
      // The row is never removed: an archived sponsor stays listed with its
      // archived label, so the write runs here and the dismissal is refused.
      confirmDismiss: (_) async {
        await _archive(sponsor);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: LavishColors.of(context).soft(LavishTone.bad),
        child: const Icon(Icons.archive_outlined, color: LavishColors.bad),
      ),
      child: _SponsorRow(
        sponsor: sponsor,
        index: index,
        isBusy: _isBusy,
        onEdit: () => _openEditor(items, sponsor),
        onTogglePublic: (value) => _setPublic(sponsor, value),
      ),
    );
  }

  Future<void> _reorder(
    List<TournamentSponsor> items,
    int oldIndex,
    int newIndex,
  ) async {
    if (_isBusy || oldIndex == newIndex) return;
    final next = [...items];
    next.insert(newIndex, next.removeAt(oldIndex));
    final changes = sponsorOrderChanges(next);
    setState(() => _items = next);
    await _mutate(() async {
      final repository = ref.read(tournamentManagementRepositoryProvider);
      for (final change in changes.entries) {
        await repository.updateSponsor(widget.tournamentId, change.key, {
          'displayOrder': change.value,
        });
      }
    });
  }

  Future<void> _setPublic(TournamentSponsor sponsor, bool value) => _mutate(
    () => ref.read(tournamentManagementRepositoryProvider).updateSponsor(
      widget.tournamentId,
      sponsor.id,
      {'status': value ? 'PUBLISHED' : 'DRAFT', 'isPublic': value},
    ),
  );

  void _openPreview(List<TournamentSponsor> items) {
    final visible = items.where((sponsor) => sponsor.isShownPublicly).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.8,
        child: SponsorsTab(sponsors: visible),
      ),
    );
  }

  Future<void> _openEditor(
    List<TournamentSponsor> items, [
    TournamentSponsor? sponsor,
  ]) async {
    // A new sponsor goes to the end of the list, like the Web panel.
    final nextOrder =
        items.fold<int>(-1, (top, item) => math.max(top, item.displayOrder)) +
        1;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final messenger = ScaffoldMessenger.of(dialogContext);
        final savedLabel = AppLocalizations.of(
          dialogContext,
        )!.tournamentManagementSponsorSaved;
        return _SponsorEditorDialog(
          sponsor: sponsor,
          nextOrder: nextOrder,
          onSave: (payload) async {
            final repository = ref.read(tournamentManagementRepositoryProvider);
            if (sponsor == null) {
              await repository.createSponsor(widget.tournamentId, payload);
            } else {
              await repository.updateSponsor(
                widget.tournamentId,
                sponsor.id,
                payload,
              );
            }
            if (!mounted || !messenger.mounted) return;
            _load();
            messenger.showSnackBar(SnackBar(content: Text(savedLabel)));
          },
        );
      },
    );
  }

  Future<void> _archive(TournamentSponsor sponsor) async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementArchiveSponsor,
      message: l10n.tournamentManagementArchiveSponsorConfirm(
        sponsor.displayName,
      ),
      confirmLabel: l10n.tournamentManagementArchive,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _mutate(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .archiveSponsor(widget.tournamentId, sponsor.id),
    );
  }
}

class _SponsorEditorDialog extends ConsumerStatefulWidget {
  const _SponsorEditorDialog({
    required this.sponsor,
    required this.nextOrder,
    required this.onSave,
  });
  final TournamentSponsor? sponsor;

  /// `displayOrder` given to a new sponsor; an edited one keeps its own.
  final int nextOrder;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  @override
  ConsumerState<_SponsorEditorDialog> createState() =>
      _SponsorEditorDialogState();
}

class _SponsorEditorDialogState extends ConsumerState<_SponsorEditorDialog> {
  late final _name = TextEditingController(
    text: widget.sponsor?.displayName ?? '',
  );
  late final _logo = TextEditingController(text: widget.sponsor?.logoUrl ?? '');
  late final _website = TextEditingController(
    text: widget.sponsor?.websiteUrl ?? '',
  );
  late final _description = TextEditingController(
    text: widget.sponsor?.shortDescription ?? '',
  );
  late String _tier = _normalizeTier(widget.sponsor?.tier ?? 'GOLD');
  late bool _isPublic =
      widget.sponsor == null ||
      (widget.sponsor!.status.toUpperCase() == 'PUBLISHED' &&
          (widget.sponsor!.isPublic ?? true));
  bool _isSaving = false;
  bool _isUploading = false;
  bool _hasError = false;

  @override
  void dispose() {
    _name.dispose();
    _logo.dispose();
    _website.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.sponsor == null
            ? l10n.tournamentManagementAddSponsor
            : l10n.tournamentManagementEditSponsor,
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementSponsorName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _logo,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementSponsorLogo,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _isUploading ? null : _uploadLogo,
                    tooltip: l10n.tournamentManagementUploadLogo,
                    icon: _isUploading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _tier,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementSponsorTier,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final value in const [
                    'TITLE',
                    'DIAMOND',
                    'GOLD',
                    'SILVER',
                    'BRONZE',
                    'IN_KIND',
                  ])
                    DropdownMenuItem(
                      value: value,
                      child: Text(_sponsorTierLabel(l10n, value)),
                    ),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _tier = value);
                      },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _website,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementSponsorWebsite,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementSponsorDescription,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isPublic,
                title: Text(l10n.tournamentManagementSponsorPublic),
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _isPublic = value),
              ),
              if (_hasError)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.tournamentManagementSaveError,
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.tournamentManagementCancel),
        ),
        FilledButton(
          onPressed: _isSaving || _isUploading ? null : _save,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.tournamentManagementSave),
        ),
      ],
    );
  }

  Future<void> _uploadLogo() async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _hasError = false;
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
      if (mounted) _logo.text = url;
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _name.text.trim();
    final logoUrl = _logo.text.trim();
    if (name.isEmpty || logoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    setState(() {
      _isSaving = true;
      _hasError = false;
    });
    try {
      await widget.onSave({
        'displayName': name,
        'tier': _tier,
        'logoUrl': logoUrl,
        'websiteUrl': _website.text.trim().isEmpty
            ? null
            : _website.text.trim(),
        'shortDescription': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'displayOrder': widget.sponsor?.displayOrder ?? widget.nextOrder,
        'status': _isPublic ? 'PUBLISHED' : 'DRAFT',
        'isPublic': _isPublic,
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _normalizeTier(String tier) =>
      const {
        'TITLE',
        'DIAMOND',
        'GOLD',
        'SILVER',
        'BRONZE',
        'IN_KIND',
      }.contains(tier.toUpperCase())
      ? tier.toUpperCase()
      : 'GOLD';
}

String _sponsorTierLabel(AppLocalizations l10n, String tier) =>
    switch (tier.toUpperCase()) {
      'TITLE' => l10n.tournamentManagementSponsorTierTitle,
      'DIAMOND' => l10n.tournamentManagementSponsorTierDiamond,
      'GOLD' => l10n.tournamentManagementSponsorTierGold,
      'SILVER' => l10n.tournamentManagementSponsorTierSilver,
      'BRONZE' => l10n.tournamentManagementSponsorTierBronze,
      _ => l10n.tournamentManagementSponsorTierInKind,
    };

/// Rank wording of the design ("Hạng Vàng"). The title and in-kind tiers are
/// not ranks, so they keep their own label.
String _sponsorTierRank(AppLocalizations l10n, String tier) {
  final label = _sponsorTierLabel(l10n, tier);
  return switch (tier.toUpperCase()) {
    'DIAMOND' ||
    'GOLD' ||
    'SILVER' ||
    'BRONZE' => l10n.tournamentManagementSponsorTierRank(label),
    _ => label,
  };
}

/// Design screen 12 `.li`: drag handle, letter avatar, name + rank, public
/// switch. Tapping the row edits it; archiving is a swipe on the wrapping
/// `Dismissible`. (The backend has no MVP flag, so the design's MVP badge is
/// not drawn.)
class _SponsorRow extends StatelessWidget {
  const _SponsorRow({
    required this.sponsor,
    required this.index,
    required this.isBusy,
    required this.onEdit,
    required this.onTogglePublic,
  });
  final TournamentSponsor sponsor;
  final int index;
  final bool isBusy;
  final VoidCallback onEdit;
  final ValueChanged<bool> onTogglePublic;

  @override
  Widget build(BuildContext context) {
    final colors = LavishColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final rank = _sponsorTierRank(l10n, sponsor.tier);
    return LavishRow(
      background: colors.surface,
      onTap: isBusy ? null : onEdit,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReorderableDragStartListener(
            key: ValueKey('sponsor-handle-${sponsor.id}'),
            index: index,
            child: Tooltip(
              message: l10n.tournamentManagementSponsorDragHandle,
              child: Icon(Icons.drag_indicator, size: 18, color: colors.faint),
            ),
          ),
          const SizedBox(width: 11),
          _SponsorAvatar(sponsor: sponsor),
        ],
      ),
      title: sponsor.displayName,
      subtitle: sponsor.isArchived
          ? '$rank · ${l10n.tournamentManagementSponsorArchived}'
          : rank,
      trailing: [
        LavishSwitch(
          key: ValueKey('sponsor-switch-${sponsor.id}'),
          value: sponsor.isShownPublicly,
          onChanged: sponsor.isArchived || isBusy ? null : onTogglePublic,
        ),
      ],
    );
  }
}

/// Design `.av` (36px, 10px radius, light-blue letter tile); the logo is drawn
/// over it once it has loaded.
class _SponsorAvatar extends StatelessWidget {
  const _SponsorAvatar({required this.sponsor});
  final TournamentSponsor sponsor;

  @override
  Widget build(BuildContext context) {
    final colors = LavishColors.of(context);
    final name = sponsor.displayName.trim();
    final letter = Container(
      color: colors.dark
          ? colors.soft(LavishTone.accent)
          : const Color(0xFFD1E9FF),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty
            ? '?'
            : String.fromCharCode(name.runes.first).toUpperCase(),
        style: TextStyle(
          color: colors.dark ? LavishColors.accent : const Color(0xFF1570EF),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 36,
        height: 36,
        child: sponsor.logoUrl.isEmpty
            ? letter
            : Image.network(
                resolveTournamentManagementImageUrl(sponsor.logoUrl),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : letter,
                errorBuilder: (context, error, stack) => letter,
              ),
      ),
    );
  }
}
