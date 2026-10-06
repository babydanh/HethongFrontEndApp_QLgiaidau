import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';

final _socialClubLog = AppLogger('ClubSocialSessions');

/// Bán kính mặc định khi bật "Gần bạn" (km). Backend cho tối đa 50.
const defaultNearbyRadiusKm = 10.0;

/// Các mốc bán kính cho chips filter.
const nearbyRadiusOptions = <double>[3, 5, 10, 20];

class SocialFilterState {
  final DateTime selectedDate;
  final String selectedSport;
  final String searchQuery;
  final Set<String> collapsedTimeSlots;

  /// Bật lọc/sắp xếp "Gần bạn" (cần quyền vị trí + venue đã ghim tọa độ).
  final bool nearbyOnly;

  /// Bán kính lọc khi [nearbyOnly] = true (km).
  final double radiusKm;

  SocialFilterState({
    DateTime? selectedDate,
    this.selectedSport = 'all',
    this.searchQuery = '',
    this.collapsedTimeSlots = const {},
    this.nearbyOnly = false,
    this.radiusKm = defaultNearbyRadiusKm,
  }) : selectedDate = _normalizeDate(selectedDate ?? DateTime.now());

  static DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool isSameDate(DateTime? other) {
    if (other == null) return false;
    return selectedDate.year == other.year &&
        selectedDate.month == other.month &&
        selectedDate.day == other.day;
  }

  SocialFilterState copyWith({
    DateTime? selectedDate,
    String? selectedSport,
    String? searchQuery,
    Set<String>? collapsedTimeSlots,
    bool? nearbyOnly,
    double? radiusKm,
  }) {
    return SocialFilterState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSport: selectedSport ?? this.selectedSport,
      searchQuery: searchQuery ?? this.searchQuery,
      collapsedTimeSlots: collapsedTimeSlots ?? this.collapsedTimeSlots,
      nearbyOnly: nearbyOnly ?? this.nearbyOnly,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }
}

class SocialFilterNotifier extends Notifier<SocialFilterState> {
  @override
  SocialFilterState build() => SocialFilterState();

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setSport(String sport) {
    state = state.copyWith(selectedSport: sport);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Bật/tắt chế độ "Gần bạn" (sort DISTANCE + lọc theo bán kính).
  void setNearbyOnly(bool value) {
    state = state.copyWith(nearbyOnly: value);
  }

  void setRadiusKm(double value) {
    state = state.copyWith(radiusKm: value);
  }

  void toggleTimeSlotCollapse(String timeSlot) {
    final current = Set<String>.from(state.collapsedTimeSlots);
    if (current.contains(timeSlot)) {
      current.remove(timeSlot);
    } else {
      current.add(timeSlot);
    }
    state = state.copyWith(collapsedTimeSlots: current);
  }

  void reset() {
    state = SocialFilterState();
  }
}

final socialFilterProvider =
    NotifierProvider<SocialFilterNotifier, SocialFilterState>(
      SocialFilterNotifier.new,
    );

class SocialSessionsNotifier extends AsyncNotifier<List<SocialSessionModel>> {
  int _nearbyPage = 1;
  bool _nearbyHasMore = false;
  bool _loadingMore = false;
  int _nearbyGeneration = 0;
  String? _loadMoreError;

  bool get hasMoreNearby => _nearbyHasMore;
  bool get isLoadingMore => _loadingMore;
  String? get loadMoreError => _loadMoreError;

  List<SocialSessionModel> _applyNearbyFilters(
    List<SocialSessionModel> items,
    SocialFilterState filter,
  ) {
    var visible = items;
    if (filter.selectedSport != 'all') {
      visible = visible.where((s) => s.sport == filter.selectedSport).toList();
    }
    final query = filter.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      visible = visible
          .where(
            (s) =>
                s.title.toLowerCase().contains(query) ||
                s.venueName.toLowerCase().contains(query) ||
                s.venueAddress.toLowerCase().contains(query),
          )
          .toList();
    }
    return visible;
  }

  /// Tọa độ gửi kèm query — chỉ khi user bật "Gần bạn" VÀ đã có vị trí.
  /// Thiếu vị trí (từ chối quyền/tắt GPS) thì fallback danh sách theo giờ.
  ({double? lat, double? lng, String? sortBy}) _geoParams(
    SocialFilterState filter,
    UserLocationState location,
  ) {
    if (filter.nearbyOnly && location.hasPosition) {
      return (
        lat: location.latitude,
        lng: location.longitude,
        sortBy: 'DISTANCE',
      );
    }
    return (lat: null, lng: null, sortBy: null);
  }

