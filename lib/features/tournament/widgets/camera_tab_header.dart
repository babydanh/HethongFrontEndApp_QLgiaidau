import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_tab_help_dialog.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Đầu tab Camera: tiêu đề, nút "?" hướng dẫn, làm mới, "Xem camera" (ẩn khi
/// chưa có camera) và dòng tóm tắt. [cameras] null nghĩa là danh sách chưa tải
/// xong — chưa có số thì không in số, tránh khẳng định "0 camera" khi đang tải.
class CameraTabHeader extends StatelessWidget {
  const CameraTabHeader({
    super.key,
    required this.cameras,
    required this.onRefresh,
    required this.onWatchCameras,
  });

  final List<TournamentCameraModel>? cameras;
  final VoidCallback onRefresh;
  final VoidCallback onWatchCameras;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final list = cameras;
    final summary = list == null ? null : cameraSummary(list);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                l10n.camTabTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.camTabHelpTooltip,
              constraints: const BoxConstraints.tightFor(
                width: kMinTouchTarget,
                height: kMinTouchTarget,
              ),
              onPressed: () => showCameraTabHelpDialog(context),
              icon: const Icon(Icons.help_outline_rounded),
            ),
            const Spacer(),
            IconButton(
              tooltip: l10n.tournamentManagementCameraRefresh,
              constraints: const BoxConstraints.tightFor(
                width: kMinTouchTarget,
                height: kMinTouchTarget,
              ),
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            if (list != null && list.isNotEmpty)
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, kMinTouchTarget),
                ),
                onPressed: onWatchCameras,
                icon: const Icon(Icons.videocam_outlined),
                label: Text(l10n.camTabWatchCameras),
              ),
          ],
        ),
        if (summary != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
            child: Text(
              l10n.camTabSummary(summary.total, summary.live, summary.failing),
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
      ],
    );
  }
}
