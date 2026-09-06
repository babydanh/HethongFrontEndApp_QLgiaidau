import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class NavigationHelper {
  static String getTournamentRoute(UserRole? role, String tournamentId) {
    return switch (role) {
      UserRole.admin => '/admin/tournament/$tournamentId',
      UserRole.referee => '/intro/$tournamentId',
      UserRole.viewer => '/intro/$tournamentId',
      _ => '/home',
    };
  }

  static String getMatchRoute(
    UserRole? role,
    String tournamentId,
    String matchId,
  ) {
    return getLiveMatchRoute(tournamentId, matchId);
  }

  /// Keep the tournament context in every match deep link. The live screen
  /// needs it to select the correct provider immediately, especially for Lite
  /// and club tournaments where an empty context triggers a second lookup.
  static String getLiveMatchRoute(String tournamentId, String matchId) {
    final cleanTournamentId = tournamentId.trim();
    return Uri(
      path: '/live/${matchId.trim()}',
      queryParameters: cleanTournamentId.isEmpty
          ? null
          : {'tournamentId': cleanTournamentId},
    ).toString();
  }

  static String getInitialRoute(UserRole? role) {
    return switch (role) {
      UserRole.admin => '/admin',
      UserRole.referee => '/referee',
      UserRole.viewer => '/viewer',
      _ => '/home',
    };
  }
}
