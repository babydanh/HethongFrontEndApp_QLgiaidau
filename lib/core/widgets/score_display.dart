import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

/// Hiển thị set history dạng badge
class SetHistoryDisplay extends StatelessWidget {
  final List<SetScoreData> sets;
  final bool isTeam1;

  const SetHistoryDisplay({
    super.key,
    required this.sets,
    required this.isTeam1,
  });

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: sets.map((s) {
        final won = isTeam1 ? s.score1 > s.score2 : s.score2 > s.score1;
        final myScore = isTeam1 ? s.score1 : s.score2;
        return Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: won
                ? AppTheme.accent.withValues(alpha: 0.15)
                : context.colors.bgSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: won ? AppTheme.accent : context.colors.border,
            ),
          ),
          child: Center(
            child: Text(
              '$myScore',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: won ? AppTheme.accent : context.colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Điểm tennis text (Love, Fifteen, etc.)
String tennisPointLabel(int points) {
  switch (points) {
    case 0: return '0';
    case 1: return '15';
    case 2: return '30';
    case 3: return '40';
    default: return '40';
  }
}

/// Hiển thị tennis game point (40-40, Ad, etc.)
class TennisGamePoint extends StatelessWidget {
  final int team1Points;
  final int team2Points;

  const TennisGamePoint({
    super.key,
    required this.team1Points,
    required this.team2Points,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (team1Points >= 3 && team2Points >= 3) {
      if (team1Points == team2Points) {
        return _point('Deuce', AppTheme.accent);
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (team1Points > team2Points) ...[
            _point('Ad', const Color(0xFF2979FF)),
            const SizedBox(width: 4),
            Text('T1', style: TextStyle(fontSize: 10, color: colors.textMuted)),
          ] else ...[
            _point('Ad', const Color(0xFFEA580C)),
            const SizedBox(width: 4),
            Text('T2', style: TextStyle(fontSize: 10, color: colors.textMuted)),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _point(tennisPointLabel(team1Points), const Color(0xFF2979FF)),
        const SizedBox(width: 6),
        Text('-', style: TextStyle(color: colors.textMuted, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        _point(tennisPointLabel(team2Points), const Color(0xFFEA580C)),
      ],
    );
  }

  Widget _point(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

/// Pickleball server indicator
class PickleballServerIndicator extends StatelessWidget {
  final bool isTeam1Serving;
  final int serveNumber; // 1 or 2

  const PickleballServerIndicator({
    super.key,
    required this.isTeam1Serving,
    this.serveNumber = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volunteer_activism_rounded, size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            'Giao bóng: ${isTeam1Serving ? "Đội 1" : "Đội 2"} · Giao $serveNumber',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
