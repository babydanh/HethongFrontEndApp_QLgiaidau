import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    throw Exception('Chưa đăng nhập');
  }

  final repo = ref.read(userRepositoryProvider);
  try {
    return await repo.getProfile();
  } catch (e) {
    // Invite token auth không có JWT → API /users/profile trả về 401
    // Trả về profile rỗng thay vì crash
    return UserProfile(
      id: '',
      fullName: 'Người dùng',
    );
  }
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
