import 'dart:convert';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The exact payload `DevicePairingScreen` scans: a JSON object with only
/// `deviceId` and `pairingToken`. Kept as a function so the contract stays
/// verifiable without decoding a rendered QR.
String buildLivestreamPairingPayload({
  required String deviceId,
  required String pairingToken,
}) => jsonEncode(<String, String>{
  'deviceId': deviceId,
  'pairingToken': pairingToken,
});

/// Shows a single-use camera pairing QR for the lifetime of the sheet.
///
/// The token is held only in this widget's field, is never persisted, copied,
/// shared, toasted or logged, and is dropped in [dispose] as soon as the sheet
/// goes away.
Future<void> showLivestreamPairingQrSheet(
  BuildContext context, {
  required String deviceId,
  required String deviceName,
  required String pairingToken,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _LivestreamPairingQrSheet(
      deviceId: deviceId,
      deviceName: deviceName,
      pairingToken: pairingToken,
    ),
  );
}

class _LivestreamPairingQrSheet extends StatefulWidget {
  const _LivestreamPairingQrSheet({
    required this.deviceId,
    required this.deviceName,
    required this.pairingToken,
  });

  final String deviceId;
  final String deviceName;
  final String pairingToken;

  @override
  State<_LivestreamPairingQrSheet> createState() =>
      _LivestreamPairingQrSheetState();
}

class _LivestreamPairingQrSheetState extends State<_LivestreamPairingQrSheet> {
  /// Nulled out on close so the one-time secret does not outlive the sheet.
  String? _payload;

  @override
  void initState() {
    super.initState();
    _payload = buildLivestreamPairingPayload(
      deviceId: widget.deviceId,
      pairingToken: widget.pairingToken,
    );
  }

  @override
  void dispose() {
    _payload = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final payload = _payload;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tournamentManagementLivestreamPairingQrTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.deviceName,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (payload == null)
              const SizedBox(height: 220)
            else
              Center(
                child: QrImageView(
                  data: payload,
                  size: 220,
                  semanticsLabel:
                      l10n.tournamentManagementLivestreamPairingQrTitle,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              l10n.tournamentManagementLivestreamPairingQrHint,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.devicePairingClose),
            ),
          ],
        ),
      ),
    );
  }
}
