import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class StatusHelper {
  /// Mã trạng thái nội bộ. Giá trị lạ trùng đúng một mã này không được trả nguyên văn,
  /// nếu không sẽ bị đọc nhầm thành trạng thái đó (ví dụ "REGISTRATION" thành đang mở đăng ký).
  static const _internalStatusCodes = {
    AppConstants.statusDraft,
    AppConstants.statusUpcoming,
    AppConstants.statusRegistration,
    AppConstants.statusRegistrationClosed,
    AppConstants.statusDrawing,
    AppConstants.statusInProgress,
    AppConstants.statusCompleted,
    AppConstants.statusCancelled,
  };

  static String _unknownStatus(String lower) =>
      _internalStatusCodes.contains(lower) ? 'raw_$lower' : lower;

  static String normalizeTournamentStatus(String? rawStatus) {
    final trimmed = (rawStatus ?? '').trim();
    // Entity lưu mã nội bộ đã chuẩn hoá (Tournament.fromJson), nên khi đọc lại
    // phải trả nguyên. Mã thô của backend luôn viết HOA, nên so khớp chữ thường
    // chính xác không biến "REGISTRATION" thành đang mở đăng ký.
    if (_internalStatusCodes.contains(trimmed)) return trimmed;
    final status = trimmed.toUpperCase();
    return switch (status) {
      'DRAFT' => AppConstants.statusDraft,
      'UPCOMING' => AppConstants.statusUpcoming,
      'REGISTRATION_OPEN' => AppConstants.statusRegistration,
      'REGISTRATION_CLOSED' ||
      'REGISTER_CLOSED' ||
      'CLOSED' => AppConstants.statusRegistrationClosed,
      'DRAWING' => AppConstants.statusDrawing,
      'ONGOING' ||
      'IN_PROGRESS' ||
      'LIVE' => AppConstants.statusInProgress,
      'COMPLETED' ||
      'FINISHED' => AppConstants.statusCompleted,
      'CANCELLED' => AppConstants.statusCancelled,
      _ => status.isEmpty ? AppConstants.statusUpcoming : _unknownStatus(status.toLowerCase()),
    };
  }

  static String getTournamentStatusLabel(
    String status, {
    AppLocalizations? l10n,
  }) {
    final normalized = normalizeTournamentStatus(status);
    final labels = l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    return switch (normalized) {
      AppConstants.statusDraft => labels.statusLabelDraft,
      AppConstants.statusUpcoming => labels.statusLabelUpcoming,
      AppConstants.statusRegistration => labels.statusLabelRegistration,
      AppConstants.statusRegistrationClosed => labels.statusLabelRegistrationClosed,
      AppConstants.statusDrawing => labels.statusLabelDrawing,
      AppConstants.statusInProgress => labels.statusLabelInProgress,
      AppConstants.statusCompleted => labels.statusLabelCompleted,
      AppConstants.statusCancelled => labels.statusLabelCancelled,
      _ => normalized,
    };
  }

  static bool isTournamentDraft(String status) => normalizeTournamentStatus(status) == AppConstants.statusDraft;
  static bool isTournamentUpcoming(String status) {
    final normalized = normalizeTournamentStatus(status);
    return normalized == AppConstants.statusUpcoming ||
        normalized == AppConstants.statusRegistrationClosed;
  }
  static bool isTournamentRegistration(String status) => normalizeTournamentStatus(status) == AppConstants.statusRegistration;
  static bool isTournamentRegistrationClosed(String status) => normalizeTournamentStatus(status) == AppConstants.statusRegistrationClosed;
  static bool isTournamentInProgress(String status) => normalizeTournamentStatus(status) == AppConstants.statusInProgress;
  static bool isTournamentCompleted(String status) => normalizeTournamentStatus(status) == AppConstants.statusCompleted;
  static bool isTournamentCancelled(String status) => normalizeTournamentStatus(status) == AppConstants.statusCancelled;

  static Color getTournamentStatusColor(String status, BuildContext context) {
    final normalized = normalizeTournamentStatus(status);
    return switch (normalized) {
      AppConstants.statusRegistration => AppTheme.primary,
      AppConstants.statusRegistrationClosed => const Color(0xFFEF4444),
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
  static String getStatusDisplayName(
    String status, {
    AppLocalizations? l10n,
  }) {
    final labels = l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    return switch (status) {
      AppConstants.matchScheduled => labels.statusLabelScheduled,
      AppConstants.matchLive => labels.statusLabelLive,
      AppConstants.matchCompleted => labels.statusLabelCompleted,
      AppConstants.matchWalkover => labels.statusLabelWalkover,
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
