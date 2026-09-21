import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/activity_feed_repository.dart';
import 'package:app_quanly_giaidau/features/social/models/activity_feed_item.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/features/social/data/social_mock_data.dart';
import 'package:app_quanly_giaidau/features/social/models/social_session_model.dart';

String _todayDateKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

class SocialFilterState {
  final int selectedDayOfMonth;
  final String selectedDateKey;
  final String selectedSport;
  final double selectedRadiusKm;
  final String searchQuery;
  final Set<String> collapsedTimeSlots;

  SocialFilterState({
    int? selectedDayOfMonth,
    String? selectedDateKey,
    this.selectedSport = 'all',
    this.selectedRadiusKm = 20.0,
    this.searchQuery = '',
    this.collapsedTimeSlots = const {},
  }) : selectedDayOfMonth = selectedDayOfMonth ?? DateTime.now().day,
       selectedDateKey = selectedDateKey ?? _todayDateKey();

  SocialFilterState copyWith({
    int? selectedDayOfMonth,
    String? selectedDateKey,
    String? selectedSport,
    double? selectedRadiusKm,
    String? searchQuery,
    Set<String>? collapsedTimeSlots,
  }) {
    return SocialFilterState(
      selectedDayOfMonth: selectedDayOfMonth ?? this.selectedDayOfMonth,
      selectedDateKey: selectedDateKey ?? this.selectedDateKey,
      selectedSport: selectedSport ?? this.selectedSport,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      searchQuery: searchQuery ?? this.searchQuery,
      collapsedTimeSlots: collapsedTimeSlots ?? this.collapsedTimeSlots,
    );
  }
}

class SocialFilterNotifier extends Notifier<SocialFilterState> {
  @override
  SocialFilterState build() => SocialFilterState();

  void setDayOfMonth(int day) {
    final current = DateTime.tryParse(state.selectedDateKey) ?? DateTime.now();
    final normalized = DateTime(current.year, current.month, day);
    state = state.copyWith(
      selectedDayOfMonth: day,
      selectedDateKey: DateFormat('yyyy-MM-dd').format(normalized),
    );
  }

  void setDateKey(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    state = state.copyWith(
      selectedDateKey: dateKey,
      selectedDayOfMonth: date?.day ?? state.selectedDayOfMonth,
    );
  }

  void setSport(String sport) {
    state = state.copyWith(selectedSport: sport);
  }

  void setRadiusKm(double km) {
    state = state.copyWith(selectedRadiusKm: km);
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
}

final socialFilterProvider =
    NotifierProvider<SocialFilterNotifier, SocialFilterState>(
      SocialFilterNotifier.new,
    );

class SocialSessionsNotifier extends Notifier<List<SocialSessionModel>> {
  @override
  List<SocialSessionModel> build() => List.of(SocialMockData.sessions);

  bool joinSession({
    required String sessionId,
    required int ticketCount,
    required String userName,
  }) {
    final index = state.indexWhere((s) => s.id == sessionId);
    if (index == -1) return false;

    final session = state[index];
    if (session.currentParticipants + ticketCount > session.maxParticipants) {
      return false;
    }

    final newParticipant = SocialParticipantModel(
      id: 'part_${DateTime.now().millisecondsSinceEpoch}',
      name: userName.isEmpty ? 'Tôi' : userName,
      initials: userName.isNotEmpty
          ? (userName.trim().split(' ').last.substring(0, 1).toUpperCase())
          : 'ME',
      skillLevel: session.skillLevel,
      status: 'Đã thanh toán ($ticketCount vé)',
      joinedAt: DateTime.now(),
    );

    final updatedParticipants = List<SocialParticipantModel>.from(
      session.participants,
    )..add(newParticipant);

    final updatedSession = session.copyWith(
      currentParticipants: session.currentParticipants + ticketCount,
      participants: updatedParticipants,
    );

    final updatedList = List<SocialSessionModel>.from(state);
    updatedList[index] = updatedSession;
    state = updatedList;
    return true;
  }

