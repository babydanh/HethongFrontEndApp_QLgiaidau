import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_editor_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/participant_row_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/stream_key_qr_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

/// Camera management of one tournament: add / delete cameras and move them
/// between courts, by picker or by dragging a camera card onto a court card
/// (OpenSpec `quan-ly-giai-web-parity`, task 5.1).
///
/// The list is never patched locally: every write is followed by a re-read
/// through [TournamentCamerasNotifier.refresh], so the server stays the truth
/// (a refused write simply leaves the list as it was). The panel itself reads no
/// stream key, publish URL or RTSP credential; the stream-key QR lives in its
/// own sheet (task 5.2).
class TournamentCameraPanel extends ConsumerStatefulWidget {
  const TournamentCameraPanel({
    super.key,
    required this.tournamentId,
    this.readOnly = false,
  });

  final String tournamentId;
  final bool readOnly;

  @override
  ConsumerState<TournamentCameraPanel> createState() =>
      _TournamentCameraPanelState();
}

class _TournamentCameraPanelState extends ConsumerState<TournamentCameraPanel> {
  late Future<List<TournamentCourtRef>> _courtsFuture = _loadCourts();

  /// Cameras with a write in flight; their card cannot be dragged or edited.
  final Set<String> _busyCameraIds = <String>{};

  Future<List<TournamentCourtRef>> _loadCourts() async {
    final venues = await ref
        .read(tournamentManagementRepositoryProvider)
        .getVenues(widget.tournamentId);
    return _flattenCourts(venues);
  }

  /// A court without an id cannot be addressed by the camera routes, so it is
  /// dropped. Same shape rules as the match-camera section.
  List<TournamentCourtRef> _flattenCourts(List<Map<String, dynamic>> venues) {
    final courts = <TournamentCourtRef>[];
    for (final venue in venues) {
      final rawCourts = venue['courts'];
      if (rawCourts is! List) continue;
      final venueName = tournamentManagementRecordName(venue);
      for (final rawCourt in rawCourts) {
        if (rawCourt is! Map) continue;
        final id = (rawCourt['id'] ?? rawCourt['courtId'] ?? '').toString();
        if (id.isEmpty) continue;
        courts.add(
          TournamentCourtRef(
            id: id,
            name: (rawCourt['name'] ?? rawCourt['courtName'] ?? '').toString(),
            venueName: venueName,
          ),
        );
      }
    }
    return courts;
  }

  String _failureText(Object failure, AppLocalizations l10n) =>
      tournamentSheetServerMessage(failure) ??
      ErrorParser.parse(failure, l10n.tournamentCameraActionFailed, l10n);

