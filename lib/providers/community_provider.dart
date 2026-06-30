import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_community_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final communityRepositoryProvider = Provider<ApiCommunityRepository>((ref) {
  return ApiCommunityRepository(ref.watch(dioClientProvider));
});

/// Provider danh sách CLB có filter + search
final communitiesProvider = FutureProvider.family<List<Community>, String?>((ref, search) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getCommunities(search: search, page: 1, limit: 50);
});

/// Provider CLB của tôi
final myCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  try {
    return await repo.getMyCommunities();
  } catch (e) {
    return [];
  }
});

/// Provider chi tiết 1 CLB
final communityDetailProvider = FutureProvider.family<Community?, String>((ref, id) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getCommunityById(id);
});
