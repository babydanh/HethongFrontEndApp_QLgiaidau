class CommunityPollVoter {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const CommunityPollVoter({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory CommunityPollVoter.fromJson(Map<String, dynamic> json) {
    return CommunityPollVoter(
      id: _asString(json['id']) ?? '',
      fullName: _asString(json['fullName']) ?? 'Thành viên',
      avatarUrl: _asString(json['avatarUrl']),
    );
  }
}

class CommunityPollOption {
  final String id;
  final String optionText;
  final int voteCount;
  final bool isVoted;
  final List<CommunityPollVoter> voters;

  const CommunityPollOption({
    required this.id,
    required this.optionText,
    this.voteCount = 0,
    this.isVoted = false,
    this.voters = const [],
  });

  factory CommunityPollOption.fromJson(Map<String, dynamic> json) {
    final rawVoters = json['voters'];
    return CommunityPollOption(
      id: _asString(json['id']) ?? '',
      optionText: _asString(json['optionText'] ?? json['text']) ?? '',
      voteCount: _asInt(json['voteCount'] ?? json['vote_count']),
      isVoted: json['isVoted'] == true,
      voters: rawVoters is List
          ? rawVoters
                .map(_asMap)
                .map(CommunityPollVoter.fromJson)
                .where((voter) => voter.id.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

class CommunityPollModel {
  final String id;
  final String question;
  final bool allowMultipleAnswers;
  final bool allowAddOptions;
  final bool isClosed;
  final DateTime? expiresAt;
  final int totalVotes;
  final List<CommunityPollOption> options;

  const CommunityPollModel({
    required this.id,
    required this.question,
    this.allowMultipleAnswers = false,
    this.allowAddOptions = false,
    this.isClosed = false,
    this.expiresAt,
    this.totalVotes = 0,
    this.options = const [],
  });

  factory CommunityPollModel.fromJson(Map<String, dynamic> json) {
    final poll = _asMap(json['poll']);
    final source = poll.isEmpty ? json : poll;
    final rawOptions = json['options'] ?? source['options'];
    return CommunityPollModel(
      id: _asString(source['id']) ?? '',
      question: _asString(source['question']) ?? '',
      allowMultipleAnswers: source['allowMultipleAnswers'] == true,
      allowAddOptions: source['allowAddOptions'] == true,
      isClosed: source['isClosed'] == true,
      expiresAt: _asDateTime(source['expiresAt'] ?? source['expires_at']),
      totalVotes: _asInt(
        json['totalVotes'] ?? source['totalVotes'] ?? json['total_votes'],
      ),
      options: rawOptions is List
          ? rawOptions
                .map(_asMap)
                .map(CommunityPollOption.fromJson)
                .where((option) => option.id.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

class CommunityPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final String? tournamentId;
  final String? tournamentName;
  final String? tournamentInviteCode;
  final String type;
  final List<String> mediaUrls;
  final List<String> topicTags;
  final List<String> mentions;
  final DateTime? createdAt;
  final int commentCount;
  final int reactionCount;
  final bool isPinned;
  final String? viewerReaction;
  final String status;
  final CommunityPollModel? poll;

  const CommunityPostModel({
    required this.id,
    required this.authorName,
    required this.text,
    this.authorId = '',
    this.authorAvatarUrl,
    this.tournamentId,
    this.tournamentName,
    this.tournamentInviteCode,
    this.type = 'NORMAL',
    this.mediaUrls = const [],
    this.topicTags = const [],
    this.mentions = const [],
    this.createdAt,
    this.commentCount = 0,
    this.reactionCount = 0,
    this.isPinned = false,
    this.viewerReaction,
    this.status = 'PUBLISHED',
    this.poll,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    final author = _asMap(json['author']);
    final tournament = _asMap(json['tournament']);
    final poll = _asMap(json['poll']);
    final rawMedia = json['mediaUrls'] ?? json['attachmentsUrls'];
    final rawTopics = json['topicTags'] ?? json['topics'] ?? json['tags'];
    return CommunityPostModel(
      id: _asString(json['id']) ?? '',
      authorId: _asString(json['authorId'] ?? author['id']) ?? '',
      authorName:
          _asString(json['authorName']) ??
          _asString(author['fullName']) ??
          _asString(author['displayName']) ??
          _asString(author['name']) ??
          'Thành viên CLB',
      authorAvatarUrl:
          _asString(json['authorAvatarUrl']) ??
          _asString(author['avatarUrl']) ??
          _asString(author['avatar']),
      text:
          _asString(json['text']) ??
          _asString(json['body']) ??
          _asString(json['content']) ??
          _asString(json['message']) ??
          '',
      tournamentId: _asString(json['tournamentId'] ?? tournament['id']),
      tournamentName: _asString(json['tournamentName'] ?? tournament['name']),
      tournamentInviteCode: _asString(json['tournamentInviteCode'] ?? tournament['inviteCode'] ?? tournament['invite_code']),
      type: _asString(json['type']) ?? 'NORMAL',
      mediaUrls: _asStringList(rawMedia),
      topicTags: _asStringList(rawTopics),
      mentions: _asStringList(json['mentions'] ?? json['mentionIds']),
      createdAt: _asDateTime(json['createdAt'] ?? json['created_at']),
      commentCount: _asInt(json['commentCount'] ?? json['commentsCount']),
      reactionCount: _asInt(json['reactionCount'] ?? json['reactionsCount']),
      isPinned: json['isPinned'] == true,
      viewerReaction: _asString(json['viewerReaction'] ?? json['myReaction']),
      status: _asString(json['status']) ?? 'PUBLISHED',
      poll: poll.isEmpty ? null : CommunityPollModel.fromJson(poll),
    );
  }
}

class CommunityCommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final String? parentId;
  final DateTime? createdAt;

  const CommunityCommentModel({
    required this.id,
    required this.authorName,
    required this.body,
    this.authorId = '',
    this.authorAvatarUrl,
    this.parentId,
    this.createdAt,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    final author = _asMap(json['author']);
    return CommunityCommentModel(
      id: _asString(json['id']) ?? '',
      authorId: _asString(json['authorId'] ?? author['id']) ?? '',
      authorName:
          _asString(json['authorName']) ??
          _asString(author['fullName']) ??
          _asString(author['displayName']) ??
          'Thành viên CLB',
      authorAvatarUrl:
          _asString(json['authorAvatarUrl']) ?? _asString(author['avatarUrl']),
      body: _asString(json['body'] ?? json['content']) ?? '',
      parentId: _asString(json['parentId'] ?? json['parent_id']),
      createdAt: _asDateTime(json['createdAt'] ?? json['created_at']),
    );
  }
}

class CommunityFeedPage {
  final List<CommunityPostModel> items;
  final String? nextCursor;
  final bool hasMore;

  const CommunityFeedPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });
}

class CommunityCommentPage {
  final List<CommunityCommentModel> items;
  final String? nextCursor;
  final bool hasMore;

  const CommunityCommentPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });
}

class CommunitySocialSettings {
  final String postingPolicy;
  final bool postApprovalRequired;
  final bool commentsEnabled;
  final bool chatEnabled;
  final bool publicFeed;
  final String memberTaggingPolicy;

  const CommunitySocialSettings({
    this.postingPolicy = 'MEMBERS',
    this.postApprovalRequired = false,
    this.commentsEnabled = true,
    this.chatEnabled = true,
    this.publicFeed = true,
    this.memberTaggingPolicy = 'MEMBERS',
  });

  factory CommunitySocialSettings.fromJson(Map<String, dynamic> json) =>
      CommunitySocialSettings(
        postingPolicy: json['postingPolicy']?.toString() ?? 'MEMBERS',
        postApprovalRequired: json['postApprovalRequired'] == true,
        commentsEnabled: json['commentsEnabled'] != false,
        chatEnabled: json['chatEnabled'] != false,
        publicFeed: json['publicFeed'] != false,
        memberTaggingPolicy:
            json['memberTaggingPolicy']?.toString() ?? 'MEMBERS',
      );

  Map<String, dynamic> toJson() => {
    'postingPolicy': postingPolicy,
    'postApprovalRequired': postApprovalRequired,
    'commentsEnabled': commentsEnabled,
    'chatEnabled': chatEnabled,
    'publicFeed': publicFeed,
    'memberTaggingPolicy': memberTaggingPolicy,
  };

  CommunitySocialSettings copyWith({
    String? postingPolicy,
    bool? postApprovalRequired,
    bool? commentsEnabled,
    bool? chatEnabled,
    bool? publicFeed,
    String? memberTaggingPolicy,
  }) => CommunitySocialSettings(
    postingPolicy: postingPolicy ?? this.postingPolicy,
    postApprovalRequired: postApprovalRequired ?? this.postApprovalRequired,
    commentsEnabled: commentsEnabled ?? this.commentsEnabled,
    chatEnabled: chatEnabled ?? this.chatEnabled,
    publicFeed: publicFeed ?? this.publicFeed,
    memberTaggingPolicy: memberTaggingPolicy ?? this.memberTaggingPolicy,
  );
}

class CommunityTagPreset {
  final String id;
  final String name;
  final String color;

  const CommunityTagPreset({
    required this.id,
    required this.name,
    required this.color,
  });

  factory CommunityTagPreset.fromJson(Map<String, dynamic> json) =>
      CommunityTagPreset(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        color: json['color']?.toString() ?? '#3B82F6',
      );
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

String? _asString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

DateTime? _asDateTime(Object? value) => value is DateTime
    ? value
    : value is String
    ? DateTime.tryParse(value)
    : null;

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.trim().isNotEmpty)
      .toList();
}
