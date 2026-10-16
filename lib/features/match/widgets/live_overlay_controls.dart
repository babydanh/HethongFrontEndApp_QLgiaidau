import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Chừa đúng chiều cao thanh điều khiển video (6 + 44 + 6) phía dưới overlay.
const double liveOverlayBottomInset = 64;

const Curve liveOverlayMotionCurve = Curves.easeOutCubic;

/// 240 ms; tắt hẳn khi hệ thống bật giảm chuyển động.
Duration liveOverlayMotionDuration(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 240);
}

/// Overlay cần hiện theo cờ server. Server ép loại trừ; nếu cả hai cờ đều true
/// (ngoài hợp đồng) thì hiện Sơ đồ. Trận đã kết thúc thì ẩn cả hai.
LiveOverlayKind? liveOverlayToShow({
  required bool h2hVisible,
  required bool bracketVisible,
  required bool matchEnded,
}) {
  if (matchEnded) return null;
  if (bracketVisible) return LiveOverlayKind.bracket;
  if (h2hVisible) return LiveOverlayKind.h2h;
  return null;
}

/// Hai chip H2H và Sơ đồ trên thanh điều khiển video của trọng tài.
///
/// Trạng thái hiển thị luôn lấy từ cờ server; widget không tự đổi trạng thái.
class LiveOverlayToggleChips extends StatelessWidget {
  const LiveOverlayToggleChips({
    super.key,
    required this.h2hVisible,
    required this.bracketVisible,
    required this.bracketAvailable,
    required this.matchEnded,
    required this.pendingKind,
    required this.onToggle,
  });

  final bool h2hVisible;
  final bool bracketVisible;

  /// false khi trận không có tournamentId: chip Sơ đồ bị khóa.
  final bool bracketAvailable;
  final bool matchEnded;

  /// Overlay đang chờ server. Khác null thì khóa cả hai chip; chip này hiện spinner.
  final LiveOverlayKind? pendingKind;

  /// Gọi với giá trị visible đảo ngược so với cờ server hiện tại.
  final void Function(LiveOverlayKind kind, bool visible) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locked = pendingKind != null || matchEnded;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OverlayChip(
          key: const ValueKey('live-overlay-chip-h2h'),
          label: l10n.liveOverlayChipH2h,
          active: h2hVisible,
          busy: pendingKind == LiveOverlayKind.h2h,
          enabled: !locked,
          onTap: () => onToggle(LiveOverlayKind.h2h, !h2hVisible),
        ),
        const SizedBox(width: 6),
        _OverlayChip(
          key: const ValueKey('live-overlay-chip-bracket'),
          label: l10n.liveOverlayChipBracket,
          active: bracketVisible,
          busy: pendingKind == LiveOverlayKind.bracket,
          enabled: !locked && bracketAvailable,
          onTap: () => onToggle(LiveOverlayKind.bracket, !bracketVisible),
        ),
        if (matchEnded) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.liveOverlayMatchEnded,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    super.key,
    required this.label,
    required this.active,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = !enabled
        ? colors.textMuted
        : active
        ? Colors.white
        : colors.textPrimary;

    return Semantics(
      button: true,
      toggled: active,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              color: active ? AppTheme.primary : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? AppTheme.primary : colors.border,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                          ),
                        )
                      : Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút đóng cục bộ của overlay: chạm được (≥ 44 px) và có nhãn qua tooltip.
class LiveOverlayCloseButton extends StatelessWidget {
  const LiveOverlayCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.close,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      style: IconButton.styleFrom(
        backgroundColor: context.colors.bgCard,
        foregroundColor: context.colors.textPrimary,
      ),
      icon: const Icon(Icons.close, size: 18),
    );
  }
}
