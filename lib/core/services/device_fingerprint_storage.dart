import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceFingerprintStorage {
  DeviceFingerprintStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _secureKey = 'livestream_device_fingerprint';
  static const _legacyPreferencesKey = 'livestream_device_fingerprint';
  static const _log = AppLogger('DeviceFingerprintStorage');

  final FlutterSecureStorage _secureStorage;

  Future<String> getOrCreate() async {
    final preferences = await SharedPreferences.getInstance();
    String? secureFingerprint;

    if (!kIsWeb) {
      try {
        secureFingerprint = await _secureStorage.read(key: _secureKey);
      } catch (error, stackTrace) {
        _log.warning(
          'Failed to read secure livestream device fingerprint: $error',
        );
        _log.error('Secure fingerprint read failure', error, stackTrace);

        final legacy = preferences.getString(_legacyPreferencesKey);
        if (legacy != null && legacy.isNotEmpty) {
          return legacy;
        }
        rethrow;
      }
    }

    if (secureFingerprint != null && secureFingerprint.isNotEmpty) {
      return secureFingerprint;
    }

    final legacy = preferences.getString(_legacyPreferencesKey);
    final fingerprint = legacy != null && legacy.isNotEmpty
        ? legacy
        : '${defaultTargetPlatform.name}-${const Uuid().v4()}';

    await _writeSecureFingerprint(fingerprint, preferences);
    return fingerprint;
  }

  Future<void> _writeSecureFingerprint(
    String fingerprint,
    SharedPreferences preferences,
  ) async {
    if (kIsWeb) {
      await preferences.setString(_legacyPreferencesKey, fingerprint);
      return;
    }

    try {
      await _secureStorage.write(key: _secureKey, value: fingerprint);
      await preferences.remove(_legacyPreferencesKey);
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to persist secure livestream device fingerprint; using local fallback: $error',
      );
      _log.error('Secure fingerprint write failure', error, stackTrace);
      await preferences.setString(_legacyPreferencesKey, fingerprint);
    }
  }
}

final deviceFingerprintStorage = DeviceFingerprintStorage();
