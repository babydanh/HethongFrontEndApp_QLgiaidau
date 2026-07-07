import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class StatusHelper {
  static String normalizeTournamentStatus(String? rawStatus) {
    final status = (rawStatus ?? '').trim().toUpperCase();
    return switch (status) {
      'DRAFT' => AppConstants.statusDraft,
      'UPCOMING' => AppConstants.statusUpcoming,
      'REGISTRATION_OPEN' || 'REGISTRATION_CLOSED' => AppConstants.statusRegistration,
      'ONGOING' || 'IN_PROGRESS' => AppConstants.statusInProgress,
      'COMPLETED' => AppConstants.statusCompleted,
      'FINISHED' => AppConstants.statusCompleted,
      'CANCELLED' => AppConstants.statusCancelled,
      _ => rawStatus?.toLowerCase() ?? AppConstants.statusDraft,
    };
  }

  static String getTournamentStatusLabel(String status) {
    final normalized = normalizeTournamentStatus(status);
    return AppConstants.statusNames[normalized] ?? normalized;
  }

  static bool isTournamentDraft(String status) => normalizeTournamentStatus(status) == AppConstants.statusDraft;
  static bool isTournamentUpcoming(String status) => normalizeTournamentStatus(status) == AppConstants.statusUpcoming;
  static bool isTournamentRegistration(String status) => normalizeTournamentStatus(status) == AppConstants.statusRegistration;
  static bool isTournamentInProgress(String status) => normalizeTournamentStatus(status) == AppConstants.statusInProgress;
  static bool isTournamentCompleted(String status) => normalizeTournamentStatus(status) == AppConstants.statusCompleted;
  static bool isTournamentCancelled(String status) => normalizeTournamentStatus(status) == AppConstants.statusCancelled;

  static Color getTournamentStatusColor(String status, BuildContext context) {
    final normalized = normalizeTournamentStatus(status);
    return switch (normalized) {
      AppConstants.statusRegistration => const Color(0xFF2563EB),
      AppConstants.statusUpcoming => context.colors.info,
      AppConstants.statusDrawing => context.colors.warning,
      AppConstants.statusInProgress => const Color(0xFF22C55E),
      AppConstants.statusCompleted => context.colors.textMuted,
      AppConstants.statusCancelled => context.colors.error,
      _ => context.colors.textSecondary,
    };
  }

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
