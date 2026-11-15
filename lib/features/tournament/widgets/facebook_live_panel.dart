import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/facebook_live_error.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "Tạo live trên fanpage Facebook" trong form tạo camera: nút Tạo live (fanpage
/// chung của hệ thống) rồi khối khoá phát. Khoá phát chỉ nằm trong state của widget này.
class FacebookLivePanel extends StatefulWidget {
  const FacebookLivePanel({
    super.key,
    required this.tournamentId,
    required this.repository,
    required this.onCreated,
    this.enabled = true,
  });

  final String tournamentId;
  final IFacebookCameraLiveRepository repository;

  /// Cha điền link xem vào ô link.
  final ValueChanged<String> onCreated;
  final bool enabled;

  @override
  State<FacebookLivePanel> createState() => _FacebookLivePanelState();
}

class _FacebookLivePanelState extends State<FacebookLivePanel> {
  FacebookLiveConnection? _connection;
  bool _loadFailed = false;
  bool _busy = false;
  FacebookLiveError? _error;
  CreatedFacebookLive? _live;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final connection = await widget.repository.getConnection(
        widget.tournamentId,
      );
      if (!mounted) return;
      setState(() => _connection = connection);
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
          if (connection != null && live == null && connected)
            FilledButton.icon(
              key: const ValueKey('fb-live-create'),
              onPressed: canTap ? _create : null,
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.live_tv_outlined),
              label: Text(
                _busy
                    ? l10n.tournamentCameraFbWorking
                    : l10n.tournamentCameraFbCreate,
              ),
            ),
          if (connection != null && live == null && !connected)
            Text(
              l10n.tournamentCameraFbErrorNotConnected,
              key: const ValueKey('fb-live-not-configured'),
              style: TextStyle(color: colors.textSecondary),
            ),
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
