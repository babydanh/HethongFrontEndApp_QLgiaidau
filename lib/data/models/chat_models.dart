import 'dart:ui';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

Map<String, dynamic>? _chatMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

class ChatParticipant {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? role;
  final bool isOnline;
  final DateTime? lastReadAt;

  const ChatParticipant({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.role,
    this.isOnline = false,
    this.lastReadAt,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? 'Thành viên').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      role: json['role']?.toString(),
      isOnline: json['isOnline'] == true,
      lastReadAt: DateTime.tryParse(json['lastReadAt']?.toString() ?? ''),
    );
  }
}

class ChatPollOptionModel {
  final String id;
  final String optionText;
  final int voteCount;
  final bool isVoted;
  final List<String> voterIds;

  const ChatPollOptionModel({
    required this.id,
    required this.optionText,
    this.voteCount = 0,
    this.isVoted = false,
    this.voterIds = const [],
  });

  factory ChatPollOptionModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final rawVoters = json['voters'] ?? json['voterIds'];
    final voterIds = <String>[];
    if (rawVoters is List) {
      for (final v in rawVoters) {
        if (v is String) {
          voterIds.add(v);
        } else if (v is Map && v['id'] != null) {
          voterIds.add(v['id'].toString());
        }
      }
    }
    final isVoted =
        json['isVoted'] == true ||
        (currentUserId != null && voterIds.contains(currentUserId));
    final count = json['voteCount'] is num
        ? (json['voteCount'] as num).toInt()
        : voterIds.length;

    return ChatPollOptionModel(
      id: (json['id'] ?? '').toString(),
      optionText: (json['optionText'] ?? json['text'] ?? '').toString(),
      voteCount: count,
      isVoted: isVoted,
      voterIds: voterIds,
    );
  }
}

class ChatPollModel {
  final String id;
  final String question;
  final bool allowMultipleAnswers;
  final bool isClosed;
  final DateTime? expiresAt;
  final int totalVotes;
  final List<ChatPollOptionModel> options;

  const ChatPollModel({
    required this.id,
    required this.question,
    this.allowMultipleAnswers = false,
    this.isClosed = false,
    this.expiresAt,
    this.totalVotes = 0,
    this.options = const [],
  });

  factory ChatPollModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final rawOptions = json['options'];
    final optionsList = <ChatPollOptionModel>[];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        final optionMap = _chatMap(opt);
        if (optionMap != null) {
          optionsList.add(
            ChatPollOptionModel.fromJson(
              optionMap,
              currentUserId: currentUserId,
            ),
          );
        }
      }
    }
    int total = json['totalVotes'] is num
        ? (json['totalVotes'] as num).toInt()
        : 0;
    if (total == 0) {
      for (final opt in optionsList) {
        total += opt.voteCount;
      }
    }

    return ChatPollModel(
      id: (json['id'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      allowMultipleAnswers:
          json['allowMultipleAnswers'] == true || json['allowMultiple'] == true,
      isClosed: json['isClosed'] == true,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      totalVotes: total,
      options: optionsList,
    );
  }
}

class ChatReactionModel {
  final String emoji;
  final int count;
  final List<String> userIds;
  final bool isReacted;

  const ChatReactionModel({
    required this.emoji,
    this.count = 1,
    this.userIds = const [],
    this.isReacted = false,
  });

  factory ChatReactionModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final rawUsers = json['userIds'] ?? json['users'];
    final userIds = <String>[];
    if (rawUsers is List) {
      for (final u in rawUsers) {
        if (u is String) {
          userIds.add(u);
        } else if (u is Map && u['id'] != null) {
          userIds.add(u['id'].toString());
        }
      }
    }
    final isReacted =
        json['isReacted'] == true ||
        (currentUserId != null && userIds.contains(currentUserId));
    final count = json['count'] is num
        ? (json['count'] as num).toInt()
        : userIds.length;

    return ChatReactionModel(
      emoji: (json['emoji'] ?? '❤️').toString(),
      count: count > 0 ? count : 1,
      userIds: userIds,
      isReacted: isReacted,
    );
  }
}

class ChatLinkPreviewModel {
  final String url;
  final String? title;
  final String? description;
  final String? image;
  final String? siteName;

  const ChatLinkPreviewModel({
    required this.url,
    this.title,
    this.description,
    this.image,
    this.siteName,
  });

