import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_spacing.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/services/camera_rtsp_url.dart';
import 'package:app_quanly_giaidau/features/camera_bridge/camera_bridge_notifier.dart';
import 'package:app_quanly_giaidau/features/camera_bridge/ffmpeg_runner.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _defaultRtspPort = 554;
const _wideLayoutWidth = 720.0;

/// Lets the organizer type the LAN address of up to two IP cameras. The device
/// pulls RTSP inside the venue and pushes RTMP to the tournament's stream key.
class CameraBridgeScreen extends StatefulWidget {
  const CameraBridgeScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  State<CameraBridgeScreen> createState() => _CameraBridgeScreenState();
}

class _CameraBridgeScreenState extends State<CameraBridgeScreen> {
  bool _showSecond = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = <Widget>[
      _CameraCard(tournamentId: widget.tournamentId, slot: 1),
      if (_showSecond)
        _CameraCard(
          tournamentId: widget.tournamentId,
          slot: 2,
          onRemove: () => setState(() => _showSecond = false),
        ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cameraBridge_title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, box) => box.maxWidth >= _wideLayoutWidth
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final card in cards) Expanded(child: card),
                        ],
                      )
                    : Column(children: cards),
              ),
              if (!_showSecond)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showSecond = true),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.cameraBridge_addCamera2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraCard extends ConsumerStatefulWidget {
  const _CameraCard({
    required this.tournamentId,
    required this.slot,
    this.onRemove,
  });

  final String tournamentId;
  final int slot;
  final VoidCallback? onRemove;

  @override
  ConsumerState<_CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends ConsumerState<_CameraCard> {
  final _formKey = GlobalKey<FormState>();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '$_defaultRtspPort');
  final _user = TextEditingController();
  final _password = TextEditingController();
  CameraBrand _brand = CameraBrand.dahua;
  bool _mainStream = true;
  bool _hidePassword = true;
  bool _busy = false;
  bool _setupFailed = false;

  /// The PUSH camera this card owns on the server; created on first start.
  String? _cameraId;

  String get _bridgeKey => '${widget.tournamentId}#${widget.slot}';

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  ValueKey<String> _key(String name) =>
      ValueKey('cameraBridge-${widget.slot}-$name');

  Future<void> _start() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _busy = true;
    setState(() => _setupFailed = false);
    final params = await _resolveParams();
    if (!mounted) return;
    setState(() => _busy = false);
    if (params == null) {
      setState(() => _setupFailed = true);
      return;
    }
    unawaited(ref.read(cameraBridgeProvider(_bridgeKey).notifier).start(params));
  }

  /// Gets the push address of this card's camera, or null when the server
  /// call failed.
  Future<BridgeStartParams?> _resolveParams() async {
    final repo = ref.read(cameraAdminRepositoryProvider);
    try {
      final id = _cameraId ??= (await repo.createCamera(
        tournamentId: widget.tournamentId,
        name: 'Camera IP ${widget.slot}',
        mode: 'PUSH',
      )).id;
      var key = await repo.getStreamKey(id);
      if (!key.hasKey) key = await repo.createStreamKey(id);
      if (!key.hasKey) return null;
      return BridgeStartParams(
        brand: _brand,
        host: _host.text.trim(),
        port: int.parse(_port.text.trim()),
        user: _user.text.trim(),
        password: _password.text,
        mainStream: _mainStream,
        rtmpServer: key.rtmpServer!,
        rtmpStreamKey: key.rtmpStreamKey!,
      );
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bridge = ref.watch(cameraBridgeProvider(_bridgeKey));
    final running =
        bridge.status == BridgeStatus.connecting ||
        bridge.status == BridgeStatus.live;
    return Card(
      margin: const EdgeInsets.all(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(l10n, bridge),
              const SizedBox(height: AppSpacing.md),
              ..._fields(l10n, enabled: !running),
              _errorLine(l10n, bridge),
              const SizedBox(height: AppSpacing.md),
              _actionButton(l10n, running),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n, CameraBridgeState bridge) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.cameraBridge_cameraN(widget.slot),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        _StatusBadge(cameraNumber: widget.slot, status: bridge.status),
        if (widget.onRemove != null)
          IconButton(
            key: _key('remove'),
            tooltip: l10n.cameraBridge_removeCamera,
            onPressed: () {
              unawaited(
                ref.read(cameraBridgeProvider(_bridgeKey).notifier).stop(),
              );
              widget.onRemove!();
            },
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }

  List<Widget> _fields(AppLocalizations l10n, {required bool enabled}) {
    const gap = SizedBox(height: AppSpacing.md);
    return [
      TextFormField(
        key: _key('host'),
        controller: _host,
        enabled: enabled,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: l10n.cameraBridge_fieldHost),
        validator: (v) =>
            (v ?? '').trim().isEmpty ? l10n.cameraBridge_hostRequired : null,
      ),
      gap,
      DropdownButtonFormField<CameraBrand>(
        key: _key('brand'),
        initialValue: _brand,
        decoration: InputDecoration(labelText: l10n.cameraBridge_fieldBrand),
        items: [
          DropdownMenuItem(
            value: CameraBrand.dahua,
            child: Text(l10n.cameraBridge_brandDahua),
          ),
          DropdownMenuItem(
            value: CameraBrand.hikvision,
            child: Text(l10n.cameraBridge_brandHikvision),
          ),
        ],
        onChanged: enabled ? (v) => setState(() => _brand = v ?? _brand) : null,
      ),
      gap,
      _portAndStream(l10n, enabled),
      gap,
      TextFormField(
        key: _key('user'),
        controller: _user,
        enabled: enabled,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        decoration: InputDecoration(labelText: l10n.cameraBridge_fieldUser),
        validator: (v) =>
            (v ?? '').trim().isEmpty ? l10n.cameraBridge_userRequired : null,
      ),
      gap,
      _passwordField(l10n, enabled),
    ];
  }

  Widget _portAndStream(AppLocalizations l10n, bool enabled) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: TextFormField(
            key: _key('port'),
            controller: _port,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.cameraBridge_fieldPort),
            validator: (v) {
              final port = int.tryParse((v ?? '').trim());
              return port == null || port < 1 || port > 65535
                  ? l10n.cameraBridge_portInvalid
                  : null;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: SegmentedButton<bool>(
            key: _key('stream'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: true,
                label: Text(l10n.cameraBridge_streamMain, maxLines: 1),
              ),
              ButtonSegment(
                value: false,
                label: Text(l10n.cameraBridge_streamSub, maxLines: 1),
              ),
            ],
            selected: {_mainStream},
            onSelectionChanged: enabled
                ? (s) => setState(() => _mainStream = s.first)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _passwordField(AppLocalizations l10n, bool enabled) {
    return TextFormField(
      key: _key('password'),
      controller: _password,
      enabled: enabled,
      obscureText: _hidePassword,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: l10n.cameraBridge_fieldPassword,
        suffixIcon: IconButton(
          key: _key('togglePassword'),
          tooltip: _hidePassword
              ? l10n.cameraBridge_showPassword
              : l10n.cameraBridge_hidePassword,
          onPressed: () => setState(() => _hidePassword = !_hidePassword),
          icon: Icon(
            _hidePassword ? Icons.visibility : Icons.visibility_off,
          ),
        ),
      ),
      validator: (v) =>
          (v ?? '').isEmpty ? l10n.cameraBridge_passwordRequired : null,
    );
  }

  Widget _errorLine(AppLocalizations l10n, CameraBridgeState bridge) {
    final message = _setupFailed
        ? l10n.cameraBridge_errorSetup
        : bridge.status == BridgeStatus.error
        ? _failureText(l10n, bridge.failure)
        : null;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(message, style: TextStyle(color: context.colors.error)),
    );
  }

  String _failureText(AppLocalizations l10n, BridgeFailure? failure) {
    return switch (failure) {
      BridgeFailure.auth => l10n.cameraBridge_errorAuth,
      BridgeFailure.unreachable => l10n.cameraBridge_errorUnreachable,
      BridgeFailure.codec => l10n.cameraBridge_errorCodec,
      BridgeFailure.invalidInput => l10n.cameraBridge_errorInvalid,
      _ => l10n.cameraBridge_errorOther,
    };
  }

  Widget _actionButton(AppLocalizations l10n, bool running) {
    const minSize = WidgetStatePropertyAll(Size.fromHeight(48));
    if (running) {
      return OutlinedButton(
        onPressed: () => unawaited(
          ref.read(cameraBridgeProvider(_bridgeKey).notifier).stop(),
        ),
        style: ButtonStyle(minimumSize: minSize),
        child: Text(l10n.cameraBridge_stop),
      );
    }
    return FilledButton(
      onPressed: _busy ? null : _start,
      style: ButtonStyle(minimumSize: minSize),
      child: Text(l10n.cameraBridge_start),
    );
  }
}

/// Dot plus word, never colour alone; announced as one sentence.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.cameraNumber, required this.status});

  final int cameraNumber;
  final BridgeStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final (label, color) = switch (status) {
      BridgeStatus.idle => (l10n.cameraBridge_statusIdle, colors.textMuted),
      BridgeStatus.connecting => (
        l10n.cameraBridge_statusConnecting,
        colors.warning,
      ),
      BridgeStatus.live => (l10n.cameraBridge_statusLive, colors.success),
      BridgeStatus.error => (l10n.cameraBridge_statusError, colors.error),
    };
    return Semantics(
      liveRegion: true,
      label: '${l10n.cameraBridge_cameraN(cameraNumber)}: $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}
