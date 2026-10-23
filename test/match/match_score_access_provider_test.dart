import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/match_score_access_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

const _path = 'GET /matches/m1/score-access';

const _signedIn = AuthState(
  status: AuthStatus.authenticated,
  role: UserRole.organizer,
);

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

Future<bool?> _read(
  Map<String, FakeReply> routes, {
  String id = 'm1',
  AuthState auth = _signedIn,
}) {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(() => _FixedAuthNotifier(auth)),
      dioClientProvider.overrideWithValue(
        fakeDioClient(FakeApiAdapter(routes)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container.read(matchScoreAccessProvider(id).future);
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  group('matchScoreAccessProvider', () {
    test('reads canScore from the wrapped data payload', () async {
      expect(
        await _read({
          _path: const FakeReply(200, {
            'data': {'canScore': true},
          }),
        }),
        isTrue,
      );
    });

    test('reads canScore from an unwrapped payload', () async {
      expect(
        await _read({_path: const FakeReply(200, {'canScore': false})}),
        isFalse,
      );
    });

    test('returns null on a server error', () async {
      expect(await _read({_path: const FakeReply(403, {'message': 'no'})}), isNull);
    });

    test('returns null when canScore is missing or not a bool', () async {
      expect(await _read({_path: const FakeReply(200, {'data': {}})}), isNull);
      expect(
        await _read({
          _path: const FakeReply(200, {
            'data': {'canScore': 'yes'},
          }),
        }),
        isNull,
      );
    });

    test('returns null for an empty match id without calling the backend', () async {
      expect(await _read(const {}, id: ''), isNull);
    });

    test('returns null when nobody is signed in, even if the backend would grant', () async {
      expect(
        await _read(
          {
            _path: const FakeReply(200, {
              'data': {'canScore': true},
            }),
          },
          auth: const AuthState(status: AuthStatus.unauthenticated),
        ),
        isNull,
      );
    });
  });
}
