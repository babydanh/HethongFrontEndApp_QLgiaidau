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

/// Phần khu vực nằm thẳng trong form (không bottom sheet).
///
/// - Nguồn duy nhất: `IRegionRepository` + `VietnamAddressParser` tất định;
///   không thêm endpoint, trường API hay lời gọi mô hình nào.
/// - Địa chỉ gõ tay đủ thông tin thì đề xuất phường + thành phố ngay tại chỗ.
///   Thành phố nêu rõ trong địa chỉ luôn thắng; tỉnh của CLB chỉ làm ngữ cảnh
///   khi địa chỉ không nêu thành phố. Không có ngữ cảnh nào thì không đoán.
/// - Ô tìm kiếm tay luôn mở: người dùng sửa hoặc chọn lại bất cứ lúc nào.
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
  final TextEditingController _wardSearch = TextEditingController();

  List<Region> _provinces = const [];
  Map<String, Region> _provincesByCode = const {};
  List<Region> _wards = const [];

  /// Lựa chọn tay đang chờ áp dụng.
  Region? _province;
  Region? _ward;

  /// Đề xuất suy ra từ địa chỉ, chỉ hiện khi chưa có lựa chọn tay nào.
  SocialRegionSelection? _suggestion;

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
  void didUpdateWidget(covariant SocialRegionPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.applied != widget.applied) _resetDraft();
    if (oldWidget.address != widget.address ||
        oldWidget.contextProvinceCode != widget.contextProvinceCode) {
      // `build` chạy ngay sau đây nên gán thẳng, không cần setState.
      _suggestion = _inferFrom(widget.address);
    }
  }

  @override
  void dispose() {
    _wardSearch.dispose();
    super.dispose();
  }

  /// Lựa chọn đã áp dụng hiện ở đầu phần khu vực; ô tìm kiếm quay về trạng
  /// thái trống để chọn lại, và đề xuất cũ không còn ý nghĩa.
  void _resetDraft() {
    _province = null;
    _ward = null;
    _wardSearch.clear();
    _suggestion = null;
  }

  /// Đề xuất chỉ được chốt khi địa chỉ đủ thông tin: thành phố nêu rõ trong
  /// địa chỉ, hoặc tỉnh của CLB khi địa chỉ không nêu thành phố; và tên phường
  /// phải khớp duy nhất trong tỉnh đó. Không đủ dữ kiện thì không đoán.
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

  /// Trùng tên trong cùng tỉnh thì không chọn hộ: người dùng tự tìm tay.
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
      setState(() {
        _provinces = provinces;
        _provincesByCode = {
          for (final province in provinces) province.code: province,
        };
        _loadingProvinces = false;
        _provinceFailed = false;
      });
      if (provinces.isEmpty) return;
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
        _wards = wards;
        _loadingWards = false;
        _wardFailed = false;
        // Địa chỉ có thể đã gõ trước khi danh mục tỉnh/phường về tới.
        _suggestion = _inferFrom(widget.address);
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

  void _selectWard(Region ward) {
    final province = _provinceFor(ward);
    if (province == null) return;
    setState(() {
      _ward = ward;
      _province = province;
      // Lựa chọn tay thay cho đề xuất cho tới khi địa chỉ đổi.
      _suggestion = null;
      _wardSearch.text = ward.name;
    });
  }

  void _onWardSearchChanged(String _) {
    setState(() {
      _ward = null;
      _province = null;
    });
  }

  void _cancel() {
    setState(() {
      _ward = null;
      _province = null;
      _wardSearch.clear();
      // Bỏ lựa chọn tay thì đề xuất theo địa chỉ hiện tại trở lại.
      _suggestion = _inferFrom(widget.address);
    });
  }

  void _apply() {
    final province = _province;
    final ward = _ward;
    if (province == null || ward == null) return;
    widget.onApply(SocialRegionSelection(province: province, ward: ward));
  }

  Future<void> _retryLoad() {
    if (_provinceFailed || _provinces.isEmpty) return _loadProvinces();
    return _loadWards();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final applied = widget.applied;
    final suggestion = _suggestion;
    final loading = _loadingProvinces || _loadingWards;
    final canApply =
        _province != null &&
        _ward != null &&
        !loading &&
        !_provinceFailed &&
        !_wardFailed &&
        _provinces.isNotEmpty &&
        _wards.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.socialRegionLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        if (applied != null && !applied.isEmpty)
          _appliedSummary(context, applied.summary(l10n)),
        if (suggestion != null && _ward == null) ...[
          const SizedBox(height: 10),
          _suggestionCard(context, l10n, suggestion),
        ],
        const SizedBox(height: 8),
        _sectionLabel(context, l10n.socialRegionWardLabel),
        _searchField(
          context,
          controller: _wardSearch,
          hint: l10n.socialRegionWardSearchHint,
          onChanged: _onWardSearchChanged,
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_provinceFailed || _wardFailed)
          _message(
            context,
            l10n.socialRegionLoadError,
            action: TextButton(
              onPressed: _retryLoad,
              child: Text(l10n.socialRegionRetry),
            ),
          )
        else if (_provinces.isEmpty || _wards.isEmpty)
          _message(
            context,
            l10n.socialRegionUnavailable,
            action: TextButton(
              onPressed: _retryLoad,
              child: Text(l10n.socialRegionRetry),
            ),
          )
        else if (_wardSearch.text.trim().length < 2)
          _message(context, l10n.socialRegionWardSearchPrompt)
        else
          _options(
            context,
            l10n: l10n,
            query: _wardSearch.text,
            selected: _ward,
            onSelected: _selectWard,
          ),
        if (_ward != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancel,
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
      ],
    );
  }

  Widget _appliedSummary(BuildContext context, String summary) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.location_city_outlined, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              summary,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Phương án suy ra từ địa chỉ: hiện ngay dưới ô địa điểm, áp dụng bằng một
  /// chạm hoặc bỏ qua và tìm tay.
  Widget _suggestionCard(
    BuildContext context,
    AppLocalizations l10n,
    SocialRegionSelection suggestion,
  ) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              suggestion.summary(l10n),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => widget.onApply(suggestion),
            child: Text(l10n.socialRegionApplyAction),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _searchField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14.5),
        decoration: InputDecoration(
          isDense: true,
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
        ),
      ),
    );
  }

  Widget _options(
    BuildContext context, {
    required AppLocalizations l10n,
    required String query,
    required Region? selected,
    required ValueChanged<Region> onSelected,
  }) {
    final colors = context.colors;
    final needle = query.trim().toLowerCase();
    final matches = _wards
        .where(
          (ward) =>
              ward.name.toLowerCase().contains(needle) &&
              _provinceFor(ward) != null,
        )
        .take(50)
        .toList(growable: false);

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          l10n.socialRegionNoResults,
          style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        for (final ward in matches)
          Semantics(
            button: true,
            selected: selected?.code == ward.code,
            label: '${ward.name}, ${_provinceFor(ward)!.name}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onSelected(ward),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selected?.code == ward.code
                      ? colors.success.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ward.name,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: selected?.code == ward.code
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _provinceFor(ward)!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected?.code == ward.code)
                      Icon(Icons.check, size: 18, color: colors.success),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _message(BuildContext context, String text, {Widget? action}) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 4), action],
        ],
      ),
    );
  }
}