  @override
  Future<List<SocialSessionModel>> build() async {
    final auth = ref.watch(authProvider);
    if (auth.status == AuthStatus.validating) return const [];
    final filter = ref.watch(socialFilterProvider);
    final location = ref.watch(userLocationProvider);
    final repo = ref.watch(socialSessionRepositoryProvider);
    final generation = ++_nearbyGeneration;
    _nearbyPage = 1;
    _nearbyHasMore = false;
    _loadingMore = false;
    _loadMoreError = null;

    if (filter.nearbyOnly && location.hasPosition) {
      final nearby = await repo.listNearby(
        lat: location.latitude!,
        lng: location.longitude!,
        radiusKm: filter.radiusKm,
        page: 1,
        limit: 20,
      );
      if (generation != _nearbyGeneration) return const [];
      _nearbyPage = nearby.page;
      _nearbyHasMore = nearby.hasMore;
      return _applyNearbyFilters(nearby.items, filter);
    }

    // "Gần bạn" đang bật nhưng chưa có toạ độ: trả list rỗng thay vì rơi
    // xuống listByDate — nếu không chip vẫn ghi "Gần bạn" nhưng danh sách
    // hiển thị mọi kèo, tức là bộ lọc không hề có tác dụng.
    if (filter.nearbyOnly) return const [];

    final dateStr = DateFormat('yyyy-MM-dd').format(filter.selectedDate);
    final geo = _geoParams(filter, location);
    final response = await repo.listByDate(
      date: dateStr,
      sport: filter.selectedSport == 'all' ? null : filter.selectedSport,
      search: filter.searchQuery.trim().isNotEmpty
          ? filter.searchQuery.trim()
          : null,
      lat: geo.lat,
      lng: geo.lng,
      radiusKm: geo.lat != null ? filter.radiusKm : null,
      sortBy: geo.sortBy,
    );
    return response.items;
  }

  Future<void> loadMoreNearby() async {
    if (_loadingMore || !_nearbyHasMore) return;
    final filter = ref.read(socialFilterProvider);
    final location = ref.read(userLocationProvider);
    if (!filter.nearbyOnly || !location.hasPosition) return;
    final auth = ref.read(authProvider);
    final generation = _nearbyGeneration;
    _loadingMore = true;
    _loadMoreError = null;
    state = AsyncData(state.asData?.value ?? const <SocialSessionModel>[]);
    try {
      final response = await ref
          .read(socialSessionRepositoryProvider)
          .listNearby(
            lat: location.latitude!,
            lng: location.longitude!,
            radiusKm: filter.radiusKm,
            page: _nearbyPage + 1,
            limit: 20,
          );
      if (!ref.mounted ||
          !identical(auth, ref.read(authProvider)) ||
          generation != _nearbyGeneration) {
        return;
      }
      final existing = state.asData?.value ?? const <SocialSessionModel>[];
      final ids = existing.map((item) => item.id).toSet();
      final next = _applyNearbyFilters(
        response.items,
        filter,
      ).where((item) => ids.add(item.id));
      _nearbyPage = response.page;
      _nearbyHasMore = response.hasMore;
      state = AsyncData([...existing, ...next]);
    } catch (_) {
      if (ref.mounted &&
          identical(auth, ref.read(authProvider)) &&
          generation == _nearbyGeneration) {
        _loadMoreError = 'Không thể tải thêm. Hãy thử lại.';
      }
    } finally {
      if (ref.mounted &&
          identical(auth, ref.read(authProvider)) &&
          generation == _nearbyGeneration) {
        _loadingMore = false;
        state = AsyncData(state.asData?.value ?? const <SocialSessionModel>[]);
      }
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await AsyncValue.guard(() => future);
  }

  Future<JoinSessionResponse> joinSession({
    required String sessionId,
    int ticketCount = 1,
  }) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    final result = await repo.join(sessionId, ticketCount: ticketCount);
    await refresh();
    return result;
  }

