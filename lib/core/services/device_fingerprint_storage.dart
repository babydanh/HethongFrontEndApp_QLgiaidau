import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceFingerprintStorage {
  DeviceFingerprintStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _secureKey = 'livestream_device_fingerprint';
  static const _legacyPreferencesKey = 'livestream_device_fingerprint';

  final FlutterSecureStorage _secureStorage;

  Future<String> getOrCreate() async {
    final existing = await _secureStorage.read(key: _secureKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final legacyPreferences = await SharedPreferences.getInstance();
    final legacy = legacyPreferences.getString(_legacyPreferencesKey);
    final fingerprint = legacy != null && legacy.isNotEmpty
        ? legacy
        : '${Platform.operatingSystem}-${const Uuid().v4()}';

    await _secureStorage.write(key: _secureKey, value: fingerprint);
    if (legacy != null) {
      await legacyPreferences.remove(_legacyPreferencesKey);
    }
    return fingerprint;
  }
}
