import 'package:app_quanly_giaidau/features/tournament/utils/camera_match_filter.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_filter_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const double _pillHeight = 44;
const double _pillIcon = 36;

/// Viên thuốc tìm kiếm thay chính hàng đầu tab Camera: nút đóng, ô nhập
/// (tự focus), nút xoá chữ và phễu lọc nằm trong viên. Phễu có chấm đỏ khi
/// đang lọc chặng hoặc "Chưa có cam".
class CameraSearchPill extends StatefulWidget {
  const CameraSearchPill({
    super.key,
    required this.filter,
    required this.stages,
    required this.onChanged,
    required this.onClose,
  });

  final CameraMatchFilter filter;
  final List<CameraStage> stages;
  final ValueChanged<CameraMatchFilter> onChanged;
  final VoidCallback onClose;

  @override
  State<CameraSearchPill> createState() => _CameraSearchPillState();
}

class _CameraSearchPillState extends State<CameraSearchPill> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.filter.query,
  );

  @override
  void didUpdateWidget(CameraSearchPill oldWidget) {
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

  Future<void> _openFilterSheet() async {
    final choice = await showCameraFilterSheet(
      context,
      stages: widget.stages,
      current: (
        stage: widget.filter.stage,
        onlyNoCamera: widget.filter.onlyNoCamera,
      ),
    );
    if (choice == null || !mounted) return;
    widget.onChanged(
      widget.filter.copyWith(
        stage: () => choice.stage,
        onlyNoCamera: choice.onlyNoCamera,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = widget.filter;
    final filtering = filter.stage != null || filter.onlyNoCamera;
    const glyph = Icon(Icons.filter_list_rounded);
    return Row(
      children: [
        IconButton(
          tooltip: l10n.camTabCloseSearch,
          constraints: const BoxConstraints.tightFor(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
          ),
          onPressed: widget.onClose,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Container(
            key: const ValueKey('camTabPill'),
            height: _pillHeight,
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(_pillHeight / 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: l10n.camTabSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: _pillIcon,
                      ),
                    ),
                    onChanged: (value) =>
                        widget.onChanged(filter.copyWith(query: value)),
                  ),
                ),
                if (filter.query.isNotEmpty)
                  IconButton(
                    tooltip: l10n.camTabClearText,
                    constraints: const BoxConstraints.tightFor(
                      width: _pillIcon,
                      height: _pillIcon,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        widget.onChanged(filter.copyWith(query: '')),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                IconButton(
                  tooltip: l10n.camTabFilterTooltip,
                  constraints: const BoxConstraints.tightFor(
                    width: _pillHeight,
                    height: _pillHeight,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: _openFilterSheet,
                  icon: filtering
                      ? const Badge(
                          key: ValueKey('camTabFilterDot'),
                          smallSize: 8,
                          child: glyph,
                        )
                      : glyph,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
