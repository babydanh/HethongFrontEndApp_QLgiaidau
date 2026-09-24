import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TournamentManagementVenuesSection extends ConsumerStatefulWidget {
  const TournamentManagementVenuesSection({
    super.key,
    required this.tournamentId,
  });
  final String tournamentId;

  @override
  ConsumerState<TournamentManagementVenuesSection> createState() =>
      _TournamentManagementVenuesSectionState();
}

class _TournamentManagementVenuesSectionState
    extends ConsumerState<TournamentManagementVenuesSection> {
  late Future<List<Map<String, dynamic>>> _venuesFuture;
  bool _isBusy = false;
  String? _mutationError;

  @override
  void initState() {
    super.initState();
    _venuesFuture = ref
        .read(tournamentManagementRepositoryProvider)
        .getVenues(widget.tournamentId);
  }

  void _reload() {
    setState(() {
      _mutationError = null;
      _venuesFuture = ref
          .read(tournamentManagementRepositoryProvider)
          .getVenues(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _venuesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return TournamentManagementError(onRetry: _reload);
        final venues = snapshot.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TournamentManagementSectionCard(
              title: l10n.tournamentManagementVenues,
              subtitle: l10n.tournamentManagementVenuesDescription,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isBusy ? null : _createVenue,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(l10n.tournamentManagementAddVenue),
                    ),
                  ),
                  if (_mutationError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.tournamentManagementActionError,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ],
                  if (venues.isEmpty)
                    TournamentManagementEmpty(
                      title: l10n.tournamentManagementVenuesEmpty,
                      subtitle: l10n.tournamentManagementVenuesEmptyDescription,
                      icon: Icons.place_outlined,
                    )
                  else ...[
                    const SizedBox(height: 12),
                    for (final venue in venues) ...[
                      _VenueCard(
                        venue: venue,
                        isBusy: _isBusy,
                        onEdit: () => _editVenue(venue),
                        onSetDefault: () => _setDefault(venue),
                        onRemove: () => _removeVenue(venue),
                        onAddCourt: () => _addCourt(venue),
                        onRemoveCourt: (court) => _removeCourt(venue, court),
                      ),
                      const SizedBox(height: 12),
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

  Future<void> _createVenue() async {
    final l10n = AppLocalizations.of(context)!;
    final values = await _showVenueDialog(
      title: l10n.tournamentManagementAddVenue,
      initialCourtFields: true,
    );
    if (values == null || !mounted) return;
    final name = values.name.trim();
    final address = values.address.trim();
    if (name.isEmpty || address.isEmpty) {
      _showMessage(l10n.tournamentManagementRequiredFields);
      return;
    }
    await _mutate(() async {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .createVenue(
            widget.tournamentId,
            name: name,
            locationAddress: address,
            isDefault: values.isDefault,
            initialCourtCount: values.initialCourtCount,
            courtPrefix: values.courtPrefix?.trim().isEmpty == true
                ? null
                : values.courtPrefix?.trim(),
          );
    });
  }

  Future<void> _editVenue(Map<String, dynamic> venue) async {
    final l10n = AppLocalizations.of(context)!;
    final venueId = tournamentManagementRecordId(venue);
    if (venueId.isEmpty) return;
    final values = await _showVenueDialog(
      title: l10n.tournamentManagementEditVenue,
      initialName: tournamentManagementRecordName(venue),
      initialAddress: (venue['locationAddress'] ?? venue['address'] ?? '')
          .toString(),
    );
    if (values == null || !mounted) return;
    await _mutate(() async {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .updateVenue(
            widget.tournamentId,
            venueId,
            name: values.name.trim(),
            locationAddress: values.address.trim(),
          );
    });
  }

  Future<void> _setDefault(Map<String, dynamic> venue) async {
    final venueId = tournamentManagementRecordId(venue);
    if (venueId.isEmpty) return;
    await _mutate(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .setDefaultVenue(widget.tournamentId, venueId),
    );
  }

  Future<void> _removeVenue(Map<String, dynamic> venue) async {
    final l10n = AppLocalizations.of(context)!;
    final venueId = tournamentManagementRecordId(venue);
    if (venueId.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementRemoveVenue,
      message: l10n.tournamentManagementRemoveVenueConfirm(
        tournamentManagementRecordName(venue),
      ),
      confirmLabel: l10n.tournamentManagementRemove,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _mutate(() async {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .removeVenue(widget.tournamentId, venueId);
    });
  }

  Future<void> _addCourt(Map<String, dynamic> venue) async {
    final l10n = AppLocalizations.of(context)!;
    final venueId = tournamentManagementRecordId(venue);
    if (venueId.isEmpty) return;
    final name = await _textDialog(
      title: l10n.tournamentManagementAddCourt,
      label: l10n.tournamentManagementCourtName,
    );
    if (name == null || !mounted) return;
    if (name.trim().isEmpty) {
      _showMessage(l10n.tournamentManagementRequiredFields);
      return;
    }
    await _mutate(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .addCourt(widget.tournamentId, venueId, courtName: name.trim()),
    );
  }

  Future<void> _removeCourt(
    Map<String, dynamic> venue,
    Map<String, dynamic> court,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final venueId = tournamentManagementRecordId(venue);
    final courtId = (court['id'] ?? court['courtId'] ?? '').toString();
    if (venueId.isEmpty || courtId.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementRemoveCourt,
      message: l10n.tournamentManagementRemoveCourtConfirm(
        (court['name'] ?? court['courtName'] ?? '').toString(),
      ),
      confirmLabel: l10n.tournamentManagementRemove,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _mutate(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .removeCourt(widget.tournamentId, venueId, courtId),
    );
  }

  Future<void> _mutate(Future<void> Function() operation) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _mutationError = null;
    });
    try {
      await operation();
      if (mounted) _reload();
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<_VenueValues?> _showVenueDialog({
    required String title,
    String initialName = '',
    String initialAddress = '',
    bool initialCourtFields = false,
  }) => showDialog<_VenueValues>(
    context: context,
    builder: (context) => _VenueDialog(
      title: title,
      initialName: initialName,
      initialAddress: initialAddress,
      showCourtFields: initialCourtFields,
    ),
  );

  Future<String?> _textDialog({
    required String title,
    required String label,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.tournamentManagementCancel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context)!.tournamentManagementSave),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _VenueValues {
  const _VenueValues({
    required this.name,
    required this.address,
    this.isDefault = false,
    this.initialCourtCount,
    this.courtPrefix,
  });
  final String name;
  final String address;
  final bool isDefault;
  final int? initialCourtCount;
  final String? courtPrefix;
}

class _VenueDialog extends StatefulWidget {
  const _VenueDialog({
    required this.title,
    required this.initialName,
    required this.initialAddress,
    required this.showCourtFields,
  });
  final String title;
  final String initialName;
  final String initialAddress;
  final bool showCourtFields;

  @override
  State<_VenueDialog> createState() => _VenueDialogState();
}

class _VenueDialogState extends State<_VenueDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _address = TextEditingController(text: widget.initialAddress);
  late final _count = TextEditingController();
  late final _prefix = TextEditingController();
  bool _default = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _count.dispose();
    _prefix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementVenueName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementVenueAddress,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (widget.showCourtFields) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _count,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementInitialCourtCount,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prefix,
                decoration: InputDecoration(
                  labelText: l10n.tournamentManagementCourtPrefix,
                  border: const OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _default,
                title: Text(l10n.tournamentManagementSetAsDefault),
                onChanged: (value) => setState(() => _default = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.tournamentManagementCancel),
        ),
        FilledButton(
          onPressed: () {
            final parsedCount = int.tryParse(_count.text.trim());
            Navigator.pop(
              context,
              _VenueValues(
                name: _name.text,
                address: _address.text,
                isDefault: _default,
                initialCourtCount:
                    widget.showCourtFields &&
                        parsedCount != null &&
                        parsedCount > 0
                    ? parsedCount
                    : null,
                courtPrefix: _prefix.text,
              ),
            );
          },
          child: Text(l10n.tournamentManagementSave),
        ),
      ],
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.isBusy,
    required this.onEdit,
    required this.onSetDefault,
    required this.onRemove,
    required this.onAddCourt,
    required this.onRemoveCourt,
  });
  final Map<String, dynamic> venue;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;
  final VoidCallback onAddCourt;
  final ValueChanged<Map<String, dynamic>> onRemoveCourt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isDefault = venue['isDefault'] == true || venue['is_default'] == true;
    final rawCourts = venue['courts'] is List
        ? venue['courts'] as List
        : const [];
    final courts = rawCourts
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final address = (venue['locationAddress'] ?? venue['address'] ?? '')
        .toString();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournamentManagementRecordName(venue),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (address.isNotEmpty)
                      Text(
                        address,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                  ],
                ),
              ),
              if (isDefault)
                Chip(
                  label: Text(l10n.tournamentManagementDefaultVenue),
                  visualDensity: VisualDensity.compact,
                ),
              PopupMenuButton<String>(
                enabled: !isBusy,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'default') onSetDefault();
                  if (value == 'remove') onRemove();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(l10n.tournamentManagementEdit),
                  ),
                  if (!isDefault)
                    PopupMenuItem(
                      value: 'default',
                      child: Text(l10n.tournamentManagementSetAsDefault),
                    ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      l10n.tournamentManagementRemove,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tournamentManagementCourtsCount(courts.length),
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              TextButton.icon(
                onPressed: isBusy ? null : onAddCourt,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.tournamentManagementAddCourt),
              ),
            ],
          ),
          if (courts.isEmpty)
            Text(
              l10n.tournamentManagementNoCourts,
              style: TextStyle(color: colors.textMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final court in courts)
                  InputChip(
                    label: Text(
                      (court['name'] ??
                              court['courtName'] ??
                              l10n.tournamentManagementCourt)
                          .toString(),
                    ),
                    onDeleted: isBusy ? null : () => onRemoveCourt(court),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
