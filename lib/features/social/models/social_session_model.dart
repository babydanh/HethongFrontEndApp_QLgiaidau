class SocialParticipantModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String initials;
  final String skillLevel;
  final bool isHost;
  final String status;
  final DateTime joinedAt;

  const SocialParticipantModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.initials,
    required this.skillLevel,
    this.isHost = false,
    this.status = 'Đã tham gia',
    required this.joinedAt,
  });

  SocialParticipantModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? initials,
    String? skillLevel,
    bool? isHost,
    String? status,
    DateTime? joinedAt,
  }) {
    return SocialParticipantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      initials: initials ?? this.initials,
      skillLevel: skillLevel ?? this.skillLevel,
      isHost: isHost ?? this.isHost,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class SocialMatchModel {
  final String id;
  final String courtName;
  final String matchType;
  final String team1Name;
  final String team2Name;
  final String? score;
  final String status; // 'Chưa diễn ra', 'Đang đấu', 'Đã xong'
  final String? timeDisplay;

  const SocialMatchModel({
    required this.id,
    required this.courtName,
    this.matchType = 'Đánh đôi',
    required this.team1Name,
    required this.team2Name,
    this.score,
    this.status = 'Chưa diễn ra',
    this.timeDisplay,
  });
}

class SocialChatMessageModel {
  final String id;
  final String senderName;
  final String? senderAvatar;
  final String senderInitials;
  final String message;
  final DateTime time;
  final bool isHost;
  final bool isMe;
  final bool isSystem;
  final SocialSessionModel? sharedSession;

  const SocialChatMessageModel({
    required this.id,
    required this.senderName,
    this.senderAvatar,
    required this.senderInitials,
    required this.message,
    required this.time,
    this.isHost = false,
    this.isMe = false,
    this.isSystem = false,
    this.sharedSession,
  });
}

class SocialPaymentModel {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final int ticketCount;
  final int totalAmount;
  final String status; // 'PAID', 'PENDING'
  final String paymentMethod; // 'CASH', 'TRANSFER'
  final DateTime? paidAt;

  const SocialPaymentModel({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.ticketCount = 1,
    required this.totalAmount,
    this.status = 'PAID',
    this.paymentMethod = 'TRANSFER',
    this.paidAt,
  });

  SocialPaymentModel copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantAvatar,
    int? ticketCount,
    int? totalAmount,
    String? status,
    String? paymentMethod,
    DateTime? paidAt,
  }) {
    return SocialPaymentModel(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      ticketCount: ticketCount ?? this.ticketCount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}

class SocialSessionModel {
  final String id;
  final String? clubId;
  final String title;
  final String status; // 'OPEN', 'COMPLETED', 'CANCELLED'
  final String sport; // 'tennis', 'pickleball', 'badminton'
  final String sportName;
  final String hostClubName;
  final String? hostClubAvatar;
  final String hostFrequency; // e.g. 'Mỗi Thứ tư'
  final String? hostPhone;
  final String? hostZalo;
  final String? zaloGroupUrl;
  final String playFormat; // 'Đánh đôi', 'Giao hữu', 'Đánh đơn'
  final String venueName;
  final String venueAddress;
  final double distanceKm;
  final DateTime dateTime;
  final int durationHours;
  final String timeSlot; // '14:45', '14:50'
  final String dateDisplay; // '14:45 Thứ tư, 16/9'
  final String fullDateTimeDisplay; // 'Thứ tư 16/09/2026 vào lúc 14:45'
  final String dayOfWeek; // 'T4', 'T5', etc.
  final int dayOfMonth; // 16, 17, etc.
  final int currentParticipants;
  final int maxParticipants;
  final int pricePerSlot;
  final String skillLevel;
  final String descriptionNotes;
  final List<SocialParticipantModel> participants;
  final List<SocialMatchModel> matches;
  final List<SocialChatMessageModel> chatMessages;
  final List<SocialPaymentModel> payments;

  const SocialSessionModel({
    required this.id,
    this.clubId,
    required this.title,
    this.status = 'OPEN',
    required this.sport,
    required this.sportName,
    required this.hostClubName,
    this.hostClubAvatar,
    this.hostFrequency = 'Mỗi tuần',
    this.hostPhone,
    this.hostZalo,
    this.zaloGroupUrl,
    required this.playFormat,
    required this.venueName,
    required this.venueAddress,
    required this.distanceKm,
    required this.dateTime,
    this.durationHours = 2,
    required this.timeSlot,
    required this.dateDisplay,
    required this.fullDateTimeDisplay,
    required this.dayOfWeek,
    required this.dayOfMonth,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.pricePerSlot,
    required this.skillLevel,
    required this.descriptionNotes,
    this.participants = const [],
    this.matches = const [],
    this.chatMessages = const [],
    this.payments = const [],
  });

  SocialSessionModel copyWith({
    String? id,
    String? clubId,
    String? title,
    String? status,
    String? sport,
    String? sportName,
    String? hostClubName,
    String? hostClubAvatar,
    String? hostFrequency,
    String? hostPhone,
    String? hostZalo,
    String? zaloGroupUrl,
    String? playFormat,
    String? venueName,
    String? venueAddress,
    double? distanceKm,
    DateTime? dateTime,
    int? durationHours,
    String? timeSlot,
    String? dateDisplay,
    String? fullDateTimeDisplay,
    String? dayOfWeek,
    int? dayOfMonth,
    int? currentParticipants,
    int? maxParticipants,
    int? pricePerSlot,
    String? skillLevel,
    String? descriptionNotes,
    List<SocialParticipantModel>? participants,
    List<SocialMatchModel>? matches,
    List<SocialChatMessageModel>? chatMessages,
    List<SocialPaymentModel>? payments,
  }) {
    return SocialSessionModel(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      title: title ?? this.title,
      status: status ?? this.status,
      sport: sport ?? this.sport,
      sportName: sportName ?? this.sportName,
      hostClubName: hostClubName ?? this.hostClubName,
      hostClubAvatar: hostClubAvatar ?? this.hostClubAvatar,
      hostFrequency: hostFrequency ?? this.hostFrequency,
      hostPhone: hostPhone ?? this.hostPhone,
      hostZalo: hostZalo ?? this.hostZalo,
      zaloGroupUrl: zaloGroupUrl ?? this.zaloGroupUrl,
      playFormat: playFormat ?? this.playFormat,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      dateTime: dateTime ?? this.dateTime,
      durationHours: durationHours ?? this.durationHours,
      timeSlot: timeSlot ?? this.timeSlot,
      dateDisplay: dateDisplay ?? this.dateDisplay,
      fullDateTimeDisplay: fullDateTimeDisplay ?? this.fullDateTimeDisplay,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      pricePerSlot: pricePerSlot ?? this.pricePerSlot,
      skillLevel: skillLevel ?? this.skillLevel,
      descriptionNotes: descriptionNotes ?? this.descriptionNotes,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      chatMessages: chatMessages ?? this.chatMessages,
      payments: payments ?? this.payments,
    );
  }
}
