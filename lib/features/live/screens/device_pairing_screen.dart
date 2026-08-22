import 'dart:convert';
import 'package:app_quanly_giaidau/core/services/device_fingerprint_storage.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/live_session_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  const DevicePairingScreen({required this.communityId, super.key});

  final String communityId;

  @override
  ConsumerState<DevicePairingScreen> createState() =>
      _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isPairing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<String> _getDeviceFingerprint() {
    return deviceFingerprintStorage.getOrCreate();
  }

  String _pairingFailureMessage(Object error, AppLocalizations l10n) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      final code = responseData is Map
          ? responseData['code']?.toString()
          : null;
      if (statusCode == 403) return l10n.devicePairingNotAllowed;
      if (code == 'PUBLISH_CONFIG_EXPIRED') return l10n.devicePairingExpired;
      if (code == 'CAMERA_NOT_READY') return l10n.devicePairingInvalidCode;
    }
    return l10n.devicePairingUnavailable;
  }

  Map<String, String>? _parsePairingPayload(String value) {
    final trimmed = value.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final deviceId = decoded['deviceId']?.toString();
        final pairingToken = decoded['pairingToken']?.toString();
        if (deviceId != null &&
            pairingToken != null &&
            deviceId.isNotEmpty &&
            pairingToken.isNotEmpty) {
          return <String, String>{
            'deviceId': deviceId,
            'pairingToken': pairingToken,
          };
        }
      }
    } on FormatException {
      // QR payload may be a URL instead of JSON.
    }

    final uri = Uri.tryParse(trimmed);
    final deviceId = uri?.queryParameters['deviceId'];
    final pairingToken = uri?.queryParameters['pairingToken'];
    if (deviceId == null ||
        pairingToken == null ||
        deviceId.isEmpty ||
        pairingToken.isEmpty) {
      return null;
    }
    return <String, String>{'deviceId': deviceId, 'pairingToken': pairingToken};
  }

  Future<void> _pairFromScan(String rawValue) async {
    if (_isPairing) return;
    final l10n = AppLocalizations.of(context)!;
    final payload = _parsePairingPayload(rawValue);
    if (payload == null) {
      setState(() => _errorMessage = l10n.devicePairingInvalidCode);
      return;
    }

    setState(() {
      _isPairing = true;
      _errorMessage = null;
    });
    await _scannerController.stop();
    try {
      final fingerprint = await _getDeviceFingerprint();
      await ref
          .read(liveSessionRepositoryProvider)
          .pairDevice(
            deviceId: payload['deviceId']!,
            pairingToken: payload['pairingToken']!,
            deviceFingerprint: fingerprint,
          );
      if (!mounted) return;
      ref.invalidate(cameraDevicesProvider(widget.communityId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.devicePairingSuccess)));
      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPairing = false;
        _errorMessage = _pairingFailureMessage(error, l10n);
      });
      await _scannerController.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPairing = false;
        _errorMessage = l10n.devicePairingUnavailable;
      });
      await _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devicePairingTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.devicePairingClose,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Text(
              l10n.devicePairingInstruction,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    for (final barcode in capture.barcodes) {
                      final rawValue = barcode.rawValue;
                      if (rawValue != null) {
                        _pairFromScan(rawValue);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            if (_isPairing) ...<Widget>[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isPairing
                  ? null
                  : () async {
                      setState(() => _errorMessage = null);
                      await _scannerController.start();
                    },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.devicePairingScanAgain),
            ),
          ],
        ),
      ),
    );
  }
}