  Future<void> addParticipantToSlot({
    required String sessionId,
    required String userId,
    int ticketCount = 1,
  }) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    await repo.addParticipant(
      sessionId,
      userId: userId,
      ticketCount: ticketCount,
    );
    await refresh();
  }

  Future<BatchAddParticipantsResponse> addParticipantsBatchToSlot({
    required String sessionId,
    required List<String> userIds,
    int ticketCount = 1,
  }) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    final res = await repo.addParticipantsBatch(
      sessionId,
      userIds: userIds,
      ticketCount: ticketCount,
    );
    await refresh();
    return res;
  }

  Future<void> togglePaymentStatus(
    String sessionId,
    String userId,
    String newStatus,
  ) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    await repo.updatePaymentStatus(sessionId, userId, paymentStatus: newStatus);
    await refresh();
  }

  Future<void> cancelSession(String sessionId) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    await repo.cancel(sessionId);
    await refresh();
  }

  void addChatMessage(
    String sessionId,
    String message, {
    String senderName = 'Tôi',
  }) {
    final currentList = state.asData?.value;
    if (currentList == null) return;
    final index = currentList.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final session = currentList[index];
    final newMessage = SocialChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      senderInitials: senderName.isNotEmpty
          ? senderName.trim().split(' ').last.substring(0, 1).toUpperCase()
          : 'ME',
      message: message,
      time: DateTime.now(),
      isMe: true,
    );

    final updated = session.copyWith(
      chatMessages: [...session.chatMessages, newMessage],
    );
    final list = List<SocialSessionModel>.from(currentList);
    list[index] = updated;
    state = AsyncData(list);
  }

  void addSharedSessionMessage(
    String sessionId,
    SocialSessionModel sharedSession, {
    String senderName = 'Sơn Bảo',
  }) {
    final currentList = state.asData?.value;
    if (currentList == null) return;
    final index = currentList.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final session = currentList[index];
    final newCardMessage = SocialChatMessageModel(
      id: 'msg_card_${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      senderInitials: senderName.isNotEmpty
          ? senderName.trim().split(' ').last.substring(0, 1).toUpperCase()
          : 'SB',
      message: sharedSession.title,
      time: DateTime.now(),
      isHost: true,
      isMe: true,
      sharedSession: sharedSession,
    );

    final updated = session.copyWith(
      chatMessages: [...session.chatMessages, newCardMessage],
    );
    final list = List<SocialSessionModel>.from(currentList);
    list[index] = updated;
    state = AsyncData(list);
  }

  void addSession(SocialSessionModel session) {
    final currentList = state.asData?.value ?? [];
    state = AsyncData([session, ...currentList]);
  }
}

final socialSessionsProvider =
    AsyncNotifierProvider<SocialSessionsNotifier, List<SocialSessionModel>>(
      SocialSessionsNotifier.new,
    );

class SocialSessionDetailNotifier extends AsyncNotifier<SocialSessionModel> {
  final String sessionId;
  SocialSessionDetailNotifier(this.sessionId);

  @override
  Future<SocialSessionModel> build() async {
    final auth = ref.watch(authProvider);
    if (auth.status == AuthStatus.validating) {
      throw StateError('Session changing');
    }
    ref.watch(socialSessionRepositoryProvider);
    _mutating = false;
    _refreshGeneration++;
    return _fetch();
  }

  int _refreshGeneration = 0;
  bool _mutating = false;

  void _checkSession(AuthState auth) {
    if (!ref.mounted || !identical(auth, ref.read(authProvider))) {
      throw StateError('Session changed');
    }
  }

  Future<void> refresh() async {
    final auth = ref.read(authProvider);
    final generation = ++_refreshGeneration;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(_fetch);
    if (!ref.mounted || !identical(auth, ref.read(authProvider))) return;
    if (generation == _refreshGeneration) state = result;
  }

  Future<JoinSessionResponse> join({int ticketCount = 1}) => _mutate(
    () => ref
        .read(socialSessionRepositoryProvider)
        .join(sessionId, ticketCount: ticketCount),
  );

  Future<void> requestJoin({
    int ticketCount = 1,
    String? userName,
    String? userAvatar,
  }) => _mutate(
    () => ref
        .read(socialSessionRepositoryProvider)
        .requestJoin(sessionId, ticketCount: ticketCount),
  );

  Future<void> approveParticipant(SocialParticipantModel participant) =>
      _mutate(
        () => ref
            .read(socialSessionRepositoryProvider)
            .approveJoinRequest(sessionId, participant.id),
        hostOnly: true,
      );

  Future<void> rejectParticipant(SocialParticipantModel participant) => _mutate(
    () => ref
        .read(socialSessionRepositoryProvider)
        .rejectJoinRequest(sessionId, participant.id),
    hostOnly: true,
  );

