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

  static String getMatchRoute(UserRole? role, String tournamentId, String matchId) {
    return '/live/$matchId';
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
