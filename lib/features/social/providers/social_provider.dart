import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/features/social/data/social_mock_data.dart';
import 'package:app_quanly_giaidau/features/social/models/social_session_model.dart';

class SocialFilterState {
  final int selectedDayOfMonth;
  final String selectedSport;
  final double selectedRadiusKm;
  final String searchQuery;
  final Set<String> collapsedTimeSlots;

  const SocialFilterState({
    this.selectedDayOfMonth = 16,
    this.selectedSport = 'all',
    this.selectedRadiusKm = 20.0,
    this.searchQuery = '',
    this.collapsedTimeSlots = const {},
  });

  SocialFilterState copyWith({
    int? selectedDayOfMonth,
    String? selectedSport,
    double? selectedRadiusKm,
    String? searchQuery,
    Set<String>? collapsedTimeSlots,
  }) {
    return SocialFilterState(
      selectedDayOfMonth: selectedDayOfMonth ?? this.selectedDayOfMonth,
      selectedSport: selectedSport ?? this.selectedSport,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      searchQuery: searchQuery ?? this.searchQuery,
      collapsedTimeSlots: collapsedTimeSlots ?? this.collapsedTimeSlots,
    );
  }
}

class SocialFilterNotifier extends Notifier<SocialFilterState> {
  @override
  SocialFilterState build() => const SocialFilterState();

  void setDayOfMonth(int day) {
    state = state.copyWith(selectedDayOfMonth: day);
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

    final updatedParticipants =
        List<SocialParticipantModel>.from(session.participants)
          ..add(newParticipant);

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

    final updatedParticipants = List<SocialParticipantModel>.from(session.participants)
      ..add(newParticipant);
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

  void addSession(SocialSessionModel session) {
    state = [session, ...state];
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
    return null;
  }
});

final clubSocialSessionsProvider =
    Provider.family<List<SocialSessionModel>, String>((ref, clubId) {
  final allSessions = ref.watch(socialSessionsProvider);
  final matched = allSessions.where((s) => s.clubId == clubId).toList();
  if (matched.isNotEmpty) return matched;

  // Fallback: match by session id 'sb_pickleball_sonbao_17' or return top sessions
  final sbSession = allSessions.where((s) => s.id == 'sb_pickleball_sonbao_17').toList();
  if (sbSession.isNotEmpty) return sbSession;
  return allSessions.take(2).toList();
});

final filteredSocialSessionsProvider = Provider<List<SocialSessionModel>>((ref) {
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
