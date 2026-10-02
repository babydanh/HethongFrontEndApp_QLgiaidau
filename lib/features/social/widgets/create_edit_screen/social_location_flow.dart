import 'dart:async';
import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/social_map_tile_provider.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_location_picker.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

enum _LocationStep { search, input, preview }

class SocialLocationFlow extends ConsumerStatefulWidget {
  const SocialLocationFlow({super.key, this.initialPlace, this.initialCenter});

  final SocialPlace? initialPlace;
  final LatLng? initialCenter;

  static Future<SocialPlace?> show(
    BuildContext context, {
    SocialPlace? initialPlace,
    LatLng? initialCenter,
  }) {
    return showModalBottomSheet<SocialPlace>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SocialLocationFlow(
        initialPlace: initialPlace,
        initialCenter: initialCenter,
      ),
    );
  }

  @override
  ConsumerState<SocialLocationFlow> createState() => _SocialLocationFlowState();
}

class _SocialLocationFlowState extends ConsumerState<SocialLocationFlow> {
  final _searchController = TextEditingController();
  final _inputController = TextEditingController();
  Timer? _searchTimer;
  int _searchGeneration = 0;
  _LocationStep _step = _LocationStep.search;
  List<SocialPlace> _results = const [];
  bool _searching = false;
  bool _searchError = false;
  bool _resolving = false;
  String? _inputError;
  SocialPlace? _candidate;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _searchChanged(String query) {
    _searchTimer?.cancel();
    final generation = ++_searchGeneration;
    setState(() {
      _results = const [];
      _searchError = false;
      _searching = query.trim().length >= 3;
    });
    if (query.trim().length < 3) return;
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_search(query.trim(), generation));
    });
  }

  Future<void> _search(String query, int generation) async {
    setState(() => _searching = true);
    try {
      final results = await ref
          .read(socialLocationRepositoryProvider)
          .search(query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = results.where((place) => place.canApply).toList();
        _searchError = false;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchError = true;
        _searching = false;
      });
    }
  }

  void _retrySearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) unawaited(_search(query, ++_searchGeneration));
  }

  String _errorMessage(Object error, AppLocalizations l10n) {
    if (error is LocationNotFound) return l10n.socialPlaceNotFound;
    if (error is UnresolvableLocation) return l10n.socialPlaceUnresolvable;
    return l10n.socialPlaceNetworkError;
  }

  Future<void> _resolveInput() async {
    final input = _inputController.text.trim();
    if (input.isEmpty || _resolving) return;
    setState(() {
      _candidate = SocialPlace(name: input, formattedAddress: input);
      _inputError =
          'Đã nhập nhãn sân. Hãy ghim và xác nhận vị trí trên bản đồ.';
    });
    await _pickOnMap();
  }

  Future<void> _pickOnMap() async {
    final previous = widget.initialPlace;
    final center = previous?.hasPin == true
        ? LatLng(previous!.latitude!, previous.longitude!)
        : widget.initialCenter ?? const LatLng(10.7769, 106.7009);
    final pin = await SocialLocationPicker.show(
      context,
      initialCenter: center,
      initialPin: previous?.hasPin == true ? center : null,
    );
    if (!mounted || pin == null) return;
    final entered = _inputController.text.trim();
    if (entered.isEmpty) {
      setState(
        () =>
            _inputError = 'Nhập tên hoặc địa chỉ sân trước khi xác nhận ghim.',
      );
      return;
    }
    Navigator.of(context).pop(
      SocialPlace(
        name: entered,
        formattedAddress: entered,
        latitude: pin.latitude,
        longitude: pin.longitude,
      ),
    );
  }

  void _goBack() {
    if (_step == _LocationStep.preview) {
      setState(() {
        _candidate = null;
        _step = _LocationStep.input;
      });
    } else if (_step == _LocationStep.input) {
      setState(() => _step = _LocationStep.search);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        MediaQuery.paddingOf(context).top -
        32;
    final height = math.max(220.0, math.min(600.0, availableHeight));
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.socialPlaceBack,
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(switch (_step) {
                      _LocationStep.search => l10n.socialPlaceSelect,
                      _LocationStep.input => l10n.socialPlaceInputTitle,
                      _LocationStep.preview => l10n.socialPlacePreviewTitle,
                    }, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (_step) {
                _LocationStep.search => _buildSearch(l10n),
                _LocationStep.input => _buildInput(l10n),
                _LocationStep.preview => _buildPreview(l10n),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(AppLocalizations l10n) {
    final pinned = _results.where((place) => place.hasPin).toList();
    final areas = _results.where((place) => !place.hasPin).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: _searchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.socialPlaceSearchHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _searching
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(l10n.socialPlaceSearchLoading),
                    ],
                  ),
                )
              : _searchError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.socialPlaceSearchError),
                      TextButton(
                        onPressed: _retrySearch,
                        child: Text(l10n.socialPlaceRetry),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.trim().isEmpty
                        ? l10n.socialPlaceSearchIdle
                        : l10n.socialPlaceSearchEmpty,
                  ),
                )
              : ListView(
                  children: [
                    if (pinned.isNotEmpty) ...[
                      _sectionHeader(l10n.socialPlaceSuggestedSection),
                      for (final place in pinned) _resultTile(place, true),
                    ],
                    if (areas.isNotEmpty) ...[
                      _sectionHeader(l10n.socialPlaceAreaSection),
                      for (final place in areas) _resultTile(place, false),
                    ],
                  ],
                ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => setState(() => _step = _LocationStep.input),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(l10n.socialPlaceAdd),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _resultTile(SocialPlace place, bool hasPin) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Icon(
        hasPin ? Icons.place_outlined : Icons.location_city_outlined,
      ),
      title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        hasPin
            ? place.formattedAddress
            : '${place.formattedAddress} • ${l10n.socialPlaceNoPin}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () async {
        if (!place.hasPin && place.venueId == null) {
          _inputController.text = place.formattedAddress;
          setState(() => _step = _LocationStep.input);
          return;
        }
        Navigator.of(context).pop(place);
      },
    );
  }

  Widget _buildInput(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TextField(
          controller: _inputController,
          maxLines: 3,
          minLines: 1,
          keyboardType: TextInputType.streetAddress,
          onChanged: (_) => setState(() => _inputError = null),
          decoration: InputDecoration(
            labelText: l10n.socialPlaceInputHint,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_inputError != null) ...[
          const SizedBox(height: 8),
          Text(
            _inputError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _resolving ? null : _pickOnMap,
          icon: const Icon(Icons.map_outlined),
          label: Text(l10n.socialPlaceMap),
        ),
        const SizedBox(height: 18),
        if (_resolving) Center(child: Text(l10n.socialPlaceResolving)),
        TextButton(
          onPressed: _inputController.text.trim().isEmpty || _resolving
              ? null
              : _resolveInput,
          child: Text(l10n.socialPlaceNext),
        ),
      ],
    );
  }

  Widget _buildPreview(AppLocalizations l10n) {
    final place = _candidate!;
    final pin = LatLng(place.latitude!, place.longitude!);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(initialCenter: pin, initialZoom: 16),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: AppConstants.osmUserAgentPackageName,
                  tileProvider: SocialMapTileProvider(),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pin,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.redAccent,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () =>
              launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
          child: const Text(
            '© OpenStreetMap contributors',
            style: TextStyle(
              fontSize: 11,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(place.name, style: Theme.of(context).textTheme.titleMedium),
        Text(place.formattedAddress),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _goBack,
                child: Text(l10n.socialPlaceBack),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(place),
                child: Text(l10n.socialPlaceConfirm),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
