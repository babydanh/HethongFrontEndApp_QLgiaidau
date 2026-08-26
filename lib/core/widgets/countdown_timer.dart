import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Widget đếm ngược tới ngày mở đăng ký.
///
/// [targetDate] Ngày mục tiêu (registrationStartDate)
/// [compact] Nếu true chỉ hiện "Còn X ngày" (dùng cho danh sách),
///          false hiện "Còn X ngày HH:MM:SS" (dùng cho chi tiết).
class CountdownTimer extends StatefulWidget {
  final DateTime targetDate;
  final bool compact;

  const CountdownTimer({
    super.key,
    required this.targetDate,
    this.compact = true,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      widget.compact
          ? const Duration(seconds: 60)
          : const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatText(AppLocalizations l10n) {
    final diff = widget.targetDate.difference(DateTime.now());
    if (diff.isNegative) {
      return l10n.coreRegistrationOpening;
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    final secs = diff.inSeconds % 60;

    if (widget.compact) {
      return l10n.coreCountdownDays(days);
    } else {
      final clock =
          '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      if (days > 0) {
        return l10n.coreCountdownTime(days, clock);
      } else {
        return l10n.coreCountdownClock(clock);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final text = _formatText(l10n);
    if (text.isEmpty) return const SizedBox.shrink();

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
}
