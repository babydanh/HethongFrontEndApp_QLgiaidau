import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/models/facebook_page_connection_model.dart';
import 'package:app_quanly_giaidau/data/models/live_session_model.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/livestream_pairing_qr_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/live_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Backend DTO bounds for `CameraDeviceModel.name`. A name outside them is
/// rejected by the server, so it is refused here instead of being sent.
const _deviceNameMinLength = 2;
const _deviceNameMaxLength = 255;

/// Livestream management that the mobile API is allowed to drive.
///
/// Covers the safe web subset only: the community camera fleet (registering a
/// reusable device, its pairing QR), the community Facebook Page connection
/// (status, connect, re-check, disconnect) and the tournament's live sessions
/// (status, end, re-check).
///
/// Registering a community camera *device* is not one of the blocked routes:
/// it sends a display name only, and the server assigns the id and every
/// publish credential.
///
/// Deliberately absent, because the backend security review blocks them until
/// the routes stop returning secrets: camera/stream-key management
/// (`listCameras`, `createCamera`, `deleteCamera`, `assign-camera`,
/// `start`/`stop` match stream) and playback. No publish capability, stream key
/// or camera credential is fetched, modelled or displayed here.
class TournamentManagementLivestreamSection extends ConsumerStatefulWidget {
  const TournamentManagementLivestreamSection({
    super.key,
    required this.tournamentId,
    this.communityId,
  });

  final String tournamentId;

  /// Community that owns the camera fleet and the Facebook Page connection.
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
    extends ConsumerState<TournamentManagementLivestreamSection>
    with WidgetsBindingObserver {
  final Set<String> _busySessionIds = <String>{};
  final Set<String> _busyDeviceIds = <String>{};
  String? _facebookActionError;
  bool _facebookBusy = false;
  final TextEditingController _deviceNameController = TextEditingController();
  bool _creatingDevice = false;
  String? _deviceNameError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // The Facebook Page connection is completed in a browser, so coming back
    // to the app is the one moment a fresh status is worth re-polling.
    _refreshFacebookConnection();
  }

