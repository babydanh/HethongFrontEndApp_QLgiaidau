import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_banner.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_filter_segment.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/leaderboard_view.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_state_views.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_registration_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_teams_empty.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/widgets/countdown_timer.dart';

class TournamentIntroScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentIntroScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentIntroScreen> createState() => _TournamentIntroScreenState();
}

class _TournamentIntroScreenState extends ConsumerState<TournamentIntroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDivision = "Tất cả";
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkFollowing();
  }

  Future<void> _checkFollowing() async {
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final following = await repo.isFollowing(widget.tournamentId);
      if (mounted) setState(() => _isFollowing = following);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowLoading = true);
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      if (_isFollowing) {
        await repo.unfollowTournament(widget.tournamentId);
        setState(() => _isFollowing = false);
      } else {
        await repo.followTournament(widget.tournamentId);
        setState(() => _isFollowing = true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Đã theo dõi giải đấu' : 'Đã bỏ theo dõi'),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
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
                onPressed: () => ref.invalidate(tournamentProvider(widget.tournamentId)),
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
    final teamsAsync = ref.watch(teamsProvider(widget.tournamentId));
    final viewerCountAsync = ref.watch(presenceCountProvider(
      (role: "intro", tournamentId: widget.tournamentId),
    ));
    final colors = context.colors;

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
              if (viewerCountAsync.hasValue &&
                  viewerCountAsync.value != null &&
                  viewerCountAsync.value! > 0)
                _viewerBadge(viewerCountAsync.value!),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                TournamentBanner(tournament: tournament),
              ],
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

  Widget _buildTabContent(Tournament tournament, List<Team> teams, UserRole? role) {
    return Stack(
      children: [
        TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(tournament, teams.length),
            _buildTeamsTab(teams),
            _buildBracketTab(tournament),
            _buildLeaderboardTab(tournament),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 120,
          child: _buildBottomBar(tournament, role),
        ),
      ],
    );
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith("http")) return url;
    return "https://qlgiaidau.esports.vn$url";
  }

  Widget _buildAboutTab(Tournament tournament, int teamCount) {
    final colors = context.colors;
    final resolvedAvatar = _resolveImageUrl(tournament.creatorAvatarUrl);
    final creatorName = tournament.creatorFullName ?? "Ban Tổ Chức";

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "BAN TỔ CHỨC",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  backgroundImage: resolvedAvatar.isNotEmpty ? NetworkImage(resolvedAvatar) : null,
                  child: resolvedAvatar.isEmpty
                      ? const Icon(Icons.person, color: AppTheme.primary, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            creatorName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.border.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.success,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Mới Tạo",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Người sáng lập giải đấu",
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 16),
            if (tournament.description.isNotEmpty) ...[
              Text(
                "GIỚI THIỆU GIẢI ĐẤU",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    tournament.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: 16),
            ],
            if (tournament.status == 'upcoming' && tournament.registrationStartDate != null) ...[
              const SizedBox(height: 4),
              CountdownTimer(targetDate: tournament.registrationStartDate!, compact: false),
              const SizedBox(height: 16),
              Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: 16),
            ],
            Text(
              "CƠ CẤU GIẢI THƯỞNG",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  tournament.prizeDescription?.isNotEmpty == true
                      ? tournament.prizeDescription!
                      : "Đang cập nhật",
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 16),
            Text(
              "THÔNG TIN LIÊN HỆ",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            if (tournament.contactInfo != null &&
                (tournament.contactInfo!['phone'] != null ||
                    tournament.contactInfo!['email'] != null)) ...[
              if (tournament.contactInfo!['phone'] != null)
                Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 18, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      tournament.contactInfo!['phone'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              if (tournament.contactInfo!['phone'] != null &&
                  tournament.contactInfo!['email'] != null)
                const SizedBox(height: 8),
              if (tournament.contactInfo!['email'] != null)
                Row(
                  children: [
                    Icon(Icons.email_rounded, size: 18, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      tournament.contactInfo!['email'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ] else ...[
              Text(
                "Chưa cập nhật",
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(Tournament tournament) {
    final standingsAsync = ref.watch(standingsProvider(tournament.id));
    final colors = context.colors;

    return standingsAsync.when(
      data: (standings) {
        final filteredStandings = _selectedDivision == "Tất cả"
            ? standings
            : standings.where((s) => s.group == _selectedDivision).toList();

        final divisionsSet = standings.map((s) => s.group.isNotEmpty ? s.group : "Khác").toSet();
        final divisions = ["Tất cả", ...divisionsSet];

        return Column(
          children: [
            DivisionFilterSegment(
              divisions: divisions,
              selectedDivision: _selectedDivision,
              onDivisionChanged: (val) {
                setState(() {
                  _selectedDivision = val;
                });
              },
            ),
            Expanded(
              child: LeaderboardView(
                standings: filteredStandings,
                selectedDivision: _selectedDivision,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          "Lỗi khi tải bảng xếp hạng",
          style: TextStyle(color: colors.error),
        ),
      ),
    );
  }

  Widget _buildTeamsTab(List<Team> teams) {
    final colors = context.colors;
    if (teams.isEmpty) {
      return const TeamsEmptyView();
    }
    String getDivision(Team t) => t.group.isNotEmpty ? t.group : "Khác";

    final divisionsSet = teams.map(getDivision).toSet().toList();
    final divisions = ["Tất cả", ...divisionsSet];

    final filteredTeams = _selectedDivision == "Tất cả"
        ? teams
        : teams.where((t) => getDivision(t) == _selectedDivision).toList();

    final grouped = <String, List<Team>>{};
    for (var t in filteredTeams) {
      final div = getDivision(t);
      grouped.putIfAbsent(div, () => []).add(t);
    }
    final sortedDivisions = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DivisionFilterSegment(
          divisions: divisions,
          selectedDivision: _selectedDivision,
          onDivisionChanged: (val) {
            setState(() {
              _selectedDivision = val;
            });
          },
        ),
        Expanded(
          child: filteredTeams.isEmpty
              ? Center(
                  child: Text(
                    "Không có đội nào",
                    style: TextStyle(color: colors.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                  children: sortedDivisions.map((division) {
                    final teamsInDiv = grouped[division]!;
                    final isFemale = division.contains("Nữ");
                    final isMale = division.contains("Nam");
                    final themeColor = isFemale
                        ? const Color(0xFFE91E63)
                        : isMale
                            ? const Color(0xFF2196F3)
                            : AppTheme.primary;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                division,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.bgSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${teamsInDiv.length}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...teamsInDiv.map((team) => _buildExpandableTeamCard(team)),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildExpandableTeamCard(Team team) {
    final colors = context.colors;
    final divisionLabel = team.group.isNotEmpty ? team.group : "Đơn nam";
    final isCheckedIn = team.isCheckedIn;
    final isFemale = divisionLabel.contains("Nữ");
    final isMale = divisionLabel.contains("Nam");
    final themeColor = isFemale
        ? const Color(0xFFE91E63)
        : isMale
            ? const Color(0xFF2196F3)
            : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.all(12),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: team.photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        team.photoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.group,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                    )
                  : const Icon(Icons.group, color: AppTheme.primary, size: 22),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  team.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  divisionLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  "${team.members.length} VĐV",
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCheckedIn ? colors.success : colors.error,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isCheckedIn ? "Đã check-in" : "Chưa check-in",
                  style: TextStyle(
                    fontSize: 10,
                    color: isCheckedIn ? colors.success : colors.error,
                  ),
                ),
                if (team.seed > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Seed #${team.seed}",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          children: List.generate(team.members.length, (index) {
            return _buildMemberRow(
              team.members[index],
              index == 0,
              colors,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMemberRow(String memberName, bool isCaptain, AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Text(
              memberName.isNotEmpty ? memberName[0].toUpperCase() : "?",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  memberName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (isCaptain) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      "Đội Trưởng",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.person_outline_rounded, size: 16, color: colors.textMuted),
        ],
      ),
    );
  }

  Widget _buildBracketTab(Tournament tournament) {
    return BracketViewScreen(
      tournamentId: tournament.id,
      isEmbedded: true,
    );
  }

  Widget _buildBottomBar(Tournament tournament, UserRole? role) {
    final hasRole = role != null;
    final isLive = tournament.status == "in_progress";
    final isRegistration = tournament.status == "registration" || tournament.status == "draft";
    final isCompleted = tournament.status == "completed";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nút theo dõi
        _followButton(),
        const SizedBox(width: 8),
        if (hasRole) _enterButton(role),
        if (hasRole && isLive) const SizedBox(width: 12),
        if (isLive) _liveButton(role, tournament.id),
        if (!hasRole && !isLive && isRegistration) _registrationButton(tournament),
        if (!hasRole && !isLive && !isRegistration)
          isCompleted
              ? _viewBracketButton("Xem kết quả")
              : _viewBracketButton("Xem lịch thi đấu"),
      ],
    );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        onPressed: () {
          _tabController.animateTo(2);
        },
        icon: const Icon(Icons.account_tree_rounded, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => TournamentRegistrationSheet(tournament: tournament),
          );
        },
        icon: const Icon(Icons.edit_note_rounded, size: 22),
        label: const Text(
          "Đăng ký tham gia",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _enterButton(UserRole? role) {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        onPressed: () {
          if (role == UserRole.admin) {
            context.go('/admin/tournament/${widget.tournamentId}');
          } else {
            _tabController.animateTo(2);
          }
        },
        icon: const Icon(Icons.login_rounded, size: 22),
        label: Text(
          role == UserRole.admin ? "Vào bảng quản trị" : "Xem sơ đồ thi đấu",
          style: const TextStyle(fontWeight: FontWeight.bold),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        onPressed: () {
          context.go('/live-matches/$tournamentId');
        },
        icon: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        label: const Text(
          "Xem trực tiếp",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _followButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isFollowing
          ? OutlinedButton.icon(
              onPressed: _isFollowLoading ? null : _toggleFollow,
              icon: _isFollowLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bookmark_rounded, size: 16),
              label: const Text("Đang theo dõi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            )
          : FilledButton.icon(
              onPressed: _isFollowLoading ? null : _toggleFollow,
              icon: _isFollowLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bookmark_border_rounded, size: 16),
              label: const Text("Theo dõi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final AppColorsExtension colors;

  _TabBarDelegate({required this.tabController, required this.colors});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            dividerColor: Colors.transparent,
            labelColor: AppTheme.primary,
            unselectedLabelColor: colors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: const [
              Tab(text: "Giới thiệu"),
              Tab(text: "Danh sách đội"),
              Tab(text: "Bảng thi đấu"),
              Tab(text: "Bảng xếp hạng"),
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