  factory ChatLinkPreviewModel.fromJson(Map<String, dynamic> json) {
    return ChatLinkPreviewModel(
      url: (json['url'] ?? '').toString(),
      title: _optionalString(json['title']),
      description: _optionalString(json['description']),
      image: _optionalString(json['image'] ?? json['imageUrl']),
      siteName: _optionalString(json['siteName'] ?? json['site_name']),
    );
  }

  bool get hasContent =>
      (title?.trim().isNotEmpty ?? false) ||
      (description?.trim().isNotEmpty ?? false) ||
      (image?.trim().isNotEmpty ?? false);

  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String? senderRole;
  final String content;
  final List<String> mediaUrls;
  final ChatMessageModel? replyToMessage;
  final ChatPollModel? poll;
  final ChatLinkPreviewModel? linkPreview;
  final List<ChatReactionModel> reactions;
  final bool isPinned;
  final bool isRevoked;
  final DateTime createdAt;
  final bool isRead;
  final bool isMine;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    this.senderRole,
    required this.content,
    this.mediaUrls = const [],
    this.replyToMessage,
    this.poll,
    this.linkPreview,
    this.reactions = const [],
    this.isPinned = false,
    this.isRevoked = false,
    required this.createdAt,
    this.isRead = true,
    this.isMine = false,
  });

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final sender = json['sender'] is Map<String, dynamic>
        ? json['sender'] as Map<String, dynamic>
        : null;
    final senderId = (json['senderId'] ?? sender?['id'] ?? '').toString();
    final senderName =
        (json['senderName'] ??
                sender?['fullName'] ??
                sender?['name'] ??
                'Thành viên')
            .toString();
    final senderAvatarUrl =
        json['senderAvatarUrl']?.toString() ?? sender?['avatarUrl']?.toString();
    final senderRole =
        json['senderRole']?.toString() ?? sender?['role']?.toString();

    final rawMedia =
        json['attachmentsUrls'] ??
        json['attachments_urls'] ??
        json['mediaUrls'] ??
        json['attachments'];
    final mediaUrls = <String>[];
    if (rawMedia is List) {
      for (final m in rawMedia) {
        if (m is String && m.isNotEmpty) mediaUrls.add(m);
        if (m is Map && m['url'] != null) mediaUrls.add(m['url'].toString());
      }
    }

    ChatMessageModel? replyTo;
    if (json['replyToMessage'] is Map<String, dynamic>) {
      replyTo = ChatMessageModel.fromJson(
        json['replyToMessage'] as Map<String, dynamic>,
        currentUserId: currentUserId,
      );
    } else if (json['replyTo'] is Map<String, dynamic>) {
      replyTo = ChatMessageModel.fromJson(
        json['replyTo'] as Map<String, dynamic>,
        currentUserId: currentUserId,
      );
    }

    ChatLinkPreviewModel? linkPreview;
    final rawMetadata = json['metadata'];
    if (json['linkPreview'] is Map<String, dynamic>) {
      linkPreview = ChatLinkPreviewModel.fromJson(
        json['linkPreview'] as Map<String, dynamic>,
      );
    } else if (rawMetadata is Map && rawMetadata['linkPreview'] is Map) {
      linkPreview = ChatLinkPreviewModel.fromJson(
        Map<String, dynamic>.from(rawMetadata['linkPreview'] as Map),
      );
    }

    final metadataMap = _chatMap(rawMetadata);
    final directPollMap = _chatMap(json['poll']);
    final nestedPollMap = _chatMap(metadataMap?['poll']);
    final messageType = (json['type'] ?? json['messageType'] ?? '')
        .toString()
        .toUpperCase();
    final metadataIsPoll =
        metadataMap != null &&
        metadataMap['question'] != null &&
        metadataMap['options'] is List;

    ChatPollModel? poll;
    final pollMap =
        directPollMap ??
        nestedPollMap ??
        (messageType == 'POLL' && metadataIsPoll ? metadataMap : null) ??
        (messageType == 'POLL' ? _chatMap(json) : null);
    if (pollMap != null &&
        pollMap['question'] != null &&
        pollMap['options'] is List) {
      poll = ChatPollModel.fromJson(pollMap, currentUserId: currentUserId);
    }

    final rawReactions = json['reactions'];
    final reactionsList = <ChatReactionModel>[];
    if (rawReactions is List) {
      for (final r in rawReactions) {
        if (r is Map<String, dynamic>) {
          reactionsList.add(
            ChatReactionModel.fromJson(r, currentUserId: currentUserId),
          );
        } else if (r is String) {
          reactionsList.add(ChatReactionModel(emoji: r));
        }
      }
    } else if (rawReactions is Map) {
      rawReactions.forEach((emoji, users) {
        reactionsList.add(
          ChatReactionModel(
            emoji: emoji.toString(),
            count: users is List ? users.length : 1,
            userIds: users is List
                ? users.map((u) => u.toString()).toList()
                : [],
            isReacted:
                currentUserId != null &&
                users is List &&
                users.contains(currentUserId),
          ),
        );
      });
    }

    final isMine =
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        senderId == currentUserId;

    return ChatMessageModel(
      id: (json['id'] ?? '').toString(),
      roomId: (json['roomId'] ?? '').toString(),
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      senderRole: senderRole,
      content: (json['messageText'] ?? json['content'] ?? json['text'] ?? '')
          .toString(),
      mediaUrls: mediaUrls,
      replyToMessage: replyTo,
      poll: poll,
      linkPreview: linkPreview,
      reactions: reactionsList,
      isPinned: json['isPinned'] == true,
      isRevoked: json['isRevoked'] == true || json['revokedAt'] != null,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] != false,
      isMine: isMine,
    );
  }

  ChatMessageModel copyWith({
    String? content,
    List<ChatReactionModel>? reactions,
    bool? isPinned,
    bool? isRevoked,
    ChatPollModel? poll,
    ChatLinkPreviewModel? linkPreview,
  }) {
    return ChatMessageModel(
      id: id,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      senderRole: senderRole,
      content: content ?? this.content,
      mediaUrls: mediaUrls,
      replyToMessage: replyToMessage,
      poll: poll ?? this.poll,
      linkPreview: linkPreview ?? this.linkPreview,
      reactions: reactions ?? this.reactions,
      isPinned: isPinned ?? this.isPinned,
      isRevoked: isRevoked ?? this.isRevoked,
      createdAt: createdAt,
      isRead: isRead,
      isMine: isMine,
    );
  }
}

