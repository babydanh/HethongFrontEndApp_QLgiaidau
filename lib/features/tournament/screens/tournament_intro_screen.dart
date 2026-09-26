import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_state_views.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/intro_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/live_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/teams_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sponsors_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/matches_tab.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_format_icons.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';

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
  int _currentTabCount = 0;
  int _introTabIndex = 0;
  String _selectedDivision = "";
  String? _selectedDivisionId;
  String? _customInviteCode;
  bool _hasUserSwitchedTab = false;
  bool _isHeaderVisible = true;
  double _lastScrollOffset = 0;

  void _updateTabController(int count, {int? defaultIndex}) {
    if (_tabController != null && _currentTabCount == count) return;
    final prev = _tabController;
    final prevIndex = prev?.index;
    _currentTabCount = count;

    // If the user hasn't actively switched tabs yet, always default to defaultIndex (overview tab)
    final targetIndex =
        (!_hasUserSwitchedTab && defaultIndex != null && defaultIndex < count)
        ? defaultIndex
        : (prevIndex != null && prevIndex < count
              ? prevIndex
              : (defaultIndex != null && defaultIndex < count
                    ? defaultIndex
                    : 0));

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
    prev?.dispose();
  }

  @override
  void dispose() {
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
          data: (tournament) {
            if (tournament == null) {
              return NotFoundView(onGoHome: () => context.go('/home'));
            }

            // ─── ACCESS GATE: Giải nội bộ CLB / Giải siêu lite / Private ───
            final isCreator = tournament.creatorId == currentUserId;
            final isClubRestricted =
                tournament.isClubTournament ||
                tournament.isClubLite ||
                (tournament.communityId != null &&
                    tournament.communityId!.isNotEmpty) ||
                tournament.visibility == 'PRIVATE';

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
        currentUserId,
        isAdmin,
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Tournament? tournament,
    String? activeInvite,
    String? currentUserId,
    bool isAdmin,
  ) {
    if (tournament == null) {
      return const SizedBox.shrink();
    }

    final isCreator = tournament.creatorId == currentUserId;
    final hasInvite = activeInvite?.trim().isNotEmpty == true;
    final isClubRestricted =
        tournament.isClubTournament ||
        tournament.isClubLite ||
        (tournament.communityId?.isNotEmpty ?? false) ||
        tournament.visibility == 'PRIVATE';

    var hasTournamentAccess =
        !isClubRestricted || isCreator || isAdmin || hasInvite;
    if (!hasTournamentAccess &&
        tournament.communityId != null &&
        tournament.communityId!.isNotEmpty) {
      final membership = ref
          .watch(myCommunityMembershipProvider(tournament.communityId!))
          .value;
      final membershipStatus = membership?.status.toUpperCase();
      hasTournamentAccess =
          membershipStatus == 'JOINED' ||
          membershipStatus == 'ADMIN' ||
          membershipStatus == 'OWNER' ||
          membershipStatus == 'APPROVED';
    }

    if (!hasTournamentAccess) return const SizedBox.shrink();

    final now = DateTime.now();
    final isRegistrationNotStarted =
        tournament.registrationStartDate != null &&
        now.isBefore(tournament.registrationStartDate!);
    final isRegistrationExpired =
        tournament.registrationEndDate != null &&
        now.isAfter(tournament.registrationEndDate!);
    final isRegOpen = StatusHelper.isTournamentRegistration(tournament.status);
    final canRegister =
        isRegOpen &&
        !tournament.isRegistrationLocked &&
        !isRegistrationNotStarted &&
        !isRegistrationExpired;
    final l10n = AppLocalizations.of(context)!;
    final registerLabel = isRegistrationNotStarted
        ? l10n.lite_registrationNotOpen
        : canRegister
        ? 'Đăng ký'
        : l10n.registerRegClosed;
    final queryParameters = <String, String>{
      if (hasInvite) 'invite': activeInvite!.trim(),
      if (_selectedDivisionId?.isNotEmpty == true)
        'divisionId': _selectedDivisionId!,
    };
    final registrationUri = Uri(
      pathSegments: ['register', tournament.id],
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: canRegister
                ? () => context.push(registrationUri)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.colors.bgSurface,
              disabledForegroundColor: context.colors.textMuted,
              elevation: canRegister ? 2 : 0,
              shadowColor: AppTheme.primary.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_reg_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  registerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Stack(
        children: [
          Positioned(left: 12, top: 8, child: _backButton(colors)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 12),
                Text(
                  l10n.tournamentLoading,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isAccessDenied =
        err is TournamentAccessDeniedException ||
        err.toString().contains('403') ||
        err.toString().contains('nội bộ') ||
        err.toString().contains('thành viên');

    if (isAccessDenied) {
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
    final activeInvite = _customInviteCode ?? widget.inviteCode;
    final hasInvite = activeInvite != null && activeInvite.trim().isNotEmpty;

    // ─── ACCESS GATE: Giải nội bộ CLB / Giải siêu lite / Private ───
    final isClubRestricted =
        tournament.isClubTournament ||
        tournament.isClubLite ||
        (tournament.communityId != null &&
            tournament.communityId!.isNotEmpty) ||
        tournament.visibility == 'PRIVATE';

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
    final teamsAsync = ref.watch(introTeamsProvider(widget.tournamentId));
    // The flat public-only endpoint intentionally excludes Lite tournaments.
    // Lite detail must use the bracket projection, which is also the source
    // used by the management screen and web bracket.
    final matchesAsync = ref.watch(
      tournament.isLite
          ? liteBracketMatchesProvider(widget.tournamentId)
          : matchesProvider(widget.tournamentId),
    );

    final isTeamSport =
        (tournament.teamSize ?? 0) > 1 ||
        tournament.sport.toLowerCase() == 'football' ||
        tournament.sport.toLowerCase() == 'bóng đá';

    final allMatches = matchesAsync.value ?? const <MatchModel>[];
    final liveMatches = allMatches.where((m) {
      final s = m.status.toLowerCase();
      return s == 'in_progress' || s == 'live' || s == 'ongoing';
    }).toList();

    final completedMatches = allMatches.where((m) {
      if (m.isBye || m.isByeMatch || m.isFullByeMatch) return false;
      if (!m.hasTeams) return false;
      return m.isCompleted;
    }).toList();

    final bool hasLive = liveMatches.isNotEmpty;
    final bool hasResults =
        completedMatches.isNotEmpty ||
        tournament.status.toLowerCase() == 'completed';
    final bool hasSponsors = tournament.sponsors.isNotEmpty;

    // Build Dynamic Tabs List & Pages List strictly according to Web Layout (Hình 2)
    final List<Widget> tabHeaders = [];
    final List<Widget> tabViews = [];

    // 1. Tab [🔴 Đang diễn ra (N)] nếu có trận Live
    if (hasLive) {
      tabHeaders.add(
        Tab(
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
                'Đang diễn ra',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.5,
                  vertical: 0.5,
                ),
                decoration: BoxDecoration(
                  color: colors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${liveMatches.length}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      tabViews.add(
        LiveTab(
          key: ValueKey('live-$_selectedDivisionId'),
          liveMatches: liveMatches,
          tournamentId: widget.tournamentId,
          divisions: tournament.divisions,
          selectedDivisionId: _selectedDivisionId,
          onSelectDivision: (div) {
            setState(() {
              _selectedDivisionId = div.id;
              _selectedDivision = div.name;
            });
          },
        ),
      );
    }

    // 2. Tab [🏆 Kết quả] CHỈ HIỆN KHI ĐÃ CÓ KẾT QUẢ / TRẬN ĐẤU HOÀN THÀNH
    if (hasResults) {
      tabHeaders.add(
        const Tab(
          height: 28,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_rounded, size: 14),
              SizedBox(width: 4),
              Text('Kết quả'),
            ],
          ),
        ),
      );
      tabViews.add(
        tournament.divisions.length > 1
            ? Column(
                children: [
                  _buildDivisionsSelectorList(tournament, colors),
                  Expanded(
                    child: ResultsTab(
                      key: ValueKey('results-$_selectedDivisionId'),
                      tournamentId: widget.tournamentId,
                      selectedDivisionId: _selectedDivisionId,
                      selectedDivision: _selectedDivision,
                    ),
                  ),
                ],
              )
            : ResultsTab(
                key: ValueKey('results-$_selectedDivisionId'),
                tournamentId: widget.tournamentId,
                selectedDivisionId: _selectedDivisionId,
                selectedDivision: _selectedDivision,
              ),
      );
    }

    // 3. Tab [Tổng quan] (Mặc định khi vào màn hình)
    final int overviewIndex = tabHeaders.length;
    tabHeaders.add(const Tab(height: 28, text: 'Tổng quan'));

    // 4. Tab [Giới thiệu]
    final int introIndex = tabHeaders.length;
    _introTabIndex = introIndex;
    tabHeaders.add(const Tab(height: 28, text: 'Giới thiệu'));

    // 5. Tab [Đội tham gia]
    tabHeaders.add(Tab(height: 28, text: l10n.tabTeams));

    // 6. Lịch thi đấu
    final int scheduleIndex = tabHeaders.length;
    tabHeaders.add(Tab(height: 28, text: l10n.tabSchedule));

    // 7. Tab [Bảng đấu]
    tabHeaders.add(const Tab(height: 28, text: 'Bảng đấu'));
    // 8. Tab [Tài trợ] (nếu có)
    if (hasSponsors) {
      tabHeaders.add(Tab(height: 28, text: l10n.tabSponsors));
    }

    _updateTabController(tabHeaders.length, defaultIndex: overviewIndex);
    final controller = _tabController!;

    // Add Views for remaining tabs:
    // Tổng quan
    tabViews.add(
      OverviewTab(
        tournament: tournament,
        teamCount: teamsAsync.value?.length ?? 0,
        resolveImageUrl: _resolveImageUrl,
        onNavigateToMatches: () {
          controller.animateTo(scheduleIndex);
        },
        onNavigateToIntro: _introTabIndex >= 0
            ? () => controller.animateTo(_introTabIndex)
            : null,
        isFollowing: isFollowing,
        onToggleFollow: () => _toggleFollow(tournament, isFollowing),
        inviteCode: activeInvite,
      ),
    );

    // Giới thiệu
    tabViews.add(
      IntroTab(
        tournament: tournament,
        resolveImageUrl: _resolveImageUrl,
      ),
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
                        isTeamSport: isTeamSport,
                        shrinkWrap: true,
                        showDivisionHeading: false,
                      ),
                    ),
                  )
                : TeamsTab(
                    key: ValueKey('teams-$_selectedDivisionId'),
                    teams: teamsAsync.value ?? const [],
                    selectedDivision: _selectedDivision,
                    selectedDivisionId: _selectedDivisionId,
                    isTeamSport: isTeamSport,
                  )),
    );

    // Lịch thi đấu (reuse the existing matches source, filters and match cards)
    tabViews.add(
      tournament.divisions.length > 1
          ? Column(
              children: [
                _buildDivisionsSelectorList(tournament, colors),
                Expanded(
                  child: MatchesTab(
                    key: ValueKey('matches-$_selectedDivisionId'),
                    tournamentId: widget.tournamentId,
                    selectedDivisionId: _selectedDivisionId,
                    selectedDivision: _selectedDivision,
                    isLite: tournament.isLite,
                  ),
                ),
              ],
            )
          : MatchesTab(
              key: ValueKey('matches-$_selectedDivisionId'),
              tournamentId: widget.tournamentId,
              selectedDivisionId: _selectedDivisionId,
              selectedDivision: _selectedDivision,
              isLite: tournament.isLite,
            ),
    );

    // Bảng đấu (BracketTab with divisions selector)
    tabViews.add(
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tournament.divisions.length > 1)
              _buildDivisionsSelectorList(tournament, colors),
            BracketTab(
              key: ValueKey('bracket-$_selectedDivisionId'),
              tournamentId: widget.tournamentId,
              selectedDivisionId: _selectedDivisionId,
              bracketType:
                  tournament.divisions
                      .where((d) => d.id == _selectedDivisionId)
                      .firstOrNull
                      ?.bracketType ??
                  tournament.bracketType,
              configuredLegs:
                  tournament.divisions
                      .where((d) => d.id == _selectedDivisionId)
                      .firstOrNull
                      ?.roundRobinLegs ??
                  1,
            ),
          ],
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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final currentOffset = notification.metrics.pixels;
          final delta = currentOffset - _lastScrollOffset;

          // Only trigger on vertical scrolls with valid scroll extent
          if (notification.metrics.axis == Axis.vertical) {
            if (currentOffset <= 20) {
              if (!_isHeaderVisible) {
                setState(() => _isHeaderVisible = true);
              }
            } else if (delta > 8 && currentOffset > 60) {
              // Lướt xuống (scroll down) -> Ẩn header
              if (_isHeaderVisible) {
                setState(() => _isHeaderVisible = false);
              }
            } else if (delta < -8) {
              // Lướt lên (scroll up) -> Hiện lại header
              if (!_isHeaderVisible) {
                setState(() => _isHeaderVisible = true);
              }
            }
          }
          _lastScrollOffset = currentOffset;
        }
        return false;
      },
      child: Column(
        children: [
          // ─── Clean Minimalist TopBar with Slide & Fade Animation ───
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              opacity: _isHeaderVisible ? 1.0 : 0.0,
              child: _isHeaderVisible
                  ? _buildTopBar(tournament, colors, isFollowing)
                  : const SizedBox.shrink(),
            ),
          ),

          // ─── Dynamic Tab Bar Navigation (Đang diễn ra, Kết quả, Tổng quan, Đội, Bảng đấu, Lịch...) ───
          _buildStickyTabBar(controller, tabHeaders, colors),

          // ─── Tab Views Content ───
          Expanded(
            child: teamsAsync.when(
              data: (_) =>
                  TabBarView(controller: controller, children: tabViews),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (err, st) => Center(
                child: Text('$err', style: TextStyle(color: colors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact division rows with optional row-local content.
  Widget _buildDivisionsSelectorList(
    Tournament tournament,
    AppColorsExtension colors, {
    Widget Function(TournamentDivision division)? selectedContentBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(tournament.divisions.length, (index) {
            final div = tournament.divisions[index];
            final isSelected = div.id == _selectedDivisionId;
            final maxP = div.maxParticipants ?? 0;
            final curP = div.participantCount;
            final countLabel = maxP > 0 ? '$curP/$maxP' : '$curP';
            final isFull =
                (maxP > 0 && curP >= maxP) ||
                tournament.status.toLowerCase() == 'completed';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                MergeSemantics(
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: '${div.name}, $countLabel',
                    child: InkWell(
                      onTap: () {
                        if (_selectedDivisionId == div.id) return;
                        setState(() {
                          _selectedDivisionId = div.id;
                          _selectedDivision = div.name;
                        });
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.12)
                                      : colors.bgSurface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: BracketFormatIcons.getIcon(
                                    div.bracketType,
                                    fallbackBracketType: tournament.bracketType,
                                    size: 15,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : colors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  div.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : colors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isFull) ...[
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(width: 7),
                              ],
                              Icon(
                                Icons.people_alt_outlined,
                                size: 13,
                                color: colors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                countLabel,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSelected && selectedContentBuilder != null)
                  selectedContentBuilder(div),
                if (index < tournament.divisions.length - 1)
                  Divider(height: 1, thickness: 1, color: colors.border),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    Tournament tournament,
    AppColorsExtension colors,
    bool isFollowing,
  ) {
    return Container(
      color: colors.bgCard,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 8,
        left: 12,
        right: 12,
      ),
      child: Row(
        children: [
          _backButton(colors),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tournament.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              isFollowing
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isFollowing ? AppTheme.primary : colors.textMuted,
              size: 22,
            ),
            onPressed: () => _toggleFollow(tournament, isFollowing),
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: colors.textMuted, size: 20),
            onPressed: () => _shareTournament(tournament),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyTabBar(
    TabController controller,
    List<Widget> tabHeaders,
    AppColorsExtension colors,
  ) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.primary, width: 2.5),
          insets: EdgeInsets.only(bottom: 0),
        ),
        dividerColor: Colors.transparent,
        labelColor: AppTheme.primary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: tabHeaders,
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
