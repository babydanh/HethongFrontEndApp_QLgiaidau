import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_social_repository.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class ApiCommunitySocialRepository implements ICommunitySocialRepository {
  static const _log = AppLogger('ApiCommunitySocialRepository');
  final DioClient _dioClient;

  ApiCommunitySocialRepository(this._dioClient);

  @override
  Future<CommunityFeedPage> getFeed(
    String communityId, {
    String? cursor,
    int limit = 12,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/communities/$communityId/posts',
        queryParameters: {
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
        options: Options(extra: {'noCache': true}),
      );
      final body = _asMap(response.data);
      final rawData = body['data'];
      final list = rawData is List ? rawData : const <Object?>[];
      final meta = _asMap(body['meta']);
      final items = list
          .map(_asMap)
          .map(CommunityPostModel.fromJson)
          .where((post) => post.id.isNotEmpty)
          .toList(growable: false);
      return CommunityFeedPage(
        items: items,
        nextCursor: meta['nextCursor']?.toString(),
        hasMore: meta['hasMore'] == true,
      );
    } catch (error, stack) {
      _log.error('Không thể tải feed CLB: $communityId', error, stack);
      rethrow;
    }
  }

  @override
  Future<CommunityPostModel> createPost(
    String communityId, {
    required String text,
    List<String> mediaUrls = const [],
    List<String> topicTags = const [],
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/communities/$communityId/posts',
        data: {
          'body': text,
          if (mediaUrls.isNotEmpty) 'mediaUrls': mediaUrls,
          if (topicTags.isNotEmpty) 'topics': topicTags,
        },
        options: Options(headers: {'Idempotency-Key': Uuid().v4()}),
      );
      final body = _asMap(response.data);
      final data = _asMap(body['data'] ?? body);
      final post = CommunityPostModel.fromJson(data);
      if (post.id.isEmpty) throw const FormatException('Bài đăng không hợp lệ');
      return post;
    } catch (error, stack) {
      _log.error('Không thể tạo bài đăng CLB: $communityId', error, stack);
      rethrow;
    }
  }

  @override
  Future<List<CommunityCommentModel>> getComments(
    String communityId,
    String postId, {
    int limit = 3,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/communities/$communityId/posts/$postId/comments',
        queryParameters: {'limit': limit},
      );
      final body = _asMap(response.data);
      final raw = body['data'];
      if (raw is! List) return const [];
      return raw
          .map(_asMap)
          .map(CommunityCommentModel.fromJson)
          .where((comment) => comment.id.isNotEmpty)
          .toList(growable: false);
    } catch (error, stack) {
      _log.error('Không thể tải bình luận bài viết: $postId', error, stack);
      rethrow;
    }
  }

  @override
  Future<CommunityCommentModel> createComment(
    String communityId,
    String postId, {
    required String body,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/communities/$communityId/posts/$postId/comments',
        data: {'body': body.trim()},
      );
      final payload = _asMap(response.data);
      final comment = CommunityCommentModel.fromJson(_asMap(payload['data'] ?? payload));
      if (comment.id.isEmpty) throw const FormatException('Bình luận không hợp lệ');
      return comment;
    } catch (error, stack) {
      _log.error('Không thể gửi bình luận bài viết: $postId', error, stack);
      rethrow;
    }
  }

  @override
  Future<void> reactToPost(
    String communityId,
    String postId, {
    required String reaction,
  }) async {
    try {
      await _dioClient.dio.post(
        '/communities/$communityId/posts/$postId/reaction',
        data: {'reactionType': reaction},
      );
    } catch (error, stack) {
      _log.error('Không thể cập nhật reaction bài viết: $postId', error, stack);
      rethrow;
    }
  }

  @override
  Future<String> uploadImage(List<int> bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dioClient.dio.post(
        '/upload/image',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      final payload = _asMap(response.data);
      final url = payload['url']?.toString() ?? _asMap(payload['data'])['url']?.toString();
      if (url == null || url.isEmpty) throw const FormatException('Ảnh tải lên không hợp lệ');
      return url;
    } catch (error, stack) {
      _log.error('Không thể tải ảnh bài viết lên', error, stack);
      rethrow;
    }
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}
