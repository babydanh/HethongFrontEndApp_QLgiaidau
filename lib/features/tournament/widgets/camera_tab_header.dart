import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_match_filter.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_filter_strip.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_tab_help_dialog.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum _MenuAction { refresh, help }

const _stripDuration = Duration(milliseconds: 200);

/// Đầu tab Camera: một hàng chỉ icon (tìm, lọc, tạo camera, xem camera, menu ⋯)
/// và dải tìm/lọc bung ngay dưới. [cameras] null nghĩa là danh sách chưa tải
/// xong — chưa có số thì không in số, tránh khẳng định "0 cam" khi đang tải.
/// [onCreateCamera] null thì ẩn nút ＋ (tab chỉ xem).
class CameraTabHeader extends StatefulWidget {
  const CameraTabHeader({
    super.key,
    required this.cameras,
    required this.filter,
    required this.rounds,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onWatchCameras,
    this.onCreateCamera,
  });

  final List<TournamentCameraModel>? cameras;
  final CameraMatchFilter filter;
  final List<int> rounds;
  final ValueChanged<CameraMatchFilter> onFilterChanged;
  final VoidCallback onRefresh;
  final VoidCallback onWatchCameras;
  final VoidCallback? onCreateCamera;

  @override
  State<CameraTabHeader> createState() => _CameraTabHeaderState();
}

class _CameraTabHeaderState extends State<CameraTabHeader> {
  bool _searchOpen = false;
  bool _filterOpen = false;

  Widget _iconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    Key? dotKey,
  }) {
    final glyph = Icon(icon);
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
      ),
      onPressed: onPressed,
      icon: dotKey == null
          ? glyph
          : Badge(key: dotKey, smallSize: 8, child: glyph),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final filter = widget.filter;
    final list = widget.cameras;
    final summary = list == null ? null : cameraSummary(list);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final strip = _searchOpen || _filterOpen
        ? CameraFilterStrip(
            showSearch: _searchOpen,
            showFilter: _filterOpen,
            filter: filter,
            rounds: widget.rounds,
            onChanged: widget.onFilterChanged,
          )
        : const SizedBox(width: double.infinity);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: kMinTouchTarget,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.camTabTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (summary != null)
                      Text(
                        l10n.camTabSummaryShort(summary.total, summary.live),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              _iconButton(
                tooltip: l10n.camTabSearchTooltip,
                icon: Icons.search_rounded,
                dotKey: filter.query.trim().isEmpty
                    ? null
                    : const ValueKey('camTabSearchDot'),
                onPressed: () => setState(() => _searchOpen = !_searchOpen),
              ),
              _iconButton(
                tooltip: l10n.camTabFilterTooltip,
                icon: Icons.filter_list_rounded,
                dotKey: filter.round == null && !filter.onlyNoCamera
                    ? null
                    : const ValueKey('camTabFilterDot'),
                onPressed: () => setState(() => _filterOpen = !_filterOpen),
              ),
              if (widget.onCreateCamera != null)
                _iconButton(
                  tooltip: l10n.camTabCreateTooltip,
                  icon: Icons.add_rounded,
                  onPressed: widget.onCreateCamera!,
                ),
              if (list != null && list.isNotEmpty)
                _iconButton(
                  tooltip: l10n.camTabWatchCameras,
                  icon: Icons.videocam_outlined,
                  onPressed: widget.onWatchCameras,
                ),
              PopupMenuButton<_MenuAction>(
                tooltip: l10n.camTabMenuTooltip,
                constraints: const BoxConstraints(minWidth: kMinTouchTarget),
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) => switch (action) {
                  _MenuAction.refresh => widget.onRefresh(),
                  _MenuAction.help => showCameraTabHelpDialog(context),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _MenuAction.refresh,
                    child: Text(l10n.camTabMenuRefresh),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.help,
                    child: Text(l10n.camTabMenuHelp),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (reduceMotion)
          strip
        else
          AnimatedSize(
            duration: _stripDuration,
            alignment: Alignment.topCenter,
            child: strip,
          ),
      ],
    );
  }
}
