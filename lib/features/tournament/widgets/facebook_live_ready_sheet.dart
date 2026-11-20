import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/rtmp_url.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Thân sheet "Camera đã sẵn sàng" sau khi tạo camera live Facebook một nút: máy
/// chủ RTMP, khoá phát (che sẵn) và QR RTMP thuần (hiện sẵn, có nút Ẩn vì QR
/// chứa khoá phát). Khoá phát chỉ vẽ ra, không log, không lưu; trạng thái
/// hiện/ẩn chết cùng sheet.
class FacebookLiveReadySheet extends StatefulWidget {
  const FacebookLiveReadySheet({
    super.key,
    required this.live,
    required this.cameraName,
  });

  final CreatedFacebookLive live;
  final String cameraName;

  static Future<void> show(
    BuildContext context, {
    required CreatedFacebookLive live,
    required String cameraName,
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
      child: FacebookLiveReadySheet(live: live, cameraName: cameraName),
    );
  }

  @override
  State<FacebookLiveReadySheet> createState() => _FacebookLiveReadySheetState();
}

class _FacebookLiveReadySheetState extends State<FacebookLiveReadySheet> {
  bool _qrVisible = true;

  Widget _qrFigure(String key, String label, String data) {
    return Semantics(
      label: label,
      image: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              key: ValueKey(key),
              data: data,
              version: QrVersions.auto,
              size: 200,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// The RTMP QR is shown right away; the toggle only hides it.
  List<Widget> _buildQr(AppLocalizations l10n, String plain) {
    final colors = context.colors;
    return [
      OutlinedButton.icon(
        key: const ValueKey('fb-live-qr-toggle'),
        onPressed: () => setState(() => _qrVisible = !_qrVisible),
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: Icon(
          _qrVisible ? Icons.visibility_off_outlined : Icons.qr_code_2,
        ),
        label: Text(
          _qrVisible
              ? l10n.tournamentCameraFbReadyHideQr
              : l10n.tournamentCameraFbReadyShowQr,
        ),
      ),
      if (_qrVisible) ...[
        const SizedBox(height: 12),
        _qrFigure(
          'fb-live-qr',
          l10n.tournamentCameraFbReadyQrPlainLabel,
          plain,
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
    final plainRtmp = buildPlainRtmpUrl(live.rtmpUrl, live.streamKey);
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
        if (plainRtmp != null) ...[
          const SizedBox(height: 12),
          ..._buildQr(l10n, plainRtmp),
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
            decoration: InputDecoration(labelText: widget.label, isDense: true),
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
              _visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
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
