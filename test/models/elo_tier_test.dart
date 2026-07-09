// Tests for EloTier entity
// Covers: RANKING-005

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_tier.dart';

void main() {
  group('TC-FLUTTER-RANKING-005: EloTier.fromJson', () {
    test('should parse full JSON', () {
      final json = {
        'id': 'tier-1',
        'categoryId': 'cat-1',
        'category_id': 'cat-1',
        'name': 'Vang',
        'minElo': 1000,
        'min_elo': 1000,
        'maxElo': 2000,
        'max_elo': 2000,
        'iconUrl': 'https://example.com/gold.png',
        'icon_url': 'https://example.com/gold.png',
      };

      final tier = EloTier.fromJson(json);

      expect(tier.id, 'tier-1');
      expect(tier.name, 'Vang');
      expect(tier.minElo, 1000);
      expect(tier.maxElo, 2000);
      expect(tier.iconUrl, 'https://example.com/gold.png');
    });

    test('should use defaults for missing fields', () {
      final tier = EloTier.fromJson({});
      expect(tier.id, '');
      expect(tier.name, '');
      expect(tier.minElo, 0);
      expect(tier.maxElo, 0);
      expect(tier.iconUrl, null);
    });
  });
}
