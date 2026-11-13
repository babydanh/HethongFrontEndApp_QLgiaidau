import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_status_badge.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Thẻ sân thu gọn: tên sân và trạng thái camera, không có gì khác. Bấm thẻ
/// mở popup sân ([showCourtCameraPopup]), nơi có URL phát và danh sách trận.
///
/// [camera] null nghĩa là sân chưa có camera ("Chưa gắn camera").
class CourtCameraCard extends StatelessWidget {
  const CourtCameraCard({
    super.key,
    required this.title,
    required this.camera,
    required this.onTap,
  });

  final String title;
  final TournamentCameraModel? camera;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final camera = this.camera;
    final colors = LavishColors.of(context);
    return LavishRow(
      leading: LavishIconBox(
        tone: camera?.status == 'LIVE' ? LavishTone.bad : LavishTone.accent,
        child: Icon(
          camera == null ? Icons.videocam_off_outlined : Icons.videocam_rounded,
        ),
      ),
      title: title,
      onTap: onTap,
      trailing: [
        if (camera == null)
          LavishPill(
            l10n.tournamentManagementCourtCameraNotAttached,
            tone: LavishTone.neutral,
          )
        else
          CameraStatusBadge(status: camera.status),
        Icon(Icons.chevron_right_rounded, size: 20, color: colors.faint),
      ],
    );
  }
}
