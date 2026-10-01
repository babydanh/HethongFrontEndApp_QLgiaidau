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

  /// Canonical deep link to a user profile page.
  ///
  /// `/user/:id` is the route declared first in the router and the one the
  /// auth redirect prefix-matches, so every profile entry point in the app
  /// builds its link here instead of hand-rolling an equivalent alias.
  /// The club context is preserved whenever the caller already knows it.
  static String getUserProfileRoute(String userId, {String? communityId}) {
    final cleanUserId = userId.trim();
    final cleanCommunityId = communityId?.trim();
    return Uri(
      path: '/user/${Uri.encodeComponent(cleanUserId)}',
      queryParameters: (cleanCommunityId == null || cleanCommunityId.isEmpty)
          ? null
          : {'communityId': cleanCommunityId},
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
