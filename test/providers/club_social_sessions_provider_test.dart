import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';

class MockSocialSessionRepository implements ISocialSessionRepository {
  int listByCommunityCallCount = 0;
  String? lastStatusRequested;
  int? lastLimitRequested;
  List<SocialSessionModel> returnedSessions = [];

  @override
  Future<SocialSessionListResponse> listByCommunity({
    required String communityId,
    String? status,
    String? sport,
    String? search,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
  }) async {
    listByCommunityCallCount++;
    lastStatusRequested = status;
    lastLimitRequested = limit;
    return SocialSessionListResponse(
      items: returnedSessions,
      page: page,
      limit: limit,
      total: returnedSessions.length,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ClubSocialSessionsNotifier & Auto-Close Integration Tests', () {
    late MockSocialSessionRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockSocialSessionRepository();
      container = ProviderContainer(
        overrides: [
          socialSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('listByCommunity is called with OPEN,FULL,COMPLETED and limit 50', () async {
      mockRepo.returnedSessions = [
        SocialSessionModel(
          id: 'session-1',
          hostUserId: 'user-1',
          title: 'Pickleball Giao lưu',
          playFormat: 'Giao hữu',
          startAt: DateTime.now().subtract(const Duration(hours: 3)),
          venueName: 'Sân SB',
          venueAddress: '123 Đường 1',
          sport: 'pickleball',
          sportName: 'Pickleball',
          status: 'COMPLETED', // Backend auto-closed expired session
        ),
        SocialSessionModel(
          id: 'session-2',
          hostUserId: 'user-2',
          title: 'Pickleball Chiều',
          playFormat: 'Giao hữu',
          startAt: DateTime.now().add(const Duration(hours: 2)),
          venueName: 'Sân SB',
          venueAddress: '123 Đường 1',
          sport: 'pickleball',
          sportName: 'Pickleball',
          status: 'OPEN',
        ),
      ];

      final sessions = await container.read(
        clubSocialSessionsProvider('club-123').future,
      );

      expect(mockRepo.listByCommunityCallCount, 1);
      expect(mockRepo.lastStatusRequested, 'OPEN,FULL,COMPLETED');
      expect(mockRepo.lastLimitRequested, 50);
      expect(sessions.length, 2);
      expect(sessions[0].status, 'COMPLETED');
      expect(sessions[1].status, 'OPEN');
    });

    test('isStale is false immediately after fetch', () async {
      mockRepo.returnedSessions = [];
      await container.read(clubSocialSessionsProvider('club-123').future);
      final notifier = container.read(
        clubSocialSessionsProvider('club-123').notifier,
      );

      expect(notifier.isStale, isFalse);
    });

    test('refresh re-fetches sessions and updates state', () async {
      mockRepo.returnedSessions = [
        SocialSessionModel(
          id: 'session-1',
          hostUserId: 'user-1',
          title: 'Pickleball 1',
          playFormat: 'Giao hữu',
          startAt: DateTime.now(),
          venueName: 'Sân SB',
          venueAddress: '123 Đường 1',
          sport: 'pickleball',
          sportName: 'Pickleball',
          status: 'OPEN',
        ),
      ];

      final initial = await container.read(
        clubSocialSessionsProvider('club-123').future,
      );
      expect(initial.length, 1);
      expect(mockRepo.listByCommunityCallCount, 1);

      // Simulate backend auto-closing the session on next fetch
      mockRepo.returnedSessions = [
        SocialSessionModel(
          id: 'session-1',
          hostUserId: 'user-1',
          title: 'Pickleball 1',
          playFormat: 'Giao hữu',
          startAt: DateTime.now(),
          venueName: 'Sân SB',
          venueAddress: '123 Đường 1',
          sport: 'pickleball',
          sportName: 'Pickleball',
          status: 'COMPLETED',
        ),
      ];

      await container.read(
        clubSocialSessionsProvider('club-123').notifier,
      ).refresh();

      final updated = container.read(
        clubSocialSessionsProvider('club-123'),
      ).asData?.value;
      expect(mockRepo.listByCommunityCallCount, 2);
      expect(updated?.length, 1);
      expect(updated?.first.status, 'COMPLETED');
    });

    test('aliases clubSocialSessionsQueryProvider points to same notifier', () async {
      mockRepo.returnedSessions = [];
      final res1 = await container.read(
        clubSocialSessionsQueryProvider('club-abc').future,
      );
      final res2 = await container.read(
        clubSocialSessionsProvider('club-abc').future,
      );

      expect(res1, equals(res2));
    });
  });
}
