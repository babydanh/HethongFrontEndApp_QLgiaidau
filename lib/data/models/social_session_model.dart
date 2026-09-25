import 'package:intl/intl.dart';

class SocialCommunitySummary {
  final String id;
  final String name;
  final String? logoUrl;

  const SocialCommunitySummary({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  factory SocialCommunitySummary.fromJson(Map<String, dynamic> json) {
    return SocialCommunitySummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (logoUrl != null) 'logoUrl': logoUrl,
  };
}

class SocialParticipantModel {
  final String id;
  final String? sessionId;
  final String userId;
  final String? guestName;
  final String role; // 'HOST' | 'PLAYER'
  final String status; // 'JOINED'
  final String paymentStatus; // 'UNPAID' | 'PAID' | 'PENDING'
  final int ticketCount;
  final DateTime joinedAt;
  final String? fullName;
  final String? avatarUrl;
  final String? customSkillLevel;

  SocialParticipantModel({
    required this.id,
    this.sessionId,
    String? userId,
    this.guestName,
    String role = 'PLAYER',
    this.status = 'JOINED',
    this.paymentStatus = 'UNPAID',
    this.ticketCount = 1,
    required this.joinedAt,
    String? fullName,
    String? name,
    this.avatarUrl,
    String? customSkillLevel,
    String? skillLevel,
    bool? isHost,
    String? initials,
  }) : userId = userId ?? id,
       role = (isHost == true) ? 'HOST' : role,
       fullName = fullName ?? name,
       customSkillLevel = customSkillLevel ?? skillLevel;

  /// Khách ngoài CLB: không có tài khoản, userId NULL ở backend,
  /// chỉ có guestName để đánh dấu slot đã có người.
  bool get isGuest => guestName?.trim().isNotEmpty == true;

  String get name {
    if (fullName?.trim().isNotEmpty == true) return fullName!.trim();
    if (guestName?.trim().isNotEmpty == true) return guestName!.trim();
    return 'Thành viên';
  }

  /// Identifier dùng cho API xóa / cập nhật thanh toán:
  /// user thật -> userId, guest -> id của row participant
  /// (backend hỗ trợ cả 2 vì guest có userId NULL).
  String get apiIdentifier => isGuest ? id : userId;

  bool get isHost => role.toUpperCase() == 'HOST';

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'TV';
    final parts = trimmed.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      final first = parts.first.substring(0, 1).toUpperCase();
      final last = parts.last.substring(0, 1).toUpperCase();
      return '$first$last';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }

  String get skillLevel => customSkillLevel ?? 'Tất cả trình độ';

  factory SocialParticipantModel.fromJson(Map<String, dynamic> json) {
    final rawJoinedAt = json['joinedAt'] ?? json['createdAt'];
    DateTime parsedJoinedAt;
    if (rawJoinedAt is String) {
      parsedJoinedAt = DateTime.tryParse(rawJoinedAt) ?? DateTime.now();
    } else if (rawJoinedAt is DateTime) {
      parsedJoinedAt = rawJoinedAt;
    } else {
      parsedJoinedAt = DateTime.now();
    }

    final participantRole =
        json['role']?.toString().toUpperCase() ??
        (json['isHost'] == true ? 'HOST' : 'PLAYER');

    final rawUserId = json['userId']?.toString();
    final rawGuestName =
        json['guestName']?.toString() ?? json['guest_name']?.toString();
    return SocialParticipantModel(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString(),
      userId: (rawUserId != null && rawUserId.isNotEmpty)
          ? rawUserId
          : json['id']?.toString() ?? '',
      guestName: (rawGuestName != null && rawGuestName.trim().isNotEmpty)
          ? rawGuestName.trim()
          : null,
      role: participantRole,
      status: json['status']?.toString() ?? 'JOINED',
      paymentStatus:
          json['paymentStatus']?.toString().toUpperCase() ?? 'UNPAID',
      ticketCount: (json['ticketCount'] is num)
          ? (json['ticketCount'] as num).toInt()
          : 1,
      joinedAt: parsedJoinedAt,
      fullName: json['fullName']?.toString() ?? json['name']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      customSkillLevel: json['skillLevel']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (sessionId != null) 'sessionId': sessionId,
    'userId': userId,
    if (guestName != null) 'guestName': guestName,
    'role': role,
    'status': status,
    'paymentStatus': paymentStatus,
    'ticketCount': ticketCount,
    'joinedAt': joinedAt.toIso8601String(),
    if (fullName != null) 'fullName': fullName,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };

  SocialParticipantModel copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? guestName,
    String? role,
    String? status,
    String? paymentStatus,
    int? ticketCount,
    DateTime? joinedAt,
    String? fullName,
    String? avatarUrl,
    String? customSkillLevel,
  }) {
    return SocialParticipantModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      guestName: guestName ?? this.guestName,
      role: role ?? this.role,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      ticketCount: ticketCount ?? this.ticketCount,
      joinedAt: joinedAt ?? this.joinedAt,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      customSkillLevel: customSkillLevel ?? this.customSkillLevel,
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

  factory SocialMatchModel.fromJson(Map<String, dynamic> json) {
    return SocialMatchModel(
      id: json['id']?.toString() ?? '',
      courtName: json['courtName']?.toString() ?? 'Sân 1',
      matchType: json['matchType']?.toString() ?? 'Đánh đôi',
      team1Name: json['team1Name']?.toString() ?? '',
      team2Name: json['team2Name']?.toString() ?? '',
      score: json['score']?.toString(),
      status: json['status']?.toString() ?? 'Chưa diễn ra',
      timeDisplay: json['timeDisplay']?.toString(),
    );
  }
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

  factory SocialChatMessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    final rawTime = json['time'] ?? json['createdAt'] ?? json['timestamp'];
    if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else if (rawTime is DateTime) {
      parsedTime = rawTime;
    } else {
      parsedTime = DateTime.now();
    }

    final sName =
        json['senderName']?.toString() ??
        json['sender']?['fullName']?.toString() ??
        'Thành viên';
    String initials = json['senderInitials']?.toString() ?? '';
    if (initials.isEmpty) {
      final parts = sName.trim().split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        initials = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        initials = parts.first.substring(0, 1).toUpperCase();
      } else {
        initials = 'TV';
      }
    }

