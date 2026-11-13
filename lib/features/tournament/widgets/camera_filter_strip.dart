import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_match_filter.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Dải tìm/lọc dưới hàng đầu tab Camera: ô tìm trận và/hoặc chọn vòng +
/// công tắc "Chưa có cam". Chỉ hiện phần đang bung.
class CameraFilterStrip extends StatefulWidget {
  const CameraFilterStrip({
    super.key,
    required this.showSearch,
    required this.showFilter,
    required this.filter,
    required this.rounds,
    required this.onChanged,
  });

  final bool showSearch;
  final bool showFilter;
  final CameraMatchFilter filter;
  final List<int> rounds;
  final ValueChanged<CameraMatchFilter> onChanged;

  @override
  State<CameraFilterStrip> createState() => _CameraFilterStripState();
}

class _CameraFilterStripState extends State<CameraFilterStrip> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.filter.query,
  );

  @override
  void didUpdateWidget(CameraFilterStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // "Xoá lọc" ở nơi khác đổi query: đồng bộ lại ô nhập.
    if (widget.filter.query != _controller.text) {
      _controller.text = widget.filter.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = widget.filter;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showSearch)
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.camTabSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  widget.onChanged(filter.copyWith(query: value)),
            ),
          if (widget.showSearch && widget.showFilter)
            const SizedBox(height: AppTheme.spacingSM),
          if (widget.showFilter)
            Wrap(
              spacing: AppTheme.spacingSM,
              runSpacing: AppTheme.spacingXS,
              children: [
                ChoiceChip(
                  label: Text(l10n.camTabAllRounds),
                  selected: filter.round == null,
                  onSelected: (_) =>
                      widget.onChanged(filter.copyWith(round: () => null)),
                ),
                for (final round in widget.rounds)
                  ChoiceChip(
                    label: Text(l10n.camTabRound(round)),
                    selected: filter.round == round,
                    onSelected: (_) =>
                        widget.onChanged(filter.copyWith(round: () => round)),
                  ),
                FilterChip(
                  label: Text(l10n.camTabNoCamera),
                  selected: filter.onlyNoCamera,
                  onSelected: (value) =>
                      widget.onChanged(filter.copyWith(onlyNoCamera: value)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
