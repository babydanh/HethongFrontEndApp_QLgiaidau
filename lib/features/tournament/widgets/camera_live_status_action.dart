import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraLiveStatusAction extends ConsumerStatefulWidget {
  const CameraLiveStatusAction({super.key, required this.cameraId});

  final String cameraId;

  @override
  ConsumerState<CameraLiveStatusAction> createState() =>
      _CameraLiveStatusActionState();
}

class _CameraLiveStatusActionState
    extends ConsumerState<CameraLiveStatusAction> {
  CameraLiveStatusModel? _status;
  bool _loading = false;
  bool _failed = false;
  int? _failureStatusCode;
  int _requestGeneration = 0;

  @override
  void didUpdateWidget(covariant CameraLiveStatusAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraId == widget.cameraId) return;
    _requestGeneration++;
    _status = null;
    _loading = false;
    _failed = false;
    _failureStatusCode = null;
  }

  Future<void> _checkStatus() async {
    if (_loading) return;
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _status = null;
      _failed = false;
      _failureStatusCode = null;
    });

    try {
      final status = await ref
          .read(courtCameraRepositoryProvider)
          .getCameraLiveStatus(widget.cameraId);
      if (!mounted || generation != _requestGeneration) return;
      if (status.cameraId != widget.cameraId) {
        throw const FormatException('Invalid camera status response.');
      }
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      final statusCode = error is DioException
          ? error.response?.statusCode
          : null;
      setState(() {
        _loading = false;
        _failed = true;
        _failureStatusCode = _isTerminalStatusCode(statusCode)
            ? statusCode
            : null;
      });
    }
  }

  String _statusLabel(AppLocalizations l10n, CameraLiveStatusModel status) {
    if (status.status == CameraLiveStatus.archived) {
      return l10n.tournamentManagementCameraArchived;
    }
    return status.online
        ? l10n.tournamentManagementCameraSignalOnline
        : l10n.tournamentManagementCameraSignalOffline;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final terminalFailure = _isTerminalStatusCode(_failureStatusCode);
    final failureMessage = switch (_failureStatusCode) {
      401 => l10n.authSessionExpired,
      403 => l10n.tournamentManagementCameraAccessDenied,
      404 => l10n.tournamentManagementCameraUnavailable,
      _ => l10n.tournamentManagementCameraStatusError,
    };
    final buttonLabel = _loading
        ? l10n.tournamentManagementCameraCheckingStatus
        : _status == null
        ? l10n.tournamentManagementCameraCheckStatus
        : l10n.tournamentManagementCameraCheckAgain;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppTheme.spacingSM,
      runSpacing: AppTheme.spacingXS,
      children: [
        OutlinedButton.icon(
          onPressed: _loading || terminalFailure ? null : _checkStatus,
          icon: _loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sensors_rounded),
          label: Text(buttonLabel),
        ),
        if (_status case final status?)
          Semantics(
            liveRegion: true,
            child: Text(
              _statusLabel(l10n, status),
              style: TextStyle(
                color: status.status == CameraLiveStatus.archived
                    ? colors.onSurfaceVariant
                    : status.online
                    ? colors.primary
                    : colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_failed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  failureMessage,
                  style: TextStyle(color: colors.error),
                ),
              ),
              if (!terminalFailure)
                TextButton(
                  onPressed: _loading ? null : _checkStatus,
                  child: Text(l10n.opsRetry),
                ),
            ],
          ),
      ],
    );
  }
}

bool _isTerminalStatusCode(int? statusCode) =>
    statusCode == 401 ||
    statusCode == 403 ||
    statusCode == 404 ||
    statusCode == 409;
