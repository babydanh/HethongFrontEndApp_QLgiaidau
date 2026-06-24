import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_quanly_giaidau/core/services/api_response.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';

// A Fake implementation of FlutterSecureStorage for testing
class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #write) {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String?;
      if (value != null) {
        _storage[key] = value;
      } else {
        _storage.remove(key);
      }
      return Future<void>.value();
    }
    if (invocation.memberName == #read) {
      final key = invocation.namedArguments[#key] as String;
      return Future<String?>.value(_storage[key]);
    }
    if (invocation.memberName == #delete) {
      final key = invocation.namedArguments[#key] as String;
      _storage.remove(key);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('ApiResponse Tests', () {
    test('should parse JSON response successfully', () {
      final json = {
        'statusCode': 200,
        'message': 'Success',
        'data': {'id': '123', 'name': 'Test Team'},
        'meta': {'total': 1}
      };

      final response = ApiResponse.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
      );

      expect(response.statusCode, 200);
      expect(response.message, 'Success');
      expect(response.data?['id'], '123');
      expect(response.meta?['total'], 1);
    });
  });

  group('TokenManager Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late TokenManager tokenManager;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      tokenManager = TokenManager(secureStorage: fakeStorage);
    });

    test('should save and retrieve tokens successfully', () async {
      await tokenManager.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
      );

      expect(await tokenManager.getAccessToken(), 'access_123');
      expect(await tokenManager.getRefreshToken(), 'refresh_456');
      expect(await tokenManager.hasValidToken(), true);
    });

    test('should clear tokens successfully', () async {
      await tokenManager.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
      );

      await tokenManager.clearTokens();

      expect(await tokenManager.getAccessToken(), isNull);
      expect(await tokenManager.getRefreshToken(), isNull);
      expect(await tokenManager.hasValidToken(), false);
    });
  });
}
