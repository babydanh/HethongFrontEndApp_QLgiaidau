import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

abstract class IRankingRepository {
  /// Lấy bảng xếp hạng PUBLIC theo category.
  /// `limit` mặc định 100 để hiển thị Top 100 trên app.
  Future<List<PlayerRanking>> getRankings({
    int? page,
    int? limit,
    String? categoryId,
  });

  /// Lấy rank tổng hợp của 1 user (public + community).
  Future<UserRankResponse> getUserRank(
    String userId,
    String categoryId,
  );

  /// Lấy danh sách các bậc ELO (tier) của 1 môn thể thao.
  /// GET /categories/:id/elo-tiers
  Future<List<EloTier>> getEloTiers(String categoryId);
}
