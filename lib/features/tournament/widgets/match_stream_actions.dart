import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/recording_access.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/match_recording_player_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_stream_control_provider.dart';
import 'package:app_quanly_giaidau/providers/tournament_match_livestreams_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const double _kActionHeight = 44;

/// Xem live / Bắt đầu / Dừng / Xem bản ghi MP4 của một trận ở bảng camera
/// (`MatchCard` của `CourtCameraBoard` trên Web).
class MatchStreamActions extends ConsumerStatefulWidget {
  const MatchStreamActions({
    super.key,
    required this.tournamentId,
    required this.matchId,
    required this.matchLabel,
    required this.hasCamera,
    this.readOnly = false,
    this.onWatchLive,
  });

  final String tournamentId;
  final String matchId;
  final String matchLabel;

  /// Trận có camera gán riêng hoặc sân của trận có URL camera.
  final bool hasCamera;

  /// Giải chỉ-đọc: bỏ Bắt đầu/Dừng, vẫn xem live và bản ghi.
  final bool readOnly;

  /// Mặc định mở `/live/{matchId}`.
  final VoidCallback? onWatchLive;

  @override
  ConsumerState<MatchStreamActions> createState() => _MatchStreamActionsState();
}

class _MatchStreamActionsState extends ConsumerState<MatchStreamActions> {
  bool _busy = false;

  Future<void> _toggle(bool isLive) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await ref
        .read(tournamentMatchLivestreamsProvider(widget.tournamentId).notifier)
        .toggle(widget.matchId, isLive: isLive);
    if (mounted) setState(() => _busy = false);

    final messages = <String>[];
    switch (result.kind) {
      case MatchStreamToggleKind.started:
        final url = result.publishUrl;
        if (url != null) {
          await Clipboard.setData(ClipboardData(text: url));
          messages.add(l10n.tournamentManagementCameraStreamPublishLinkCreated);
        } else {
          messages.add(l10n.tournamentManagementCameraStreamStartedFromUrl);
        }
      case MatchStreamToggleKind.stopped:
        messages.add(l10n.tournamentManagementCameraStreamStopped);
      case MatchStreamToggleKind.permissionDenied:
        messages.add(l10n.tournamentManagementCameraStreamPermissionDenied);
      case MatchStreamToggleKind.failed || MatchStreamToggleKind.silentFailure:
        messages.add(
          ErrorParser.parse(
            result.error,
            l10n.tournamentManagementCameraStreamActionFailed,
            l10n,
          ),
        );
      case MatchStreamToggleKind.ignored:
        break;
    }
    if (result.recordingStatus == MatchRecordingStatus.pending) {
      messages.add(l10n.tournamentManagementCameraRecordingPending);
    }
    if (messages.isEmpty) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(messages.join('\n'))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(
      tournamentMatchLivestreamsProvider(
        widget.tournamentId,
      ).select((rows) => rows.asData?.value[widget.matchId]),
    );
    final isLive = summary?.isLive ?? false;
    final hasCamera = widget.hasCamera || (summary?.hasCamera ?? false);
    final label = widget.matchLabel;
    const size = Size(0, _kActionHeight);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: size),
          onPressed: _busy
              ? null
              : (widget.onWatchLive ??
                    () => context.push('/live/${widget.matchId}')),
          child: Semantics(
            label: l10n.tournamentManagementCameraStreamWatchLiveAria(label),
            excludeSemantics: true,
            child: Text(l10n.tournamentManagementCameraStreamWatchLive),
          ),
        ),
        if (!widget.readOnly)
          if (isLive)
            Tooltip(
              message: l10n.tournamentManagementCameraStreamStop,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: size,
                  foregroundColor: const Color(0xFFE11D48),
                  side: const BorderSide(color: Color(0xFFE11D48)),
                ),
                onPressed: _busy ? null : () => _toggle(true),
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: Text(l10n.tournamentManagementCameraStreamStop),
              ),
            )
          else
            Tooltip(
              message: hasCamera
                  ? l10n.tournamentManagementCameraStreamStart
                  : l10n.tournamentManagementCameraStreamNeedsCamera,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: size),
                onPressed: _busy || !hasCamera ? null : () => _toggle(false),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(l10n.tournamentManagementCameraStreamStart),
              ),
            ),
        if (!isLive &&
            canShowRecordingButton(
              hasCamera: hasCamera,
              hasRecording: summary?.hasRecording,
            ))
          Tooltip(
            message: l10n.tournamentManagementRecordingOpen,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: size),
              onPressed: _busy
                  ? null
                  : () => showMatchRecordingPlayerSheet(
                      context,
                      matchId: widget.matchId,
                    ),
              icon: const Icon(Icons.video_library_outlined, size: 18),
              label: const Text('MP4'),
            ),
          ),
      ],
    );
  }
}
