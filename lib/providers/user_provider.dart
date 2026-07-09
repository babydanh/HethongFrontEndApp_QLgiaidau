import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class Province {
  final String code;
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

final provincesProvider = FutureProvider<List<Province>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/regions/provinces');
  final List<dynamic> data = response.data['data'] ?? response.data;
  return data.map((json) => Province.fromJson(json)).toList();
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    throw Exception('Chưa đăng nhập');
  }

  final repo = ref.read(userRepositoryProvider);
  return await repo.getProfile();
});

/// Provider lấy hồ sơ công khai của người dùng khác.
/// GET /users/:id/public — dùng cho trang xem profile người khác.
final userPublicProfileProvider = FutureProvider.family<UserPublicProfile, String>((ref, userId) async {
  final repo = ref.read(userRepositoryProvider);
  return repo.getPublicProfile(userId);
});

/// Gọi GET /api/v1/rankings/user/:userId
/// BE trả về { data: { publicRanks: [...], communityRanks: [...] } }
/// TransformInterceptor wrap: { data: { publicRanks: [...], ... }, message, statusCode }
final userRankingsProvider = FutureProvider<List<PlayerRanking>>((ref) async {
  final profileAsync = ref.watch(userProfileProvider);
  final profile = profileAsync.asData?.value;
  if (profile == null) return [];

  final userId = profile.id;
  if (userId.isEmpty) return [];

  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/rankings/user/$userId');

    // response.data là Map (Dio tự parse JSON)
    final raw = response.data;
    if (raw is! Map<String, dynamic>) return [];

    // TransformInterceptor: { data: ..., message, statusCode }
    final inner = raw['data'] as Map<String, dynamic>? ?? raw;

    // inner = { publicRanks: [...], communityRanks: [...] }
    final list = inner['publicRanks'] as List<dynamic>? ?? [];
    return list
        .map((e) => PlayerRanking.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});