  Future<SocialSessionModel> _fetch() async {
    final repo = ref.read(socialSessionRepositoryProvider);
    final auth = ref.read(authProvider);
    final detail = await repo.getDetail(sessionId);
    _checkSession(auth);
    final requests = detail.isHost
        ? await repo.listJoinRequests(sessionId)
        : <SocialParticipantModel>[];
    _checkSession(auth);
    return detail.copyWith(requestedParticipants: requests);
  }

  Future<T> _mutate<T>(
    Future<T> Function() action, {
    bool hostOnly = false,
  }) async {
    if (_mutating ||
        state.isLoading ||
        state.asData == null ||
        !ref.read(authProvider).isAuthenticated ||
        (hostOnly && !state.requireValue.isHost)) {
      throw StateError('Social session is not ready for this action');
    }
    final auth = ref.read(authProvider);
    _mutating = true;
    try {
      late final T result;
      try {
        result = await action();
      } catch (_) {
        _checkSession(auth);
        await refresh();
        _checkSession(auth);
        ref.invalidate(socialSessionsProvider);
        ref.invalidate(clubSocialSessionsProvider);
        rethrow;
      }
      _checkSession(auth);
      await refresh();
      _checkSession(auth);
      ref.invalidate(socialSessionsProvider);
      ref.invalidate(clubSocialSessionsProvider);
      if (state.hasError) {
        throw StateError('Saved, but synchronization failed. Please refresh.');
      }
      return result;
    } finally {
      if (ref.mounted && identical(auth, ref.read(authProvider))) {
        _mutating = false;
      }
    }
  }

  Future<void> updatePaymentStatus(String userId, String paymentStatus) async {
    await _mutate(() async {
      final repo = ref.read(socialSessionRepositoryProvider);
      await repo.updatePaymentStatus(
        sessionId,
        userId,
        paymentStatus: paymentStatus,
      );
    }, hostOnly: true);
  }

  Future<void> removeParticipant(String userId) async {
    await _mutate(() async {
      final repo = ref.read(socialSessionRepositoryProvider);
      await repo.removeParticipant(sessionId, userId);
    }, hostOnly: true);
  }

  Future<void> addParticipant({
    required String userId,
    int ticketCount = 1,
  }) async {
    await _mutate(() async {
      final repo = ref.read(socialSessionRepositoryProvider);
      await repo.addParticipant(
        sessionId,
        userId: userId,
        ticketCount: ticketCount,
      );
    }, hostOnly: true);
  }

  Future<void> addGuestParticipant({
    required String guestName,
    int ticketCount = 1,
  }) async {
    await _mutate(() async {
      final repo = ref.read(socialSessionRepositoryProvider);
      await repo.addGuestParticipant(
        sessionId,
        guestName: guestName,
        ticketCount: ticketCount,
      );
    }, hostOnly: true);
  }

  Future<BatchAddParticipantsResponse> addParticipantsBatch({
    required List<String> userIds,
    int ticketCount = 1,
  }) => _mutate(
    () => ref
        .read(socialSessionRepositoryProvider)
        .addParticipantsBatch(
          sessionId,
          userIds: userIds,
          ticketCount: ticketCount,
        ),
    hostOnly: true,
  );

  Future<void> cancelSession() async {
    await _mutate(() async {
      final repo = ref.read(socialSessionRepositoryProvider);
      await repo.cancel(sessionId);
    }, hostOnly: true);
  }

  void addChatMessage(String message, {String senderName = 'Tôi'}) {
    final current = state.asData?.value;
    if (current == null) return;
    final newMessage = SocialChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      senderInitials: senderName.isNotEmpty
          ? senderName.trim().split(' ').last.substring(0, 1).toUpperCase()
          : 'ME',
      message: message,
      time: DateTime.now(),
      isMe: true,
    );
    state = AsyncData(
      current.copyWith(chatMessages: [...current.chatMessages, newMessage]),
    );
  }
}

final socialSessionDetailProvider =
    AsyncNotifierProvider.family<
      SocialSessionDetailNotifier,
      SocialSessionModel,
      String
    >(SocialSessionDetailNotifier.new);

/// Thời gian TTL tối đa cho cache Social sessions (giây).
/// Sau khoảng này, dữ liệu được coi là stale và tự fetch lại.
const _socialSessionsCacheTtlSeconds = 60;

/// Chu kỳ auto-refresh Social sessions (giây).
/// Khớp với cron `EVERY_5_MINUTES` phía backend để đảm bảo
/// status expired (OPEN → COMPLETED) luôn đồng bộ.
const _socialSessionsAutoRefreshSeconds = 5 * 60;

