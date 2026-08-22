import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
    // ELO below 1000 is clamped to the product floor and is not a separate tier.
    EloTierThreshold(minElo: 1000, name: 'Low Tier D'),
    EloTierThreshold(minElo: 1100, name: 'High Tier D'),
    EloTierThreshold(minElo: 1200, name: 'Low Tier C'),
    EloTierThreshold(minElo: 1300, name: 'High Tier C'),
    EloTierThreshold(minElo: 1400, name: 'Low Tier B'),
    EloTierThreshold(minElo: 1500, name: 'High Tier B'),
    EloTierThreshold(minElo: 1600, name: 'Low Tier A'),
    EloTierThreshold(minElo: 1700, name: 'High Tier A'),
    EloTierThreshold(minElo: 1800, name: 'Tier S'),
  ];

  static String getEloMatchTypeLabel(
    String? matchType,
    AppLocalizations l10n,
  ) {
    switch (matchType) {
      case 'SINGLES':
        return l10n.ranking_matchTypeSingles;
      case 'DOUBLES':
        return l10n.ranking_matchTypeDoubles;
      case 'MIXED_DOUBLES':
        return l10n.ranking_matchTypeMixedDoubles;
      default:
        return l10n.ranking_matchTypeOverview;
    }
  }

  static String getRankDisplayName(
    PlayerRanking ranking,
    AppLocalizations l10n,
  ) {
    final categoryName = ranking.categoryName?.trim().isNotEmpty == true
        ? ranking.categoryName!.trim()
        : l10n.ranking_sportFallback;
    return '$categoryName • ${getEloMatchTypeLabel(ranking.matchType, l10n)}';
  }

  static String getRankTierName(
    PlayerRanking? ranking,
    AppLocalizations l10n,
  ) {
    if (ranking == null || ranking.matchesPlayed <= 0) {
      return l10n.ranking_unranked;
    }
    return ranking.tierName.trim().isNotEmpty
        ? ranking.tierName.trim()
        : l10n.ranking_ranked;
  }

  static String getTierName(int index, AppLocalizations l10n) {
    return switch (index) {
      0 => l10n.ranking_tierLowD,
      1 => l10n.ranking_tierHighD,
      2 => l10n.ranking_tierLowC,
      3 => l10n.ranking_tierHighC,
      4 => l10n.ranking_tierLowB,
      5 => l10n.ranking_tierHighB,
      6 => l10n.ranking_tierLowA,
      7 => l10n.ranking_tierHighA,
      _ => l10n.ranking_tierS,
    };
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

    final active = candidates.where((rank) => rank.matchesPlayed > 0).toList();
    if (active.isEmpty) return null;

    final sorted = [...active]
      ..sort((a, b) {
        final byElo = b.eloPoints.compareTo(a.eloPoints);
        if (byElo != 0) return byElo;

        final byMatches = b.matchesPlayed.compareTo(a.matchesPlayed);
        if (byMatches != 0) return byMatches;

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
    final safeElo = elo < 1000 ? 1000 : elo;
    for (var i = thresholds.length - 1; i >= 0; i--) {
      if (safeElo >= thresholds[i].minElo) return i;
    }
    return 0;
  }

  static EloProgressInfo getEloProgressInfo(
    int elo,
    AppLocalizations l10n,
  ) {
    final safeElo = elo < 1000 ? 1000 : elo;
    final index = findTierIndex(safeElo);
    if (index == thresholds.length - 1) {
            return EloProgressInfo(

        percent: 100,
        currentIndex: 8,
        nextIndex: null,
        label: l10n.ranking_eloPeakProgress,
      );
    }

    final currentMin = thresholds[index].minElo;
    final nextIndex = index + 1;
    final nextMin = thresholds[nextIndex].minElo;
    final range = nextMin - currentMin;
    final rawPercent = range > 0 ? ((safeElo - currentMin) / range) * 100 : 0.0;
    final remaining = nextMin - safeElo;
    final nextName = getTierName(nextIndex, l10n);

    return EloProgressInfo(
      percent: rawPercent.clamp(0.0, 100.0),
      currentIndex: index,
      nextIndex: nextIndex,
      label: l10n.ranking_eloToNext(
        remaining <= 0 ? nextMin - currentMin : remaining,
        nextName,
      ),
    );
  }

  static ShieldStatus getShieldStatus(
    PlayerRanking? ranking,
    AppLocalizations l10n,
  ) {
    final matchesPlayed = ranking?.matchesPlayed ?? 0;
    if (matchesPlayed <= 0) {
      return ShieldStatus(
        state: ShieldState.onboarding,
        copy: l10n.ranking_shieldOnboarding,
      );
    }

    if (ranking?.shieldActive == true) {
      return ShieldStatus(
        state: ShieldState.active,
        copy: l10n.ranking_shieldActive,
      );
    }

    return ShieldStatus(
      state: ShieldState.broken,
      copy: l10n.ranking_shieldBroken,
    );
  }

  static String getOnboardingCopy(AppLocalizations l10n) {
    return l10n.ranking_eloOnboarding;
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
