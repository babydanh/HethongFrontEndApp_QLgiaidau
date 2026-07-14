import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class SportPill extends StatelessWidget {
  final String sportKey;

  const SportPill({
    super.key,
    required this.sportKey,
  });

  @override
  Widget build(BuildContext context) {
    final sportName = AppConstants.sportNames[sportKey] ?? sportKey;
    final icon = AppConstants.sportIcons[sportKey] ?? "🏆";
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon.startsWith("assets/"))
            Image.asset(
              icon,
              width: 14,
              height: 14,
              errorBuilder: (context, error, stackTrace) => const Text("🏆", style: TextStyle(fontSize: 12)),
            )
          else
            Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            sportName,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
