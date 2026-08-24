import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_banner.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_state_views.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/about_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/teams_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/gallery_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sponsors_tab.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TournamentIntroScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentIntroScreen({super.key, required this.tournamentId});

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
  bool _isFollowLoading = false;

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
      tournamentIntroProvider(widget.tournamentId),
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
                    tournamentIntroProvider(widget.tournamentId),
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
    final l10n = AppLocalizations.of(context)!;
    final hasSponsors = tournament.sponsors.isNotEmpty;
    final tabCount = hasSponsors ? 5 : 4;
    _updateTabController(tabCount);
    final controller = _tabController!;

    if ((_selectedDivisionId == null || _selectedDivision.isEmpty) &&
        tournament.divisions.isNotEmpty) {
      _selectedDivision = tournament.divisions.first.name;
      _selectedDivisionId = tournament.divisions.first.id;
    }
    final teamsAsync = ref.watch(introTeamsProvider(widget.tournamentId));
    final isTeamSport =
        (tournament.teamSize ?? 0) > 1 ||
        tournament.sport.toLowerCase() == 'football' ||
        tournament.sport.toLowerCase() == 'bóng đá';
    final colors = context.colors;

    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(tournament, colors),
            Expanded(
              child: NestedScrollView(
                physics: const BouncingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: TournamentHeaderView(
                      tournament: tournament,
                      colors: colors,
                      compact: false,
                      selectedDivision: _selectedDivision,
                      selectedDivisionId: _selectedDivisionId,
                      onChangedDivision: (div) {
                        setState(() {
                          _selectedDivision = div.name;
                          _selectedDivisionId = div.id;
                        });
                      },
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      tabController: controller,
                      colors: colors,
                      showSponsors: hasSponsors,
                    ),
                  ),
                ],
                body: teamsAsync.when(
                  data: (teams) => TabBarView(
                    controller: controller,
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 160),
                        child: AboutTab(
                          tournament: tournament,
                          teamCount: teams.length,
                          resolveImageUrl: _resolveImageUrl,
                        ),
                      ),
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 160),
                        child: tournament.isClubLite
                            ? _buildLiteTeamList(teams)
                            : TeamsTab(
                                teams: teams,
                                selectedDivision: _selectedDivision,
                                selectedDivisionId: _selectedDivisionId,
                                isTeamSport: isTeamSport,
                              ),
                      ),
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 160),
                        child: BracketTab(
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
                      ),
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 160),
                        child: GalleryTab(
                          galleryImages: tournament.galleryImages,
                          resolveImageUrl: _resolveImageUrl,
                        ),
                      ),
                      if (hasSponsors)
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 160),
                          child: SponsorsTab(sponsors: tournament.sponsors),
                        ),
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      l10n.teamsLoadError,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Floating Registration Button (Active or Disabled if closed)
        Positioned(
          right: 16,
          bottom: 88,
          child: _registrationButton(tournament),
        ),
      ],
    );
  }

  Widget _buildTopBar(Tournament tournament, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final followedAsync = ref.watch(followedTournamentsProvider);
    final isFollowing = followedAsync.maybeWhen(
      data: (items) => items.any((t) => t.id == tournament.id),
      orElse: () => false,
    );

    return AppBar(
      backgroundColor: colors.bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: colors.bgCard.withValues(alpha: 0.88),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: colors.textPrimary,
            size: 19,
          ),
        ),
        onPressed: _goBack,
      ),
      title: Text(
        tournament.name.toUpperCase(),
        key: ValueKey(tournament.name),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.1,
        ),
      ),
      actions: [
        IconButton(
          icon: _isFollowLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                )
              : Icon(
                  isFollowing
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isFollowing ? AppTheme.primary : colors.textPrimary,
                  size: 22,
                ),
          onPressed: _isFollowLoading
              ? null
              : () => _toggleFollow(tournament, isFollowing),
          tooltip: isFollowing ? l10n.unfollow : l10n.follow,
        ),
        IconButton(
          icon: Icon(Icons.share_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => _shareTournament(tournament),
          tooltip: l10n.share,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Future<void> _toggleFollow(Tournament tournament, bool isFollowing) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }
    if (_isFollowLoading) return;

    setState(() => _isFollowLoading = true);
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      if (isFollowing) {
        await repo.unfollowTournament(tournament.id);
      } else {
        await repo.followTournament(tournament.id);
      }
      ref.invalidate(followedTournamentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFollowing ? l10n.unfollowedTournament : l10n.followedTournament,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.followError}: $e')));
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith("http")) return url;
    return "https://sporto.asia$url";
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
                      style: TextStyle(
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

  Widget _registrationButton(Tournament tournament) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final statusUpper = tournament.status.toUpperCase();

    // Hide button completely if tournament is already in progress, completed or cancelled
    if (statusUpper == 'IN_PROGRESS' ||
        statusUpper == 'ONGOING' ||
        statusUpper == 'COMPLETED' ||
        statusUpper == 'FINISHED' ||
        statusUpper == 'CANCELLED') {
      return const SizedBox.shrink();
    }

    final isClosed =
        statusUpper == 'REGISTRATION_CLOSED' ||
        statusUpper == 'CLOSED' ||
        (tournament.registrationEndDate != null &&
            now.isAfter(tournament.registrationEndDate!));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: isClosed
            ? []
            : [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: isClosed ? context.colors.bgCard : AppTheme.primary,
          disabledBackgroundColor: context.colors.bgCard,
          foregroundColor: isClosed ? context.colors.textMuted : Colors.white,
          disabledForegroundColor: context.colors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: isClosed
                ? BorderSide(color: context.colors.border)
                : BorderSide.none,
          ),
        ),
        onPressed: isClosed
            ? null
            : () {
                final auth = ref.read(authProvider);
                if (!auth.isAuthenticated) {
                  context.push('/login');
                  return;
                }
                if (tournament.isClubLite &&
                    tournament.inviteCode != null &&
                    tournament.inviteCode!.isNotEmpty) {
                  context.push('/lite-join/${tournament.inviteCode}');
                  return;
                }
                final query =
                    _selectedDivisionId != null &&
                        _selectedDivisionId!.isNotEmpty
                    ? '?divisionId=$_selectedDivisionId'
                    : '';
                context.push('/register/${tournament.id}$query');
              },
        child: Text(
          isClosed ? l10n.registrationClosed : l10n.register,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isClosed ? context.colors.textMuted : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final AppColorsExtension colors;
  final bool showSponsors;

  _TabBarDelegate({
    required this.tabController,
    required this.colors,
    required this.showSponsors,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
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
        tabs: [
          Tab(height: 34, text: l10n.tabAbout),
          Tab(height: 34, text: l10n.tabTeams),
          Tab(height: 34, text: l10n.tabBracket),
          Tab(height: 34, text: l10n.tabGallery),
          if (showSponsors) Tab(height: 34, text: l10n.tabSponsors),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 44;

  @override
  double get minExtent => 44;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      tabController != oldDelegate.tabController ||
      showSponsors != oldDelegate.showSponsors ||
      colors != oldDelegate.colors;
}
