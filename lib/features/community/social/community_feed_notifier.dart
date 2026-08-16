import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_community_social_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_social_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final communitySocialRepositoryProvider = Provider<ICommunitySocialRepository>((ref) {
  return ApiCommunitySocialRepository(ref.watch(dioClientProvider));
});

class CommunityFeedNotifier extends Notifier<CommunityFeedState> {
  static const _log = AppLogger('CommunityFeedNotifier');
  final String communityId;

  CommunityFeedNotifier(this.communityId);

  @override
  CommunityFeedState build() => const CommunityFeedState();

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref.read(communitySocialRepositoryProvider).getFeed(communityId);
      state = CommunityFeedState(
        posts: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    } catch (error, stack) {
      _log.error('Không thể tải feed CLB', error, stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chưa thể tải bảng tin. Kiểm tra kết nối rồi thử lại.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.nextCursor == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref.read(communitySocialRepositoryProvider).getFeed(
        communityId,
        cursor: state.nextCursor,
      );
      final knownIds = state.posts.map((post) => post.id).toSet();
      final fresh = page.items.where((post) => !knownIds.contains(post.id));
      state = state.copyWith(
        posts: [...state.posts, ...fresh],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (error, stack) {
      _log.error('Không thể tải thêm bài đăng CLB', error, stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chưa thể tải thêm bài đăng.',
      );
    }
  }

  Future<bool> createPost({
    required String text,
    List<String> mediaUrls = const [],
    List<String> topicTags = const [],
    List<String> mentions = const [],
    Map<String, dynamic>? poll,
  }) async {
    final trimmed = text.trim();
    if ((trimmed.isEmpty && mediaUrls.isEmpty) || state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final post = await ref.read(communitySocialRepositoryProvider).createPost(
        communityId,
        text: trimmed,
        mediaUrls: mediaUrls,
        topicTags: topicTags,
        mentions: mentions,
        poll: poll,
      );
      state = state.copyWith(posts: [post, ...state.posts], isSubmitting: false, clearError: true);
      return true;
    } catch (error, stack) {
      _log.error('Không thể đăng bài CLB', error, stack);
      state = state.copyWith(isSubmitting: false, errorMessage: 'Đăng bài thất bại. Vui lòng thử lại.');
      return false;
    }
  }

  Future<void> reactToPost(String postId, String reaction) async {
    try {
      await ref.read(communitySocialRepositoryProvider).reactToPost(
        communityId,
        postId,
        reaction: reaction,
      );
      await loadInitial();
    } catch (error, stack) {
      _log.error('Không thể reaction bài viết CLB', error, stack);
    }
  }
}

final communityFeedProvider = NotifierProvider.family<CommunityFeedNotifier, CommunityFeedState, String>(
  CommunityFeedNotifier.new,
);

class CommunityFeedState {
  final List<CommunityPostModel> posts;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const CommunityFeedState({
    this.posts = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  CommunityFeedState copyWith({
    List<CommunityPostModel>? posts,
    String? nextCursor,
    bool? hasMore,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
