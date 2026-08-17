import 'package:flutter/foundation.dart';

@immutable
class ClubNotificationPrefModel {
  final String communityId;
  final String communityName;
  final String? logoUrl;
  final String role;
  final String notificationPreference; // 'ALL' | 'MENTIONS_ONLY' | 'MUTED'

  const ClubNotificationPrefModel({
    required this.communityId,
    required this.communityName,
    this.logoUrl,
    required this.role,
    required this.notificationPreference,
  });

  factory ClubNotificationPrefModel.fromJson(Map<String, dynamic> json) {
    return ClubNotificationPrefModel(
      communityId: json['communityId']?.toString() ?? '',
      communityName: json['communityName']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      role: json['role']?.toString() ?? 'MEMBER',
      notificationPreference: json['notificationPreference']?.toString() ?? 'ALL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'communityName': communityName,
      'logoUrl': logoUrl,
      'role': role,
      'notificationPreference': notificationPreference,
    };
  }

  ClubNotificationPrefModel copyWith({
    String? communityId,
    String? communityName,
    String? logoUrl,
    String? role,
    String? notificationPreference,
  }) {
    return ClubNotificationPrefModel(
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      logoUrl: logoUrl ?? this.logoUrl,
      role: role ?? this.role,
      notificationPreference: notificationPreference ?? this.notificationPreference,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClubNotificationPrefModel &&
          runtimeType == other.runtimeType &&
          communityId == other.communityId &&
          communityName == other.communityName &&
          logoUrl == other.logoUrl &&
          role == other.role &&
          notificationPreference == other.notificationPreference;

  @override
  int get hashCode =>
      communityId.hashCode ^
      communityName.hashCode ^
      logoUrl.hashCode ^
      role.hashCode ^
      notificationPreference.hashCode;
}
