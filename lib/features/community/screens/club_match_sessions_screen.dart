import 'dart:async';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_session_create_screen.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_dialog.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

String _localizedSessionStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'OPEN' => l10n.clubMatchSessionStatusOpen,
      'LIVE' => l10n.clubMatchSessionStatusLive,
      'CLOSED' => l10n.clubMatchSessionStatusClosed,
      'ENDED' => l10n.clubMatchSessionStatusEnded,
      'CANCELLED' => l10n.clubMatchSessionStatusCancelled,
      _ => l10n.clubMatchSessionStatusUnknown,
    };

String _localizedEloStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'WAITING_RESULT' => l10n.clubMatchSessionEloWaiting,
      'PENDING' => l10n.clubMatchSessionEloPending,
      'NOT_RANKED' => l10n.clubMatchSessionEloNotRanked,
      'SKIPPED_MOCK' => l10n.clubMatchSessionEloSkippedMock,
      'SKIPPED_CANCELLED' => l10n.clubMatchSessionEloSkippedCancelled,
      'APPLIED' => l10n.clubMatchSessionEloApplied,
      'FAILED_RETRYABLE' => l10n.clubMatchSessionEloRetry,
      'FAILED_TERMINAL' => l10n.clubMatchSessionEloFailed,
      _ => l10n.clubMatchSessionStatusUnknown,
    };

class ClubMatchSessionsScreen extends ConsumerStatefulWidget {
  final String communityId;
  const ClubMatchSessionsScreen({super.key, required this.communityId});

  @override
  ConsumerState<ClubMatchSessionsScreen> createState() =>
      _ClubMatchSessionsScreenState();
}