  Future<void> _refresh() => ref
      .read(tournamentCamerasProvider(widget.tournamentId).notifier)
      .refresh();

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Runs one write for [camera]; a failure is shown verbatim and changes
  /// nothing. Returns whether the write went through.
  Future<bool> _runWrite(
    TournamentCameraModel camera,
    Future<void> Function() write,
  ) async {
    if (_busyCameraIds.contains(camera.id)) return false;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busyCameraIds.add(camera.id));
    try {
      await write();
      await _refresh();
      return true;
    } on Object catch (failure) {
      if (mounted) _toast(_failureText(failure, l10n));
      return false;
    } finally {
      if (mounted) setState(() => _busyCameraIds.remove(camera.id));
    }
  }

  String _courtName(List<TournamentCourtRef> courts, String? courtId) {
    final l10n = AppLocalizations.of(context)!;
    if (courtId == null) return l10n.tournamentCameraCourtNone;
    for (final court in courts) {
      if (court.id == courtId) return court.name.isEmpty ? court.id : court.name;
    }
    return courtId;
  }

  Future<void> _moveToCourt(
    TournamentCameraModel camera,
    String? courtId,
    List<TournamentCourtRef> courts,
  ) async {
    if (camera.courtId == courtId) return;
    final l10n = AppLocalizations.of(context)!;
    final moved = await _runWrite(
      camera,
      () => ref
          .read(cameraAdminRepositoryProvider)
          .assignCameraCourt(camera.id, courtId),
    );
    if (moved && mounted) {
      _toast(
        l10n.tournamentCameraCourtChanged(
          camera.name,
          _courtName(courts, courtId),
        ),
      );
    }
  }

  Future<void> _openAdd(List<TournamentCourtRef> courts) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    TournamentCameraModel? created;
    final saved = await CameraEditorSheet.show(
      context,
      courts: courts,
      onSubmit: (value) async {
        created = await ref
            .read(cameraAdminRepositoryProvider)
            .createCamera(
              tournamentId: widget.tournamentId,
              name: value.name,
              mode: value.mode,
              courtId: value.courtId,
            );
        await _refresh();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.tournamentCameraCreated(value.name))),
          );
      },
    );
    // Như Web (LivestreamTab.handleCreateCamera): camera PUSH vừa tạo thì mở
    // luôn popup QR, không hỏi lại; popup tự tạo stream key khi chưa có.
    final camera = created;
    if (saved != true ||
        camera == null ||
        !mounted ||
        !shouldOpenStreamKeyAfterCreate(camera.mode)) {
      return;
    }
    await StreamKeyQrSheet.show(context, camera: camera);
  }

  /// The QR carries the stream key, so it is never one tap away: the
  /// organizer confirms first and only then is the sheet (and its key request)
  /// opened.
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

  /// Chip picker for one court. A `null` camera in the result means "remove
  /// the camera(s) of this court"; a dismissed sheet returns nothing.
  Future<void> _pickCamera(
    TournamentCourtRef court,
    List<TournamentCameraModel> cameras,
    List<TournamentCourtRef> courts,
  ) async {
    final picked = await showModalBottomSheet<(TournamentCameraModel?,)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CameraPickSheet(court: court, cameras: cameras),
    );
    if (picked == null || !mounted) return;
    final camera = picked.$1;
    if (camera != null) {
      await _moveToCourt(camera, court.id, courts);
      return;
    }
    for (final current in cameras.where((item) => item.courtId == court.id)) {
      if (!mounted) return;
      await _moveToCourt(current, null, courts);
    }
  }

  Future<void> _confirmDelete(TournamentCameraModel camera) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementConfirmTitle,
      message: l10n.tournamentCameraDeleteConfirm(camera.name),
      confirmLabel: l10n.tournamentManagementDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final deleted = await _runWrite(
      camera,
      () => ref.read(cameraAdminRepositoryProvider).deleteCamera(camera.id),
    );
    if (deleted && mounted) _toast(l10n.tournamentCameraDeleted(camera.name));
  }

  /// Row tap: the only secondary action of a camera is deleting it, which the
  /// design keeps off the row itself (the row carries the status and the QR).
  Future<void> _openCameraMenu(TournamentCameraModel camera) async {
    final l10n = AppLocalizations.of(context)!;
    final delete = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          key: ValueKey('camera-delete-${camera.id}'),
          leading: const Icon(
            Icons.delete_outline_rounded,
            color: LavishColors.bad,
          ),
          title: Text(l10n.tournamentCameraDeleteTooltip),
          subtitle: Text(camera.name),
          onTap: () => Navigator.pop(sheetContext, true),
        ),
      ),
    );
    if (delete != true || !mounted) return;
    await _confirmDelete(camera);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<TournamentCourtRef>>(
      future: _courtsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TournamentManagementError(
            error: snapshot.error,
            onRetry: () => setState(() => _courtsFuture = _loadCourts()),
          );
        }
        if (!snapshot.hasData) {
          return const BoneListLoading(itemCount: 3, leadingAvatar: false);
        }
        return _buildBody(l10n, snapshot.data!);
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n, List<TournamentCourtRef> courts) {
    final camerasAsync = ref.watch(tournamentCamerasProvider(widget.tournamentId));
    return camerasAsync.when(
      loading: () => const BoneListLoading(itemCount: 3, leadingAvatar: false),
      error: (error, _) =>
          TournamentManagementError(error: error, onRetry: _refresh),
      data: (cameras) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LavishGroupHeader(l10n.tournamentCameraListTitle(cameras.length)),
          if (cameras.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Text(
                l10n.tournamentCameraEmpty,
                style: TextStyle(
                  fontSize: 13,
                  color: LavishColors.of(context).muted,
                ),
              ),
            ),
          for (final camera in cameras)
            _CameraRow(
              camera: camera,
              courtName: camera.courtId == null
                  ? l10n.tournamentCameraNoCourt
                  : _courtName(courts, camera.courtId),
              enabled: !widget.readOnly && !_busyCameraIds.contains(camera.id),
              onMenu: () => _openCameraMenu(camera),
              onStreamKey: () => _openStreamKey(camera),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: LavishButton(
              key: const ValueKey('camera-panel-add'),
              kind: LavishButtonKind.outline,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: l10n.tournamentCameraAdd,
              onPressed: widget.readOnly ? null : () => _openAdd(courts),
            ),
          ),
          if (courts.isNotEmpty) ...[
            LavishGroupHeader(l10n.tournamentCameraCourtsTitle),
            for (final court in courts)
              _CourtRow(
                court: court,
                cameras: [
                  for (final camera in cameras)
                    if (camera.courtId == court.id) camera,
                ],
                acceptDrops: !widget.readOnly,
                onDrop: (camera) => _moveToCourt(camera, court.id, courts),
                onPick: widget.readOnly
                    ? null
                    : () => _pickCamera(court, cameras, courts),
              ),
          ],
        ],
      ),
    );
  }
}

