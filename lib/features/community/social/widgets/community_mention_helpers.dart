import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:flutter/material.dart';

class MentionInput {
  final int start;
  final int end;
  final String query;

  const MentionInput({
    required this.start,
    required this.end,
    required this.query,
  });
}

MentionInput? findActiveMention(String text, TextSelection selection) {
  if (!selection.isValid || selection.start < 0) return null;
  final cursor = selection.start.clamp(0, text.length);
  final before = text.substring(0, cursor);
  final start = before.lastIndexOf('@');
  if (start < 0 ||
      (start > 0 && !RegExp(r'\s').hasMatch(before[start - 1]))) {
    return null;
  }
  final query = before.substring(start + 1);
  if (query.contains(RegExp(r'\s'))) return null;
  return MentionInput(start: start, end: cursor, query: query);
}

bool containsMentionToken(String text, String memberName) {
  final pattern = RegExp(
    '(^|\\s)@${RegExp.escape(memberName)}(?=\\s|[.,!?;:)]|' r'$)',
    caseSensitive: false,
  );
  return pattern.hasMatch(text);
}

extension CommunityMentionMember on CommunityMemberModel {
  String get mentionDisplayName => (userFullName?.trim().isNotEmpty ?? false)
      ? userFullName!.trim()
      : (userEmail?.split('@').first ?? 'Thành viên');

  String get mentionInitial => mentionDisplayName.isEmpty
      ? '?'
      : mentionDisplayName.substring(0, 1).toUpperCase();

  ImageProvider<Object>? get mentionAvatarProvider =>
      (userAvatarUrl?.trim().isNotEmpty ?? false)
          ? NetworkImage(userAvatarUrl!)
          : null;
}
