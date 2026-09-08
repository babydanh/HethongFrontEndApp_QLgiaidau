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
