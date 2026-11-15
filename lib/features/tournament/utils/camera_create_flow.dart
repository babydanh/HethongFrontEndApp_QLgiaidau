import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/participant_row_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_editor_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/facebook_live_ready_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/stream_key_qr_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Luồng "Tạo camera" dùng chung cho tab Livestream và tab Camera: mở
/// [CameraEditorSheet], tạo camera, làm mới danh sách, báo snackbar, rồi mở
/// popup QR stream key khi camera là PUSH (như Web `handleCreateCamera`), hoặc
/// sheet "Camera đã sẵn sàng" khi camera vừa tạo bằng nút live Facebook một chạm.
Future<void> runCreateCameraFlow({
  required BuildContext context,
  required WidgetRef ref,
  required String tournamentId,
  required List<TournamentCourtRef> courts,
  required Future<void> Function() refresh,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  TournamentCameraModel? created;
  CameraEditorValue? submitted;
  final saved = await CameraEditorSheet.show(
    context,
    courts: courts,
    facebookLiveTournamentId: tournamentId,
    facebookLiveRepository: ref.read(facebookCameraLiveRepositoryProvider),
    onSubmit: (value) async {
      created = await ref
          .read(cameraAdminRepositoryProvider)
          .createCamera(
            tournamentId: tournamentId,
            name: value.name,
            mode: value.mode,
            courtId: value.courtId,
            playbackUrl: value.playbackUrl,
          );
      submitted = value;
      // The camera exists now: a failing refresh must not make onSubmit throw,
      // or the sheet would stay open and a retry would create a second camera.
      try {
        await refresh();
      } on Object {
        // The list refreshes on the next load; the camera itself was saved.
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.tournamentCameraCreated(value.name))),
        );
    },
  );
  final camera = created;
  final value = submitted;
  if (saved != true || camera == null || value == null || !context.mounted) {
    return;
  }
  final live = value.facebookLive;
  if (live != null) {
    await FacebookLiveReadySheet.show(
      context,
      live: live,
      cameraName: value.name,
    );
    return;
  }
  if (!shouldOpenStreamKeyAfterCreate(camera.mode)) return;
  await StreamKeyQrSheet.show(context, camera: camera);
}
