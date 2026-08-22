import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

extension RoleExtension on String {
  /// Full display name with emoji.
  String toRoleDisplayName(AppLocalizations l10n) {
    return switch (this) {
      'admin' => l10n.roleAdminDisplay,
      'referee' => l10n.roleRefereeDisplay,
      'viewer' => l10n.roleViewerDisplay,
      _ => this,
    };
  }

  /// Short name without emoji.
  String toRoleShortName(AppLocalizations l10n) {
    return switch (this) {
      'admin' => l10n.roleAdminShort,
      'referee' => l10n.roleRefereeShort,
      'viewer' => l10n.roleViewerShort,
      _ => this,
    };
  }
}
