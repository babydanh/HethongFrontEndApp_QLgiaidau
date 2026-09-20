import 'package:app_quanly_giaidau/features/social/models/activity_feed_item.dart';

class ActivityFeedPage {
  final List<ActivityFeedItem> items;
  final String? nextCursor;
  final bool hasMore;

  const ActivityFeedPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });
}

abstract class IActivityFeedRepository {
  Future<ActivityFeedPage> getClubActivityFeed({
    required String date,
    String? type,
    String? region,
    String? cursor,
    int limit = 50,
  });

  Future<ActivityFeedPage> getPersonalPickups({
    required String date,
    String? categoryId,
    String? region,
    String? cursor,
    int limit = 50,
  });

  Future<void> joinPersonalPickup(String id);
  Future<void> leavePersonalPickup(String id);
  Future<void> joinClubSession(String sessionId);
  Future<void> leaveClubSession(String sessionId);
}
