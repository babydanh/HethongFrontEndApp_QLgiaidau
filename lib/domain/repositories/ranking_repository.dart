import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

abstract class IRankingRepository {
  Future<List<PlayerRanking>> getRankings({
    int? page,
    int? limit,
    String? categoryId,
  });

  Future<UserRankResponse> getUserRank(
    String userId,
    String categoryId,
  );
}
