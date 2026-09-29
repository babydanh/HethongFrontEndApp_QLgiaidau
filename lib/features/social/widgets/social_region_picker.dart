import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Khu vực đã áp dụng cho buổi: phường/xã trước, tỉnh/thành được suy ra.
///
/// Chỉ giữ tên hiển thị — không lưu mã địa phương vào payload.
class SocialRegionSelection {
  const SocialRegionSelection({this.province, this.ward});

  final Region? province;
  final Region? ward;

  bool get isEmpty => province == null && ward == null;

  /// Tóm tắt hiển thị: "Phường/Xã, Tỉnh/Thành phố".
  String summary(AppLocalizations l10n) {
    final provinceName = province?.name.trim() ?? '';
    final wardName = ward?.name.trim() ?? '';
    if (provinceName.isEmpty) return wardName;
    if (wardName.isEmpty) return provinceName;
    return l10n.socialRegionSelectedSummary(wardName, provinceName);
  }
}

/// Locality selector opens as a bottom sheet with separate province/city and
/// ward/commune fields, address-derived suggestions, and manual correction.
///
/// It uses only the existing `IRegionRepository` and deterministic
/// `VietnamAddressParser`; no endpoint, payload field, region ID, or model call
/// is added. The applied names are composed into the existing `venueAddress`.
class SocialRegionPicker extends ConsumerStatefulWidget {
  const SocialRegionPicker({
    super.key,
    required this.address,
    required this.applied,
    required this.onApply,
    this.contextProvinceCode,
  });

  /// Địa chỉ sân gõ tay, nguồn của đề xuất suy ra.
  final String address;

  /// Lựa chọn đã áp dụng cho form, hiển thị ở đầu phần khu vực.
  final SocialRegionSelection? applied;

  /// Tỉnh của CLB gắn kèm: ngữ cảnh dự phòng khi địa chỉ không nêu thành phố.
  final String? contextProvinceCode;

  /// Chỉ gọi khi người dùng bấm "Áp dụng"; form ghép tên khu vực vào
  /// `venueAddress` lúc lưu.
  final ValueChanged<SocialRegionSelection> onApply;

  @override
  ConsumerState<SocialRegionPicker> createState() => _SocialRegionPickerState();
}

