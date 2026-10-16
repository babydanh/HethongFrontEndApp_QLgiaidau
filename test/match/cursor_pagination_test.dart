import 'package:flutter_test/flutter_test.dart';

import 'package:app_quanly_giaidau/core/utils/cursor_pagination.dart';

void main() {
  test('does not advance when metadata says more but cursor is missing', () {
    expect(
      canAdvanceCursorPage(
        isLoading: false,
        hasCachedPage: false,
        nextCursor: null,
      ),
      isFalse,
    );
  });

  test('advances with a non-empty cursor', () {
    expect(
      canAdvanceCursorPage(
        isLoading: false,
        hasCachedPage: false,
        nextCursor: 'opaque-cursor',
      ),
      isTrue,
    );
  });

  test('does not advance while a page request is in flight', () {
    expect(
      canAdvanceCursorPage(
        isLoading: true,
        hasCachedPage: true,
        nextCursor: 'opaque-cursor',
      ),
      isFalse,
    );
  });

  test('does not advance with a blank cursor and no cached page', () {
    expect(
      canAdvanceCursorPage(
        isLoading: false,
        hasCachedPage: false,
        nextCursor: '   ',
      ),
      isFalse,
    );
  });

  group('fetchCursorPageWhere', () {
    test('returns the kept items of the first page that has one', () async {
      final requests = <String?>[];
      final pages = <String?, CursorPage<String>>{
        null: (items: ['hidden'], nextCursor: 'a'),
        'a': (items: ['shown', 'hidden'], nextCursor: 'b'),
      };
      final page = await fetchCursorPageWhere<String>(
        startCursor: null,
        accept: (item) => item == 'shown',
        fetchPage: (cursor) async {
          requests.add(cursor);
          return pages[cursor]!;
        },
      );
      expect(page.items, ['shown']);
      expect(page.nextCursor, 'b');
      expect(requests, [null, 'a']);
    });

    test('returns no cursor when the API has no further page', () async {
      final requests = <String?>[];
      final page = await fetchCursorPageWhere<String>(
        startCursor: null,
        accept: (item) => item == 'shown',
        fetchPage: (cursor) async {
          requests.add(cursor);
          return (items: ['hidden'], nextCursor: null);
        },
      );
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
      expect(requests, [null]);
    });

    test('returns a repeated cursor without requesting it again', () async {
      final requests = <String?>[];
      final pages = <String?, CursorPage<String>>{
        null: (items: ['hidden'], nextCursor: 'a'),
        'a': (items: ['hidden'], nextCursor: 'b'),
        'b': (items: ['hidden'], nextCursor: 'a'),
      };
      final page = await fetchCursorPageWhere<String>(
        startCursor: null,
        accept: (item) => item == 'shown',
        fetchPage: (cursor) async {
          requests.add(cursor);
          return pages[cursor]!;
        },
      );
      expect(page.items, isEmpty);
      expect(page.nextCursor, 'a');
      expect(requests, [null, 'a', 'b']);
    });

    test('keeps the cursor after maxExtraPages extra requests', () async {
      final requests = <String?>[];
      final page = await fetchCursorPageWhere<String>(
        startCursor: null,
        accept: (item) => item == 'shown',
        maxExtraPages: 2,
        fetchPage: (cursor) async {
          requests.add(cursor);
          return (items: ['hidden'], nextCursor: 'c${requests.length}');
        },
      );
      expect(page.items, isEmpty);
      expect(requests, [null, 'c1', 'c2']);
      expect(page.nextCursor, 'c3');
    });
  });
}
