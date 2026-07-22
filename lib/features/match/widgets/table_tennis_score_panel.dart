import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/rally_score_panel.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';

/// Panel Bóng bàn: dùng chung core RallyScorePanel, thêm hướng dẫn riêng theo môn.
class TableTennisScorePanel extends StatelessWidget {
  final MatchControlParams params;
  final bool isReadOnly;

  const TableTennisScorePanel({
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
            color: colors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.warning.withValues(alpha: 0.22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sports_score_rounded, size: 18, color: colors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bóng bàn dùng rally point: thường chạm 11, thắng cách 2; lưu ý đổi giao bóng theo luật giải nếu cần.',
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
