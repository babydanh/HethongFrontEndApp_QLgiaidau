import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/core/utils/tennis_game_point_display.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_dialog.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_result_dialog.dart';

class ClubActivityTab extends ConsumerStatefulWidget {
  final String communityId;
  final Community? club;

  const ClubActivityTab({super.key, required this.communityId, this.club});

  @override
  ConsumerState<ClubActivityTab> createState() => _ClubActivityTabState();
}

enum _ActivityFilter { all, myMatches, ongoing, completed }

class _ClubActivityTabState extends ConsumerState<ClubActivityTab> {
  static const _activityMatchPageSize = 10;
  static const _activitySessionPageSize = 8;

  List<MatchModel> _matches = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreActivity = false;
  int _activityDisplayLimit = _activityMatchPageSize;
  String? _errorMessage;
  _ActivityFilter _filter = _ActivityFilter.all;
  Timer? _refreshTimer;
  Timer? _socketRefreshTimer;
  StreamSubscription<Map<String, dynamic>>? _socketScoreSubscription;
  StreamSubscription<Map<String, dynamic>>? _socketStatusSubscription;
  StreamSubscription<Map<String, dynamic>>? _socketMatchSubscription;
  final Set<String> _joinedActivityMatchIds = <String>{};
  final Set<String> _joinedActivitySessionIds = <String>{};
  final Set<String> _joinedActivityTournamentIds = <String>{};
  final List<Map<String, dynamic>> _activityTournaments = [];
  final Map<String, ClubMatchSessionModel> _activitySessions = {};
  final Map<String, String?> _tournamentMatchCursors = {};
  final Map<String, bool> _tournamentMatchHasMore = {};
  final Map<String, String?> _sessionMatchCursors = {};
  final Map<String, bool> _sessionMatchHasMore = {};
  String? _sessionListCursor;
  bool _sessionListHasMore = false;
  String? _standaloneMatchCursor;
  bool _standaloneMatchHasMore = false;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
    _listenForActivityMatchUpdates();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _fetchMatches(silent: true);
    });
  }

  void _listenForActivityMatchUpdates() {
    final socket = ref.read(matchSocketServiceProvider);
    _socketScoreSubscription = socket.onScoreUpdate.listen(
      _handleSocketMatchUpdate,
    );
    _socketStatusSubscription = socket.onMatchStatus.listen(
      _handleSocketMatchUpdate,
    );
    _socketMatchSubscription = socket.onTournamentMatchUpdate.listen(
      _handleSocketMatchUpdate,
    );
    socket.joinClubCommunity(widget.communityId);
    unawaited(socket.connect(null, joinMatch: false));
  }

  void _handleSocketMatchUpdate(Map<String, dynamic> payload) {
    final matchId = (payload['id'] ?? payload['matchId'])?.toString().trim();
    if (matchId == null || matchId.isEmpty) return;

    // Socket events are the fast path. Re-read the authoritative activity
    // projection so liveState (including tennis game points) and set scores
    // are updated together instead of merging a partial payload.
    _socketRefreshTimer?.cancel();
    _socketRefreshTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) unawaited(_fetchMatches(silent: true));
    });
  }

  void _syncActivitySocketRooms() {
    final socket = ref.read(matchSocketServiceProvider);
    unawaited(socket.connect(null, joinMatch: false));
    for (final match in _matches) {
      if (match.isStandaloneMatch) {
        if (_joinedActivityMatchIds.add(match.id)) socket.join(match.id);
        continue;
      }
      final sessionId = match.clubMatchSessionId;
      if (sessionId != null && sessionId.isNotEmpty) {
        if (_joinedActivitySessionIds.add(sessionId)) {
          socket.joinClubMatchSession(sessionId);
        }
        continue;
      }
      final tournamentId = match.tournamentId;
      if (tournamentId != null && tournamentId.isNotEmpty) {
        if (_joinedActivityTournamentIds.add(tournamentId)) {
          socket.joinTournament(tournamentId);
        }
      }
    }
  }

  @override
  void dispose() {
    _socketRefreshTimer?.cancel();
    _socketScoreSubscription?.cancel();
    _socketStatusSubscription?.cancel();
    _socketMatchSubscription?.cancel();
    final socket = ref.read(matchSocketServiceProvider);
    for (final matchId in _joinedActivityMatchIds) {
      socket.leave(matchId);
    }
    for (final sessionId in _joinedActivitySessionIds) {
      socket.leaveClubMatchSession(sessionId);
    }
    for (final tournamentId in _joinedActivityTournamentIds) {
      socket.leaveTournament(tournamentId);
    }
    socket.leaveClubCommunity(widget.communityId);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _resetActivityPaging() {
    _activityTournaments.clear();
    _activitySessions.clear();
    _tournamentMatchCursors.clear();
    _tournamentMatchHasMore.clear();
    _sessionMatchCursors.clear();
    _sessionMatchHasMore.clear();
    _sessionListCursor = null;
    _sessionListHasMore = false;
    _standaloneMatchCursor = null;
    _standaloneMatchHasMore = false;
    _hasMoreActivity = false;
    _activityDisplayLimit = _activityMatchPageSize;
  }

  String? _safeNextCursor(String? cursor, String? nextCursor, bool hasMore) {
    if (!hasMore || nextCursor == null || nextCursor.isEmpty) return null;
    if (nextCursor == cursor) return null;
    return nextCursor;
  }

  bool get _hasMoreActivitySource =>
      _sessionListHasMore ||
      _standaloneMatchHasMore ||
      _tournamentMatchHasMore.values.any((value) => value) ||
      _sessionMatchHasMore.values.any((value) => value);

  bool _isOngoingMatch(MatchModel match) {
    return match.isLive;
  }

  int _activityStatusOrder(MatchModel match) {
    if (_isOngoingMatch(match)) return 0;
    if (match.isCompleted) return 1;
    return 2;
  }

  DateTime _activitySortTime(MatchModel match) {
    return match.completedAt ??
        match.startedAt ??
        match.scheduledTime ??
        match.updatedAt;
  }

  String? _activityDateLabel(MatchModel match) {
    final time = match.completedAt ?? match.startedAt ?? match.scheduledTime;
    return time == null ? null : DateFormatterUtils.formatDateTime(time);
  }

  void _sortActivityMatches(List<MatchModel> items) {
    items.sort((a, b) {
      final statusOrder = _activityStatusOrder(
        a,
      ).compareTo(_activityStatusOrder(b));
      if (statusOrder != 0) return statusOrder;
      return _activitySortTime(b).compareTo(_activitySortTime(a));
    });
  }

  void _mergeActivityMatches(
    List<MatchModel> incoming, {
    required bool replace,
  }) {
    final byId = <String, MatchModel>{};
    if (!replace) {
      for (final match in _matches) {
        byId[match.id] = match;
      }
    }
    for (final match in incoming) {
      if (match.id.isNotEmpty) byId[match.id] = match;
    }
    final merged = byId.values.toList();
    _sortActivityMatches(merged);
    if (mounted) {
      setState(() {
        _matches = merged;
        _hasMoreActivity =
            merged.length > _activityDisplayLimit || _hasMoreActivitySource;
      });
    }
  }

  Future<void> _fetchMatches({
    bool silent = false,
    bool loadMore = false,
  }) async {
    if (loadMore && (_isLoadingMore || !_hasMoreActivity)) return;

    // The activity feed merges independent cursor streams. Reveal buffered
    // rows before requesting another remote page when no source has more.
    if (loadMore && !_hasMoreActivitySource) {
      if (!mounted) return;
      setState(() {
        _activityDisplayLimit += _activityMatchPageSize;
        _hasMoreActivity = _matches.length > _activityDisplayLimit;
      });
      return;
    }

    final isFirstPage = !silent && !loadMore;
    final isHeadRefresh = silent && !loadMore;
    if (isFirstPage) {
      _resetActivityPaging();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (loadMore) {
      _activityDisplayLimit += _activityMatchPageSize;
      setState(() => _isLoadingMore = true);
    }

    final pageMatches = <MatchModel>[];
    try {
      final dio = ref.read(dioClientProvider).dio;
      final matchRepository = ref.read(matchRepositoryProvider);
      final sessionRepo = ref.read(clubMatchSessionRepositoryProvider);

      // 1. Giải đấu: mỗi giải là một stream cursor độc lập.
      var tournamentRows = _activityTournaments;
      if (isFirstPage || isHeadRefresh || tournamentRows.isEmpty) {
        try {
          final tourRes = await dio.get(
            '/communities/${widget.communityId}/tournaments',
          );
          final rawTours = tourRes.data is Map
              ? (tourRes.data['data'] ?? tourRes.data)
              : tourRes.data;
          final parsedTours = (rawTours is List ? rawTours : const <dynamic>[])
              .whereType<Map>()
              .map((tour) => Map<String, dynamic>.from(tour))
              .take(5)
              .toList(growable: false);
          _activityTournaments
            ..clear()
            ..addAll(parsedTours);
          tournamentRows = _activityTournaments;
        } catch (_) {}
      }

      for (final tour in tournamentRows) {
        final tourId = tour['id']?.toString();
        final tourName = tour['name']?.toString() ?? 'Giải đấu';
        if (tourId == null || tourId.isEmpty) continue;

        final previousCursor = _tournamentMatchCursors[tourId];
        final isNewStream = !_tournamentMatchCursors.containsKey(tourId);
        final cursor = loadMore ? previousCursor : null;
        try {
          final page = await matchRepository.getTournamentMatchesPaged(
            tournamentId: tourId,
            cursor: cursor,
            limit: _activityMatchPageSize,
          );
          if (!isHeadRefresh || isNewStream) {
            final next = _safeNextCursor(cursor, page.nextCursor, page.hasMore);
            _tournamentMatchCursors[tourId] = next;
            _tournamentMatchHasMore[tourId] = next != null;
          }
          pageMatches.addAll(
            page.matches
                .where(isRenderablePublicMatch)
                .map((match) => match.copyWith(tournamentName: tourName)),
          );
        } catch (_) {}
      }

      // 2. Buổi giao lưu: phân trang danh sách buổi và từng stream trận.
      try {
        var currentSessionPage = const <ClubMatchSessionModel>[];
        if (!loadMore || _sessionListHasMore) {
          final sessionCursor = loadMore ? _sessionListCursor : null;
          final sessionPage = await sessionRepo.listPage(
            widget.communityId,
            cursor: sessionCursor,
            limit: _activitySessionPageSize,
          );
          currentSessionPage = sessionPage.data;
          if (!isHeadRefresh) {
            final next = _safeNextCursor(
              sessionCursor,
              sessionPage.nextCursor,
              sessionPage.hasMore,
            );
            _sessionListCursor = next;
            _sessionListHasMore = next != null;
          }
        }

        for (final session in currentSessionPage) {
          if (session.id.isNotEmpty) _activitySessions[session.id] = session;
        }
        final sessionsToFetch = loadMore
            ? _activitySessions.values.toList(growable: false)
            : currentSessionPage;
        for (final session in sessionsToFetch) {
          final sessionId = session.id;
          if (sessionId.isEmpty) continue;
          final isNewSession = !_sessionMatchCursors.containsKey(sessionId);
          final existingMatchCursor = _sessionMatchCursors[sessionId];
          final shouldFetchMatches =
              !loadMore ||
              isNewSession ||
              (_sessionMatchHasMore[sessionId] ?? false);
          if (!shouldFetchMatches) continue;

          final matchCursor = loadMore && !isNewSession
              ? existingMatchCursor
              : null;
          try {
            final matchPage = await sessionRepo.matchesPage(
              sessionId,
              cursor: matchCursor,
              limit: _activityMatchPageSize,
            );
            if (!isHeadRefresh || isNewSession) {
              final next = _safeNextCursor(
                matchCursor,
                matchPage.nextCursor,
                matchPage.hasMore,
              );
              _sessionMatchCursors[sessionId] = next;
              _sessionMatchHasMore[sessionId] = next != null;
            }
            pageMatches.addAll(
              matchPage.data.map(
                (match) => _mapClubMatch(
                  match,
                  tournamentName: session.resolvedName.isNotEmpty
                      ? session.resolvedName
                      : 'Giao lưu CLB',
                  sessionId: sessionId,
                  updatedAt: session.startAt,
                ),
              ),
            );
          } catch (_) {}
        }
      } catch (_) {}

      // 3. Trận riêng: stream cursor độc lập, không gán tournament/session giả.
      try {
        final standaloneCursor = loadMore ? _standaloneMatchCursor : null;
        final standalonePage = await sessionRepo.standaloneMatchesPage(
          widget.communityId,
          cursor: standaloneCursor,
          limit: _activityMatchPageSize,
        );
        if (!isHeadRefresh) {
          final next = _safeNextCursor(
            standaloneCursor,
            standalonePage.nextCursor,
            standalonePage.hasMore,
          );
          _standaloneMatchCursor = next;
          _standaloneMatchHasMore = next != null;
        }
        pageMatches.addAll(
          standalonePage.data.map(
            (match) => _mapClubMatch(
              match,
              tournamentName: l10nFallbackStandaloneMatchName,
              standalone: true,
            ),
          ),
        );
      } catch (_) {}

      if (mounted) {
        _mergeActivityMatches(pageMatches, replace: isFirstPage);
        _syncActivitySocketRooms();
      }
    } catch (e) {
      if (mounted && isFirstPage) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isFirstPage) _isLoading = false;
          if (loadMore) _isLoadingMore = false;
        });
      }
    }
  }

  bool _onActivityScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        _hasMoreActivity &&
        !_isLoadingMore &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 400) {
      unawaited(_fetchMatches(loadMore: true));
    }
    return false;
  }

  Widget _buildLoadMoreButton(AppColorsExtension colors) {
    if (!_hasMoreActivity) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: _isLoadingMore
              ? null
              : () => _fetchMatches(loadMore: true),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoadingMore
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  AppLocalizations.of(context)!.club_loadMoreMatches,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  String get l10nFallbackStandaloneMatchName => 'Trận đấu riêng';

  MatchModel _mapClubMatch(
    ClubSessionMatchModel sm, {
    required String tournamentName,
    bool standalone = false,
    String? sessionId,
    DateTime? updatedAt,
  }) {
    final sideAMembers = sm.sideAMembers
        .map(
          (m) => MatchMemberInfo(
            userId: m.userId,
            fullName: m.displayName,
            avatarUrl: m.avatarUrl,
            isMock: m.isMock,
          ),
        )
        .toList(growable: false);
    final sideBMembers = sm.sideBMembers
        .map(
          (m) => MatchMemberInfo(
            userId: m.userId,
            fullName: m.displayName,
            avatarUrl: m.avatarUrl,
            isMock: m.isMock,
          ),
        )
        .toList(growable: false);
    final sideAName = sm.sideANames.join(' · ').trim();
    final sideBName = sm.sideBNames.join(' · ').trim();
    final status = sm.status.toUpperCase();
    final winnerId = switch (status) {
      'COMPLETED' when sm.sideAScore > sm.sideBScore => 'SIDE_A',
      'COMPLETED' when sm.sideBScore > sm.sideAScore => 'SIDE_B',
      _ => '',
    };
    // The API can include a placeholder for the next set. Keep the current
    // set, but do not show trailing empty sets until somebody scores in them.
    final parsedDisplaySets = parseClubSessionScoreDetails(
      sm.scoreDetails,
    ).take(10).toList(growable: true);
    while (parsedDisplaySets.length > 1 &&
        parsedDisplaySets.last.sideAScore == 0 &&
        parsedDisplaySets.last.sideBScore == 0) {
      parsedDisplaySets.removeLast();
    }
    final displaySets = parsedDisplaySets
        .map(
          (score) =>
              SetScore(score1: score.sideAScore, score2: score.sideBScore),
        )
        .toList(growable: false);
    final kind = sm.sportKey.isNotEmpty ? sm.sportKey : 'pickleball';
    return MatchModel(
      id: sm.id,
      // The endpoint is authoritative: session rows are social-session
      // matches; rows from /standalone-matches are private club matches.
      isStandaloneMatch: standalone,
      clubMatchSessionId: standalone
          ? null
          : ((sessionId ?? sm.sessionId).trim().isNotEmpty
                ? (sessionId ?? sm.sessionId).trim()
                : null),
      tournamentName: tournamentName,
      round: 0,
      matchNumber: 1,
      team1Id: 'SIDE_A',
      team2Id: 'SIDE_B',
      team1Name: sideAName.isEmpty ? 'Đội A' : sideAName,
      team2Name: sideBName.isEmpty ? 'Đội B' : sideBName,
      score1: sm.sideAScore,
      score2: sm.sideBScore,
      sets: displaySets.isNotEmpty
          ? displaySets
          : [
              SetScore(
                score1: status == 'COMPLETED' ? sm.sideAScore : 0,
                score2: status == 'COMPLETED' ? sm.sideBScore : 0,
              ),
            ],
      winnerId: winnerId,
      loserId: winnerId == 'SIDE_A'
          ? 'SIDE_B'
          : winnerId == 'SIDE_B'
          ? 'SIDE_A'
          : '',
      status: sm.status,
      bracketPosition: const BracketPosition(round: 1, position: 1),
      scoreDetails: sm.scoreDetails,
      team1Members: sideAMembers.map((m) => m.fullName).toList(),
      team2Members: sideBMembers.map((m) => m.fullName).toList(),
      team1MemberInfos: sideAMembers,
      team2MemberInfos: sideBMembers,
      eloDelta: sm.eloDelta,
      eloStatus: sm.eloStatus,
      team1LogoUrl: sideAMembers.length == 1
          ? sideAMembers.first.avatarUrl
          : null,
      team2LogoUrl: sideBMembers.length == 1
          ? sideBMembers.first.avatarUrl
          : null,
      sportKey: kind,
      tournamentConfig: sm.tournamentConfig.isNotEmpty
          ? sm.tournamentConfig
          : const {
              'isLite': true,
              'mode': 'LITE',
              'scoringMode': 'FREE',
              'maxSets': 10,
            },
      sportRules: sm.sportRules.isNotEmpty
          ? sm.sportRules
          : {
              'kind': kind,
              'mode': 'LITE',
              'scoringMode': 'FREE',
              'maxSets': 10,
            },
      revision: sm.revision,
      scheduledTime: sm.scheduledAt,
      startedAt: sm.startedAt,
      completedAt: sm.completedAt,
      updatedAt:
          sm.updatedAt ??
          sm.createdAt ??
          updatedAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  void _showMemberSheet(
    BuildContext context,
    String userId,
    String fullName,
    String? avatarUrl,
  ) {
    UserProfileBottomSheet.show(
      context,
      userId: userId,
      communityId: widget.communityId,
      initialFullName: fullName,
      initialAvatarUrl: avatarUrl,
      onFilterMatches: (query) {
        final name = Uri.encodeComponent(widget.club?.name ?? '');
        context.push(
          '/club/${widget.communityId}/search?name=$name&q=${Uri.encodeComponent(query)}',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(userProfileProvider).asData?.value;
    final membership = ref.watch(
      myCommunityMembershipProvider(widget.communityId),
    );
    final isClubMember =
        membership.asData?.value?.status.toUpperCase() == 'JOINED';
    final socialSettings = ref
        .watch(communitySocialSettingsProvider(widget.communityId))
        .asData
        ?.value;
    final memberRole =
        membership.asData?.value?.role ?? widget.club?.myRole ?? '';
    final isClubManager = const {
      'OWNER',
      'ADMIN',
      'MODERATOR',
    }.contains(memberRole.toUpperCase());
    final canCreateStandalone =
        isClubMember &&
        (isClubManager || socialSettings?.memberMatchCreationEnabled != false);
    final currentUserId = currentUser?.id ?? '';
    final currentUserName = (currentUser?.fullName ?? '').toLowerCase();

    // Lọc trận đấu của tôi
    final userMatches = isClubMember
        ? _matches.where((m) {
            if (currentUserId.isEmpty && currentUserName.isEmpty) return false;
            final isT1 =
                m.team1MemberInfos.any((mem) => mem.userId == currentUserId) ||
                (currentUserName.isNotEmpty &&
                    m.team1Name.toLowerCase().contains(currentUserName));
            final isT2 =
                m.team2MemberInfos.any((mem) => mem.userId == currentUserId) ||
                (currentUserName.isNotEmpty &&
                    m.team2Name.toLowerCase().contains(currentUserName));
            return isT1 || isT2;
          }).toList()
        : <MatchModel>[];

    // Lọc danh sách theo bộ lọc hoạt động. Tìm kiếm dùng màn hình search
    // chung mở từ header CLB.
    final filteredMatches = _matches.where((m) {
      if (_filter == _ActivityFilter.ongoing && !m.isLive) {
        return false;
      }
      if (_filter == _ActivityFilter.completed && !m.isCompleted) {
        return false;
      }
      if (_filter == _ActivityFilter.myMatches) {
        if (!userMatches.contains(m)) return false;
      }

      return true;
    }).toList();
    final visibleMatches = filteredMatches.take(_activityDisplayLimit).toList();

    return NotificationListener<ScrollNotification>(
      onNotification: _onActivityScroll,
      child: RefreshIndicator(
        onRefresh: () => _fetchMatches(),
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ─── 2. THANH LỌC & TÌM KIẾM & TẠO TRẬN ĐẤU ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (canCreateStandalone) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final createdMatch =
                                  await ClubStandaloneMatchDialog.show(
                                    context,
                                    communityId: widget.communityId,
                                    clubName: widget.club?.name,
                                    onMatchCreated: () => _fetchMatches(),
                                  );
                              if (!context.mounted || createdMatch == null) {
                                return;
                              }
                              final action =
                                  await ClubStandaloneMatchResultDialog.show(
                                    context,
                                    match: createdMatch,
                                  );
                              if (!context.mounted) return;
                              if (action == ClubStandaloneMatchAction.saved) {
                                unawaited(_fetchMatches(silent: true));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.club_matchScoreSaved,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 15),
                            label: Text(
                              l10n.club_createMatchStandalone,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Filter Dropdown Row
                  _buildFilterDropdown(
                    colors: colors,
                    isClubMember: isClubMember,
                    currentUser: currentUser,
                    userMatches: userMatches,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ─── 3. DANH SÁCH TRẬN ĐẤU TIMELINE ───────────────────────
            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 36,
                        color: colors.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lỗi tải hoạt động CLB: $_errorMessage',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _fetchMatches(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (filteredMatches.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports_tennis_rounded,
                        size: 40,
                        color: colors.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Chưa có hoạt động trận đấu nào',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _filter == _ActivityFilter.myMatches
                            ? 'Bạn chưa tham gia trận đấu nào trong các giải thuộc CLB.'
                            : 'Khi các giải đấu diễn ra, kết quả và diễn biến sẽ xuất hiện ở đây.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              _buildLoadMoreButton(colors),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: visibleMatches.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final match = visibleMatches[index];
                  return _buildMatchCard(context, match, colors);
                },
              ),
              _buildLoadMoreButton(colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required AppColorsExtension colors,
    required bool isClubMember,
    required dynamic currentUser,
    required List<dynamic> userMatches,
  }) {
    String filterLabel(_ActivityFilter f) {
      switch (f) {
        case _ActivityFilter.all:
          return 'Tất cả (${_matches.length})';
        case _ActivityFilter.myMatches:
          return 'Trận của tôi (${userMatches.length})';
        case _ActivityFilter.ongoing:
          return 'Đang diễn ra';
        case _ActivityFilter.completed:
          return 'Đã kết thúc';
      }
    }

    final options = <_ActivityFilter>[
      _ActivityFilter.all,
      if (isClubMember && currentUser != null) _ActivityFilter.myMatches,
      _ActivityFilter.ongoing,
      _ActivityFilter.completed,
    ];

    return PopupMenuButton<_ActivityFilter>(
      initialValue: _filter,
      onSelected: (f) => setState(() => _filter = f),
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minHeight: 32),
      itemBuilder: (_) => options.map((f) {
        final isSelected = _filter == f;
        return PopupMenuItem<_ActivityFilter>(
          value: f,
          height: 40,
          child: Row(
            children: [
              if (isSelected)
                Icon(Icons.check_rounded, size: 14, color: AppTheme.primary)
              else
                const SizedBox(width: 14),
              const SizedBox(width: 6),
              Text(
                filterLabel(f),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : colors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filterLabel(_filter),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    MatchModel match,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isOngoing = match.isLive;
    final isCompleted = match.isCompleted;

    final isT1Winner = isCompleted && match.winnerId == match.team1Id;
    final isT2Winner = isCompleted && match.winnerId == match.team2Id;

    // Only render signed deltas persisted by the API. Never derive ELO from
    // winner/score and never use a fixed fallback value.
    String? teamEloDelta(List<MatchMemberInfo> members) {
      if (!isCompleted ||
          match.eloStatus.toUpperCase() != 'APPLIED' ||
          match.eloDelta.isEmpty) {
        return null;
      }
      for (final member in members) {
        final userId = member.userId;
        if (userId == null || userId.isEmpty) continue;
        final delta = match.eloDelta[userId];
        if (delta != null) return '${delta > 0 ? '+' : ''}$delta';
      }
      return null;
    }

    final t1EloDelta = teamEloDelta(match.team1MemberInfos);
    final t2EloDelta = teamEloDelta(match.team2MemberInfos);
    final currentTennisGamePoints = readTennisGamePointDisplay(
      match,
      isLive: isOngoing,
    );

    final headerTitle = match.isStandaloneMatch
        ? l10n.club_standaloneMatch
        : (match.tournamentName?.trim().isNotEmpty == true
              ? match.tournamentName!.trim()
              : 'Buổi giao lưu CLB');
    final activityDate = _activityDateLabel(match);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMatch(context, match),
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            border: Border(
              bottom: BorderSide(color: colors.borderLight, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Header Bar: Tournament Name, Round & Status
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isOngoing ? const Color(0xFFFEF2F2) : colors.bgSurface,
                  border: Border(
                    bottom: BorderSide(
                      color: isOngoing
                          ? const Color(0xFFFECACA)
                          : colors.borderLight,
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              headerTitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (activityDate != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                activityDate,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (match.isStandaloneMatch &&
                            match.normalizedStatus == 'COMPLETED')
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 26,
                            ),
                            iconSize: 18,
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteStandaloneMatch(context, match);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Xóa trận'),
                              ),
                            ],
                          ),
                        if (isOngoing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fiber_manual_record_rounded,
                                  size: 8,
                                  color: Color(0xFFDC2626),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Đang diễn ra',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isCompleted)
                          Text(
                            'Đã kết thúc',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scores & Teams
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  children: [
                    // Team 1 Row
                    _buildTeamRow(
                      context: context,
                      name: match.team1Name,
                      logoUrl: match.team1LogoUrl,
                      isWinner: isT1Winner,
                      eloDelta: t1EloDelta,
                      sets: match.sets.map((s) => s.score1).toList(),
                      currentGamePoint: currentTennisGamePoints?.team1,
                      memberInfos: match.team1MemberInfos,
                      colors: colors,
                    ),
                    const SizedBox(height: 10),
                    // Team 2 Row
                    _buildTeamRow(
                      context: context,
                      name: match.team2Name,
                      logoUrl: match.team2LogoUrl,
                      isWinner: isT2Winner,
                      eloDelta: t2EloDelta,
                      sets: match.sets.map((s) => s.score2).toList(),
                      currentGamePoint: currentTennisGamePoints?.team2,
                      memberInfos: match.team2MemberInfos,
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMatch(BuildContext context, MatchModel match) async {
    final repository = ref.read(matchRepositoryProvider);
    if (match.isStandaloneMatch) {
      if (repository is ApiMatchRepository) {
        repository.primeMatch(match);
      }
      final action = await ClubStandaloneMatchResultDialog.show(
        context,
        match: match,
      );
      if (!context.mounted) return;
      if (action == ClubStandaloneMatchAction.saved) {
        unawaited(_fetchMatches(silent: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.club_matchScoreSaved),
          ),
        );
      } else if (action == ClubStandaloneMatchAction.openScoreboard) {
        _openOfficialScoreboard(context, match);
      }
      return;
    }

    if (match.clubMatchSessionId != null &&
        match.clubMatchSessionId!.isNotEmpty) {
      if (repository is ApiMatchRepository) {
        repository.primeMatch(match);
      }
      _openOfficialScoreboard(context, match);
      return;
    }

    if (match.tournamentId != null && match.tournamentId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LiveScoreScreen(
            tournamentId: match.tournamentId!,
            matchId: match.id,
          ),
        ),
      );
    }
  }

  void _openOfficialScoreboard(BuildContext context, MatchModel match) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfficialScorePage(
          tournamentId: '',
          matchId: match.id,
          match: match,
        ),
      ),
    );
  }

  Future<void> _deleteStandaloneMatch(
    BuildContext context,
    MatchModel match,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa trận đấu?'),
        content: const Text(
          'Trận sẽ bị gỡ khỏi hoạt động CLB. Nếu đã tính ELO, điểm và lịch sử của trận sẽ được hoàn nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa trận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(clubMatchSessionRepositoryProvider)
          .deleteStandaloneMatch(match.id);
      if (!mounted) return;
      setState(() => _matches.removeWhere((item) => item.id == match.id));
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xóa trận và hoàn nguyên ELO nếu có.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data is Map
                ? (error.response?.data['message']?.toString() ??
                      'Không thể xóa trận')
                : 'Không thể xóa trận',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTeamRow({
    required BuildContext context,
    required String name,
    required String? logoUrl,
    required bool isWinner,
    required String? eloDelta,
    required List<int> sets,
    String? currentGamePoint,
    required List<MatchMemberInfo> memberInfos,
    required AppColorsExtension colors,
  }) {
    final isDoubles = memberInfos.length >= 2;
    final displayMembers = isDoubles
        ? memberInfos.take(2).toList(growable: false)
        : const <MatchMemberInfo>[];
    final firstMember = memberInfos.isNotEmpty ? memberInfos.first : null;
    final targetUserId = firstMember?.userId;
    final eloIsNegative = eloDelta?.startsWith('-') == true;

    return Row(
      children: [
        // Đội đôi dùng cụm hai avatar tách nhẹ; mỗi avatar vẫn mở đúng hồ sơ VĐV.
        if (isDoubles)
          SizedBox(
            width: 54,
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 2,
                  child: _buildMemberAvatar(
                    context: context,
                    member: displayMembers[0],
                    isWinner: isWinner,
                    colors: colors,
                  ),
                ),
                Positioned(
                  left: 22,
                  top: 2,
                  child: _buildMemberAvatar(
                    context: context,
                    member: displayMembers[1],
                    isWinner: isWinner,
                    colors: colors,
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: targetUserId != null && targetUserId.isNotEmpty
                ? () => _showMemberSheet(context, targetUserId, name, logoUrl)
                : null,
            child: _buildTeamAvatar(
              name: name,
              logoUrl: logoUrl,
              isWinner: isWinner,
              colors: colors,
            ),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              // Đội đôi: mỗi VĐV một dòng, chỉ hiển thị tên cuối để luôn đủ tên.
              Expanded(
                child: GestureDetector(
                  onTap: targetUserId != null && targetUserId.isNotEmpty
                      ? () => _showMemberSheet(
                          context,
                          targetUserId,
                          name,
                          logoUrl,
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDoubles)
                        for (final member in displayMembers)
                          Text(
                            _lastTwoNameWords(member.fullName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.15,
                              fontWeight: isWinner
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: isWinner
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          )
                      else
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isWinner
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isWinner
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                        ),
                      if (eloDelta != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: eloIsNegative
                                ? const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.12)
                                : const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: eloIsNegative
                                  ? const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.3)
                                  : const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            eloDelta,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: eloIsNegative
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Neo cụm điểm vào mép phải; set mới xuất hiện bên phải và
              // tự đẩy các set trước đó sang trái.
              () {
                final displaySets = sets.length > 5
                    ? sets.sublist(sets.length - 5)
                    : sets;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: displaySets.map((s) {
                          return Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: isWinner
                                  ? const Color(0xFF2563EB)
                                  : colors.bgSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$s',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isWinner
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                fontFamily: 'monospace',
                                color: isWinner
                                    ? Colors.white
                                    : colors.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (currentGamePoint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          currentGamePoint,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: colors.textSecondary,
                            height: 1,
                          ),
                        ),
                      ),
                  ],
                );
              }(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAvatar({
    required BuildContext context,
    required MatchMemberInfo member,
    required bool isWinner,
    required AppColorsExtension colors,
  }) {
    final userId = member.userId;
    return GestureDetector(
      onTap: userId != null && userId.isNotEmpty
          ? () => _showMemberSheet(
              context,
              userId,
              member.fullName,
              member.avatarUrl,
            )
          : null,
      child: _buildTeamAvatar(
        name: member.fullName,
        logoUrl: member.avatarUrl,
        isWinner: isWinner,
        colors: colors,
        borderColor: colors.bgCard,
      ),
    );
  }

  Widget _buildTeamAvatar({
    required String name,
    required String? logoUrl,
    required bool isWinner,
    required AppColorsExtension colors,
    Color? borderColor,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isWinner ? const Color(0xFF2563EB) : colors.bgSurface,
        border: Border.all(
          color:
              borderColor ??
              (isWinner ? const Color(0xFF2563EB) : colors.borderLight),
          width: borderColor != null ? 2 : 1.5,
        ),
      ),
      child: ClipOval(
        child: logoUrl != null && logoUrl.isNotEmpty
            ? Image.network(
                logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _avatarFallback(name, isWinner),
              )
            : _avatarFallback(name, isWinner),
      ),
    );
  }

  String _lastTwoNameWords(String fullName) {
    final normalized = fullName.trim();
    if (normalized.isEmpty) return '?';
    final words = normalized.split(RegExp(r'\s+'));
    return words.length <= 2
        ? normalized
        : words.sublist(words.length - 2).join(' ');
  }

  Widget _avatarFallback(String name, bool isWinner) {
    return Center(
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isWinner ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
