import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_progress_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/widgets/app_responsive.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/public_tournament_type_sheet.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/rank_tier_badge.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/features/profile/screens/achievements_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedSport = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final profileAsync = ref.watch(userProfileProvider);
    final rankingsAsync = ref.watch(userRankingsProvider);
    final footballTeamsAsync = ref.watch(myFootballTeamsProvider);
    final workspaceAsync = ref.watch(myTournamentWorkspaceProvider);
    final isAuth = ref.watch(authProvider).isAuthenticated;

    if (!isAuth) {
      return Scaffold(
        backgroundColor: colors.bgDark,
        appBar: AppBar(
          title: Text(l10n.dashboard_title),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.dashboard_customize_rounded,
                    size: 40,
                    color: colors.info,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.dashboard_loginPrompt,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: Text(l10n.loginButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        title: Text(l10n.dashboard_title),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(myTournamentWorkspaceProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.zero,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: AppResponsive.padding(
                  MediaQuery.sizeOf(context).width,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeader(
                      profileAsync: profileAsync,
                      rankingsAsync: rankingsAsync,
                      footballTeamsAsync: footballTeamsAsync,
                    ),
                    const SizedBox(height: 16),

                    // Sport Category Filter Chips
                    _buildSportFilterChips(colors),
                    const SizedBox(height: 16),

                    // Detailed ELO rankings cards (filtered by _selectedSport)
                    _buildRankingsSection(context, rankingsAsync),
                    const SizedBox(height: 20),

                    // Recent Achievements (filtered by _selectedSport)
                    AchievementsTab(selectedSport: _selectedSport),
                    const SizedBox(height: 20),

                    workspaceAsync.when(
                      loading: () => const _DashboardLoadingCard(),
                      error: (error, _) => _DashboardErrorCard(
                        onRetry: () => ref
                            .read(myTournamentWorkspaceProvider.notifier)
                            .refresh(),
                      ),
                      data: (workspace) =>
                          _WorkspaceDashboardContent(workspace: workspace),
                    ),
                    const SizedBox(height: 16),
                    _QuickActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSportFilterChips(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];
    final sports = [
      {'id': 'all', 'label': l10n.infoAll, 'icon': Icons.grid_view_rounded},
      ...categories.map(
        (category) => <String, Object>{
          'id': category.slug,
          'label': category.name,
          'icon': _profileSportIcon(category.slug),
        },
      ),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sports.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sport = sports[index];
          final isSelected = _selectedSport == sport['id'];
          final icon = sport['icon'] as IconData;
          return GestureDetector(
            onTap: () => setState(() => _selectedSport = sport['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : colors.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : colors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sport['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _profileSportIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'tennis':
        return Icons.sports_tennis_rounded;
      case 'football':
        return Icons.sports_soccer_rounded;
      case 'badminton':
        return Icons.sports_tennis_outlined;
      case 'table_tennis':
        return Icons.sports_rounded;
      default:
        return Icons.sports_handball_rounded;
    }
  }

  Widget _buildRankingsSection(
    BuildContext context,
    AsyncValue<List<PlayerRanking>> rankingsAsync,
  ) {
    final colors = context.colors;

    return rankingsAsync.when(
      data: (rankings) {
        final playedRankings =
            rankings.where((ranking) {
              if (ranking.matchesPlayed <= 0) return false;
              if (_selectedSport == 'all') return true;

              final sportKey = (ranking.categoryId ?? ranking.categoryName ?? '')
                  .trim()
                  .toLowerCase();
              final sel = _selectedSport.toLowerCase();

              if (sel == 'pickleball' &&
                  (sportKey.contains('pickle') || sportKey.contains('padd'))) {
                return true;
              }
              if (sel == 'badminton' &&
                  (sportKey.contains('badminton') || sportKey.contains('cầu'))) {
                return true;
              }
              if (sel == 'table_tennis' &&
                  (sportKey.contains('table') || sportKey.contains('bàn'))) {
                return true;
              }
              if (sel == 'tennis' && sportKey.contains('tennis')) {
                return true;
              }
              if (sel == 'football' &&
                  (sportKey.contains('foot') ||
                      sportKey.contains('socc') ||
                      sportKey.contains('bóng'))) {
                return true;
              }

              return sportKey == sel;
            }).toList()
              ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));

        if (playedRankings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildPrivateNoRankState(colors),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: playedRankings
                .map((ranking) => _buildPrivateRankCard(context, ranking))
                .toList(),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: colors.border),
          ),
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _buildPrivateNoRankState(colors),
      ),
    );
  }

  Widget _buildPrivateNoRankState(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 42, color: colors.textMuted),
          const SizedBox(height: 10),
          Text(
            l10n.publicProfileNoPlayedElo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.publicProfileNoPlayedEloHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateRankCard(BuildContext context, PlayerRanking ranking) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final tierColor = TierPalette.fromElo(
      ranking.eloPoints,
      ranking.tierName,
    ).badgeBg;
    final winRate = ranking.matchesPlayed > 0
        ? (ranking.matchesWon / ranking.matchesPlayed * 100).round()
        : 0;
    final isDoubles =
        ranking.matchType == 'DOUBLES' || ranking.matchType == 'MIXED_DOUBLES';
    final streakType = ranking.currentStreakType?.toUpperCase();
    final streakColor = streakType == 'WIN'
        ? const Color(0xFF2563EB)
        : streakType == 'LOSS'
        ? const Color(0xFFDC2626)
        : colors.textMuted;
    final streakText = streakType == 'WIN'
        ? l10n.publicProfileWinStreak(ranking.currentStreakCount)
        : streakType == 'LOSS'
        ? l10n.publicProfileLossStreak(ranking.currentStreakCount)
        : l10n.publicProfileNoStreak;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EloHistoryScreen(
              userId: ranking.userId,
              userName: ranking.fullName,
              avatarUrl: ranking.avatarUrl,
              currentElo: ranking.eloPoints,
              tierName: ranking.tierName,
              categoryId: ranking.categoryId,
              categoryName: ranking.categoryName,
              initialScope: 'PUBLIC',
              matchType: ranking.matchType,
              genderRestriction: ranking.genderRestriction ?? '__NONE__',
              partnerId: ranking.partnerId,
              lockRatingScope: true,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDoubles ? Icons.people_alt_rounded : Icons.person_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ranking.categoryName?.isNotEmpty == true
                        ? ranking.categoryName!
                        : l10n.publicProfileUserFallback,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  isDoubles
                      ? ranking.matchType == 'MIXED_DOUBLES'
                            ? l10n.publicProfileScopeMixedDoubles
                            : l10n.publicProfileScopeDoubles
                      : l10n.publicProfileScopeSingles,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.textMuted,
                ),
              ],
            ),
            if (isDoubles && ranking.partnerName?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.publicProfilePartner}: ${ranking.partnerName}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RankTierBadge(
                        tierName: ranking.tierName,
                        elo: ranking.eloPoints,
                        sportName: ranking.categoryName,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ELO',
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ranking.eloPoints}',
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCompactProfileStat(
                  l10n.publicProfileMatchesShort,
                  '${ranking.matchesPlayed}',
                  colors,
                ),
                _buildCompactProfileStat(
                  l10n.infoWin,
                  '${ranking.matchesWon}',
                  colors,
                ),
                _buildCompactProfileStat(
                  l10n.publicProfileWinRateShort,
                  '$winRate%',
                  colors,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (winRate / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  winRate >= 60 ? colors.success : tierColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  streakType == 'NONE'
                      ? Icons.remove_circle_outline_rounded
                      : Icons.local_fire_department_rounded,
                  color: streakColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${l10n.publicProfileCurrentStreak}: $streakText',
                  style: TextStyle(
                    color: streakColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactProfileStat(
    String label,
    String value,
    AppColorsExtension colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceDashboardContent extends StatelessWidget {
  const _WorkspaceDashboardContent({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final roleSummary = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _PendingInviteSection(workspace: workspace)),
            const SizedBox(width: 16),
            Expanded(child: _RoleSection(workspace: workspace)),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkspaceOverview(workspace: workspace),
            const SizedBox(height: 16),
            wide
                ? roleSummary
                : Column(
                    children: [
                      _PendingInviteSection(workspace: workspace),
                      const SizedBox(height: 16),
                      _RoleSection(workspace: workspace),
                    ],
                  ),
            const SizedBox(height: 16),
            _AssignedMatchesSection(workspace: workspace),
            const SizedBox(height: 16),
            _UnifiedTournamentsSection(workspace: workspace),
          ],
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.profileAsync,
    required this.rankingsAsync,
    required this.footballTeamsAsync,
  });

  final AsyncValue<dynamic> profileAsync;
  final AsyncValue<dynamic> rankingsAsync;
  final AsyncValue<dynamic> footballTeamsAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = profileAsync.asData?.value.fullName ?? l10n.dashboard_user;
    final email = profileAsync.asData?.value.email as String?;
    final avatarUrl = profileAsync.asData?.value.avatarUrl as String?;
    final rankings = rankingsAsync.asData?.value ?? const [];
    final footballTeams = footballTeamsAsync.asData?.value ?? const [];
    final bestFootballTeam = footballTeams.isEmpty
        ? null
        : footballTeams.reduce((a, b) => a.eloPoints >= b.eloPoints ? a : b);

    return EloProgressCard(
      userName: name,
      userEmail: email,
      avatarUrl: avatarUrl,
      rankings: rankings,
      footballTeam: bestFootballTeam,
      onTapProfile: () => context.push('/profile'),
    ).animate().fadeIn(duration: 260.ms);
  }
}

class _WorkspaceOverview extends StatelessWidget {
  const _WorkspaceOverview({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _OverviewMetric(
            icon: Icons.notifications_active_rounded,
            color: context.colors.warning,
            label: l10n.dashboard_invites,
            value: '${workspace.pendingInviteCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewMetric(
            icon: Icons.verified_user_rounded,
            color: AppTheme.primary,
            label: l10n.dashboard_roles,
            value: '${workspace.activeRoleCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewMetric(
            icon: Icons.sports_score_rounded,
            color: const Color(0xFF10B981),
            label: l10n.dashboard_refereeMatchesCount,
            value: '${workspace.refereeMatches.length}',
          ),
        ),
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingInviteSection extends StatelessWidget {
  const _PendingInviteSection({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pendingInvites = workspace.refereeInvites
        .where((invite) => invite.isPending)
        .toList();
    if (pendingInvites.isEmpty) {
      return const SizedBox.shrink();
    }

    final latestInvite = pendingInvites.first;
    return _SectionCard(
      title: l10n.dashboard_pendingInvitesTitle,
      actionLabel: l10n.dashboard_openList,
      onTap: () => context.push('/referee/invites'),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.gavel_rounded,
            label: latestInvite.tournamentName,
            value: latestInvite.categoryName.isNotEmpty
                ? latestInvite.categoryName
                : l10n.dashboard_refereeInviteFallback,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: l10n.dashboard_inviteDate,
            value: latestInvite.assignedAt != null
                ? DateFormatterUtils.formatDateTime(
                    latestInvite.assignedAt!.toLocal(),
                  )
                : l10n.dashboard_updateInProgress,
          ),
        ],
      ),
    );
  }
}

class _RoleSection extends StatelessWidget {
  const _RoleSection({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <Widget>[
      if (workspace.organizedTournaments.isNotEmpty)
        _RoleChip(
          icon: Icons.workspace_premium_rounded,
          label: l10n.dashboard_organizer,
          count: workspace.organizedTournaments.length,
          color: const Color(0xFF10B981),
        ),
      if (workspace.coOrganizerTournaments.isNotEmpty)
        _RoleChip(
          icon: Icons.groups_rounded,
          label: l10n.dashboard_coOrganizer,
          count: workspace.coOrganizerTournaments.length,
          color: AppTheme.primary,
        ),
      if (workspace.refereeTournaments.isNotEmpty)
        _RoleChip(
          icon: Icons.gavel_rounded,
          label: l10n.infoReferee,
          count: workspace.refereeTournaments.length,
          color: AppTheme.refereeColor,
        ),
      if (workspace.participatingTournaments.isNotEmpty)
        _RoleChip(
          icon: Icons.sports_tennis_rounded,
          label: l10n.infoPlayer,
          count: workspace.participatingTournaments.length,
          color: context.colors.info,
        ),
    ];

    return _SectionCard(
      title: l10n.dashboard_myRoles,
      child: items.isEmpty
          ? _EmptySectionText(l10n.dashboard_noRolesDesc)
          : Wrap(spacing: 10, runSpacing: 10, children: items),
    );
  }
}

class _AssignedMatchesSection extends StatelessWidget {
  const _AssignedMatchesSection({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matches = workspace.refereeMatches.take(3).toList();
    return _SectionCard(
      title: l10n.dashboard_assignedMatches,
      actionLabel: workspace.refereeMatches.isNotEmpty
          ? l10n.dashboard_viewInvites
          : null,
      onTap: workspace.refereeMatches.isNotEmpty
          ? () => context.push('/referee/invites')
          : null,
      child: matches.isEmpty
          ? _EmptySectionText(l10n.dashboard_noAssignedMatches)
          : Column(
              children: matches.map((match) {
                final stageDisplay = MatchRoundLabel.formatStageOrGroupName(
                  match.stageName,
                  l10n: l10n,
                );
                final subtitle = [
                  if (stageDisplay.isNotEmpty) stageDisplay,
                  if (match.groupName.isNotEmpty &&
                      !match.groupName.toUpperCase().contains('BRACKET') &&
                      !match.groupName.toUpperCase().contains('MAIN'))
                    match.groupName,
                  l10n.dashboard_roundLabel(match.roundNumber),
                ].join(' • ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AssignmentTile(
                    title: match.tournamentName,
                    subtitle: subtitle,
                    participants: match.participantLabel,
                    meta: _formatMatchMeta(match, l10n),
                    onTap: () => context.push('/live/${match.id}'),
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _formatMatchMeta(
    TournamentAssignedMatch match,
    AppLocalizations l10n,
  ) {
    final parts = <String>[];
    if (match.courtName.isNotEmpty) {
      parts.add(match.courtName);
    }
    if (match.scheduledAt != null) {
      parts.add(
        DateFormatterUtils.formatDateTime(match.scheduledAt!.toLocal()),
      );
    }
    return parts.isEmpty ? l10n.dashboard_waitingSchedule : parts.join(' • ');
  }
}

class _UnifiedTournamentsSection extends StatefulWidget {
  const _UnifiedTournamentsSection({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  State<_UnifiedTournamentsSection> createState() =>
      _UnifiedTournamentsSectionState();
}

class _UnifiedTournamentsSectionState
    extends State<_UnifiedTournamentsSection> {
  bool _isExpanded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final workspace = widget.workspace;

    // Deduplicate all tournaments (Organized, Co-Organized, Participating)
    final Map<String, Tournament> tournamentMap = {};
    for (final t in workspace.organizedTournaments) {
      tournamentMap[t.id] = t;
    }
    for (final t in workspace.coOrganizerTournaments) {
      tournamentMap[t.id] = t;
    }
    for (final t in workspace.participatingTournaments) {
      tournamentMap[t.id] = t;
    }

    final allTournaments = tournamentMap.values.toList()
      ..sort((a, b) {
        if (a.isClubLite == b.isClubLite) return 0;
        return a.isClubLite ? -1 : 1;
      });

    // Filter by search query
    final filteredTournaments = allTournaments.where((t) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return t.name.toLowerCase().contains(q) ||
          t.sport.toLowerCase().contains(q);
    }).toList();

    final visibleTournaments = _isExpanded
        ? filteredTournaments
        : filteredTournaments.take(4).toList();

    final remainingCount = filteredTournaments.length - 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboard_myTournaments(allTournaments.length),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              if (allTournaments.isNotEmpty)
                Text(
                  l10n.dashboard_tournamentCount(allTournaments.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Bar
          if (allTournaments.length > 2) ...[
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.dashboard_searchHint,
                  hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: colors.textMuted,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // List of Tournament Cards
          if (filteredTournaments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 36,
                      color: colors.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? l10n.dashboard_noSearchResults
                          : l10n.dashboard_noTournaments,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Column(
              children: visibleTournaments.map((tournament) {
                final isOwner = workspace.organizedTournaments.any(
                  (item) => item.id == tournament.id,
                );
                final isCoOrg = workspace.coOrganizerTournaments.any(
                  (item) => item.id == tournament.id,
                );
                final isParticipant = workspace.participatingTournaments.any(
                  (item) => item.id == tournament.id,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TournamentTile(
                    tournament: tournament,
                    isOwner: isOwner,
                    isCoOrg: isCoOrg,
                    isParticipant: isParticipant,
                  ),
                );
              }).toList(),
            ),

            // "Xem thêm" / "Thu gọn" button
            if (filteredTournaments.length > 4) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: TextButton.icon(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  label: Text(
                    _isExpanded
                        ? l10n.dashboard_collapse
                        : l10n.dashboard_showMore(remainingCount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboard_quickActions,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _QuickActionRow(
            icon: Icons.bolt_rounded,
            title: l10n.dashboard_createLite,
            subtitle: l10n.dashboard_createLiteSub,
            onTap: () => _openLiteCreation(context),
          ),
          const Divider(height: 24),
          _QuickActionRow(
            icon: Icons.notifications_rounded,
            title: l10n.settingsNotifications,
            subtitle: l10n.dashboard_notificationsSub,
            onTap: () => context.push('/notifications'),
          ),
          const Divider(height: 24),
          _QuickActionRow(
            icon: Icons.leaderboard_rounded,
            title: l10n.dashboardRankings,
            subtitle: l10n.dashboardRankingsSub,
            onTap: () => context.push('/rankings'),
          ),
          const Divider(height: 24),
          _QuickActionRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: l10n.dashboardChat,
            subtitle: l10n.dashboardChatSub,
            onTap: () => context.push('/chat'),
          ),
          const Divider(height: 24),
          _QuickActionRow(
            icon: Icons.flag_outlined,
            title: l10n.dashboardReports,
            subtitle: l10n.dashboardReportsSub,
            onTap: () => context.push('/profile/reports'),
          ),
          const Divider(height: 24),
          _QuickActionRow(
            icon: Icons.sports_soccer_rounded,
            title: l10n.dashboardFootballTeams,
            subtitle: l10n.dashboardFootballTeamsSub,
            onTap: () => context.push('/football-teams'),
          ),
          const Divider(height: 24),
          _QuickActionRow(
            icon: Icons.groups_rounded,
            title: l10n.dashboard_clubInvites,
            subtitle: l10n.dashboard_clubInvitesSub,
            onTap: () => context.push('/club-invites'),
          ),
          const Divider(height: 24),
          _QuickActionRow(
            icon: Icons.person_rounded,
            title: l10n.dashboard_profile,
            subtitle: l10n.dashboard_profileSub,
            onTap: () => context.push('/profile'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 180.ms, duration: 260.ms);
  }

  void _openLiteCreation(BuildContext context) {
    showPublicTournamentTypeSheet(context);
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (actionLabel != null && onTap != null)
                TextButton(onPressed: onTap, child: Text(actionLabel!)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label • $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({
    required this.title,
    required this.subtitle,
    required this.participants,
    required this.meta,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String participants;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.refereeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.scoreboard_rounded,
                color: AppTheme.refereeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    participants,
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _TournamentTile extends StatelessWidget {
  const _TournamentTile({
    required this.tournament,
    this.isOwner = false,
    this.isCoOrg = false,
    this.isParticipant = false,
  });

  final Tournament tournament;
  final bool isOwner;
  final bool isCoOrg;
  final bool isParticipant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isClubLite = tournament.isClubLite;

    String badgeText = l10n.dashboard_registered;
    Color badgeBg = const Color(0xFFECFDF5);
    Color badgeTextCol = const Color(0xFF059669);
    Color badgeBorder = const Color(0xFFA7F3D0);

    if (isOwner) {
      badgeText = l10n.dashboard_organizer;
      badgeBg = const Color(0xFFEFF6FF);
      badgeTextCol = const Color(0xFF2563EB);
      badgeBorder = const Color(0xFFBFDBFE);
    } else if (isCoOrg) {
      badgeText = l10n.dashboard_coOrganizer;
      badgeBg = const Color(0xFFF3E8FF);
      badgeTextCol = const Color(0xFF9333EA);
      badgeBorder = const Color(0xFFE9D5FF);
    }

    return InkWell(
      onTap: () {
        if (isOwner || isCoOrg) {
          if (isClubLite) {
            context.push('/lite-manage/${tournament.id}');
          } else {
            context.push('/organizer/tournaments/${tournament.id}/ops');
          }
        } else {
          context.push('/intro/${tournament.id}');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  (tournament.logoUrl != null && tournament.logoUrl!.isNotEmpty)
                  ? Image.network(
                      tournament.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/sporto_v1_with_text.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/sporto_v1_with_text.png',
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (tournament.communityName != null && tournament.communityName!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 11,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            tournament.communityName!,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    isClubLite
                        ? (tournament.communityName != null && tournament.communityName!.isNotEmpty
                            ? 'Giải Siêu Lite • ${tournament.communityName}'
                            : l10n.dashboard_liteDesc)
                        : l10n.opsOrganizerOnly,
                    style: TextStyle(
                      fontSize: 9,
                      color: isClubLite
                          ? const Color(0xFF059669)
                          : AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeBorder),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeTextCol,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _buildTournamentMeta(tournament, l10n),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _buildTournamentMeta(Tournament tournament, AppLocalizations l10n) {
    final parts = <String>[];
    if (tournament.sport.isNotEmpty) {
      parts.add(tournament.sport);
    }
    if (tournament.startDate != null) {
      parts.add(DateFormatterUtils.formatDate(tournament.startDate!.toLocal()));
    }
    return parts.isEmpty ? l10n.dashboard_updateInProgress : parts.join(' • ');
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _EmptySectionText extends StatelessWidget {
  const _EmptySectionText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, color: context.colors.textMuted),
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboard_loadErrorTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dashboard_loadErrorDesc,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: Text(l10n.dashboard_retry)),
        ],
      ),
    );
  }
}
