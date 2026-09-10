import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/community_ranking_model.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/gallery_image_model.dart';
import 'package:app_quanly_giaidau/data/models/community_invite_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_community_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final communityRepositoryProvider = Provider<ICommunityRepository>((ref) {
  return ApiCommunityRepository(ref.watch(dioClientProvider));
});

/// Bộ lọc danh sách CLB (search + tỉnh/thành — server-side như web).
typedef CommunityQuery = ({String? search, String? provinceCode});

/// Provider danh sách CLB có filter + search
final communitiesProvider =
    FutureProvider.family<List<Community>, CommunityQuery>((ref, query) async {
      final repo = ref.watch(communityRepositoryProvider);
      return repo.getCommunities(
        search: query.search,
        provinceCode: query.provinceCode,
        limit: 50,
      );
    });

/// Provider CLB của tôi
final myCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  // Giữ lỗi để UI hiển thị retry/error state; không biến 401/5xx thành
  // danh sách rỗng khiến người dùng tưởng chưa có CLB.
  return repo.getMyCommunities();
});

/// Makes every visible CLB list refetch after a mutation. `communitiesProvider`
/// is a family, so invalidating the family also covers search/province variants.
void invalidateCommunityCollections(dynamic ref) {
  ref.invalidate(communitiesProvider);
  ref.invalidate(myCommunitiesProvider);
}

/// Provider chi tiết 1 CLB
final communityDetailProvider = FutureProvider.family<Community?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getCommunityById(id);
});

/// Provider danh sách thành viên CLB
final communityMembersProvider =
    FutureProvider.family<List<CommunityMemberModel>, String>((
      ref,
      communityId,
    ) async {
      final repo = ref.watch(communityRepositoryProvider);
      return repo.getMembers(communityId);
    });

/// Cursor-backed member feed for the club detail tab. The legacy
/// `communityMembersProvider` remains available for directory/mention flows
/// that explicitly need a bounded snapshot.
final communityMembersFeedProvider =
    NotifierProvider.family<
      CommunityMembersFeedNotifier,
      CommunityMembersFeedState,
      String
    >(CommunityMembersFeedNotifier.new);

class CommunityMembersFeedNotifier extends Notifier<CommunityMembersFeedState> {
  final String communityId;

  CommunityMembersFeedNotifier(this.communityId);

  @override
  CommunityMembersFeedState build() {
    Future<void>.microtask(loadInitial);
    return const CommunityMembersFeedState();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref
          .read(communityRepositoryProvider)
          .getMembersPaged(communityId, status: 'JOINED', limit: 20);
      state = CommunityMembersFeedState(
        members: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách thành viên.',
      );
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (state.isLoading || !state.hasMore || cursor == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref
          .read(communityRepositoryProvider)
          .getMembersPaged(
            communityId,
            cursor: cursor,
            status: 'JOINED',
            limit: 20,
          );
      final knownIds = state.members
          .map((member) => member.id.isNotEmpty ? member.id : member.userId)
          .toSet();
      final fresh = page.items.where((member) {
        final id = member.id.isNotEmpty ? member.id : member.userId;
        return id.isEmpty || knownIds.add(id);
      });
      state = CommunityMembersFeedState(
        members: [...state.members, ...fresh],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải thêm thành viên.',
      );
    }
  }
}

class CommunityMembersFeedState {
  final List<CommunityMemberModel> members;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final String? errorMessage;

  const CommunityMembersFeedState({
    this.members = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoading = false,
    this.errorMessage,
  });

