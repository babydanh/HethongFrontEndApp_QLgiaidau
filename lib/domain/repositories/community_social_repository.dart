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
  });

  Future<List<CommunityCommentModel>> getComments(
    String communityId,
    String postId, {
    int limit = 3,
  });

  Future<CommunityCommentModel> createComment(
    String communityId,
    String postId, {
    required String body,
  });

  Future<void> reactToPost(
    String communityId,
    String postId, {
    required String reaction,
  });

  Future<String> uploadImage(List<int> bytes, String fileName);
}
