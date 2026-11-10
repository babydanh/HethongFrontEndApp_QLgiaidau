import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/domain/services/tournament_manage_access.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_state_views.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/intro_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_merged_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/teams_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_register_bar.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/public_bracket_view.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sponsors_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/matches_tab.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_accordion.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_tab_bar_delegate.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/widgets/tournament_avatar.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_brand_fallback.dart';

/// The two facts of a match list that the tab bar depends on. A record so that
/// `select` only notifies when one of them actually changes.
typedef _MatchSummary = ({int liveCount, bool hasCompleted});

_MatchSummary _summarizeMatches(List<MatchModel>? matches) {
  var liveCount = 0;
  var hasCompleted = false;
  for (final match in matches ?? const <MatchModel>[]) {
    if (isLiveMatch(match)) liveCount++;
    final isRealResult =
        !(match.isBye || match.isByeMatch || match.isFullByeMatch) &&
        match.hasTeams &&
        match.isCompleted;
    if (isRealResult) hasCompleted = true;
  }
  return (liveCount: liveCount, hasCompleted: hasCompleted);
}

class TournamentIntroScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? inviteCode;

  const TournamentIntroScreen({
    super.key,
    required this.tournamentId,
    this.inviteCode,
  });

  @override
  ConsumerState<TournamentIntroScreen> createState() =>
      _TournamentIntroScreenState();
}

