import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class ScoreStepper extends StatelessWidget {
  final int currentScore;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ScoreStepper({
    super.key,
    required this.currentScore,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScoreStepperButton(
          icon: Icons.remove,
          onTap: currentScore > 0 ? onDecrement : null,
          color: context.colors.error,
        ),
        const SizedBox(width: 8),
        ScoreStepperButton(
          icon: Icons.add,
          onTap: onIncrement,
          color: context.colors.success,
        ),
      ],
    );
  }
}

class ScoreStepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const ScoreStepperButton({
    super.key,
    required this.icon,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.15)
              : context.colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null
                ? color.withValues(alpha: 0.5)
                : context.colors.border,
          ),
        ),
        child: Icon(
          icon,
          color: onTap != null ? color : context.colors.textMuted,
          size: 22,
        ),
      ),
    );
  }
}
