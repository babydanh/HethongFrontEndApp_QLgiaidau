import 'dart:async';
import 'dart:convert';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/footer_button.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_location_picker.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _savedPlacesKey = 'social_nearby_saved_places_v1';

/// Tâm mặc định khi chưa có bất kỳ vị trí nào (TP.HCM).
const _defaultMapCenter = LatLng(10.7769, 106.7009);

class SocialNearbyFilter extends ConsumerWidget {
  const SocialNearbyFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(socialFilterProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: Icon(
            Icons.my_location_rounded,
            size: 18,
            color: AppTheme.primary,
          ),
          label: Text(
            filter.nearbyOnly
                ? 'Gần bạn · ${filter.radiusKm.round()} km'
                : 'Gần bạn',
          ),
          side: BorderSide(color: AppTheme.primary),
          backgroundColor: filter.nearbyOnly
              ? AppTheme.primary.withValues(alpha: 0.12)
              : null,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            builder: (_) => _NearbySheet(initialRadius: filter.radiusKm),
          ),
        ),
      ),
    );
  }
}

enum _Page { filter, manage, add }

class _NearbySheet extends ConsumerStatefulWidget {
  const _NearbySheet({required this.initialRadius});
  final double initialRadius;

  @override
  ConsumerState<_NearbySheet> createState() => _NearbySheetState();
}

class _NearbySheetState extends ConsumerState<_NearbySheet> {
  final _savedSearch = TextEditingController();
  final _label = TextEditingController();
  final _placeSearch = TextEditingController();
  Timer? _debounce;
  _Page _page = _Page.filter;
  List<SocialPlace> _saved = [];
  List<SocialPlace> _suggestions = [];
  SocialPlace? _selected;
  SocialPlace? _candidate;
  late double _radius;
  bool _searching = false;
  bool _searchSaved = false;
  bool _saving = false;
  String? _error;
  bool _isCurrentLocation = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius.clamp(1.0, 50.0).toDouble();
    _loadSaved();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _savedSearch.dispose();
    _label.dispose();
    _placeSearch.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final places = <SocialPlace>[];
    for (final row in prefs.getStringList(_savedPlacesKey) ?? <String>[]) {
      try {
        final value = jsonDecode(row);
        if (value is Map) {
          final place = SocialPlace.fromJson(value);
          if (place.hasPin) places.add(place);
        }
      } catch (_) {
        // Skip a damaged entry.
      }
    }
    if (!mounted) return;
    setState(() {
      _saved = places;
      if (places.isNotEmpty) _selected = places.first;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _savedPlacesKey,
      _saved.map((place) => jsonEncode(place.toJson())).toList(),
    );
  }

