import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/match_recording_playback_plan.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Mở trình phát bản ghi nối tiếp của một ngày.
Future<void> showMatchRecordingPlayerSheet(
  BuildContext context, {
  required String matchId,
  required String period,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MatchRecordingPlayerSheet(matchId: matchId, period: period),
  );
}

/// Phát nối tiếp các đoạn bản ghi của một ngày theo thứ tự server.
///
/// Đoạn kế được nạp sẵn khi đoạn hiện tại đang phát. Khi đoạn hiện tại kết thúc
/// (`position >= duration`) thì chuyển sang đoạn kế. Đoạn lỗi bị bỏ qua, không
/// dừng cả chuỗi.
class MatchRecordingPlayerSheet extends ConsumerStatefulWidget {
  const MatchRecordingPlayerSheet({
    super.key,
    required this.matchId,
    required this.period,
  });

  final String matchId;
  final String period;

  @override
  ConsumerState<MatchRecordingPlayerSheet> createState() =>
      _MatchRecordingPlayerSheetState();
}

class _MatchRecordingPlayerSheetState
    extends ConsumerState<MatchRecordingPlayerSheet> {
  bool _loading = true;
  bool _loadError = false;
  List<MatchRecordingSegment> _segments = const <MatchRecordingSegment>[];
  MatchRecordingPlaybackPlan _plan = MatchRecordingPlaybackPlan(
    segmentCount: 0,
  );

  // Tăng khi nạp lại hoặc khi người dùng chọn đoạn khác: thao tác cũ tự bỏ.
  int _epoch = 0;
  VideoPlayerController? _current;
  int? _currentIndex;
  ({int index, Future<VideoPlayerController?> controller})? _prepared;
  bool _opening = false;
  bool _advancing = false;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _epoch++;
    _disposePrepared();
    _stopCurrent();
    super.dispose();
  }

  bool _isCurrent(int epoch) => mounted && epoch == _epoch;

  Future<void> _load() async {
    final epoch = ++_epoch;
    _disposePrepared();
    _stopCurrent();
    setState(() {
      _loading = true;
      _loadError = false;
      _segments = const <MatchRecordingSegment>[];
    });

    final MatchRecordingPlaylist playlist;
    try {
      playlist = await ref
          .read(matchRecordingCatalogRepositoryProvider)
          .getPlaylist(widget.matchId, period: widget.period);
    } on Object {
      if (!_isCurrent(epoch)) return;
      setState(() {
        _loading = false;
        _loadError = true;
      });
      return;
    }
    if (!_isCurrent(epoch)) return;

    _plan = MatchRecordingPlaybackPlan(segmentCount: playlist.segments.length);
    setState(() {
      _loading = false;
      _segments = playlist.segments;
    });
    final first = _plan.nextAfter(-1);
    if (first != null) await _play(first, epoch);
  }

  /// Mở đoạn [index] rồi phát. Đoạn không mở được thì thử đoạn chưa lỗi kế tiếp.
  Future<void> _play(int index, int epoch) async {
    if (!_isCurrent(epoch)) return;
    setState(() => _opening = true);

    var candidate = index;
    while (true) {
      final controller = await _take(candidate, epoch);
      if (!_isCurrent(epoch)) {
        await controller?.dispose();
        return;
      }
      if (controller != null) {
        await _show(controller, candidate, epoch);
        return;
      }
      final next = _plan.nextAfter(candidate);
      if (next == null) break;
      candidate = next;
    }

    // Không còn đoạn nào từ vị trí này trở đi mở được.
    _stopCurrent();
    setState(() {});
  }

  Future<void> _show(
    VideoPlayerController controller,
    int index,
    int epoch,
  ) async {
    controller.addListener(() => _onValueChanged(controller));
    final previous = _current;
    setState(() {
      _current = controller;
      _currentIndex = index;
      _opening = false;
      _ended = false;
    });
    _advancing = false;
    if (previous != null) unawaited(previous.dispose());

    await controller.play();
    if (!_isCurrent(epoch)) return;
    _prepare(_plan.nextAfter(index), epoch);
  }

  void _onValueChanged(VideoPlayerController controller) {
    if (!mounted || !identical(controller, _current) || _opening) return;
    final value = controller.value;
    final finished =
        value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration;
    if (!finished || _advancing || _ended) return;
    _advancing = true;
    unawaited(_advance());
  }

  Future<void> _advance() async {
    final epoch = _epoch;
    final index = _currentIndex;
    final next = index == null ? null : _plan.nextAfter(index);
    if (next == null) {
      // Hết đoạn: giữ khung cuối, người dùng có thể phát lại đoạn này.
      _advancing = false;
      setState(() => _ended = true);
      return;
    }
    await _play(next, epoch);
    if (_isCurrent(epoch)) _advancing = false;
  }

  /// Người dùng chọn đoạn trong danh sách.
  void _jump(int index) {
    if (_plan.isFailed(index)) return;
    final epoch = ++_epoch;
    _disposePrepared();
    _advancing = false;
    _ended = false;
    final current = _current;
    // Tạm dừng đoạn cũ để nó không kết thúc trong lúc mở đoạn mới.
    if (current != null) unawaited(current.pause());
    unawaited(_play(index, epoch));
  }

  void _togglePlay() {
    final controller = _current;
    if (controller == null) return;
    if (_ended) {
      final index = _currentIndex;
      if (index != null) _jump(index);
      return;
    }
    if (controller.value.isPlaying) {
      unawaited(controller.pause());
    } else {
      unawaited(controller.play());
    }
  }

  Future<VideoPlayerController?> _take(int index, int epoch) {
    final prepared = _prepared;
    if (prepared != null && prepared.index == index) {
      _prepared = null;
      return prepared.controller;
    }
    _disposePrepared();
    return _open(index, epoch);
  }

  /// Tạo và khởi tạo controller cho đoạn [index]. Lỗi thì đánh dấu đoạn đó lỗi
  /// và trả null. Controller tạo xong nhưng đã bị bỏ qua thì tự dispose.
  Future<VideoPlayerController?> _open(int index, int epoch) async {
    final plan = _plan;
    final controller = VideoPlayerController.networkUrl(_segments[index].url);
    try {
      await controller.initialize();
      await controller.setLooping(false);
    } on Object {
      // dispose() của video_player chờ initialize xong; khi create() đã lỗi thì
      // future đó không bao giờ hoàn thành, nên không await để còn đánh dấu lỗi.
      unawaited(controller.dispose());
      if (mounted && identical(plan, _plan)) {
        plan.markFailed(index);
        setState(() {});
      }
      return null;
    }
    if (!_isCurrent(epoch)) {
      await controller.dispose();
      return null;
    }
    return controller;
  }

  void _prepare(int? index, int epoch) {
    _disposePrepared();
    if (index == null) return;
    _prepared = (index: index, controller: _open(index, epoch));
  }

  void _disposePrepared() {
    final prepared = _prepared;
    _prepared = null;
    if (prepared == null) return;
    unawaited(
      prepared.controller.then<void>((controller) async {
        await controller?.dispose();
      }),
    );
  }

  void _stopCurrent() {
    final current = _current;
    _current = null;
    _currentIndex = null;
    _opening = false;
    _advancing = false;
    _ended = false;
    if (current != null) unawaited(current.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.recordingPlayerTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        widget.period,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSM),
            _buildVideo(l10n),
            _buildControls(l10n),
            const Divider(height: AppTheme.spacingLG),
            Text(
              l10n.recordingPlayerSegments,
              style: theme.textTheme.titleSmall,
            ),
            _buildSegments(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo(AppLocalizations l10n) {
    final controller = _current;
    final Widget content;
    if (_loading) {
      content = _StatusMessage(
        message: l10n.recordingPlayerLoading,
        showSpinner: true,
      );
    } else if (_loadError) {
      content = _StatusMessage(
        message: l10n.recordingPlayerLoadError,
        action: TextButton(
          onPressed: () => unawaited(_load()),
          child: Text(l10n.opsRetry),
        ),
      );
    } else if (_segments.isEmpty) {
      content = _StatusMessage(message: l10n.recordingPlayerEmpty);
    } else if (controller != null) {
      content = ValueListenableBuilder<VideoPlayerValue>(
        key: ValueKey(controller),
        valueListenable: controller,
        builder: (context, value, _) {
          if (!value.isInitialized) {
            return _StatusMessage(
              message: l10n.recordingPlayerOpening,
              showSpinner: true,
            );
          }
          return Center(
            child: AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          );
        },
      );
    } else if (_plan.allFailed) {
      content = _StatusMessage(message: l10n.recordingPlayerAllFailed);
    } else if (_opening) {
      content = _StatusMessage(
        message: l10n.recordingPlayerOpening,
        showSpinner: true,
      );
    } else {
      content = _StatusMessage(message: l10n.recordingPlayerPickSegment);
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(color: Colors.black, child: content),
    );
  }

  Widget _buildControls(AppLocalizations l10n) {
    final controller = _current;
    final index = _currentIndex;
    final name = index == null ? '' : _segments[index].name;
    final Widget toggle;
    if (controller == null) {
      toggle = IconButton(
        tooltip: l10n.recordingPlayerPlay,
        onPressed: null,
        icon: const Icon(Icons.play_arrow_rounded),
      );
    } else {
      toggle = ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final IconData icon;
          final String tooltip;
          if (value.isPlaying) {
            icon = Icons.pause_rounded;
            tooltip = l10n.recordingPlayerPause;
          } else if (_ended) {
            icon = Icons.replay_rounded;
            tooltip = l10n.recordingPlayerPlay;
          } else {
            icon = Icons.play_arrow_rounded;
            tooltip = l10n.recordingPlayerPlay;
          }
          return IconButton(
            tooltip: tooltip,
            onPressed: _togglePlay,
            icon: Icon(icon),
          );
        },
      );
    }
    return Row(
      children: [
        toggle,
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildSegments(AppLocalizations l10n) {
    if (_loading || _loadError || _segments.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _segments.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final segment = _segments[index];
        final failed = _plan.isFailed(index);
        final selected = index == _currentIndex;
        final startAt = segment.startAt;
        final IconData icon;
        if (failed) {
          icon = Icons.error_outline_rounded;
        } else if (selected) {
          icon = Icons.play_circle_rounded;
        } else {
          icon = Icons.video_file_outlined;
        }
        final Widget? subtitle;
        if (failed) {
          subtitle = Text(l10n.recordingPlayerSegmentFailed);
        } else if (startAt != null) {
          subtitle = Text(
            segment.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        } else {
          subtitle = null;
        }
        return ListTile(
          contentPadding: EdgeInsets.zero,
          selected: selected,
          enabled: !failed,
          leading: ExcludeSemantics(child: Icon(icon)),
          title: Text(
            startAt == null
                ? segment.name
                : DateFormatterUtils.formatTime(startAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle,
          onTap: failed ? null : () => _jump(index),
        );
      },
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.message,
    this.showSpinner = false,
    this.action,
  });

  final String message;
  final bool showSpinner;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const CircularProgressIndicator(color: Colors.white),
            if (showSpinner) const SizedBox(height: AppTheme.spacingSM),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
