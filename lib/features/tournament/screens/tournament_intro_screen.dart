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
  String _selectedDivision = "Tất cả";
  String? _selectedDivisionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // default 4, updated dynamically
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final authRole = ref.watch(authProvider).role;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: tournamentAsync.when(
        data: (tournament) {
          if (tournament == null) {
            return NotFoundView(onGoHome: () => context.go('/home'));
          }
          return _buildContent(tournament, authRole);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Lỗi: $err', style: TextStyle(color: context.colors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(tournamentProvider(widget.tournamentId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
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

  Widget _buildContent(Tournament tournament, UserRole? role) {
    if (_selectedDivisionId == null && _selectedDivision != "Tất cả" && tournament.divisions.isNotEmpty) {
      _selectedDivisionId = tournament.divisions.first.id;
    }
    final teamsAsync = ref.watch(teamsProvider(widget.tournamentId));
    final viewerCountAsync = ref.watch(
      presenceCountProvider((role: "intro", tournamentId: widget.tournamentId)),
    );
    final colors = context.colors;

    const tabCount = 4;
    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: colors.bgDark,
            leading: IconButton(
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
              onPressed: () {
                final auth = ref.read(authProvider);
                if (auth.tokenCode != null && auth.tokenCode != 'SESSION') {
                  ref.read(authProvider.notifier).signOut();
                }
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            title: Text(
              tournament.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              // Share button
              IconButton(
                icon: Icon(Icons.share_rounded, color: colors.textPrimary, size: 20),
                onPressed: () => _shareTournament(tournament),
                tooltip: 'Chia sẻ',
              ),
              if (viewerCountAsync.hasValue &&
                  viewerCountAsync.value != null &&
                  viewerCountAsync.value! > 0)
                _viewerBadge(viewerCountAsync.value!),
              const SizedBox(width: 8),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: TournamentCollapsibleHeaderDelegate(
              tournament: tournament,
              colors: colors,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabController,
              colors: colors,
            ),
          ),
        ];
      },
      body: teamsAsync.when(
        data: (teams) => _buildTabContent(tournament, teams, role),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => _buildTabContent(tournament, [], role),
      ),
    );
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

  Widget _viewerBadge(int count) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.error,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    Tournament tournament,
    List<Team> teams,
    UserRole? role,
  ) {
    final isLive = StatusHelper.isTournamentInProgress(tournament.status);
    final divisionsSet = tournament.divisions
        .map((d) => d.name)
        .toSet()
        .toList();
    final divisions = ["Tất cả", ...divisionsSet];

    return Column(
      children: [
        // Global Division Filter (Visible on Teams, Bracket, and Standings tabs)
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            if (_tabController.index == 0) {
              return const SizedBox.shrink(); // Hide filter on "About" tab
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DivisionFilterSegment(
                divisions: divisions,
                selectedDivision: _selectedDivision,
                onDivisionChanged: (val) {
                  setState(() {
                    _selectedDivision = val;
                    if (val == "Tất cả") {
                      _selectedDivisionId = null;
                    } else {
                      final matched = tournament.divisions.firstWhere(
                        (d) => d.name == val,
                        orElse: () => tournament.divisions.first,
                      );
                      _selectedDivisionId = matched.id;
                    }
                  });
                },
              ),
            );
          },
        ),
        Expanded(
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  AboutTab(
                    tournament: tournament,
                    teamCount: teams.length,
                    resolveImageUrl: _resolveImageUrl,
                  ),
                  TeamsTab(
                    teams: teams,
                    selectedDivision: _selectedDivision,
                  ),
                  BracketTab(
                    tournamentId: widget.tournamentId,
                    selectedDivisionId: _selectedDivisionId,
                  ),
                  GalleryTab(
                    galleryImages: tournament.galleryImages,
                    resolveImageUrl: _resolveImageUrl,
                  ),
                ],
              ),
              if (!isLive)
                Positioned(
                  right: 16,
                  bottom: 120,
                  child: _buildBottomBar(tournament, role),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Tournament tournament, UserRole? role) {
    final isLive = StatusHelper.isTournamentInProgress(tournament.status);
    final isRegistration =
        StatusHelper.isTournamentRegistration(tournament.status) ||
        StatusHelper.isTournamentDraft(tournament.status) ||
        StatusHelper.isTournamentUpcoming(tournament.status);
    final isCompleted = StatusHelper.isTournamentCompleted(tournament.status);

    if (isLive) {
      return _liveButton(role, tournament.id);
    }
    if (isRegistration) {
      return _registrationButton(tournament);
    }
    return isCompleted
        ? _viewBracketButton("Xem kết quả")
        : _viewBracketButton("Xem lịch thi đấu");
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
        onPressed: () => context.push('/register/${tournament.id}'),
        icon: const Icon(Icons.edit_note_rounded, size: 22),
        label: const Text(
          "Đăng ký tham gia",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _liveButton(UserRole? role, String tournamentId) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: context.colors.error.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.error,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        onPressed: () {
          context.go('/live-matches/$tournamentId');
        },
        icon: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.bgCard,
          ),
        ),
        label: const Text(
          "Xem trực tiếp",
          style: TextStyle(fontWeight: FontWeight.bold),
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
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            dividerColor: Colors.transparent,
            labelColor: AppTheme.primary,
            unselectedLabelColor: colors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: "Giới thiệu"),
              Tab(text: "Danh sách đội"),
              Tab(text: "Bảng thi đấu"),
              Tab(text: "Gallery"),
            ],
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