  void _searchPlaces(String text) {
    _debounce?.cancel();
    final generation = ++_generation;
    setState(() {
      _candidate = null;
      _error = null;
      _suggestions = [];
      _searching = text.trim().length >= 3;
    });
    if (text.trim().length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final location = ref.read(userLocationProvider);
        final reference = _selected?.hasPin == true ? _selected : null;
        final bias = reference != null
            ? LatLng(reference.latitude!, reference.longitude!)
            : location.hasPosition
            ? LatLng(location.latitude!, location.longitude!)
            : null;
        final results = await Future.wait<List<SocialPlace>>([
          ref
              .read(socialLocationRepositoryProvider)
              .search(text.trim(), bias: bias)
              .catchError((_) => <SocialPlace>[]),
          ref
              .read(regionRepositoryProvider)
              .searchRegions(text.trim())
              .then(
                (regions) => regions
                    .where(
                      (region) =>
                          region.latitude != null && region.longitude != null,
                    )
                    .map(
                      (region) => SocialPlace(
                        name: region.name,
                        formattedAddress: region.displayAddress,
                        latitude: region.latitude,
                        longitude: region.longitude,
                        regionEstimated: true,
                      ),
                    )
                    .toList(),
              )
              .catchError((_) => <SocialPlace>[]),
        ]);
        final places = [...results[0], ...results[1]];
        if (bias != null) {
          const distance = Distance();
          places.sort(
            (a, b) => distance
                .as(LengthUnit.Meter, bias, LatLng(a.latitude!, a.longitude!))
                .compareTo(
                  distance.as(
                    LengthUnit.Meter,
                    bias,
                    LatLng(b.latitude!, b.longitude!),
                  ),
                ),
          );
        }
        if (!mounted || generation != _generation) return;
        setState(() {
          _suggestions = places.where((place) => place.hasPin).toList();
          _searching = false;
        });
      } catch (_) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _searching = false;
          _error = 'Không tìm được địa điểm. Hãy thử lại.';
        });
      }
    });
  }

  /// Tâm bản đồ khởi tạo: ưu tiên địa điểm đang chọn, sau đó tới vị trí đã
  /// biết. Không chặn vào việc chờ GPS vì `_pickOnMap` mở map ngay.
  LatLng _mapCenterFallback() {
    final place = _selected?.hasPin == true ? _selected : _candidate;
    if (place != null && place.hasPin) {
      return LatLng(place.latitude!, place.longitude!);
    }
    final location = ref.read(userLocationProvider);
    if (location.hasPosition) {
      return LatLng(location.latitude!, location.longitude!);
    }
    return _defaultMapCenter;
  }

  Future<void> _pickOnMap() async {
    final previous = ref.read(userLocationProvider);
    // Mở map ngay với tâm sẵn có, GPS chạy song song thay vì chặn trước:
    // chờ `getCurrentPosition` xong rồi mới show sheet khiến người dùng đợi
    // 5–10s mới thấy bản đồ. Vị trí đang chọn được giữ nguyên.
    final center = _mapCenterFallback();
    final notifier = ref.read(userLocationProvider.notifier);
    final gps = switch (previous.status) {
      UserLocationStatus.selected => Future<void>.value(),
      UserLocationStatus.granted => notifier.refreshSilently(),
      _ => notifier.requestWhenInUse(),
    };
    final pin = await SocialLocationPicker.showSheet(
      context,
      initialCenter: center,
    );
    await gps;
    if (previous.hasPosition &&
        previous.status == UserLocationStatus.selected) {
      ref
          .read(userLocationProvider.notifier)
          .useSelectedPosition(
            previous.latitude!,
            previous.longitude!,
            source: previous.referenceSource ?? 'saved',
          );
    }
    if (!mounted || pin == null) return;
    setState(() => _searching = true);
    String resolvedAddress;
    try {
      final place = await ref
          .read(socialLocationRepositoryProvider)
          .reverseLookup(pin);
      resolvedAddress = place.formattedAddress.isNotEmpty
          ? place.formattedAddress
          : '${pin.latitude.toStringAsFixed(6)}, ${pin.longitude.toStringAsFixed(6)}';
    } catch (_) {
      resolvedAddress =
          '${pin.latitude.toStringAsFixed(6)}, ${pin.longitude.toStringAsFixed(6)}';
    }
    if (!mounted) return;
    setState(() {
      _searching = false;
      _candidate = SocialPlace(
        name: 'Vị trí trên bản đồ',
        formattedAddress: resolvedAddress,
        latitude: pin.latitude,
        longitude: pin.longitude,
      );
      _placeSearch.text = _candidate!.formattedAddress;
      _error = null;
    });
  }

  Future<void> _savePlace() async {
    final label = _label.text.trim();
    final place = _candidate;
    if (label.isEmpty || place == null || !place.hasPin) return;
    setState(() => _saving = true);
    final saved = SocialPlace(
      name: label,
      formattedAddress: place.formattedAddress,
      latitude: place.latitude,
      longitude: place.longitude,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final next = [..._saved, saved];
      await prefs.setStringList(
        _savedPlacesKey,
        next.map((item) => jsonEncode(item.toJson())).toList(),
      );
      if (!mounted) return;
      setState(() {
        _saved = next;
        _selected = saved;
        // Địa điểm vừa lưu thay cho "vị trí hiện tại": nếu giữ cờ cũ thì
        // bấm "Xác nhận" sẽ lọc theo tọa độ thiết bị thay vì điểm vừa ghim.
        _isCurrentLocation = false;
        _saving = false;
        _page = _Page.manage;
        _label.clear();
        _placeSearch.clear();
        _candidate = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Không lưu được địa điểm. Hãy thử lại.';
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    await ref.read(userLocationProvider.notifier).useCurrentPosition();
    if (!mounted) return;
    final location = ref.read(userLocationProvider);
    if (!location.hasPosition) {
      setState(
        () => _error = location.message ?? 'Không lấy được vị trí thiết bị.',
      );
      return;
    }
    setState(() {
      _isCurrentLocation = true;
      _selected = null;
      _error = null;
    });
  }

  void _confirm() {
    if (_isCurrentLocation &&
        ref.read(userLocationProvider).hasPosition) {
      _confirmCurrentLocation();
    } else {
      _confirmSavedPlace();
    }
  }

  void _confirmCurrentLocation() {
    final location = ref.read(userLocationProvider);
    if (!location.hasPosition) return;
    ref
        .read(userLocationProvider.notifier)
        .useSelectedPosition(
          location.latitude!,
          location.longitude!,
          source: 'current',
        );
    final filter = ref.read(socialFilterProvider.notifier);
    filter.setRadiusKm(_radius);
    filter.setNearbyOnly(true);
    Navigator.of(context).pop();
  }

  void _confirmSavedPlace() {
    final place = _selected;
    if (place == null || !place.hasPin) return;
    ref
        .read(userLocationProvider.notifier)
        .useSelectedPosition(
          place.latitude!,
          place.longitude!,
          source: 'saved',
        );
    final filter = ref.read(socialFilterProvider.notifier);
    filter.setRadiusKm(_radius);
    filter.setNearbyOnly(true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: FractionallySizedBox(
        heightFactor: keyboard > 0 ? 0.98 : 0.88,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_page),
                  child: switch (_page) {
                    _Page.filter => _filterPage(),
                    _Page.manage => _managePage(),
                    _Page.add => _addPage(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String title, VoidCallback onBack, {bool isClose = false}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(isClose ? Icons.close : Icons.arrow_back),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: isClose ? TextAlign.center : TextAlign.left,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        if (isClose) const SizedBox(width: 48),
      ],
    ),
  );

  Widget _placeTile(SocialPlace place, {bool selectable = false}) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: () => setState(() {
      _selected = place;
      _isCurrentLocation = false;
    }),
      title: Text(
        place.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        place.formattedAddress,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: selectable
          ? Icon(
              identical(_selected, place)
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: AppTheme.primary,
            )
          : IconButton(
              tooltip: 'Xóa địa điểm',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                setState(() {
                  _saved = _saved
                      .where((item) => !identical(item, place))
                      .toList();
                  if (identical(_selected, place)) {
                    _selected = _saved.isEmpty ? null : _saved.first;
                  }
                });
                await _persist();
              },
            ),
    ),
  );

  Widget _filterPage() {
    final colors = context.colors;
    final query = _savedSearch.text.trim().toLowerCase();
    final visible = _saved
        .where(
          (place) => '${place.name} ${place.formattedAddress}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
    final canConfirm = _isCurrentLocation || _selected != null;
    return Column(
      children: [
        _heading('Vị trí', () => Navigator.of(context).pop(), isClose: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // 'Tìm kiếm' title row without background border
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Tìm kiếm',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ở trong ',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        '${_radius.round()}km',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Slider(
                min: 1,
                max: 50,
                divisions: 49,
                value: _radius,
                label: '${_radius.round()} km',
                onChanged: (value) => setState(() => _radius = value),
              ),
              const SizedBox(height: 4),

              // Wrap chips: no check icon when selected, grey bg + no border when !selected
              Wrap(
                spacing: 8,
                children: [
                  _filterChip(
                    label: 'Đã lưu',
                    selected: !_searchSaved,
                    onSelected: (_) => setState(() => _searchSaved = false),
                  ),
                  _filterChip(
                    label: 'Tìm kiếm',
                    selected: _searchSaved,
                    onSelected: (_) => setState(() => _searchSaved = true),
                  ),
                ],
              ),
              if (_searchSaved) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _savedSearch,
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 250), () {
                      if (mounted) setState(() {});
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Tìm địa điểm đã lưu',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_saved.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Text('Chưa lưu địa điểm'),
                  ),
                if (_saved.isNotEmpty && visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Không tìm thấy địa điểm đã lưu'),
                  ),
                ...visible.map((place) => _placeTile(place, selectable: true)),
              ],
              if (!_searchSaved) ...[
                const SizedBox(height: 16),
                // 'Vị trí hiện tại' option placed in 'Đã lưu' section
                InkWell(
                  onTap: _useCurrentLocation,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: _isCurrentLocation
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : colors.chipBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: _isCurrentLocation
                          ? Border.all(color: AppTheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          color: _isCurrentLocation ? AppTheme.primary : colors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Vị trí hiện tại',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _isCurrentLocation ? FontWeight.w700 : FontWeight.w600,
                            color: _isCurrentLocation ? AppTheme.primary : colors.textPrimary,
                          ),
                        ),
                        if (_isCurrentLocation) ...[
                          const Spacer(),
                          Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_saved.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Text('Chưa lưu địa điểm'),
                  ),
                if (_saved.isNotEmpty && visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Không tìm thấy địa điểm đã lưu'),
                  ),
                ...visible.map((place) => _placeTile(place, selectable: true)),
                TextButton(
                  onPressed: () => setState(() => _page = _Page.manage),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Quản lý địa điểm'),
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: colors.error),
                  ),
                ),
            ],
          ),
        ),
        if (ref.watch(socialFilterProvider).nearbyOnly)
          TextButton(
            onPressed: () {
              ref.read(socialFilterProvider.notifier).setNearbyOnly(false);
              Navigator.of(context).pop();
            },
            child: const Text('Tắt Gần bạn'),
          ),
        FooterButton(
          label: 'Xác nhận',
          onPressed: canConfirm ? _confirm : null,
        ),
      ],
    );
  }

  Widget _managePage() => Column(
    children: [
      _heading('Địa điểm', () => setState(() => _page = _Page.filter)),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const Text(
              'Vị trí của bạn được giữ kín. Chúng chỉ được sử dụng để hiển thị các hoạt động và câu lạc bộ gần đó.',
            ),
            const SizedBox(height: 24),
            ..._saved.map(_placeTile),
            TextButton.icon(
              onPressed: () => setState(() {
                _page = _Page.add;
                _error = null;
              }),
              icon: const Icon(Icons.add),
              label: const Text('Thêm vị trí'),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _addPage() => Column(
    children: [
      _heading('Thêm vị trí', () => setState(() => _page = _Page.manage)),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const Text(
              'Nhập tên khu phố hoặc thành phố bạn muốn đến, chúng tôi sẽ hiển thị các hoạt động gần khu vực đó.',
            ),
            const SizedBox(height: 28),
            const Text('Tên địa điểm'),
            const SizedBox(height: 8),
            TextField(
              controller: _label,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Nhà, Cơ quan, ...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 22),
            const Text('Vị trí'),
            const SizedBox(height: 8),
            TextField(
              controller: _placeSearch,
              onChanged: _searchPlaces,
              decoration: InputDecoration(
                hintText: 'Nhập vị trí',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Chọn trên bản đồ từ vị trí hiện tại',
                  onPressed: _pickOnMap,
                  icon: const Icon(Icons.map_outlined),
                ),
              ),
            ),
            if (_searching) const LinearProgressIndicator(),
            ..._suggestions.map(
              (place) => ListTile(
                title: Text(place.name),
                subtitle: Text(place.formattedAddress),
                onTap: () => setState(() {
                  _candidate = place;
                  _placeSearch.text = place.formattedAddress;
                  _suggestions = [];
                  _generation++;
                }),
              ),
            ),
            if (!_searching &&
                _candidate == null &&
                _placeSearch.text.trim().length >= 3 &&
                _suggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Không tìm thấy vị trí có tọa độ. Bạn có thể chọn trên bản đồ.',
                ),
              ),
            if (_candidate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Đã chọn: ${_candidate!.formattedAddress}'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      FooterButton(
        label: 'Lưu',
        isLoading: _saving,
        onPressed: _label.text.trim().isEmpty || _candidate == null
            ? null
            : _savePlace,
      ),
    ],
  );

  Widget _filterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final colors = context.colors;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppTheme.primaryLight,
      backgroundColor: colors.chipBackground,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.black87 : colors.textPrimary,
      ),
      onSelected: onSelected,
    );
  }
}
