import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/larix_link.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> _launchExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Thân sheet "Camera đã sẵn sàng" sau khi tạo camera live Facebook một nút: máy
/// chủ RTMP, khoá phát (che sẵn), nút Mở trong Larix và QR của cùng link Larix
/// (ẩn cho tới khi bấm Hiện mã QR vì QR chứa khoá phát). Khoá phát chỉ vẽ ra,
/// không log, không lưu; trạng thái hiện/ẩn chết cùng sheet.
class FacebookLiveReadySheet extends StatefulWidget {
  const FacebookLiveReadySheet({
    super.key,
    required this.live,
    required this.cameraName,
    required this.launchLink,
  });

  final CreatedFacebookLive live;
  final String cameraName;

  /// Mở link ngoài app (Larix); tách ra để test không gọi plugin thật.
  final Future<bool> Function(Uri uri) launchLink;

  static Future<void> show(
    BuildContext context, {
    required CreatedFacebookLive live,
    required String cameraName,
    Future<bool> Function(Uri uri)? launchLink,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManageSheet.show<void>(
      context,
      title: l10n.tournamentCameraFbReadyTitle,
      actions: [
        FilledButton(
          key: const ValueKey('fb-live-ready-done'),
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(l10n.tournamentCameraFbReadyDone),
        ),
      ],
      child: FacebookLiveReadySheet(
        live: live,
        cameraName: cameraName,
        launchLink: launchLink ?? _launchExternal,
      ),
    );
  }

  @override
  State<FacebookLiveReadySheet> createState() => _FacebookLiveReadySheetState();
}

class _FacebookLiveReadySheetState extends State<FacebookLiveReadySheet> {
  bool _launching = false;
  bool _qrVisible = false;

  /// Larix chưa cài (hoặc không mở được) thì báo cách xử lý thay vì im lặng.
  Future<void> _openLarix(String link) async {
    if (_launching) return;
    final messenger = ScaffoldMessenger.of(context);
    final missing = AppLocalizations.of(
      context,
    )!.tournamentCameraFbLarixMissing;
    setState(() => _launching = true);
    var opened = false;
    try {
      opened = await widget.launchLink(Uri.parse(link));
    } on Object {
      opened = false;
    } finally {
      if (mounted) setState(() => _launching = false);
    }
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(missing)));
    }
  }

  /// QR hidden by default, like the web: it carries the stream key.
  List<Widget> _buildQr(AppLocalizations l10n, String link) {
    final colors = context.colors;
    return [
      OutlinedButton.icon(
        key: const ValueKey('fb-live-qr-toggle'),
        onPressed: () => setState(() => _qrVisible = !_qrVisible),
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: Icon(_qrVisible ? Icons.visibility_off_outlined : Icons.qr_code_2),
        label: Text(
          _qrVisible
              ? l10n.tournamentCameraFbReadyHideQr
              : l10n.tournamentCameraFbReadyShowQr,
        ),
      ),
      if (_qrVisible) ...[
        const SizedBox(height: 12),
        Center(
          child: Semantics(
            label: l10n.tournamentCameraFbReadyQrLabel,
            image: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                key: const ValueKey('fb-live-qr'),
                data: link,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tournamentCameraFbReadyQrWarning,
          style: TextStyle(color: colors.warning, fontSize: 12),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final live = widget.live;
    final larixLink = buildLarixSetupUrl(
      live.rtmpUrl,
      live.streamKey,
      'SportO Live',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.cameraName,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tournamentCameraFbReadyHint,
          style: TextStyle(color: colors.textSecondary),
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
        if (larixLink != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('fb-live-larix-open'),
            onPressed: _launching ? null : () => _openLarix(larixLink),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.smartphone_outlined),
            label: Text(l10n.tournamentCameraFbLarixOpen),
          ),
          const SizedBox(height: 12),
          ..._buildQr(l10n, larixLink),
        ],
      ],
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
