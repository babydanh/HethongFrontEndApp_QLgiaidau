import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});
  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  static const _log = AppLogger('NotificationScreen');
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // Filter mode: false = Tất cả, true = Chưa đọc
  bool _unreadOnly = false;
  final Set<String> _handledInviteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(notificationStateProvider.notifier).loadPage(1);
      // Đồng bộ lại badge số chưa đọc mỗi lần mở màn hình thông báo.
      ref.invalidate(unreadCountProvider);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final s = ref.read(notificationStateProvider);
      if (s.hasMore && !_isLoadingMore) {
        _isLoadingMore = true;
        ref
            .read(notificationStateProvider.notifier)
            .loadPage(s.currentPage + 1)
            .then((_) {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ref.read(notificationStateProvider.notifier).markAllAsRead();
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notification_markAllReadError)),
      );
    }
  }

  Future<void> _handleInviteAction(
      AppNotification notif, bool accept) async {
    try {
      if (notif.type == 'CLUB_INVITE' || notif.type == 'COMMUNITY_INVITED') {
        final communityId = notif.communityId;
        if (communityId == null || communityId.isEmpty) {
          throw StateError('Lời mời không có mã cộng đồng.');
        }
        // Community invitations are actions on the community resource, not
        // generic notification actions.
        await ref.read(communityRepositoryProvider).respondToInvite(
              communityId,
              accept ? 'accept' : 'decline',
            );
      } else {
        throw StateError('Loại lời mời này chưa có thao tác tương ứng.');
      }
      await ref.read(notificationStateProvider.notifier).markAsRead(notif.id);
      if (mounted) setState(() => _handledInviteIds.add(notif.id));
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? l10n.notification_inviteAccepted : l10n.notification_inviteDeclined),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi xử lý lời mời', e, stack);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? l10n.notification_acceptError : l10n.notification_declineError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateNotif = ref.watch(notificationStateProvider);
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    // Lọc notifications theo chế độ
    final displayedNotifications = _unreadOnly
        ? stateNotif.notifications.where((n) => !n.isRead).toList()
        : stateNotif.notifications;

    final totalUnread = stateNotif.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.notification_title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          if (totalUnread > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                l10n.notification_readAll,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(colors, totalUnread, l10n),
          Expanded(
            child: stateNotif.notifications.isEmpty && stateNotif.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stateNotif.notifications.isEmpty && stateNotif.errorMessage != null
                    ? _buildError(stateNotif.errorMessage!, colors, l10n)
                    : stateNotif.notifications.isEmpty
                        ? _buildEmpty(colors, l10n)
                        : displayedNotifications.isEmpty
                            ? _buildFilteredEmpty(colors, l10n)
                            : _buildList(displayedNotifications, colors, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppColorsExtension colors, int totalUnread, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgDark,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          _FilterSegment(
            label: l10n.notification_all,
            isActive: !_unreadOnly,
            colors: colors,
            onTap: () => setState(() => _unreadOnly = false),
          ),
          const SizedBox(width: 8),
          _FilterSegment(
            label: totalUnread > 0 ? '${l10n.notification_unread} ($totalUnread)' : l10n.notification_unread,
            isActive: _unreadOnly,
            colors: colors,
            count: totalUnread,
            onTap: () => setState(() => _unreadOnly = true),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors, AppLocalizations l10n) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              l10n.notification_emptyTitle,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notification_emptySubtitle,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      );

  Widget _buildFilteredEmpty(AppColorsExtension colors, AppLocalizations l10n) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all_rounded, size: 48, color: colors.success.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              l10n.notification_filteredEmptyTitle,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => setState(() => _unreadOnly = false),
              child: Text(l10n.notification_viewAll),
            ),
          ],
        ),
      );

  Widget _buildError(String message, AppColorsExtension colors, AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(notificationStateProvider.notifier).loadPage(1),
                child: Text(l10n.infoRetry),
              ),
            ],
          ),
        ),
      );

  Widget _buildList(List<AppNotification> notifications, AppColorsExtension colors, AppLocalizations l10n) {
    final workspaceAsync = ref.watch(myTournamentWorkspaceProvider);

    final grouped = <String, List<AppNotification>>{};
    final now = DateTime.now();
    final todayLabel = l10n.notification_today;
    final yesterdayLabel = l10n.notification_yesterday;
    final thisWeekLabel = l10n.notification_thisWeek;
    for (final n in notifications) {
      final diff = now.difference(n.createdAt);
      final key = diff.inDays == 0
          ? todayLabel
          : diff.inDays == 1
              ? yesterdayLabel
              : diff.inDays < 7
                  ? thisWeekLabel
                  : '${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}';
      grouped.putIfAbsent(key, () => []).add(n);
    }

    // Sort groups by date key
    final orderedKeys = <String>[];
    if (grouped.containsKey(todayLabel)) orderedKeys.add(todayLabel);
    if (grouped.containsKey(yesterdayLabel)) orderedKeys.add(yesterdayLabel);
    if (grouped.containsKey(thisWeekLabel)) orderedKeys.add(thisWeekLabel);
    for (final k in grouped.keys) {
      if (!orderedKeys.contains(k)) orderedKeys.add(k);
    }

    final hasWorkspace = workspaceAsync.asData?.value.hasAnyData ?? false;

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationStateProvider.notifier).loadPage(1),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (hasWorkspace)
            _buildMyTournaments(
              workspaceAsync.asData!.value,
              colors,
              l10n,
            ),
          for (final entryKey in orderedKeys)
            Builder(builder: (context) {
              final items = grouped[entryKey]!;
              return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  entryKey,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              ...items.map((n) => _buildCard(n, colors, l10n)),
            ],
          );
            }),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  Widget _buildMyTournaments(TournamentWorkspace workspace, AppColorsExtension colors, AppLocalizations l10n) {
    final items = <_TournamentWithRole>[];
    for (final t in workspace.organizedTournaments) {
      items.add(_TournamentWithRole(t, l10n.notification_roleBtc, const Color(0xFF2979FF)));
    }
    for (final t in workspace.coOrganizerTournaments) {
      items.add(_TournamentWithRole(t, l10n.notification_roleBtc, const Color(0xFF2979FF)));
    }
    for (final refInvite in workspace.refereeTournaments) {
      Tournament? t = workspace.organizedTournaments
          .where((ot) => ot.id == refInvite.tournamentId).firstOrNull;
      t ??= workspace.participatingTournaments
          .where((pt) => pt.id == refInvite.tournamentId).firstOrNull;
      if (t != null && !items.any((i) => i.tournament.id == t!.id)) {
        items.add(_TournamentWithRole(t, l10n.notification_roleReferee, const Color(0xFFF59E0B)));
      }
    }
    for (final t in workspace.participatingTournaments) {
      if (!items.any((i) => i.tournament.id == t.id)) {
        items.add(_TournamentWithRole(t, l10n.notification_rolePlayer, const Color(0xFF10B981)));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    items.sort((a, b) {
      final aLite = a.tournament.isLite ? 0 : 1;
      final bLite = b.tournament.isLite ? 0 : 1;
      if (aLite != bLite) return aLite.compareTo(bLite);
      return a.tournament.name.compareTo(b.tournament.name);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            l10n.infoMyTournaments,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final item = items[i];
              return GestureDetector(
                onTap: () => context.push('/intro/${item.tournament.id}'),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.tournament.isLite)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: colors.warning,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.tournament.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.roleColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.role,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: item.roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AppNotification notif, AppColorsExtension colors, AppLocalizations l10n) {
    final isInvite = notif.isInvite;

    return GestureDetector(
      onTap: () async {
        if (!notif.isRead) {
          try {
            await ref
                .read(notificationStateProvider.notifier)
                .markAsRead(notif.id);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(l10n.notification_updateStatusError)),
              );
            }
          }
        }
        if (!mounted) return;
        if (notif.isRefereeInvite) return;
        final route = notif.routeTarget;
        if (route != null) context.push(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notif.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(notif.icon, color: notif.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2979FF),
                              ),
                            ),
                        ],
                      ),
                      if (notif.body != null && notif.body!.isNotEmpty)
                        ...[
                          const SizedBox(height: 4),
                          Text(
                            notif.body!,
                            style: TextStyle(
                                fontSize: 12, color: colors.textSecondary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      const SizedBox(height: 4),
                      Text(
                        notif.timeAgo,
                        style: TextStyle(
                            fontSize: 11, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isInvite && !_handledInviteIds.contains(notif.id)) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleInviteAction(notif, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textMuted,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(l10n.notification_decline,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _handleInviteAction(notif, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(l10n.notification_accept,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── _TournamentWithRole Helper ───

class _TournamentWithRole {
  final Tournament tournament;
  final String role;
  final Color roleColor;

  const _TournamentWithRole(this.tournament, this.role, this.roleColor);
}

// ─── Filter Segment Widget ───

class _FilterSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final AppColorsExtension colors;
  final int? count;
  final VoidCallback onTap;

  const _FilterSegment({
    required this.label,
    required this.isActive,
    required this.colors,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2979FF).withValues(alpha: 0.12)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF2979FF).withValues(alpha: 0.4)
                : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              size: 16,
              color: isActive
                  ? const Color(0xFF2979FF)
                  : colors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF2979FF)
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
