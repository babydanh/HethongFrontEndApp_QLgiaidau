import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_playback_repository.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_player.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final matchPlaybackProvider =
    FutureProvider.family<MatchPlaybackModel?, String>((ref, matchId) async {
  final client = ref.watch(dioClientProvider);
  final repository = ApiMatchPlaybackRepository(client);
  try {
    final playback = await repository.getMatchPlayback(matchId);
    return playback.hasStream ? playback : null;
  } on Object {
    // Trận chưa gán camera, sân chưa khai URL, hoặc backend lỗi — đều hiển thị
    // khung "chưa có tín hiệu" thay vì làm hỏng cả màn hình.
    return null;
  }
});

/// Khung video của trận trực tiếp: tự lấy URL phát rồi hiển thị.
///
/// Không dựng URL từ stream key — luôn đọc từ `playback` của backend để khi
/// sân đổi giao thức phát (FLV sang HLS) thì app không phải sửa.
class LiveVideoBox extends ConsumerStatefulWidget {
  const LiveVideoBox({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<LiveVideoBox> createState() => _LiveVideoBoxState();
}

class _LiveVideoBoxState extends ConsumerState<LiveVideoBox> {
  String? _resolvedFor;
  String? _url;

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(matchPlaybackProvider(widget.matchId));
    final url = playback.maybeWhen(
      data: (value) => value?.playbackUrl,
      orElse: () => null,
    );
    final label = playback.maybeWhen(
      data: (value) => value?.cameraName,
      orElse: () => null,
    );

    // Chỉ dựng lại player khi URL thật sự đổi, tránh hủy và tạo lại
    // controller ở mỗi lần dựng lại giao diện.
    if (url != null && url != _resolvedFor) {
      _resolvedFor = url;
      _url = url;
    }
    if (url == null && _resolvedFor != null) {
      _resolvedFor = null;
      _url = null;
    }

    if (_url == null) {
      return const _NoSignalBox();
    }
    return LiveVideoPlayer(url: _url!, label: label);
  }
}

class _NoSignalBox extends StatelessWidget {
  const _NoSignalBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_outlined, color: Colors.white24, size: 36),
          const SizedBox(height: 10),
          Text(
            'Chưa có tín hiệu phát trực tiếp',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
