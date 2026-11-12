import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

SocialSessionModel _session(
  String id, {
  String sport = 'pickleball',
  String title = 'Kèo',
  String venue = 'Sân A',
  String address = '1 Lê Lợi',
  bool isHost = false,
  bool isPending = false,
}) => SocialSessionModel(
  id: id,
  hostUserId: 'host',
  title: title,
  playFormat: 'Giao lưu',
  startAt: DateTime(2026, 6, 1, 10),
  venueName: venue,
  venueAddress: address,
  sport: sport,
  sportName: sport,
  isHost: isHost,
  isPending: isPending,
);

class _AuthFixed extends AuthNotifier {
  _AuthFixed(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class _FixedLocation extends UserLocationNotifier {
  @override
  UserLocationState build() => const UserLocationState(
    status: UserLocationStatus.selected,
    latitude: 10.5,
    longitude: 106.5,
  );
}

/// Ghi lại lời gọi và trả dữ liệu cấu hình sẵn.
class _FakeRepo extends Fake implements ISocialSessionRepository {
  final calls = <String>[];
  List<SocialSessionModel> byDate = [];
  List<SocialSessionModel> nearby = [];
  Map<int, NearbySocialSessionsResponse> nearbyPages = {};
  SocialSessionModel detail = _session('s1');
  List<SocialParticipantModel> requests = [];
  Object? mutationError;
  Object? nearbyError;
  Map<String, Object?> lastListByDate = {};

  @override
  Future<SocialSessionListResponse> listByDate({
    String? date,
    String? sport,
    String? communityId,
    String? search,
    int page = 1,
    int limit = 20,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
  }) async {
    calls.add('listByDate');
    lastListByDate = {
      'date': date,
      'sport': sport,
      'search': search,
      'lat': lat,
      'radiusKm': radiusKm,
      'sortBy': sortBy,
    };
    return SocialSessionListResponse(items: byDate);
  }

  @override
  Future<NearbySocialSessionsResponse> listNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int page = 1,
    int limit = 20,
  }) async {
    calls.add('listNearby:$page');
    if (nearbyError != null && page > 1) throw nearbyError!;
    return nearbyPages[page] ??
        NearbySocialSessionsResponse(items: nearby, page: page, limit: 20);
  }

  @override
  Future<SocialSessionModel> getDetail(String sessionId) async {
    calls.add('getDetail');
    return detail;
  }

  @override
  Future<List<SocialParticipantModel>> listJoinRequests(
    String sessionId,
  ) async {
    calls.add('listJoinRequests');
    return requests;
  }

  Future<void> _mutation(String name) async {
    calls.add(name);
    if (mutationError != null) throw mutationError!;
  }

  @override
  Future<JoinSessionResponse> join(
    String sessionId, {
    int ticketCount = 1,
  }) async {
    await _mutation('join:$ticketCount');
    return const JoinSessionResponse(ok: true, currentSlots: 2, status: 'OPEN');
  }

  @override
  Future<void> requestJoin(String sessionId, {int ticketCount = 1}) =>
      _mutation('requestJoin');

  @override
  Future<void> withdrawJoinRequest(String sessionId) => _mutation('withdraw');

  @override
  Future<void> approveJoinRequest(String sessionId, String participantId) =>
      _mutation('approve:$participantId');

  @override
  Future<void> rejectJoinRequest(String sessionId, String participantId) =>
      _mutation('reject:$participantId');

  @override
  Future<void> addParticipant(
    String sessionId, {
    required String userId,
    int ticketCount = 1,
  }) => _mutation('addParticipant:$userId');

  @override
  Future<void> addGuestParticipant(
    String sessionId, {
    required String guestName,
    int ticketCount = 1,
  }) => _mutation('addGuest:$guestName');

  @override
  Future<BatchAddParticipantsResponse> addParticipantsBatch(
    String sessionId, {
    required List<String> userIds,
    int ticketCount = 1,
  }) async {
    await _mutation('batch:${userIds.length}');
    return const BatchAddParticipantsResponse(currentSlots: 3, status: 'OPEN');
  }

  @override
  Future<void> updatePaymentStatus(
    String sessionId,
    String userId, {
    required String paymentStatus,
  }) => _mutation('pay:$userId:$paymentStatus');

  @override
  Future<void> removeParticipant(String sessionId, String userId) =>
      _mutation('remove:$userId');

  @override
  Future<void> cancel(String sessionId) => _mutation('cancel');

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
    calls.add('listByCommunity');
    if (mutationError != null) throw mutationError!;
    return SocialSessionListResponse(items: byDate);
  }
}