class _SocialRegionPickerState extends ConsumerState<SocialRegionPicker> {
  Future<void> _openPicker() async {
    final selection = await showModalBottomSheet<SocialRegionSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.86,
        child: _SocialRegionPickerSheet(
          address: widget.address,
          applied: widget.applied,
          contextProvinceCode: widget.contextProvinceCode,
        ),
      ),
    );
    if (selection != null && mounted) widget.onApply(selection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final applied = widget.applied;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.socialRegionLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.colors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: _openPicker,
          icon: const Icon(Icons.place_outlined),
          label: Text(
            applied == null || applied.isEmpty
                ? l10n.socialRegionOpenAction
                : applied.summary(l10n),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            side: BorderSide(color: context.colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialRegionPickerSheet extends ConsumerStatefulWidget {
  const _SocialRegionPickerSheet({
    required this.address,
    required this.applied,
    required this.contextProvinceCode,
  });

  final String address;
  final SocialRegionSelection? applied;
  final String? contextProvinceCode;

  @override
  ConsumerState<_SocialRegionPickerSheet> createState() =>
      _SocialRegionPickerSheetState();
}

class _SocialRegionPickerSheetState
    extends ConsumerState<_SocialRegionPickerSheet> {
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _maxVisibleOptions = 50;
  static final _wardTypePrefix = RegExp(r'^(?:phuong|xa|thi tran|dac khu)\s+');

  final TextEditingController _provinceSearch = TextEditingController();
  final TextEditingController _wardSearch = TextEditingController();

  List<Region> _provinces = const [];
  Map<String, Region> _provincesByCode = const {};
  List<Region> _wards = const [];
  Region? _province;
  Region? _ward;
  SocialRegionSelection? _suggestion;
  _RegionField _activeField = _RegionField.province;
  String? _selectedLetter;

  bool _loadingProvinces = true;
  bool _provinceFailed = false;
  bool _loadingWards = false;
  bool _wardFailed = false;

  @override
  void initState() {
    super.initState();
    _resetDraft();
    _loadProvinces();
  }

  @override
  void didUpdateWidget(covariant _SocialRegionPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address ||
        oldWidget.contextProvinceCode != widget.contextProvinceCode) {
      _suggestion = widget.applied == null ? _inferFrom(widget.address) : null;
    }
  }

  @override
  void dispose() {
    _provinceSearch.dispose();
    _wardSearch.dispose();
    super.dispose();
  }

  void _resetDraft() {
    _province = widget.applied?.province;
    _ward = widget.applied?.ward;
    _provinceSearch.text = _province?.name ?? '';
    _wardSearch.text = _ward?.name ?? '';
    _activeField = _province == null
        ? _RegionField.province
        : _RegionField.ward;
    _selectedLetter = null;
    _suggestion = widget.applied == null ? _inferFrom(widget.address) : null;
  }

  SocialRegionSelection? _inferFrom(String rawAddress) {
    final address = rawAddress.trim();
    if (address.isEmpty || _provinces.isEmpty) return null;

    final detected = VietnamAddressParser.detectProvince<Region>(
      rawAddress: address,
      provinces: _provinces,
      getCode: (region) => region.code,
      getName: (region) => region.name,
      getFullName: (region) => region.fullName ?? region.name,
    );
    final contextCode = widget.contextProvinceCode?.trim() ?? '';
    final province =
        detected ??
        (contextCode.isEmpty ? null : _provincesByCode[contextCode]);
    if (province == null) return null;

    final scope = _wards
        .where((ward) => ward.provinceCode == province.code)
        .toList(growable: false);
    if (scope.isEmpty) return null;

    final ward = VietnamAddressParser.detectWard<Region>(
      rawAddress: address,
      wards: scope,
      getCode: (region) => region.code,
      getName: (region) => region.name,
      getFullName: (region) => region.fullName ?? region.name,
    );
    if (ward == null || !_isUniquelyNamed(ward, scope)) return null;
    return SocialRegionSelection(province: province, ward: ward);
  }

  bool _isUniquelyNamed(Region ward, List<Region> scope) {
    final key = VietnamAddressParser.removeVietnameseTones(ward.name);
    return scope
            .where(
              (item) =>
                  VietnamAddressParser.removeVietnameseTones(item.name) == key,
            )
            .length ==
        1;
  }

  List<Region> _sortRegions(List<Region> regions, {required bool isWard}) {
    final sorted = List<Region>.of(regions);
    sorted.sort((left, right) {
      final normalized = _alphabetKey(
        left,
        isWard: isWard,
      ).compareTo(_alphabetKey(right, isWard: isWard));
      if (normalized != 0) return normalized;
      final byName = left.name.compareTo(right.name);
      if (byName != 0) return byName;
      return left.code.compareTo(right.code);
    });
    return sorted;
  }

  String _searchKey(Region region) =>
      VietnamAddressParser.removeVietnameseTones(region.name);

  String _alphabetKey(Region region, {required bool isWard}) {
    final key = _searchKey(region);
    return isWard ? key.replaceFirst(_wardTypePrefix, '') : key;
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _loadingProvinces = true;
      _provinceFailed = false;
      _loadingWards = false;
      _wardFailed = false;
      _wards = const [];
    });
    try {
      final provinces = await ref.read(regionRepositoryProvider).getProvinces();
      if (!mounted) return;
      final sorted = _sortRegions(provinces, isWard: false);
      setState(() {
        _provinces = sorted;
        _provincesByCode = {
          for (final province in sorted) province.code: province,
        };
        _loadingProvinces = false;
        _provinceFailed = false;
      });
      if (sorted.isEmpty) return;
      await _loadWards();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _provinces = const [];
        _provincesByCode = const {};
        _wards = const [];
        _loadingProvinces = false;
        _loadingWards = false;
        _provinceFailed = true;
        _wardFailed = false;
      });
    }
  }

  Future<void> _loadWards() async {
    if (_provinces.isEmpty) return;
    setState(() {
      _loadingWards = true;
      _wardFailed = false;
    });
    try {
      final wards = await ref
          .read(regionRepositoryProvider)
          .getWardsByProvince('');
      if (!mounted) return;
      setState(() {
        _wards = _sortRegions(wards, isWard: true);
        _loadingWards = false;
        _wardFailed = false;
        _suggestion = widget.applied == null
            ? _inferFrom(widget.address)
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _wards = const [];
        _loadingWards = false;
        _wardFailed = true;
      });
    }
  }

  Region? _provinceFor(Region ward) {
    final provinceCode = ward.provinceCode?.trim();
    if (provinceCode == null || provinceCode.isEmpty) return null;
    return _provincesByCode[provinceCode];
  }

  void _selectProvince(Region province) {
    setState(() {
      _province = province;
      if (_ward?.provinceCode != province.code) _ward = null;
      _provinceSearch.text = province.name;
      _wardSearch.clear();
      _activeField = _RegionField.ward;
      _selectedLetter = null;
      _suggestion = null;
    });
  }

  void _selectWard(Region ward) {
    final province = _provinceFor(ward);
    final selectedProvince = _province;
    if (province == null ||
        (selectedProvince != null && selectedProvince.code != province.code)) {
      return;
    }
    setState(() {
      _province = province;
      _ward = ward;
      _provinceSearch.text = province.name;
      _wardSearch.text = ward.name;
      _activeField = _RegionField.ward;
      _selectedLetter = null;
      _suggestion = null;
    });
  }

  void _activateField(_RegionField field) {
    setState(() {
      _activeField = field;
      _selectedLetter = null;
    });
  }

  void _onProvinceSearchChanged(String _) {
    setState(() {
      _activeField = _RegionField.province;
      _province = null;
      _ward = null;
      _wardSearch.clear();
      _selectedLetter = null;
      _suggestion = null;
    });
  }

  void _onWardSearchChanged(String _) {
    setState(() {
      _activeField = _RegionField.ward;
      _ward = null;
      _selectedLetter = null;
      _suggestion = null;
    });
  }

  List<Region> _activeOptions() {
    if (_activeField == _RegionField.province) return _provinces;
    final province = _province;
    if (province != null) {
      return _wards
          .where((ward) => ward.provinceCode == province.code)
          .toList(growable: false);
    }
    return _wards
        .where((ward) => _provincesByCode.containsKey(ward.provinceCode))
        .toList(growable: false);
  }

  List<Region> _visibleOptions() {
    final queryController = _activeField == _RegionField.province
        ? _provinceSearch
        : _wardSearch;
    final query = VietnamAddressParser.removeVietnameseTones(
      queryController.text.trim(),
    );
    return _activeOptions()
        .where((region) {
          final searchKey = _searchKey(region);
          final alphabetKey = _alphabetKey(
            region,
            isWard: _activeField == _RegionField.ward,
          );
          final matchesQuery = query.isEmpty || searchKey.contains(query);
          final matchesLetter =
              _selectedLetter == null ||
              alphabetKey.startsWith(_selectedLetter!.toLowerCase());
          return matchesQuery && matchesLetter;
        })
        .take(_maxVisibleOptions)
        .toList(growable: false);
  }

  bool _hasOptionsForLetter(String letter) => _activeOptions().any(
    (region) => _alphabetKey(
      region,
      isWard: _activeField == _RegionField.ward,
    ).startsWith(letter.toLowerCase()),
  );

  void _selectLetter(String letter) {
    setState(() {
      _selectedLetter = _selectedLetter == letter ? null : letter;
    });
  }

  void _apply() {
    final province = _province;
    final ward = _ward;
    if (province == null ||
        ward == null ||
        ward.provinceCode != province.code) {
      return;
    }
    Navigator.of(
      context,
    ).pop(SocialRegionSelection(province: province, ward: ward));
  }

  void _applySuggestion() {
    final suggestion = _suggestion;
    if (suggestion != null) Navigator.of(context).pop(suggestion);
  }

  Future<void> _retryLoad() {
    if (_provinceFailed || _provinces.isEmpty) return _loadProvinces();
    return _loadWards();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestion = _suggestion;
    final province = _province;
    final ward = _ward;
    final canApply =
        province != null &&
        ward != null &&
        ward.provinceCode == province.code &&
        !_loadingProvinces &&
        !_loadingWards &&
        !_provinceFailed &&
        !_wardFailed;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            _sheetHeader(context, l10n),
            if (suggestion != null) ...[
              const SizedBox(height: 12),
              _suggestionCard(context, l10n, suggestion),
            ],
            const SizedBox(height: 12),
            _selectionFields(context, l10n),
            const SizedBox(height: 8),
            _alphabetFilter(context, l10n),
            const SizedBox(height: 8),
            Expanded(child: _optionsList(context, l10n)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.socialRegionCancelAction),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canApply ? _apply : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(l10n.socialRegionApplyAction),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.socialRegionPickerTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.socialRegionCloseAction,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _selectionFields(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _searchField(
          context,
          field: _RegionField.province,
          controller: _provinceSearch,
          label: l10n.socialRegionProvinceLabel,
          hint: l10n.socialRegionProvinceSearchHint,
          onChanged: _onProvinceSearchChanged,
        ),
        const SizedBox(height: 8),
        _searchField(
          context,
          field: _RegionField.ward,
          controller: _wardSearch,
          label: l10n.socialRegionWardLabel,
          hint: l10n.socialRegionWardSearchHint,
          onChanged: _onWardSearchChanged,
        ),
      ],
    );
  }

  Widget _searchField(
    BuildContext context, {
    required _RegionField field,
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onTap: () => _activateField(field),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: context.colors.bgDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _alphabetFilter(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.socialRegionAlphabetHint,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final letter in _alphabet.split(''))
                _letterFilter(l10n, letter),
            ],
          ),
        ),
      ],
    );
  }

  /// Một bộ lọc A–Z. Chip giữ callback chạm, nút [Semantics] bao ngoài mang
  /// đúng lựa chọn đó cho trình đọc màn hình: chữ cái không chỉ được đọc mà
  /// còn kích hoạt được. Chữ cái không có kết quả vẫn bị khoá ở cả hai đường.
  Widget _letterFilter(AppLocalizations l10n, String letter) {
    final available = _hasOptionsForLetter(letter);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Semantics(
        button: true,
        enabled: available,
        selected: _selectedLetter == letter,
        label: '${l10n.socialRegionAlphabetHint}: $letter',
        excludeSemantics: true,
        onTap: available ? () => _selectLetter(letter) : null,
        child: ChoiceChip(
          label: Text(letter),
          selected: _selectedLetter == letter,
          onSelected: available ? (_) => _selectLetter(letter) : null,
          // Mật độ chuẩn giữ vùng chạm tối thiểu 48 px trong hàng cuộn ngang.
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
        ),
      ),
    );
  }

  Widget _optionsList(BuildContext context, AppLocalizations l10n) {
    if (_loadingProvinces || _loadingWards) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_provinceFailed || _wardFailed) {
      return _message(
        context,
        l10n.socialRegionLoadError,
        action: TextButton(
          onPressed: _retryLoad,
          child: Text(l10n.socialRegionRetry),
        ),
      );
    }
    if (_provinces.isEmpty || _wards.isEmpty) {
      return _message(
        context,
        l10n.socialRegionUnavailable,
        action: TextButton(
          onPressed: _retryLoad,
          child: Text(l10n.socialRegionRetry),
        ),
      );
    }
    final wardQuery = _wardSearch.text.trim();
    if (_activeField == _RegionField.ward &&
        wardQuery.isNotEmpty &&
        wardQuery.length < 2 &&
        _selectedLetter == null) {
      return Center(
        child: Text(
          l10n.socialRegionWardSearchPrompt,
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }

    final options = _visibleOptions();
    if (options.isEmpty) {
      return Center(
        child: Text(
          l10n.socialRegionNoResults,
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: options.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: context.colors.border.withValues(alpha: 0.5),
      ),
      itemBuilder: (context, index) => _regionOption(context, options[index]),
    );
  }

  Widget _regionOption(BuildContext context, Region region) {
    final isProvince = _activeField == _RegionField.province;
    final selected = isProvince
        ? _province?.code == region.code
        : _ward?.code == region.code;
    final province = isProvince ? null : _provinceFor(region);
    final label = isProvince
        ? region.name
        : '${region.name}, ${province?.name ?? ''}';

    void onSelect() {
      if (isProvince) {
        _selectProvince(region);
      } else {
        _selectWard(region);
      }
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      // Cùng lựa chọn với cú chạm, để trình đọc màn hình kích hoạt được
      // tỉnh/phường chứ không chỉ nghe tên.
      onTap: onSelect,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(region.name),
        subtitle: province == null ? null : Text(province.name),
        trailing: selected
            ? Icon(Icons.check_circle, color: context.colors.success)
            : null,
        onTap: onSelect,
      ),
    );
  }

  Widget _suggestionCard(
    BuildContext context,
    AppLocalizations l10n,
    SocialRegionSelection suggestion,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.socialRegionSuggestionLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.summary(l10n),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _applySuggestion,
              child: Text(l10n.socialRegionApplyAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, String text, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: context.colors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 4), action],
          ],
        ),
      ),
    );
  }
}

enum _RegionField { province, ward }
