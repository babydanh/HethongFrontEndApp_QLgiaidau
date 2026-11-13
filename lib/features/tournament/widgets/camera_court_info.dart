import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_stream_stats_badge.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_status_badge.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/stream_key_qr_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/camera_preview_provider.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One line of the court popup: the court's camera (status, name, ping), the
/// Đổi / Gán picker and, for a PUSH camera, the stream-key QR.
///
/// The camera is read from [tournamentCamerasProvider] so the line follows a
/// change made from its own picker. Every write re-reads the list; a refused
/// write changes nothing and shows the server's message.
class CameraCourtInfo extends ConsumerStatefulWidget {
  const CameraCourtInfo({
    super.key,
    required this.tournamentId,
    required this.court,
    required this.readOnly,
  });

  final String tournamentId;
  final TournamentCourtRef court;
  final bool readOnly;

  @override
  ConsumerState<CameraCourtInfo> createState() => _CameraCourtInfoState();
}

class _CameraCourtInfoState extends ConsumerState<CameraCourtInfo> {
  bool _busy = false;

  String get _courtTitle =>
      widget.court.name.isEmpty ? widget.court.id : widget.court.name;

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// Runs one camera write then re-reads the list. Returns whether it worked.
  Future<bool> _write(Future<void> Function() write) async {
    if (_busy) return false;
    final l10n = AppLocalizations.of(context)!;
    // Read before the await: the popup may be closed while the write runs.
    final cameras = ref.read(
      tournamentCamerasProvider(widget.tournamentId).notifier,
    );
    setState(() => _busy = true);
    try {
      await write();
      await cameras.refresh();
      return true;
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
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _moveCamera(
    TournamentCameraModel camera,
    String? courtId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final admin = ref.read(cameraAdminRepositoryProvider);
    final moved = await _write(
      () => admin.assignCameraCourt(camera.id, courtId),
    );
    if (!moved || !mounted) return false;
    _toast(
      l10n.tournamentCameraCourtChanged(
        camera.name,
        courtId == null ? l10n.tournamentCameraCourtNone : _courtTitle,
      ),
    );
    return true;
  }

  Future<void> _deleteCamera(TournamentCameraModel camera) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementConfirmTitle,
      message: l10n.tournamentCameraDeleteConfirm(camera.name),
      confirmLabel: l10n.tournamentManagementDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final admin = ref.read(cameraAdminRepositoryProvider);
    final deleted = await _write(() => admin.deleteCamera(camera.id));
    if (deleted && mounted) _toast(l10n.tournamentCameraDeleted(camera.name));
  }

  Future<void> _pick(List<TournamentCameraModel> cameras) async {
    final action = await showModalBottomSheet<_PickAction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CameraPickSheet(court: widget.court, cameras: cameras),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _Assign(:final camera):
        await _moveCamera(camera, widget.court.id);
      case _Unassign():
        final here = cameras.where((c) => c.courtId == widget.court.id);
        // Stop at the first refusal so its message stays on screen.
        for (final current in here.toList()) {
          if (!mounted || !await _moveCamera(current, null)) return;
        }
      case _Delete(:final camera):
        await _deleteCamera(camera);
    }
  }

  /// The QR carries the stream key, so the organizer confirms first.
  Future<void> _openStreamKey(TournamentCameraModel camera) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentStreamKeyConfirmTitle,
      message: l10n.tournamentStreamKeyConfirmMessage,
      confirmLabel: l10n.tournamentStreamKeyConfirmAction,
    );
    if (!confirmed || !mounted) return;
    await StreamKeyQrSheet.show(context, camera: camera);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Null while the list loads or failed: the picker shows, disabled.
    final loaded = ref
        .watch(tournamentCamerasProvider(widget.tournamentId))
        .asData
        ?.value;
    final cameras = loaded ?? const <TournamentCameraModel>[];
    final camera = cameraForCourt(cameras, widget.court.id);
    final canEdit = !widget.readOnly && !_busy;
    return Row(
      key: const ValueKey('camera-court-line'),
      children: [
        Expanded(child: _CameraLabel(camera: camera)),
        if (!widget.readOnly && (loaded == null || loaded.isNotEmpty))
          TextButton(
            key: const ValueKey('camera-court-pick'),
            onPressed: canEdit && loaded != null ? () => _pick(loaded) : null,
            child: Text(
              camera == null
                  ? l10n.tournamentCameraAssign
                  : l10n.tournamentCameraChange,
            ),
          ),
        // Only a PUSH camera has a stream key; a PULL one is just a URL.
        if (camera != null && camera.mode == 'PUSH' && !widget.readOnly)
          IconButton(
            key: ValueKey('camera-stream-key-${camera.id}'),
            tooltip: l10n.tournamentStreamKeyTooltip,
            onPressed: canEdit ? () => _openStreamKey(camera) : null,
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
      ],
    );
  }
}

