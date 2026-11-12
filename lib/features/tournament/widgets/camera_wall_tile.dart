import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_player.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Dựng trình phát cho [url]; test thay bằng widget giả để khỏi chạm plugin.
typedef CameraPlayerBuilder = Widget Function(BuildContext context, String url);

Widget defaultCameraPlayer(BuildContext context, String url) =>
    LiveVideoPlayer(url: url, fill: true);

/// Một ô của tường camera: tên + sân, huy hiệu tín hiệu, hình (chỉ khi LIVE và
/// còn bật xem thử), công tắc xem thử và dòng trận. Không hiện tỉ số.
class CameraWallTile extends StatelessWidget {
  const CameraWallTile({
    super.key,
    required this.camera,
    required this.courtName,
    required this.matchLine,
    required this.previewOn,
    required this.onPreviewChanged,
    required this.onRetry,
    required this.onDoubleTap,
    this.playerBuilder = defaultCameraPlayer,
  });

  final TournamentCameraModel camera;
  final String? courtName;
  final String matchLine;
  final bool previewOn;
  final ValueChanged<bool> onPreviewChanged;
  final VoidCallback onRetry;

  /// Chạm đôi vào tên hoặc hình để phóng 1×1. Hàng công tắc nằm ngoài vùng
  /// này: bọc cả ô thì chạm công tắc bị trễ chờ phân biệt với chạm đôi.
  final VoidCallback onDoubleTap;
  final CameraPlayerBuilder playerBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final signal = cameraSignal(camera);
    final court = (courtName == null || courtName!.isEmpty)
        ? l10n.camWallNoCourt
        : courtName!;
    final name = camera.name.isEmpty ? camera.id : camera.name;
    final mount = shouldMountPlayer(camera, previewOn);
    final playbackUrl = camera.playbackUrl;

    return Container(
      color: colors.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: onDoubleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$name · $court',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _SignalBadge(signal: signal, status: camera.status),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onDoubleTap: onDoubleTap,
                  child: ColoredBox(
                    color: Colors.black,
                    child: mount && playbackUrl != null
                        ? playerBuilder(context, playbackUrl)
                        : const Center(
                            child: Icon(
                              Icons.videocam_off_outlined,
                              color: Colors.white38,
                            ),
                          ),
                  ),
                ),
                // Ngoài vùng chạm đôi để bấm Thử lại không bị trễ.
                if (signal == CameraSignal.failed)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(l10n.camWallRetry),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    matchLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
                Tooltip(
                  message: l10n.camWallPreviewHint,
                  child: Text(
                    l10n.camWallPreview,
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ),
                Switch(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: previewOn,
                  onChanged: onPreviewChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBadge extends StatelessWidget {
  const _SignalBadge({required this.signal, required this.status});

  final CameraSignal signal;
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final (label, tone) = switch (signal) {
      CameraSignal.live => (l10n.camWallSignalLive, colors.success),
      CameraSignal.connecting => (l10n.camWallSignalConnecting, colors.warning),
      CameraSignal.failed => (
        status == 'ERROR' ? l10n.camWallSignalError : l10n.camWallSignalOffline,
        colors.error,
      ),
      CameraSignal.idle => (l10n.camWallSignalIdle, colors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
