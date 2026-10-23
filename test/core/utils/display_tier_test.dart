import 'package:app_quanly_giaidau/core/utils/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveDisplayTier', () {
    test('uses the DUPR tier name instead of the ELO tier', () {
      final tier = resolveDisplayTier(
        elo: 1100,
        tierName: 'High Tier C',
        tierSource: 'DUPR',
        tierAvailable: true,
      );

      expect(tier?.shortCode, 'HTC');
    });

    test('hides a DUPR tier when none is available', () {
      expect(
        resolveDisplayTier(
          elo: 1850,
          tierName: 'Tier S',
          tierSource: 'DUPR',
          tierAvailable: false,
        ),
        isNull,
      );
    });

    test('never derives a DUPR tier from ELO when the name is empty', () {
      expect(
        resolveDisplayTier(
          elo: 1850,
          tierName: '',
          tierSource: 'DUPR',
          tierAvailable: true,
        ),
        isNull,
      );
    });

    test('keeps ELO fallback when tierName is empty', () {
      final tier = resolveDisplayTier(
        elo: 1450,
        tierName: '',
        tierSource: 'ELO',
        tierAvailable: true,
      );

      expect(tier?.shortCode, 'LTB');
    });

    test('treats a missing tierSource as ELO', () {
      final rank = PlayerRanking.fromJson({
        'id': 'rank-1',
        'userId': 'user-1',
        'fullName': 'Player',
        'eloPoints': 1450,
        'tierName': '',
      });

      expect(
        resolveDisplayTier(
          elo: rank.eloPoints,
          tierName: rank.tierName,
          tierSource: rank.tierSource,
          tierAvailable: rank.tierAvailable,
        )?.shortCode,
        'LTB',
      );
    });
  });

  group('ranking tier source fields', () {
    test('parses camelCase and snake_case fields', () {
      final camelCase = PlayerRanking.fromJson({
        'id': 'rank-1',
        'userId': 'user-1',
        'fullName': 'Player',
        'tierSource': 'DUPR',
        'tierAvailable': true,
      });
      final snakeCase = PlayerRanking.fromJson({
        'id': 'rank-2',
        'userId': 'user-1',
        'fullName': 'Player',
        'tier_source': 'DUPR',
        'tier_available': false,
      });

      expect(camelCase.tierSource, 'DUPR');
      expect(camelCase.tierAvailable, isTrue);
      expect(snakeCase.tierSource, 'DUPR');
      expect(snakeCase.tierAvailable, isFalse);
    });

    test('parses tier source fields on UserRankResponse in both formats', () {
      final camelCase = UserRankResponse.fromJson({
        'tierSource': 'DUPR',
        'tierAvailable': true,
      });
      final snakeCase = UserRankResponse.fromJson({
        'tier_source': 'DUPR',
        'tier_available': false,
      });

      expect(camelCase.tierSource, 'DUPR');
      expect(camelCase.tierAvailable, isTrue);
      expect(snakeCase.tierSource, 'DUPR');
      expect(snakeCase.tierAvailable, isFalse);
    });

    test('serializes and copies PlayerRanking tier source fields', () {
      const rank = PlayerRanking(
        id: 'rank-1',
        userId: 'user-1',
        fullName: 'Player',
        tierSource: 'DUPR',
        tierAvailable: true,
      );

      expect(rank.toJson()['tierSource'], 'DUPR');
      expect(rank.toJson()['tierAvailable'], isTrue);
      expect(rank.copyWith().tierSource, 'DUPR');
      expect(rank.copyWith().tierAvailable, isTrue);
    });
  });

  test('EloTier parses decimal DUPR values and nullable maximum', () {
    final tier = EloTier.fromJson({
      'id': 'tier-1',
      'categoryId': 'pickleball',
      'name': 'High Tier C',
      'tierSource': 'DUPR',
      'minValue': 3.5,
      'maxValue': null,
    });

    expect(tier.tierSource, 'DUPR');
    expect(tier.minValue, 3.5);
    expect(tier.maxValue, isNull);

    final snakeCase = EloTier.fromJson({
      'tier_source': 'DUPR',
      'min_value': 3.5,
      'max_value': 4.0,
    });
    expect(snakeCase.tierSource, 'DUPR');
    expect(snakeCase.minValue, 3.5);
    expect(snakeCase.maxValue, 4.0);
  });
}
