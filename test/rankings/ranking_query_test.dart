/// Test cho `ranking_query_helpers.dart` — sanitize query params cho ranking API.
///
/// Backend `GET /rankings` nhận: page, limit, categoryId, matchType,
/// genderRestriction, scope, provinceCode, communityId.
/// Backend KHÔNG hỗ trợ search param, nên search chỉ dùng local.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/core/utils/ranking_query_helpers.dart';

void main() {
  group('buildRankingQueryParams', () {
    test('omits categoryId when "all"', () {
      final params = buildRankingQueryParams(
        categoryId: 'all',
        matchType: 'SINGLES',
      );
      expect(params, isNot(contains('categoryId')));
    });

    test('omits categoryId when null', () {
      final params = buildRankingQueryParams(
        categoryId: null,
        matchType: 'SINGLES',
      );
      expect(params, isNot(contains('categoryId')));
    });

    test('omits matchType when empty', () {
      final params = buildRankingQueryParams(
        categoryId: 'cat-1',
        matchType: '',
      );
      expect(params, isNot(contains('matchType')));
    });

    test('omits genderRestriction when null', () {
      final params = buildRankingQueryParams(
        categoryId: 'cat-1',
        genderRestriction: null,
      );
      expect(params, isNot(contains('genderRestriction')));
    });

    test('omits provinceCode when null', () {
      final params = buildRankingQueryParams(
        categoryId: 'cat-1',
        provinceCode: null,
      );
      expect(params, isNot(contains('provinceCode')));
    });

    test('omits provinceCode when empty', () {
      final params = buildRankingQueryParams(
        categoryId: 'cat-1',
        provinceCode: '',
      );
      expect(params, isNot(contains('provinceCode')));
    });

    test('trims and omits whitespace-only optional params', () {
      final params = buildRankingQueryParams(
        categoryId: '  ',
        matchType: '  ',
        genderRestriction: '  ',
        provinceCode: '  ',
      );
      expect(params.keys, unorderedEquals(['scope', 'page', 'limit']));
    });

    test('trims valid optional params before sending to API', () {
      final params = buildRankingQueryParams(
        categoryId: ' cat-1 ',
        matchType: ' DOUBLES ',
        genderRestriction: ' FEMALE ',
        provinceCode: ' 79 ',
      );
      expect(params['categoryId'], 'cat-1');
      expect(params['matchType'], 'DOUBLES');
      expect(params['genderRestriction'], 'FEMALE');
      expect(params['provinceCode'], '79');
    });

    test('includes valid categoryId', () {
      final params = buildRankingQueryParams(
        categoryId: 'uuid-cat',
        matchType: 'SINGLES',
      );
      expect(params['categoryId'], 'uuid-cat');
    });

    test('includes matchType when provided', () {
      final params = buildRankingQueryParams(
        categoryId: 'uuid-cat',
        matchType: 'DOUBLES',
      );
      expect(params['matchType'], 'DOUBLES');
    });

    test('includes genderRestriction when provided', () {
      final params = buildRankingQueryParams(
        categoryId: 'uuid-cat',
        genderRestriction: 'FEMALE',
      );
      expect(params['genderRestriction'], 'FEMALE');
    });

    test('includes provinceCode when provided', () {
      final params = buildRankingQueryParams(
        categoryId: 'uuid-cat',
        provinceCode: '79',
      );
      expect(params['provinceCode'], '79');
    });

    test('preserves scope=PUBLIC', () {
      final params = buildRankingQueryParams(categoryId: 'uuid-cat');
      expect(params['scope'], 'PUBLIC');
    });

    test('preserves limit without legacy page offset', () {
      final params = buildRankingQueryParams(
        categoryId: 'uuid-cat',
        limit: 50,
      );
      expect(params['limit'], 50);
    });

    test('uses default limit=100 when omitted', () {
      final params = buildRankingQueryParams(categoryId: 'uuid-cat');
      expect(params['limit'], 100);
    });

    test('includes only non-null/non-empty params', () {
      final params = buildRankingQueryParams(
        categoryId: 'all',
        matchType: '',
        genderRestriction: null,
        provinceCode: null,
      );
      // Chỉ còn scope, page, limit
      expect(params.keys.length, 3);
      expect(params['scope'], 'PUBLIC');
      expect(params['page'], 1);
      expect(params['limit'], 100);
    });
  });
}
