import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/camera_stream_key_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

/// Backend DTO rule for the stream name (`^[A-Za-z0-9_-]+$`, 1..255).
final _streamNamePattern = RegExp(r'^[A-Za-z0-9_-]+$');
const _streamNameMaxLength = 255;
const _keyMask = '••••••••';

/// Stream-key QR of one PUSH camera: shows the QR and the masked RTMP key,
/// issues a key (automatically once when the camera has none), renames the
/// stream while no key exists and rotates the key after a confirmation
/// (OpenSpec `quan-ly-giai-web-parity`, task 5.2).
///
/// The key, the RTMP server and the QR payload are secrets: they are only
/// drawn, never logged, never put in a message. Errors show the server's
/// own message. The revealed state lives in this widget and dies with it.
class StreamKeyQrSheet extends ConsumerStatefulWidget {
  const StreamKeyQrSheet({super.key, required this.camera});

  final TournamentCameraModel camera;

  /// Drag is off: the sheet can turn busy right after opening and the route's
  /// drag flags are fixed at push time; barrier and back go through the
  /// sheet's own `PopScope`.
  static Future<void> show(
    BuildContext context, {
    required TournamentCameraModel camera,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => StreamKeyQrSheet(camera: camera),
  );

  @override
  ConsumerState<StreamKeyQrSheet> createState() => _StreamKeyQrSheetState();
}

class _StreamKeyQrSheetState extends ConsumerState<StreamKeyQrSheet> {
  final _nameController = TextEditingController();
  CameraStreamKeyModel? _state;
  bool _loading = true;
  bool _busy = false;
  bool _revealed = false;
  bool _editingName = false;
  String? _loadError;
  String? _error;
  String? _nameError;
  String? _notice;

  /// Bumped by every load and write; a response whose id is no longer current
  /// is dropped so a stale read never overwrites a newer state.
  int _requestId = 0;

  /// One automatic issue per sheet opening.
  bool _autoIssued = false;

  @override
  void initState() {
    super.initState();
    _load(autoIssue: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _message(Object failure, AppLocalizations l10n) =>
      tournamentSheetServerMessage(failure) ??
      ErrorParser.parse(failure, l10n.tournamentCameraActionFailed, l10n);

  Future<void> _load({bool autoIssue = false, bool silent = false}) async {
    final id = ++_requestId;
    try {
      final next = await ref
          .read(cameraAdminRepositoryProvider)
          .getStreamKey(widget.camera.id);
      if (!mounted || id != _requestId) return;
      setState(() {
        _state = next;
        _loading = false;
        _loadError = null;
      });
      // A key id without RTMP details means the server forgot the key: that
      // one is only ever re-issued by an explicit tap.
      if (autoIssue &&
          !_autoIssued &&
          !next.hasKey &&
          next.streamKeyId == null) {
        _autoIssued = true;
        await _mutate(ref.read(cameraAdminRepositoryProvider).createStreamKey);
      }
    } on Object catch (failure) {
      if (!mounted || id != _requestId || silent) return;
      final text = _message(failure, AppLocalizations.of(context)!);
      setState(() {
        _loading = false;
        _loadError = text;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    // The once-per-open guard in _load still caps auto-issuing at one call.
    _load(autoIssue: true);
  }

  /// Runs one write. A failure shows the server message and re-reads the
  /// state (like the web), so the screen never shows a state the server does
  /// not have.
  Future<void> _mutate(
    Future<CameraStreamKeyModel> Function(String cameraId) call, {
    String? doneNotice,
  }) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    _requestId++;
    try {
      final next = await call(widget.camera.id);
      if (!mounted) return;
      setState(() {
        _state = next;
        _busy = false;
        _editingName = false;
        _revealed = false;
        _notice = doneNotice;
      });
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _message(failure, l10n);
      });
      await _load(silent: true);
    }
  }

  Future<void> _confirmRotate() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementConfirmTitle,
      message: l10n.tournamentStreamKeyRotateConfirm,
      confirmLabel: l10n.tournamentStreamKeyRotate,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _mutate(
      ref.read(cameraAdminRepositoryProvider).rotateStreamKey,
      doneNotice: l10n.tournamentStreamKeyRotated,
    );
  }

  void _startRename() {
    _nameController.text = _state?.streamName ?? '';
    setState(() {
      _editingName = true;
      _nameError = null;
    });
  }

  Future<void> _saveRename() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty ||
        name.length > _streamNameMaxLength ||
        !_streamNamePattern.hasMatch(name)) {
      setState(() => _nameError = l10n.tournamentStreamKeyRenameInvalid);
      return;
    }
    if (name == _state?.streamName) {
      setState(() {
        _nameError = null;
        _editingName = false;
      });
      return;
    }
    setState(() => _nameError = null);
    await _mutate(
      (cameraId) => ref
          .read(cameraAdminRepositoryProvider)
          .renameStreamKey(cameraId, name),
    );
  }

