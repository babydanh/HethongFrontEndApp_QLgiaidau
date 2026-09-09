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
}