class ChatRoomModel {
  final String id;
  final String type; // 'CLUB' | 'DIRECT' | 'SUPPORT' | 'GROUP'
  final String? name;
  final String? clubName;
  final String? clubAvatar;
  final String? communityId;
  final List<ChatParticipant> participants;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final DateTime updatedAt;

  const ChatRoomModel({
    required this.id,
    required this.type,
    this.name,
    this.clubName,
    this.clubAvatar,
    this.communityId,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    required this.updatedAt,
  });

  factory ChatRoomModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final rawParticipants = json['participants'];
    final participantsList = <ChatParticipant>[];
    if (rawParticipants is List) {
      for (final p in rawParticipants) {
        if (p is Map<String, dynamic>) {
          participantsList.add(ChatParticipant.fromJson(p));
        }
      }
    }

    ChatMessageModel? lastMsg;
    if (json['lastMessage'] is Map<String, dynamic>) {
      lastMsg = ChatMessageModel.fromJson(
        json['lastMessage'] as Map<String, dynamic>,
        currentUserId: currentUserId,
      );
    }

    return ChatRoomModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'DIRECT').toString().toUpperCase(),
      name: json['name']?.toString(),
      clubName:
          json['clubName']?.toString() ?? json['communityName']?.toString(),
      clubAvatar:
          json['clubAvatar']?.toString() ?? json['communityLogo']?.toString(),
      communityId: json['communityId']?.toString(),
      participants: participantsList,
      lastMessage: lastMsg,
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : 0,
      isPinned: json['isPinned'] == true,
      isMuted: json['isMuted'] == true,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String displayTitle(String? currentUserId) => localizedDisplayTitle(
    currentUserId,
    lookupAppLocalizations(PlatformDispatcher.instance.locale),
  );

  String localizedDisplayTitle(String? currentUserId, AppLocalizations l10n) {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (clubName != null && clubName!.trim().isNotEmpty) {
      return clubName!.trim();
    }
    if (type == 'DIRECT') {
      final other = participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => participants.isNotEmpty
            ? participants.first
            : ChatParticipant(id: '', fullName: l10n.chatParticipantFallback),
      );
      return other.fullName;
    }
    return type == 'CLUB'
        ? l10n.chatClubFallback
        : l10n.chatConversationFallback;
  }

  String? displayAvatar(String? currentUserId) {
    if (clubAvatar != null && clubAvatar!.isNotEmpty) return clubAvatar;
    if (type == 'DIRECT') {
      final other = participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => participants.isNotEmpty
            ? participants.first
            : const ChatParticipant(id: '', fullName: ''),
      );
      return other.avatarUrl;
    }
    return null;
  }
}
