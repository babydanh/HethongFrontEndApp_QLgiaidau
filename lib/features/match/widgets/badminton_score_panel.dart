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
    return RallyScorePanel(params: params, isReadOnly: isReadOnly);
  }
}
