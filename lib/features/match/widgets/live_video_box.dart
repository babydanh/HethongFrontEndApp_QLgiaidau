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
  });

  final String matchId;

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
    final label = livePlayback?.cameraName;

    if (url != null) {
      // Chỉ dựng lại player khi URL thật sự đổi, tránh hủy và tạo lại
      // controller ở mỗi lần dựng lại giao diện.
      if (url != _resolvedFor) {
        _resolvedFor = url;
        _url = url;
      }
      return LiveVideoPlayer(
        url: _url!,
        label: label,
        showStreamStats: widget.showStreamStats,
        fill: widget.fill,
        fullscreen: widget.fullscreen,
        onToggleFullscreen: widget.onToggleFullscreen,
      );
    }

    _resolvedFor = null;
    _url = null;
    if (!playback.hasValue) return const _NoSignalBox();
    final replay = ref.watch(matchReplayProvider(widget.matchId));
    return replay.maybeWhen(
      data: (value) {
        if (value == null) return const _NoSignalBox();
        final player = MatchReplayPlayer(
          key: ValueKey<String>('match-replay-${value.matchId}'),
          replay: value,
        );
        return widget.fill ? _fitReplay(player) : player;
      },
      orElse: () => const _NoSignalBox(),
    );
  }
}

/// The replay is a column (label + 16:9 video + timeline). In a bounded
/// landscape box, narrow it so the whole column fits the height.
Widget _fitReplay(Widget player) {
  const chromeHeight = 140.0;
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = ((constraints.maxHeight - chromeHeight) * 16 / 9).clamp(
        160.0,
        constraints.maxWidth,
      );
      return Center(child: SizedBox(width: width, child: player));
    },
  );
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
