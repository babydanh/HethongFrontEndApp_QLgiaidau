import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/footer_button.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_flow.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_inline_map.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

const _defaultCenter = LatLng(10.7769, 106.7009);

/// The single popup for choosing a session location: a name field with venue
/// suggestions, a map with a draft pin (inside this sheet, no second popup) and
/// province/ward boxes that follow the confirmed pin.
///
/// Pops a [SocialPlace]: the venue picked from the suggestions right away, or
/// the typed name + confirmed pin / [SocialPlace.deferred] on "Xác nhận".
class SocialLocationSheet extends ConsumerStatefulWidget {
  const SocialLocationSheet({super.key, this.initialPlace, this.categoryId});

  final SocialPlace? initialPlace;

  /// `categories.id` of the chosen sport; suggestions are limited to it.
  final String? categoryId;

  static Future<SocialPlace?> show(
    BuildContext context, {
    SocialPlace? initialPlace,
    String? categoryId,
  }) {
    return showModalBottomSheet<SocialPlace>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: SocialLocationSheet(
            initialPlace: initialPlace,
            categoryId: categoryId,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<SocialLocationSheet> createState() =>
      _SocialLocationSheetState();
}

class _SocialLocationSheetState extends ConsumerState<SocialLocationSheet> {
  final _nameController = TextEditingController();
  final _provinceController = TextEditingController();
  final _wardController = TextEditingController();
  final _mapController = MapController();
  // A venue's map never moves programmatically, so it keeps its own controller.
  final _venueMapController = MapController();
  Timer? _searchTimer;
  int _searchGeneration = 0;
  int _pinGeneration = 0;
  int _wardsGeneration = 0;

  List<SocialPlace> _suggestions = const [];
  bool _searching = false;
  bool _searchFailed = false;
  SocialPlace? _venue;
  bool _deferred = false;

  late LatLng _pin;
  bool _pinConfirmed = false;
  bool _locating = false;
  bool _resolving = false;
  SocialPlace? _resolved;

  List<Region> _provinces = const [];
  List<Region> _wards = const [];
  late final Future<void> _provincesLoaded;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPlace;
    _deferred = initial?.isDeferred == true;
    final hasPin = !_deferred && initial?.hasPin == true;
    _pin = hasPin
        ? LatLng(initial!.latitude!, initial.longitude!)
        : _draftPin();
    // An existing place is already pinned: keep its address when re-confirmed.
    _pinConfirmed = hasPin;
    if (hasPin) _resolved = initial;
    if (initial != null && !_deferred && !initial.nameFromRegion) {
      _nameController.text = initial.name;
    }
    if (initial?.venueId != null && !_deferred) _venue = initial;
    _provincesLoaded = _loadProvinces();
    final venue = _venue;
    if (venue != null) unawaited(_fillRegion(venue, _pinGeneration));
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _nameController.dispose();
    _provinceController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  /// Draft pin: the user's GPS fix when already known, else central HCMC.
  LatLng _draftPin() {
    final location = ref.read(userLocationProvider);
    return location.hasPosition
        ? LatLng(location.latitude!, location.longitude!)
        : _defaultCenter;
  }

  SocialPlace? _buildPlace() {
    if (_deferred) return const SocialPlace.deferred();
    if (_venue != null) return _venue;
    final name = _nameController.text.trim();
    if (!_pinConfirmed || name.isEmpty) return null;
    final resolved = _resolved;
    if (resolved != null) {
      try {
        return socialPlaceFromResolvedPin(name, _pin, resolved);
      } on UnresolvableLocation {
        // Fall through to the name-only address below.
      }
    }
    return SocialPlace(
      name: name,
      formattedAddress: name,
      latitude: _pin.latitude,
      longitude: _pin.longitude,
    );
  }

  /// Valid = a venue, "decide later", or a name with a confirmed pin; never
  /// while the pin's address is still being looked up.
  bool get _canConfirm => !_resolving && _buildPlace() != null;

  void _confirm() {
    final place = _buildPlace();
    if (place != null) Navigator.of(context).pop(place);
  }

  // ─── Suggestions ───

  void _onNameChanged(String value) {
    _searchTimer?.cancel();
    final generation = ++_searchGeneration;
    final query = value.trim();
    setState(() {
      if (_venue != null) {
        // Editing a chosen venue turns it into a new place at the same pin.
        _venue = null;
        _pinConfirmed = false;
      }
      _suggestions = const [];
      _searchFailed = false;
      _searching = query.length >= 3;
    });
    if (query.length < 3) return;
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_search(query, generation));
    });
  }

  Future<void> _search(String query, int generation) async {
    try {
      final results = await ref
          .read(socialLocationRepositoryProvider)
          .search(query, categoryId: widget.categoryId);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _suggestions = results
            .where((p) => p.canApply && (p.hasPin || p.venueId != null))
            .take(5)
            .toList();
        _searching = false;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchFailed = true;
        _searching = false;
      });
    }
  }

  void _retrySearch() {
    final query = _nameController.text.trim();
    if (query.length < 3) return;
    setState(() {
      _searchFailed = false;
      _searching = true;
    });
    unawaited(_search(query, ++_searchGeneration));
  }

  /// A venue that already exists needs no pin: its map is fixed on the venue
  /// and confirming is enabled right away.
  void _pickVenue(SocialPlace place) {
    _searchTimer?.cancel();
    _searchGeneration++;
    final generation = ++_pinGeneration;
    _nameController.text = place.name;
    setState(() {
      _venue = place;
      _suggestions = const [];
      _searching = false;
      _resolving = false;
      if (place.hasPin) _pin = LatLng(place.latitude!, place.longitude!);
    });
    unawaited(_fillRegion(place, generation));
  }

  /// Back to entering a new place, with the draft pin at GPS / central HCMC.
  void _clearVenue() {
    _pinGeneration++;
    _nameController.clear();
    _resolved = null;
    _pin = _draftPin();
    _clearRegion();
    _onNameChanged('');
  }

  void _setDeferred(bool value) {
    _searchTimer?.cancel();
    _searchGeneration++;
    setState(() {
      _deferred = value;
      _suggestions = const [];
      _searching = false;
    });
  }

  // ─── Pin ───

  void _dragPin(LatLng point) => setState(() => _pin = point);

  /// A tap, a finished drag or "my location" confirms the pin.
  void _confirmPin(LatLng point) {
    setState(() {
      _pin = point;
      _pinConfirmed = true;
      _resolved = null;
      _resolving = true;
    });
    unawaited(_lookup(point));
  }

  Future<void> _lookup(LatLng point) async {
    final generation = ++_pinGeneration;
    SocialPlace? resolved;
    try {
      resolved = await ref
          .read(socialLocationRepositoryProvider)
          .reverseLookup(point);
    } catch (_) {
      // Outside every ward polygon or offline: the boxes stay empty and the
      // confirmed pin is still enough to create the session.
    }
    if (!mounted || generation != _pinGeneration) return;
    _resolved = resolved;
    if (resolved == null) {
      _clearRegion();
    } else {
      await _fillRegion(resolved, generation);
    }
    if (mounted && generation == _pinGeneration) {
      setState(() => _resolving = false);
    }
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    await ref.read(userLocationProvider.notifier).useCurrentPosition();
    if (!mounted) return;
    final location = ref.read(userLocationProvider);
    setState(() => _locating = false);
    if (!location.hasPosition) {
      _showLocationError();
      return;
    }
    final point = LatLng(location.latitude!, location.longitude!);
    _mapController.move(point, 16);
    _confirmPin(point);
  }

  void _showLocationError() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(l10n.socialLocationInlineMyLocationError)),
    );
  }

  // ─── Province / ward ───

  Future<void> _loadProvinces() async {
    List<Region> provinces = const [];
    try {
      provinces = await ref.read(regionRepositoryProvider).getProvinces();
    } catch (_) {
      // Empty list: the box simply has nothing to pick.
    }
    if (mounted) setState(() => _provinces = provinces);
  }

  Future<List<Region>> _fetchWards(String provinceCode) async {
    try {
      return await ref
          .read(regionRepositoryProvider)
          .getWardsByProvince(provinceCode);
    } catch (_) {
      return const [];
    }
  }

  void _clearRegion() {
    _wardsGeneration++;
    setState(() {
      _wards = const [];
      _provinceController.clear();
      _wardController.clear();
    });
  }

  /// The pin is the truth: overwrite whatever was picked by hand.
  Future<void> _fillRegion(SocialPlace resolved, int generation) async {
    await _provincesLoaded;
    if (!mounted || generation != _pinGeneration) return;
    final province = _provinces
        .where((r) => r.code == resolved.provinceCode)
        .firstOrNull;
    if (province == null) {
      if (mounted && generation == _pinGeneration) _clearRegion();
      return;
    }
    final wardsGeneration = ++_wardsGeneration;
    final wards = await _fetchWards(province.code);
    if (!mounted || wardsGeneration != _wardsGeneration) return;
    final ward = wards.where((r) => r.code == resolved.wardCode).firstOrNull;
    setState(() {
      _wards = wards;
      _provinceController.text = province.name;
      _wardController.text = ward?.name ?? '';
    });
  }

  void _onProvinceSelected(Region? province) {
    final generation = ++_wardsGeneration;
    setState(() {
      _wards = const [];
      _wardController.clear();
    });
    if (province == null) return;
    unawaited(
      _fetchWards(province.code).then((wards) {
        if (mounted && generation == _wardsGeneration) {
          setState(() => _wards = wards);
        }
      }),
    );
  }

  /// Picking a ward only moves the map; the pin it drags along stays a draft.
  void _onWardSelected(Region? ward) {
    final lat = ward?.latitude;
    final lng = ward?.longitude;
    if (lat == null || lng == null) return;
    final center = LatLng(lat, lng);
    _pinGeneration++;
    _mapController.move(center, 15);
    setState(() {
      _pin = center;
      _pinConfirmed = false;
      _resolved = null;
      _resolving = false;
    });
  }

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.socialPlaceSelect,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _buildPanel(l10n),
          ),
        ),
        FooterButton(
          label: l10n.socialPlaceConfirm,
          onPressed: _canConfirm ? _confirm : null,
        ),
      ],
    );
  }

  Widget _buildPanel(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_deferred) ...[
          _buildNameField(l10n),
          _buildSuggestions(l10n),
          if (_venue != null)
            ..._buildVenueArea(_venue!, l10n)
          else
            ..._buildPinArea(l10n),
        ],
        _buildDeferredToggle(l10n),
      ],
    );
  }

  Widget _buildDeferredToggle(AppLocalizations l10n) {
    return InkWell(
      key: const ValueKey('social-inline-deferred'),
      onTap: () => _setDeferred(!_deferred),
      child: Row(
        children: [
          Checkbox(
            value: _deferred,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) => _setDeferred(value ?? false),
          ),
          Flexible(
            child: Text(
              l10n.socialPlaceDecideLater,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return TextField(
      key: const ValueKey('social-inline-name'),
      controller: _nameController,
      inputFormatters: [LengthLimitingTextInputFormatter(255)],
      onChanged: _onNameChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        labelText: l10n.socialLocationInlineNameLabel,
        hintText: l10n.socialPlaceInputHint,
        suffixIcon: _venue == null
            ? null
            : IconButton(
                tooltip: l10n.socialLocationPinClear,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: _clearVenue,
              ),
      ),
    );
  }

  Widget _buildSuggestions(AppLocalizations l10n) {
    if (_searching) return const LinearProgressIndicator(minHeight: 2);
    if (_searchFailed) {
      return Row(
        children: [
          Expanded(child: Text(l10n.socialPlaceSearchError)),
          TextButton(
            onPressed: _retrySearch,
            child: Text(l10n.socialPlaceRetry),
          ),
        ],
      );
    }
    return Column(
      children: [
        for (final place in _suggestions)
          ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined),
            title: Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              place.formattedAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _pickVenue(place),
          ),
      ],
    );
  }

  /// Venue picked from the directory: read-only map on its pin and its region.
  List<Widget> _buildVenueArea(SocialPlace venue, AppLocalizations l10n) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          venue.formattedAddress,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      if (venue.hasPin) ...[
        const SizedBox(height: 8),
        SocialLocationInlineMap(
          key: ValueKey('venue-map-${venue.venueId}'),
          controller: _venueMapController,
          pin: LatLng(venue.latitude!, venue.longitude!),
          zoom: 16,
        ),
      ],
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n.socialLocationInlineVenueFromDirectory,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ),
      if (venue.provinceCode != null) ...[
        const SizedBox(height: 8),
        _buildRegionRow(l10n, enabled: false),
      ],
    ];
  }

  List<Widget> _buildPinArea(AppLocalizations l10n) {
    return [
      const SizedBox(height: 8),
      SocialLocationInlineMap(
        controller: _mapController,
        pin: _pin,
        locating: _locating,
        onPinDragged: _dragPin,
        onPinPlaced: _confirmPin,
        onMyLocation: _useMyLocation,
      ),
      if (!_pinConfirmed) _buildPinNotice(l10n),
      const SizedBox(height: 8),
      _buildRegionRow(l10n),
    ];
  }

  Widget _buildRegionRow(AppLocalizations l10n, {bool enabled = true}) {
    return Row(
      children: [
        Expanded(
          child: _regionMenu(
            key: 'social-inline-province',
            label: l10n.socialLocationInlineProvinceLabel,
            controller: _provinceController,
            items: _provinces,
            onSelected: _onProvinceSelected,
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _regionMenu(
            key: 'social-inline-ward',
            label: l10n.socialLocationInlineWardLabel,
            controller: _wardController,
            items: _wards,
            onSelected: _onWardSelected,
            enabled: enabled,
          ),
        ),
      ],
    );
  }

  /// Small orange caption under the map while the pin is only a draft.
  Widget _buildPinNotice(AppLocalizations l10n) {
    final color = Colors.orange.shade800;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.pin_drop_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.socialLocationInlinePinRequired,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _regionMenu({
    required String key,
    required String label,
    required TextEditingController controller,
    required List<Region> items,
    required ValueChanged<Region?> onSelected,
    bool enabled = true,
  }) {
    return DropdownMenu<Region>(
      key: ValueKey(key),
      enabled: enabled,
      controller: controller,
      label: Text(label, style: const TextStyle(fontSize: 13)),
      textStyle: const TextStyle(fontSize: 13),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(),
      ),
      expandedInsets: EdgeInsets.zero,
      menuHeight: 240,
      enableFilter: true,
      requestFocusOnTap: true,
      filterCallback: _filterRegions,
      dropdownMenuEntries: [
        for (final region in items)
          DropdownMenuEntry(value: region, label: region.name),
      ],
      onSelected: onSelected,
    );
  }

  /// Accent-insensitive "contains" so "ho chi minh" finds "Hồ Chí Minh".
  List<DropdownMenuEntry<Region>> _filterRegions(
    List<DropdownMenuEntry<Region>> entries,
    String filter,
  ) {
    final query = VietnamAddressParser.removeVietnameseTones(filter);
    return entries
        .where(
          (e) => VietnamAddressParser.removeVietnameseTones(
            e.label,
          ).contains(query),
        )
        .toList();
  }
}