  Future<void> _copy(String value) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      setState(() {
        _error = null;
        _notice = l10n.tournamentStreamKeyCopied;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => _error = l10n.tournamentCameraActionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final state = _state;
    return TournamentManageSheet(
      title: l10n.tournamentStreamKeyTitle,
      busy: _busy,
      actions: [
        ?_primaryAction(l10n, state),
        OutlinedButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.camera.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const BoneBlockLoading(itemCount: 3, itemHeight: 48)
          else if (_loadError != null)
            Text(_loadError!, style: TextStyle(color: colors.error))
          else if (state != null)
            ..._buildState(l10n, state),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const ValueKey('stream-key-error'),
              style: TextStyle(color: colors.error),
            ),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 12),
            Text(_notice!, style: TextStyle(color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }

  /// The sheet's main action follows its state: retry, issue or rotate.
  Widget? _primaryAction(AppLocalizations l10n, CameraStreamKeyModel? state) {
    if (_loadError != null) {
      return FilledButton(
        key: const ValueKey('stream-key-retry'),
        onPressed: _busy ? null : _retry,
        child: Text(l10n.tournamentManagementRetry),
      );
    }
    if (_loading || state == null) return null;
    if (state.hasKey) {
      return FilledButton(
        key: const ValueKey('stream-key-rotate'),
        onPressed: _busy ? null : _confirmRotate,
        child: Text(l10n.tournamentStreamKeyRotate),
      );
    }
    return FilledButton(
      key: const ValueKey('stream-key-issue'),
      onPressed: _busy
          ? null
          : () => _mutate(
              ref.read(cameraAdminRepositoryProvider).createStreamKey,
            ),
      child: Text(
        state.streamKeyId == null
            ? l10n.tournamentStreamKeyIssue
            : l10n.tournamentStreamKeyReissue,
      ),
    );
  }

  List<Widget> _buildState(AppLocalizations l10n, CameraStreamKeyModel state) {
    final colors = context.colors;
    final qr = state.qrPayloadString;
    return [
      _buildNameRow(l10n, state),
      const SizedBox(height: 12),
      if (!state.hasKey)
        Text(
          state.streamKeyId == null
              ? l10n.tournamentStreamKeyNone
              : l10n.tournamentStreamKeyForgotten,
          style: TextStyle(color: colors.textSecondary),
        ),
      if (qr != null) ...[
        Center(
          child: Semantics(
            label: l10n.tournamentStreamKeyTitle,
            image: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                // The key is a digest, never the payload: it makes the QR
                // rebuild on rotate and is what tests match on.
                key: ValueKey('stream-key-qr-${qr.hashCode}'),
                data: qr,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tournamentStreamKeyQrWarning,
          style: TextStyle(color: colors.warning, fontSize: 12),
        ),
      ],
      if (state.hasKey) ...[
        const SizedBox(height: 12),
        _buildValueRow(
          label: l10n.tournamentStreamKeyServerLabel,
          value: state.rtmpServer!,
          copyTooltip: l10n.tournamentStreamKeyCopyServer,
        ),
        _buildValueRow(
          label: l10n.tournamentStreamKeyKeyLabel,
          value: state.rtmpStreamKey!,
          copyTooltip: l10n.tournamentStreamKeyCopyKey,
          secret: true,
        ),
      ],
    ];
  }

  Widget _buildNameRow(AppLocalizations l10n, CameraStreamKeyModel state) {
    final colors = context.colors;
    if (_editingName) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('stream-key-rename-field'),
              controller: _nameController,
              enabled: !_busy,
              maxLength: _streamNameMaxLength,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.tournamentStreamKeyStreamName,
                errorText: _nameError,
                errorMaxLines: 3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FilledButton.tonal(
              key: const ValueKey('stream-key-rename-save'),
              onPressed: _busy ? null : _saveRename,
              child: Text(l10n.tournamentStreamKeyRenameSave),
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() => _editingName = false),
            child: Text(l10n.tournamentManagementCancel),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                state.streamName,
                key: const ValueKey('stream-key-name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: colors.textPrimary,
                ),
              ),
            ),
            OutlinedButton(
              key: const ValueKey('stream-key-rename'),
              onPressed: _busy || state.hasKey ? null : _startRename,
              child: Text(l10n.tournamentStreamKeyRename),
            ),
          ],
        ),
        if (state.hasKey)
          Text(
            l10n.tournamentStreamKeyRenameLocked,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
      ],
    );
  }

  /// A label + value row with a copy button; a [secret] value is masked until
  /// the toggle reveals it.
  Widget _buildValueRow({
    required String label,
    required String value,
    required String copyTooltip,
    bool secret = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final hidden = secret && !_revealed;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(color: colors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hidden ? _keyMask : value,
              key: secret ? const ValueKey('stream-key-value') : null,
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.textPrimary,
              ),
            ),
          ),
          if (secret)
            IconButton(
              key: const ValueKey('stream-key-toggle'),
              tooltip: _revealed
                  ? l10n.tournamentStreamKeyHide
                  : l10n.tournamentStreamKeyShow,
              constraints: const BoxConstraints(
                minWidth: kMinTouchTarget,
                minHeight: kMinTouchTarget,
              ),
              onPressed: () => setState(() => _revealed = !_revealed),
              icon: Icon(
                _revealed
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          IconButton(
            tooltip: copyTooltip,
            constraints: const BoxConstraints(
              minWidth: kMinTouchTarget,
              minHeight: kMinTouchTarget,
            ),
            onPressed: () => _copy(value),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}
