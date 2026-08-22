import 'dart:ui';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Entity cho thông báo từ API GET /notifications
class AppNotification {
  final String id;
  final String type; // TOURNAMENT | MATCH | PAYMENT | SYSTEM | CHAT | REMINDER
  final String title;
  final String? body;
  final String? redirectUrl; // deep link
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // raw data payload

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.redirectUrl,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      title: json['title'] ?? '',
      body: json['content'] ?? json['body'],
      redirectUrl: json['redirectUrl'],
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
          DateTime.now(),
      data: (json['data'] is Map<String, dynamic>)
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }

  /// Trích xuất tournamentId từ data payload
  String? get tournamentId {
    if (data == null) return null;
    final val = data!['tournamentId'];
    if (val is String && val.isNotEmpty) return val;
    if (val is num) return val.toString();
    return null;
  }

  /// Trích xuất matchId từ data payload
  String? get matchId {
    if (data == null) return null;
    final val = data!['matchId'];
    if (val is String && val.isNotEmpty) return val;
    if (val is num) return val.toString();
    return null;
  }

  String? get footballTeamId {
    final value = data?['teamId'] ?? data?['team_id'];
    if (value is String && value.isNotEmpty) return value;
    if (value is num) return value.toString();
    final uri = Uri.tryParse(redirectUrl ?? '');
    final queryId = uri?.queryParameters['teamId'];
    return queryId == null || queryId.isEmpty ? null : queryId;
  }

  /// Đường dẫn đích dựa trên loại thông báo + data
  String? get routeTarget {
    switch (type) {
      case 'MATCH_LIVE':
      case 'MATCH_RESULT':
        if (matchId != null) return '/live/$matchId';
        return null;

      case 'MATCH_REMINDER':
        // Reminder payloads carry the canonical deep link; keep the match
        // fallback for older notifications that only contained matchId.
        return _normalizeRedirectUrl(redirectUrl) ??
            (matchId == null ? null : '/live/$matchId');

      case 'TOURNAMENT_INVITE':
      case 'TOURNAMENT_REGISTER_PENDING':
      case 'TEAM_CONFIRMATION_EXPIRED':
        if (tournamentId != null) return '/intro/$tournamentId';
        return null;

      case 'CLUB_INVITE':
        return communityId == null ? null : '/club/$communityId';

      case 'COMMUNITY_POST_MENTIONED':
      case 'COMMUNITY_POST_COMMENTED':
        return _normalizeRedirectUrl(redirectUrl) ??
            (communityId == null ? null : '/club/$communityId');

      case 'DOUBLES_TEAM_INVITE':
        if (tournamentId != null) return '/register/$tournamentId/doubles';
        return null;

      case 'PAYMENT':
      case 'PAYOUT':
      case 'PAYOUT_APPROVED':
      case 'PAYOUT_REJECTED':
        return '/profile';

      default:
        if (type.startsWith('FOOTBALL_TEAM_')) {
          if (footballTeamId != null)
            return '/football-teams?teamId=$footballTeamId';
          return _normalizeRedirectUrl(redirectUrl);
        }
        if (type.contains('MATCH') && matchId != null) {
          return '/live/$matchId';
        }
        if (type.startsWith('TOURNAMENT_') && tournamentId != null) {
          return '/intro/$tournamentId';
        }
        if ((type.startsWith('COMMUNITY_') || type.startsWith('CLUB_')) &&
            communityId != null) {
          return '/club/$communityId';
        }

        // type chứa 'DOUBLES'
        if (type.contains('DOUBLES') && tournamentId != null) {
          return '/register/$tournamentId/doubles';
        }
        // type chứa 'GENERAL' hoặc unknown → dùng redirectUrl nếu có
        if (type.startsWith('GENERAL') || type.startsWith('SYSTEM')) {
          return _normalizeRedirectUrl(redirectUrl);
        }
        // REFEREE types are handled inline via isInvite/isRefereeInvite — no route
        if (isRefereeInvite) return null;
        // Fallback: dùng redirectUrl nếu có
        return _normalizeRedirectUrl(redirectUrl);
    }
  }

  /// Converts web notification links to routes that exist in the mobile app.
  String? _normalizeRedirectUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final raw = rawUrl.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final path = uri.path;
    final segments = uri.pathSegments;

    if (path == '/profile' ||
        path == '/notifications' ||
        path == '/football-teams')
      return raw;
    if (segments.length >= 2 && segments[0] == 'tournaments') {
      final participantId = uri.queryParameters['participantId'];
      if (participantId != null && participantId.isNotEmpty) {
        final divisionId = uri.queryParameters['divisionId'];
        return '/register/${segments[1]}/team?participantId=${Uri.encodeQueryComponent(participantId)}${divisionId == null ? '' : '&divisionId=${Uri.encodeQueryComponent(divisionId)}'}';
      }
      if (segments.length >= 5 &&
          segments[2] == 'participants' &&
          segments[4] == 'accept-partner') {
        return '/join-team?tournamentId=${segments[1]}&pid=${segments[3]}';
      }
      if (segments.length >= 3 && segments[2] == 'join-team') {
        final pid = uri.queryParameters['pid'] ?? '';
        final token = uri.queryParameters['token'] ?? '';
        return '/join-team?tournamentId=${segments[1]}&pid=$pid&token=$token';
      }
      if (segments.length >= 3 && segments[2] == 'register') {
        final divisionId = uri.queryParameters['divisionId'];
        final tab = uri.queryParameters['tab'];
        final participantId = uri.queryParameters['participantId'];
        final query = <String, String>{
          if (divisionId != null && divisionId.isNotEmpty)
            'divisionId': divisionId,
          if (tab != null && tab.isNotEmpty) 'tab': tab,
          if (participantId != null && participantId.isNotEmpty)
            'participantId': participantId,
        };
        final suffix = query.entries
            .map(
              (entry) =>
                  '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
            )
            .join('&');
        return '/register/${segments[1]}${suffix.isEmpty ? '' : '?$suffix'}';
      }
      return '/intro/${segments[1]}';
    }
    if (segments.length >= 3 &&
        segments[0] == 'organizer' &&
        segments[1] == 'tournaments') {
      // Advanced management remains web-first, but the app must still land
      // on the real tournament instead of silently dropping the notification.
      return '/intro/${segments[2]}';
    }
    if (segments.length >= 2 &&
        segments[0] == 'organizer' &&
        segments[1] == 'tournaments') {
      return '/dashboard';
    }
    if (segments.length >= 2 && segments[0] == 'matches') {
      return '/live/${segments[1]}';
    }
    if (segments.length >= 2 && segments[0] == 'communities') {
      final postId = uri.queryParameters['postId'];
      final query = postId == null || postId.isEmpty
          ? ''
          : '?postId=${Uri.encodeQueryComponent(postId)}';
      return '/communities/${segments[1]}/social$query';
    }
    if (segments.length >= 2 && segments[0] == 'clubs') {
      final postId = uri.queryParameters['postId'];
      final query = postId == null || postId.isEmpty
          ? ''
          : '?postId=${Uri.encodeQueryComponent(postId)}';
      return '/communities/${segments[1]}/social$query';
    }
    if (path == '/reset-password') {
      final token = uri.queryParameters['token'];
      return token == null || token.isEmpty
          ? null
          : '/reset-password?token=${Uri.encodeComponent(token)}';
    }
    if (path.startsWith('/live/') ||
        path.startsWith('/intro/') ||
        path.startsWith('/club/') ||
        path.startsWith('/register/')) {
      return raw;
    }
    return null;
  }

  String? get communityId {
    final value = data?['communityId'] ?? data?['clubId'];
    if (value is String && value.isNotEmpty) return value;
    if (value is num) return value.toString();

    // Community invite notifications currently carry the community id in
    // redirectUrl rather than data. Support both shapes so old and new
    // notifications use the same accept/decline flow.
    final rawRedirect = redirectUrl;
    if (rawRedirect != null && rawRedirect.isNotEmpty) {
      final uri = Uri.tryParse(rawRedirect);
      final segments = uri?.pathSegments ?? const <String>[];
      if (segments.length >= 2 &&
          (segments[0] == 'communities' || segments[0] == 'clubs')) {
        final id = segments[1].trim();
        if (id.isNotEmpty) return id;
      }
    }
    return null;
  }

  /// Kiểm tra nếu là lời mời trọng tài
  bool get isRefereeInvite {
    return type == 'REFEREE_INVITE' || type == 'REFEREE_INVITED';
  }

  /// Kiểm tra nếu thông báo có chứa action accept/decline
  bool get isFootballTeamInvite => type == 'FOOTBALL_TEAM_INVITED';

  bool get isInvite {
    return type == 'CLUB_INVITE' ||
        type == 'COMMUNITY_INVITED' ||
        type == 'INVITE' ||
        type == 'PARTNER_INVITE_RECEIVED' ||
        isFootballTeamInvite ||
        isRefereeInvite;
  }

  /// Icon theo loại thông báo
  IconData get icon {
    if (type.startsWith('FOOTBALL_TEAM_')) return Icons.sports_soccer_rounded;
    switch (type) {
      case 'TOURNAMENT':
      case 'TOURNAMENT_REGISTER_PENDING':
      case 'TOURNAMENT_REGISTER_SUCCESS':
      case 'TOURNAMENT_REGISTER_REJECTED':
      case 'TOURNAMENT_PARTICIPANT_NEW':
      case 'TOURNAMENT_WITHDRAWN':
      case 'TOURNAMENT_KICKED':
        return Icons.emoji_events_rounded;
      case 'MATCH':
      case 'MATCH_SCHEDULED':
      case 'MATCH_REMINDER':
      case 'MATCH_COMPLETED':
        return Icons.sports_tennis_rounded;
      case 'PAYMENT':
      case 'PAYOUT_APPROVED':
      case 'PAYOUT_REJECTED':
        return Icons.payments_rounded;
      case 'PARTNER_INVITE_RECEIVED':
      case 'PARTNER_INVITE_ACCEPTED':
      case 'PARTNER_INVITE_REJECTED':
      case 'PARTNER_INVITE_CANCELLED':
        return Icons.group_add_rounded;
      case 'REFEREE_INVITED':
      case 'REFEREE_INVITE_ACCEPTED':
      case 'REFEREE_INVITE_DECLINED':
      case 'REFEREE_INVITE_REVOKED':
      case 'REFEREE_ASSIGNED':
        return Icons.sports_rounded;
      case 'COMMUNITY_INVITED':
      case 'COMMUNITY_ROLE_PROMOTED':
      case 'COMMUNITY_ROLE_DEMOTED':
      case 'COMMUNITY_KICKED':
      case 'COMMUNITY_INVITE_REVOKED':
        return Icons.groups_rounded;
      case 'CHAT':
        return Icons.chat_rounded;
      case 'REMINDER':
        return Icons.notifications_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Màu theo loại thông báo
  Color get color {
    if (type.startsWith('FOOTBALL_TEAM_')) return const Color(0xFF059669);
    switch (type) {
      case 'TOURNAMENT':
      case 'TOURNAMENT_REGISTER_PENDING':
      case 'TOURNAMENT_REGISTER_SUCCESS':
      case 'TOURNAMENT_REGISTER_REJECTED':
      case 'TOURNAMENT_PARTICIPANT_NEW':
      case 'TOURNAMENT_WITHDRAWN':
      case 'TOURNAMENT_KICKED':
        return const Color(0xFFF59E0B);
      case 'MATCH':
      case 'MATCH_SCHEDULED':
      case 'MATCH_REMINDER':
      case 'MATCH_COMPLETED':
        return const Color(0xFF2979FF);
      case 'PAYMENT':
      case 'PAYOUT_APPROVED':
      case 'PAYOUT_REJECTED':
        return const Color(0xFF10B981);
      case 'PARTNER_INVITE_RECEIVED':
        return const Color(0xFF8B5CF6);
      case 'PARTNER_INVITE_ACCEPTED':
        return const Color(0xFF10B981);
      case 'PARTNER_INVITE_REJECTED':
      case 'PARTNER_INVITE_CANCELLED':
        return const Color(0xFF64748B);
      case 'REFEREE_INVITED':
      case 'REFEREE_ASSIGNED':
        return const Color(0xFFF59E0B);
      case 'REFEREE_INVITE_ACCEPTED':
        return const Color(0xFF10B981);
      case 'REFEREE_INVITE_DECLINED':
      case 'REFEREE_INVITE_REVOKED':
        return const Color(0xFF64748B);
      case 'COMMUNITY_INVITED':
        return const Color(0xFF8B5CF6);
      case 'COMMUNITY_ROLE_PROMOTED':
        return const Color(0xFF10B981);
      case 'COMMUNITY_ROLE_DEMOTED':
      case 'COMMUNITY_KICKED':
      case 'COMMUNITY_INVITE_REVOKED':
        return const Color(0xFF64748B);
      case 'CHAT':
        return const Color(0xFF8B5CF6);
      case 'REMINDER':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  /// Legacy Vietnamese formatter kept for non-UI compatibility.
  String get timeAgo =>
      localizedTimeAgo(lookupAppLocalizations(PlatformDispatcher.instance.locale));

  String localizedTimeAgo(AppLocalizations l10n) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return l10n.communityComment_justNow;
    if (diff.inMinutes < 60) {
      return l10n.notificationMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.notificationHoursAgo(diff.inHours);
    }
    if (diff.inDays < 7) {
      return l10n.notificationDaysAgo(diff.inDays);
    }
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
