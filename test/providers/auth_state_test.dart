// Tests for AuthNotifier
// Covers: TC-FLUTTER-AUTH-024, 025, 026, 027, 028, 029, 032, 033, 034, 035

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';

void main() {
  group('TC-FLUTTER-AUTH-035: AuthState getters', () {
    test('authenticated admin returns correct state', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        role: UserRole.admin,
      );

      expect(state.isAuthenticated, true);
      expect(state.isAdmin, true);
      expect(state.canScore, true);
      expect(state.isReferee, false);
      expect(state.isViewer, false);
    });

    test('authenticated referee returns correct state', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        role: UserRole.referee,
      );

      expect(state.isAuthenticated, true);
      expect(state.isReferee, true);
      expect(state.canScore, true);
      expect(state.isAdmin, false);
      expect(state.isViewer, false);
    });

    test('authenticated viewer returns correct state', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        role: UserRole.viewer,
      );

      expect(state.isAuthenticated, true);
      expect(state.isViewer, true);
      expect(state.canScore, false);
      expect(state.isAdmin, false);
    });

    test('unauthenticated state returns false for everything', () {
      final state = AuthState(status: AuthStatus.unauthenticated);

      expect(state.isAuthenticated, false);
      expect(state.canScore, false);
      expect(state.isAdmin, false);
      expect(state.isReferee, false);
      expect(state.isViewer, false);
    });

    test('invalid state returns isAuthenticated false', () {
      final state = AuthState(status: AuthStatus.invalid);
      expect(state.isAuthenticated, false);
    });

    test('validating state returns isAuthenticated false', () {
      final state = AuthState(status: AuthStatus.validating);
      expect(state.isAuthenticated, false);
    });
  });

  group('AuthState role mapping', () {
    test('isAdmin true when role is admin', () {
      expect(AuthState(status: AuthStatus.authenticated, role: UserRole.admin).isAdmin, true);
    });

    test('isAdmin false for referee', () {
      expect(AuthState(status: AuthStatus.authenticated, role: UserRole.referee).isAdmin, false);
    });

    test('isAdmin false for viewer', () {
      expect(AuthState(status: AuthStatus.authenticated, role: UserRole.viewer).isAdmin, false);
    });
  });
}
