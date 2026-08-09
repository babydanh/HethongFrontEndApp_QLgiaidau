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
      createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      data: (json['data'] is Map<String, dynamic>) ? json['data'] as Map<String, dynamic> : null,
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

  /// Đường dẫn đích dựa trên loại thông báo + data
  String? get routeTarget {
    switch (type) {
      case 'MATCH_LIVE':
      case 'MATCH_RESULT':
        if (matchId != null) return '/live/$matchId';
        return null;

      case 'TOURNAMENT_INVITE':
      case 'TOURNAMENT_REGISTER_PENDING':
      case 'TEAM_CONFIRMATION_EXPIRED':
        if (tournamentId != null) return '/intro/$tournamentId';
        return null;

      case 'CLUB_INVITE':
        return communityId == null ? null : '/club/$communityId';

      case 'DOUBLES_TEAM_INVITE':
        if (tournamentId != null) return '/register/$tournamentId/doubles';
        return null;

      case 'PAYMENT':
      case 'PAYOUT':
      case 'PAYOUT_APPROVED':
      case 'PAYOUT_REJECTED':
        return '/profile';

      default:
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

    if (path == '/profile' || path == '/notifications') return path;
    if (segments.length >= 2 && segments[0] == 'tournaments') {
      if (segments.length >= 5 && segments[2] == 'participants' && segments[4] == 'accept-partner') {
        return '/join-team?tournamentId=${segments[1]}&pid=${segments[3]}';
      }
      if (segments.length >= 3 && segments[2] == 'join-team') {
        final pid = uri.queryParameters['pid'] ?? '';
        final token = uri.queryParameters['token'] ?? '';
        return '/join-team?tournamentId=${segments[1]}&pid=$pid&token=$token';
      }
      if (segments.length >= 3 && segments[2] == 'register') {
        final divisionId = uri.queryParameters['divisionId'];
        if (divisionId != null && divisionId.isNotEmpty) {
           return '/register/${segments[1]}?divisionId=$divisionId';
        }
        return '/register/${segments[1]}';
      }
      return '/intro/${segments[1]}';
    }
    if (segments.length >= 2 && segments[0] == 'matches') {
      return '/live/${segments[1]}';
    }
    if (segments.length >= 2 &&
        (segments[0] == 'communities' || segments[0] == 'clubs')) {
      return '/club/${segments[1]}';
    }
    if (path == '/reset-password') {
      final token = uri.queryParameters['token'];
      return token == null || token.isEmpty
          ? null
          : '/reset-password?token=${Uri.encodeComponent(token)}';
    }
    if (path.startsWith('/live/') || path.startsWith('/intro/') ||
        path.startsWith('/club/') || path.startsWith('/register/')) {
      return raw;
    }
    return null;
  }

  String? get communityId {
    if (data == null) return null;
    final value = data!['communityId'] ?? data!['clubId'];
    if (value is String && value.isNotEmpty) return value;
    if (value is num) return value.toString();
    return null;
  }

  /// Kiểm tra nếu là lời mời trọng tài
  bool get isRefereeInvite {
    return type == 'REFEREE_INVITE' || type.contains('REFEREE');
  }

  /// Kiểm tra nếu thông báo có chứa action accept/decline
  bool get isInvite {
    return type == 'CLUB_INVITE' ||
        type == 'INVITE' ||
        isRefereeInvite;
  }

  /// Icon theo loại thông báo
  IconData get icon {
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
      case 'MATCH_COMPLETED':
        return Icons.sports_tennis_rounded;
      case 'PAYMENT':
      case 'PAYOUT_APPROVED':
      case 'PAYOUT_REJECTED':
        return Icons.payments_rounded;
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
      case 'MATCH_COMPLETED':
        return const Color(0xFF2979FF);
      case 'PAYMENT':
      case 'PAYOUT_APPROVED':
      case 'PAYOUT_REJECTED':
        return const Color(0xFF10B981);
      case 'CHAT':
        return const Color(0xFF8B5CF6);
      case 'REMINDER':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  /// Format thời gian tương đối
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