/// Design `.li` camera row: icon box, name, "MODE · court", status pill and
/// the stream-key QR box. Long-press drags it onto a court row.
class _CameraRow extends StatelessWidget {
  const _CameraRow({
    required this.camera,
    required this.courtName,
    required this.enabled,
    required this.onMenu,
    required this.onStreamKey,
  });

  final TournamentCameraModel camera;
  final String courtName;

  /// False for a read-only tournament or while a write is in flight.
  final bool enabled;
  final VoidCallback onMenu;
  final VoidCallback onStreamKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final live = camera.status == 'LIVE';
    final row = LavishRow(
      key: ValueKey('camera-card-${camera.id}'),
      leading: LavishIconBox(
        tone: live ? LavishTone.bad : LavishTone.accent,
        child: const Icon(Icons.videocam_rounded),
      ),
      title: camera.name,
      subtitle: camera.mode.isEmpty ? courtName : '${camera.mode} · $courtName',
      onTap: enabled ? onMenu : null,
      trailing: [
        LavishPill(
          live
              ? l10n.tournamentManagementLivestreamStatusLive
              : l10n.tournamentCameraStatusIdle,
          tone: live ? LavishTone.ok : LavishTone.neutral,
        ),
        // Only a PUSH camera has a stream key; a PULL one is just a URL.
        if (camera.mode == 'PUSH')
          // 40dp touch target around the design's 30dp box.
          GestureDetector(
            key: ValueKey('camera-stream-key-${camera.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onStreamKey : null,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: LavishIconBox(
                  size: 30,
                  tooltip: l10n.tournamentStreamKeyTooltip,
                  child: const Icon(Icons.qr_code_2_rounded),
                ),
              ),
            ),
          ),
      ],
    );
    return LongPressDraggable<TournamentCameraModel>(
      data: camera,
      // 0 turns dragging off (read-only tournament or write in flight).
      maxSimultaneousDrags: enabled ? 1 : 0,
      feedback: Material(
        color: Colors.transparent,
        child: Chip(label: Text(camera.name)),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );
  }
}

/// Design `.li` court row: court name, its camera(s) and the assign chip. A
/// camera row dropped on it moves the camera here.
class _CourtRow extends StatelessWidget {
  const _CourtRow({
    required this.court,
    required this.cameras,
    required this.acceptDrops,
    required this.onDrop,
    required this.onPick,
  });

  final TournamentCourtRef court;
  final List<TournamentCameraModel> cameras;
  final bool acceptDrops;
  final void Function(TournamentCameraModel camera) onDrop;

  /// Opens the camera picker; null (read-only tournament) disables the chip.
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DragTarget<TournamentCameraModel>(
      key: ValueKey('camera-court-${court.id}'),
      onWillAcceptWithDetails: (details) =>
          acceptDrops && details.data.courtId != court.id,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, _) => LavishRow(
        background: candidates.isEmpty
            ? null
            : LavishColors.of(context).soft(LavishTone.accent),
        title: court.name.isEmpty ? court.id : court.name,
        subtitle: cameras.isEmpty
            ? l10n.tournamentCameraCourtNoCameras
            : cameras.map((camera) => camera.name).join(', '),
        trailing: [
          LavishChipButton(
            key: ValueKey('camera-court-assign-${court.id}'),
            chevron: true,
            onPressed: onPick,
            label: cameras.isEmpty
                ? l10n.tournamentCameraAssign
                : l10n.tournamentCameraChange,
          ),
        ],
      ),
    );
  }
}

/// Chip picker of one court: tap a camera to assign it, or "remove" to take
/// the court's camera away. Pops a one-field record so that "no camera" (null)
/// is told apart from a dismissed sheet.
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
                  ChoiceChip(
                    key: ValueKey('camera-pick-${camera.id}'),
                    label: Text(camera.name),
                    selected: camera.courtId == court.id,
                    onSelected: (_) => Navigator.pop(context, (camera,)),
                  ),
                if (hasCamera)
                  ActionChip(
                    key: const ValueKey('camera-pick-none'),
                    avatar: const Icon(Icons.link_off_rounded, size: 18),
                    label: Text(l10n.tournamentCameraPickNone),
                    onPressed: () => Navigator.pop(context, (null,)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
