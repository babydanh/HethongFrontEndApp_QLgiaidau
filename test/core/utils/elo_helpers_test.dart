import 'package:app_quanly_giaidau/core/utils/elo_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  PlayerRanking ranking({
    required String id,
    required int elo,
    required int played,
    String? updatedAt,
    String? categoryId,
    String? categoryName,
    String? matchType,
    bool? shieldActive,
  }) {
    return PlayerRanking(
      id: id,
      userId: 'user-1',
      fullName: 'Nguyen Van A',
      eloPoints: elo,
      matchesPlayed: played,
      matchesWon: played ~/ 2,
      categoryId: categoryId,
      categoryName: categoryName,
      matchType: matchType,
      updatedAt: updatedAt,
      shieldActive: shieldActive,
    );
  }

  group('EloHelpers.getBestRankForCategory', () {
    test('ưu tiên nhiều trận hơn trước ELO cao hơn', () {
      final best = EloHelpers.getBestRankForCategory([
        ranking(id: 'low-played-high-elo', elo: 1700, played: 4),
        ranking(id: 'high-played-low-elo', elo: 1300, played: 12),
      ]);

      expect(best?.id, 'high-played-low-elo');
    });

    test('nếu số trận bằng nhau thì chọn ELO cao hơn', () {
      final best = EloHelpers.getBestRankForCategory([
        ranking(id: 'elo-1300', elo: 1300, played: 8),
        ranking(id: 'elo-1450', elo: 1450, played: 8),
      ]);

      expect(best?.id, 'elo-1450');
    });

    test('nếu số trận và ELO bằng nhau thì chọn updatedAt mới nhất', () {
      final best = EloHelpers.getBestRankForCategory([
        ranking(
          id: 'old',
          elo: 1400,
          played: 8,
          updatedAt: '2026-07-01T00:00:00Z',
        ),
        ranking(
          id: 'new',
          elo: 1400,
          played: 8,
          updatedAt: '2026-07-19T00:00:00Z',
        ),
      ]);

      expect(best?.id, 'new');
    });

    test('lọc theo categoryId trước khi chọn rank nổi bật', () {
      final best = EloHelpers.getBestRankForCategory([
        ranking(
          id: 'pickleball',
          elo: 1200,
          played: 20,
          categoryId: 'pickleball',
        ),
        ranking(id: 'badminton', elo: 1500, played: 6, categoryId: 'badminton'),
      ], categoryId: 'badminton');

      expect(best?.id, 'badminton');
    });
  });

  group('EloHelpers labels', () {
    test('hiển thị đầy đủ môn và loại đánh', () {
      final displayName = EloHelpers.getRankDisplayName(
        ranking(
          id: 'rank-1',
          elo: 1500,
          played: 10,
          categoryName: 'Pickleball',
          matchType: 'DOUBLES',
        ),
        l10n,
      );

      expect(displayName, 'Pickleball • Đôi');
    });

    test('fallback loại đánh không rõ thành Tổng quan', () {
      expect(EloHelpers.getEloMatchTypeLabel(null, l10n), 'Tổng quan');

      expect(EloHelpers.getEloMatchTypeLabel('UNKNOWN', l10n), 'Tổng quan');
    });
  });

  group('EloHelpers shield', () {
    test('chưa có trận thì khiên ở trạng thái onboarding', () {
      final status = EloHelpers.getShieldStatus(
        ranking(id: 'r', elo: 1000, played: 0),
        l10n,
      );

      expect(status.state, ShieldState.onboarding);
      expect(status.copy, contains('mở khóa ELO'));
    });

    test('shieldActive true thì khiên đang hoạt động', () {
      final status = EloHelpers.getShieldStatus(
        ranking(id: 'r', elo: 1200, played: 5, shieldActive: true),
        l10n,
      );

      expect(status.state, ShieldState.active);
    });

    test('đã đấu nhưng shieldActive false thì khiên đã vỡ', () {
      final status = EloHelpers.getShieldStatus(
        ranking(id: 'r', elo: 1200, played: 5, shieldActive: false),
        l10n,
      );

      expect(status.state, ShieldState.broken);
    });
  });
}
