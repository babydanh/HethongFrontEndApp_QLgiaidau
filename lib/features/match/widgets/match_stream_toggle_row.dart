import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_stream_control_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hàng "Trực tiếp" của trang chấm điểm: nút Bắt đầu (xanh) / Dừng (đỏ).
///
/// Chỉ hiện khi trận có camera và server nhận ra trạng thái phát; 403 ẩn nút.
class MatchStreamToggleRow extends ConsumerWidget {
  const MatchStreamToggleRow({
    super.key,
    required this.matchId,
    required this.matchLabel,
    this.compact = false,
  });

  final String matchId;
  final String matchLabel;

  /// Chỉ còn nút tròn (ngang màn hình thấp, hàng tiêu đề đã chật).
  final bool compact;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(matchStreamControlProvider(matchId).notifier)
        .toggle();
    String? message;
    switch (result.kind) {
      case MatchStreamToggleKind.permissionDenied:
        message = l10n.tournamentManagementCameraStreamPermissionDenied;
      case MatchStreamToggleKind.failed:
        message = ErrorParser.parse(
          result.error,
          l10n.tournamentManagementCameraStreamActionFailed,
          l10n,
        );
      case MatchStreamToggleKind.started || MatchStreamToggleKind.stopped:
        if (result.recordingStatus == MatchRecordingStatus.pending) {
          message = l10n.tournamentManagementCameraRecordingPending;
        }
      case MatchStreamToggleKind.ignored || MatchStreamToggleKind.silentFailure:
        break;
    }
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(matchStreamControlProvider(matchId));
    if (!view.canToggle) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final isLive = view.isLive;
    final label = isLive
        ? l10n.tournamentManagementCameraStreamStop
        : l10n.tournamentManagementCameraStreamStart;
    final aria = isLive
        ? l10n.tournamentManagementCameraStreamStopAria(matchLabel)
        : l10n.tournamentManagementCameraStreamStartAria(matchLabel);
    final colors = context.colors;
    final accent = isLive ? const Color(0xFFE11D48) : const Color(0xFF059669);
    if (compact) {
      return IconButton(
        tooltip: aria,
        onPressed: view.isPending ? null : () => _toggle(context, ref),
        style: IconButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(44, 30),
        ),
        icon: view.isPending
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isLive ? Icons.stop_circle_rounded : Icons.videocam_rounded),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.tournamentManagementCameraStreamTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
          Semantics(
            button: true,
            toggled: isLive,
            label: aria,
            excludeSemantics: true,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(96, 44),
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
              onPressed: view.isPending ? null : () => _toggle(context, ref),
              icon: view.isPending
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isLive ? Icons.stop_rounded : Icons.videocam_rounded,
                      size: 18,
                    ),
              label: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