/// AsyncNotifier quản lý danh sách Social sessions của một CLB.
///
/// Luồng hoạt động theo tài liệu backend:
/// 1. Gọi `GET /social-sessions/by-community/:communityId`
/// 2. Backend tự chạy `closeExpiredSessions(now, communityId)` scoped đúng
///    Club đó **trước khi** query list → response trả về status mới nhất.
/// 3. Client KHÔNG gọi endpoint close riêng.
///
/// Cơ chế refresh:
/// - Auto-refresh mỗi 5 phút (nhịp cron server).
/// - TTL 60s: nếu data cũ hơn 60s khi rebuild, tự fetch lại.
/// - Pull-to-refresh / resume app / chuyển tab → gọi [refresh] thủ công.
class ClubSocialSessionsNotifier
    extends AsyncNotifier<List<SocialSessionModel>> {
  final String communityId;
  ClubSocialSessionsNotifier(this.communityId);

  Timer? _autoRefreshTimer;
  DateTime? _lastFetchTime;

  @override
  Future<List<SocialSessionModel>> build() async {
    final auth = ref.watch(authProvider);
    _autoRefreshTimer?.cancel();
    if (auth.status == AuthStatus.validating) return const [];
    // Hủy timer cũ khi provider rebuild (ví dụ: hot restart).
    _autoRefreshTimer?.cancel();

    // Đăng ký auto-dispose: hủy timer khi provider bị dispose.
    ref.onDispose(() {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
    });

    final items = await _fetchSessions();
    if (!ref.mounted || !identical(auth, ref.read(authProvider))) {
      return const [];
    }

    // Khởi tạo auto-refresh timer sau khi fetch thành công lần đầu.
    _startAutoRefreshTimer();

    return items;
  }

  Future<List<SocialSessionModel>> _fetchSessions() async {
    final repo = ref.read(socialSessionRepositoryProvider);
    try {
      // Backend: GET /social-sessions/by-community/:communityId
      // → auto close expired sessions trước khi query.
      // Default status: OPEN,FULL,COMPLETED (tài liệu §3).
      final res = await repo.listByCommunity(
        communityId: communityId,
        status: 'OPEN,FULL,COMPLETED',
        limit: 50,
      );
      _lastFetchTime = DateTime.now();
      return res.items;
    } catch (error, stack) {
      _socialClubLog.error(
        'listByCommunity failed for $communityId',
        error,
        stack,
      );
      rethrow;
    }
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: _socialSessionsAutoRefreshSeconds),
      (_) => _silentRefresh(),
    );
  }

  /// Refresh im lặng: không set loading state, chỉ cập nhật data.
  /// Dùng cho auto-refresh timer, không gây flicker UI.
  Future<void> _silentRefresh() async {
    final auth = ref.read(authProvider);
    try {
      final items = await _fetchSessions();
      if (ref.mounted && identical(auth, ref.read(authProvider))) {
        state = AsyncData(items);
      }
    } catch (error) {
      // Silent refresh lỗi: giữ data cũ, chỉ warn log.
      // Cron server sẽ dọn lại, lần refresh tiếp sẽ đúng.
      _socialClubLog.warning('Silent refresh failed for $communityId: $error');
    }
  }

  /// Refresh công khai: hiện loading indicator, dùng cho pull-to-refresh,
  /// resume app, chuyển tab.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await AsyncValue.guard(() => future);
  }

  /// Kiểm tra data đã stale chưa (quá TTL).
  /// Dùng trong widget khi chuyển tab hoặc resume app.
  bool get isStale {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!).inSeconds >
        _socialSessionsCacheTtlSeconds;
  }
}

final clubSocialSessionsProvider =
    AsyncNotifierProvider.family<
      ClubSocialSessionsNotifier,
      List<SocialSessionModel>,
      String
    >(ClubSocialSessionsNotifier.new);

/// Aliases tương thích ngược: cùng trỏ tới [clubSocialSessionsProvider]
/// để dùng chung cơ chế auto-close, auto-refresh 5 phút và TTL 60s.
final clubSocialSessionsQueryProvider = clubSocialSessionsProvider;
final communitySocialSessionsQueryProvider = clubSocialSessionsProvider;

final filteredSocialSessionsProvider =
    Provider<AsyncValue<List<SocialSessionModel>>>((ref) {
      return ref.watch(socialSessionsProvider);
    });