  void addChatMessage(
    String sessionId,
    String message, {
    String senderName = 'Tôi',
  }) {
    final index = state.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final session = state[index];
    final newMessage = SocialChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      senderInitials: senderName.substring(0, 1).toUpperCase(),
      message: message,
      time: DateTime.now(),
      isMe: true,
    );

    final updatedSession = session.copyWith(
      chatMessages: [...session.chatMessages, newMessage],
    );

    final updatedList = List<SocialSessionModel>.from(state);
    updatedList[index] = updatedSession;
    state = updatedList;
  }

  void addSharedSessionMessage(
    String sessionId,
    SocialSessionModel sharedSession, {
    String senderName = 'Sơn Bảo',
  }) {
    final index = state.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final session = state[index];
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

    final updatedSession = session.copyWith(
      chatMessages: [...session.chatMessages, newCardMessage],
    );

    final updatedList = List<SocialSessionModel>.from(state);
    updatedList[index] = updatedSession;
    state = updatedList;
  }

  void togglePaymentStatus(String sessionId, String paymentId) {
    final index = state.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final session = state[index];
    final updatedPayments = session.payments.map((p) {
      if (p.id == paymentId) {
        final newStatus = p.status == 'PAID' ? 'PENDING' : 'PAID';
        return p.copyWith(
          status: newStatus,
          paidAt: newStatus == 'PAID' ? DateTime.now() : null,
        );
      }
      return p;
    }).toList();

    final updatedSession = session.copyWith(payments: updatedPayments);
    final updatedList = List<SocialSessionModel>.from(state);
    updatedList[index] = updatedSession;
    state = updatedList;
  }

  bool addParticipantToSlot({
    required String sessionId,
    required String participantName,
  }) {
    final index = state.indexWhere((s) => s.id == sessionId);
    if (index == -1) return false;

    final session = state[index];
    if (session.currentParticipants >= session.maxParticipants) return false;

    final partId = 'part_${DateTime.now().millisecondsSinceEpoch}';
    final newParticipant = SocialParticipantModel(
      id: partId,
      name: participantName.isEmpty ? 'Thành viên mới' : participantName,
      initials: participantName.isNotEmpty
          ? participantName.trim().split(' ').last.substring(0, 1).toUpperCase()
          : 'TV',
      skillLevel: session.skillLevel,
      status: 'Xác nhận tham gia',
      joinedAt: DateTime.now(),
    );

    final newPayment = SocialPaymentModel(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      participantId: partId,
      participantName: newParticipant.name,
      ticketCount: 1,
      totalAmount: session.pricePerSlot,
      status: 'PAID',
      paymentMethod: 'CASH',
      paidAt: DateTime.now(),
    );

    final updatedParticipants = List<SocialParticipantModel>.from(
      session.participants,
    )..add(newParticipant);
    final updatedPayments = List<SocialPaymentModel>.from(session.payments)
      ..add(newPayment);

    final updatedSession = session.copyWith(
      currentParticipants: session.currentParticipants + 1,
      participants: updatedParticipants,
      payments: updatedPayments,
    );

    final updatedList = List<SocialSessionModel>.from(state);
    updatedList[index] = updatedSession;
    state = updatedList;
    return true;
  }
}

final socialSessionsProvider =
    NotifierProvider<SocialSessionsNotifier, List<SocialSessionModel>>(
      SocialSessionsNotifier.new,
    );

final socialSessionDetailProvider =
    Provider.family<SocialSessionModel?, String>((ref, sessionId) {
      final list = ref.watch(socialSessionsProvider);
      try {
        return list.firstWhere((s) => s.id == sessionId);
      } catch (_) {
        try {
          return SocialMockData.sessions.firstWhere((s) => s.id == sessionId);
        } catch (_) {
          // Fallback an toàn: nếu session ID bất kỳ không tìm thấy (ví dụ ID ngẫu nhiên hoặc từ backend)
          // fallback về session mock mẫu để không bị crash hay màn hình trống
          if (SocialMockData.sessions.isNotEmpty) {
            final defaultMock = SocialMockData.sessions.first;
            return defaultMock.copyWith(id: sessionId);
          }
          return null;
        }
      }
    });

