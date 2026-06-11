import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class StatusHelper {
  // Color for UI display
  static Color getStatusColor(String status, BuildContext context) {
    return switch (status) {
      AppConstants.matchLive || AppConstants.statusInProgress => context.colors.error,
      AppConstants.matchCompleted || AppConstants.statusCompleted => context.colors.success,
      AppConstants.matchScheduled || AppConstants.statusDraft || AppConstants.statusRegistration => context.colors.textSecondary,
      AppConstants.matchWalkover || AppConstants.statusDrawing => context.colors.warning,
      _ => context.colors.border,
    };
  }

  // Display name with emoji
  static String getStatusDisplayName(String status) {
    return switch (status) {
      AppConstants.matchScheduled => 'Chưa thi đấu',
      AppConstants.matchLive => 'Đang thi đấu',
      AppConstants.matchCompleted => 'Hoàn thành',
      AppConstants.matchWalkover => 'Walkover',
      _ => status,
    };
  }

  // Check helpers
  static bool isCompleted(String status) =>
      status == AppConstants.matchCompleted;
  static bool isWalkover(String status) => status == AppConstants.matchWalkover;
  static bool isLive(String status) => status == AppConstants.matchLive;
  static bool isScheduled(String status) =>
      status == AppConstants.matchScheduled;
}
