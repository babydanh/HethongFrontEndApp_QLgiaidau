import 'package:app_quanly_giaidau/data/repositories/api/api_user_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

(ApiUserRepository, FakeApiAdapter) _setup(Map<String, FakeReply> routes) {
  final adapter = FakeApiAdapter(routes);
  return (ApiUserRepository(fakeDioClient(adapter)), adapter);
}

/// The message of the Exception the repository throws for a failed call.
String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '');

Future<String> _failureOf(Future<Object?> call) async {
  try {
    await call;
  } on Exception catch (e) {
    return _message(e);
  }
  fail('expected an Exception');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('profile reads and writes', () {
    test('getProfile merges the nested profile object over the account',
        () async {
      final (repo, _) = _setup({
        'GET /users/profile': const FakeReply(200, {
          'data': {
            'id': 'u1',
            'email': 'a@b.vn',
            'isEmailVerified': true,
            'roles': ['ORGANIZER'],
            'profile': {'fullName': 'Nguyễn An', 'bio': 'hi', 'id': 'ignored'},
          },
        }),
      });

      final profile = await repo.getProfile();

      expect(profile.id, 'u1'); // top-level wins over the nested copy
      expect(profile.fullName, 'Nguyễn An');
      expect(profile.bio, 'hi');
      expect(profile.isEmailVerified, isTrue);
      expect(profile.roles, ['ORGANIZER']);
    });

    test('getProfile accepts an unwrapped body', () async {
      final (repo, _) = _setup({
        'GET /users/profile': const FakeReply(200, {'id': 'u2'}),
      });

      expect((await repo.getProfile()).id, 'u2');
    });

    test('getProfile rejects a non-object body with the localized message',
        () async {
      final (repo, _) = _setup({
        'GET /users/profile': const FakeReply(200, <dynamic>[]),
      });

      expect(await _failureOf(repo.getProfile()), isNotEmpty);
    });

    test('updateProfile PATCHes the data and returns the new profile',
        () async {
      final (repo, adapter) = _setup({
        'PATCH /users/profile': const FakeReply(200, {
          'data': {'id': 'u1', 'fullName': 'Tên mới'},
        }),
      });

      final profile = await repo.updateProfile({'fullName': 'Tên mới'});

      expect(profile.fullName, 'Tên mới');
      expect(adapter.requests.single.body, {'fullName': 'Tên mới'});
    });

    test('uploading an avatar or a cover returns the refreshed profile',
        () async {
      final (repo, adapter) = _setup({
        'POST /users/profile/avatar': const FakeReply(201, {
          'data': {'id': 'u1', 'avatarUrl': 'https://cdn/a.png'},
        }),
        'POST /users/profile/cover': const FakeReply(200, {
          'id': 'u1',
          'coverUrl': 'https://cdn/c.png',
        }),
      });

      final avatar = await repo.uploadAvatar([1, 2], 'a.png');
      final cover = await repo.uploadCover([3], 'c.png');

      expect(avatar.avatarUrl, 'https://cdn/a.png');
      expect(cover.coverUrl, 'https://cdn/c.png');
      expect(adapter.requests.map((r) => r.path), [
        '/users/profile/avatar',
        '/users/profile/cover',
      ]);
    });

    test('getPublicProfile reads the public route and merges pair ranks',
        () async {
      final (repo, _) = _setup({
        'GET /users/u9/public': const FakeReply(200, {
          'data': {
            'id': 'u9',
            'fullName': 'Công khai',
            'systemRole': 'PLAYER',
            'isVerified': true,
          },
        }),
      });

      final profile = await repo.getPublicProfile('u9');

      expect(profile.fullName, 'Công khai');
      expect(profile.role, 'PLAYER');
      expect(profile.isVerified, isTrue);
    });
  });

  group('error translation', () {
    test('known Nest messages are shown in Vietnamese', () async {
      final (repo, _) = _setup({
        'PATCH /users/profile': const FakeReply(400, {
          'message': ['email must be an email', 'other'],
        }),
        'PATCH /users/change-password': const FakeReply(400, {
          'message': 'Invalid credentials',
        }),
      });

      expect(
        await _failureOf(repo.updateProfile({})),
        'Địa chỉ email không hợp lệ.',
      );
      expect(
        await _failureOf(repo.changePassword('a', 'b')),
        'Email hoặc mật khẩu không đúng.',
      );
    });

    test('an unknown message is passed through unchanged', () async {
      final (repo, _) = _setup({
        'GET /users/profile': const FakeReply(403, {
          'message': 'Tài khoản bị khoá',
        }),
      });

      expect(await _failureOf(repo.getProfile()), 'Tài khoản bị khoá');
    });

    test('a string body is shown as is, a body with no message falls back to '
        'the transport message', () async {
      final (stringBody, _) = _setup({
        'GET /users/u1/public': const FakeReply(500, 'Máy chủ bận'),
      });
      final (noMessage, _) = _setup({
        'GET /users/u1/public': const FakeReply(500, {'statusCode': 500}),
      });

      expect(await _failureOf(stringBody.getPublicProfile('u1')), 'Máy chủ bận');
      expect(
        await _failureOf(noMessage.getPublicProfile('u1')),
        contains('500'),
      );
    });

    test('every wrapped call throws instead of returning a stale value',
        () async {
      final (repo, _) = _setup({});

      for (final call in <Future<Object?> Function()>[
        repo.getProfile,
        () => repo.updateProfile({}),
        () => repo.uploadAvatar([1], 'a.png'),
        () => repo.uploadCover([1], 'c.png'),
        () => repo.getPublicProfile('u'),
        () => repo.changePassword('a', 'b'),
        () => repo.deleteAccount('pw'),
        () => repo.createChangeRequest(requestType: 'EMAIL', newValue: 'x'),
      ]) {
        await expectLater(call(), throwsA(isA<Exception>()));
      }
    });
  });

  group('account actions', () {
    test('changePassword sends both passwords', () async {
      final (repo, adapter) = _setup({
        'PATCH /users/change-password': const FakeReply(200, {}),
      });

      await repo.changePassword('cũ', 'mới');

      expect(adapter.requests.single.body, {
        'oldPassword': 'cũ',
        'newPassword': 'mới',
      });
    });

    test('deleteAccount sends the password for confirmation', () async {
      final (repo, adapter) = _setup({
        'POST /users/delete-account': const FakeReply(201, {}),
      });

      await repo.deleteAccount('mật-khẩu');

      expect(adapter.requests.single.body, {'password': 'mật-khẩu'});
    });

    test('createChangeRequest sends the type and the new value', () async {
      final (repo, adapter) = _setup({
        'POST /users/change-requests': const FakeReply(201, {}),
      });

      await repo.createChangeRequest(requestType: 'PHONE', newValue: '0900');

      expect(adapter.requests.single.body, {
        'requestType': 'PHONE',
        'newValue': '0900',
      });
    });
  });

  group('searchUsers', () {
    test('parses the data list, keeps only objects and aliases', () async {
      final (repo, adapter) = _setup({
        'GET /users/search': const FakeReply(200, {
          'data': [
            {'id': 'u1', 'fullName': 'An'},
            {'userId': 'u2', 'name': 'Bình', 'avatarUrl': 'a.png'},
            'junk',
          ],
        }),
      });

      final results = await repo.searchUsers('an');

      expect(results.map((r) => (r.id, r.fullName)), [('u1', 'An'), ('u2', 'Bình')]);
      expect(results.last.avatarUrl, 'a.png');
      expect(adapter.requests.single.query, {'q': 'an'});
    });

    test('accepts a bare list and degrades to [] on failure', () async {
      final (bare, _) = _setup({
        'GET /users/search': const FakeReply(200, [
          {'id': 'u1', 'fullName': 'An'},
        ]),
      });
      final (failing, _) = _setup({});

      expect(await bare.searchUsers('x'), hasLength(1));
      expect(await failing.searchUsers('x'), isEmpty);
    });
  });
}
