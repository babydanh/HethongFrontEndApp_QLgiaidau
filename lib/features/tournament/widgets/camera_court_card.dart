import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_court_info.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_live_status_action.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_match_row.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_status_badge.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Collapsed court card of the Camera tab: name, camera status and match
/// count. Everything else (camera line, URL, matches) lives in the popup that
/// [showCameraCourtSheet] opens when the card is tapped.
class CameraCourtTile extends StatelessWidget {
  const CameraCourtTile({
    super.key,
    required this.court,
    required this.camera,
    required this.matchCount,
    required this.onTap,
  });

  final TournamentCourtRef court;
  final TournamentCameraModel? camera;
  final int matchCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final title = court.name.isEmpty ? court.id : court.name;
    final cam = camera;
    return Semantics(
      button: true,
      label: l10n.camCourtOpenSheet(title),
      excludeSemantics: true,
      child: Material(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: kMinTouchTarget),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.sports_tennis_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.camCourtMatchCount(matchCount),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                if (cam == null)
                  Text(
                    l10n.camTabNoCamera,
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  )
                else
                  CameraStatusBadge(status: cam.status),
                Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Popup of one court: camera line, playback URL, then its matches with the
/// ones still to play first and the finished ones below.
Future<void> showCameraCourtSheet(
  BuildContext context, {
  required String tournamentId,
  required TournamentCourtRef court,
  required TournamentCameraModel? camera,
  required List<MatchModel> courtMatches,
  required List<MatchModel> allMatches,
  required List<TournamentCameraModel> cameras,
  required bool readOnly,
  required String Function(MatchModel match) labelOf,
  required bool Function(MatchModel match) hasCameraOf,
  required Future<void> Function(MatchModel match, TournamentCameraModel camera)
  onPickCamera,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _CameraCourtSheet(
      tournamentId: tournamentId,
      court: court,
      camera: camera,
      courtMatches: courtMatches,
      allMatches: allMatches,
      cameras: cameras,
      readOnly: readOnly,
      labelOf: labelOf,
      hasCameraOf: hasCameraOf,
      onPickCamera: onPickCamera,
    ),
  );
}

class _CameraCourtSheet extends StatelessWidget {
  const _CameraCourtSheet({
    required this.tournamentId,
    required this.court,
    required this.camera,
    required this.courtMatches,
    required this.allMatches,
    required this.cameras,
    required this.readOnly,
    required this.labelOf,
    required this.hasCameraOf,
    required this.onPickCamera,
  });

  final String tournamentId;
  final TournamentCourtRef court;
  final TournamentCameraModel? camera;
  final List<MatchModel> courtMatches;
  final List<MatchModel> allMatches;
  final List<TournamentCameraModel> cameras;
  final bool readOnly;
  final String Function(MatchModel match) labelOf;
  final bool Function(MatchModel match) hasCameraOf;
  final Future<void> Function(MatchModel match, TournamentCameraModel camera)
  onPickCamera;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final title = court.name.isEmpty ? court.id : court.name;
    final cam = camera;
    final open = courtMatches.where((match) => !match.isCompleted).toList()
      ..sort(_byScheduledTime);
    final finished = courtMatches.where((match) => match.isCompleted).toList()
      ..sort(_byScheduledTime);

    Widget group(String heading, List<MatchModel> rows, {required bool done}) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSM),
              child: Text(
                heading,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.border),
              CameraMatchRow(
                tournamentId: tournamentId,
                match: rows[i],
                label: labelOf(rows[i]),
                hasCamera: hasCameraOf(rows[i]),
                // Finished matches keep only the recordings entry.
                readOnly: readOnly || done,
                showCourtChip: false,
                cameras: done ? const [] : cameras,
                onPickCamera: done ? null : (value) => onPickCamera(rows[i], value),
              ),
            ],
          ],
        );

    return ConstrainedBox(
      key: const ValueKey('camera-court-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shrinkWrap: true,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (court.venueName.isNotEmpty)
            Text(
              court.venueName,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          if (cam != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            CameraCourtInfo(
              tournamentId: tournamentId,
              camera: cam,
              matches: allMatches,
              matchLabelOf: labelOf,
            ),
          ],
          const SizedBox(height: AppTheme.spacingSM),
          CourtCameraUrlRow(
            tournamentId: tournamentId,
            courtId: court.id,
            courtName: title,
            readOnly: readOnly,
          ),
          if (cam != null) ...[
            const SizedBox(height: AppTheme.spacingSM),
            CameraLiveStatusAction(cameraId: cam.id),
          ],
          const SizedBox(height: AppTheme.spacingSM),
          Divider(height: 1, color: colors.border),
          if (courtMatches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSM),
              child: Text(
                l10n.tournamentManagementCameraNoMatchesHere,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ),
          if (open.isNotEmpty) group(l10n.camCourtOpenMatches, open, done: false),
          if (finished.isNotEmpty)
            group(l10n.camCourtFinishedMatches, finished, done: true),
        ],
      ),
    );
  }
}

/// Earliest first; matches without a time go last.
int _byScheduledTime(MatchModel a, MatchModel b) {
  final left = a.scheduledTime;
  final right = b.scheduledTime;
  if (left == null || right == null) {
    return left == null ? (right == null ? 0 : 1) : -1;
  }
  return left.compareTo(right);
}
