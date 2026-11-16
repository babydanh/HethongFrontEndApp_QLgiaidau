import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_chat_moderation.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_chat_repository.dart';
import 'package:app_quanly_giaidau/features/chat/widgets/tournament_room_member_lists.dart';
import 'package:app_quanly_giaidau/features/chat/widgets/tournament_room_settings_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Manage room" for tournament-room moderators (organizer, co-organizer,
/// host-club manager, admin): members, kicked/muted, slow mode and lock.
class TournamentRoomManageSheet extends ConsumerStatefulWidget {
  const TournamentRoomManageSheet({
    super.key,
    required this.roomId,
    required this.slowModeSeconds,
    required this.locked,
    required this.onSettingsChanged,
  });

  final String roomId;
  final int slowModeSeconds;
  final bool locked;
  final void Function(int slowModeSeconds, bool locked) onSettingsChanged;

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    required int slowModeSeconds,
    required bool locked,
    required void Function(int slowModeSeconds, bool locked) onSettingsChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: TournamentRoomManageSheet(
          roomId: roomId,
          slowModeSeconds: slowModeSeconds,
          locked: locked,
          onSettingsChanged: onSettingsChanged,
        ),
      ),
    );
  }

  @override
  ConsumerState<TournamentRoomManageSheet> createState() =>
      _TournamentRoomManageSheetState();
}

class _TournamentRoomManageSheetState
    extends ConsumerState<TournamentRoomManageSheet> {
  List<ChatRoomMember> _members = const [];
  List<ChatRoomKick> _kicks = const [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadFailed = false;
  late int _slowMode = widget.slowModeSeconds;
  late bool _locked = widget.locked;

  ITournamentChatRepository get _repo =>
      ref.read(tournamentChatRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final (page, kicks) = await (
        _repo.listParticipants(widget.roomId),
        _repo.listKicks(widget.roomId),
      ).wait;
      if (!mounted) return;
      setState(() {
        _members = page.items;
        _nextCursor = page.nextCursor;
        _kicks = kicks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null) return;
    try {
      final page = await _repo.listParticipants(widget.roomId, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _members = [..._members, ...page.items];
        _nextCursor = page.nextCursor;
      });
    } catch (_) {
      _snack(AppLocalizations.of(context)!.chatRoomManageLoadError);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Runs one moderation call, then reloads both lists. 403
  /// CANNOT_KICK_ORGANIZER / CANNOT_MUTE_ORGANIZER gets its own message.
  Future<void> _run(Future<void> Function() call, {String? done}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await call();
      if (done != null) _snack(done);
      await _reload();
    } catch (e) {
      final body = e is DioException ? e.response?.data : null;
      final staff =
          body is Map &&
          [body['code'], body['message']].any(
            (v) =>
                v?.toString().contains('CANNOT_KICK_ORGANIZER') == true ||
                v?.toString().contains('CANNOT_MUTE_ORGANIZER') == true,
          );
      _snack(
        staff ? l10n.chatRoomCannotModerateStaff : l10n.chatRoomActionFailed,
      );
    }
  }

  Future<void> _onMemberAction(
    ChatRoomMember member,
    RoomMemberAction action,
  ) async {
    final name = member.fullName ?? member.userId;
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case RoomMemberAction.kick:
        if (await _confirmKick(name) != true) return;
        await _run(
          () => _repo.kickUser(widget.roomId, member.userId),
          done: l10n.chatKickDone(name),
        );
      case RoomMemberAction.unkick:
        await _run(() => _repo.unkickUser(widget.roomId, member.userId));
      case RoomMemberAction.mute:
        final minutes = await _pickMuteMinutes(name);
        if (minutes == null) return;
        await _run(
          () => _repo.muteUser(widget.roomId, member.userId, minutes),
          done: l10n.chatRoomMuteDone(name),
        );
      case RoomMemberAction.unmute:
        await _run(() => _repo.unmuteUser(widget.roomId, member.userId));
    }
  }

  Future<bool?> _confirmKick(String name) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatKickConfirmTitle),
        content: Text(l10n.chatKickConfirmBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.chatDetailCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.chatKickConfirmAction),
          ),
        ],
      ),
    );
  }

  Future<int?> _pickMuteMinutes(String name) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      15: l10n.chatRoomMuteFor15m,
      60: l10n.chatRoomMuteFor1h,
      1440: l10n.chatRoomMuteFor1d,
    };
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.chatRoomMuteTitle(name)),
        children: [
          for (final minutes in kChatMuteMinutes)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, minutes),
              child: Text(labels[minutes]!),
            ),
        ],
      ),
    );
  }

  Future<bool> _saveSettings({int? slowModeSeconds, bool? locked}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _repo.updateSettings(
        widget.roomId,
        slowModeSeconds: slowModeSeconds,
        locked: locked,
      );
      _slowMode = slowModeSeconds ?? _slowMode;
      _locked = locked ?? _locked;
      widget.onSettingsChanged(_slowMode, _locked);
      _snack(l10n.chatRoomSettingsUpdated);
      return true;
    } catch (_) {
      _snack(l10n.chatRoomSettingsUpdateError);
      return false;
    }
  }

  Widget _listsOrStatus(Widget Function() list) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (!_loadFailed) return list();
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.chatRoomManageLoadError),
          TextButton(onPressed: _reload, child: Text(l10n.chatRoomManageRetry)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final me = ref.watch(userProfileProvider).asData?.value.id;
    final now = DateTime.now();
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l10n.chatRoomManageTooltip,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TabBar(
            labelColor: AppTheme.primary,
            tabs: [
              Tab(text: l10n.chatRoomManageTabMembers),
              Tab(text: l10n.chatRoomManageTabRestricted),
              Tab(text: l10n.chatRoomManageTabSettings),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _listsOrStatus(
                  () => TournamentRoomMembersList(
                    members: _members,
                    currentUserId: me,
                    hasMore: _nextCursor != null,
                    onLoadMore: _loadMore,
                    onAction: _onMemberAction,
                  ),
                ),
                _listsOrStatus(
                  () => TournamentRoomRestrictedList(
                    kicks: _kicks,
                    muted: _members.where((m) => m.isMutedAt(now)).toList(),
                    onUnkick: (kick) => _run(
                      () => _repo.unkickUser(widget.roomId, kick.userId),
                    ),
                    onUnmute: (member) => _run(
                      () => _repo.unmuteUser(widget.roomId, member.userId),
                    ),
                  ),
                ),
                TournamentRoomSettingsTab(
                  slowModeSeconds: _slowMode,
                  locked: _locked,
                  onSave: _saveSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