  CommunityMembersFeedState copyWith({
    List<CommunityMemberModel>? members,
    String? nextCursor,
    bool? hasMore,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunityMembersFeedState(
      members: members ?? this.members,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// Tag preset của CLB (tên + màu) — nguồn màu hiển thị tag thành viên
/// mọi nơi có tên + avatar (bài viết, chat, danh sách, profile) như web.
final communityTagPresetsProvider =
    FutureProvider.family<List<CommunityTagPreset>, String>((
      ref,
      communityId,
    ) async {
      return ref.watch(communityRepositoryProvider).getTagPresets(communityId);
    });

/// Map userId → member để tra nhanh tag/role theo tác giả bài viết, tin nhắn.
/// (Web cũng resolve client-side bằng getMembers limit 100 + match theo id.)
final communityMemberDirectoryProvider =
    FutureProvider.family<Map<String, CommunityMemberModel>, String>((
      ref,
      communityId,
    ) async {
      final members = await ref.watch(
        communityMembersProvider(communityId).future,
      );
      return {for (final member in members) member.userId: member};
    });

/// Bounded, server-side member lookup for @mentions.  It deliberately never
/// downloads an entire large club just to populate a composer popup.
typedef CommunityMemberSearch = ({String communityId, String query});

final communityMemberSearchProvider =
    FutureProvider.family<List<CommunityMemberModel>, CommunityMemberSearch>((
      ref,
      request,
    ) async {
      final repo = ref.watch(communityRepositoryProvider);
      return repo.getMembers(
        request.communityId,
        search: request.query,
        limit: 20,
        mentionableOnly: true,
      );
    });

/// Membership of the signed-in user.  Social UI uses this small endpoint for
/// capability checks instead of scanning the member directory.
final myCommunityMembershipProvider =
    FutureProvider.family<CommunityMemberModel?, String>((
      ref,
      communityId,
    ) async {
      final repo = ref.watch(communityRepositoryProvider);
      final membership = await repo.getMyMembership(communityId);
      if (membership == null) return null;
      return CommunityMemberModel(
        id: membership['memberId']?.toString() ?? '',
        userId: membership['userId']?.toString() ?? '',
        communityId: communityId,
        role: membership['role']?.toString() ?? 'MEMBER',
        status: membership['status']?.toString() ?? 'JOINED',
        joinedAt: membership['joinedAt']?.toString() ?? '',
      );
    });

/// Provider danh sách giải đấu trong CLB
final communityTournamentsProvider = FutureProvider.autoDispose
    .family<List<CommunityTournamentModel>, String>((ref, communityId) async {
      final repo = ref.watch(communityRepositoryProvider);
      try {
        final tournaments = await repo
            .getTournaments(communityId)
            .timeout(const Duration(seconds: 10));
        // Keep the card list defensive while backend instances/cache converge:
        // PENDING_DELETE is hidden by the detail endpoint for non-owners.
        return tournaments
            .where((tournament) {
              final status = tournament.status.trim().toUpperCase();
              return status != 'PENDING_DELETE';
            })
            .toList(growable: false);
      } catch (e) {
        return const <CommunityTournamentModel>[];
      }
    });

/// Provider gallery ảnh CLB
final communityGalleryProvider = FutureProvider.autoDispose
    .family<List<GalleryImageModel>, String>((ref, communityId) async {
      final repo = ref.watch(communityRepositoryProvider);
      try {
        return await repo
            .getGallery(communityId)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        return const <GalleryImageModel>[];
      }
    });

/// Provider danh sách yêu cầu tham gia CLB (OWNER/ADMIN thấy).
final joinRequestsProvider =
    FutureProvider.family<List<CommunityMemberModel>, String>((
      ref,
      communityId,
    ) async {
      final repo = ref.watch(communityRepositoryProvider);
      return repo.getJoinRequests(communityId);
    });

/// Provider danh sách CLB chờ duyệt (Admin).
final pendingCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getPendingCommunities();
});

/// Provider danh sách lời mời CLB của tôi
final myCommunityInvitesProvider = FutureProvider<List<CommunityInviteModel>>((
  ref,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getMyInvites();
});

/// Trạng thái theo dõi CLB của user hiện tại (P2E.2).
final isFollowingProvider = FutureProvider.family<bool, String>((
  ref,
  communityId,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.isFollowing(communityId);
});

/// Trạng thái yêu thích CLB của user hiện tại (P2E.2).
final isFavoritedProvider = FutureProvider.family<bool, String>((
  ref,
  communityId,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.isFavorited(communityId);
});

final communitySocialSettingsProvider =
    FutureProvider.family<CommunitySocialSettings, String>((
      ref,
      communityId,
    ) async {
      return ref
          .watch(communityRepositoryProvider)
          .getSocialSettings(communityId);
    });

/// Provider bảng xếp hạng ELO nội bộ CLB (GET /communities/:id/rankings)
final communityRankingsProvider =
    FutureProvider.family<List<CommunityRankingModel>, String>((
      ref,
      communityId,
    ) async {
      final repo = ref.watch(communityRepositoryProvider);
      return repo.getRankings(communityId, limit: 200);
    });
