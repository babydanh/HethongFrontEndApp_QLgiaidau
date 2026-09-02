import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_state_views.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/live_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/matches_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/teams_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sponsors_tab.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
  String _selectedDivision = "";
  String? _selectedDivisionId;

  void _updateTabController(int count) {
    if (_tabController != null && _currentTabCount == count) return;
    final prev = _tabController;
    final prevIndex = prev?.index ?? 0;
    _currentTabCount = count;
    _tabController = TabController(
      length: count,
      vsync: this,
      initialIndex: prevIndex < count ? prevIndex : 0,
    );
    prev?.dispose();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(
      tournamentIntroWithInviteProvider((
        id: widget.tournamentId,
        invite: widget.inviteCode,
      )),
    );
    final divisionsAsync = ref.watch(
      tournamentDivisionsProvider(widget.tournamentId),
    );
    final authRole = ref.watch(authProvider).role;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: ColoredBox(
        color: context.colors.bgDark,
        child: tournamentAsync.when(
          data: (tournament) {
            if (tournament == null) {
              return NotFoundView(onGoHome: () => context.go('/home'));
            }
            final divisions = tournament.divisions.isNotEmpty
                ? tournament.divisions
                : (divisionsAsync.value ?? const <Map<String, dynamic>>[])
                      .map(TournamentDivision.fromJson)
                      .toList();
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
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: 1,
        onTabSelected: (index) {
          if (index == 2) {
            context.go('/profile');
          } else {
            context.go('/home');
          }
        },
        onProfileTap: () => context.go('/profile'),
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
                      invite: widget.inviteCode,
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
          Icons.arrow_back_rounded,
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

    if ((_selectedDivisionId == null || _selectedDivision.isEmpty) &&
        tournament.divisions.isNotEmpty) {
      _selectedDivision = tournament.divisions.first.name;
      _selectedDivisionId = tournament.divisions.first.id;
    }
    final teamsAsync = ref.watch(introTeamsProvider(widget.tournamentId));
    final matchesAsync = ref.watch(matchesProvider(widget.tournamentId));

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
      final s = m.status.toLowerCase();
      return s == 'completed' || s == 'finished';
    }).toList();

    final bool hasLive = liveMatches.isNotEmpty;
    final bool hasResults =
        completedMatches.isNotEmpty || tournament.status.toLowerCase() == 'completed';
    final bool hasSponsors = tournament.sponsors.isNotEmpty;

    // Build Dynamic Tabs List & Pages List strictly according to Web Layout (Hình 2)
    final List<Widget> tabHeaders = [];
    final List<Widget> tabViews = [];

    // 1. Tab [🔴 Đang diễn ra (N)] nếu có trận Live
    if (hasLive) {
      tabHeaders.add(
        Tab(
          height: 34,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${liveMatches.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      tabViews.add(LiveTab(liveMatches: liveMatches));
    }

    // 2. Tab [🏆 Kết quả] CHỈ HIỆN KHI ĐÃ CÓ KẾT QUẢ / TRẬN ĐẤU HOÀN THÀNH
    if (hasResults) {
      tabHeaders.add(
        const Tab(
          height: 34,
          text: 'Kết quả',
        ),
      );
      tabViews.add(
        ResultsTab(
          key: ValueKey('results-$_selectedDivisionId'),
          tournamentId: widget.tournamentId,
          selectedDivisionId: _selectedDivisionId,
          selectedDivision: _selectedDivision,
        ),
      );
    }

    // 3. Tab [Tổng quan]
    tabHeaders.add(const Tab(height: 34, text: 'Tổng quan'));

    // 4. Tab [Đội tham gia]
    tabHeaders.add(Tab(height: 34, text: l10n.tabTeams));

    // 5. Tab [Bảng đấu]
    final int bracketIndex = tabHeaders.length;
    tabHeaders.add(const Tab(height: 34, text: 'Bảng đấu'));

    // 6. Tab [Lịch thi đấu]
    final int matchesIndex = tabHeaders.length;
    tabHeaders.add(const Tab(height: 34, text: 'Lịch thi đấu'));

    // 7. Tab [Tài trợ] (nếu có)
    if (hasSponsors) {
      tabHeaders.add(Tab(height: 34, text: l10n.tabSponsors));
    }

    _updateTabController(tabHeaders.length);
    final controller = _tabController!;

    // Add Views for remaining tabs:
    // Tổng quan
    tabViews.add(
      OverviewTab(
        tournament: tournament,
        teamCount: teamsAsync.value?.length ?? 0,
        resolveImageUrl: _resolveImageUrl,
        onNavigateToMatches: () {
          controller.animateTo(matchesIndex);
        },
        onSelectDivision: (div) {
          setState(() {
            _selectedDivisionId = div.id;
            _selectedDivision = div.name;
          });
          controller.animateTo(bracketIndex);
        },
        isFollowing: isFollowing,
        onToggleFollow: () => _toggleFollow(tournament, isFollowing),
      ),
    );

    // Đội tham gia
    tabViews.add(
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 160),
        child: tournament.isClubLite
            ? _buildLiteTeamList(teamsAsync.value ?? const [])
            : TeamsTab(
                teams: teamsAsync.value ?? const [],
                selectedDivision: _selectedDivision,
                selectedDivisionId: _selectedDivisionId,
                isTeamSport: isTeamSport,
              ),
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

    // Lịch thi đấu (MatchesTab)
    tabViews.add(
      MatchesTab(
        key: ValueKey('matches-$_selectedDivisionId'),
        tournamentId: widget.tournamentId,
        selectedDivisionId: _selectedDivisionId,
        selectedDivision: _selectedDivision,
      ),
    );

    // Tài trợ
    if (hasSponsors) {
      tabViews.add(
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 160),
          child: SponsorsTab(
            sponsors: tournament.sponsors,
          ),
        ),
      );
    }

    return Column(
      children: [
        // ─── Clean Minimalist TopBar (Bỏ hoàn toàn dropdown trên đầu) ───
        _buildTopBar(tournament, colors, isFollowing),

        // ─── Dynamic Tab Bar Navigation (Đang diễn ra, Kết quả, Tổng quan, Đội, Bảng đấu, Lịch...) ───
        _buildStickyTabBar(controller, tabHeaders, colors),

        // ─── Tab Views Content ───
        Expanded(
          child: teamsAsync.when(
            data: (_) => TabBarView(
              controller: controller,
              children: tabViews,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
            error: (err, st) => Center(
              child: Text(
                '$err',
                style: TextStyle(color: colors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Danh sách Phân hạng trực quan chuẩn Web (Hình 2)
  Widget _buildDivisionsSelectorList(
    Tournament tournament,
    AppColorsExtension colors,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tournament.divisions.map((div) {
          final isSelected = div.id == _selectedDivisionId;
          final maxP = div.maxParticipants ?? 0;
          final curP = div.participantCount;
          final isFull = maxP > 0 && curP >= maxP;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : colors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : colors.border.withValues(alpha: 0.6),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDivisionId = div.id;
                  _selectedDivision = div.name;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: isSelected ? AppTheme.primary : colors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        div.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primary
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                    if (isFull) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bgDark,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          'Đã kết thúc / Đủ',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          size: 13,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          maxP > 0 ? '$curP / $maxP' : '$curP',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
              isFollowing ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isFollowing ? AppTheme.primary : colors.textMuted,
              size: 22,
            ),
            onPressed: () => _toggleFollow(tournament, isFollowing),
          ),
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: colors.textMuted,
              size: 20,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        dividerColor: Colors.transparent,
        labelColor: AppTheme.primary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
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
    final shareUrl = tournament.isClubLite &&
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
