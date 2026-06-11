import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

class MatchCardLive extends StatelessWidget {
  final MatchModel match;

  const MatchCardLive({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.colors.error, width: 2),
        boxShadow: [
          BoxShadow(
            color: context.colors.error.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Live banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              gradient: context.liveGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLarge - 2),
                topRight: Radius.circular(AppTheme.radiusLarge - 2),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fiber_manual_record, size: 10, color: Colors.white),
                SizedBox(width: 6),
                Text('LIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    )),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Team 1
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.team1Name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${match.score1}',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textPrimary,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textMuted.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vòng ${match.round}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),

                // Team 2
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.team2Name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${match.score2}',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textPrimary,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
