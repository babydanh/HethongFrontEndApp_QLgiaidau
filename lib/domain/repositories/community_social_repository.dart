import 'package:app_quanly_giaidau/data/models/community_social_models.dart';

/// Hợp đồng dữ liệu cho khu sinh hoạt CLB.
/// UI chỉ phụ thuộc vào contract này, không biết Dio hay format backend.
abstract class ICommunitySocialRepository {
  Future<CommunityFeedPage> getFeed(
    String communityId, {
    String? cursor,
    int limit = 12,
  });

  Future<CommunityPostModel> createPost(
    String communityId, {
    required String text,
    List<String> mediaUrls = const [],
    List<String> topicTags = const [],
    List<String> mentions = const [],
    Map<String, dynamic>? poll,
  });

  Future<CommunityCommentPage> getComments(
    String communityId,
    String postId, {
    String? cursor,
    int limit = 20,
  });

  Future<CommunityCommentModel> createComment(
    String communityId,
    String postId, {
    required String body,
    String? parentId,
  });

  Future<void> deletePost(String communityId, String postId);

  Future<List<CommunityPostModel>> getPendingPosts(String communityId);

  Future<void> moderatePost(
    String communityId,
    String postId, {
    required String status,
  });

  Future<void> reportPost(
    String communityId,
    String postId, {
    required String reason,
    String? details,
  });

  Future<void> deleteComment(String communityId, String commentId);

  Future<CommunityPollModel> votePoll(
    String communityId,
    String pollId,
    String optionId,
  );

  Future<CommunityPollModel> addPollOption(
    String communityId,
    String pollId,
    String optionText,
  );

  Future<void> reactToPost(
    String communityId,
    String postId, {
    required String reaction,
  });

  Future<String> uploadImage(List<int> bytes, String fileName);
}
