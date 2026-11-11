import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kết quả một lần bấm Bắt đầu/Dừng, để UI chọn thông báo.
enum MatchStreamToggleKind {
  /// Không làm gì: đang gửi, chưa có camera hoặc chưa có trạng thái.
  ignored,
  started,
  stopped,

  /// Server 403: nút bị ẩn.
  permissionDenied,

  /// Lỗi 5xx: không thông báo (giống Web).
  silentFailure,
  failed,
}

class MatchStreamToggleResult {
  const MatchStreamToggleResult(
    this.kind, {
    this.recordingStatus,
    this.publishUrl,
    this.error,
  });

  final MatchStreamToggleKind kind;
  final MatchRecordingStatus? recordingStatus;
  final String? publishUrl;
  final Object? error;
}

class MatchStreamControlView {
  const MatchStreamControlView({this.control, this.isPending = false});

  /// Null: chưa đọc xong hoặc bị 403, nút ẩn.
  final MatchStreamControlStateModel? control;
  final bool isPending;

  bool get canToggle => control?.canToggleStream ?? false;
  bool get isLive => control?.streamStatus == MatchStreamStatus.live;
}

int? _statusCode(Object error) =>
    error is DioException ? error.response?.statusCode : null;

/// Điều khiển phát của một trận (hook `useMatchStreamControl` của Web).
class MatchStreamControlNotifier extends Notifier<MatchStreamControlView> {
  MatchStreamControlNotifier(this.matchId);

  final String matchId;
  int _requestId = 0;

  @override
  MatchStreamControlView build() {
    Future<void>.microtask(refresh);
    return const MatchStreamControlView();
  }

  /// Đọc lại control-state; 403 ẩn nút, lỗi khác giữ trạng thái đã xác nhận.
  Future<void> refresh() async {
    final requestId = ++_requestId;
    try {
      final control = await ref
          .read(matchRecordingCatalogRepositoryProvider)
          .getMatchControlState(matchId);
      if (!ref.mounted || requestId != _requestId) return;
      state = MatchStreamControlView(
        control: control,
        isPending: state.isPending,
      );
    } on Object catch (error) {
      if (!ref.mounted || requestId != _requestId) return;
      if (_statusCode(error) == 403) {
        state = MatchStreamControlView(isPending: state.isPending);
      }
    }
  }

  Future<MatchStreamToggleResult> toggle() async {
    final current = state.control;
    if (state.isPending || current == null || !current.canToggleStream) {
      return const MatchStreamToggleResult(MatchStreamToggleKind.ignored);
    }
    final stopping = state.isLive;
    final repository = ref.read(matchRecordingCatalogRepositoryProvider);
    state = MatchStreamControlView(control: current, isPending: true);
    try {
      final result = stopping
          ? await repository.stopMatchStream(matchId)
          : await repository.startMatchStream(matchId);
      // Video thuộc về trang, không thuộc về nút: gắn lại luồng cho mọi người xem.
      if (ref.mounted) ref.invalidate(matchPlaybackProvider(matchId));
      final confirmed = result.streamStatus;
      if (ref.mounted) {
        state = MatchStreamControlView(
          control: confirmed == null
              ? current
              : MatchStreamControlStateModel(
                  matchId: matchId,
                  hasCamera: true,
                  hasRecording: current.hasRecording,
                  streamStatus: confirmed,
                ),
        );
        // Thành công mà thiếu trạng thái thì không phải xác nhận: đọc lại.
        if (confirmed == null) await refresh();
      }
      return MatchStreamToggleResult(
        stopping ? MatchStreamToggleKind.stopped : MatchStreamToggleKind.started,
        recordingStatus: result.recordingStatus,
        publishUrl: result.publishUrl,
      );
    } on Object catch (error) {
      if (ref.mounted) {
        final denied = _statusCode(error) == 403;
        state = MatchStreamControlView(control: denied ? null : current);
      }
      final code = _statusCode(error) ?? 0;
      if (code == 403) {
        return MatchStreamToggleResult(
          MatchStreamToggleKind.permissionDenied,
          error: error,
        );
      }
      return MatchStreamToggleResult(
        code >= 500
            ? MatchStreamToggleKind.silentFailure
            : MatchStreamToggleKind.failed,
        error: error,
      );
    }
  }
}

final matchStreamControlProvider =
    NotifierProvider.family<
      MatchStreamControlNotifier,
      MatchStreamControlView,
      String
    >(MatchStreamControlNotifier.new);
