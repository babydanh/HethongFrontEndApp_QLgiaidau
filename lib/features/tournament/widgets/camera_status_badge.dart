import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Trạng thái camera sân (`camera.status`), cùng 6 giá trị với badge của Web.
enum CameraStatusKind {
  ready,
  assigned,
  waiting,
  live,
  offline,
  error,
  unknown;

  static CameraStatusKind parse(String? status) => switch (status) {
    'IDLE' => ready,
    'ASSIGNED' => assigned,
    'WAITING' => waiting,
    'LIVE' => live,
    'OFFLINE' => offline,
    'ERROR' => error,
    _ => unknown,
  };
}

/// Chấm màu + chữ: trạng thái không chỉ dựa vào màu.
class CameraStatusBadge extends StatelessWidget {
  const CameraStatusBadge({super.key, required this.status});

  final String? status;

  String _label(AppLocalizations l10n, CameraStatusKind kind) => switch (kind) {
    CameraStatusKind.ready => l10n.tournamentManagementCameraBadgeReady,
    CameraStatusKind.assigned => l10n.tournamentManagementCameraBadgeAssigned,
    CameraStatusKind.waiting => l10n.tournamentManagementCameraBadgeWaiting,
    CameraStatusKind.live => l10n.tournamentManagementCameraBadgeLive,
    CameraStatusKind.offline => l10n.tournamentManagementCameraBadgeOffline,
    CameraStatusKind.error => l10n.tournamentManagementCameraBadgeError,
    CameraStatusKind.unknown => l10n.tournamentManagementCameraBadgeUnknown,
  };

  Color _tone(AppColorsExtension colors, CameraStatusKind kind) =>
      switch (kind) {
        CameraStatusKind.ready => colors.success,
        CameraStatusKind.assigned => colors.info,
        CameraStatusKind.waiting => colors.warning,
        CameraStatusKind.live => const Color(0xFFE11D48),
        CameraStatusKind.offline => colors.textMuted,
        CameraStatusKind.error => colors.error,
        CameraStatusKind.unknown => colors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final kind = CameraStatusKind.parse(status);
    final label = _label(l10n, kind);
    final tone = _tone(colors, kind);
    return Semantics(
      label: l10n.tournamentManagementCameraBadgeSemantics(label),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: tone.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: const ValueKey('camera-status-dot'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
