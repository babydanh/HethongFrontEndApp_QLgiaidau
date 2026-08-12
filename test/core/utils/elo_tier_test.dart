import 'package:app_quanly_giaidau/core/utils/elo_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveEloTier — ngưỡng số chuẩn WEB', () {
    test('1800 → S', () {
      expect(resolveEloTier(elo: 1800).label, 'S');
      expect(resolveEloTier(elo: 2500).label, 'S');
    });

    test('1700 → A (biên dưới)', () {
      expect(resolveEloTier(elo: 1700).label, 'A');
      expect(resolveEloTier(elo: 1799).label, 'A');
    });

    test('1500 → B (biên dưới)', () {
      expect(resolveEloTier(elo: 1500).label, 'B');
      expect(resolveEloTier(elo: 1699).label, 'B');
    });

    test('1200 → C (biên dưới)', () {
      expect(resolveEloTier(elo: 1200).label, 'C');
      expect(resolveEloTier(elo: 1499).label, 'C');
    });

    test('1100 → D và dưới 1100 vẫn D', () {
      expect(resolveEloTier(elo: 1100).label, 'D');
      expect(resolveEloTier(elo: 1199).label, 'D');
      expect(resolveEloTier(elo: 1000).label, 'D');
      expect(resolveEloTier(elo: 0).label, 'D');
    });
  });

  group('resolveEloTier — ưu tiên tierName từ API', () {
    test('tierName "Tier S" thắng ngưỡng số thấp', () {
      expect(resolveEloTier(elo: 1000, tierName: 'Tier S').label, 'S');
    });

    test('"High/Low Tier A" → A', () {
      expect(resolveEloTier(elo: 1000, tierName: 'High Tier A').label, 'A');
      expect(resolveEloTier(elo: 1000, tierName: 'Low Tier A').label, 'A');
    });

    test('"High Tier B" → B, "Low Tier C" → C, "High Tier D" → D', () {
      expect(resolveEloTier(elo: 1800, tierName: 'High Tier B').label, 'B');
      expect(resolveEloTier(elo: 1800, tierName: 'Low Tier C').label, 'C');
      expect(resolveEloTier(elo: 1800, tierName: 'High Tier D').label, 'D');
    });

    test('tierName không nhận diện được → fallback ngưỡng số', () {
      expect(resolveEloTier(elo: 1550, tierName: 'Chưa xếp hạng').label, 'B');
      expect(resolveEloTier(elo: 1550, tierName: 'unknown').label, 'B');
    });
  });
}