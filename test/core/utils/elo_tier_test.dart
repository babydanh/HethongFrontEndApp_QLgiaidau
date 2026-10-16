import 'package:app_quanly_giaidau/core/utils/elo_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveEloTier — ngưỡng số chuẩn WEB', () {
    test('1800 → TS', () {
      expect(resolveEloTier(elo: 1800).label, 'TS');
      expect(resolveEloTier(elo: 2500).label, 'TS');
    });

    test('1700 → HTA (biên dưới)', () {
      expect(resolveEloTier(elo: 1700).label, 'HTA');
      expect(resolveEloTier(elo: 1799).label, 'HTA');
    });

    test('1500 → HTB (biên dưới), 1699 → LTA', () {
      expect(resolveEloTier(elo: 1500).label, 'HTB');
      expect(resolveEloTier(elo: 1699).label, 'LTA');
    });

    test('1200 → LTC (biên dưới), 1499 → LTB', () {
      expect(resolveEloTier(elo: 1200).label, 'LTC');
      expect(resolveEloTier(elo: 1499).label, 'LTB');
    });

    test('1100 → HTD, dưới 1100 → LTD', () {
      expect(resolveEloTier(elo: 1100).label, 'HTD');
      expect(resolveEloTier(elo: 1199).label, 'HTD');
      expect(resolveEloTier(elo: 1000).label, 'LTD');
      expect(resolveEloTier(elo: 0).label, 'LTD');
    });
  });

  group('resolveEloTier — ưu tiên tierName từ API', () {
    test('tierName "Tier S" thắng ngưỡng số thấp', () {
      expect(resolveEloTier(elo: 1000, tierName: 'Tier S').label, 'TS');
    });

    test('"High Tier A" → HTA, "Low Tier A" → LTA', () {
      expect(resolveEloTier(elo: 1000, tierName: 'High Tier A').label, 'HTA');
      expect(resolveEloTier(elo: 1000, tierName: 'Low Tier A').label, 'LTA');
    });

    test('"High Tier B" → HTB, "Low Tier C" → LTC, "High Tier D" → HTD', () {
      expect(resolveEloTier(elo: 1800, tierName: 'High Tier B').label, 'HTB');
      expect(resolveEloTier(elo: 1800, tierName: 'Low Tier C').label, 'LTC');
      expect(resolveEloTier(elo: 1800, tierName: 'High Tier D').label, 'HTD');
    });

    test('tierName không nhận diện được → fallback ngưỡng số', () {
      expect(resolveEloTier(elo: 1550, tierName: 'Chưa xếp hạng').label, 'HTB');
      expect(resolveEloTier(elo: 1550, tierName: 'unknown').label, 'HTB');
    });
  });
}