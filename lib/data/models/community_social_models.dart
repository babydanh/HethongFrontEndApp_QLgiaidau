class CommunityPostModel {
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final List<String> mediaUrls;
  final List<String> topicTags;
  final DateTime? createdAt;
  final int commentCount;
  final int reactionCount;
  final bool isPinned;
  final String? viewerReaction;
  final String status;

  const CommunityPostModel({
    required this.id,
    required this.authorName,
    required this.text,
    this.authorAvatarUrl,
    this.mediaUrls = const [],
    this.topicTags = const [],
    this.createdAt,
    this.commentCount = 0,
    this.reactionCount = 0,
    this.isPinned = false,
    this.viewerReaction,
    this.status = 'PUBLISHED',
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    final author = _asMap(json['author']);
    final rawMedia = json['mediaUrls'] ?? json['attachmentsUrls'];
    final rawTopics = json['topicTags'] ?? json['topics'] ?? json['tags'];
    return CommunityPostModel(
      id: _asString(json['id']) ?? '',
      authorName: _asString(json['authorName']) ??
          _asString(author['fullName']) ??
          _asString(author['displayName']) ??
          _asString(author['name']) ??
          'Thành viên CLB',
      authorAvatarUrl: _asString(json['authorAvatarUrl']) ??
          _asString(author['avatarUrl']) ??
          _asString(author['avatar']),
      text: _asString(json['text']) ??
          _asString(json['body']) ??
          _asString(json['content']) ??
          _asString(json['message']) ??
          '',
      mediaUrls: _asStringList(rawMedia),
      topicTags: _asStringList(rawTopics),
      createdAt: _asDateTime(json['createdAt'] ?? json['created_at']),
      commentCount: _asInt(json['commentCount'] ?? json['commentsCount']),
      reactionCount: _asInt(json['reactionCount'] ?? json['reactionsCount']),
      isPinned: json['isPinned'] == true,
      viewerReaction: _asString(json['viewerReaction'] ?? json['myReaction']),
      status: _asString(json['status']) ?? 'PUBLISHED',
    );
  }
}

class CommunityCommentModel {
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final DateTime? createdAt;

  const CommunityCommentModel({
    required this.id,
    required this.authorName,
    required this.body,
    this.authorAvatarUrl,
    this.createdAt,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    final author = _asMap(json['author']);
    return CommunityCommentModel(
      id: _asString(json['id']) ?? '',
      authorName: _asString(json['authorName']) ??
          _asString(author['fullName']) ??
          _asString(author['displayName']) ??
          'Thành viên CLB',
      authorAvatarUrl: _asString(json['authorAvatarUrl']) ?? _asString(author['avatarUrl']),
      body: _asString(json['body'] ?? json['content']) ?? '',
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

  factory CommunitySocialSettings.fromJson(Map<String, dynamic> json) => CommunitySocialSettings(
        postingPolicy: json['postingPolicy']?.toString() ?? 'MEMBERS',
        postApprovalRequired: json['postApprovalRequired'] == true,
        commentsEnabled: json['commentsEnabled'] != false,
        chatEnabled: json['chatEnabled'] != false,
        publicFeed: json['publicFeed'] != false,
        memberTaggingPolicy: json['memberTaggingPolicy']?.toString() ?? 'MEMBERS',
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

  const CommunityTagPreset({required this.id, required this.name, required this.color});

  factory CommunityTagPreset.fromJson(Map<String, dynamic> json) => CommunityTagPreset(
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

String? _asString(Object? value) => value is String && value.trim().isNotEmpty
    ? value
    : null;

int _asInt(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

DateTime? _asDateTime(Object? value) => value is DateTime
    ? value
    : value is String
        ? DateTime.tryParse(value)
        : null;

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().where((item) => item.trim().isNotEmpty).toList();
}
