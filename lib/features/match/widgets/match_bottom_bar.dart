import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';

/// Bottom bar: penalty, override, kết thúc set/trận.
class MatchBottomBar extends ConsumerWidget {
  final MatchControlParams params;
  const MatchBottomBar({required this.params, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(scorePanelNotifierProvider(params));
    final state = notifier.state;
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error message
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          // Override toggle
          if (state.overrideEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                maxLines: 2,
                maxLength: 200,
                style: TextStyle(color: colors.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Lý do override (ghi rõ lý do ngoại lệ)',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 11),
                  filled: true,
                  fillColor: colors.bgSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(8),
                ),
                onChanged: (v) => notifier.setOverride(true, v),
              ),
            ),
          // Action buttons row
          Row(
            children: [
              // Kết thúc trận — Đội 1
              Expanded(
                child: _actionButton(
                  label: 'Đội 1 thắng',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFF2979FF),
                  loading: state.isSubmitting,
                  onTap: state.isMatchComplete && state.winnerTeam == 1
                      ? () => notifier.completeMatch(1)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              // Kết thúc trận — Đội 2
              Expanded(
                child: _actionButton(
                  label: 'Đội 2 thắng',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFEA580C),
                  loading: state.isSubmitting,
                  onTap: state.isMatchComplete && state.winnerTeam == 2
                      ? () => notifier.completeMatch(2)
                      : null,
                ),
              ),
            ],
          ),
          if (!state.isMatchComplete && !state.overrideEnabled) ...[
            const SizedBox(height: 6),
            // Override toggle button
            TextButton.icon(
              onPressed: () => notifier.setOverride(true, ''),
              icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
              label: Text(
                'Override (chốt tỉ số ngoại lệ)',
                style: TextStyle(fontSize: 11, color: Colors.orange[700]),
              ),
            ),
          ],
          if (state.overrideEnabled)
            TextButton.icon(
              onPressed: () => notifier.setOverride(false, ''),
              icon: const Icon(Icons.close_rounded, size: 14),
              label: const Text('Huỷ override', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
