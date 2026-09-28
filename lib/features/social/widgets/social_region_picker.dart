import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialRegionSelection {
  final Region? province;
  final Region? ward;

  const SocialRegionSelection({this.province, this.ward});

  String composeAddress(
    String detail, {
    SocialRegionSelection? previousSelection,
  }) {
    final selectedNames = [ward?.name, province?.name]
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    final regionNames = [
      previousSelection?.ward?.name,
      previousSelection?.province?.name,
      ...selectedNames,
    ].whereType<String>().where((name) => name.trim().isNotEmpty);
    final retainedParts = detail
        .split(',')
        .map((part) => part.trim())
        .where(
          (part) =>
              part.isNotEmpty &&
              !regionNames.any(
                (name) => name.toLowerCase() == part.toLowerCase(),
              ),
        )
        .toList(growable: true);
    retainedParts.addAll(selectedNames);
    return retainedParts.join(', ');
  }
}

class SocialRegionPicker extends ConsumerStatefulWidget {
  final ValueChanged<SocialRegionSelection> onChanged;
  final bool showSectionLabel;

  const SocialRegionPicker({
    super.key,
    required this.onChanged,
    this.showSectionLabel = true,
  });

  @override
  ConsumerState<SocialRegionPicker> createState() => _SocialRegionPickerState();
}

class _SocialRegionPickerState extends ConsumerState<SocialRegionPicker> {
  List<Region> _provinces = const [];
  List<Region> _wards = const [];
  Region? _province;
  Region? _ward;
  bool _loadingProvinces = false;
  bool _loadingWards = false;
  bool _provinceLoadFailed = false;
  bool _wardLoadFailed = false;
  int _wardLoadVersion = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProvinces());
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _loadingProvinces = true;
      _provinceLoadFailed = false;
    });
    try {
      final provinces = await ref.read(regionRepositoryProvider).getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _loadingProvinces = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProvinces = false;
        _provinceLoadFailed = true;
      });
    }
  }

  Future<void> _loadWards(Region province) async {
    final loadVersion = ++_wardLoadVersion;
    setState(() {
      _wards = const [];
      _ward = null;
      _loadingWards = true;
      _wardLoadFailed = false;
    });
    try {
      final wards = await ref
          .read(regionRepositoryProvider)
          .getWardsByProvince(province.code);
      if (!mounted || loadVersion != _wardLoadVersion) return;
      setState(() {
        _wards = wards;
        _loadingWards = false;
      });
    } catch (_) {
      if (!mounted || loadVersion != _wardLoadVersion) return;
      setState(() {
        _loadingWards = false;
        _wardLoadFailed = true;
      });
    }
  }

  void _clearProvince() {
    _wardLoadVersion++;
    setState(() {
      _province = null;
      _ward = null;
      _wards = const [];
      _loadingWards = false;
      _wardLoadFailed = false;
    });
    widget.onChanged(const SocialRegionSelection());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final selectedArea = [
      _ward?.name,
      _province?.name,
    ].whereType<String>().where((name) => name.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSectionLabel) ...[
          Text(
            l10n.socialRegionSectionLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
        ],
        _buildRegionFields(context, l10n, colors),
        if (selectedArea.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            selectedArea,
            key: const ValueKey('social-region-selected-summary'),
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildRegionFields(
    BuildContext context,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingProvinces || _loadingWards)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        _autocomplete(
          key: const ValueKey('social-region-province'),
          fieldKey: const ValueKey('social-region-province-input'),
          label: l10n.clubRegionProvinceLabel,
          hintText: l10n.socialRegionSearchHint,
          initialValue: _province?.name ?? '',
          enabled: !_loadingProvinces && !_provinceLoadFailed,
          options: _provinces,
          onSelected: (province) {
            FocusScope.of(context).unfocus();
            setState(() {
              _province = province;
              _ward = null;
              _wards = const [];
              _wardLoadFailed = false;
            });
            widget.onChanged(SocialRegionSelection(province: province));
            unawaited(_loadWards(province));
          },
          onTextChanged: (value) {
            if (value.trim().isEmpty && _province != null) {
              _clearProvince();
            }
          },
          colors: colors,
        ),
        const SizedBox(height: 10),
        _autocomplete(
          key: ValueKey('social-region-ward-${_province?.code ?? 'none'}'),
          fieldKey: const ValueKey('social-region-ward-input'),
          label: l10n.clubRegionWardLabel,
          hintText: l10n.socialRegionSearchHint,
          initialValue: _ward?.name ?? '',
          enabled: _province != null && !_loadingWards && !_wardLoadFailed,
          options: _wards,
          onSelected: (ward) {
            FocusScope.of(context).unfocus();
            setState(() => _ward = ward);
            widget.onChanged(
              SocialRegionSelection(province: _province, ward: ward),
            );
          },
          onTextChanged: (value) {
            if (_ward != null && value.trim() != _ward!.name) {
              setState(() => _ward = null);
              widget.onChanged(SocialRegionSelection(province: _province));
            }
          },
          colors: colors,
        ),
        if (_provinceLoadFailed || _wardLoadFailed) ...[
          const SizedBox(height: 6),
          Text(
            l10n.socialRegionSearchFailed,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          TextButton.icon(
            onPressed: _provinceLoadFailed
                ? _loadProvinces
                : _province == null
                ? null
                : () => _loadWards(_province!),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(l10n.socialRegionRetry),
          ),
        ],
      ],
    );
  }

  Widget _autocomplete({
    required Key key,
    required String label,
    required Key fieldKey,
    required String hintText,
    required String initialValue,
    required bool enabled,
    required List<Region> options,
    required ValueChanged<Region> onSelected,
    required ValueChanged<String> onTextChanged,
    required AppColorsExtension colors,
  }) {
    return Autocomplete<Region>(
      initialValue: TextEditingValue(text: initialValue),
      key: key,
      displayStringForOption: (region) => region.name,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return options;
        return options.where((region) {
          return region.name.toLowerCase().contains(query) ||
              (region.fullName?.toLowerCase().contains(query) ?? false);
        });
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          onChanged: onTextChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            isDense: true,
            filled: true,
            fillColor: enabled ? colors.bgCard : colors.bgSurface,
            suffixIcon: const Icon(Icons.search, size: 18),
          ),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onOptionSelected, matches) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: colors.bgCard,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 420),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final region = matches.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      region.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle:
                        region.fullName == null ||
                            region.fullName == region.name
                        ? null
                        : Text(
                            region.fullName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => onOptionSelected(region),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