/// Status badge, camera name and, while it is live, the ping badge.
class _CameraLabel extends StatelessWidget {
  const _CameraLabel({required this.camera});

  final TournamentCameraModel? camera;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final cam = camera;
    if (cam == null) {
      return Text(
        l10n.camTabNoCamera,
        style: TextStyle(color: colors.textMuted),
      );
    }
    final playbackUrl = cam.playbackUrl;
    // Wraps instead of overflowing on a narrow phone next to the buttons.
    return Wrap(
      spacing: AppTheme.spacingSM,
      runSpacing: AppTheme.spacingXS,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CameraStatusBadge(status: cam.status),
        Text(
          cam.name.isEmpty ? cam.id : cam.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (playbackUrl != null && cameraSignal(cam) == CameraSignal.live)
          LiveStreamStatsBadge(url: playbackUrl),
      ],
    );
  }
}

/// ⏻ next to the court title: turns the camera preview off on this device
/// only. Nothing is sent to the Backend; the camera keeps streaming.
class CameraPreviewToggle extends ConsumerWidget {
  const CameraPreviewToggle({super.key, required this.cameraId});

  final String cameraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final previewOn = !ref.watch(cameraPreviewOffProvider).contains(cameraId);
    return IconButton(
      tooltip: l10n.camCourtPreviewToggle,
      constraints: const BoxConstraints.tightFor(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
      ),
      color: previewOn ? colors.success : colors.textMuted,
      onPressed: () =>
          ref.read(cameraPreviewOffProvider.notifier).toggle(cameraId),
      icon: const Icon(Icons.power_settings_new_rounded),
    );
  }
}

sealed class _PickAction {
  const _PickAction();
}

class _Assign extends _PickAction {
  const _Assign(this.camera);
  final TournamentCameraModel camera;
}

class _Unassign extends _PickAction {
  const _Unassign();
}

class _Delete extends _PickAction {
  const _Delete(this.camera);
  final TournamentCameraModel camera;
}

/// Camera picker of one court: tap a camera to put it here, ✕ to delete it,
/// or "Bỏ gán camera" to leave the court without one.
class _CameraPickSheet extends StatelessWidget {
  const _CameraPickSheet({required this.court, required this.cameras});

  final TournamentCourtRef court;
  final List<TournamentCameraModel> cameras;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasCamera = cameras.any((camera) => camera.courtId == court.id);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tournamentCameraPickTitle(
                court.name.isEmpty ? court.id : court.name,
              ),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final camera in cameras)
                  InputChip(
                    key: ValueKey('camera-pick-${camera.id}'),
                    label: Text(camera.name),
                    selected: camera.courtId == court.id,
                    onSelected: (_) => Navigator.pop(context, _Assign(camera)),
                    deleteButtonTooltipMessage:
                        l10n.tournamentCameraDeleteTooltip,
                    onDeleted: () => Navigator.pop(context, _Delete(camera)),
                  ),
                if (hasCamera)
                  ActionChip(
                    key: const ValueKey('camera-pick-none'),
                    avatar: const Icon(Icons.link_off_rounded, size: 18),
                    label: Text(l10n.tournamentCameraPickNone),
                    onPressed: () => Navigator.pop(context, const _Unassign()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