final clubSocialSessionsProvider =
    Provider.family<List<SocialSessionModel>, String>((ref, clubId) {
      final allSessions = ref.watch(socialSessionsProvider);
      final matched = allSessions.where((s) => s.clubId == clubId).toList();
      if (matched.isNotEmpty) return matched;

      // Fallback: match by session id 'sb_pickleball_sonbao_17' or return top sessions
      final sbSession = allSessions
          .where((s) => s.id == 'sb_pickleball_sonbao_17')
          .toList();
      if (sbSession.isNotEmpty) {
        return sbSession.map((s) => s.copyWith(clubId: clubId)).toList();
      }

      if (allSessions.isNotEmpty) {
        return allSessions.take(2).map((s) => s.copyWith(clubId: clubId)).toList();
      }

      return SocialMockData.sessions.take(2).map((s) => s.copyWith(clubId: clubId)).toList();
    });

final filteredSocialSessionsProvider = Provider<List<SocialSessionModel>>((
  ref,
) {
  final allSessions = ref.watch(socialSessionsProvider);
  final filter = ref.watch(socialFilterProvider);

  return allSessions.where((session) {
    // Filter by day of month
    if (session.dayOfMonth != filter.selectedDayOfMonth) {
      return false;
    }

    // Filter by sport
    if (filter.selectedSport != 'all' &&
        session.sport.toLowerCase() != filter.selectedSport.toLowerCase()) {
      return false;
    }

    // Filter by radius (if selected radius > 0)
    if (filter.selectedRadiusKm > 0 &&
        session.distanceKm > filter.selectedRadiusKm) {
      return false;
    }

    // Filter by search query
    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.trim().toLowerCase();
      final matchTitle = session.title.toLowerCase().contains(q);
      final matchClub = session.hostClubName.toLowerCase().contains(q);
      final matchVenue = session.venueName.toLowerCase().contains(q);
      if (!matchTitle && !matchClub && !matchVenue) {
        return false;
      }
    }

    return true;
  }).toList();
});

final activityFeedProvider =
    AsyncNotifierProvider<ActivityFeedNotifier, List<ActivityFeedItem>>(
      ActivityFeedNotifier.new,
    );

class ActivityFeedNotifier extends AsyncNotifier<List<ActivityFeedItem>> {
  String _dateKey = '';
  final Set<String> _joinedIds = <String>{};

  @override
  Future<List<ActivityFeedItem>> build() async {
    _dateKey = ref.watch(
      socialFilterProvider.select((filter) => filter.selectedDateKey),
    );
    return _load(_dateKey);
  }

  Future<List<ActivityFeedItem>> _load(String date) async {
    final repository = ref.read(activityFeedRepositoryProvider);
    final results = await Future.wait<List<ActivityFeedItem>?>([
      _loadClub(repository, date),
      _loadPersonal(repository, date),
    ]);
    final club = results[0];
    final personal = results[1];

    // Danh sách từ API
    final apiItems = [
      ...?club,
      ...?personal,
    ];

    // Fallback Mock Data: Nếu API rỗng hoặc server chưa có dữ liệu ngày này,
    // tự động chuyển đổi các session từ SocialMockData sang ActivityFeedItem
    final List<ActivityFeedItem> rawItems;
    if (apiItems.isNotEmpty) {
      rawItems = apiItems;
    } else {
      rawItems = _generateMockFeedItems(date);
    }

    final merged =
        rawItems
            .map(
              (item) => item.copyWith(
                isJoined: item.isJoined || _joinedIds.contains(item.id),
              ),
            )
            .toList()
          ..sort((left, right) {
            final leftTime =
                left.startDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            final rightTime =
                right.startDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            final byTime = leftTime.compareTo(rightTime);
            return byTime == 0 ? left.title.compareTo(right.title) : byTime;
          });
    return merged;
  }

