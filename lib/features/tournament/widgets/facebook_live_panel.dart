import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/facebook_live_error.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// "Tạo live trên fanpage Facebook" trong form tạo camera: một nút tạo live trên
/// fanpage chung rồi giao live cho cha ([onCreated]) để tạo camera. Khoá phát đi
/// theo [CreatedFacebookLive] sang sheet "Camera đã sẵn sàng", không nằm lại đây.
class FacebookLivePanel extends StatefulWidget {
  const FacebookLivePanel({
    super.key,
    required this.tournamentId,
    required this.repository,
    required this.onCreated,
    this.onBeforeCreate,
    this.onBusyChanged,
    this.enabled = true,
  });

  final String tournamentId;
  final IFacebookCameraLiveRepository repository;

  /// Cha tạo camera từ live vừa tạo; panel giữ nút bận cho tới khi xong.
  final Future<void> Function(CreatedFacebookLive live) onCreated;

  /// Cha kiểm dữ liệu form trước khi gọi Facebook; trả false thì không tạo live.
  final bool Function()? onBeforeCreate;

  /// Báo cha khi panel bắt đầu/xong việc, để cha khoá phần còn lại của sheet.
  final ValueChanged<bool>? onBusyChanged;
  final bool enabled;

  @override
  State<FacebookLivePanel> createState() => _FacebookLivePanelState();
}

class _FacebookLivePanelState extends State<FacebookLivePanel> {
  FacebookLiveConnection? _connection;
  bool _loadFailed = false;
  bool _busy = false;
  FacebookLiveError? _error;

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
    widget.onBusyChanged?.call(true);
    try {
      await action();
    } on Object catch (failure) {
      if (mounted) setState(() => _error = facebookLiveError(failure));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged?.call(false);
      }
    }
  }

  Future<void> _create() async {
    if (_busy || widget.onBeforeCreate?.call() == false) return;
    await _run(_createAndHandOver);
  }

  Future<void> _createAndHandOver() async {
    final live = await widget.repository.createLive(widget.tournamentId);
    if (!mounted) return;
    await widget.onCreated(live);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final connection = _connection;
    final connected = connection?.connected == true;
    final canTap = widget.enabled && !_busy;
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
          if (connection != null && connected)
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
                    ? l10n.tournamentCameraFbCreatingCamera
                    : l10n.tournamentCameraFbCreateCamera,
              ),
            ),
          if (connection != null && !connected)
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
        ],
      ),
    );
  }
}
