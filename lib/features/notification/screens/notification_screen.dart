import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
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

  // Category filter: 0 = Tất cả, 1 = Giải đấu, 2 = Đội nhóm, 3 = Hệ thống
  int _selectedCategoryTab = 0;
  // Filter mode: false = Tất cả, true = Chỉ chưa đọc
  bool _unreadOnly = false;
  final Set<String> _handledInviteIds = <String>{};
  final Set<String> _handlingInviteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(notificationStateProvider.notifier).loadPage(1);
      ref.invalidate(myCommunityInvitesProvider);
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

  Future<void> _handleInviteAction(AppNotification notif, bool accept) async {
    if (_handlingInviteIds.contains(notif.id)) return;
    setState(() => _handlingInviteIds.add(notif.id));

    final l10n = AppLocalizations.of(context)!;
    try {
      if (notif.type == 'CLUB_INVITE' || notif.type == 'COMMUNITY_INVITED') {
        final communityId = notif.communityId;
        if (communityId == null || communityId.isEmpty) {
          throw StateError(l10n.notification_missingCommunityId);
        }
        await ref
            .read(communityRepositoryProvider)
            .respondToInvite(communityId, accept ? 'accept' : 'decline');
        ref.invalidate(myCommunityInvitesProvider);
        ref.invalidate(communityDetailProvider(communityId));
      } else if (notif.isFootballTeamInvite) {
        final teamId = notif.footballTeamId;
        if (teamId == null || teamId.isEmpty) {
          throw StateError(l10n.notification_missingTeamId);
        }
        await ref
            .read(footballTeamApiProvider)
            .respondToFootballTeamInvite(
              teamId,
              accept ? 'ACCEPTED' : 'DECLINED',
            );
      } else if (notif.isRefereeInvite) {
        final uri = Uri.tryParse(notif.redirectUrl ?? '');
        final tournamentId = uri?.queryParameters['tournamentId'];
        final refereeId = uri?.queryParameters['refereeId'];
        if (tournamentId == null || refereeId == null) {
          throw StateError(l10n.notification_missingRefereeInfo);
        }
        await ref
            .read(myTournamentWorkspaceProvider.notifier)
            .respondToRefereeInvite(
              tournamentId: tournamentId,
              refereeId: refereeId,
              action: accept ? 'ACCEPT' : 'DECLINE',
            );
      } else if (notif.type == 'PARTNER_INVITE_RECEIVED') {
        final uri = Uri.tryParse(notif.redirectUrl ?? '');
        final segments = uri?.pathSegments ?? const <String>[];
        final participantIndex = segments.indexOf('participants');
        final participantId =
            participantIndex >= 0 && participantIndex + 1 < segments.length
            ? segments[participantIndex + 1]
            : null;
        if (participantId == null || participantId.isEmpty) {
          throw StateError(l10n.notification_missingParticipantId);
        }
        await ref
            .read(dioProvider)
            .post(
              '/tournaments/participants/$participantId/${accept ? 'accept-partner' : 'reject-partner'}',
            );
      } else {
        throw StateError(l10n.notification_unsupportedInviteType);
      }
      await ref.read(notificationStateProvider.notifier).markAsRead(notif.id);
      if (mounted) {
        setState(() => _handledInviteIds.add(notif.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? l10n.notification_inviteAccepted
                  : l10n.notification_inviteDeclined,
            ),
            backgroundColor: accept
                ? const Color(0xFF059669)
                : context.colors.textSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi xử lý lời mời', e, stack);
      // Chỉ 404 (không còn lời mời) và 409 (đã xử lý) là "đã xử lý"; 400 là
      // lỗi thật của yêu cầu nên phải hiện cho người dùng.
      var isAlreadyJoinedOrResolved = false;
      if (e is DioException) {
        final code = e.response?.statusCode;
        isAlreadyJoinedOrResolved = code == 404 || code == 409;
      } else {
        final rawError = e.toString().toLowerCase();
        isAlreadyJoinedOrResolved =
            rawError.contains('not found') ||
            rawError.contains('no pending') ||
            rawError.contains('đã tham gia') ||
            rawError.contains('đã được xử lý') ||
            rawError.contains('already');
      }

      if (isAlreadyJoinedOrResolved) {
        await ref.read(notificationStateProvider.notifier).markAsRead(notif.id);
        if (mounted) {
          setState(() => _handledInviteIds.add(notif.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                accept
                    ? (notif.isFootballTeamInvite
                          ? l10n.notification_alreadyTeamMember
                          : l10n.notification_alreadyClubMember)
                    : l10n.notification_inviteAlreadyHandled,
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          final cleanMsg = e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('StateError: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${accept ? l10n.notification_acceptError : l10n.notification_declineError} $cleanMsg',
              ),
              backgroundColor: context.colors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _handlingInviteIds.remove(notif.id));
      }
    }
  }

  bool _matchesCategory(AppNotification n) {
    if (_selectedCategoryTab == 0) return true;
    final t = n.type.toUpperCase();
    if (_selectedCategoryTab == 1) {
      // Giải đấu & Trận đấu
      return t.startsWith('TOURNAMENT') ||
          t.startsWith('MATCH') ||
          t.contains('REFEREE') ||
          t.contains('DOUBLES') ||
          t.contains('PARTNER');
    } else if (_selectedCategoryTab == 2) {
      // Đội nhóm & CLB / Cộng đồng
      return t.startsWith('CLUB') ||
          t.startsWith('COMMUNITY') ||
          t.startsWith('FOOTBALL_TEAM');
    } else {
      // Hệ thống, thanh toán, nhắc nhở, chat
      return t.startsWith('SYSTEM') ||
          t.startsWith('GENERAL') ||
          t.startsWith('PAYMENT') ||
          t.startsWith('PAYOUT') ||
          t.startsWith('CHAT') ||
          t.startsWith('REMINDER');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateNotif = ref.watch(notificationStateProvider);
    final l10n = AppLocalizations.of(context)!;

    // Lọc notifications theo chế độ chưa đọc và tab phân loại
    final displayedNotifications = stateNotif.notifications.where((n) {
      if (_unreadOnly && n.isRead) return false;
      return _matchesCategory(n);
    }).toList();

    final totalUnread = stateNotif.notifications.where((n) => !n.isRead).length;
    final all = stateNotif.notifications;

    final Widget content;
    if (all.isEmpty && stateNotif.isLoading) {
      content = const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: LavishRowSkeleton(count: 8),
      );
    } else if (all.isEmpty && stateNotif.errorMessage != null) {
      content = LavishErrorState(
        message: stateNotif.errorMessage,
        onRetry: () => ref.read(notificationStateProvider.notifier).loadPage(1),
      );
    } else if (all.isEmpty) {
      content = LavishEmptyState(
        icon: Icons.notifications_none_rounded,
        title: l10n.notification_emptyTitle,
      );
    } else if (displayedNotifications.isEmpty) {
      content = LavishEmptyState(
        icon: Icons.done_all_rounded,
        title: l10n.notification_filteredEmptyTitle,
        action: l10n.notification_viewAll,
        onAction: () => setState(() {
          _unreadOnly = false;
          _selectedCategoryTab = 0;
        }),
      );
    } else {
      content = _buildList(displayedNotifications, l10n);
    }

    return LavishScaffold(
      title: l10n.notification_title,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      actions: [
        if (totalUnread > 0)
          IconButton(
            tooltip: l10n.notification_readAll,
            icon: const Icon(Icons.done_all_rounded),
            onPressed: _markAllAsRead,
          ),
      ],
      body: Column(
        children: [
          _buildFilterChips(l10n, totalUnread),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n, int totalUnread) {
    final tabs = [
      l10n.notification_all,
      l10n.notification_tabTournaments,
      l10n.notification_tabTeams,
      l10n.notification_tabSystem,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            LavishChipButton(
              label: tabs[i],
              selected: _selectedCategoryTab == i,
              onPressed: () => setState(() => _selectedCategoryTab = i),
            ),
            const SizedBox(width: 8),
          ],
          LavishChipButton(
            label: totalUnread > 0
                ? '${l10n.notification_unread} ($totalUnread)'
                : l10n.notification_unread,
            selected: _unreadOnly,
            onPressed: () => setState(() => _unreadOnly = !_unreadOnly),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<AppNotification> notifications,
    AppLocalizations l10n,
  ) {
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
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (hasWorkspace)
            ..._buildMyTournaments(workspaceAsync.asData!.value, l10n),
          for (final key in orderedKeys) ...[
            LavishGroupHeader(key),
            for (final n in grouped[key]!) _buildCard(n, l10n),
          ],
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMyTournaments(
    TournamentWorkspace workspace,
    AppLocalizations l10n,
  ) {
    final items = <_TournamentWithRole>[];
    for (final t in workspace.organizedTournaments) {
      items.add(
        _TournamentWithRole(t, l10n.notification_roleBtc, LavishTone.accent),
      );
    }
    for (final t in workspace.coOrganizerTournaments) {
      if (!items.any((i) => i.tournament.id == t.id)) {
        items.add(
          _TournamentWithRole(t, l10n.notification_roleBtc, LavishTone.accent),
        );
      }
    }
    for (final refInvite in workspace.refereeTournaments) {
      Tournament? t = workspace.organizedTournaments
          .where((ot) => ot.id == refInvite.tournamentId)
          .firstOrNull;
      t ??= workspace.participatingTournaments
          .where((pt) => pt.id == refInvite.tournamentId)
          .firstOrNull;
      if (t != null && !items.any((i) => i.tournament.id == t!.id)) {
        items.add(
          _TournamentWithRole(
            t,
            l10n.notification_roleReferee,
            LavishTone.warn,
          ),
        );
      }
    }
    for (final t in workspace.participatingTournaments) {
      if (!items.any((i) => i.tournament.id == t.id)) {
        items.add(
          _TournamentWithRole(t, l10n.notification_rolePlayer, LavishTone.ok),
        );
      }
    }
    if (items.isEmpty) return const [];

    items.sort((a, b) {
      final aLite = a.tournament.isClubLite ? 0 : 1;
      final bLite = b.tournament.isClubLite ? 0 : 1;
      if (aLite != bLite) return aLite.compareTo(bLite);
      return a.tournament.name.compareTo(b.tournament.name);
    });

    return [
      LavishGroupHeader(l10n.infoMyTournaments),
      for (final item in items.take(3))
        LavishRow(
          title: item.tournament.name,
          leading: LavishIconBox(
            tone: item.tone,
            child: Icon(
              item.tournament.isClubLite
                  ? Icons.bolt_rounded
                  : Icons.emoji_events_rounded,
            ),
          ),
          trailing: [LavishPill(item.role, tone: item.tone)],
          onTap: () => context.push('/intro/${item.tournament.id}'),
        ),
    ];
  }

  LavishTone _toneOf(AppNotification n) {
    final c = n.color.toARGB32();
    return switch (c) {
      0xFFF59E0B => LavishTone.warn,
      0xFF10B981 || 0xFF059669 => LavishTone.ok,
      0xFFEF4444 => LavishTone.bad,
      0xFF64748B => LavishTone.neutral,
      _ => LavishTone.accent,
    };
  }

  Widget _buildCard(AppNotification notif, AppLocalizations l10n) {
    final c = LavishColors.of(context);
    final isInvite = notif.isInvite;
    final pendingInvitesAsync = ref.watch(myCommunityInvitesProvider);
    final pendingCommunityIds = pendingInvitesAsync.asData?.value
        .map((inv) => inv.communityId)
        .toSet();

    final isCommunityInvite =
        notif.type == 'CLUB_INVITE' || notif.type == 'COMMUNITY_INVITED';
    final isHandled =
        _handledInviteIds.contains(notif.id) ||
        (isCommunityInvite &&
            pendingCommunityIds != null &&
            notif.communityId != null &&
            !pendingCommunityIds.contains(notif.communityId));
    final handling = _handlingInviteIds.contains(notif.id);
    final background = notif.isRead
        ? null
        : LavishColors.accent.withValues(alpha: c.dark ? 0.10 : 0.06);
    final body = notif.body;

    final row = LavishRow(
      title: notif.title,
      subtitle: body != null && body.isNotEmpty ? body : null,
      subtitleMaxLines: 2,
      background: background,
      leading: LavishIconBox(tone: _toneOf(notif), child: Icon(notif.icon)),
      trailing: [
        Text(
          notif.localizedTimeAgo(l10n),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.faint,
          ),
        ),
        if (!notif.isRead)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: LavishColors.accent,
            ),
          ),
      ],
      onTap: () async {
        if (!notif.isRead) {
          try {
            await ref
                .read(notificationStateProvider.notifier)
                .markAsRead(notif.id);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.notification_updateStatusError)),
              );
            }
          }
        }
        if (!mounted) return;
        if (notif.isRefereeInvite) return;
        final route = notif.routeTarget;
        if (route != null) context.push(route);
      },
    );
    if (!isInvite) return row;

    return Column(
      children: [
        row,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            color: background,
            border: Border(bottom: BorderSide(color: c.rowLine)),
          ),
          child: isHandled
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: LavishPill(
                    l10n.notification_inviteHandled,
                    tone: LavishTone.ok,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LavishButton(
                      label: l10n.notification_decline,
                      kind: LavishButtonKind.outline,
                      dense: true,
                      onPressed: handling
                          ? null
                          : () => _handleInviteAction(notif, false),
                    ),
                    const SizedBox(width: 8),
                    LavishButton(
                      label: l10n.notification_accept,
                      dense: true,
                      busy: handling,
                      onPressed: handling
                          ? null
                          : () => _handleInviteAction(notif, true),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TournamentWithRole {
  final Tournament tournament;
  final String role;
  final LavishTone tone;

  const _TournamentWithRole(this.tournament, this.role, this.tone);
}