  /// Chuyển đổi SocialMockData thành ActivityFeedItem phong phú để hiển thị ngay cả khi offline / server trống
  List<ActivityFeedItem> _generateMockFeedItems(String targetDate) {
    return SocialMockData.sessions.map((session) {
      final startTimeParts = session.timeSlot.split(':');
      final hour = int.tryParse(startTimeParts.first) ?? 14;
      final minute = int.tryParse(startTimeParts.length > 1 ? startTimeParts[1] : '0') ?? 0;

      DateTime startDt;
      final parsedDate = DateTime.tryParse(targetDate);
      if (parsedDate != null) {
        startDt = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
      } else {
        startDt = session.dateTime;
      }
      final endDt = startDt.add(Duration(hours: session.durationHours));

      return ActivityFeedItem(
        id: session.id,
        type: session.clubId != null ? ActivityFeedType.clubRecruiting : ActivityFeedType.personalPickup,
        sport: session.sport,
        sportTier: session.skillLevel,
        playDate: targetDate,
        startDateTime: startDt,
        endDateTime: endDt,
        location: '${session.distanceKm.toStringAsFixed(1)} km · ${session.venueName}',
        title: session.title,
        description: session.descriptionNotes,
        bannerUrl: session.hostClubAvatar,
        club: session.clubId != null
            ? ActivityIdentity(
                id: session.clubId!,
                name: session.hostClubName,
                avatarUrl: session.hostClubAvatar,
                verified: true,
              )
            : null,
        host: ActivityIdentity(
          id: 'host_${session.id}',
          name: session.hostClubName,
          avatarUrl: session.hostClubAvatar,
        ),
        slots: ActivitySlots(
          current: session.currentParticipants,
          max: session.maxParticipants,
          feePerSlot: session.pricePerSlot,
          joinedPlayers: session.participants
              .map((p) => ActivityJoinedPlayer(userId: p.id, name: p.name, avatarUrl: p.avatarUrl))
              .toList(),
        ),
        venue: ActivityVenue(
          name: session.venueName,
          address: session.venueAddress,
        ),
      );
    }).toList();
  }

  Future<List<ActivityFeedItem>?> _loadClub(
    IActivityFeedRepository repository,
    String date,
  ) async {
    try {
      return (await repository.getClubActivityFeed(date: date)).items;
    } catch (_) {
      return null;
    }
  }

  Future<List<ActivityFeedItem>?> _loadPersonal(
    IActivityFeedRepository repository,
    String date,
  ) async {
    try {
      return (await repository.getPersonalPickups(date: date)).items;
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_dateKey));
  }

  Future<void> join(ActivityFeedItem item) async {
    final slots = item.slots;
    if (slots == null || slots.current >= slots.max) {
      throw StateError('Buổi giao lưu đã đủ người hoặc chưa mở slot');
    }
    final repository = ref.read(activityFeedRepositoryProvider);
    if (item.isPersonal) {
      await repository.joinPersonalPickup(item.id);
    } else if (item.clubMatchSessionId != null &&
        item.clubMatchSessionId!.isNotEmpty) {
      await repository.joinClubSession(item.clubMatchSessionId!);
    } else {
      throw StateError('Hoạt động chưa sẵn sàng nhận đăng ký');
    }
    _joinedIds.add(item.id);
    await refresh();
  }

  Future<void> leave(ActivityFeedItem item) async {
    final repository = ref.read(activityFeedRepositoryProvider);
    if (item.isPersonal) {
      await repository.leavePersonalPickup(item.id);
    } else if (item.clubMatchSessionId != null &&
        item.clubMatchSessionId!.isNotEmpty) {
      await repository.leaveClubSession(item.clubMatchSessionId!);
    } else {
      throw StateError('Hoạt động chưa sẵn sàng nhận đăng ký');
    }
    _joinedIds.remove(item.id);
    await refresh();
  }
}
