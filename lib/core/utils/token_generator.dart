import 'dart:math';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';

class TokenGenerator {
  static final _random = Random.secure();

  // Loại bỏ ký tự dễ nhầm lẫn: 0/O, 1/I/L
  static const _chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Sinh token với prefix theo role
  /// VD: "ADM-X7K9-M2P4"
  static String generate(String role) {
    final prefix = switch (role) {
      AppConstants.roleAdmin => AppConstants.tokenPrefixAdmin,
      AppConstants.roleReferee => AppConstants.tokenPrefixReferee,
      AppConstants.roleViewer => AppConstants.tokenPrefixViewer,
      _ => 'UNK',
    };

    final part1 = _randomString(4);
    final part2 = _randomString(4);

    return '$prefix-$part1-$part2';
  }

  /// Sinh cả bộ 3 token cho 1 giải đấu
  static Map<String, String> generateAll() {
    return {
      AppConstants.roleAdmin: generate(AppConstants.roleAdmin),
      AppConstants.roleReferee: generate(AppConstants.roleReferee),
      AppConstants.roleViewer: generate(AppConstants.roleViewer),
    };
  }

  static String _randomString(int length) {
    return List.generate(
      length,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
  }
}
