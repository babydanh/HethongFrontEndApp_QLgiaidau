import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const _guest = AuthState();
const _viewer = AuthState(
  status: AuthStatus.authenticated,
  role: UserRole.viewer,
);

void main() {
  group('BUG-GUEST-01 guest cannot open authenticated-only routes', () {
    for (final path in [
      '/chat',
      '/chat/abc',
      '/club-create',
      '/club/create',
      '/club-invites',
    ]) {
      test('guest opening $path is sent to login or home', () {
        expect(appRedirect(_guest, path), anyOf('/login', '/home'));
      });
    }

    for (final path in ['/club/abc', '/communities/abc', '/tournaments/abc']) {
      test('guest can still view public $path', () {
        expect(appRedirect(_guest, path), isNull);
      });
    }
  });

  group('BUG-REF-01 viewer role and referee invites', () {
    test('viewer keeps /referee/invites', () {
      expect(appRedirect(_viewer, '/referee/invites'), isNull);
    });

    test('viewer is still sent away from the referee scoring screen', () {
      expect(appRedirect(_viewer, '/referee/match/m1'), '/viewer');
    });
  });
}