ProviderContainer _container(
  _FakeRepo repo, {
  AuthState auth = const AuthState(status: AuthStatus.authenticated),
  bool withLocation = false,
}) {
  final container = ProviderContainer(
    overrides: [
      socialSessionRepositoryProvider.overrideWithValue(repo),
      authProvider.overrideWith(() => _AuthFixed(auth)),
      if (withLocation) userLocationProvider.overrideWith(_FixedLocation.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('SocialFilterNotifier / SocialFilterState', () {
    test('selected date is normalised to midnight and compared by day', () {
      final filter = SocialFilterState(
        selectedDate: DateTime(2026, 6, 1, 23, 59),
      );

      expect(filter.selectedDate, DateTime(2026, 6, 1));
      expect(filter.isSameDate(DateTime(2026, 6, 1, 3)), isTrue);
      expect(filter.isSameDate(DateTime(2026, 6, 2)), isFalse);
      expect(filter.isSameDate(null), isFalse);
    });

    test('setters change one field and keep the rest; reset restores '
        'defaults', () {
      final container = _container(_FakeRepo());
      final notifier = container.read(socialFilterProvider.notifier);

      notifier
        ..setSport('tennis')
        ..setSearchQuery('xuân')
        ..setNearbyOnly(true)
        ..setRadiusKm(20)
        ..setSelectedDate(DateTime(2026, 7, 4, 9));
      final changed = container.read(socialFilterProvider);

      expect(changed.selectedSport, 'tennis');
      expect(changed.searchQuery, 'xuân');
      expect(changed.nearbyOnly, isTrue);
      expect(changed.radiusKm, 20);
      expect(changed.selectedDate, DateTime(2026, 7, 4));

      notifier.reset();
      final reset = container.read(socialFilterProvider);
      expect(reset.selectedSport, 'all');
      expect(reset.searchQuery, '');
      expect(reset.nearbyOnly, isFalse);
      expect(reset.radiusKm, defaultNearbyRadiusKm);
    });

    test(
      'toggleTimeSlotCollapse adds, removes and never mutates the old set',
      () {
        final container = _container(_FakeRepo());
        final notifier = container.read(socialFilterProvider.notifier);

        notifier.toggleTimeSlotCollapse('08:00');
        final afterAdd = container
            .read(socialFilterProvider)
            .collapsedTimeSlots;
        notifier.toggleTimeSlotCollapse('09:00');
        notifier.toggleTimeSlotCollapse('08:00');
        final afterRemove = container
            .read(socialFilterProvider)
            .collapsedTimeSlots;

        expect(afterAdd, {'08:00'});
        expect(afterRemove, {'09:00'});
      },
    );
  });

  group('SocialSessionsNotifier', () {
    test(
      'lists by the selected date with trimmed search and no geo params',
      () async {
        final repo = _FakeRepo()..byDate = [_session('a')];
        final container = _container(repo);
        container.read(socialFilterProvider.notifier)
          ..setSelectedDate(DateTime(2026, 6, 1))
          ..setSport('tennis')
          ..setSearchQuery('  kèo  ');

        final items = await container.read(socialSessionsProvider.future);

        expect(items.single.id, 'a');
        expect(repo.lastListByDate, {
          'date': '2026-06-01',
          'sport': 'tennis',
          'search': 'kèo',
          'lat': null,
          'radiusKm': null,
          'sortBy': null,
        });
      },
    );

    test('sport "all" and a blank search are not sent', () async {
      final repo = _FakeRepo();
      final container = _container(repo);
      container.read(socialFilterProvider.notifier).setSearchQuery('   ');

      await container.read(socialSessionsProvider.future);

      expect(repo.lastListByDate['sport'], isNull);
      expect(repo.lastListByDate['search'], isNull);
    });

    test(
      'returns nothing while the session is still being validated',
      () async {
        final repo = _FakeRepo()..byDate = [_session('a')];
        final container = _container(
          repo,
          auth: const AuthState(status: AuthStatus.validating),
        );

        expect(await container.read(socialSessionsProvider.future), isEmpty);
        expect(repo.calls, isEmpty);
      },
    );

    test('nearby results are filtered client-side by sport and text', () async {
      final repo = _FakeRepo()
        ..nearby = [
          _session('a', title: 'Giao lưu Quận 1'),
          _session('b', sport: 'tennis', title: 'Quận 1 tennis'),
          _session('c', venue: 'Sân Quận 7', title: 'Khác'),
          _session('d', address: 'Đường quận 1', title: 'Không khớp'),
        ];
      final container = _container(repo, withLocation: true);
      container.read(socialFilterProvider.notifier)
        ..setNearbyOnly(true)
        ..setSport('pickleball')
        ..setSearchQuery(' QUẬN 1 ');

      final items = await container.read(socialSessionsProvider.future);

      expect(items.map((s) => s.id), ['a', 'd']);
    });

    test('loadMoreNearby appends the next page without duplicates and updates '
        'paging', () async {
      final repo = _FakeRepo()
        ..nearbyPages = {
          1: NearbySocialSessionsResponse(
            items: [_session('a')],
            page: 1,
            limit: 1,
            total: 3,
          ),
          2: NearbySocialSessionsResponse(
            items: [_session('a'), _session('b')],
            page: 2,
            limit: 1,
            total: 3,
          ),
        };
      final container = _container(repo, withLocation: true);
      container.read(socialFilterProvider.notifier).setNearbyOnly(true);
      await container.read(socialSessionsProvider.future);
      final notifier = container.read(socialSessionsProvider.notifier);
      expect(notifier.hasMoreNearby, isTrue);

      await notifier.loadMoreNearby();

      expect(
        container.read(socialSessionsProvider).requireValue.map((s) => s.id),
        ['a', 'b'],
      );
      expect(repo.calls, ['listNearby:1', 'listNearby:2']);
      expect(notifier.isLoadingMore, isFalse);
      expect(notifier.loadMoreError, isNull);
      // page 2 * limit 1 < total 3 → still more.
      expect(notifier.hasMoreNearby, isTrue);
    });

    test('loadMoreNearby does nothing without more pages or when nearby is '
        'off', () async {
      final repo = _FakeRepo()..byDate = [_session('a')];
      final container = _container(repo);
      await container.read(socialSessionsProvider.future);

      await container.read(socialSessionsProvider.notifier).loadMoreNearby();

      expect(repo.calls, ['listByDate']);
    });

    test(
      'a failing next page keeps the list and exposes a retry message',
      () async {
        final repo = _FakeRepo()
          ..nearbyError = StateError('boom')
          ..nearbyPages = {
            1: NearbySocialSessionsResponse(
              items: [_session('a')],
              page: 1,
              limit: 1,
              total: 5,
            ),
          };
        final container = _container(repo, withLocation: true);
        container.read(socialFilterProvider.notifier).setNearbyOnly(true);
        await container.read(socialSessionsProvider.future);
        final notifier = container.read(socialSessionsProvider.notifier);

        await notifier.loadMoreNearby();

        expect(
          container.read(socialSessionsProvider).requireValue.map((s) => s.id),
          ['a'],
        );
        expect(notifier.loadMoreError, contains('thử lại'));
        expect(notifier.isLoadingMore, isFalse);
      },
    );

    test('mutations call the repository then refresh the list', () async {
      final repo = _FakeRepo()..byDate = [_session('a')];
      final container = _container(repo);
      await container.read(socialSessionsProvider.future);
      final notifier = container.read(socialSessionsProvider.notifier);

      final joined = await notifier.joinSession(sessionId: 'a', ticketCount: 2);
      await notifier.addParticipantToSlot(sessionId: 'a', userId: 'u1');
      final batch = await notifier.addParticipantsBatchToSlot(
        sessionId: 'a',
        userIds: ['u1', 'u2'],
      );
      await notifier.togglePaymentStatus('a', 'u1', 'PAID');
      await notifier.cancelSession('a');

      expect(joined.ok, isTrue);
      expect(batch.currentSlots, 3);
      expect(repo.calls.where((c) => c != 'listByDate'), [
        'join:2',
        'addParticipant:u1',
        'batch:2',
        'pay:u1:PAID',
        'cancel',
      ]);
      // initial load + one refresh per mutation
      expect(repo.calls.where((c) => c == 'listByDate'), hasLength(6));
    });

    test('a failed mutation does not refresh and surfaces the error', () async {
      final repo = _FakeRepo()
        ..byDate = [_session('a')]
        ..mutationError = StateError('full');
      final container = _container(repo);
      await container.read(socialSessionsProvider.future);

      await expectLater(
        container
            .read(socialSessionsProvider.notifier)
            .joinSession(sessionId: 'a'),
        throwsA(isA<StateError>()),
      );
      expect(repo.calls.where((c) => c == 'listByDate'), hasLength(1));
    });

    test('addChatMessage appends a "me" message with initials from the last '
        'name word', () async {
      final repo = _FakeRepo()..byDate = [_session('a'), _session('b')];
      final container = _container(repo);
      await container.read(socialSessionsProvider.future);
      final notifier = container.read(socialSessionsProvider.notifier);

      notifier.addChatMessage('a', 'Xin chào', senderName: 'Nguyễn Văn bình');
      notifier.addChatMessage('missing', 'bỏ qua');
      notifier.addChatMessage('a', 'lần hai');

      final a = container
          .read(socialSessionsProvider)
          .requireValue
          .firstWhere((s) => s.id == 'a');
      final b = container
          .read(socialSessionsProvider)
          .requireValue
          .firstWhere((s) => s.id == 'b');
      expect(a.chatMessages.map((m) => m.message), ['Xin chào', 'lần hai']);
      expect(a.chatMessages.first.senderInitials, 'B');
      expect(a.chatMessages.first.isMe, isTrue);
      expect(b.chatMessages, isEmpty);
    });

    test(
      'addSharedSessionMessage attaches the card; addSession prepends',
      () async {
        final repo = _FakeRepo()..byDate = [_session('a')];
        final container = _container(repo);
        await container.read(socialSessionsProvider.future);
        final notifier = container.read(socialSessionsProvider.notifier);

        notifier.addSharedSessionMessage(
          'a',
          _session('shared', title: 'Thẻ kèo'),
        );
        notifier.addSharedSessionMessage('missing', _session('x'));
        notifier.addSession(_session('new'));

        final items = container.read(socialSessionsProvider).requireValue;
        expect(items.map((s) => s.id), ['new', 'a']);
        final message = items.last.chatMessages.single;
        expect(message.message, 'Thẻ kèo');
        expect(message.sharedSession?.id, 'shared');
        expect(message.isHost, isTrue);
      },
    );

    test(
      'filteredSocialSessionsProvider mirrors the sessions provider',
      () async {
        final repo = _FakeRepo()..byDate = [_session('a')];
        final container = _container(repo);

        await container.read(socialSessionsProvider.future);

        expect(
          container.read(filteredSocialSessionsProvider).requireValue.single.id,
          'a',
        );
      },
    );
  });

  group('SocialSessionDetailNotifier', () {
    test('a non-host detail loads without fetching join requests', () async {
      final repo = _FakeRepo();
      final container = _container(repo);

      final detail = await container.read(
        socialSessionDetailProvider('s1').future,
      );

      expect(detail.id, 's1');
      expect(repo.calls, ['getDetail']);
    });

    test('a host detail merges the pending join requests', () async {
      final repo = _FakeRepo()
        ..detail = _session('s1', isHost: true)
        ..requests = [
          SocialParticipantModel(
            id: 'r1',
            status: 'REQUESTED',
            joinedAt: DateTime(2026),
          ),
        ];
      final container = _container(repo);

      final detail = await container.read(
        socialSessionDetailProvider('s1').future,
      );

      expect(detail.requestedParticipants.map((p) => p.id), ['r1']);
      expect(repo.calls, ['getDetail', 'listJoinRequests']);
    });

    test(
      'mutations run, refresh the detail and invalidate the lists',
      () async {
        final repo = _FakeRepo();
        final container = _container(repo);
        await container.read(socialSessionDetailProvider('s1').future);
        final notifier = container.read(
          socialSessionDetailProvider('s1').notifier,
        );

        final joined = await notifier.join(ticketCount: 2);
        await notifier.requestJoin();

        expect(joined.currentSlots, 2);
        expect(repo.calls, [
          'getDetail',
          'join:2',
          'getDetail',
          'requestJoin',
          'getDetail',
        ]);
      },
    );

    test('host-only actions are refused for a non-host', () async {
      final repo = _FakeRepo();
      final container = _container(repo);
      await container.read(socialSessionDetailProvider('s1').future);
      final notifier = container.read(
        socialSessionDetailProvider('s1').notifier,
      );

      await expectLater(
        notifier.removeParticipant('u1'),
        throwsA(isA<StateError>()),
      );
      await expectLater(notifier.cancelSession(), throwsA(isA<StateError>()));
      await expectLater(
        notifier.updatePaymentStatus('u1', 'PAID'),
        throwsA(isA<StateError>()),
      );
      expect(repo.calls, ['getDetail']); // nothing reached the repository
    });

    test(
      'a host can manage participants, payments, guests and the session',
      () async {
        final repo = _FakeRepo()..detail = _session('s1', isHost: true);
        final container = _container(repo);
        await container.read(socialSessionDetailProvider('s1').future);
        final notifier = container.read(
          socialSessionDetailProvider('s1').notifier,
        );
        final pending = SocialParticipantModel(
          id: 'p9',
          joinedAt: DateTime(2026),
        );

        await notifier.approveParticipant(pending);
        await notifier.rejectParticipant(pending);
        await notifier.addParticipant(userId: 'u1');
        await notifier.addGuestParticipant(guestName: 'Khách');
        final batch = await notifier.addParticipantsBatch(userIds: ['a', 'b']);
        await notifier.updatePaymentStatus('u1', 'PAID');
        await notifier.removeParticipant('u1');
        await notifier.cancelSession();

        expect(batch.currentSlots, 3);
        expect(
          repo.calls.where(
            (c) => !c.startsWith('getDetail') && c != 'listJoinRequests',
          ),
          [
            'approve:p9',
            'reject:p9',
            'addParticipant:u1',
            'addGuest:Khách',
            'batch:2',
            'pay:u1:PAID',
            'remove:u1',
            'cancel',
          ],
        );
      },
    );

    test(
      'a failed action still re-syncs the detail before rethrowing',
      () async {
        final repo = _FakeRepo()..mutationError = StateError('full');
        final container = _container(repo);
        await container.read(socialSessionDetailProvider('s1').future);
        final notifier = container.read(
          socialSessionDetailProvider('s1').notifier,
        );

        await expectLater(notifier.join(), throwsA(isA<StateError>()));

        expect(repo.calls, ['getDetail', 'join:1', 'getDetail']);
        // The guard is released, so the next action is allowed to run.
        repo.mutationError = null;
        await notifier.join();
        expect(repo.calls.where((c) => c == 'join:1'), hasLength(2));
      },
    );

    test('actions are refused when the user is not authenticated', () async {
      final repo = _FakeRepo();
      final container = _container(
        repo,
        auth: const AuthState(status: AuthStatus.unauthenticated),
      );
      await container.read(socialSessionDetailProvider('s1').future);

      await expectLater(
        container.read(socialSessionDetailProvider('s1').notifier).join(),
        throwsA(isA<StateError>()),
      );
      expect(repo.calls, ['getDetail']);
    });

    test('withdrawJoinRequest needs a pending, non-host viewer', () async {
      final notPending = _FakeRepo();
      final c1 = _container(notPending);
      await c1.read(socialSessionDetailProvider('s1').future);

      expect(
        () => c1
            .read(socialSessionDetailProvider('s1').notifier)
            .withdrawJoinRequest(),
        throwsA(isA<StateError>()),
      );

      final pending = _FakeRepo()..detail = _session('s1', isPending: true);
      final c2 = _container(pending);
      await c2.read(socialSessionDetailProvider('s1').future);
      await c2
          .read(socialSessionDetailProvider('s1').notifier)
          .withdrawJoinRequest();

      expect(pending.calls, contains('withdraw'));
    });

    test(
      'while the session is being validated the detail does not load',
      () async {
        final repo = _FakeRepo();
        final container = _container(
          repo,
          auth: const AuthState(status: AuthStatus.validating),
        );

        await expectLater(
          container.read(socialSessionDetailProvider('s1').future),
          throwsA(isA<StateError>()),
        );
        expect(repo.calls, isEmpty);
      },
    );

    test(
      'addChatMessage appends locally without touching the network',
      () async {
        final repo = _FakeRepo();
        final container = _container(repo);
        await container.read(socialSessionDetailProvider('s1').future);
        final notifier = container.read(
          socialSessionDetailProvider('s1').notifier,
        );

        notifier.addChatMessage('chào', senderName: 'An');

        final detail = container
            .read(socialSessionDetailProvider('s1'))
            .requireValue;
        expect(detail.chatMessages.single.message, 'chào');
        expect(detail.chatMessages.single.senderInitials, 'A');
        expect(repo.calls, ['getDetail']);
      },
    );
  });

  group('ClubSocialSessionsNotifier', () {
    test('loads once, is fresh right after, and a failure surfaces as an '
        'error state', () async {
      final repo = _FakeRepo()..byDate = [_session('a')];
      final container = _container(repo);

      final items = await container.read(
        clubSocialSessionsProvider('c1').future,
      );
      final notifier = container.read(
        clubSocialSessionsProvider('c1').notifier,
      );

      expect(items.single.id, 'a');
      expect(notifier.isStale, isFalse);

      repo.mutationError = StateError('down');
      await notifier.refresh();
      expect(container.read(clubSocialSessionsProvider('c1')).hasError, isTrue);
    });

    test('is stale before the first successful fetch completes', () async {
      final repo = _FakeRepo();
      repo.mutationError = StateError('down');
      final container = _container(repo);
      final notifier = container.read(
        clubSocialSessionsProvider('c1').notifier,
      );

      await container
          .read(clubSocialSessionsProvider('c1').future)
          .then<void>((_) {}, onError: (_) {});

      expect(notifier.isStale, isTrue);
    });
  });
}
