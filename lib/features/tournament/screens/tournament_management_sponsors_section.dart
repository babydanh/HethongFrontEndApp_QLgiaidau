import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
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
  late Future<List<TournamentSponsor>> _sponsorsFuture;
  bool _isBusy = false;
  String? _mutationError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _sponsorsFuture = ref
      .read(tournamentManagementRepositoryProvider)
      .getSponsors(widget.tournamentId);
  void _reload() => setState(() {
    _mutationError = null;
    _load();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<TournamentSponsor>>(
      future: _sponsorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return TournamentManagementError(onRetry: _reload);
        final sponsors = snapshot.data ?? const <TournamentSponsor>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TournamentManagementSectionCard(
              title: l10n.tournamentManagementSponsors,
              subtitle: l10n.tournamentManagementSponsorsDescription,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isBusy ? null : () => _openEditor(),
                      icon: const Icon(Icons.handshake_outlined),
                      label: Text(l10n.tournamentManagementAddSponsor),
                    ),
                  ),
                  if (_mutationError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.tournamentManagementActionError,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ],
                  if (sponsors.isEmpty)
                    TournamentManagementEmpty(
                      title: l10n.tournamentManagementSponsorsEmpty,
                      subtitle:
                          l10n.tournamentManagementSponsorsEmptyDescription,
                      icon: Icons.handshake_outlined,
                    )
                  else ...[
                    const SizedBox(height: 12),
                    for (final sponsor in sponsors) ...[
                      _SponsorCard(
                        sponsor: sponsor,
                        isBusy: _isBusy,
                        onEdit: () => _openEditor(sponsor),
                        onArchive: () => _archive(sponsor),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditor([TournamentSponsor? sponsor]) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _SponsorEditorDialog(
        sponsor: sponsor,
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
          if (!mounted) return;
          _reload();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.tournamentManagementSponsorSaved,
              ),
            ),
          );
        },
      ),
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
    setState(() {
      _isBusy = true;
      _mutationError = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .archiveSponsor(widget.tournamentId, sponsor.id);
      if (mounted) _reload();
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}

class _SponsorEditorDialog extends ConsumerStatefulWidget {
  const _SponsorEditorDialog({required this.sponsor, required this.onSave});
  final TournamentSponsor? sponsor;
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
  late final _order = TextEditingController(
    text: (widget.sponsor?.displayOrder ?? 0).toString(),
  );
  late String _tier = _normalizeTier(widget.sponsor?.tier ?? 'GOLD');
  bool _isPublic = true;
  bool _isSaving = false;
  bool _isUploading = false;
  bool _hasError = false;

  @override
  void dispose() {
    _name.dispose();
    _logo.dispose();
    _website.dispose();
    _description.dispose();
    _order.dispose();
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
                      child: Text(_tierLabel(l10n, value)),
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
              const SizedBox(height: 10),
              TextField(
                controller: _order,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementDisplayOrder,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (widget.sponsor == null)
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
    final displayOrder = int.tryParse(_order.text.trim());
    if (name.isEmpty ||
        logoUrl.isEmpty ||
        displayOrder == null ||
        displayOrder < 0) {
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
        'displayOrder': displayOrder,
        if (widget.sponsor == null) 'status': _isPublic ? 'PUBLISHED' : 'DRAFT',
        if (widget.sponsor == null) 'isPublic': _isPublic,
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

  String _tierLabel(AppLocalizations l10n, String tier) => switch (tier) {
    'TITLE' => l10n.tournamentManagementSponsorTierTitle,
    'DIAMOND' => l10n.tournamentManagementSponsorTierDiamond,
    'GOLD' => l10n.tournamentManagementSponsorTierGold,
    'SILVER' => l10n.tournamentManagementSponsorTierSilver,
    'BRONZE' => l10n.tournamentManagementSponsorTierBronze,
    _ => l10n.tournamentManagementSponsorTierInKind,
  };
}

class _SponsorCard extends StatelessWidget {
  const _SponsorCard({
    required this.sponsor,
    required this.isBusy,
    required this.onEdit,
    required this.onArchive,
  });
  final TournamentSponsor sponsor;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 54,
              height: 54,
              child: sponsor.logoUrl.isEmpty
                  ? Icon(Icons.handshake_outlined, color: colors.textMuted)
                  : Image.network(
                      resolveTournamentManagementImageUrl(sponsor.logoUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Icon(
                        Icons.broken_image_outlined,
                        color: colors.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sponsor.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _tierLabel(l10n, sponsor.tier),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                if (sponsor.shortDescription?.isNotEmpty == true)
                  Text(
                    sponsor.shortDescription!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: isBusy ? null : onEdit,
            tooltip: l10n.tournamentManagementEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: isBusy ? null : onArchive,
            tooltip: l10n.tournamentManagementArchive,
            icon: Icon(Icons.archive_outlined, color: colors.error),
          ),
        ],
      ),
    );
  }

  String _tierLabel(AppLocalizations l10n, String tier) =>
      switch (tier.toUpperCase()) {
        'TITLE' => l10n.tournamentManagementSponsorTierTitle,
        'DIAMOND' => l10n.tournamentManagementSponsorTierDiamond,
        'GOLD' => l10n.tournamentManagementSponsorTierGold,
        'SILVER' => l10n.tournamentManagementSponsorTierSilver,
        'BRONZE' => l10n.tournamentManagementSponsorTierBronze,
        _ => l10n.tournamentManagementSponsorTierInKind,
      };
}
