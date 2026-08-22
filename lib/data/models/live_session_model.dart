enum LiveSessionStatus {
  created,
  starting,
  live,
  reconnecting,
  stopping,
  ended,
  failed,
  unknown,
}

LiveSessionStatus liveSessionStatusFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'CREATED':
      return LiveSessionStatus.created;
    case 'STARTING':
      return LiveSessionStatus.starting;
    case 'LIVE':
      return LiveSessionStatus.live;
    case 'RECONNECTING':
      return LiveSessionStatus.reconnecting;
    case 'STOPPING':
      return LiveSessionStatus.stopping;
    case 'ENDED':
      return LiveSessionStatus.ended;
    case 'FAILED':
      return LiveSessionStatus.failed;
    default:
      return LiveSessionStatus.unknown;
  }
}

enum LiveSessionProvider { facebook, internal, unknown }

LiveSessionProvider liveSessionProviderFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'FACEBOOK':
      return LiveSessionProvider.facebook;
    case 'INTERNAL':
      return LiveSessionProvider.internal;
    default:
      return LiveSessionProvider.unknown;
  }
}

enum ReplayProvider { none, facebook, youtube, unknown }

ReplayProvider replayProviderFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'NONE':
      return ReplayProvider.none;
    case 'FACEBOOK':
      return ReplayProvider.facebook;
    case 'YOUTUBE':
      return ReplayProvider.youtube;
    default:
      return ReplayProvider.unknown;
  }
}

class LiveSessionModel {
  const LiveSessionModel({
    required this.id,
    required this.tournamentId,
    required this.matchId,
    required this.provider,
    required this.status,
    required this.replayProvider,
    this.courtId,
    this.cameraDeviceId,
    this.providerSessionId,
    this.title,
    this.description,
    this.idempotencyKey,
    this.publishConfigExpiresAt,
    this.startedAt,
    this.endedAt,
    this.lastProviderCheckAt,
    this.replayUrl,
    this.youtubeVideoId,
    this.failureCode,
    this.failureMessage,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tournamentId;
  final String? courtId;
  final String matchId;
  final String? cameraDeviceId;
  final LiveSessionProvider provider;
  final String? providerSessionId;
  final LiveSessionStatus status;
  final String? title;
  final String? description;
  final String? idempotencyKey;
  final DateTime? publishConfigExpiresAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? lastProviderCheckAt;
  final String? replayUrl;
  final ReplayProvider replayProvider;
  final String? youtubeVideoId;
  final String? failureCode;
  final String? failureMessage;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LiveSessionModel.fromJson(Map<String, Object?> json) {
    DateTime? parseDate(Object? value) {
      final text = value?.toString();
      return text == null ? null : DateTime.tryParse(text);
    }

    String? parseNullableString(Object? value) => value?.toString();

    return LiveSessionModel(
      id: json['id']?.toString() ?? '',
      tournamentId:
          json['tournamentId']?.toString() ??
          json['tournament_id']?.toString() ??
          '',
      courtId: parseNullableString(json['courtId'] ?? json['court_id']),
      matchId:
          json['matchId']?.toString() ?? json['match_id']?.toString() ?? '',
      cameraDeviceId: parseNullableString(
        json['cameraDeviceId'] ?? json['camera_device_id'],
      ),
      provider: liveSessionProviderFromString(json['provider']?.toString()),
      providerSessionId: parseNullableString(
        json['providerSessionId'] ?? json['provider_session_id'],
      ),
      status: liveSessionStatusFromString(json['status']?.toString()),
      title: parseNullableString(json['title']),
      description: parseNullableString(json['description']),
      idempotencyKey: parseNullableString(
        json['idempotencyKey'] ?? json['idempotency_key'],
      ),
      publishConfigExpiresAt: parseDate(
        json['publishConfigExpiresAt'] ?? json['publish_config_expires_at'],
      ),
      startedAt: parseDate(json['startedAt'] ?? json['started_at']),
      endedAt: parseDate(json['endedAt'] ?? json['ended_at']),
      lastProviderCheckAt: parseDate(
        json['lastProviderCheckAt'] ?? json['last_provider_check_at'],
      ),
      replayUrl: parseNullableString(json['replayUrl'] ?? json['replay_url']),
      replayProvider: replayProviderFromString(
        json['replayProvider']?.toString() ??
            json['replay_provider']?.toString(),
      ),
      youtubeVideoId: parseNullableString(
        json['youtubeVideoId'] ?? json['youtube_video_id'],
      ),
      failureCode: parseNullableString(
        json['failureCode'] ?? json['failure_code'],
      ),
      failureMessage: parseNullableString(
        json['failureMessage'] ?? json['failure_message'],
      ),
      createdBy: parseNullableString(json['createdBy'] ?? json['created_by']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class LiveSessionPublishConfigModel {
  const LiveSessionPublishConfigModel({
    required this.publishUrl,
    required this.expiresAt,
  });

  final String publishUrl;
  final DateTime expiresAt;

  factory LiveSessionPublishConfigModel.fromJson(Map<String, Object?> json) {
    return LiveSessionPublishConfigModel(
      publishUrl:
          json['publishUrl']?.toString() ??
          json['publish_url']?.toString() ??
          '',
      expiresAt:
          DateTime.tryParse(
            json['expiresAt']?.toString() ??
                json['expires_at']?.toString() ??
                '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class LiveSessionOperatorResultModel {
  const LiveSessionOperatorResultModel({
    required this.session,
    this.publishConfig,
  });

  final LiveSessionModel session;
  final LiveSessionPublishConfigModel? publishConfig;

  factory LiveSessionOperatorResultModel.fromJson(Map<String, Object?> json) {
    final sessionJson = json['session'];
    final publishConfigJson = json['publishConfig'] ?? json['publish_config'];
    return LiveSessionOperatorResultModel(
      session: LiveSessionModel.fromJson(
        sessionJson is Map ? Map<String, Object?>.from(sessionJson) : json,
      ),
      publishConfig: publishConfigJson is Map
          ? LiveSessionPublishConfigModel.fromJson(
              Map<String, Object?>.from(publishConfigJson),
            )
          : null,
    );
  }
}
