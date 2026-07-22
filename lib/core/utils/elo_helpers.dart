import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

class EloTierThreshold {
  final int minElo;
  final String name;

  const EloTierThreshold({required this.minElo, required this.name});
}

class EloProgressInfo {
  final double percent;
  final int currentIndex;
  final int? nextIndex;
  final String label;

  const EloProgressInfo({
    required this.percent,
    required this.currentIndex,
    required this.nextIndex,
    required this.label,
  });
}

enum ShieldState { onboarding, active, broken }

class ShieldStatus {
  final ShieldState state;
  final String copy;

  const ShieldStatus({required this.state, required this.copy});
}

class EloHelpers {
  static const thresholds = <EloTierThreshold>[
    EloTierThreshold(minElo: 0, name: 'Low Tier D'),
    EloTierThreshold(minElo: 1100, name: 'High Tier D'),
    EloTierThreshold(minElo: 1200, name: 'Low Tier C'),
    EloTierThreshold(minElo: 1300, name: 'High Tier C'),
    EloTierThreshold(minElo: 1400, name: 'Low Tier B'),
    EloTierThreshold(minElo: 1500, name: 'High Tier B'),
    EloTierThreshold(minElo: 1600, name: 'Low Tier A'),
    EloTierThreshold(minElo: 1700, name: 'High Tier A'),
    EloTierThreshold(minElo: 1800, name: 'Tier S'),
  ];

  static String getEloMatchTypeLabel(String? matchType) {
    switch (matchType) {
      case 'SINGLES':
        return 'Đơn';
      case 'DOUBLES':
        return 'Đôi';
      case 'MIXED_DOUBLES':
        return 'Đôi nam nữ';
      default:
        return 'Tổng quan';
    }
  }

  static String getRankDisplayName(PlayerRanking ranking) {
    final categoryName = ranking.categoryName?.trim().isNotEmpty == true
        ? ranking.categoryName!.trim()
        : 'Môn thi đấu';
    return '$categoryName • ${getEloMatchTypeLabel(ranking.matchType)}';
  }

  static String getRankTierName(PlayerRanking? ranking) {
    if (ranking == null || ranking.matchesPlayed <= 0) return 'Chưa xếp hạng';
    return ranking.tierName.trim().isNotEmpty
        ? ranking.tierName.trim()
        : 'Đã xếp hạng';
  }

  static int getRankWinRate(PlayerRanking? ranking) {
    if (ranking == null || ranking.matchesPlayed <= 0) return 0;
    return ((ranking.matchesWon / ranking.matchesPlayed) * 100).round();
  }

  static PlayerRanking? getBestRankForCategory(
    List<PlayerRanking> ranks, {
    String? categoryId,
  }) {
    final candidates = categoryId == null || categoryId.isEmpty
        ? ranks
        : ranks.where((rank) => rank.categoryId == categoryId).toList();
    if (candidates.isEmpty) return null;

    final sorted = [...candidates]
      ..sort((a, b) {
        final byMatches = b.matchesPlayed.compareTo(a.matchesPlayed);
        if (byMatches != 0) return byMatches;

        final byElo = b.eloPoints.compareTo(a.eloPoints);
        if (byElo != 0) return byElo;

        return (b.updatedAt ?? '').compareTo(a.updatedAt ?? '');
      });

    return sorted.first;
  }

  static List<PlayerRanking> getRanksForCategory(
    List<PlayerRanking> ranks, {
    String? categoryId,
  }) {
    final filtered = categoryId == null || categoryId.isEmpty
        ? ranks
        : ranks.where((rank) => rank.categoryId == categoryId).toList();
    final sorted = [...filtered]
      ..sort((a, b) {
        final byType = _matchTypeOrder(
          a.matchType,
        ).compareTo(_matchTypeOrder(b.matchType));
        if (byType != 0) return byType;
        return b.eloPoints.compareTo(a.eloPoints);
      });
    return sorted;
  }

  static int findTierIndex(int elo) {
    final safeElo = elo < 0 ? 0 : elo;
    for (var i = thresholds.length - 1; i >= 0; i--) {
      if (safeElo >= thresholds[i].minElo) return i;
    }
    return 0;
  }

  static EloProgressInfo getEloProgressInfo(int elo) {
    final safeElo = elo < 0 ? 0 : elo;
    final index = findTierIndex(safeElo);
    if (index == thresholds.length - 1) {
      return const EloProgressInfo(
        percent: 100,
        currentIndex: 8,
        nextIndex: null,
        label: '🏆 Đã đạt đỉnh — Tier S',
      );
    }

    final currentMin = thresholds[index].minElo;
    final nextIndex = index + 1;
    final nextMin = thresholds[nextIndex].minElo;
    final range = nextMin - currentMin;
    final rawPercent = range > 0 ? ((safeElo - currentMin) / range) * 100 : 0.0;
    final remaining = nextMin - safeElo;
    final nextName = thresholds[nextIndex].name;

    return EloProgressInfo(
      percent: rawPercent.clamp(0.0, 100.0),
      currentIndex: index,
      nextIndex: nextIndex,
      label: remaining <= 0
          ? 'Còn ${nextMin - currentMin} ELO tới $nextName'
          : 'Còn $remaining ELO tới $nextName',
    );
  }

  static ShieldStatus getShieldStatus(PlayerRanking? ranking) {
    final matchesPlayed = ranking?.matchesPlayed ?? 0;
    if (matchesPlayed <= 0) {
      return const ShieldStatus(
        state: ShieldState.onboarding,
        copy: 'Đánh 1 trận xếp hạng để mở khóa ELO và khiên rank.',
      );
    }

    if (ranking?.shieldActive == true) {
      return const ShieldStatus(
        state: ShieldState.active,
        copy: 'Khiên còn nguyên — đỡ 1 lần rớt khỏi mốc rank hiện tại.',
      );
    }

    return const ShieldStatus(
      state: ShieldState.broken,
      copy: 'Khiên đã vỡ — cần lên rank hoặc rớt rank để hồi lại khiên.',
    );
  }

  static String getOnboardingCopy() {
    return 'Đánh 1 trận xếp hạng để bắt đầu tiến trình ELO.';
  }

  static int _matchTypeOrder(String? type) {
    switch (type) {
      case 'SINGLES':
        return 0;
      case 'DOUBLES':
        return 1;
      case 'MIXED_DOUBLES':
        return 2;
      default:
        return 3;
    }
  }
}
