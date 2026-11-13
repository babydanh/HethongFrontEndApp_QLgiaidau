import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(Map<String, dynamic> extra) => {
  'name': 'Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION',
  'entryFee': 150000,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  ...extra,
};

void main() {
  test('TC-FEEMODE-APP-01 missing feeCollectionMode defaults to PAYOS', () {
    final t = Tournament.fromJson(_json({}), 't1');
    expect(t.feeCollectionMode, 'PAYOS');
    expect(t.isDirectFeeCollection, isFalse);
  });

  test('TC-FEEMODE-APP-02 DIRECT is parsed, case and spaces tolerated', () {
    for (final raw in ['DIRECT', 'direct', ' Direct ']) {
      final t = Tournament.fromJson(_json({'feeCollectionMode': raw}), 't1');
      expect(t.feeCollectionMode, 'DIRECT', reason: raw);
      expect(t.isDirectFeeCollection, isTrue, reason: raw);
    }
  });

  test('TC-FEEMODE-APP-03 unknown or null values fall back to PAYOS', () {
    for (final raw in <Object?>['MANUAL', '', null, 42]) {
      final t = Tournament.fromJson(_json({'feeCollectionMode': raw}), 't1');
      expect(t.isDirectFeeCollection, isFalse, reason: '$raw');
    }
    expect(
      Tournament.fromJson(
        _json({'feeCollectionMode': 'PAYOS'}),
        't1',
      ).isDirectFeeCollection,
      isFalse,
    );
  });

  test('TC-FEEMODE-APP-04 copyWith keeps and overrides the mode', () {
    final direct = Tournament.fromJson(
      _json({'feeCollectionMode': 'DIRECT'}),
      't1',
    );
    expect(direct.copyWith(name: 'Other').isDirectFeeCollection, isTrue);
    expect(
      direct.copyWith(feeCollectionMode: 'PAYOS').isDirectFeeCollection,
      isFalse,
    );
  });

  test('TC-FEEMODE-APP-05 normalize helpers accept raw backend values', () {
    expect(normalizeFeeCollectionMode('direct'), 'DIRECT');
    expect(normalizeFeeCollectionMode(null), 'PAYOS');
    expect(isDirectFeeCollectionMode('DIRECT'), isTrue);
    expect(isDirectFeeCollectionMode('whatever'), isFalse);
  });
}
