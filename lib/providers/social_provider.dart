import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';

final _socialClubLog = AppLogger('ClubSocialSessions');

class SocialFilterState {
  final DateTime selectedDate;
  final String selectedSport;
  final String searchQuery;
  final Set<String> collapsedTimeSlots;

  SocialFilterState({
    DateTime? selectedDate,
    this.selectedSport = 'all',
    this.searchQuery = '',
    this.collapsedTimeSlots = const {},
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
  }) {
    return SocialFilterState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSport: selectedSport ?? this.selectedSport,
      searchQuery: searchQuery ?? this.searchQuery,
      collapsedTimeSlots: collapsedTimeSlots ?? this.collapsedTimeSlots,
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

class SocialSessionsNotifier
    extends AsyncNotifier<List<SocialSessionModel>> {
  @override
  Future<List<SocialSessionModel>> build() async {
    final filter = ref.watch(socialFilterProvider);
    final repo = ref.watch(socialSessionRepositoryProvider);

    final dateStr = DateFormat('yyyy-MM-dd').format(filter.selectedDate);
    final response = await repo.listByDate(
      date: dateStr,
      sport: filter.selectedSport == 'all' ? null : filter.selectedSport,
      search: filter.searchQuery.trim().isNotEmpty
          ? filter.searchQuery.trim()
          : null,
    );
    return response.items;
  }

  Future<void> refresh() async {
    final filter = ref.read(socialFilterProvider);
    final repo = ref.read(socialSessionRepositoryProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(filter.selectedDate);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await repo.listByDate(
        date: dateStr,
        sport: filter.selectedSport == 'all' ? null : filter.selectedSport,
        search: filter.searchQuery.trim().isNotEmpty
            ? filter.searchQuery.trim()
            : null,
      );
      return response.items;
    });
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

  Future<void> togglePaymentStatus(
    String sessionId,
    String userId,
    String newStatus,
  ) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    await repo.updatePaymentStatus(
      sessionId,
      userId,
      paymentStatus: newStatus,
    );
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

class SocialSessionDetailNotifier
    extends AsyncNotifier<SocialSessionModel> {
  final String sessionId;
  SocialSessionDetailNotifier(this.sessionId);

  @override
  Future<SocialSessionModel> build() async {
    final repo = ref.watch(socialSessionRepositoryProvider);
    return await repo.getDetail(sessionId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(socialSessionRepositoryProvider).getDetail(sessionId);
    });
  }

  Future<JoinSessionResponse> join({int ticketCount = 1}) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    final res = await repo.join(sessionId, ticketCount: ticketCount);
    await refresh();
    ref.read(socialSessionsProvider.notifier).refresh();
    return res;
  }

  Future<void> updatePaymentStatus(String userId, String paymentStatus) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    await repo.updatePaymentStatus(sessionId, userId, paymentStatus: paymentStatus);
    await refresh();
    ref.read(socialSessionsProvider.notifier).refresh();
  }

  Future<void> removeParticipant(String userId) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    await repo.removeParticipant(sessionId, userId);
    await refresh();
    ref.read(socialSessionsProvider.notifier).refresh();
  }

  Future<void> addParticipant({
    required String userId,
    int ticketCount = 1,
  }) async {
    final repo = ref.read(socialSessionRepositoryProvider);
    await repo.addParticipant(sessionId, userId: userId, ticketCount: ticketCount);
    await refresh();
    ref.read(socialSessionsProvider.notifier).refresh();
  }

  Future<void> cancelSession() async {
    final repo = ref.read(socialSessionRepositoryProvider);
    await repo.cancel(sessionId);
    await refresh();
    ref.read(socialSessionsProvider.notifier).refresh();
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
      current.copyWith(
        chatMessages: [...current.chatMessages, newMessage],
      ),
    );
  }
}

final socialSessionDetailProvider =
    AsyncNotifierProvider.family<
      SocialSessionDetailNotifier,
      SocialSessionModel,
      String
    >(SocialSessionDetailNotifier.new);

final clubSocialSessionsQueryProvider =
    FutureProvider.family<List<SocialSessionModel>, String>(
  (ref, communityId) async {
    final repo = ref.watch(socialSessionRepositoryProvider);
    try {
      // Backend: GET /social-sessions/by-community/:communityId
      // Lấy toàn bộ Social của CLB (không giới hạn theo ngày hôm nay).
      final res = await repo.listByCommunity(
        communityId: communityId,
        status: 'OPEN,FULL,COMPLETED',
        limit: 20,
      );
      return res.items;
    } catch (error, stack) {
      // Đừng nuốt lỗi: log để debug vì sao tab "Mở" trống
      // trong khi tab "Đã xong" vẫn có dữ liệu.
      _socialClubLog.error(
        'listByCommunity failed for $communityId',
        error,
        stack,
      );
      rethrow;
    }
  },
);

final clubSocialSessionsProvider =
    Provider.family<List<SocialSessionModel>, String>((ref, communityId) {
  return ref.watch(clubSocialSessionsQueryProvider(communityId)).asData?.value ??
      const <SocialSessionModel>[];
});

final communitySocialSessionsQueryProvider =
    FutureProvider.family<List<SocialSessionModel>, String>(
  (ref, communityId) async {
    final repo = ref.watch(socialSessionRepositoryProvider);
    try {
      final res = await repo.listByCommunity(
        communityId: communityId,
        status: 'OPEN,FULL,COMPLETED',
        limit: 20,
      );
      return res.items;
    } catch (error, stack) {
      _socialClubLog.error(
        'listByCommunity failed for $communityId',
        error,
        stack,
      );
      rethrow;
    }
  },
);

final filteredSocialSessionsProvider =
    Provider<AsyncValue<List<SocialSessionModel>>>((ref) {
  return ref.watch(socialSessionsProvider);
});
