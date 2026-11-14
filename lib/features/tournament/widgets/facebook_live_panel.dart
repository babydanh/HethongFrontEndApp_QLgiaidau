import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/facebook_live_error.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// "Tạo live trên fanpage Facebook" trong form tạo camera: nút Kết nối/Tạo live
/// rồi khối khoá phát. Khoá phát chỉ nằm trong state của widget này.
class FacebookLivePanel extends StatefulWidget {
  const FacebookLivePanel({
    super.key,
    required this.tournamentId,
    required this.repository,
    required this.onCreated,
    this.enabled = true,
    this.launcher = _launchExternal,
  });

  final String tournamentId;
  final IFacebookCameraLiveRepository repository;

  /// Cha điền link xem vào ô link.
  final ValueChanged<String> onCreated;
  final bool enabled;
  final ExternalLauncher launcher;

  @override
  State<FacebookLivePanel> createState() => _FacebookLivePanelState();
}

class _FacebookLivePanelState extends State<FacebookLivePanel>
    with WidgetsBindingObserver {
  FacebookLiveConnection? _connection;
  bool _loadFailed = false;
  bool _busy = false;
  bool _awaitingReturn = false;
  FacebookLiveError? _error;
  CreatedFacebookLive? _live;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Quay lại app sau khi cấp quyền ở trình duyệt thì tự kiểm tra lại.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingReturn && !_busy) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final connection = await widget.repository.getConnection(
        widget.tournamentId,
      );
      if (!mounted) return;
      setState(() {
        _connection = connection;
        if (connection.connected) _awaitingReturn = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  /// Chặn bấm đôi bằng cờ `_busy` đặt đồng bộ trước mọi `await`.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on Object catch (failure) {
      if (mounted) setState(() => _error = facebookLiveError(failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _run(() async {
    final communityId = _connection?.communityId;
    if (communityId == null) return;
    final url = await widget.repository.getConnectUrl(communityId);
    final opened = await widget.launcher(url);
    if (!opened) {
      if (mounted) setState(() => _error = FacebookLiveError.browser);
      return;
    }
    if (mounted) setState(() => _awaitingReturn = true);
  });

  Future<void> _create() => _run(() async {
    final live = await widget.repository.createLive(widget.tournamentId);
    if (!mounted) return;
    setState(() => _live = live);
    widget.onCreated(live.watchUrl);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final connection = _connection;
    final connected = connection?.connected == true;
    final hasCommunity = connection?.communityId != null;
    final canTap = widget.enabled && !_busy;
    final live = _live;
    return Container(
      key: const ValueKey('fb-live-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tournamentCameraFbTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tournamentCameraFbHint,
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (connection == null && !_loadFailed)
            Row(
              key: const ValueKey('fb-live-checking'),
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.tournamentCameraFbChecking)),
              ],
            ),
          if (_loadFailed) ...[
            Text(
              l10n.tournamentCameraFbErrorNetwork,
              key: const ValueKey('fb-live-load-error'),
              style: TextStyle(color: colors.error),
            ),
            TextButton(
              key: const ValueKey('fb-live-recheck'),
              onPressed: _load,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(l10n.tournamentCameraFbRecheck),
            ),
          ],
          if (connection != null && live == null) ...[
            if (connected && connection.pageName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.tournamentCameraFbPage(connection.pageName!),
                  key: const ValueKey('fb-live-page'),
                ),
              ),
            FilledButton.icon(
              key: ValueKey(connected ? 'fb-live-create' : 'fb-live-connect'),
              onPressed: canTap && (connected || hasCommunity)
                  ? (connected ? _create : _connect)
                  : null,
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(connected ? Icons.live_tv_outlined : Icons.link),
              label: Text(
                _busy
                    ? l10n.tournamentCameraFbWorking
                    : connected
                    ? l10n.tournamentCameraFbCreate
                    : l10n.tournamentCameraFbConnect,
              ),
            ),
            if (!connected && !hasCommunity)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.tournamentCameraFbNoCommunity),
              ),
            if (!connected && _awaitingReturn) ...[
              const SizedBox(height: 8),
              Text(l10n.tournamentCameraFbConnectHelp),
              TextButton(
                key: const ValueKey('fb-live-recheck'),
                onPressed: canTap ? _load : null,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(l10n.tournamentCameraFbRecheck),
              ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                facebookLiveErrorText(l10n, _error!),
                key: const ValueKey('fb-live-error'),
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
          if (live != null) ...[
            Text(
              l10n.tournamentCameraFbHowTo,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _SecretRow(
              fieldKey: 'fb-live-rtmp',
              label: l10n.tournamentCameraFbRtmpLabel,
              value: live.rtmpUrl,
            ),
            const SizedBox(height: 12),
            _SecretRow(
              fieldKey: 'fb-live-key',
              label: l10n.tournamentCameraFbKeyLabel,
              value: live.streamKey,
              masked: true,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tournamentCameraFbKeyWarning,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecretRow extends StatefulWidget {
  const _SecretRow({
    required this.fieldKey,
    required this.label,
    required this.value,
    this.masked = false,
  });

  final String fieldKey;
  final String label;
  final String value;
  final bool masked;

  @override
  State<_SecretRow> createState() => _SecretRowState();
}

class _SecretRowState extends State<_SecretRow> {
  bool _visible = false;

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: widget.value));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.tournamentCameraFbCopied(widget.label))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextFormField(
            key: ValueKey(widget.fieldKey),
            initialValue: widget.value,
            readOnly: true,
            obscureText: widget.masked && !_visible,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              labelText: widget.label,
              isDense: true,
            ),
          ),
        ),
        if (widget.masked)
          IconButton(
            key: ValueKey('${widget.fieldKey}-toggle'),
            tooltip: _visible
                ? l10n.tournamentCameraFbHideKey
                : l10n.tournamentCameraFbShowKey,
            onPressed: () => setState(() => _visible = !_visible),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            ),
          ),
        IconButton(
          key: ValueKey('${widget.fieldKey}-copy'),
          tooltip: l10n.tournamentCameraFbCopy(widget.label),
          onPressed: _copy,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.copy_outlined),
        ),
      ],
    );
  }
}