  String? get _communityId {
    final trimmed = widget.communityId?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void _refreshFacebookConnection() {
    final communityId = _communityId;
    if (communityId == null || !mounted) return;
    ref.invalidate(facebookPageConnectionProvider(communityId));
  }

  Future<void> _connectFacebookPage() async {
    final communityId = _communityId;
    if (communityId == null) return;
    setState(() {
      _facebookBusy = true;
      _facebookActionError = null;
    });
    try {
      // The OAuth URL carries an encrypted state nonce, so it goes straight to
      // the platform browser and is never stored, logged or shared. Failures
      // are reported with a fixed message rather than the error text, which
      // could echo the URL.
      final authorizationUrl = await ref
          .read(liveSessionRepositoryProvider)
          .createFacebookOAuthUrl(communityId);
      final uri = Uri.tryParse(authorizationUrl);
      if (uri == null || !uri.hasScheme) {
        throw StateError('Facebook OAuth start returned an unusable URL.');
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Facebook OAuth URL could not be opened.');
      }
    } on Object {
      if (mounted) {
        setState(() {
          _facebookActionError = AppLocalizations.of(
            context,
          )!.tournamentManagementLivestreamFacebookConnectFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _facebookBusy = false);
    }
  }

  Future<void> _runFacebookAction(Future<Object?> Function() action) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    setState(() {
      _facebookBusy = true;
      _facebookActionError = null;
    });
    try {
      await action();
    } on Object {
      if (mounted) {
        setState(
          () => _facebookActionError = l10n.tournamentManagementActionError,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _facebookBusy = false;
          _refreshFacebookConnection();
        });
      }
    }
  }

  Future<void> _revalidateFacebookPage(String connectionId) {
    return _runFacebookAction(
      () => ref
          .read(liveSessionRepositoryProvider)
          .validateFacebookConnection(connectionId),
    );
  }

  Future<void> _disconnectFacebookPage() {
    final communityId = _communityId;
    if (communityId == null) return Future<void>.value();
    return _runFacebookAction(
      () => ref
          .read(liveSessionRepositoryProvider)
          .disconnectFacebookConnection(communityId),
    );
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (communityId == null)
          TournamentManagementSectionCard(
            title: l10n.tournamentManagementLivestream,
            subtitle: l10n.tournamentManagementLivestreamDescription,
            child: TournamentManagementEmpty(
              title: l10n.tournamentManagementLivestreamDevicesUnavailable,
              icon: Icons.link_off_rounded,
            ),
          )
        else ...[
          _buildFacebookCard(l10n, communityId),
          const SizedBox(height: 16),
          _buildDevicesCard(l10n, communityId),
        ],
        const SizedBox(height: 16),
        _buildSessionsCard(l10n),
      ],
    );
  }

  Widget _buildFacebookCard(AppLocalizations l10n, String communityId) {
    final connection = ref.watch(facebookPageConnectionProvider(communityId));
    return TournamentManagementSectionCard(
      title: l10n.contactFacebook,
      subtitle: l10n.tournamentManagementLivestreamFacebookSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          connection.when(
            skipLoadingOnRefresh: true,
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => TournamentManagementError(
              onRetry: () => _refreshFacebookConnection(),
              error: error,
            ),
            data: (value) => value == null
                ? TournamentManagementEmpty(
                    title:
                        l10n.tournamentManagementLivestreamFacebookNotConnected,
                    icon: Icons.facebook_rounded,
                    action: FilledButton.icon(
                      onPressed: _facebookBusy ? null : _connectFacebookPage,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(
                        l10n.tournamentManagementLivestreamFacebookConnect,
                      ),
                    ),
                  )
                : _FacebookConnectionBody(
                    connection: value,
                    busy: _facebookBusy,
                    onRevalidate: () => _revalidateFacebookPage(value.id),
                    onConnect: _connectFacebookPage,
                    onDisconnect: _disconnectFacebookPage,
                  ),
          ),
          if (_facebookActionError != null) ...[
            const SizedBox(height: 8),
            Text(
              _facebookActionError!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.colors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDevicesCard(AppLocalizations l10n, String communityId) {
    final devices = ref.watch(cameraDevicesProvider(communityId));
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementLivestreamDevices,
      subtitle: l10n.tournamentManagementLivestreamDevicesDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Deliberately outside the `data:` branch: a community that has no
          // device yet must still be able to register the first one.
          _buildCreateDeviceForm(l10n, communityId),
          const SizedBox(height: 16),
          devices.when(
            skipLoadingOnRefresh: true,
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => TournamentManagementError(
              onRetry: _refreshCameraDevices,
              error: error,
            ),
            data: (items) {
              if (items.isEmpty) {
                return TournamentManagementEmpty(
                  title: l10n.tournamentManagementLivestreamDevicesEmpty,
                  icon: Icons.videocam_off_outlined,
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) const Divider(height: 1),
                    _CameraDeviceTile(
                      device: items[index],
                      busy: _busyDeviceIds.contains(items[index].id),
                      onCreatePairingQr: () => _createPairingQr(items[index]),
                      statusLabel: _cameraDeviceStatusLabel(
                        l10n,
                        items[index].status,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreateDeviceForm(AppLocalizations l10n, String communityId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _deviceNameController,
            enabled: !_creatingDevice,
            onChanged: _onDeviceNameChanged,
            textInputAction: TextInputAction.done,
            onSubmitted: _creatingDevice
                ? null
                : (_) => _createDevice(communityId),
            decoration: InputDecoration(
              labelText: l10n.tournamentManagementLivestreamDeviceNameLabel,
              hintText: l10n.tournamentManagementLivestreamDeviceNameHint,
              errorText: _deviceNameError,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(
            onPressed: _creatingDevice
                ? null
                : () => _createDevice(communityId),
            icon: const Icon(Icons.videocam_outlined),
            label: Text(l10n.tournamentManagementLivestreamCreateDevice),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsCard(AppLocalizations l10n) {
    final sessions = ref.watch(
      tournamentLiveSessionsProvider(widget.tournamentId),
    );
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementLivestreamSessions,
      subtitle: l10n.tournamentManagementLivestreamSessionsDescription,
      child: sessions.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) =>
            TournamentManagementError(onRetry: _refreshSessions, error: error),
        data: (items) {
          if (items.isEmpty) {
            return TournamentManagementEmpty(
              title: l10n.tournamentManagementLivestreamSessionsEmpty,
              icon: Icons.podcasts_outlined,
            );
          }
          return Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                _LiveSessionTile(
                  session: items[index],
                  busy: _busySessionIds.contains(items[index].id),
                  statusLabel: _liveSessionStatusLabel(
                    l10n,
                    items[index].status,
                  ),
                  onRecheckStatus: () => _recheckSessionStatus(items[index]),
                  onStop: () => _stopSession(items[index]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FacebookConnectionBody extends StatelessWidget {
  const _FacebookConnectionBody({
    required this.connection,
    required this.busy,
    required this.onRevalidate,
    required this.onConnect,
    required this.onDisconnect,
  });

  final FacebookPageConnectionModel connection;
  final bool busy;
  final VoidCallback onRevalidate;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final lastChecked = connection.lastValidatedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                connection.pageName,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(
              label: _facebookStatusLabel(l10n, connection.status),
              color: connection.isActive ? colors.success : colors.textMuted,
            ),
          ],
        ),
        if (lastChecked != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.tournamentManagementLivestreamFacebookLastChecked(
              _formatTimestamp(context, lastChecked),
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
        // Re-check and unlink only make sense for a live authorization, so a
        // connection the backend still reports in any other state is a dead
        // end. The empty state's connect action is offered here as well: it
        // hands the repository's OAuth URL straight to the platform browser
        // and never shows, stores or logs it.
        if (connection.isActive)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onRevalidate,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  l10n.tournamentManagementLivestreamFacebookRevalidate,
                ),
              ),
              TextButton.icon(
                onPressed: busy ? null : onDisconnect,
                icon: const Icon(Icons.link_off_rounded),
                label: Text(
                  l10n.tournamentManagementLivestreamFacebookDisconnect,
                ),
              ),
            ],
          )
        else
          FilledButton.icon(
            onPressed: busy ? null : onConnect,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.tournamentManagementLivestreamFacebookConnect),
          ),
      ],
    );
  }
}

class _CameraDeviceTile extends StatelessWidget {
  const _CameraDeviceTile({
    required this.device,
    required this.busy,
    required this.onCreatePairingQr,
    required this.statusLabel,
  });

  final CameraDeviceModel device;
  final bool busy;
  final VoidCallback onCreatePairingQr;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onCreatePairingQr,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: Text(l10n.tournamentManagementLivestreamCreatePairingQr),
          ),
        ],
      ),
    );
  }
}

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
    final colors = context.colors;
    final title = (session.title?.trim().isNotEmpty ?? false)
        ? session.title!
        : session.matchId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(
                label: statusLabel,
                color: _sessionStatusColor(colors, session.status),
              ),
            ],
          ),
          if (supportsStatusRecheck(session.status) ||
              supportsStop(session.status)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (supportsStatusRecheck(session.status))
                  Tooltip(
                    message:
                        l10n.tournamentManagementLivestreamRecheckStatusHint,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onRecheckStatus,
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(
                        l10n.tournamentManagementLivestreamRecheckStatus,
                      ),
                    ),
                  ),
                if (supportsStop(session.status))
                  TextButton.icon(
                    onPressed: busy ? null : onStop,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(l10n.tournamentManagementLivestreamStopSession),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

String _formatTimestamp(BuildContext context, DateTime value) {
  final localizations = MaterialLocalizations.of(context);
  final local = value.toLocal();
  return '${localizations.formatMediumDate(local)} '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

Color _sessionStatusColor(
  AppColorsExtension colors,
  LiveSessionStatus status,
) => switch (status) {
  LiveSessionStatus.live => colors.success,
  LiveSessionStatus.starting ||
  LiveSessionStatus.reconnecting ||
  LiveSessionStatus.stopping => colors.warning,
  LiveSessionStatus.failed => colors.error,
  _ => colors.textMuted,
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

String _facebookStatusLabel(
  AppLocalizations l10n,
  FacebookPageConnectionStatus status,
) => switch (status) {
  FacebookPageConnectionStatus.active =>
    l10n.tournamentManagementLivestreamFacebookActive,
  FacebookPageConnectionStatus.disconnected =>
    l10n.tournamentManagementLivestreamFacebookDisconnected,
  FacebookPageConnectionStatus.revoked =>
    l10n.tournamentManagementLivestreamDeviceRevoked,
  FacebookPageConnectionStatus.unknown =>
    l10n.tournamentManagementLivestreamStatusOther,
};
