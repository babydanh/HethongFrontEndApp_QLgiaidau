import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(Map<String, dynamic> extra) => {
  'name': 'Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  ...extra,
};

void main() {
  test('categoryId is read from the column', () {
    final t = Tournament.fromJson(_json({'categoryId': 'cat-1'}), 't1');
    expect(t.categoryId, 'cat-1');
  });

  test('categoryId falls back to snake_case then the category object', () {
    expect(
      Tournament.fromJson(_json({'category_id': 'cat-2'}), 't1').categoryId,
      'cat-2',
    );
    expect(
      Tournament.fromJson(
        _json({
          'category': {'id': 'cat-3', 'name': 'Pickleball', 'slug': 'pickleball'},
        }),
        't1',
      ).categoryId,
      'cat-3',
    );
  });

  test('categoryId is null when absent and survives copyWith', () {
    final t = Tournament.fromJson(_json({}), 't1');
    expect(t.categoryId, isNull);
    final withCat = Tournament.fromJson(_json({'categoryId': 'cat-1'}), 't1');
    expect(withCat.copyWith(name: 'Other').categoryId, 'cat-1');
  });
}
