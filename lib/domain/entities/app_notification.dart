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

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.redirectUrl,
    this.isRead = false,
    required this.createdAt,
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
    );
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
