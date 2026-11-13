import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_match_filter.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_search_pill.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_tab_help_dialog.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum _MenuAction { streaming, refresh, help }

const _swapDuration = Duration(milliseconds: 180);

/// Đầu tab Camera: một hàng chỉ icon (tìm, tạo camera, xem camera, menu ⋯).
/// Bấm tìm thì [CameraSearchPill] thay chính hàng đó (phễu lọc nằm trong viên);
/// chặng (bảng/lượt/playoff) / "Chưa có cam" đang lọc hiện thành một dòng thẻ
/// nhỏ bên dưới.
/// [cameras] null nghĩa là danh sách chưa tải xong — chưa có số thì không in
/// số, tránh khẳng định "0 cam" khi đang tải. [onCreateCamera] null thì ẩn nút
/// ＋ (tab chỉ xem). [onOpenStreaming] null thì menu ⋯ không có mục
/// "Điện thoại & phiên phát".
class CameraTabHeader extends StatefulWidget {
  const CameraTabHeader({
    super.key,
    required this.cameras,
    required this.filter,
    required this.stages,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onWatchCameras,
    this.onCreateCamera,
    this.onOpenStreaming,
  });

  final List<TournamentCameraModel>? cameras;
  final CameraMatchFilter filter;
  final List<CameraStage> stages;
  final ValueChanged<CameraMatchFilter> onFilterChanged;
  final VoidCallback onRefresh;
  final VoidCallback onWatchCameras;
  final VoidCallback? onCreateCamera;
  final VoidCallback? onOpenStreaming;

  @override
  State<CameraTabHeader> createState() => _CameraTabHeaderState();
}

class _CameraTabHeaderState extends State<CameraTabHeader> {
  bool _searchOpen = false;

  /// Đóng viên thuốc: bỏ chữ tìm, giữ lọc vòng / "Chưa có cam" (còn thấy ở
  /// dòng thẻ bên dưới).
  void _closeSearch() {
    if (widget.filter.query.isNotEmpty) {
      widget.onFilterChanged(widget.filter.copyWith(query: ''));
    }
    setState(() => _searchOpen = false);
  }

  Widget _iconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) => IconButton(
    tooltip: tooltip,
    constraints: const BoxConstraints.tightFor(
      width: kMinTouchTarget,
      height: kMinTouchTarget,
    ),
    onPressed: onPressed,
    icon: Icon(icon),
  );

  Widget _titleRow(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    final list = widget.cameras;
    final summary = list == null ? null : cameraSummary(list);
    return Row(
      key: const ValueKey('camTabTitleRow'),
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
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
        _iconButton(
          tooltip: l10n.camTabSearchTooltip,
          icon: Icons.search_rounded,
          onPressed: () => setState(() => _searchOpen = true),
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
            _MenuAction.streaming => widget.onOpenStreaming?.call(),
            _MenuAction.refresh => widget.onRefresh(),
            _MenuAction.help => showCameraTabHelpDialog(context),
          },
          itemBuilder: (_) => [
            if (widget.onOpenStreaming != null)
              PopupMenuItem(
                key: const ValueKey('camTabMenuStreaming'),
                value: _MenuAction.streaming,
                child: Text(l10n.camTabMenuStreaming),
              ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final row = _searchOpen
        ? CameraSearchPill(
            key: const ValueKey('camTabPillRow'),
            filter: widget.filter,
            stages: widget.stages,
            onChanged: widget.onFilterChanged,
            onClose: _closeSearch,
          )
        : _titleRow(context, l10n);
    final tags = _FilterTags(
      filter: widget.filter,
      onChanged: widget.onFilterChanged,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: kMinTouchTarget,
          child: reduceMotion
              ? row
              : AnimatedSwitcher(duration: _swapDuration, child: row),
        ),
        if (reduceMotion)
          tags
        else
          AnimatedSize(
            duration: _swapDuration,
            alignment: Alignment.topCenter,
            child: tags,
          ),
      ],
    );
  }
}

/// Một dòng thẻ nhỏ cuộn ngang cho lọc chặng / "Chưa có cam"; không lọc thì
/// không chiếm chỗ. Bấm ✕ trên thẻ bỏ đúng lọc đó.
class _FilterTags extends StatelessWidget {
  const _FilterTags({required this.filter, required this.onChanged});

  final CameraMatchFilter filter;
  final ValueChanged<CameraMatchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final stage = filter.stage;
    if (stage == null && !filter.onlyNoCamera) {
      return const SizedBox(width: double.infinity);
    }
    final l10n = AppLocalizations.of(context)!;
    Widget tag(Key key, String label, VoidCallback onRemove) => Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingXS),
      child: InputChip(
        key: key,
        label: Text(label),
        visualDensity: VisualDensity.compact,
        deleteIcon: const Icon(Icons.close_rounded, size: 16),
        onDeleted: onRemove,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (stage != null)
              tag(
                const ValueKey('camTabTagStage'),
                stage,
                () => onChanged(filter.copyWith(stage: () => null)),
              ),
            if (filter.onlyNoCamera)
              tag(
                const ValueKey('camTabTagNoCamera'),
                l10n.camTabNoCamera,
                () => onChanged(filter.copyWith(onlyNoCamera: false)),
              ),
          ],
        ),
      ),
    );
  }
}
