import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Chiều cao thanh điều khiển video (6 + 44 + 6): overlay nằm trên nó khi thanh
/// đang hiện.
const double liveOverlayBottomInset = 64;

/// Gap between an overlay and the picture's bottom edge while the control bar
/// is hidden.
const double liveOverlayRestingInset = 8;

/// Overlays are drawn for a 400dp-wide video at 70% of their old size; a
/// narrower video shrinks them further (floor 0.55 of that), a wider one never
/// grows them past the old 0.7.
double liveOverlayScale(double videoWidth) {
  final width = videoWidth.isFinite ? videoWidth : 400;
  return (width / 400).clamp(0.55, 1.0) * 0.7;
}

/// Frosted-glass blur behind a translucent overlay panel. Wrap it in the
/// panel's own ClipRRect so the blur stops at the rounded edge. The picture is
/// a platform view on some devices; there the blur is a no-op and the
/// translucent fill alone keeps the panel readable.
Widget liveGlassBackdrop({required Widget child}) {
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: child,
  );
}

const Curve liveOverlayMotionCurve = Curves.easeOutCubic;

/// 240 ms; tắt hẳn khi hệ thống bật giảm chuyển động.
Duration liveOverlayMotionDuration(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 240);
}

/// Leaving is quicker than entering (160 ms); zero with reduced motion.
Duration liveOverlayReverseDuration(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 160);
}

/// Enter/leave transition shared by the on-video overlays: fade plus an
/// optional slide ([slideFrom], a fraction of the child's size) and/or a
/// small scale ([scaleFrom]). Use as `AnimatedSwitcher.transitionBuilder`.
Widget liveOverlayTransition(
  Widget child,
  Animation<double> animation, {
  Offset slideFrom = Offset.zero,
  double scaleFrom = 1,
}) {
  final eased = animation.drive(CurveTween(curve: liveOverlayMotionCurve));
  Widget result = FadeTransition(opacity: animation, child: child);
  if (slideFrom != Offset.zero) {
    result = SlideTransition(
      position: eased.drive(Tween(begin: slideFrom, end: Offset.zero)),
      child: result,
    );
  }
  if (scaleFrom != 1) {
    result = ScaleTransition(
      scale: eased.drive(Tween(begin: scaleFrom, end: 1.0)),
      child: result,
    );
  }
  return result;
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

/// Outer margin [LiveOverlayCloseFrame] keeps above and beside its panel so
/// the close button's touch area stays inside the hit-testable bounds.
const double liveOverlayCloseGutter = 16;

/// Room a panel header leaves on its right so the button never covers it.
const double liveOverlayCloseReserve = 24;

/// Nút đóng cục bộ của overlay: chấm tròn 24 px nhìn thấy, vùng chạm 44 px,
/// có nhãn qua tooltip.
class LiveOverlayCloseButton extends StatelessWidget {
  const LiveOverlayCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.close,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: DecoratedBox(
        key: const ValueKey('live-overlay-close-dot'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0B1B3A),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: Icon(Icons.close, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

/// Puts [child] (a panel) under a [LiveOverlayCloseButton] hanging off its
/// top-right corner. Without [onClose] the child is returned untouched.
class LiveOverlayCloseFrame extends StatelessWidget {
  const LiveOverlayCloseFrame({super.key, required this.child, this.onClose});

  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final onClose = this.onClose;
    if (onClose == null) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            liveOverlayCloseGutter,
            liveOverlayCloseGutter,
            liveOverlayCloseGutter,
            0,
          ),
          child: child,
        ),
        Positioned(
          top: 0,
          right: 0,
          child: LiveOverlayCloseButton(onPressed: onClose),
        ),
      ],
    );
  }
}
