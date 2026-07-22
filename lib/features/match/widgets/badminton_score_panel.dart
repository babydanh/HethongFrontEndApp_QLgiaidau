import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/rally_score_panel.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';

/// Panel Cầu lông: dùng chung core RallyScorePanel, thêm hướng dẫn riêng theo môn.
class BadmintonScorePanel extends StatelessWidget {
  final MatchControlParams params;
  final bool isReadOnly;

  const BadmintonScorePanel({
    super.key,
    required this.params,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.sports_tennis_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cầu lông dùng rally point: mỗi pha bóng được 1 điểm, thường chạm 21 và thắng cách 2 theo cấu hình giải.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        RallyScorePanel(params: params, isReadOnly: isReadOnly),
      ],
    );
  }
}
