import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class AppActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isSelected;
  final Axis layout;

  const AppActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
    this.isSelected = false,
    this.layout = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (layout == Axis.vertical) {
      return _buildVertical(context);
    }
    return _buildHorizontal(context);
  }

  Widget _buildVertical(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : context.colors.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: isSelected ? color : context.colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}