class _ClubMatchSessionsScreenState
    extends ConsumerState<ClubMatchSessionsScreen> {
  StreamSubscription<Map<String, dynamic>>? _matchSubscription;
  String? _openSessionId;

  @override
  void dispose() {
    _matchSubscription?.cancel();
    if (_openSessionId != null) {
      ref
          .read(matchSocketServiceProvider)
          .leaveClubMatchSession(_openSessionId!);
    }
    super.dispose();
  }

  Future<void> _showCreateDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ClubMatchSessionCreateScreen(communityId: widget.communityId),
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.clubMatchSessionCreated)));
    }
  }

  Future<void> _openSession(ClubMatchSessionModel session) async {
    final socket = ref.read(matchSocketServiceProvider);
    _openSessionId = session.id;
    await socket.connect(null, joinMatch: false);
    socket.joinClubMatchSession(session.id);
    await _matchSubscription?.cancel();
    _matchSubscription = socket.onTournamentMatchUpdate.listen((event) {
      if (event['clubMatchSessionId'] == session.id) {
        ref.invalidate(clubSessionDetailProvider(session.id));
      }
    });
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClubMatchSessionDetailPage(session: session),
      ),
    );
    socket.leaveClubMatchSession(session.id);
    _openSessionId = null;
    await _matchSubscription?.cancel();
    _matchSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessions = ref.watch(clubMatchSessionsProvider(widget.communityId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clubMatchSessionTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.clubMatchSessionCreate),
      ),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton.tonal(
            onPressed: () => ref
                .read(clubMatchSessionsProvider(widget.communityId).notifier)
                .refresh(),
            child: Text(l10n.infoRetry),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref
              .read(clubMatchSessionsProvider(widget.communityId).notifier)
              .refresh(),
          child: items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 160),
                    Icon(
                      Icons.sports_tennis_rounded,
                      size: 52,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Center(child: Text(l10n.clubMatchSessionEmpty)),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final session = items[index];
                    final colors = context.colors;

                    final (
                      badgeBg,
                      badgeTextColor,
                      statusDotColor,
                    ) = switch (session.status) {
                      'OPEN' => (
                        const Color(0xFF10B981).withValues(alpha: 0.12),
                        const Color(0xFF059669),
                        const Color(0xFF10B981),
                      ),
                      'LIVE' => (
                        const Color(0xFFEF4444).withValues(alpha: 0.12),
                        const Color(0xFFDC2626),
                        const Color(0xFFEF4444),
                      ),
                      'CLOSED' => (
                        const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        const Color(0xFFD97706),
                        const Color(0xFFF59E0B),
                      ),
                      'ENDED' => (
                        colors.bgSurface,
                        colors.textMuted,
                        colors.textMuted,
                      ),
                      'CANCELLED' => (
                        colors.bgSurface,
                        colors.textMuted,
                        colors.textMuted,
                      ),
                      _ => (
                        colors.bgSurface,
                        colors.textMuted,
                        colors.textMuted,
                      ),
                    };

                    return InkWell(
                      onTap: () => _openSession(session),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.sports_tennis_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.resolvedName,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: session.isRanked
                                                  ? const Color(
                                                      0xFF3B82F6,
                                                    ).withValues(alpha: 0.10)
                                                  : colors.bgSurface,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.insights_rounded,
                                                  size: 13,
                                                  color: session.isRanked
                                                      ? const Color(0xFF2563EB)
                                                      : colors.textMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  session.isRanked
                                                      ? l10n.clubMatchSessionRankedShort
                                                      : l10n.clubMatchSessionUnrankedShort,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: session.isRanked
                                                        ? const Color(
                                                            0xFF2563EB,
                                                          )
                                                        : colors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (session.startAt != null) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 13,
                                              color: colors.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${session.startAt!.day}/${session.startAt!.month} ${session.startAt!.hour.toString().padLeft(2, '0')}:${session.startAt!.minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: statusDotColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _localizedSessionStatus(
                                          l10n,
                                          session.status,
                                        ),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: badgeTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              color: colors.border.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline_rounded,
                                      size: 15,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${session.participantCount ?? 0}/${session.maxParticipants} người tham gia',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    if (session.matchCount != null &&
                                        session.matchCount! > 0) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.sports_rounded,
                                        size: 15,
                                        color: colors.textSecondary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${session.matchCount} trận',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Chi tiết',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.info,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: colors.info,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class ClubMatchSessionDetailPage extends ConsumerStatefulWidget {
  final ClubMatchSessionModel session;
  const ClubMatchSessionDetailPage({super.key, required this.session});

  @override
  ConsumerState<ClubMatchSessionDetailPage> createState() =>
      _ClubMatchSessionDetailPageState();
}

class _ClubMatchSessionDetailPageState
    extends ConsumerState<ClubMatchSessionDetailPage> {
  StreamSubscription<Map<String, dynamic>>? _sessionMatchSubscription;
  Timer? _sessionRefreshTimer;
  bool _sessionRefreshScheduled = false;
  int _currentPage = 1;
  static const int _slotsPerPage = 16;
  static const List<Color> _kSlotAvatarColors = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFF43F5E),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
  ];

  Color _getColorByName(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return _kSlotAvatarColors[hash.abs() % _kSlotAvatarColors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  ClubMatchSessionModel get session => widget.session;

  @override
  void initState() {
    super.initState();
    unawaited(_connectSessionSocket());
  }

  Future<void> _connectSessionSocket() async {
    final socket = ref.read(matchSocketServiceProvider);
    await socket.connect(null, joinMatch: false);
    if (!mounted) return;

    // This page can be opened directly from the club feed/detail page, where
    // the list screen is not alive to own the session room subscription.
    // Subscribe before joining so the first score event cannot be missed.
    _sessionMatchSubscription = socket.onTournamentMatchUpdate.listen((event) {
      final eventSessionId = (event['clubMatchSessionId'] ?? event['sessionId'])
          ?.toString();
      if (eventSessionId != session.id) return;
      _scheduleSessionRefresh();
    });
    socket.joinClubMatchSession(session.id);
  }

  void _scheduleSessionRefresh() {
    _sessionRefreshTimer?.cancel();
    _sessionRefreshTimer = Timer(const Duration(milliseconds: 80), () {
      _scheduleSessionDetailRefresh();
    });
  }

  /// Refresh after the current route/menu frame has finished its teardown.
  ///
  /// Invalidating while a PopupMenu/Dialog is still being removed can make
  /// the tab tree deactivate while DefaultTabController still has dependents.
  void _scheduleSessionDetailRefresh() {
    if (!mounted || _sessionRefreshScheduled) return;
    _sessionRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionRefreshScheduled = false;
      if (mounted) ref.invalidate(clubSessionDetailProvider(session.id));
    });
  }

  @override
  void dispose() {
    _sessionMatchSubscription?.cancel();
    _sessionRefreshTimer?.cancel();
    ref.read(matchSocketServiceProvider).leaveClubMatchSession(session.id);
    super.dispose();
  }

  Future<void> _mutation(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String success,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await action();
      _scheduleSessionDetailRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 409) {
        _scheduleSessionDetailRefresh();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorParser.parse(error, '', l10n))),
        );
      }
    }
  }

  Future<void> _createMatch(
    BuildContext context,
    WidgetRef ref,
    List<ClubMatchParticipantModel> participants,
  ) async {
    await ClubStandaloneMatchDialog.show(
      context,
      communityId: session.communityId,
      sessionId: session.id,
      onMatchCreated: () => _scheduleSessionDetailRefresh(),
    );
  }

  Future<void> _forceParticipants(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final members = await ref.read(
      communityMembersProvider(session.communityId).future,
    );
    if (!context.mounted) return;
    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.clubMatchSessionAssignMembers),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: members
                    .where((member) => member.status == 'JOINED')
                    .map(
                      (member) => CheckboxListTile(
                        value: selected.contains(member.userId),
                        title: Text(
                          member.userFullName ??
                              l10n.clubMatchSessionUnnamedMember,
                        ),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            selected.add(member.userId);
                          } else {
                            selected.remove(member.userId);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text(l10n.clubMatchSessionAssign),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _mutation(
      context,
      ref,
      () => ref
          .read(clubMatchSessionRepositoryProvider)
          .forceParticipants(session.id, selected.toList(), const Uuid().v4()),
      l10n.clubMatchSessionAssigned,
    );
  }

  Future<void> _createMockParticipant(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clubMatchSessionCreateMock),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 255,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: l10n.clubMatchSessionMockNameHint,
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.clubMatchSessionCreateMock),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !context.mounted) return;
    await _mutation(
      context,
      ref,
      () => ref
          .read(clubMatchSessionRepositoryProvider)
          .createMockParticipant(session.id, name),
      l10n.clubMatchSessionMockCreated,
    );
  }

  Future<void> _removeParticipant(
    BuildContext context,
    WidgetRef ref,
    ClubMatchParticipantModel participant,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.clubMatchSessionRemoveParticipantConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clubMatchSessionRemoveParticipant),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _mutation(
      context,
      ref,
      () => ref
          .read(clubMatchSessionRepositoryProvider)
          .removeParticipant(
            session.id,
            participant.userId,
            participant.version,
          ),
      l10n.clubMatchSessionParticipantRemoved,
    );
  }

  Future<void> _transition(
    BuildContext context,
    WidgetRef ref,
    String action,
    ClubMatchSessionModel currentSession,
  ) => _mutation(
    context,
    ref,
    () => ref
        .read(clubMatchSessionRepositoryProvider)
        .transition(session.id, action, currentSession.version),
    AppLocalizations.of(context)!.clubMatchSessionStatusUpdated,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(clubSessionDetailProvider(session.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(session.resolvedName),
        actions: [
          IconButton(
            tooltip: l10n.share,
            onPressed: () => AppShareModal.show(
              context: context,
              title: session.resolvedName,
              subtitle: l10n.clubMatchSessionTitle,
              webUrl:
                  '${AppConstants.appDomain}/communities/${session.communityId}/match-sessions/${session.id}',
            ),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: l10n.infoRetry,
            onPressed: _scheduleSessionDetailRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: detail.when(
          // Keep the existing tab tree mounted during a refresh. This avoids
          // tearing down DefaultTabController between the API response and
          // the next frame after creating a mock participant.
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.clubMatchSessionLoadFailed)),
          data: (value) => _buildDetailTabs(context, ref, value),
        ),
      ),
    );
  }

  Widget _buildDetailTabs(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Material(
          color: context.colors.bgCard,
          child: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.organizer_tabOverview),
              Tab(text: l10n.clubMatchSessionParticipants),
              Tab(text: l10n.clubMatchSessionMatches),
              Tab(text: l10n.club_statsSection),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _buildOverviewTab(context, ref, value),
              _buildParticipantsTab(context, ref, value),
              _buildMatchesTab(context, ref, value),
              _buildStatsTab(context, ref, value),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    final currentSession = value.session;
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    // Active participants
    final activeParticipants = value.participants
        .where((p) => p.status == 'ACTIVE')
        .toList();
    final totalSlots = max(
      currentSession.maxParticipants,
      activeParticipants.length,
    );
    final totalPages = max(1, (totalSlots / _slotsPerPage).ceil());
    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * _slotsPerPage;
    final endIndex = min(startIndex + _slotsPerPage, totalSlots);

    // Check viewer slot and page
    final currentUserId = currentSession.viewerUserId ?? '';
    final userSlotIndex = currentUserId.isNotEmpty
        ? activeParticipants.indexWhere((p) => p.userId == currentUserId)
        : -1;
    final userPage = userSlotIndex >= 0
        ? (userSlotIndex ~/ _slotsPerPage) + 1
        : null;

    // Date/time formatting
    String dateRangeStr = 'Chưa cập nhật thời gian';
    if (currentSession.startAt != null) {
      final start = currentSession.startAt!;
      final dateStr = DateFormat('dd/MM/yyyy').format(start);
      final hour = start.hour;
      final minute = start.minute;
      final timeStr = (hour != 0 || minute != 0)
          ? ' · ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
          : '';
      String durationStr = '';
      if (currentSession.endAt != null &&
          currentSession.endAt!.isAfter(start)) {
        final diffMinutes = currentSession.endAt!.difference(start).inMinutes;
        if (diffMinutes > 0 && diffMinutes < 24 * 60) {
          final h = diffMinutes ~/ 60;
          final m = diffMinutes % 60;
          durationStr = h > 0
              ? (m > 0 ? ' (${h}h${m}p)' : ' (${h}h)')
              : ' (${m}p)';
        }
      }
      dateRangeStr = '$dateStr$timeStr$durationStr';
    }

    // Format badge text
    final formatBadge = switch (currentSession.registrationMode.toUpperCase()) {
      'PAIR' => 'Đánh đôi',
      'SINGLE' => 'Đánh đơn',
      _ => 'Ghép tự do',
    };

    return _refreshableTab(
      context,
      ref,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          // ─── 1. THẺ TỔNG QUAN PHONG CÁCH SIÊU LITE ───
          Container(
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Sport badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        '🏓 Buổi giao lưu',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    // Format badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        formatBadge,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: currentSession.status == 'OPEN'
                            ? const Color(0xFF10B981)
                            : currentSession.status == 'LIVE'
                            ? const Color(0xFFEF4444)
                            : colors.textMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _localizedSessionStatus(l10n, currentSession.status),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // ELO Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: currentSession.isRanked
                            ? const Color(0xFFF59E0B)
                            : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentSession.isRanked ? '★ ELO' : 'Phong trào',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tiêu đề tên buổi giao lưu
                Text(
                  currentSession.resolvedName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                // 3 dòng inline thông tin (Thời gian, Địa điểm, Lệ phí)
                _buildInlineInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Thời gian:',
                  value: dateRangeStr,
                  colors: colors,
                ),
                const SizedBox(height: 6),
                _buildInlineInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Địa điểm:',
                  value: currentSession.description?.isNotEmpty == true
                      ? currentSession.description!
                      : 'Sân hoạt động CLB',
                  colors: colors,
                ),
                const SizedBox(height: 6),
                _buildInlineInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Lệ phí:',
                  value: 'Miễn phí',
                  colors: colors,
                ),

                // Quick stats summary
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 18,
                            color: colors.info,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${activeParticipants.length}/$totalSlots người tham gia',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.sports_tennis_outlined,
                          size: 18,
                          color: colors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${value.matches.length} trận đấu',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── 2. BANNER QUẢN LÝ CHO BQT (NẾU CÓ QUYỀN) ───
          if (currentSession.canManage) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bạn là Ban quản trị',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Điều hành trận đấu, xếp cặp và quản lý VĐV',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Thao tác quản lý',
                    onSelected: (action) {
                      switch (action) {
                        case 'CREATE_MATCH':
                          _createMatch(context, ref, value.participants);
                          break;
                        case 'ASSIGN_MEMBERS':
                          _forceParticipants(context, ref);
                          break;
                        case 'CREATE_MOCK':
                          _createMockParticipant(context, ref);
                          break;
                        case 'CLOSE':
                          _transition(context, ref, 'CLOSE', currentSession);
                          break;
                        case 'END':
                          _transition(context, ref, 'END', currentSession);
                          break;
                        case 'CANCEL':
                          _transition(context, ref, 'CANCEL', currentSession);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (currentSession.canCreateMatch)
                        PopupMenuItem(
                          value: 'CREATE_MATCH',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.clubMatchSessionCreateMatch),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'ASSIGN_MEMBERS',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.clubMatchSessionAssignMembers),
                          ],
                        ),
                      ),
                      if (currentSession.status == 'OPEN')
                        PopupMenuItem(
                          value: 'CREATE_MOCK',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_add_alt_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.clubMatchSessionCreateMock),
                            ],
                          ),
                        ),
                      if (currentSession.status == 'OPEN' ||
                          currentSession.status == 'LIVE')
                        PopupMenuItem(
                          value: 'CLOSE',
                          child: Row(
                            children: [
                              const Icon(Icons.lock_clock_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.clubMatchSessionCloseRegistration),
                            ],
                          ),
                        ),
                      if (currentSession.status != 'ENDED' &&
                          currentSession.status != 'CANCELLED')
                        PopupMenuItem(
                          value: 'END',
                          child: Row(
                            children: [
                              const Icon(Icons.flag_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.clubMatchSessionEnd),
                            ],
                          ),
                        ),
                      if (currentSession.status != 'ENDED' &&
                          currentSession.status != 'CANCELLED')
                        PopupMenuItem(
                          value: 'CANCEL',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cancel_outlined,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.clubMatchSessionCancel,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Quản lý',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ─── 3. THẺ XÁC NHẬN THAM GIA (LƯỚI TRÒN 16 SLOT & PHÂN TRANG) ───
          Container(
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Xác nhận tham gia · ${activeParticipants.length}',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFDBEAFE),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            formatBadge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${activeParticipants.length}/$totalSlots người',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                // Helper banner when user is registered on a different page
                if (userPage != null && userPage != safePage) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bạn đang ở slot #${userSlotIndex + 1} (Trang $userPage)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _currentPage = userPage),
                          child: const Text(
                            'Xem vị trí →',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // 4-Column Circular Slots Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: endIndex - startIndex,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.76,
                  ),
                  itemBuilder: (context, idx) {
                    final globalSlotIndex = startIndex + idx;
                    final isOccupied =
                        globalSlotIndex < activeParticipants.length;

                    if (isOccupied) {
                      final item = activeParticipants[globalSlotIndex];
                      final isSelf =
                          currentUserId.isNotEmpty &&
                          item.userId == currentUserId;
                      final displayName = item.displayName.trim().isNotEmpty
                          ? item.displayName.trim()
                          : (item.isMock
                                ? '${l10n.clubMatchSessionMockPlayer} ${globalSlotIndex + 1}'
                                : 'VĐV');

                      return GestureDetector(
                        onTap: isSelf && currentSession.canWithdraw
                            ? () => _mutation(
                                context,
                                ref,
                                () => ref
                                    .read(clubMatchSessionRepositoryProvider)
                                    .withdraw(session.id),
                                l10n.clubMatchSessionWithdrawn,
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: _getColorByName(displayName),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelf
                                          ? const Color(0xFF3B82F6)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child:
                                        item.avatarUrl != null &&
                                            item.avatarUrl!.isNotEmpty
                                        ? Image.network(
                                            item.avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Center(
                                                      child: Text(
                                                        _getInitials(
                                                          displayName,
                                                        ),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                          )
                                        : Center(
                                            child: Text(
                                              _getInitials(displayName),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                if (isSelf)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            if (isSelf)
                              const Text(
                                '(Bạn)',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            else if (item.isMock)
                              Text(
                                l10n.clubMatchSessionMockPlayer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    // Empty Slot with Dashed/Grey Circle
                    final canTapEmptySlot =
                        currentSession.canJoin &&
                        currentSession.status == 'OPEN';
                    return GestureDetector(
                      onTap: canTapEmptySlot
                          ? () => _mutation(
                              context,
                              ref,
                              () => ref
                                  .read(clubMatchSessionRepositoryProvider)
                                  .selfJoin(session.id),
                              l10n.clubMatchSessionJoined,
                            )
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_rounded,
                                size: 22,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Slot #${globalSlotIndex + 1}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Pagination Toolbar (When totalPages > 1)
                if (totalPages > 1) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Slot ${startIndex + 1} - $endIndex / $totalSlots',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      Row(
                        children: [
                          // Prev button
                          InkWell(
                            onTap: safePage > 1
                                ? () => setState(
                                    () => _currentPage = safePage - 1,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: safePage > 1
                                    ? Colors.white
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: safePage > 1
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Text(
                                '‹ Trước',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: safePage > 1
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Page pills
                          ...List.generate(totalPages, (i) {
                            final pageNum = i + 1;
                            final isActive = pageNum == safePage;
                            final hasUser = pageNum == userPage;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _currentPage = pageNum),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 26,
                                      ),
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$pageNum',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isActive
                                              ? Colors.white
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    if (hasUser)
                                      Positioned(
                                        top: -3,
                                        right: -3,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 6),

                          // Next button
                          InkWell(
                            onTap: safePage < totalPages
                                ? () => setState(
                                    () => _currentPage = safePage + 1,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: safePage < totalPages
                                    ? Colors.white
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: safePage < totalPages
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Text(
                                'Sau ›',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: safePage < totalPages
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required AppColorsExtension colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: colors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsTab(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return _refreshableTab(
      context,
      ref,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SessionSectionTitle(
            icon: Icons.people_alt_outlined,
            title: l10n.clubMatchSessionParticipants,
            count: value.participants.length,
          ),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            child: Column(
              children: value.participants.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(l10n.noParticipants),
                      ),
                    ]
                  : value.participants
                        .map(
                          (item) => ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  item.avatarUrl?.trim().isNotEmpty == true
                                  ? NetworkImage(item.avatarUrl!.trim())
                                  : null,
                              backgroundColor: colors.info.withValues(
                                alpha: .12,
                              ),
                              child: item.avatarUrl?.trim().isNotEmpty == true
                                  ? null
                                  : Text(
                                      item.displayName.isEmpty
                                          ? '?'
                                          : item.displayName[0].toUpperCase(),
                                      style: TextStyle(color: colors.info),
                                    ),
                            ),
                            title: Text(item.displayName),
                            subtitle: Text(
                              item.isMock
                                  ? '${l10n.clubMatchSessionMockPlayer} · ${l10n.clubMatchSessionMockEloDisabled}'
                                  : item.source == 'MANDATORY'
                                  ? l10n.clubMatchSessionMandatorySource
                                  : l10n.clubMatchSessionSelfSource,
                            ),
                            trailing:
                                value.session.canManage &&
                                    item.status == 'ACTIVE'
                                ? IconButton(
                                    tooltip:
                                        l10n.clubMatchSessionRemoveParticipant,
                                    onPressed: () =>
                                        _removeParticipant(context, ref, item),
                                    icon: const Icon(
                                      Icons.person_remove_rounded,
                                    ),
                                  )
                                : null,
                          ),
                        )
                        .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return _refreshableTab(
      context,
      ref,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SessionSectionTitle(
            icon: Icons.sports_tennis_outlined,
            title: l10n.clubMatchSessionMatches,
            count: value.matches.length,
            action: value.session.canCreateMatch
                ? FilledButton.tonalIcon(
                    onPressed: () =>
                        _createMatch(context, ref, value.participants),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.clubMatchSessionCreateMatch),
                  )
                : null,
          ),
          if (value.matches.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text(l10n.clubMatchSessionNoMatches)),
              ),
            ),
          ...value.matches.map((match) => _ClubMatchScoreCard(match: match)),
        ],
      ),
    );
  }

  Widget _buildStatsTab(
    BuildContext context,
    WidgetRef ref,
    ClubSessionDetail value,
  ) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final stats = _buildClubMemberStats(value);
    final completedMatches = value.matches
        .where((match) => match.status.trim().toUpperCase() == 'COMPLETED')
        .length;
    final liveMatches = value.matches
        .where((match) => match.status.trim().toUpperCase() == 'ONGOING')
        .length;
    final playedStats = stats.where((stat) => stat.played > 0).toList();
    final topWins = playedStats.isEmpty
        ? null
        : playedStats.reduce((a, b) => b.wins > a.wins ? b : a);
    final topLosses = playedStats.isEmpty
        ? null
        : playedStats.reduce((a, b) => b.losses > a.losses ? b : a);

    return _refreshableTab(
      context,
      ref,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SessionSectionTitle(
            icon: Icons.insights_outlined,
            title: l10n.club_statsSection,
            count: stats.length,
          ),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _StatsMetric(
                    value: value.matches.length.toString(),
                    label: l10n.totalMatchesLabel,
                    color: colors.info,
                  ),
                  _StatsMetric(
                    value: completedMatches.toString(),
                    label: l10n.completedMatchesLabel,
                    color: colors.success,
                  ),
                  _StatsMetric(
                    value: liveMatches.toString(),
                    label: l10n.liveMatchesLabel,
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
          ),
          if (topWins != null || topLosses != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (topWins != null)
                  Expanded(
                    child: _StatsHighlight(
                      label: 'Thắng nhiều nhất',
                      stat: topWins,
                      icon: Icons.emoji_events_outlined,
                      color: colors.success,
                    ),
                  ),
                if (topWins != null && topLosses != null)
                  const SizedBox(width: 10),
                if (topLosses != null)
                  Expanded(
                    child: _StatsHighlight(
                      label: 'Thua nhiều nhất',
                      stat: topLosses,
                      icon: Icons.trending_down_rounded,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.clubMatchSessionParticipants,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (stats.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text(l10n.noParticipants)),
              ),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (var index = 0; index < stats.length; index++) ...[
                      _ClubMemberStatRow(stat: stats[index]),
                      if (index < stats.length - 1)
                        Divider(
                          height: 1,
                          indent: 62,
                          endIndent: 12,
                          color: colors.border.withValues(alpha: .65),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _refreshableTab(BuildContext context, WidgetRef ref, Widget child) =>
      RefreshIndicator(
        onRefresh: () async => _scheduleSessionDetailRefresh(),
        child: child,
      );
}


class _SessionSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Widget? action;
  const _SessionSectionTitle({
    required this.icon,
    required this.title,
    required this.count,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: context.colors.info),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$title ($count)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ...?(action == null ? null : <Widget>[action!]),
      ],
    ),
  );
}

List<_ClubMemberStat> _buildClubMemberStats(ClubSessionDetail value) {
  final stats = <String, _ClubMemberStat>{};

  void addMember(ClubSessionMatchMemberModel member) {
    if (member.userId.trim().isEmpty) return;
    stats.putIfAbsent(member.userId, () => _ClubMemberStat(member: member));
  }

  for (final participant in value.participants) {
    if (participant.status == 'ACTIVE') {
      addMember(
        ClubSessionMatchMemberModel(
          userId: participant.userId,
          displayName: participant.displayName,
          avatarUrl: participant.avatarUrl,
          isMock: participant.isMock,
        ),
      );
    }
  }

  for (final match in value.matches) {
    for (final member in [...match.sideAMembers, ...match.sideBMembers]) {
      addMember(member);
    }
    if (match.status.trim().toUpperCase() != 'COMPLETED' ||
        match.sideAScore == match.sideBScore) {
      continue;
    }

    final sideAWon = match.sideAScore > match.sideBScore;
    final sideAIds = <String>{};
    for (final member in match.sideAMembers) {
      if (sideAIds.add(member.userId)) {
        stats[member.userId]?.record(
          won: sideAWon,
          eloDelta: match.eloDelta[member.userId] ?? 0,
        );
      }
    }
    final sideBIds = <String>{};
    for (final member in match.sideBMembers) {
      if (sideBIds.add(member.userId)) {
        stats[member.userId]?.record(
          won: !sideAWon,
          eloDelta: match.eloDelta[member.userId] ?? 0,
        );
      }
    }
  }

  final result = stats.values.toList();
  result.sort((a, b) {
    final byWins = b.wins.compareTo(a.wins);
    if (byWins != 0) return byWins;
    final byElo = b.eloDelta.compareTo(a.eloDelta);
    if (byElo != 0) return byElo;
    final byPlayed = b.played.compareTo(a.played);
    if (byPlayed != 0) return byPlayed;
    return a.member.displayName.toLowerCase().compareTo(
      b.member.displayName.toLowerCase(),
    );
  });
  return result;
}

class _ClubMemberStat {
  final ClubSessionMatchMemberModel member;
  int played = 0;
  int wins = 0;
  int losses = 0;
  int eloDelta = 0;
  bool _streakClosed = false;
  bool? _streakWon;
  int currentStreak = 0;

  _ClubMemberStat({required this.member});

  void record({required bool won, required int eloDelta}) {
    played++;
    if (won) {
      wins++;
    } else {
      losses++;
    }
    this.eloDelta += eloDelta;

    // The API returns matches newest-first, so this is the current streak.
    if (_streakClosed) return;
    if (_streakWon == null || _streakWon == won) {
      _streakWon = won;
      currentStreak++;
    } else {
      _streakClosed = true;
    }
  }
}

class _StatsMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatsMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _StatsHighlight extends StatelessWidget {
  final String label;
  final _ClubMemberStat stat;
  final IconData icon;
  final Color color;

  const _StatsHighlight({
    required this.label,
    required this.stat,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${stat.member.displayName} · ${stat.wins}/${stat.losses}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubMemberStatRow extends StatelessWidget {
  final _ClubMemberStat stat;

  const _ClubMemberStatRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final eloColor = stat.eloDelta > 0
        ? colors.success
        : stat.eloDelta < 0
        ? const Color(0xFFDC2626)
        : colors.textMuted;
    final eloText = stat.member.isMock
        ? '— ELO'
        : '${stat.eloDelta > 0 ? '+' : ''}${stat.eloDelta} ELO';
    final streakText = stat.currentStreak >= 2
        ? '${stat._streakWon == true ? '🔥' : '↘'} ${stat.currentStreak} liên tiếp'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.info.withValues(alpha: .12),
            backgroundImage: stat.member.avatarUrl?.trim().isNotEmpty == true
                ? NetworkImage(stat.member.avatarUrl!.trim())
                : null,
            child: stat.member.avatarUrl?.trim().isNotEmpty == true
                ? null
                : Text(
                    stat.member.displayName.isEmpty
                        ? '?'
                        : stat.member.displayName[0].toUpperCase(),
                    style: TextStyle(
                      color: colors.info,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.member.displayName.isEmpty
                      ? 'VĐV chưa đặt tên'
                      : stat.member.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${stat.played} ${l10n.ranking_matchesLabel} · ${l10n.series_recordSummary(stat.wins, stat.losses)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                if (stat.member.isMock)
                  Text(
                    l10n.clubMatchSessionMockEloDisabled,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                eloText,
                style: TextStyle(
                  color: eloColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (streakText != null) ...[
                const SizedBox(height: 3),
                Text(
                  streakText,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ClubMatchScoreCard extends StatelessWidget {
  final ClubSessionMatchModel match;
  const _ClubMatchScoreCard({required this.match});

  MatchModel _asSharedMatch() {
    final sideAMembers = match.sideAMembers
        .map(
          (member) => MatchMemberInfo(
            userId: member.userId,
            fullName: member.displayName,
            avatarUrl: member.avatarUrl,
            isMock: member.isMock,
          ),
        )
        .toList(growable: false);
    final sideBMembers = match.sideBMembers
        .map(
          (member) => MatchMemberInfo(
            userId: member.userId,
            fullName: member.displayName,
            avatarUrl: member.avatarUrl,
            isMock: member.isMock,
          ),
        )
        .toList(growable: false);
    final sideAName = match.sideANames.join(' · ').trim();
    final sideBName = match.sideBNames.join(' · ').trim();
    final winnerId = switch (match.status) {
      'COMPLETED' when match.sideAScore > match.sideBScore => 'SIDE_A',
      'COMPLETED' when match.sideBScore > match.sideAScore => 'SIDE_B',
      _ => '',
    };

    return MatchModel(
      id: match.id,
      clubMatchSessionId: match.sessionId,
      round: 1,
      matchNumber: 1,
      team1Id: 'SIDE_A',
      team2Id: 'SIDE_B',
      team1Name: sideAName.isEmpty ? 'Đội A' : sideAName,
      team2Name: sideBName.isEmpty ? 'Đội B' : sideBName,
      score1: match.sideAScore,
      score2: match.sideBScore,
      winnerId: winnerId,
      loserId: winnerId == 'SIDE_A'
          ? 'SIDE_B'
          : winnerId == 'SIDE_B'
          ? 'SIDE_A'
          : '',
      status: match.status,
      bracketPosition: const BracketPosition(round: 1, position: 1),
      scoreDetails: match.scoreDetails,
      team1Members: sideAMembers.map((member) => member.fullName).toList(),
      team2Members: sideBMembers.map((member) => member.fullName).toList(),
      team1MemberInfos: sideAMembers,
      team2MemberInfos: sideBMembers,
      team1LogoUrl: sideAMembers.length == 1
          ? sideAMembers.first.avatarUrl
          : null,
      team2LogoUrl: sideBMembers.length == 1
          ? sideBMembers.first.avatarUrl
          : null,
      sportKey: match.sportKey.isNotEmpty ? match.sportKey : 'pickleball',
      tournamentConfig: const {
        'isLite': false,
        'scoringMode': 'STANDARD',
      },
      sportRules: {
        'kind': match.sportKey.isNotEmpty ? match.sportKey : 'pickleball',
        'mode': 'STANDARD',
        'scoringMode': 'STANDARD',
        'bestOf': 3,
        'setsToWin': 2,
        'pointsPerSet': 11,
        'mustWinByTwo': true,
      },
      revision: match.revision,
      updatedAt: DateTime.now(),
    );
  }

  void _openScoring(BuildContext context, MatchModel initialMatch) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ClubSessionMatchScoringEntry(
          matchId: match.id,
          initialMatch: initialMatch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sharedMatch = _asSharedMatch();
    final status = match.status.trim().toUpperCase();
    final delta = match.eloDelta.values.fold<int>(
      0,
      (sum, value) => sum + value.abs(),
    );
    final sideADelta = match.sideAMembers.fold<int>(
      0,
      (sum, member) => sum + (match.eloDelta[member.userId] ?? 0),
    );
    final sideBDelta = match.sideBMembers.fold<int>(
      0,
      (sum, member) => sum + (match.eloDelta[member.userId] ?? 0),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveMatchCardV2(
          match: sharedMatch,
          isLive: status == 'ONGOING',
          isCompleted: status == 'COMPLETED',
          onTap: () => _openScoring(context, sharedMatch),
          footer: _ClubMatchEloFooter(
            status: match.eloStatus,
            delta: delta,
            sideADelta: sideADelta,
            sideBDelta: sideBDelta,
          ),
        ),
      ],
    );
  }
}

class _ClubMatchEloFooter extends StatelessWidget {
  final String status;
  final int delta;
  final int sideADelta;
  final int sideBDelta;

  const _ClubMatchEloFooter({
    required this.status,
    required this.delta,
    required this.sideADelta,
    required this.sideBDelta,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isApplied = status == 'APPLIED' && delta > 0;
    final sideChanges = isApplied && (sideADelta != 0 || sideBDelta != 0)
        ? 'A ${_signedElo(sideADelta)} · B ${_signedElo(sideBDelta)} ELO'
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: colors.bgSurface.withValues(alpha: .65),
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: .55)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_flat_rounded,
            size: 15,
            color: isApplied ? colors.success : colors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_localizedEloStatus(l10n, status)}${sideChanges != null
                  ? ' · $sideChanges'
                  : isApplied
                  ? ' · ${l10n.clubMatchSessionEloDelta(delta)}'
                  : ''}',
              style: TextStyle(
                color: isApplied ? colors.success : colors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _signedElo(int value) => '${value > 0 ? '+' : ''}$value';

class _ClubSessionMatchScoringEntry extends ConsumerWidget {
  final String matchId;
  final MatchModel initialMatch;

  const _ClubSessionMatchScoringEntry({
    required this.matchId,
    required this.initialMatch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(matchRepositoryProvider);
    if (repository is ApiMatchRepository) {
      repository.primeMatch(initialMatch);
    }
    final matchAsync = ref.watch(
      singleMatchProvider((tournamentId: '', matchId: matchId)),
    );
    // Open with the authoritative card snapshot immediately. The provider
    // continues to reconcile the match and supplies the live score state;
    // this avoids a blank tap while the dedicated social endpoint responds.
    final match = matchAsync.value ?? initialMatch;
    return OfficialScorePage(tournamentId: '', matchId: matchId, match: match);
  }
}
