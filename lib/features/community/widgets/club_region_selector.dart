import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Khu vực hoạt động của CLB: cascade Tỉnh/Thành → Quận/Huyện → Phường/Xã.
///
/// Đồng bộ logic với web (SettingsTab.tsx):
/// - Chọn tỉnh mới → reset quận + phường; chọn quận mới → reset phường.
/// - Ghép địa chỉ: "địa điểm chi tiết, phường, quận, tỉnh" (không lặp tên tỉnh/quận).
class ClubRegionSelector extends ConsumerStatefulWidget {
  final String initialProvinceCode;
  final String initialDistrictCode;
  final String initialWardCode;
  final ValueChanged<ClubRegionSelection> onChanged;

  const ClubRegionSelector({
    super.key,
    this.initialProvinceCode = '',
    this.initialDistrictCode = '',
    this.initialWardCode = '',
    required this.onChanged,
  });

  @override
  ConsumerState<ClubRegionSelector> createState() => _ClubRegionSelectorState();
}

class _ClubRegionSelectorState extends ConsumerState<ClubRegionSelector> {
  List<Region> _provinces = const [];
  List<Region> _districts = const [];
  List<Region> _wards = const [];

  String _provinceCode = '';
  String _districtCode = '';
  String _wardCode = '';
  bool _loadingProvinces = true;

  @override
  void initState() {
    super.initState();
    _provinceCode = widget.initialProvinceCode;
    _districtCode = widget.initialDistrictCode;
    _wardCode = widget.initialWardCode;
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    final provinces = await ref.read(regionRepositoryProvider).getProvinces();
    if (!mounted) return;
    setState(() {
      _provinces = provinces;
      _loadingProvinces = false;
    });
    if (_provinceCode.isNotEmpty) await _loadDistricts(loadWards: true);
    _notify();
  }

  Future<void> _loadDistricts({bool loadWards = false}) async {
    final districts =
        await ref.read(regionRepositoryProvider).getDistricts(_provinceCode);
    if (!mounted) return;
    setState(() => _districts = districts);
    if (loadWards && _districtCode.isNotEmpty) {
      await _loadWards();
    } else {
      _notify();
    }
  }

  Future<void> _loadWards() async {
    final wards = await ref.read(regionRepositoryProvider).getWards(_districtCode);
    if (!mounted) return;
    setState(() => _wards = wards);
    _notify();
  }

  void _notify() {
    widget.onChanged(ClubRegionSelection(
      provinceCode: _provinceCode,
      districtCode: _districtCode,
      wardCode: _wardCode,
      provinces: _provinces,
      districts: _districts,
      wards: _wards,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_loadingProvinces) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dropdown(
          context: context,
          colors: colors,
          label: 'Tỉnh / Thành phố *',
          value: _provinceCode,
          items: _provinces,
          onChanged: (code) {
            setState(() {
              _provinceCode = code;
              _districtCode = '';
              _wardCode = '';
              _districts = const [];
              _wards = const [];
            });
            if (code.isNotEmpty) _loadDistricts();
            _notify();
          },
        ),
        const SizedBox(height: 12),
        _dropdown(
          context: context,
          colors: colors,
          label: 'Quận / Huyện',
          value: _districtCode,
          items: _districts,
          enabled: _provinceCode.isNotEmpty,
          onChanged: (code) {
            setState(() {
              _districtCode = code;
              _wardCode = '';
              _wards = const [];
            });
            if (code.isNotEmpty) _loadWards();
            _notify();
          },
        ),
        const SizedBox(height: 12),
        _dropdown(
          context: context,
          colors: colors,
          label: 'Phường / Xã',
          value: _wardCode,
          items: _wards,
          enabled: _districtCode.isNotEmpty,
          onChanged: (code) {
            setState(() => _wardCode = code);
            _notify();
          },
        ),
      ],
    );
  }

  Widget _dropdown({
    required BuildContext context,
    required AppColorsExtension colors,
    required String label,
    required String value,
    required List<Region> items,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    // Giá trị đã lưu nằm ngoài danh sách (dữ liệu cũ) — vẫn hiển thị để không mất.
    final effectiveItems = [...items];
    if (value.isNotEmpty && !items.any((region) => region.code == value)) {
      effectiveItems.insert(0, Region(code: value, name: '$value (cũ)'));
    }
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: enabled ? colors.bgCard : colors.bgSurface,
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('-- Chọn --')),
        ...effectiveItems.map(
          (region) => DropdownMenuItem(value: region.code, child: Text(region.name)),
        ),
      ],
      onChanged: enabled ? (code) => onChanged(code ?? '') : null,
    );
  }
}

/// Trạng thái chọn vùng + danh sách để màn cha ghép địa chỉ khi lưu.
class ClubRegionSelection {
  final String provinceCode;
  final String districtCode;
  final String wardCode;
  final List<Region> provinces;
  final List<Region> districts;
  final List<Region> wards;

  const ClubRegionSelection({
    this.provinceCode = '',
    this.districtCode = '',
    this.wardCode = '',
    this.provinces = const [],
    this.districts = const [],
    this.wards = const [],
  });

  String? _nameOf(List<Region> source, String code) {
    if (code.isEmpty) return null;
    for (final region in source) {
      if (region.code == code) return region.name;
    }
    return null;
  }

  /// Ghép địa chỉ giống web: "chi tiết, phường, quận, tỉnh".
  /// Bỏ lặp nếu chi tiết đã chứa tên tỉnh/quận; chỉ chi tiết → giữ nguyên.
  String composeAddress(String detail) {
    final wardName = _nameOf(wards, wardCode);
    final districtName = _nameOf(districts, districtCode);
    final provinceName = _nameOf(provinces, provinceCode);
    final adminPart = [wardName, districtName, provinceName]
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .join(', ');
    final trimmedDetail = detail.trim();

    if (trimmedDetail.isEmpty) return adminPart;
    if (adminPart.isEmpty) return trimmedDetail;
    final alreadyContainsAdmin =
        (provinceName != null && trimmedDetail.contains(provinceName)) ||
            (districtName != null && trimmedDetail.contains(districtName));
    return alreadyContainsAdmin ? trimmedDetail : '$trimmedDetail, $adminPart';
  }
}
