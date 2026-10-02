import 'dart:async';
import 'dart:convert';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_location_picker.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _savedPlacesKey = 'social_nearby_saved_places_v1';

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

  Future<void> _pickOnMap() async {
    final previous = ref.read(userLocationProvider);
    await ref.read(userLocationProvider.notifier).useCurrentPosition();
    if (!mounted) return;
    final current = ref.read(userLocationProvider);
    if (!current.hasPosition) {
      if (previous.hasPosition) {
        ref
            .read(userLocationProvider.notifier)
            .useSelectedPosition(
              previous.latitude!,
              previous.longitude!,
              source: previous.referenceSource ?? 'saved',
            );
      }
      setState(
        () => _error = current.message ?? 'Không lấy được vị trí thiết bị.',
      );
      return;
    }
    final pin = await SocialLocationPicker.showSheet(
      context,
      initialCenter: LatLng(current.latitude!, current.longitude!),
    );
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
    setState(() {
      _candidate = SocialPlace(
        name: 'Vị trí trên bản đồ',
        formattedAddress:
            '${pin.latitude.toStringAsFixed(6)}, ${pin.longitude.toStringAsFixed(6)}',
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

  void _confirm() {
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

  Widget _heading(String title, VoidCallback onBack) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    child: Row(
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget _placeTile(SocialPlace place, {bool selectable = false}) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: () => setState(() => _selected = place),
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
    final query = _savedSearch.text.trim().toLowerCase();
    final visible = _saved
        .where(
          (place) => '${place.name} ${place.formattedAddress}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
    return Column(
      children: [
        _heading('Vị trí', () => Navigator.of(context).pop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Row(
                children: [
                  const Text(
                    'Tìm kiếm',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text('ở trong ${_radius.round()} km'),
                ],
              ),
              Slider(
                min: 1,
                max: 50,
                divisions: 49,
                value: _radius,
                label: '${_radius.round()} km',
                onChanged: (value) => setState(() => _radius = value),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Đã lưu'),
                    selected: !_searchSaved,
                    onSelected: (_) => setState(() => _searchSaved = false),
                  ),
                  ChoiceChip(
                    label: const Text('Tìm kiếm'),
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
              ],
              const SizedBox(height: 16),
              const Text(
                'Đã lưu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
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
        _footer('Xác nhận', _selected == null ? null : _confirm),
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
            const Text('Nhãn'),
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
      _footer(
        'Lưu',
        _saving || _label.text.trim().isEmpty || _candidate == null
            ? null
            : _savePlace,
      ),
    ],
  );

  Widget _footer(String label, VoidCallback? onPressed) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(onPressed: onPressed, child: Text(label)),
      ),
    ),
  );
}
