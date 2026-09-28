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

  String composeAddress(String detail) {
    final selectedNames = [ward?.name, province?.name]
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    final retainedParts = detail
        .split(',')
        .map((part) => part.trim())
        .where(
          (part) =>
              part.isNotEmpty &&
              !selectedNames.any(
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

  const SocialRegionPicker({super.key, required this.onChanged});

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
  bool _provincesLoaded = false;
  int _wardLoadVersion = 0;
  SocialRegionSelection? _appliedSelection;

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
        _provincesLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProvinces = false;
        _provinceLoadFailed = true;
      });
    }
  }

  Future<void> _loadWards(Region province, {Region? selectedWard}) async {
    final loadVersion = ++_wardLoadVersion;
    setState(() {
      _wards = const [];
      _ward = selectedWard;
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
        _ward =
            selectedWard != null &&
                wards.any((ward) => ward.code == selectedWard.code)
            ? selectedWard
            : null;
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final selectedArea = [
      _appliedSelection?.ward?.name,
      _appliedSelection?.province?.name,
    ].whereType<String>().where((name) => name.isNotEmpty).join(', ');
    final label = selectedArea.isEmpty
        ? l10n.socialRegionSectionLabel
        : selectedArea;
    return IconButton(
      key: const ValueKey('social-region-picker-toggle'),
      tooltip: label,
      onPressed: () => _showPicker(context),
      icon: Icon(
        Icons.location_searching,
        color: _appliedSelection?.province == null
            ? colors.textSecondary
            : colors.success,
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    setState(() {
      _province = _appliedSelection?.province;
      _ward = _appliedSelection?.ward;
      _wards = const [];
      _wardLoadFailed = false;
    });
    final province = _province;
    if (province != null) {
      unawaited(_loadWards(province, selectedWard: _ward));
    }
    if (!_provincesLoaded && !_loadingProvinces && !_provinceLoadFailed) {
      unawaited(_loadProvinces());
    }
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colors.bgSurface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final keyboardInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
            final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.82;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, keyboardInset + 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.socialRegionSectionLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: MaterialLocalizations.of(
                                sheetContext,
                              ).closeButtonTooltip,
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        if (_province != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              [
                                _ward?.name,
                                _province!.name,
                              ].whereType<String>().join(', '),
                              style: TextStyle(color: colors.textSecondary),
                            ),
                          ),
                        _buildRegionFields(
                          context,
                          l10n,
                          colors,
                          setModalState,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const ValueKey('social-region-apply'),
                          onPressed: () {
                            final selection = SocialRegionSelection(
                              province: _province,
                              ward: _ward,
                            );
                            setState(() => _appliedSelection = selection);
                            widget.onChanged(selection);
                            Navigator.of(sheetContext).pop();
                          },
                          icon: const Icon(Icons.check),
                          label: Text(l10n.socialRegionApply),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRegionFields(
    BuildContext context,
    AppLocalizations l10n,
    AppColorsExtension colors,
    StateSetter setModalState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingProvinces)
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
            setState(() => _province = province);
            setModalState(() => _province = province);
            unawaited(
              _loadWards(province).then((_) {
                if (mounted) setModalState(() {});
              }),
            );
          },
          onTextChanged: (value) {
            if (_province != null && value.trim().isEmpty) {
              _clearProvince();
              setModalState(() {});
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
            setModalState(() => _ward = ward);
          },
          onTextChanged: (_) {},
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
