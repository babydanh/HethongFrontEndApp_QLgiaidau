import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BoneListLoading();
        }
        if (snapshot.hasError) {
          return TournamentManagementError(
            error: snapshot.error,
            onRetry: _reload,
          );
        }
        final venues = snapshot.data ?? const <Map<String, dynamic>>[];
        return LavishSurface(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (_mutationError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Text(
                    l10n.tournamentManagementActionError,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LavishColors.bad,
                    ),
                  ),
                ),
              if (venues.isEmpty)
                TournamentManagementEmpty(
                  title: l10n.tournamentManagementVenuesEmpty,
                  subtitle: l10n.tournamentManagementVenuesEmptyDescription,
                  icon: Icons.place_outlined,
                )
              else
                for (final venue in venues)
                  _VenueCard(
                    tournamentId: widget.tournamentId,
                    venue: venue,
                    isBusy: _isBusy,
                    onEdit: () => _editVenue(venue),
                    onSetDefault: () => _setDefault(venue),
                    onRemove: () => _removeVenue(venue),
                    onAddCourt: () => _addCourt(venue),
                    onRemoveCourt: (court) => _removeCourt(venue, court),
                  ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: LavishButton(
                  buttonKey: const ValueKey('venue-add'),
                  kind: LavishButtonKind.outline,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                  label: l10n.tournamentManagementAddVenue,
                  onPressed: _isBusy ? null : _createVenue,
                ),
              ),
            ],
          ),
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

/// One venue: the design's `.li` header row (place box, name, address,
/// "Mặc định" pill, menu) followed by its "N SÂN" group of one-line courts.
class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.tournamentId,
    required this.venue,
    required this.isBusy,
    required this.onEdit,
    required this.onSetDefault,
    required this.onRemove,
    required this.onAddCourt,
    required this.onRemoveCourt,
  });
  final String tournamentId;
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
    final colors = LavishColors.of(context);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishRow(
          leading: const LavishIconBox(child: Icon(Icons.place_outlined)),
          title: tournamentManagementRecordName(venue),
          subtitle: address.isEmpty ? null : address,
          trailing: [
            if (isDefault) LavishPill(l10n.tournamentManagementDefaultVenue),
            PopupMenuButton<String>(
              enabled: !isBusy,
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.faint),
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
                    style: const TextStyle(color: LavishColors.bad),
                  ),
                ),
              ],
            ),
          ],
        ),
        LavishGroupHeader(
          l10n.tournamentManagementCourtsCount(courts.length),
          trailing: InkWell(
            key: const ValueKey('venue-add-court'),
            onTap: isBusy ? null : onAddCourt,
            child: Text(
              '＋ ${l10n.tournamentManagementAddCourt}'.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.66,
                color: LavishColors.accent,
              ),
            ),
          ),
        ),
        if (courts.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Text(
              l10n.tournamentManagementNoCourts,
              style: TextStyle(fontSize: 13, color: colors.faint),
            ),
          )
        else
          for (final court in courts)
            _VenueCourtRow(
              tournamentId: tournamentId,
              court: court,
              fallbackName: l10n.tournamentManagementCourt,
              isBusy: isBusy,
              onRemove: () => onRemoveCourt(court),
            ),
      ],
    );
  }
}

/// One court on one line: name, camera status, edit-camera button and a menu
/// holding the destructive action. The camera URL itself never shows here; it
/// only lives (masked) in [CourtCameraSheet].
class _VenueCourtRow extends ConsumerWidget {
  const _VenueCourtRow({
    required this.tournamentId,
    required this.court,
    required this.fallbackName,
    required this.isBusy,
    required this.onRemove,
  });

  final String tournamentId;
  final Map<String, dynamic> court;
  final String fallbackName;
  final bool isBusy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LavishColors.of(context);
    final name =
        (court['name'] ?? court['courtName'] ?? fallbackName).toString();
    final courtId = (court['id'] ?? court['courtId'] ?? '').toString();
    final attached =
        cameraForCourt(
          ref.watch(tournamentCamerasProvider(tournamentId)).asData?.value ??
              const [],
          courtId,
        )?.hasPlaybackUrl ??
        false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rowLine)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                // Icon plus wording, never colour alone.
                Row(
                  children: [
                    Icon(
                      attached
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_outlined,
                      size: 14,
                      color: attached ? LavishColors.ok : colors.faint,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        attached
                            ? l10n.tournamentManagementCourtCameraAttached
                            : l10n.tournamentManagementCourtCameraNotAttached,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: attached ? colors.muted : colors.faint,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Without an id the camera routes cannot address this court.
          if (courtId.isNotEmpty)
            IconButton(
              key: ValueKey('court-edit-$courtId'),
              tooltip: l10n.tournamentManagementCourtCameraEdit,
              visualDensity: VisualDensity.compact,
              onPressed: isBusy
                  ? null
                  : () => showCourtCameraSheet(
                      context,
                      tournamentId: tournamentId,
                      courtId: courtId,
                      courtName: name,
                    ),
              icon: Icon(Icons.edit_outlined, size: 18, color: colors.faint),
            ),
          PopupMenuButton<String>(
            key: ValueKey('court-menu-$courtId'),
            tooltip: l10n.tournamentManagementCourtActions,
            enabled: !isBusy,
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.faint),
            onSelected: (_) => onRemove(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'remove',
                child: Text(
                  l10n.tournamentManagementRemove,
                  style: const TextStyle(color: LavishColors.bad),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
