import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'dart:ui';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/utils/ranking_query_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/repositories/ranking_repository.dart';

class ApiRankingRepository implements IRankingRepository {
  static const _log = AppLogger('ApiRankingRepo');
  final DioClient _dioClient;

  ApiRankingRepository(this._dioClient);

  @override
  Future<List<PlayerRanking>> getRankings({
    int? limit,
    String? categoryId,
    String? matchType,
    String? genderRestriction,
    String? provinceCode,
  }) async {
    _log.info('Tải bảng xếp hạng: limit=$limit, categoryId=$categoryId');
    try {
      final queryParams = buildRankingQueryParams(
        categoryId: categoryId,
        matchType: matchType,
        genderRestriction: genderRestriction,
        provinceCode: provinceCode,
        limit: limit ?? 100,
      );

      final rankings = <PlayerRanking>[];
      String? cursor;
      const pageSize = 100;
      for (var page = 0; page < 50; page++) {
        final pageQuery = <String, dynamic>{...queryParams, 'limit': pageSize};
        if (cursor != null && cursor.isNotEmpty) pageQuery['cursor'] = cursor;
        final response = await _dioClient.dio.get(
          '/rankings',
          queryParameters: pageQuery,
        );
        if (response.statusCode != 200) {
          throw Exception(
            lookupAppLocalizations(
              PlatformDispatcher.instance.locale,
            ).rankingRequestFailed,
          );
        }
        final raw = response.data;
        final List<dynamic> dataList = raw is Map<String, dynamic>
            ? (raw['data'] as List<dynamic>? ?? [])
            : (raw as List<dynamic>? ?? []);
        rankings.addAll(
          dataList.map(
            (json) => PlayerRanking.fromJson(json as Map<String, dynamic>),
          ),
        );
        final meta = raw is Map<String, dynamic> && raw['meta'] is Map
            ? Map<String, dynamic>.from(raw['meta'] as Map)
            : const <String, dynamic>{};
        final next = meta['nextCursor']?.toString();
        if (meta['hasMore'] != true ||
            next == null ||
            next.isEmpty ||
            next == cursor ||
            dataList.isEmpty) {
          break;
        }
        cursor = next;
      }
      final enriched = <PlayerRanking>[];
      for (var i = 0; i < rankings.length; i++) {
        enriched.add(rankings[i].copyWith(rank: i + 1));
      }
      return enriched;
    } catch (e, stack) {
      _log.error('Lỗi tải bảng xếp hạng', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<FootballTeamRanking>> getFootballTeamRankings({
    required String categoryId,
    String? communityId,
    int? limit,
  }) async {
    final response = await _dioClient.dio.get(
      '/rankings/football-teams',
      queryParameters: {
        'categoryId': categoryId,
        'limit': limit ?? 100,
        if (communityId != null && communityId.isNotEmpty)
          'communityId': communityId,
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        lookupAppLocalizations(
          PlatformDispatcher.instance.locale,
        ).rankingRequestFailed,
      );
    }
    final raw = response.data;
    final list = raw is Map<String, dynamic>
        ? (raw['data'] as List<dynamic>? ?? [])
        : (raw as List<dynamic>? ?? []);
    return list
        .map(
          (json) => FootballTeamRanking.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<EloTier>> getEloTiers(String categoryId) async {
    _log.info('Tải danh sách bậc ELO: categoryId=$categoryId');
    try {
      final response = await _dioClient.dio.get(
        '/categories/$categoryId/elo-tiers',
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        // Endpoint có thể trả mảng trực tiếp hoặc bọc trong { data: [...] }
        final List<dynamic> list = raw is Map<String, dynamic>
            ? (raw['data'] as List<dynamic>? ?? [])
            : (raw as List<dynamic>? ?? []);
        final tiers = list
            .map((json) => EloTier.fromJson(json as Map<String, dynamic>))
            .toList();
        // Sắp xếp tăng dần theo minElo để hiển thị legend đúng thứ tự.
        tiers.sort((a, b) => a.minElo.compareTo(b.minElo));
        return tiers;
      }

      throw Exception(
        lookupAppLocalizations(
          PlatformDispatcher.instance.locale,
        ).rankingEloTiersLoadError,
      );
    } catch (e, stack) {
      _log.error('Lỗi tải danh sách bậc ELO', e, stack);
      rethrow;
    }
  }

  @override
  Future<UserRankResponse> getUserRank(String userId, String categoryId) async {
    _log.info('Tải rank của user: $userId trong category: $categoryId');
    try {
      final response = await _dioClient.dio.get(
        '/rankings/user/$userId',
        queryParameters: categoryId.isNotEmpty
            ? {'categoryId': categoryId}
            : null,
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final data =
            raw['data'] as Map<String, dynamic>? ??
            raw as Map<String, dynamic>?;
        // API trả về { publicRanks: [...], communityRanks: [...] }
        // Tìm rank trong publicRanks theo categoryId
        if (data != null) {
          final publicRanks = data['publicRanks'] as List<dynamic>? ?? [];
          for (final r in publicRanks) {
            final rank = PlayerRanking.fromJson(r as Map<String, dynamic>);
            if (rank.categoryId == categoryId || categoryId.isEmpty) {
              return UserRankResponse(
                eloPoints: rank.eloPoints,
                tierName: rank.tierName,
                categoryId: rank.categoryId,
              );
            }
          }
          return UserRankResponse(
            eloPoints: 1000,
            tierName: lookupAppLocalizations(
              PlatformDispatcher.instance.locale,
            ).rankingUnrankedFallback,
            categoryId: categoryId,
          );
        }
      }

      throw Exception(
        lookupAppLocalizations(
          PlatformDispatcher.instance.locale,
        ).rankingLoadError,
      );
    } catch (e, stack) {
      _log.error('Lỗi tải user rank', e, stack);
      rethrow;
    }
  }
}