    return SocialChatMessageModel(
      id: json['id']?.toString() ?? '',
      senderName: sName,
      senderAvatar:
          json['senderAvatar']?.toString() ??
          json['sender']?['avatarUrl']?.toString(),
      senderInitials: initials,
      message: json['message']?.toString() ?? json['content']?.toString() ?? '',
      time: parsedTime,
      isHost: json['isHost'] == true,
      isMe: json['isMe'] == true,
      isSystem: json['isSystem'] == true,
      sharedSession: json['sharedSession'] is Map
          ? SocialSessionModel.fromJson(
              (json['sharedSession'] as Map).map(
                (k, v) => MapEntry(k.toString(), v),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderName': senderName,
    if (senderAvatar != null) 'senderAvatar': senderAvatar,
    'senderInitials': senderInitials,
    'message': message,
    'time': time.toIso8601String(),
    'isHost': isHost,
    'isMe': isMe,
    'isSystem': isSystem,
    if (sharedSession != null) 'sharedSession': sharedSession!.toJson(),
  };
}

class SocialPaymentModel {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final int ticketCount;
  final int totalAmount;
  final String status; // 'PAID', 'PENDING', 'UNPAID'
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
  final String? shortCode;
  final String? communityId;
  final String hostUserId;
  final String? categoryId;
  final String title;
  final String? description;
  final String playFormat;
  final String? playDate;
  final DateTime startAt;
  final int durationMinutes;
  final String venueName;
  final String venueAddress;
  final int maxSlots;
  final int currentSlots;
  final int feePerSlot;
  final String levelRequirement;
  final String visibility;
  final String? contactPhone;
  final String? zaloGroupUrl;
  final String status; // 'OPEN', 'FULL', 'COMPLETED', 'CANCELLED'
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final SocialCommunitySummary? community;
  final String sport;
  final String sportName;
  final List<SocialParticipantModel> participants;
  final bool isJoined;
  final bool isHost;
  final String? chatRoomId;

  // Local phase 2 fields (matches & chat)
  final List<SocialMatchModel> matches;
  final List<SocialChatMessageModel> chatMessages;

  const SocialSessionModel({
    required this.id,
    this.shortCode,
    this.communityId,
    required this.hostUserId,
    this.categoryId,
    required this.title,
    this.description,
    required this.playFormat,
    this.playDate,
    required this.startAt,
    this.durationMinutes = 120,
    required this.venueName,
    required this.venueAddress,
    this.maxSlots = 6,
    this.currentSlots = 1,
    this.feePerSlot = 0,
    this.levelRequirement = 'ALL',
    this.visibility = 'PUBLIC',
    this.contactPhone,
    this.zaloGroupUrl,
    this.status = 'OPEN',
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.community,
    required this.sport,
    required this.sportName,
    this.participants = const [],
    this.isJoined = false,
    this.isHost = false,
    this.chatRoomId,
    this.matches = const [],
    this.chatMessages = const [],
  });

  // Backward compatibility getters for UI
  String? get clubId => communityId ?? community?.id;
  String get shareUrl => shortCode != null && shortCode!.isNotEmpty
      ? 'https://sporto.asia/s/$shortCode'
      : 'https://sporto.asia/social/$id';
  String get creatorId => hostUserId;
  double get distanceKm => 0.0; // Ignored as per user instruction
  String get hostClubName =>
      community?.name ??
      (participants.where((p) => p.isHost).firstOrNull?.name ?? 'Host');
  String? get hostClubAvatar => community?.logoUrl;
  String get hostFrequency => metadata['frequency']?.toString() ?? 'Hàng tuần';
  String? get hostPhone => contactPhone;
  String? get hostZalo => contactPhone;
  int get currentParticipants => currentSlots;
  int get maxParticipants => maxSlots;
  int get pricePerSlot => feePerSlot;
  int get durationHours => (durationMinutes / 60).round();
  String get skillLevel =>
      levelRequirement == 'ALL' ? 'Tất cả trình độ' : levelRequirement;
  String get notes => description ?? '';
  DateTime get dateTime => startAt;

  String get timeSlot => DateFormat('HH:mm').format(startAt.toLocal());

  String get dateDisplay {
    final local = startAt.toLocal();
    return '${DateFormat('HH:mm').format(local)} ${_weekdayDisplay(local)}, ${local.day}/${local.month}';
  }

  String get fullDateTimeDisplay {
    final local = startAt.toLocal();
    return '${_fullWeekdayDisplay(local)} ${DateFormat('dd/MM/yyyy').format(local)} vào lúc ${DateFormat('HH:mm').format(local)}';
  }

  String get dayOfWeek => _shortDayOfWeek(startAt.toLocal());
  int get dayOfMonth => startAt.toLocal().day;

  List<SocialPaymentModel> get payments {
    return participants.map((p) {
      return SocialPaymentModel(
        id: 'pay_${p.id}',
        participantId: p.apiIdentifier,
        participantName: p.name,
        participantAvatar: p.avatarUrl,
        ticketCount: p.ticketCount,
        totalAmount: p.ticketCount * feePerSlot,
        status: p.paymentStatus,
        paymentMethod: 'TRANSFER',
        paidAt: p.joinedAt,
      );
    }).toList();
  }

  static String _weekdayDisplay(DateTime dt) {
    const days = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[dt.weekday];
  }

  static String _shortDayOfWeek(DateTime dt) {
    const days = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[dt.weekday];
  }

  static String _fullWeekdayDisplay(DateTime dt) {
    const days = [
      '',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
      'Chủ nhật',
    ];
    return days[dt.weekday];
  }

  factory SocialSessionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedStartAt;
    final rawStartAt = json['startAt'] ?? json['dateTime'];
    if (rawStartAt is String) {
      parsedStartAt = DateTime.tryParse(rawStartAt) ?? DateTime.now();
    } else if (rawStartAt is DateTime) {
      parsedStartAt = rawStartAt;
    } else {
      parsedStartAt = DateTime.now();
    }

    final rawParticipants = json['participants'];
    final participantsList = (rawParticipants is List)
        ? rawParticipants
              .whereType<Map>()
              .map(
                (p) => SocialParticipantModel.fromJson(
                  p.map((k, v) => MapEntry(k.toString(), v)),
                ),
              )
              .toList()
        : <SocialParticipantModel>[];

    final rawCommunity = json['community'];
    final communityObj = (rawCommunity is Map)
        ? SocialCommunitySummary.fromJson(
            rawCommunity.map((k, v) => MapEntry(k.toString(), v)),
          )
        : null;

    final sportKey = json['sport']?.toString() ?? 'pickleball';
    String sportName = json['sportName']?.toString() ?? '';
    if (sportName.isEmpty) {
      switch (sportKey.toLowerCase()) {
        case 'pickleball':
          sportName = 'Pickleball';
          break;
        case 'tennis':
          sportName = 'Tennis';
          break;
        case 'badminton':
          sportName = 'Cầu lông';
          break;
        default:
          sportName = sportKey;
      }
    }

    final durationMin = (json['durationMinutes'] is num)
        ? (json['durationMinutes'] as num).toInt()
        : ((json['durationHours'] is num)
              ? ((json['durationHours'] as num) * 60).toInt()
              : 120);

    return SocialSessionModel(
      id: json['id']?.toString() ?? '',
      shortCode: json['shortCode']?.toString(),
      communityId:
          json['communityId']?.toString() ??
          (rawCommunity is Map ? rawCommunity['id']?.toString() : null),
      hostUserId:
          json['hostUserId']?.toString() ?? json['creatorId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? json['notes']?.toString(),
      playFormat: json['playFormat']?.toString() ?? 'Giao hữu',
      playDate: json['playDate']?.toString(),
      startAt: parsedStartAt,
      durationMinutes: durationMin,
      venueName: json['venueName']?.toString() ?? '',
      venueAddress: json['venueAddress']?.toString() ?? '',
      maxSlots: (json['maxSlots'] is num)
          ? (json['maxSlots'] as num).toInt()
          : ((json['maxParticipants'] is num)
                ? (json['maxParticipants'] as num).toInt()
                : 6),
      currentSlots: (json['currentSlots'] is num)
          ? (json['currentSlots'] as num).toInt()
          : ((json['currentParticipants'] is num)
                ? (json['currentParticipants'] as num).toInt()
                : participantsList.length),
      feePerSlot: (json['feePerSlot'] is num)
          ? (json['feePerSlot'] as num).toInt()
          : ((json['pricePerSlot'] is num)
                ? (json['pricePerSlot'] as num).toInt()
                : 0),
      levelRequirement:
          json['levelRequirement']?.toString() ??
          json['skillLevel']?.toString() ??
          'ALL',
      visibility: json['visibility']?.toString() ?? 'PUBLIC',
      contactPhone:
          json['contactPhone']?.toString() ??
          json['hostPhone']?.toString() ??
          json['hostZalo']?.toString(),
      zaloGroupUrl: json['zaloGroupUrl']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
      metadata: (json['metadata'] is Map)
          ? (json['metadata'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : const {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
      community: communityObj,
      sport: sportKey,
      sportName: sportName,
      participants: participantsList,
      isJoined: json['isJoined'] == true,
      isHost: json['isHost'] == true,
      chatRoomId: json['chatRoomId']?.toString(),
      chatMessages: (json['chatMessages'] ?? json['messages']) is List
          ? ((json['chatMessages'] ?? json['messages']) as List)
                .whereType<Map>()
                .map(
                  (m) => SocialChatMessageModel.fromJson(
                    m.map((k, v) => MapEntry(k.toString(), v)),
                  ),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (shortCode != null) 'shortCode': shortCode,
    if (communityId != null) 'communityId': communityId,
    'hostUserId': hostUserId,
    if (categoryId != null) 'categoryId': categoryId,
    'title': title,
    if (description != null) 'description': description,
    'playFormat': playFormat,
    if (playDate != null) 'playDate': playDate,
    'startAt': startAt.toIso8601String(),
    'durationMinutes': durationMinutes,
    'venueName': venueName,
    'venueAddress': venueAddress,
    'maxSlots': maxSlots,
    'currentSlots': currentSlots,
    'feePerSlot': feePerSlot,
    'levelRequirement': levelRequirement,
    'visibility': visibility,
    if (contactPhone != null) 'contactPhone': contactPhone,
    if (zaloGroupUrl != null) 'zaloGroupUrl': zaloGroupUrl,
    'status': status,
    'metadata': metadata,
    if (community != null) 'community': community!.toJson(),
    'sport': sport,
    'sportName': sportName,
    'participants': participants.map((p) => p.toJson()).toList(),
    'isJoined': isJoined,
    'isHost': isHost,
    if (chatRoomId != null) 'chatRoomId': chatRoomId,
    if (chatMessages.isNotEmpty)
      'chatMessages': chatMessages.map((m) => m.toJson()).toList(),
  };

  SocialSessionModel copyWith({
    String? id,
    String? shortCode,
    String? communityId,
    String? hostUserId,
    String? categoryId,
    String? title,
    String? description,
    String? playFormat,
    String? playDate,
    DateTime? startAt,
    int? durationMinutes,
    String? venueName,
    String? venueAddress,
    int? maxSlots,
    int? currentSlots,
    int? feePerSlot,
    String? levelRequirement,
    String? visibility,
    String? contactPhone,
    String? zaloGroupUrl,
    String? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SocialCommunitySummary? community,
    String? sport,
    String? sportName,
    List<SocialParticipantModel>? participants,
    bool? isJoined,
    bool? isHost,
    String? chatRoomId,
    List<SocialMatchModel>? matches,
    List<SocialChatMessageModel>? chatMessages,
  }) {
    return SocialSessionModel(
      id: id ?? this.id,
      shortCode: shortCode ?? this.shortCode,
      communityId: communityId ?? this.communityId,
      hostUserId: hostUserId ?? this.hostUserId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      playFormat: playFormat ?? this.playFormat,
      playDate: playDate ?? this.playDate,
      startAt: startAt ?? this.startAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      maxSlots: maxSlots ?? this.maxSlots,
      currentSlots: currentSlots ?? this.currentSlots,
      feePerSlot: feePerSlot ?? this.feePerSlot,
      levelRequirement: levelRequirement ?? this.levelRequirement,
      visibility: visibility ?? this.visibility,
      contactPhone: contactPhone ?? this.contactPhone,
      zaloGroupUrl: zaloGroupUrl ?? this.zaloGroupUrl,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      community: community ?? this.community,
      sport: sport ?? this.sport,
      sportName: sportName ?? this.sportName,
      participants: participants ?? this.participants,
      isJoined: isJoined ?? this.isJoined,
      isHost: isHost ?? this.isHost,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      matches: matches ?? this.matches,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}

class CreateSocialSessionRequest {
  final String sport;
  final String title;
  final String? description;
  final String playFormat;
  final DateTime startAt;
  final int durationMinutes;
  final String venueName;
  final String venueAddress;
  final int maxSlots;
  final int feePerSlot;
  final String levelRequirement;
  final String visibility;
  final String? contactPhone;
  final String? zaloGroupUrl;
  final String? communityId;

  const CreateSocialSessionRequest({
    required this.sport,
    required this.title,
    this.description,
    this.playFormat = 'Giao hữu',
    required this.startAt,
    this.durationMinutes = 120,
    required this.venueName,
    required this.venueAddress,
    this.maxSlots = 6,
    this.feePerSlot = 0,
    this.levelRequirement = 'ALL',
    this.visibility = 'PUBLIC',
    this.contactPhone,
    this.zaloGroupUrl,
    this.communityId,
  });

  Map<String, dynamic> toJson() {
    final offset = startAt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final formattedIsoWithOffset =
        '${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(startAt)}$sign$hours:$minutes';

    return {
      'sport': sport,
      'title': title,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'playFormat': playFormat,
      'startAt': formattedIsoWithOffset,
      'durationMinutes': durationMinutes,
      'venueName': venueName,
      'venueAddress': venueAddress,
      'maxSlots': maxSlots,
      'feePerSlot': feePerSlot,
      'levelRequirement': levelRequirement,
      'visibility': visibility,
      if (contactPhone != null && contactPhone!.isNotEmpty)
        'contactPhone': contactPhone,
      if (zaloGroupUrl != null && zaloGroupUrl!.isNotEmpty)
        'zaloGroupUrl': zaloGroupUrl,
      if (communityId != null && communityId!.isNotEmpty)
        'communityId': communityId,
    };
  }
}

class JoinSessionResponse {
  final bool ok;
  final SocialParticipantModel? participant;
  final int currentSlots;
  final String status;

  const JoinSessionResponse({
    required this.ok,
    this.participant,
    required this.currentSlots,
    required this.status,
  });

  factory JoinSessionResponse.fromJson(Map<String, dynamic> json) {
    final rawParticipant = json['participant'];
    return JoinSessionResponse(
      ok: json['ok'] == true,
      participant: rawParticipant is Map
          ? SocialParticipantModel.fromJson(
              rawParticipant.map((k, v) => MapEntry(k.toString(), v)),
            )
          : null,
      currentSlots: (json['currentSlots'] is num)
          ? (json['currentSlots'] as num).toInt()
          : 1,
      status: json['status']?.toString() ?? 'OPEN',
    );
  }
}

class SocialSessionListResponse {
  final List<SocialSessionModel> items;
  final int page;
  final int limit;
  final int total;

  const SocialSessionListResponse({
    required this.items,
    this.page = 1,
    this.limit = 20,
    this.total = 0,
  });

  factory SocialSessionListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['data'];
    final itemsList = (rawItems is List)
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => SocialSessionModel.fromJson(
                  item.map((k, v) => MapEntry(k.toString(), v)),
                ),
              )
              .toList()
        : <SocialSessionModel>[];

    final meta = json['meta'] is Map ? json['meta'] as Map : {};
    return SocialSessionListResponse(
      items: itemsList,
      page: (meta['page'] is num) ? (meta['page'] as num).toInt() : 1,
      limit: (meta['limit'] is num) ? (meta['limit'] as num).toInt() : 20,
      total: (meta['total'] is num)
          ? (meta['total'] as num).toInt()
          : itemsList.length,
    );
  }
}

class BatchAddParticipantsResponse {
  final List<SocialParticipantModel> added;
  final List<String> skipped;
  final int currentSlots;
  final String status;

  const BatchAddParticipantsResponse({
    this.added = const [],
    this.skipped = const [],
    required this.currentSlots,
    required this.status,
  });

  factory BatchAddParticipantsResponse.fromJson(Map<String, dynamic> json) {
    final rawAdded = json['added'];
    final addedList = (rawAdded is List)
        ? rawAdded
              .whereType<Map>()
              .map(
                (p) => SocialParticipantModel.fromJson(
                  p.map((k, v) => MapEntry(k.toString(), v)),
                ),
              )
              .toList()
        : <SocialParticipantModel>[];
    final rawSkipped = json['skipped'];
    final skippedList = (rawSkipped is List)
        ? rawSkipped.map((e) => e.toString()).toList()
        : <String>[];
    return BatchAddParticipantsResponse(
      added: addedList,
      skipped: skippedList,
      currentSlots: (json['currentSlots'] is num)
          ? (json['currentSlots'] as num).toInt()
          : addedList.length,
      status: json['status']?.toString() ?? 'OPEN',
    );
  }
}
