import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/models/live_session_model.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/livestream_pairing_qr_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/live_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

/// Backend DTO bounds for `CameraDeviceModel.name`. A name outside them is
/// rejected by the server, so it is refused here instead of being sent.
const _deviceNameMinLength = 2;
const _deviceNameMaxLength = 255;

/// Opens [TournamentManagementLivestreamSection] as a sheet from the Camera
/// tab menu; cameras themselves are managed in the tab.
Future<void> showLivestreamToolsSheet(
  BuildContext context, {
  required String tournamentId,
  String? communityId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (sheetContext) => SizedBox(
    height: MediaQuery.sizeOf(sheetContext).height * 0.75,
    child: TournamentManagementLivestreamSection(
      tournamentId: tournamentId,
      communityId: communityId,
    ),
  ),
);

/// Live sessions of the tournament (status, re-check, stop), then the
/// community's reusable phone cameras (collapsed until opened: register a
/// device, its pairing QR). Cameras and courts are managed in the Camera tab.
///
/// Registering a community camera *device* sends a display name only, and the
/// server assigns the id and every publish credential.
///
/// Still absent: starting a match stream (`start`). Only the Backend decides
/// who may write (403 shows as an error).
class TournamentManagementLivestreamSection extends ConsumerStatefulWidget {
  const TournamentManagementLivestreamSection({
    super.key,
    required this.tournamentId,
    this.communityId,
  });

  final String tournamentId;

  /// Community that owns the camera fleet.
  ///
  /// `null` (tournament not linked to a community) means every community-scoped
  /// call is skipped instead of guessed: the backend guards those routes by
  /// community membership, so asking with a made-up id could only produce a
  /// misleading 403. Session monitoring is tournament-scoped and still loads.
  final String? communityId;

  @override
  ConsumerState<TournamentManagementLivestreamSection> createState() =>
      _TournamentManagementLivestreamSectionState();
}

class _TournamentManagementLivestreamSectionState
    extends ConsumerState<TournamentManagementLivestreamSection> {
  final Set<String> _busySessionIds = <String>{};
  final Set<String> _busyDeviceIds = <String>{};
  final TextEditingController _deviceNameController = TextEditingController();
  bool _creatingDevice = false;
  bool _devicesExpanded = false;
  String? _deviceNameError;

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  String? get _communityId {
    final trimmed = widget.communityId?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _createPairingQr(CameraDeviceModel device) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    setState(() => _busyDeviceIds.add(device.id));
    // Kept in a local so the one-time secret can be dropped the moment the
    // sheet closes; never persisted, copied, shared, toasted or logged.
    var pairingToken = '';
    try {
      final result = await ref
          .read(liveSessionRepositoryProvider)
          .createPairingToken(device.id);
      pairingToken = result.pairingToken;
      if (!mounted) return;
      await showLivestreamPairingQrSheet(
        context,
        deviceId: result.device.id.isEmpty ? device.id : result.device.id,
        deviceName: result.device.name.isEmpty
            ? device.name
            : result.device.name,
        pairingToken: pairingToken,
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tournamentManagementLivestreamPairingQrFailed),
          ),
        );
      }
    } finally {
      pairingToken = '';
      if (mounted) {
        setState(() => _busyDeviceIds.remove(device.id));
        _refreshCameraDevices();
      }
    }
  }

  void _refreshCameraDevices() {
    final communityId = _communityId;
    if (communityId == null) return;
    ref.invalidate(cameraDevicesProvider(communityId));
  }

  void _onDeviceNameChanged(String value) {
    if (_deviceNameError == null || value.trim().isEmpty) return;
    setState(() => _deviceNameError = null);
  }

  /// Registers a new reusable camera device and re-polls the fleet.
  ///
  /// The display name is the only value that leaves the device, and a failure
  /// is reported with a fixed message: neither the request nor the response
  /// body is ever rendered.
  Future<void> _createDevice(String communityId) async {
    if (_creatingDevice) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final name = _deviceNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _deviceNameError =
            l10n.tournamentManagementLivestreamDeviceNameRequired;
      });
      return;
    }
    if (name.length < _deviceNameMinLength ||
        name.length > _deviceNameMaxLength) {
      setState(() {
        _deviceNameError =
            l10n.tournamentManagementLivestreamDeviceNameLengthInvalid;
      });
      return;
    }
    setState(() {
      _creatingDevice = true;
      _deviceNameError = null;
    });
    try {
      await ref
          .read(liveSessionRepositoryProvider)
          .createDevice(communityId: communityId, name: name);
      if (!mounted) return;
      _deviceNameController.clear();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tournamentManagementActionError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creatingDevice = false);
        _refreshCameraDevices();
      }
    }
  }

  Future<void> _runSessionAction(
    String sessionId,
    Future<Object?> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    setState(() => _busySessionIds.add(sessionId));
    try {
      await action();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tournamentManagementActionError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busySessionIds.remove(sessionId));
        _refreshSessions();
      }
    }
  }

  void _refreshSessions() {
    ref.invalidate(tournamentLiveSessionsProvider(widget.tournamentId));
  }

  /// Re-polls the provider for a session status. It never restarts or
  /// republishes anything, so the copy must not promise a restart.
  Future<void> _recheckSessionStatus(LiveSessionModel session) {
    return _runSessionAction(
      session.id,
      () =>
          ref.read(liveSessionRepositoryProvider).reconnectSession(session.id),
    );
  }

  Future<void> _stopSession(LiveSessionModel session) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementConfirmTitle,
      message: l10n.tournamentManagementLivestreamStopSessionConfirm,
      confirmLabel: l10n.tournamentManagementLivestreamStopSession,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _runSessionAction(
      session.id,
      () => ref.read(liveSessionRepositoryProvider).stopSession(session.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final communityId = _communityId;
    return LavishSurface(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildSessions(l10n),
          // Phones belong to a community: without one there is nothing to
          // show, so the block is left out instead of explaining why.
          if (communityId != null) _buildDevices(l10n, communityId),
        ],
      ),
    );
  }

  Widget _buildSessions(AppLocalizations l10n) {
    final sessions = ref.watch(
      tournamentLiveSessionsProvider(widget.tournamentId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishGroupHeader(l10n.tournamentManagementLivestreamSessions),
        sessions.when(
          skipLoadingOnRefresh: true,
          loading: () => const _InlineLoading(),
          error: (error, _) => TournamentManagementError(
            onRetry: _refreshSessions,
            error: error,
          ),
          data: (items) {
            if (items.isEmpty) {
              return _MutedLine(
                l10n.tournamentManagementLivestreamSessionsEmpty,
              );
            }
            return Column(
              children: [
                for (final session in items)
                  _LiveSessionTile(
                    session: session,
                    busy: _busySessionIds.contains(session.id),
                    statusLabel: _liveSessionStatusLabel(l10n, session.status),
                    onRecheckStatus: () => _recheckSessionStatus(session),
                    onStop: () => _stopSession(session),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDevices(AppLocalizations l10n, String communityId) {
    final devices = ref.watch(cameraDevicesProvider(communityId));
    final count = devices.asData?.value.length;
    final title = count == null
        ? l10n.tournamentManagementLivestreamDevices
        : '${l10n.tournamentManagementLivestreamDevices} · $count';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const ValueKey('livestream-devices-toggle'),
          onTap: () => setState(() => _devicesExpanded = !_devicesExpanded),
          child: LavishGroupHeader(
            title,
            trailing: Icon(
              _devicesExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 18,
              color: LavishColors.of(context).muted,
            ),
          ),
        ),
        // Deliberately outside the `data:` branch: a community that has no
        // device yet must still be able to register the first one.
        if (_devicesExpanded) _buildCreateDeviceForm(l10n, communityId),
        // A failure stays on screen while the provider silently retries, so
        // a 403 never flickers into a spinner.
        if (devices.hasError)
          TournamentManagementError(
            onRetry: _refreshCameraDevices,
            error: devices.error,
          )
        else
          devices.when(
            skipLoadingOnRefresh: true,
            loading: () => _devicesExpanded
                ? const _InlineLoading()
                : const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
            data: (items) {
              if (!_devicesExpanded) return const SizedBox.shrink();
              if (items.isEmpty) {
                return _MutedLine(
                  l10n.tournamentManagementLivestreamDevicesEmpty,
                );
              }
              return Column(
                children: [
                  for (final device in items)
                    LavishRow(
                      leading: const LavishIconBox(
                        child: Icon(Icons.smartphone_rounded),
                      ),
                      title: device.name,
                      subtitle: _cameraDeviceStatusLabel(l10n, device.status),
                      trailing: [
                        LavishChipButton(
                          label: l10n
                              .tournamentManagementLivestreamCreatePairingQr,
                          onPressed: _busyDeviceIds.contains(device.id)
                              ? null
                              : () => _createPairingQr(device),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildCreateDeviceForm(AppLocalizations l10n, String communityId) {
    final colors = LavishColors.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.chipLine, width: 1.5),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _deviceNameController,
            enabled: !_creatingDevice,
            onChanged: _onDeviceNameChanged,
            textInputAction: TextInputAction.done,
            onSubmitted: _creatingDevice
                ? null
                : (_) => _createDevice(communityId),
            style: TextStyle(fontSize: 13, color: colors.text),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              labelText: l10n.tournamentManagementLivestreamDeviceNameLabel,
              hintText: l10n.tournamentManagementLivestreamDeviceNameHint,
              errorText: _deviceNameError,
              border: border,
              enabledBorder: border,
            ),
          ),
          const SizedBox(height: 10),
          LavishButton(
            label: l10n.tournamentManagementLivestreamCreateDevice,
            icon: const Icon(Icons.videocam_outlined, size: 16),
            busy: _creatingDevice,
            onPressed: () => _createDevice(communityId),
          ),
        ],
      ),
    );
  }
}

/// One live session: `.li` row with the status pill, then the actions it
/// supports (re-check, stop) as design buttons.
class _LiveSessionTile extends StatelessWidget {
  const _LiveSessionTile({
    required this.session,
    required this.busy,
    required this.statusLabel,
    required this.onRecheckStatus,
    required this.onStop,
  });

  final LiveSessionModel session;
  final bool busy;
  final String statusLabel;
  final VoidCallback onRecheckStatus;
  final VoidCallback onStop;

  /// The backend only re-polls a provider session for these two states, so the
  /// action is hidden elsewhere instead of offering a no-op.
  static bool supportsStatusRecheck(LiveSessionStatus status) =>
      status == LiveSessionStatus.starting ||
      status == LiveSessionStatus.reconnecting;

  /// Mirrors the backend's stoppable set, minus `stopping` which is already
  /// being torn down.
  static bool supportsStop(LiveSessionStatus status) =>
      status == LiveSessionStatus.created ||
      status == LiveSessionStatus.starting ||
      status == LiveSessionStatus.live ||
      status == LiveSessionStatus.reconnecting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = (session.title?.trim().isNotEmpty ?? false)
        ? session.title!
        : session.matchId;
    final recheck = supportsStatusRecheck(session.status);
    final stop = supportsStop(session.status);
    return Column(
      key: ValueKey('live-session-${session.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishRow(
          title: title,
          trailing: [
            LavishPill(statusLabel, tone: _sessionStatusTone(session.status)),
          ],
        ),
        if (recheck || stop)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                if (stop)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: LavishButton(
                        kind: LavishButtonKind.danger,
                        label: l10n.tournamentManagementLivestreamStopSession,
                        onPressed: busy ? null : onStop,
                      ),
                    ),
                  ),
                if (stop && recheck) const SizedBox(width: 10),
                if (recheck)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Tooltip(
                        message: l10n
                            .tournamentManagementLivestreamRecheckStatusHint,
                        child: LavishButton(
                          kind: LavishButtonKind.outline,
                          label:
                              l10n.tournamentManagementLivestreamRecheckStatus,
                          onPressed: busy ? null : onRecheckStatus,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) =>
      const BoneListLoading(itemCount: 2, leadingAvatar: false);
}

class _MutedLine extends StatelessWidget {
  const _MutedLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: LavishColors.of(context).muted),
    ),
  );
}

LavishTone _sessionStatusTone(LiveSessionStatus status) => switch (status) {
  LiveSessionStatus.live => LavishTone.ok,
  LiveSessionStatus.starting ||
  LiveSessionStatus.reconnecting ||
  LiveSessionStatus.stopping => LavishTone.warn,
  LiveSessionStatus.failed => LavishTone.bad,
  _ => LavishTone.neutral,
};

String _liveSessionStatusLabel(
  AppLocalizations l10n,
  LiveSessionStatus status,
) => switch (status) {
  LiveSessionStatus.created => l10n.tournamentManagementLivestreamStatusCreated,
  LiveSessionStatus.starting =>
    l10n.tournamentManagementLivestreamStatusStarting,
  LiveSessionStatus.live => l10n.tournamentManagementLivestreamStatusLive,
  LiveSessionStatus.reconnecting =>
    l10n.tournamentManagementLivestreamStatusReconnecting,
  LiveSessionStatus.stopping =>
    l10n.tournamentManagementLivestreamStatusStopping,
  LiveSessionStatus.ended => l10n.tournamentManagementLivestreamStatusEnded,
  LiveSessionStatus.failed => l10n.tournamentManagementLivestreamStatusFailed,
  LiveSessionStatus.unknown => l10n.tournamentManagementLivestreamStatusOther,
};

String _cameraDeviceStatusLabel(
  AppLocalizations l10n,
  CameraDeviceStatus status,
) => switch (status) {
  CameraDeviceStatus.unpaired =>
    l10n.tournamentManagementLivestreamDeviceUnpaired,
  CameraDeviceStatus.ready => l10n.tournamentManagementLivestreamDeviceReady,
  CameraDeviceStatus.online => l10n.tournamentManagementLivestreamDeviceOnline,
  CameraDeviceStatus.live => l10n.tournamentManagementLivestreamStatusLive,
  CameraDeviceStatus.offline =>
    l10n.tournamentManagementLivestreamDeviceOffline,
  CameraDeviceStatus.revoked =>
    l10n.tournamentManagementLivestreamDeviceRevoked,
  CameraDeviceStatus.unknown => l10n.tournamentManagementLivestreamStatusOther,
};
