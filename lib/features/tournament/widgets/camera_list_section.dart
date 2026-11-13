import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_status_badge.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every camera of the tournament, one line each: name, mode · court (or
/// "Chưa gắn sân") and status, with a delete button for organizers.
///
/// It lists cameras that no court uses too, which the court popups cannot
/// show. A delete re-reads the list; a refused delete shows the server's
/// message and changes nothing.
class CameraListSection extends ConsumerStatefulWidget {
  const CameraListSection({
    super.key,
    required this.tournamentId,
    required this.cameras,
    required this.courts,
    required this.readOnly,
  });

  final String tournamentId;
  final List<TournamentCameraModel> cameras;
  final List<TournamentCourtRef> courts;
  final bool readOnly;

  @override
  ConsumerState<CameraListSection> createState() => _CameraListSectionState();
}

class _CameraListSectionState extends ConsumerState<CameraListSection> {
  final _busyIds = <String>{};

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  String _courtName(String? courtId) {
    for (final court in widget.courts) {
      if (court.id != courtId) continue;
      return court.name.isEmpty ? court.id : court.name;
    }
    return courtId ?? '';
  }

  Future<void> _delete(TournamentCameraModel camera) async {
    if (_busyIds.contains(camera.id)) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementConfirmTitle,
      message: l10n.tournamentCameraDeleteConfirm(camera.name),
      confirmLabel: l10n.tournamentManagementDelete,
      destructive: true,
    );
    if (!confirmed || !mounted || _busyIds.contains(camera.id)) return;
    // Read before the await: the tab may be left while the delete runs.
    final notifier = ref.read(
      tournamentCamerasProvider(widget.tournamentId).notifier,
    );
    final admin = ref.read(cameraAdminRepositoryProvider);
    setState(() => _busyIds.add(camera.id));
    try {
      await admin.deleteCamera(camera.id);
      await notifier.refresh();
      if (mounted) _toast(l10n.tournamentCameraDeleted(camera.name));
    } on Object catch (failure) {
      if (mounted) {
        _toast(
          tournamentSheetServerMessage(failure) ??
              ErrorParser.parse(
                failure,
                l10n.tournamentCameraActionFailed,
                l10n,
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(camera.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Column(
      key: const ValueKey('camera-list-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
          child: Text(
            l10n.tournamentCameraListTitle(widget.cameras.length),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        if (widget.cameras.isEmpty)
          Text(
            l10n.tournamentCameraEmpty,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        for (final camera in widget.cameras)
          _CameraLine(
            camera: camera,
            courtLabel: camera.courtId == null
                ? l10n.tournamentCameraNoCourt
                : _courtName(camera.courtId),
            busy: _busyIds.contains(camera.id),
            onDelete: widget.readOnly ? null : () => _delete(camera),
          ),
      ],
    );
  }
}

class _CameraLine extends StatelessWidget {
  const _CameraLine({
    required this.camera,
    required this.courtLabel,
    required this.busy,
    required this.onDelete,
  });

  final TournamentCameraModel camera;
  final String courtLabel;
  final bool busy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      key: ValueKey('camera-list-row-${camera.id}'),
      constraints: const BoxConstraints(minHeight: kMinTouchTarget),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingXS),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    camera.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${camera.mode} · $courtLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          CameraStatusBadge(status: camera.status),
          if (busy)
            const SizedBox.square(
              dimension: kMinTouchTarget,
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (onDelete != null)
            IconButton(
              tooltip: l10n.tournamentCameraDeleteTooltip,
              constraints: const BoxConstraints.tightFor(
                width: kMinTouchTarget,
                height: kMinTouchTarget,
              ),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            )
          else
            const SizedBox(width: AppTheme.spacingSM),
        ],
      ),
    );
  }
}
