import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

/// Hạng dùng để tô viền avatar của chính người dùng: hạng ELO cao nhất trong
/// các hạng đủ điều kiện lên bảng xếp hạng; nếu không có thì hạng đầu tiên.
///
/// Cùng quy tắc với màn Hồ sơ (`profile_screen.dart`, biến `bestRanking`).
PlayerRanking? bestRankingOf(List<PlayerRanking> rankings) {
  PlayerRanking? best;
  for (final r in rankings) {
    if (!r.isLeaderboardEligible || r.eloPoints <= 0) continue;
    if (best == null || r.eloPoints > best.eloPoints) best = r;
  }
  if (best != null) return best;
  return rankings.isNotEmpty ? rankings.first : null;
}
