import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_banner.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_filter_segment.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_state_views.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/about_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/teams_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/gallery_tab.dart';

class TournamentIntroScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentIntroScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentIntroScreen> createState() =>
      _TournamentIntroScreenState();
}

class _TournamentIntroScreenState extends ConsumerState<TournamentIntroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDivision = "";
  String? _selectedDivisionId;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentIntroProvider(widget.tournamentId));
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
            return _buildContent(tournament, authRole);
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
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 8,
            child: _backButton(colors),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Đang tải giải đấu...',
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
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 8,
            child: _backButton(colors),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: colors.error, size: 42),
                const SizedBox(height: 12),
                Text(
                  'Không tải được giải đấu',
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
                  onPressed: () =>
                      ref.invalidate(tournamentIntroProvider(widget.tournamentId)),
                  child: const Text('Thử lại'),
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
    final auth = ref.read(authProvider);
    if (auth.tokenCode != null && auth.tokenCode != 'SESSION') {
      ref.read(authProvider.notifier).signOut();
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Widget _buildContent(Tournament tournament, UserRole? role) {
    if ((_selectedDivisionId == null || _selectedDivision.isEmpty) && tournament.divisions.isNotEmpty) {
      _selectedDivision = tournament.divisions.first.name;
      _selectedDivisionId = tournament.divisions.first.id;
    }
    final teamsAsync = ref.watch(introTeamsProvider(widget.tournamentId));
    final colors = context.colors;

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildTopBar(tournament, colors),
              TournamentHeaderView(
                tournament: tournament,
                colors: colors,
                compact: false,
              ),
              SizedBox(
                height: 38,
                child: _TabBarDelegate(
                  tabController: _tabController,
                  colors: colors,
                ).build(context, 0, false),
              ),
              teamsAsync.when(
                data: (teams) => _buildTabContent(tournament, teams, role),
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
                error: (e, _) => _buildTabContent(tournament, [], role),
              ),
              const SizedBox(height: 160),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 96,
          child: _buildBottomBar(tournament, role),
        ),
      ],
    );
  }

  Widget _buildTopBar(
    Tournament tournament,
    AppColorsExtension colors,
  ) {
    final followedAsync = ref.watch(followedTournamentsProvider);
    final isFollowing = followedAsync.maybeWhen(
      data: (items) => items.any((t) => t.id == tournament.id),
      orElse: () => false,
    );

    return Container(
      color: colors.bgDark,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.bgCard.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: colors.textPrimary,
                    size: 20,
                  ),
                ),
                onPressed: _goBack,
              ),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      tournament.name.toUpperCase(),
                      key: ValueKey(tournament.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: _isFollowLoading
                    ? SizedBox(
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
                        color: isFollowing
                            ? AppTheme.primary
                            : colors.textPrimary,
                        size: 22,
                      ),
                onPressed: _isFollowLoading
                    ? null
                    : () => _toggleFollow(tournament, isFollowing),
                tooltip: isFollowing ? 'Bỏ theo dõi' : 'Theo dõi',
              ),
              IconButton(
                icon: Icon(
                  Icons.share_rounded,
                  color: colors.textPrimary,
                  size: 20,
                ),
                onPressed: () => _shareTournament(tournament),
                tooltip: 'Chia sẻ',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFollow(
    Tournament tournament,
    bool isFollowing,
  ) async {
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
            isFollowing ? 'Đã bỏ theo dõi giải đấu' : 'Đã theo dõi giải đấu',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật theo dõi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith("http")) return url;
    return "https://qlgiaidau.esports.vn$url";
  }

  Future<void> _shareTournament(Tournament tournament) async {
    final text =
        '${tournament.name} - ${tournament.category ?? tournament.sport}';
    final url = 'https://giaidau.vnvar.com/tournaments/${tournament.id}';
    await SharePlus.instance.share(
      ShareParams(text: '$text\n\n$url'),
    );
  }

  Widget _buildTabContent(
    Tournament tournament,
    List<Team> teams,
    UserRole? role,
  ) {
    final divisions = tournament.divisions
        .map((d) => d.name)
        .toSet()
        .toList();

    return Column(
      children: [
        // Global Division Filter (Visible on Teams, Bracket, and Standings tabs)
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            if (_tabController.index == 0 || divisions.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: DivisionFilterSegment(
                divisions: divisions,
                selectedDivision: _selectedDivision,
                onDivisionChanged: (val) {
                  setState(() {
                    _selectedDivision = val;
                    final matchedList = tournament.divisions.where((d) => d.name == val);
                    if (matchedList.isNotEmpty) {
                      _selectedDivisionId = matchedList.first.id;
                    } else if (tournament.divisions.isNotEmpty) {
                      _selectedDivisionId = tournament.divisions.first.id;
                    }
                  });
                },
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            switch (_tabController.index) {
              case 0:
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AboutTab(
                    tournament: tournament,
                    teamCount: teams.length,
                    resolveImageUrl: _resolveImageUrl,
                  ),
                );
              case 1:
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TeamsTab(
                    teams: teams,
                    selectedDivision: _selectedDivision,
                  ),
                );
              case 2:
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: BracketTab(
                    tournamentId: widget.tournamentId,
                    selectedDivisionId: _selectedDivisionId,
                  ),
                );
              case 3:
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GalleryTab(
                    galleryImages: tournament.galleryImages,
                    resolveImageUrl: _resolveImageUrl,
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(Tournament tournament, UserRole? role) {
    final isCompleted = StatusHelper.isTournamentCompleted(tournament.status);
    if (isCompleted) {
      return _viewBracketButton("Xem kết quả");
    }
    return _registrationButton(tournament);
  }

  Widget _viewBracketButton(String label) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        onPressed: () {
          _tabController.animateTo(2);
        },
        icon: const Icon(Icons.account_tree_rounded, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _registrationButton(Tournament tournament) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        onPressed: () => context.push('/register/${tournament.id}'),
        child: const Text(
          "Đăng ký",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final AppColorsExtension colors;

  _TabBarDelegate({
    required this.tabController,
    required this.colors,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: colors.bgDark,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color: colors.border.withValues(alpha: 0.5),
            ),
          ),
          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            dividerColor: Colors.transparent,
            labelColor: AppTheme.primary,
            unselectedLabelColor: colors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            tabs: const [
              Tab(height: 32, text: "Giới thiệu"),
              Tab(height: 32, text: "Danh sách đội"),
              Tab(height: 32, text: "Bảng thi đấu"),
              Tab(height: 32, text: "Thư viện"),
            ],
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 38;

  @override
  double get minExtent => 38;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
