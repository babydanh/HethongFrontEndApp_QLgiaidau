import 'dart:async';

import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_mention_helpers.dart';
import 'package:flutter/material.dart';

/// Điều khiển logic @mention cho composer: nhận diện token @, debounce tìm kiếm,
/// chọn thành viên, dọn mention stale. Thuần logic — không biết đến UI.
/// (Giống TextEditingController: mutable controller, không phải Riverpod state.)
class ComposerMentionEngine {
  ComposerMentionEngine({
    required this.controller,
    required this.onQueryChanged,
    this.onWarning,
    this.maxMentions = 20,
  });

  final TextEditingController controller;
  final ValueChanged<String?> onQueryChanged;
  final ValueChanged<String>? onWarning;
  final int maxMentions;

  Timer? _debounce;
  MentionInput? activeMention;
  final Map<String, CommunityMemberModel> _mentions = {};

  List<CommunityMemberModel> get mentionedMembers =>
      List.unmodifiable(_mentions.values);

  void start() => controller.addListener(_onTextChanged);

  void dispose() {
    _debounce?.cancel();
    controller.removeListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = controller.text;
    _mentions.removeWhere(
        (_, member) => !containsMentionToken(text, member.mentionDisplayName));
    activeMention = findActiveMention(text, controller.selection);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      onQueryChanged(activeMention?.query);
    });
  }

  /// Chèn ký tự @ tại vị trí con trỏ hiện tại.
  void insertToken() {
    final selection = controller.selection;
    final position =
        selection.isValid ? selection.start : controller.text.length;
    final text = controller.text;
    controller.value = TextEditingValue(
      text: '${text.substring(0, position)}@${text.substring(position)}',
      selection: TextSelection.collapsed(offset: position + 1),
    );
  }

  /// Thay token @đang gõ bằng @tên thành viên. Trả về false nếu bị chặn.
  bool selectMember(CommunityMemberModel member) {
    final input = activeMention;
    if (input == null || member.userId.isEmpty) return false;
    if (_mentions.length >= maxMentions && !_mentions.containsKey(member.userId)) {
      onWarning?.call('Bạn chỉ có thể gắn tối đa $maxMentions thành viên.');
      return false;
    }
    final name = member.mentionDisplayName;
    final duplicated = _mentions.entries.any((entry) =>
        entry.key != member.userId &&
        entry.value.mentionDisplayName.toLowerCase() == name.toLowerCase());
    if (duplicated) {
      onWarning?.call(
          'CLB có hai thành viên cùng tên. Hãy dùng tên khác để tránh nhầm lẫn.');
      return false;
    }
    final text = controller.text;
    final replacement = '@$name ';
    controller.value = TextEditingValue(
      text:
          '${text.substring(0, input.start)}$replacement${text.substring(input.end)}',
      selection:
          TextSelection.collapsed(offset: input.start + replacement.length),
    );
    _mentions[member.userId] = member;
    return true;
  }

  void removeMention(String userId) => _mentions.remove(userId);

  /// Chỉ giữ mention còn token @tên trong nội dung cuối (khớp logic web).
  List<String> validMentionIdsFor(String text) => _mentions.entries
      .where((entry) =>
          containsMentionToken(text, entry.value.mentionDisplayName))
      .map((entry) => entry.key)
      .toList(growable: false);
}