class _TournamentIntroScreenState extends ConsumerState<TournamentIntroScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<String> _tabIds = const [];
  int _introTabIndex = 0;
  String _selectedDivision = "";
  String? _selectedDivisionId;
  bool _divisionExpanded = true;
  String? _customInviteCode;
  bool _hasUserSwitchedTab = false;
  late final ScrollController _scrollController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshHeldDetail());
  }

  /// Data kept from an earlier visit is shown at once; fetch a fresh copy in
  /// the background so it never stays stale. Nothing to do on a first open,
  /// where the request is already in flight.
  void _refreshHeldDetail() {
    if (!mounted) return;
    final provider = tournamentIntroWithInviteProvider((
      id: widget.tournamentId,
      invite: widget.inviteCode,
    ));
    if (ref.read(provider).hasValue) ref.invalidate(provider);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final collapsed = _scrollController.offset >= 110.0;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  void _updateTabController(List<String> tabIds, {int? defaultIndex}) {
    final prev = _tabController;
    var hasSameTabs = prev != null && _tabIds.length == tabIds.length;
    for (var index = 0; hasSameTabs && index < tabIds.length; index++) {
      hasSameTabs = _tabIds[index] == tabIds[index];
    }
    if (hasSameTabs) return;

    final prevIndex = prev?.index;
    final previousTabId = prevIndex != null && prevIndex < _tabIds.length
        ? _tabIds[prevIndex]
        : null;
    final identityIndex = previousTabId == null
        ? -1
        : tabIds.indexOf(previousTabId);
    final count = tabIds.length;
    _tabIds = tabIds;

    // Keep a user-selected page by identity when optional tabs change position.
    final targetIndex =
        (!_hasUserSwitchedTab && defaultIndex != null && defaultIndex < count)
        ? defaultIndex
        : (identityIndex >= 0
              ? identityIndex
              : (prevIndex != null && prevIndex < count
                    ? prevIndex
                    : (defaultIndex != null && defaultIndex < count
                          ? defaultIndex
                          : 0)));

    final newController = TabController(
      length: count,
      vsync: this,
      initialIndex: targetIndex,
    );
    newController.addListener(() {
      if (newController.indexIsChanging || newController.index != targetIndex) {
        _hasUserSwitchedTab = true;
      }
    });

    _tabController = newController;
    // The old TabBar/TabBarView still reference [prev] until this frame ends.
    if (prev != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => prev.dispose());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeInvite = _customInviteCode ?? widget.inviteCode;
    final tournamentAsync = ref.watch(
      tournamentIntroWithInviteProvider((
        id: widget.tournamentId,
        invite: activeInvite,
      )),
    );
    final divisionsAsync = ref.watch(
      tournamentDivisionsProvider(widget.tournamentId),
    );
    // Start the roster request together with the tournament detail instead of
    // after it; only the Teams tab waits for it.
    ref.watch(introTeamsProvider(widget.tournamentId));
    final authState = ref.watch(authProvider);
    final authRole = authState.role;
    final userProfile = ref.watch(userProfileProvider).value;
    final currentUserId = userProfile?.id;
    final isAdmin = authState.isAdmin;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: ColoredBox(
        color: context.colors.bgDark,
        child: tournamentAsync.when(
          // A failed background refresh keeps the content already shown;
          // only a revoked access replaces it.
          skipError:
              tournamentAsync.hasValue &&
              !_isAccessDenied(tournamentAsync.error),
          data: (tournament) {
            if (tournament == null) {
              return NotFoundView(onGoHome: () => context.go('/home'));
            }

            // ─── ACCESS GATE: chỉ giải PRIVATE mới chặn người ngoài ───
            final isCreator = tournament.creatorId == currentUserId;
            final isClubRestricted = tournament.visibility == 'PRIVATE';

            if (isClubRestricted &&
                activeInvite == null &&
                !isAdmin &&
                !isCreator) {
              if (tournament.communityId != null &&
                  tournament.communityId!.isNotEmpty) {
                final membershipAsync = ref.watch(
                  myCommunityMembershipProvider(tournament.communityId!),
                );
                final isVerifiedMember = membershipAsync.maybeWhen(
                  data: (m) {
                    if (m == null) return false;
                    final s = m.status.toUpperCase();
                    return s == 'JOINED' ||
                        s == 'ADMIN' ||
                        s == 'OWNER' ||
                        s == 'APPROVED';
                  },
                  orElse: () => false,
                );
                if (!isVerifiedMember) {
                  return SafeArea(
                    child: Stack(
                      children: [
                        Positioned(
                          left: 12,
                          top: 8,
                          child: _backButton(context.colors),
                        ),
                        PrivateTournamentAccessView(
                          message:
                              'Đây là giải đấu nội bộ của Câu Lạc Bộ. Bạn cần tham gia Câu Lạc Bộ hoặc nhập mã mời từ Ban tổ chức để xem chi tiết.',
                          onGoHome: () => context.go('/home'),
                          onSubmitInviteCode: (code) {
                            setState(() {
                              _customInviteCode = code;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }
              } else {
                return SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 12,
                        top: 8,
                        child: _backButton(context.colors),
                      ),
                      PrivateTournamentAccessView(
                        message:
                            'Giải đấu này yêu cầu mã mời để xem thông tin chi tiết.',
                        onGoHome: () => context.go('/home'),
                        onSubmitInviteCode: (code) {
                          setState(() {
                            _customInviteCode = code;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }
            }

            final asyncDivRawList =
                divisionsAsync.value ?? const <Map<String, dynamic>>[];
            final asyncDivDetailsMap = <String, TournamentDivision>{
              for (final raw in asyncDivRawList)
                if (raw['id'] != null && raw['id'].toString().isNotEmpty)
                  raw['id'].toString(): TournamentDivision.fromJson(raw),
            };

            final divisions = tournament.divisions.isNotEmpty
                ? tournament.divisions.map((d) {
                    final detail = asyncDivDetailsMap[d.id];
                    if (detail != null) {
                      return d.copyWith(
                        bracketType: detail.bracketType ?? d.bracketType,
                        roundRobinLegs:
                            detail.roundRobinLegs ?? d.roundRobinLegs,
                        maxParticipants:
                            detail.maxParticipants ?? d.maxParticipants,
                        genderRestriction:
                            detail.genderRestriction ?? d.genderRestriction,
                      );
                    }
                    return d;
                  }).toList()
                : asyncDivRawList.map(TournamentDivision.fromJson).toList();

            return _buildContent(
              tournament.copyWith(divisions: divisions),
              authRole,
            );
          },
          loading: () => _buildLoadingState(),
          error: (err, stack) => _buildErrorState(err),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomBar(
        context,
        tournamentAsync.asData?.value,
        activeInvite,
        divisionsAsync.asData?.value,
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Tournament? tournament,
    String? activeInvite,
    List<Map<String, dynamic>>? divisionData,
  ) {
    // Thanh đăng ký nằm NGAY TRÊN thanh điều hướng và chiếm chỗ thật, nên
    // không đè lên nội dung như nút nổi trước đây.
    final registerBar = _buildRegistrationAction(
      context,
      tournament,
      activeInvite,
      divisionData,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [?registerBar, _buildFloatingBottomNav(context)],
    );
  }

  Widget? _buildRegistrationAction(
    BuildContext context,
    Tournament? tournament,
    String? activeInvite,
    List<Map<String, dynamic>>? divisionData,
  ) {
    if (tournament == null) return null;

    final now = DateTime.now();
    final isRegistrationNotStarted =
        tournament.registrationStartDate != null &&
        now.isBefore(tournament.registrationStartDate!);
    final isRegistrationExpired =
        tournament.registrationEndDate != null &&
        now.isAfter(tournament.registrationEndDate!);

    final divisions = (divisionData ?? const <Map<String, dynamic>>[])
        .map(TournamentDivisionOption.fromJson)
        .toList(growable: false);
    final hasDivisionRegistrationState = divisions.any(
      (division) => division.hasRegistrationOpenContract,
    );
    if (hasDivisionRegistrationState &&
        !divisions.any(
          (division) =>
              division.status?.trim().toUpperCase() != 'CANCELLED' &&
              division.isRegistrationOpen,
        )) {
      return null;
    }
    final isRegistrationOpen = StatusHelper.isTournamentRegistration(
      tournament.status,
    );
    if (!hasDivisionRegistrationState &&
        (!isRegistrationOpen ||
            tournament.isRegistrationLocked ||
            isRegistrationNotStarted ||
            isRegistrationExpired)) {
      return null;
    }

    final hasInvite = activeInvite?.trim().isNotEmpty == true;
    final queryParameters = <String, String>{
      if (hasInvite) 'invite': activeInvite!.trim(),
      if (_selectedDivisionId?.isNotEmpty == true)
        'divisionId': _selectedDivisionId!,
    };
    final registrationUri = Uri(
      pathSegments: ['register', tournament.id],
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();

    return TournamentRegisterBar(
      entryFee: tournament.entryFee,
      registrationEnd: tournament.registrationEndDate,
      onRegister: () => context.push(registrationUri),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context) => FloatingBottomNav(
    currentIndex: 1,
    onTabSelected: (index) {
      if (index != 1) context.go('/home?tab=$index');
    },
    onMenuTap: () => AppMenuSheet.show(context),
  );

  Widget _buildLoadingState() {
    return SafeArea(
      child: Stack(
        children: [
          const ShimmerBody(),
          Positioned(left: 12, top: 8, child: _backButton(context.colors)),
        ],
      ),
    );
  }

  Widget _buildTeamsLoadError() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.teamsLoadError,
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                ref.invalidate(introTeamsProvider(widget.tournamentId)),
            child: Text(l10n.infoRetry),
          ),
        ],
      ),
    );
  }

  static bool _isAccessDenied(Object? err) =>
      err != null &&
      (err is TournamentAccessDeniedException ||
          err.toString().contains('403') ||
          err.toString().contains('nội bộ') ||
          err.toString().contains('thành viên'));

  Widget _buildErrorState(Object err) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    if (_isAccessDenied(err)) {
      return SafeArea(
        child: Stack(
          children: [
            Positioned(left: 12, top: 8, child: _backButton(colors)),
            PrivateTournamentAccessView(
              message: err is TournamentAccessDeniedException
                  ? err.message
                  : 'Đây là giải đấu nội bộ của Câu Lạc Bộ. Bạn cần tham gia Câu Lạc Bộ hoặc nhập mã mời từ Ban tổ chức để xem chi tiết.',
              onGoHome: () => context.go('/home'),
              onSubmitInviteCode: (code) {
                setState(() {
                  _customInviteCode = code;
                });
              },
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          Positioned(left: 12, top: 8, child: _backButton(colors)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.error,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.tournamentLoadError,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '$err',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(
                    tournamentIntroWithInviteProvider((
                      id: widget.tournamentId,
                      invite: _customInviteCode ?? widget.inviteCode,
                    )),
                  ),
                  child: Text(l10n.infoRetry),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton(AppColorsExtension colors) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.bgCard.withValues(alpha: 0.88),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_rounded,
          color: colors.textPrimary,
          size: 20,
        ),
      ),
      onPressed: _goBack,
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Widget _buildContent(Tournament tournament, UserRole? role) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final followedAsync = ref.watch(followedTournamentsProvider);
    final isFollowing = followedAsync.maybeWhen(
      data: (items) => items.any((t) => t.id == tournament.id),
      orElse: () => false,
    );

    final authState = ref.watch(authProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final currentUserId = userProfile?.id;
    final isCreator = tournament.creatorId == currentUserId;
    final isAdmin = authState.isAdmin;
    final workspace = ref.watch(myTournamentWorkspaceProvider).value;
    final canManage = canManageTournament(
      tournamentId: tournament.id,
      userId: currentUserId,
      creatorId: tournament.creatorId,
      managedTournamentIds: {
        ...?workspace?.organizedTournaments.map((t) => t.id),
        ...?workspace?.coOrganizerTournaments.map((t) => t.id),
      },
    );
    final activeInvite = _customInviteCode ?? widget.inviteCode;
    final hasInvite = activeInvite != null && activeInvite.trim().isNotEmpty;

    // ─── ACCESS GATE: chỉ giải PRIVATE mới chặn người ngoài ───
    final isClubRestricted = tournament.visibility == 'PRIVATE';

    if (isClubRestricted && !isCreator && !isAdmin && !hasInvite) {
      final membership =
          tournament.communityId != null && tournament.communityId!.isNotEmpty
          ? ref
                .watch(myCommunityMembershipProvider(tournament.communityId!))
                .value
          : null;
      final isMember =
          membership != null &&
          (membership.status.toUpperCase() == 'JOINED' ||
              membership.status.toUpperCase() == 'ADMIN' ||
              membership.status.toUpperCase() == 'OWNER' ||
              membership.status.toUpperCase() == 'APPROVED');
      if (!isMember) {
        return Scaffold(
          backgroundColor: colors.bgDark,
          appBar: AppBar(
            backgroundColor: colors.bgCard,
            title: Text(tournament.name),
            leading: _backButton(colors),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 36,
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Giải đấu nội bộ câu lạc bộ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Giải đấu này chỉ dành riêng cho thành viên của câu lạc bộ hoặc người có mã mời. Vui lòng tham gia câu lạc bộ hoặc nhập mã mời để xem chi tiết.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (tournament.communityId != null &&
                      tournament.communityId!.isNotEmpty)
                    FilledButton.icon(
                      icon: const Icon(Icons.groups_rounded),
                      label: const Text('Xem câu lạc bộ'),
                      onPressed: () => context.push(
                        '/communities/${tournament.communityId}',
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if ((_selectedDivisionId == null || _selectedDivision.isEmpty) &&
        tournament.divisions.isNotEmpty) {
      _selectedDivision = tournament.divisions.first.name;
      _selectedDivisionId = tournament.divisions.first.id;
    }
    String? selectedMatchType;
    for (final division in tournament.divisions) {
      if (division.id == _selectedDivisionId) {
        selectedMatchType = division.matchType;
        break;
      }
    }
    final teamsAsync = ref.watch(introTeamsProvider(widget.tournamentId));
    // The flat public-only endpoint intentionally excludes Lite tournaments.
    // Lite detail must use the bracket projection, which is also the source
    // used by the management screen and web bracket.
    // Only these two facts decide the tab bar, so rebuild this screen when they
    // change, not on every poll or socket emission of the match list.
    final matchSummary = ref.watch(
      (tournament.isLite
              ? liteBracketMatchesProvider(widget.tournamentId)
              : matchesProvider(widget.tournamentId))
          .select((async) => _summarizeMatches(async.value)),
    );

    final isTeamSport =
        (tournament.teamSize ?? 0) > 1 ||
        tournament.sport.toLowerCase() == 'football' ||
        tournament.sport.toLowerCase() == 'bóng đá';

    final bool hasLive = matchSummary.liveCount > 0;
    final bool showLiveTab =
        StatusHelper.isTournamentInProgress(tournament.status) || hasLive;
    final bool hasResults =
        matchSummary.hasCompleted ||
        tournament.status.toLowerCase() == 'completed';
    final bool hasSponsors = tournament.sponsors.isNotEmpty;

    // Build Dynamic Tabs List & Pages List strictly according to Web Layout (Hình 2)
    final List<Widget> tabHeaders = [];
    final List<Widget> tabViews = [];
    final List<String> tabIds = [];

    // 1. Tab [Tổng quan] (Mặc định khi vào màn hình)
    final int overviewIndex = tabHeaders.length;
    tabHeaders.add(const Tab(height: 28, text: 'Tổng quan'));
    tabIds.add('overview');

    // 2. Tab [Giới thiệu]
    final int introIndex = tabHeaders.length;
    _introTabIndex = introIndex;
    tabHeaders.add(const Tab(height: 28, text: 'Giới thiệu'));
    tabIds.add('intro');

    // 3. Tab [Đội tham gia]
    tabHeaders.add(Tab(height: 28, text: l10n.tabTeams));
    tabIds.add('teams');

    // 4. Tab [Bảng đấu]
    tabHeaders.add(const Tab(height: 28, text: 'Bảng đấu'));
    tabIds.add('bracket');

    // 5. Lịch thi đấu.
    tabHeaders.add(Tab(height: 28, text: l10n.tabSchedule));
    tabIds.add('schedule');

    // 6. Tab [Tài trợ] (nếu có).
    if (hasSponsors) {
      tabHeaders.add(Tab(height: 28, text: l10n.tabSponsors));
      tabIds.add('sponsors');
    }

    // 7. Tab [Kết quả] là tab cuối, như Web: gộp "Đang diễn ra" vào đây. Người
    // xem thấy khi giải đang thi đấu hoặc đã có kết quả; Ban tổ chức luôn thấy.
    final bool showResultsTab = showLiveTab || hasResults || canManage;
    if (showResultsTab) {
      tabHeaders.add(_resultsTabHeader(colors, hasLive, matchSummary.liveCount));
      tabIds.add('results');
    }

    _updateTabController(tabIds, defaultIndex: overviewIndex);
    final controller = _tabController!;

    // Add Views for remaining tabs:
    // Tổng quan
    tabViews.add(
      OverviewTab(
        tournament: tournament,
        teamCount: teamsAsync.value?.length ?? 0,
        resolveImageUrl: _resolveImageUrl,
        onNavigateToIntro: _introTabIndex >= 0
            ? () => controller.animateTo(_introTabIndex)
            : null,
        isFollowing: isFollowing,
        onToggleFollow: () => _toggleFollow(tournament, isFollowing),
        inviteCode: activeInvite,
        hasSliverBanner: !tournament.isClubLite,
      ),
    );

    // Giới thiệu
    tabViews.add(
      IntroTab(tournament: tournament, resolveImageUrl: _resolveImageUrl),
    );

    // Đội tham gia
    tabViews.add(
      tournament.isClubLite
          ? SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 160),
              child: _buildLiteTeamList(teamsAsync.value ?? const []),
            )
          : (tournament.divisions.length > 1
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 160),
                    child: _buildDivisionsSelectorList(
                      tournament,
                      colors,
                      selectedContentBuilder: (division) => TeamsTab(
                        key: ValueKey('teams-inline-${division.id}'),
                        teams: teamsAsync.value ?? const [],
                        selectedDivision: division.name,
                        selectedDivisionId: division.id,
                        divisions: tournament.divisions,
                        isTeamSport: isTeamSport,
                        shrinkWrap: true,
                        showDivisionHeading: false,
                        isDoublesDivision: division.isDoubles,
                      ),
                    ),
                  )
                : TeamsTab(
                    key: ValueKey('teams-$_selectedDivisionId'),
                    teams: teamsAsync.value ?? const [],
                    selectedDivision: _selectedDivision,
                    selectedDivisionId: _selectedDivisionId,
                    divisions: tournament.divisions,
                    isTeamSport: isTeamSport,
                    isDoublesDivision:
                        tournament.divisions.firstOrNull?.isDoubles ?? false,
                  )),
    );

    // Bảng đấu: sơ đồ bracket nằm ngay trong row nội dung (như tab Đội), chỉ
    // sơ đồ, cuộn dọc hoặc ngang không chéo.
    PublicBracketLoader bracketFor(TournamentDivision? division) =>
        PublicBracketLoader(
          key: ValueKey('bracket-${division?.id ?? _selectedDivisionId}'),
          tournamentId: widget.tournamentId,
          divisionId: division?.id ?? _selectedDivisionId,
          bracketType: division?.bracketType ?? tournament.bracketType,
          // Only the organizers of this tournament score from the bracket; a
          // global ADMIN role alone must not grant it.
          canScoreMatch: canManage,
          canEditSeeds: canManage,
          canEditBracket: canManage,
        );
    tabViews.add(
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 160),
        child: tournament.divisions.length > 1
            ? _buildDivisionsSelectorList(
                tournament,
                colors,
                selectedContentBuilder: bracketFor,
                fullBleedContent: true,
              )
            : bracketFor(tournament.divisions.firstOrNull),
      ),
    );

    // Lịch thi đấu: một lưới chung cho mọi division, không lọc theo division.
    tabViews.add(
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 160),
        child: MatchesTab(
          key: const ValueKey('matches-tab'),
          tournamentId: widget.tournamentId,
          isLite: tournament.isLite,
          scheduleSettings: tournament.scheduleSettings,
          venueIds: tournament.venueIds,
          tournamentVenueName: tournament.venueName,
          tournamentLocationAddress: tournament.locationAddress,
          divisionNameById: {
            for (final division in tournament.divisions)
              division.id: division.name,
          },
          divisionMetadataById: {
            for (final division in tournament.divisions) division.id: division,
          },
        ),
      ),
    );

    // Tài trợ
    if (hasSponsors) {
      tabViews.add(
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 160),
          child: SponsorsTab(sponsors: tournament.sponsors),
        ),
      );
    }

    // Kết quả (tab cuối): bục vinh danh rồi bảng trận của hạng mục. Nhiều hạng
    // mục thì dùng danh sách hạng mục mở/thu như tab Đội, nội dung ngay dưới hàng.
    if (showResultsTab) {
      ResultsMergedTab resultsFor(
        TournamentDivision? division, {
        bool inline = false,
      }) => ResultsMergedTab(
        key: ValueKey('results-${division?.id ?? _selectedDivisionId}'),
        tournamentId: widget.tournamentId,
        isLite: tournament.isLite,
        canManage: canManage,
        divisionId: division?.id,
        divisionName: division?.name ?? _selectedDivision,
        matchType: division?.matchType ?? selectedMatchType,
        onShare: () => _shareTournament(tournament),
        inline: inline,
      );
      tabViews.add(
        tournament.divisions.length > 1
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 160),
                child: _buildDivisionsSelectorList(
                  tournament,
                  colors,
                  selectedContentBuilder: (division) =>
                      resultsFor(division, inline: true),
                ),
              )
            : resultsFor(null),
      );
    }

    // The roster only feeds the Teams tab: that tab shows its own placeholder
    // while loading or after a failure, so the other tabs are never blocked.
    final teamsTabIndex = tabIds.indexOf('teams');
    if (teamsTabIndex >= 0 && !teamsAsync.hasValue) {
      tabViews[teamsTabIndex] = teamsAsync.hasError
          ? _buildTeamsLoadError()
          : const ShimmerBody();
    }

    final isClubLite = tournament.isClubLite;
    final topPadding = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          tournamentIntroWithInviteProvider((
            id: widget.tournamentId,
            invite: activeInvite,
          )),
        );
        ref.invalidate(tournamentDivisionsProvider(widget.tournamentId));
        ref.invalidate(introTeamsProvider(widget.tournamentId));
        ref.invalidate(
          tournament.isLite
              ? liteBracketMatchesProvider(widget.tournamentId)
              : matchesProvider(widget.tournamentId),
        );
      },
      child: NestedScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(
            tournament,
            colors,
            isFollowing,
            topPadding,
            isClubLite: isClubLite,
            canManage: canManage,
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: TournamentTabBarDelegate(
              tabController: controller,
              tabHeaders: tabHeaders,
              colors: colors,
            ),
          ),
        ],
        body: TabBarView(controller: controller, children: tabViews),
      ),
    );
  }

  /// "Kết quả" tab label: a red dot and the live count while a match is in
  /// play, the trophy otherwise.
  Tab _resultsTabHeader(AppColorsExtension colors, bool hasLive, int liveCount) {
    if (!hasLive) {
      return const Tab(
        height: 28,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, size: 14),
            SizedBox(width: 4),
            Text('Kết quả'),
          ],
        ),
      );
    }
    return Tab(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Kết quả',
            style: TextStyle(
              color: colors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: colors.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$liveCount',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Danh sách hạng mục dùng chung cho các tab (xem [DivisionAccordion]).
  /// Bấm hạng mục đang chọn thì thu/mở nội dung; bấm hạng mục khác thì chọn và mở.
  Widget _buildDivisionsSelectorList(
    Tournament tournament,
    AppColorsExtension colors, {
    Widget Function(TournamentDivision division)? selectedContentBuilder,
    bool fullBleedContent = false,
  }) {
    return DivisionAccordion(
      fullBleedContent: fullBleedContent,
      divisions: tournament.divisions,
      selectedDivisionId: _selectedDivisionId,
      expanded: _divisionExpanded,
      fallbackBracketType: tournament.bracketType,
      isCompleted: tournament.status.toLowerCase() == 'completed',
      contentBuilder: selectedContentBuilder,
      onTapDivision: (div) {
        if (_selectedDivisionId == div.id) {
          if (selectedContentBuilder != null) {
            setState(() => _divisionExpanded = !_divisionExpanded);
          }
          return;
        }
        setState(() {
          _selectedDivisionId = div.id;
          _selectedDivision = div.name;
          if (selectedContentBuilder != null) _divisionExpanded = true;
        });
      },
    );
  }

  Widget _buildSliverAppBar(
    Tournament tournament,
    AppColorsExtension colors,
    bool isFollowing,
    double topPadding, {
    required bool isClubLite,
    required bool canManage,
  }) {
    final images = <String>[];
    if (tournament.bannerUrl != null && tournament.bannerUrl!.isNotEmpty) {
      images.add(tournament.bannerUrl!);
    }
    // The logo never stands in for the cover (a QR or a square logo stretched
    // over the whole banner); it always gets its own badge instead.
    final showLogoBadge = tournament.logoUrl?.isNotEmpty ?? false;
    final double bannerContentHeight = isClubLite ? 0.0 : 180.0;
    final double totalBannerHeight = bannerContentHeight + topPadding;

    Widget fallbackBanner() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        color: isDark ? const Color(0xFF16233A) : const Color(0xFFE8EEFB),
        child: const Center(
          child: SportoBrandFallback(
            withTagline: true,
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            semanticsLabel: 'SportO tournament fallback banner',
          ),
        ),
      );
    }

    final List<Shadow>? iconShadows = (_isCollapsed || isClubLite)
        ? null
        : [
            Shadow(
              offset: const Offset(0, 1),
              blurRadius: 4.0,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ];

    final Color currentIconColor = (_isCollapsed || isClubLite)
        ? colors.textPrimary
        : Colors.white;

    return SliverAppBar(
      pinned: true,
      primary: true,
      toolbarHeight: 44.0,
      expandedHeight: isClubLite ? 44.0 + topPadding : totalBannerHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: (_isCollapsed || isClubLite)
          ? colors.bgDark
          : Colors.transparent,
      iconTheme: IconThemeData(color: currentIconColor, opacity: 1.0),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: currentIconColor,
          size: 20,
          shadows: iconShadows,
        ),
        onPressed: _goBack,
        splashRadius: 20,
      ),
      // User requirement: Khi cuộn xuống qua banner thì hiện header với nút quay lại thôi, KHÔNG CẦN HIỆN TÊN GIẢI
      title: null,
      actions: [
        IconButton(
          icon: Icon(
            isFollowing
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: isFollowing ? AppTheme.primary : currentIconColor,
            size: 22,
            shadows: isFollowing ? null : iconShadows,
          ),
          splashRadius: 20,
          onPressed: () => _toggleFollow(tournament, isFollowing),
        ),
        IconButton(
          icon: Icon(
            Icons.share_outlined,
            color: currentIconColor,
            size: 20,
            shadows: iconShadows,
          ),
          splashRadius: 20,
          onPressed: () => _shareTournament(tournament),
        ),
        if (canManage)
          IconButton(
            tooltip: AppLocalizations.of(context)!.managementTitle,
            icon: Icon(
              Icons.settings_suggest_rounded,
              color: currentIconColor,
              size: 20,
              shadows: iconShadows,
            ),
            splashRadius: 20,
            onPressed: () {
              if (tournament.isSuperLite) {
                context.push('/lite-manage/${tournament.id}');
              } else {
                context.push('/organizer/tournaments/${tournament.id}/manage');
              }
            },
          ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: isClubLite
          ? null
          : FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  images.isNotEmpty
                      ? Image.network(
                          _resolveImageUrl(images.first),
                          fit: BoxFit.cover,
                          // Brand placeholder instead of an empty banner
                          // while the image is still downloading.
                          frameBuilder: (ctx, child, frame, wasSync) =>
                              wasSync || frame != null
                              ? child
                              : fallbackBanner(),
                          errorBuilder: (ctx, err, stack) => fallbackBanner(),
                        )
                      : fallbackBanner(),
                  // Top/Bottom gradient overlay for legibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                  if (showLogoBadge)
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: TournamentAvatar(
                        key: const ValueKey('tournament-intro-logo'),
                        imageUrl: _resolveImageUrl(tournament.logoUrl),
                        tournamentName: tournament.name,
                        sport: tournament.sport,
                        size: 58,
                        borderWidth: 2,
                        borderColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://sporto.asia$url';
  }

  Future<void> _toggleFollow(Tournament tournament, bool current) async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }
    final repo = ref.read(tournamentRepositoryProvider);
    try {
      if (current) {
        await repo.unfollowTournament(tournament.id);
      } else {
        await repo.followTournament(tournament.id);
      }
      ref.invalidate(followedTournamentsProvider);
    } catch (_) {}
  }

  Future<void> _shareTournament(Tournament tournament) async {
    final l10n = AppLocalizations.of(context)!;
    final shareUrl =
        tournament.isClubLite &&
            tournament.inviteCode != null &&
            tournament.inviteCode!.isNotEmpty
        ? 'https://sporto.asia/lite/tournaments/join/${Uri.encodeComponent(tournament.inviteCode!)}'
        : 'https://sporto.asia/tournaments/${tournament.id}';
    AppShareModal.show(
      context: context,
      title: tournament.name,
      subtitle:
          '${tournament.locationAddress ?? l10n.vietnam} • ${tournament.category ?? tournament.sport}',
      webUrl: shareUrl,
      imageUrl: tournament.logoUrl ?? tournament.bannerUrl,
      badgeText: tournament.isClubLite
          ? l10n.liteTournament
          : l10n.advancedTournament,
    );
  }

  Widget _buildLiteTeamList(List<Team> teams) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: colors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noParticipants,
              style: TextStyle(fontSize: 15, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: teams
          .map(
            (team) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (team.members.isNotEmpty)
                          Text(
                            team.members.join(', '),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.joined,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
