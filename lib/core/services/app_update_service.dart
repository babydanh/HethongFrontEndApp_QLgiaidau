import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String minimumVersion;
  final String storeUrl;
  final String releaseNotes;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.minimumVersion,
    required this.storeUrl,
    required this.releaseNotes,
  });

  bool get hasUpdate => _compare(latestVersion, currentVersion) > 0;
  bool get isRequired => _compare(minimumVersion, currentVersion) > 0;

  static int _compare(String left, String right) {
    final a = _parts(left);
    final b = _parts(right);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i].compareTo(b[i]);
    }
    return 0;
  }

  static List<int> _parts(String value) {
    final parts = value.split('.').map((part) {
      final match = RegExp(r'^\d+').firstMatch(part);
      return int.tryParse(match?.group(0) ?? '0') ?? 0;
    }).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.take(3).toList();
  }
}

class AppUpdateService {
  final Dio dio;

  const AppUpdateService(this.dio);

  Future<AppUpdateInfo?> check() async {
    if (kIsWeb) return null;
    final platform = Platform.isIOS ? 'ios' : 'android';
    final packageInfo = await PackageInfo.fromPlatform();
    final response = await dio.get(
      '/app/version',
      queryParameters: {'platform': platform},
    );
    final raw = response.data;
    final data = raw is Map
        ? Map<String, dynamic>.from(
            (raw.containsKey('data') && raw['data'] is Map)
                ? raw['data'] as Map
                : raw,
          )
        : null;
    if (data == null) return null;
    return AppUpdateInfo(
      currentVersion: packageInfo.version,
      latestVersion: '${data['latestVersion'] ?? packageInfo.version}',
      minimumVersion: '${data['minimumVersion'] ?? '0.0.0'}',
      storeUrl: '${data['storeUrl'] ?? ''}',
      releaseNotes: '${data['releaseNotes'] ?? ''}',
    );
  }
}
