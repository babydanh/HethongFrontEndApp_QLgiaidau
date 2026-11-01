/// Messages from one author closer together than this share a single header.
const chatGroupWindow = Duration(minutes: 5);

/// Whether a message continues the group of the next-older message, so its
/// avatar and name can be skipped. System rows and unknown authors never group.
bool isChatContinuation({
  required String userId,
  required DateTime at,
  String? olderUserId,
  DateTime? olderAt,
}) {
  if (userId.isEmpty || olderUserId == null || olderAt == null) return false;
  if (userId != olderUserId) return false;
  return at.difference(olderAt).abs() <= chatGroupWindow;
}
