import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/locale_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';

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
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/regions/provinces');
    final raw = response.data;
    final payload = raw is Map ? (raw['data'] ?? raw) : raw;
    final List<dynamic> data = payload is List ? payload : [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => Province.fromJson(json))
        .toList();
  } catch (_) {
    return [];
  }
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    final l10n = lookupAppLocalizations(ref.read(localeProvider));
    return UserProfile(id: '', fullName: l10n.userGuestFallback, email: '');
  }

  try {
    final repo = ref.read(userRepositoryProvider);
    return await repo.getProfile();
  } catch (_) {
    // DioClient chịu trách nhiệm refresh token. Không tự đăng xuất tại đây vì
    // lỗi mạng/timeout có thể vẫn mang response 401 của request ban đầu.
    rethrow;
  }
});

/// Provider lấy hồ sơ công khai của người dùng khác.
/// GET /users/:id/public — dùng cho trang xem profile người khác.
final userPublicProfileProvider =
    FutureProvider.family<UserPublicProfile, String>((ref, userId) async {
      final repo = ref.read(userRepositoryProvider);
      return repo.getPublicProfile(userId);
    });

bool _isMockInvolvedMatch(MatchModel match) {
  return match.team1IsMock ||
      match.team2IsMock ||
      match.team1MemberInfos.any((member) => member.isMock) ||
      match.team2MemberInfos.any((member) => member.isMock);
}

/// Trận đấu công khai của hồ sơ, dùng cùng endpoint với web.
final publicUserMatchesProvider =
    FutureProvider.family<List<MatchModel>, String>((ref, userId) async {
      final response = await ref
          .read(dioProvider)
          .get('/matches', queryParameters: {'userId': userId, 'limit': 10});
      final raw = response.data;
      final payload = raw is Map<String, dynamic> ? (raw['data'] ?? raw) : raw;
      final list = payload is Map<String, dynamic>
          ? (payload['data'] as List<dynamic>? ?? [])
          : (payload as List<dynamic>? ?? []);
      return list.whereType<Map<String, dynamic>>().map((item) {
        final id = item['id']?.toString() ?? '';
        return MatchModel.fromJson(item, id);
      }).where((match) => !_isMockInvolvedMatch(match)).toList();
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

    final raw = response.data;
    if (raw is! Map) return [];

    final inner = raw['data'] is Map ? raw['data'] as Map : raw;
    final list = inner['publicRanks'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => PlayerRanking.fromJson(e))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Các đội bóng người dùng đang tham gia, dùng để hiển thị ELO đội cao nhất
/// trong dashboard cá nhân. Backend trả rank theo category đang hoạt động.
final myFootballTeamsProvider = FutureProvider<List<FootballTeamSummary>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return const [];
  return ref.read(footballTeamApiProvider).listMyFootballTeams();
});
