import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_stream_control_provider.dart';
import 'package:app_quanly_giaidau/providers/tournament_match_livestreams_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bắt đầu hoặc dừng phát một trận rồi báo kết quả bằng SnackBar. Cùng hành vi
/// với `MatchStreamActions` (Xem live / Bắt đầu / Dừng) nhưng gọi được từ menu
/// ⋯ của dòng trận gọn.
Future<void> toggleMatchStream(
  BuildContext context,
  WidgetRef ref, {
  required String tournamentId,
  required String matchId,
  required bool isLive,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref
      .read(tournamentMatchLivestreamsProvider(tournamentId).notifier)
      .toggle(matchId, isLive: isLive);

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
