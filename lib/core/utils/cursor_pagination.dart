/// A cursor is the only proof that a following page can be requested.
/// `hasMore` alone is not actionable and may be stale/incomplete metadata.
bool canAdvanceCursorPage({
  required bool isLoading,
  required bool hasCachedPage,
  required String? nextCursor,
}) {
  if (isLoading) return false;
  return hasCachedPage || nextCursor?.trim().isNotEmpty == true;
}

/// One cursor page of items as returned by the API, plus the cursor for the
/// page after it.
typedef CursorPage<T> = ({List<T> items, String? nextCursor});

/// Walks cursor pages from [startCursor] until one page has an item that
/// [accept] keeps.
///
/// Returns the kept items of that page and the cursor for the page after it.
/// Returns no cursor only when the API has no further page. When a cursor
/// repeats, it is returned without being requested again, so the caller can
/// page to it manually. The same holds for the cursor still set after
/// [maxExtraPages] extra requests.
Future<CursorPage<T>> fetchCursorPageWhere<T>({
  required Future<CursorPage<T>> Function(String? cursor) fetchPage,
  required bool Function(T item) accept,
  required String? startCursor,
  int maxExtraPages = 5,
}) async {
  assert(maxExtraPages >= 0);
  final requested = <String>{?startCursor};
  var cursor = startCursor;
  var extraRequests = 0;
  while (true) {
    final page = await fetchPage(cursor);
    final kept = page.items.where(accept).toList(growable: false);
    final continuation = _continuationCursor(page.nextCursor, cursor);
    if (kept.isNotEmpty || continuation == null) {
      return (items: kept, nextCursor: continuation);
    }
    if (!requested.add(continuation)) {
      return (items: kept, nextCursor: continuation);
    }
    if (extraRequests >= maxExtraPages) {
      return (items: kept, nextCursor: continuation);
    }
    extraRequests++;
    cursor = continuation;
  }
}

String? _continuationCursor(String? nextCursor, String? requestCursor) {
  final trimmed = nextCursor?.trim();
  if (trimmed == null || trimmed.isEmpty || trimmed == requestCursor) {
    return null;
  }
  return trimmed;
}
