import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_chat_moderation.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatRoomTime(DateTime time) =>
    DateFormat('HH:mm dd/MM').format(time.toLocal());

enum RoomMemberAction { kick, unkick, mute, unmute }

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null
          ? Text(name.isNotEmpty ? name.characters.first.toUpperCase() : '?')
          : null,
    );
  }
}

/// "People in the room" tab: everyone registered, with status chips and a
/// kick / mute menu (not on yourself).
class TournamentRoomMembersList extends StatelessWidget {
  const TournamentRoomMembersList({
    super.key,
    required this.members,
    required this.currentUserId,
    required this.hasMore,
    required this.onLoadMore,
    required this.onAction,
  });

  final List<ChatRoomMember> members;
  final String? currentUserId;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final void Function(ChatRoomMember, RoomMemberAction) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (members.isEmpty) return Center(child: Text(l10n.chatRoomManageEmpty));
    return ListView.builder(
      itemCount: members.length + (hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == members.length) {
          return Center(
            child: TextButton(
              onPressed: onLoadMore,
              child: Text(l10n.chatRoomManageLoadMore),
            ),
          );
        }
        return _memberTile(context, members[i]);
      },
    );
  }

  Widget _memberTile(BuildContext context, ChatRoomMember member) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final name = member.fullName ?? member.userId;
    final muted = member.isMutedAt(DateTime.now());
    final statuses = [
      switch (member.registration) {
        'PENDING' => l10n.chatRoomMemberPending,
        'STAFF' => l10n.chatRoomMemberStaff,
        _ => l10n.chatRoomMemberApproved,
      },
      if (member.online) l10n.chatRoomMemberOnline,
      if (member.kicked) l10n.chatRoomMemberKicked,
      if (muted)
        l10n.chatRoomMemberMutedUntil(formatRoomTime(member.mutedUntil!)),
    ];
    return ListTile(
      leading: _Avatar(name: name, url: member.avatarUrl),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final status in statuses)
            Text(
              status,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
        ],
      ),
      trailing: member.userId == currentUserId
          ? null
          : PopupMenuButton<RoomMemberAction>(
              key: ValueKey('room-member-actions-${member.userId}'),
              onSelected: (action) => onAction(member, action),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: muted
                      ? RoomMemberAction.unmute
                      : RoomMemberAction.mute,
                  child: Text(
                    muted ? l10n.chatRoomUnmuteAction : l10n.chatRoomMuteAction,
                  ),
                ),
                PopupMenuItem(
                  value: member.kicked
                      ? RoomMemberAction.unkick
                      : RoomMemberAction.kick,
                  child: Text(
                    member.kicked
                        ? l10n.chatRoomUnkickAction
                        : l10n.chatKickUserAction,
                  ),
                ),
              ],
            ),
    );
  }
}

/// "Kicked / muted" tab: who was kicked (by whom, when) and who is muted,
/// each with a button to lift it.
class TournamentRoomRestrictedList extends StatelessWidget {
  const TournamentRoomRestrictedList({
    super.key,
    required this.kicks,
    required this.muted,
    required this.onUnkick,
    required this.onUnmute,
  });

  final List<ChatRoomKick> kicks;
  final List<ChatRoomMember> muted;
  final void Function(ChatRoomKick) onUnkick;
  final void Function(ChatRoomMember) onUnmute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (kicks.isEmpty && muted.isEmpty) {
      return Center(child: Text(l10n.chatRoomManageEmpty));
    }
    return ListView(
      children: [
        if (kicks.isNotEmpty) _header(context, l10n.chatRoomKickedSection),
        for (final kick in kicks) _kickTile(context, kick),
        if (muted.isNotEmpty) _header(context, l10n.chatRoomMutedSection),
        for (final member in muted) _mutedTile(context, member),
      ],
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: context.colors.textMuted,
      ),
    ),
  );

  Widget _kickTile(BuildContext context, ChatRoomKick kick) {
    final l10n = AppLocalizations.of(context)!;
    final name = kick.fullName ?? kick.userId;
    final at = kick.kickedAt == null ? '' : formatRoomTime(kick.kickedAt!);
    return ListTile(
      leading: _Avatar(name: name, url: kick.avatarUrl),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        kick.kickedByName != null
            ? l10n.chatRoomKickedBy(kick.kickedByName!, at)
            : l10n.chatRoomKickedAt(at),
      ),
      trailing: TextButton(
        key: ValueKey('room-unkick-${kick.userId}'),
        onPressed: () => onUnkick(kick),
        child: Text(l10n.chatRoomUnkickAction),
      ),
    );
  }

  Widget _mutedTile(BuildContext context, ChatRoomMember member) {
    final l10n = AppLocalizations.of(context)!;
    final name = member.fullName ?? member.userId;
    return ListTile(
      leading: _Avatar(name: name, url: member.avatarUrl),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        l10n.chatRoomMemberMutedUntil(formatRoomTime(member.mutedUntil!)),
      ),
      trailing: TextButton(
        key: ValueKey('room-unmute-${member.userId}'),
        onPressed: () => onUnmute(member),
        child: Text(l10n.chatRoomUnmuteAction),
      ),
    );
  }
}
