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

  group('AuthNotifier.mapSessionRole (F1: ORGANIZER không rơi về viewer)', () {
    UserRole mapRoles(List<String> roles) => AuthNotifier.mapSessionRole(
      AuthSession(accessToken: 'a', refreshToken: 'r', roles: roles),
    );

    test('ORGANIZER trả về organizer', () {
      expect(mapRoles(['ORGANIZER']), UserRole.organizer);
    });

    test('tên role viết thường vẫn nhận diện', () {
      expect(mapRoles(['organizer']), UserRole.organizer);
    });

    test('ADMIN và REFEREE giữ nguyên', () {
      expect(mapRoles(['ADMIN']), UserRole.admin);
      expect(mapRoles(['REFEREE']), UserRole.referee);
    });

    test('PLAYER, MODERATOR và danh sách rỗng là viewer', () {
      expect(mapRoles(['PLAYER']), UserRole.viewer);
      expect(mapRoles(['MODERATOR']), UserRole.viewer);
      expect(mapRoles([]), UserRole.viewer);
    });

    test('nhiều role lấy quyền cao nhất: ADMIN > REFEREE > ORGANIZER', () {
      expect(mapRoles(['PLAYER', 'ORGANIZER']), UserRole.organizer);
      expect(mapRoles(['ORGANIZER', 'REFEREE']), UserRole.referee);
      expect(mapRoles(['ORGANIZER', 'ADMIN']), UserRole.admin);
    });

    test('BTC có isOrganizer và canScore', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        role: mapRoles(['ORGANIZER']),
      );
      expect(state.isOrganizer, isTrue);
      expect(state.canScore, isTrue);
    });
  });
}
