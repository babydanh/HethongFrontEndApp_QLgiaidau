import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/dialogs/popup_dialog.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/venue_text_hint.dart';
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
    this.editFirstVenue = false,
  });
  final String tournamentId;

  /// Open the editor of the default (else first) venue once the list loads.
  final bool editFirstVenue;

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
    if (widget.editFirstVenue) _editFirstVenueWhenLoaded();
  }

  void _editFirstVenueWhenLoaded() {
    // A load error is already shown by the list's FutureBuilder.
    _venuesFuture.then((venues) {
      if (!mounted || venues.isEmpty) return;
      final venue = venues.firstWhere(
        (venue) => venue['isDefault'] == true,
        orElse: () => venues.first,
      );
      _editVenue(venue);
    }, onError: (_) {});
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
  }) => showPopupDialog<_VenueValues>(
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
    final value = await showPopupDialog<String>(
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
  // Same default as the Web and the Backend, so the field is never blank.
  late final _prefix = TextEditingController(text: 'Sân');
  bool _default = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _count.dispose();
    _prefix.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty && _address.text.trim().isNotEmpty;

  void _submit() {
    final parsedCount = int.tryParse(_count.text.trim());
    Navigator.pop(
      context,
      _VenueValues(
        name: _name.text,
        address: _address.text,
        isDefault: _default,
        initialCourtCount:
            widget.showCourtFields && parsedCount != null && parsedCount > 0
            ? parsedCount
            : null,
        courtPrefix: _prefix.text,
      ),
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  /// Web-like field: the label sits above the box, a red star marks required.
  Widget _field({
    required Key key,
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool autofocus = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final colors = LavishColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: LavishColors.bad),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: key,
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: _border(colors.chipLine),
            enabledBorder: _border(colors.chipLine),
            focusedBorder: _border(LavishColors.accent, 1.5),
          ),
        ),
      ],
    );
  }

  Widget _header(LavishColors colors, AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.soft(LavishTone.accent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: LavishColors.accent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('venue-dialog-close'),
          tooltip: l10n.tournamentManagementCancel,
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: colors.muted),
        ),
      ],
    ),
  );

  /// Courts block like the Web: count (+ prefix) and the default-venue tick in
  /// one soft card. Only when creating a venue.
  Widget _courtCard(LavishColors colors, AppLocalizations l10n) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
    decoration: BoxDecoration(
      color: colors.rowLine,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: colors.line),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                key: const ValueKey('venue-dialog-count'),
                label: l10n.tournamentManagementInitialCourtCount,
                controller: _count,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                key: const ValueKey('venue-dialog-prefix'),
                label: l10n.tournamentManagementCourtPrefix,
                controller: _prefix,
              ),
            ),
          ],
        ),
        Material(
          type: MaterialType.transparency,
          child: CheckboxListTile(
            key: const ValueKey('venue-dialog-default'),
            value: _default,
            onChanged: (value) => setState(() => _default = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              l10n.tournamentManagementSetAsDefault,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _footer(LavishColors colors, AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.text,
              side: BorderSide(color: colors.chipLine),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.tournamentManagementCancel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            key: const ValueKey('venue-dialog-submit'),
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: LavishColors.accent,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              widget.showCourtFields ? Icons.add_rounded : Icons.check_rounded,
              size: 18,
            ),
            label: Text(
              widget.showCourtFields
                  ? l10n.tournamentManagementAddVenue
                  : l10n.tournamentManagementSave,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LavishColors.of(context);
    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        // Header and footer stay put; only the fields scroll, so the buttons
        // never hide behind the keyboard.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(colors, l10n),
            Divider(height: 1, color: colors.line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(
                      key: const ValueKey('venue-dialog-name'),
                      label: l10n.tournamentManagementVenueName,
                      controller: _name,
                      required: true,
                      autofocus: true,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      key: const ValueKey('venue-dialog-address'),
                      label: l10n.tournamentManagementVenueAddress,
                      controller: _address,
                      required: true,
                      maxLines: 2,
                    ),
                    // The fields call setState on every edit, so this rebuilds.
                    VenueTextHintBar(
                      name: _name.text,
                      address: _address.text,
                      onApply: (name, address) => setState(() {
                        _name.text = name;
                        _address.text = address;
                      }),
                    ),
                    if (widget.showCourtFields) ...[
                      const SizedBox(height: 14),
                      _courtCard(colors, l10n),
                    ],
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colors.line),
            _footer(colors, l10n),
          ],
        ),
      ),
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
