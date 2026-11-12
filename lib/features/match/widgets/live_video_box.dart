import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_player.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_replay_player.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final matchPlaybackProvider = FutureProvider.family<MatchPlaybackModel?, String>((
  ref,
  matchId,
) async {
  final repository = ref.watch(matchPlaybackRepositoryProvider);
  try {
    final playback = await repository.getMatchPlayback(matchId);
    return playback.hasStream ? playback : null;
  } on Object {
    // Trận chưa gán camera, sân chưa khai URL, hoặc backend lỗi — đều hiển thị
    // khung "chưa có tín hiệu" thay vì làm hỏng cả màn hình.
    return null;
  }
});

final matchReplayProvider = FutureProvider.family<MatchReplay?, String>((
  ref,
  matchId,
) async {
  final repository = ref.watch(matchPlaybackRepositoryProvider);
  // Ask again when the live stream appears or goes: an earlier "no recording
  // yet" answer must not stick once the match has moved on.
  ref.watch(
    matchPlaybackProvider(matchId).select((v) => v.asData?.value?.playbackUrl),
  );
  try {
    final replay = await repository.getMatchReplay(matchId);
    return replay.available && replay.segments.isNotEmpty ? replay : null;
  } on Object {
    return null;
  }
});

/// Khung video của trận: phát luồng trực tiếp hoặc bản ghi khi có sẵn.
///
/// Luồng live vẫn lấy từ `playback`; bản ghi chỉ được truy vấn khi chưa có URL
/// live và được phát trực tiếp từ các URL HTTPS do Backend trả về.
class LiveVideoBox extends ConsumerStatefulWidget {
  const LiveVideoBox({
    super.key,
    required this.matchId,
    this.showStreamStats = false,
    this.fill = false,
    this.fullscreen = false,
    this.onToggleFullscreen,
    this.showLiveDot = false,
    this.onControlsVisibleChanged,
    this.onAspectRatioChanged,
    this.onReplayPositionChanged,
    this.preferReplay = false,
    this.onToggleReplay,
  });

  final String matchId;

  /// Forwarded to whichever player shows: true while its control bar is up.
  final ValueChanged<bool>? onControlsVisibleChanged;

  /// Forwarded to the live player: the stream's real width / height.
  final ValueChanged<double>? onAspectRatioChanged;

  /// Forwarded to the replay player: the whole-match timeline second.
  final ValueChanged<int>? onReplayPositionChanged;

  /// With a live stream AND a recording, the viewer picks which one plays. The
  /// button only exists when [onToggleReplay] is given.
  final bool preferReplay;
  final VoidCallback? onToggleReplay;

  /// Forwarded to the live player: red LIVE dot beside the sound button.
  final bool showLiveDot;

  /// Fill the parent's bounded height (landscape fullscreen) instead of sizing
  /// by aspect ratio.
  final bool fill;

  /// Fullscreen state and toggle, forwarded to the live player's controls.
  final bool fullscreen;
  final VoidCallback? onToggleFullscreen;

  /// Bật huy hiệu thông số luồng (chỉ owner/admin, do màn live quyết định).
  final bool showStreamStats;

  @override
  ConsumerState<LiveVideoBox> createState() => _LiveVideoBoxState();
}

class _LiveVideoBoxState extends ConsumerState<LiveVideoBox> {
  String? _resolvedFor;
  String? _url;

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(matchPlaybackProvider(widget.matchId));
    final livePlayback = playback.asData?.value;
    final url = livePlayback?.playbackUrl;
    final replay = ref
        .watch(matchReplayProvider(widget.matchId))
        .asData
        ?.value;

    final canToggle =
        url != null && replay != null && widget.onToggleReplay != null;
    if (url != null && !(canToggle && widget.preferReplay)) {
      // Chỉ dựng lại player khi URL thật sự đổi, tránh hủy và tạo lại
      // controller ở mỗi lần dựng lại giao diện.
      if (url != _resolvedFor) {
        _resolvedFor = url;
        _url = url;
      }
      final live = LiveVideoPlayer(
        url: _url!,
        label: livePlayback?.cameraName,
        showStreamStats: widget.showStreamStats,
        fill: widget.fill,
        fullscreen: widget.fullscreen,
        onToggleFullscreen: widget.onToggleFullscreen,
        showLiveDot: widget.showLiveDot,
        onControlsVisibleChanged: widget.onControlsVisibleChanged,
        onAspectRatioChanged: widget.onAspectRatioChanged,
      );
      return canToggle ? _withToggle(live, replayShown: false) : live;
    }

    _resolvedFor = null;
    _url = null;
    if (url == null && !playback.hasValue) return const _NoSignalBox();
    if (replay == null) return const _NoSignalBox();
    final player = MatchReplayPlayer(
      key: ValueKey<String>('match-replay-${replay.matchId}'),
      replay: replay,
      fullscreen: widget.fullscreen,
      onToggleFullscreen: widget.onToggleFullscreen,
      onControlsVisibleChanged: widget.onControlsVisibleChanged,
      onPositionChanged: widget.onReplayPositionChanged,
    );
    // The player keeps its own 16:9 shape; the page aligns it.
    return canToggle ? _withToggle(player, replayShown: true) : player;
  }

  Widget _withToggle(Widget child, {required bool replayShown}) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black54,
            shape: const StadiumBorder(),
            child: InkWell(
              key: const ValueKey<String>('live-replay-toggle'),
              customBorder: const StadiumBorder(),
              onTap: widget.onToggleReplay,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  replayShown ? l10n.liveBackToLive : l10n.liveWatchRecording,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoSignalBox extends StatelessWidget {
  const _NoSignalBox();

  @override
  Widget build(BuildContext context) {
    // Cùng tỉ lệ dự phòng với LiveVideoPlayer: không có khung tỉ lệ thì khung
    // chỉ cao vừa icon + chữ, bảng điểm và nhãn camera đè lên nhau.
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_outlined,
              color: Colors.white24,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.liveNoSignalLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
