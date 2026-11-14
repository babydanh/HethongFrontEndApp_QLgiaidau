import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

String rosterStatusLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'FOUND':
      return l10n.rosterImportStatusFound;
    case 'NOT_FOUND':
      return l10n.rosterImportStatusNotFound;
    case 'INVALID_EMAIL':
      return l10n.rosterImportStatusInvalidEmail;
    case 'MISSING_EMAIL':
      return l10n.rosterImportStatusMissingEmail;
    case 'MISSING_NAME':
      return l10n.rosterImportStatusMissingName;
    case 'DUPLICATE_IN_FILE':
      return l10n.rosterImportStatusDuplicateInFile;
    case 'DUPLICATE_IN_TOURNAMENT':
      return l10n.rosterImportStatusDuplicateInTournament;
    case 'PLAYER2_REQUIRED':
      return l10n.rosterImportStatusPlayer2Required;
    case 'PLAYER2_NOT_ALLOWED':
      return l10n.rosterImportStatusPlayer2NotAllowed;
    case 'DIVISION_UNKNOWN':
      return l10n.rosterImportStatusDivisionUnknown;
    default:
      return l10n.rosterImportStatusUnknown;
  }
}

Widget rosterToneChip(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

Widget rosterNoticeText(String text, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}
