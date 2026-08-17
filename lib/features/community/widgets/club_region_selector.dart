import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Khu vực hoạt động của CLB: cascade Tỉnh/Thành → Phường/Xã.
///
/// Đồng bộ logic với web (SettingsTab.tsx):
/// - Chọn tỉnh mới → tải lại danh sách phường/xã.
/// - Ghép địa chỉ: "địa điểm chi tiết, phường, tỉnh".
class ClubRegionSelector extends ConsumerStatefulWidget {
  final String initialProvinceCode;
  final String initialWardCode;
  final ValueChanged<ClubRegionSelection> onChanged;

  const ClubRegionSelector({
    super.key,
    this.initialProvinceCode = '',
    this.initialWardCode = '',
    required this.onChanged,
  });

  @override
  ConsumerState<ClubRegionSelector> createState() => _ClubRegionSelectorState();
}

class _ClubRegionSelectorState extends ConsumerState<ClubRegionSelector> {
  List<Region> _provinces = const [];
  List<Region> _wards = const [];

  String _provinceCode = '';
  String _wardCode = '';
  bool _loadingProvinces = true;

  @override
  void initState() {
    super.initState();
    _provinceCode = widget.initialProvinceCode;
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
    if (_provinceCode.isNotEmpty) await _loadWards();
    _notify();
  }

  Future<void> _loadWards() async {
    final wards = await ref.read(regionRepositoryProvider).getWardsByProvince(_provinceCode);
    if (!mounted) return;
    setState(() => _wards = wards);
    _notify();
  }

  void _notify() {
    widget.onChanged(ClubRegionSelection(
      provinceCode: _provinceCode,
      wardCode: _wardCode,
      provinces: _provinces,
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
          key: const ValueKey('province'),
          context: context,
          colors: colors,
          label: 'Tỉnh / Thành phố *',
          value: _provinceCode,
          items: _provinces,
          onChanged: (code) {
            setState(() {
              _provinceCode = code;
              _wardCode = '';
              _wards = const [];
            });
            if (code.isNotEmpty) _loadWards();
            _notify();
          },
        ),
        const SizedBox(height: 12),
        _dropdown(
          key: ValueKey('ward-$_provinceCode'),
          context: context,
          colors: colors,
          label: 'Phường / Xã / Thị trấn (Tùy chọn)',
          value: _wardCode,
          items: _wards,
          enabled: _provinceCode.isNotEmpty,
          onChanged: (code) {
            setState(() => _wardCode = code);
            _notify();
          },
        ),
      ],
    );
  }

  Widget _dropdown({
    Key? key,
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
      key: key,
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
  final String wardCode;
  final List<Region> provinces;
  final List<Region> wards;

  const ClubRegionSelection({
    this.provinceCode = '',
    this.wardCode = '',
    this.provinces = const [],
    this.wards = const [],
  });

  String? _nameOf(List<Region> source, String code) {
    if (code.isEmpty) return null;
    for (final region in source) {
      if (region.code == code) return region.name;
    }
    return null;
  }

  String? get provinceName => _nameOf(provinces, provinceCode);
  String? get wardName => _nameOf(wards, wardCode);

  /// Ghép địa chỉ giống web: "chi tiết, phường, tỉnh".
  String composeAddress(String detail) {
    final wardName = _nameOf(wards, wardCode);
    final provinceName = _nameOf(provinces, provinceCode);
    final adminPart = [wardName, provinceName]
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .join(', ');
    final trimmedDetail = detail.trim();

    if (trimmedDetail.isEmpty) return adminPart;
    if (adminPart.isEmpty) return trimmedDetail;
    final alreadyContainsAdmin = provinceName != null && trimmedDetail.contains(provinceName);
    return alreadyContainsAdmin ? trimmedDetail : '$trimmedDetail, $adminPart';
  }
}
