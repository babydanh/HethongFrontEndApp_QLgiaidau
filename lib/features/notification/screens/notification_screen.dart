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
      bool isAlreadyJoinedOrResolved = false;
      if (e is DioException) {
        final code = e.response?.statusCode;
        if (code == 404 || code == 400 || code == 409) {
          isAlreadyJoinedOrResolved = true;
        }
      }
      final rawError = e.toString().toLowerCase();
      if (rawError.contains('404') ||
          rawError.contains('not found') ||
          rawError.contains('no pending') ||
          rawError.contains('đã tham gia') ||
          rawError.contains('đã được xử lý') ||
          rawError.contains('already')) {
        isAlreadyJoinedOrResolved = true;
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
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    // Lọc notifications theo chế độ chưa đọc và tab phân loại
    final displayedNotifications = stateNotif.notifications.where((n) {
      if (_unreadOnly && n.isRead) return false;
      return _matchesCategory(n);
    }).toList();

    final totalUnread = stateNotif.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: colors.bgDark,
      body: Stack(
        children: [
          // Background subtle top ambient blur / gradient like Image 2
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2979FF).withValues(alpha: 0.16),
                    const Color(0xFF3AB5F6).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildModernAppBar(colors, totalUnread, l10n),
                _buildCategoryTabs(colors, l10n, totalUnread),
                Expanded(
                  child: stateNotif.notifications.isEmpty && stateNotif.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : stateNotif.notifications.isEmpty &&
                            stateNotif.errorMessage != null
                      ? _buildError(stateNotif.errorMessage!, colors, l10n)
                      : stateNotif.notifications.isEmpty
                      ? _buildEmpty(colors, l10n)
                      : displayedNotifications.isEmpty
                      ? _buildFilteredEmpty(colors, l10n)
                      : _buildList(displayedNotifications, colors, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(
    AppColorsExtension colors,
    int totalUnread,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colors.bgCard.withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.border.withValues(alpha: 0.6)),
              ),
            ),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: colors.textPrimary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.notification_title,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (totalUnread > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2979FF),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: Text(
                l10n.notification_readAll,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(
    AppColorsExtension colors,
    AppLocalizations l10n,
    int totalUnread,
  ) {
    final tabs = [
      l10n.notification_all,
      l10n.notification_tabTournaments,
      l10n.notification_tabTeams,
      l10n.notification_tabSystem,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PillFilterTab(
                      label: tabs[i],
                      isSelected: _selectedCategoryTab == i,
                      onTap: () => setState(() => _selectedCategoryTab = i),
                      colors: colors,
                    ),
                  ),
                // Toggle chỉ hiển thị chưa đọc
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => setState(() => _unreadOnly = !_unreadOnly),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _unreadOnly
                            ? const Color(0xFF2979FF).withValues(alpha: 0.15)
                            : colors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _unreadOnly
                              ? const Color(0xFF2979FF)
                              : colors.border.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _unreadOnly ? Icons.mark_chat_unread : Icons.mark_chat_unread_outlined,
                            size: 14,
                            color: _unreadOnly ? const Color(0xFF2979FF) : colors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            totalUnread > 0
                                ? '${l10n.notification_unread} ($totalUnread)'
                                : l10n.notification_unread,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: _unreadOnly ? FontWeight.w700 : FontWeight.w600,
                              color: _unreadOnly
                                  ? const Color(0xFF2979FF)
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors, AppLocalizations l10n) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.notification_emptyTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notification_emptySubtitle,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      );

  Widget _buildFilteredEmpty(
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.done_all_rounded,
          size: 48,
          color: colors.success.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.notification_filteredEmptyTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => setState(() => _unreadOnly = false),
          child: Text(l10n.notification_viewAll),
        ),
      ],
    ),
  );

  Widget _buildError(
    String message,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
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

  Widget _buildList(
    List<AppNotification> notifications,
    AppColorsExtension colors,
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
            _buildMyTournaments(workspaceAsync.asData!.value, colors, l10n),
          for (final entryKey in orderedKeys)
            Builder(
              builder: (context) {
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
              },
            ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  Widget _buildMyTournaments(
    TournamentWorkspace workspace,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final items = <_TournamentWithRole>[];
    for (final t in workspace.organizedTournaments) {
      items.add(
        _TournamentWithRole(
          t,
          l10n.notification_roleBtc,
          const Color(0xFF2979FF),
        ),
      );
    }
    for (final t in workspace.coOrganizerTournaments) {
      if (!items.any((i) => i.tournament.id == t.id)) {
        items.add(
          _TournamentWithRole(
            t,
            l10n.notification_roleBtc,
            const Color(0xFF2979FF),
          ),
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
            const Color(0xFFF59E0B),
          ),
        );
      }
    }
    for (final t in workspace.participatingTournaments) {
      if (!items.any((i) => i.tournament.id == t.id)) {
        items.add(
          _TournamentWithRole(
            t,
            l10n.notification_rolePlayer,
            const Color(0xFF10B981),
          ),
        );
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    items.sort((a, b) {
      final aLite = a.tournament.isClubLite ? 0 : 1;
      final bLite = b.tournament.isClubLite ? 0 : 1;
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
                          if (item.tournament.isClubLite)
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
                          horizontal: 8,
                          vertical: 3,
                        ),
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

  Widget _buildCard(
    AppNotification notif,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? colors.border.withValues(alpha: 0.5)
                : const Color(0xFF2979FF).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular icon container as in Image 2
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: notif.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notif.icon, color: notif.color, size: 22),
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
                                fontSize: 14.5,
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            notif.localizedTimeAgo(l10n),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (notif.body != null && notif.body!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          notif.body!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: colors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Red unread dot or chevron navigation arrow
                if (!notif.isRead) ...[
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEF4444), // red dot as seen in Image 2
                    ),
                  ),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.textMuted.withValues(alpha: 0.6),
                ),
              ],
            ),
            if (isInvite) ...[
              const SizedBox(height: 12),
              if (isHandled) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 5),
                      Text(
                        l10n.notification_inviteHandled,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _handlingInviteIds.contains(notif.id)
                          ? null
                          : () => _handleInviteAction(notif, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textMuted,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        l10n.notification_decline,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _handlingInviteIds.contains(notif.id)
                          ? null
                          : () => _handleInviteAction(notif, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2979FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _handlingInviteIds.contains(notif.id)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.notification_accept,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
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

// ─── Filter Pill Tab Widget ───

class _PillFilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorsExtension colors;

  const _PillFilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2979FF)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2979FF)
                : colors.border.withValues(alpha: 0.7),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

