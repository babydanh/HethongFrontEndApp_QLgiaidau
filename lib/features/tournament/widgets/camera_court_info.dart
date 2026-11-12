import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_stream_stats_badge.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/camera_preview_provider.dart';
import 'package:app_quanly_giaidau/providers/tournament_match_livestreams_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dưới tên sân: "Camera: tên · Ping" cùng trận camera đang chiếu và nút ⏻
/// tắt/bật xem thử. Nút ⏻ chỉ ảnh hưởng máy này: không gọi Backend, camera vẫn
/// phát bình thường.
class CameraCourtInfo extends ConsumerWidget {
  const CameraCourtInfo({
    super.key,
    required this.tournamentId,
    required this.camera,
    required this.matches,
    required this.matchLabelOf,
  });

  final String tournamentId;
  final TournamentCameraModel camera;
  final List<MatchModel> matches;
  final String Function(MatchModel match) matchLabelOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final streams =
        ref
            .watch(tournamentMatchLivestreamsProvider(tournamentId))
            .asData
            ?.value ??
        const {};
    final previewOn = !ref.watch(cameraPreviewOffProvider).contains(camera.id);
    final showing = cameraMatch(
      camera: camera,
      matches: matches,
      livestreams: streams,
    );
    final name = camera.name.isEmpty ? camera.id : camera.name;
    final playbackUrl = camera.playbackUrl;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.camCourtCameraLine(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  if (playbackUrl != null &&
                      cameraSignal(camera) == CameraSignal.live) ...[
                    const SizedBox(width: AppTheme.spacingXS),
                    LiveStreamStatsBadge(url: playbackUrl),
                  ],
                ],
              ),
              if (showing != null)
                Text(
                  l10n.camCourtNowShowing(matchLabelOf(showing)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.camCourtPreviewToggle,
          constraints: const BoxConstraints.tightFor(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
          ),
          color: previewOn ? colors.success : colors.textMuted,
          onPressed: () =>
              ref.read(cameraPreviewOffProvider.notifier).toggle(camera.id),
          icon: const Icon(Icons.power_settings_new_rounded),
        ),
      ],
    );
  }
}
