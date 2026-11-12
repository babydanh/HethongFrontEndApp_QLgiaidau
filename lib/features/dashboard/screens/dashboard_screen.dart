import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/core/utils/elo_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/profile/screens/achievements_tab.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String _selectedSport = 'all';

  /// Tổng quan | Hoạt động | Quản lý.
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  /// Kéo để làm mới: tải lại hồ sơ, xếp hạng, đội bóng và workspace rồi mới
  /// thả vòng quay. Lỗi từng nguồn đã hiện ở khối tương ứng nên nuốt ở đây.
  Future<void> _refreshAll() async {
    ref.invalidate(userProfileProvider);
    ref.invalidate(userRankingsProvider);
    ref.invalidate(myFootballTeamsProvider);
    Future<void> settle(Future<Object?> future) async {
      try {
        await future;
      } catch (_) {
        // Lỗi từng nguồn đã hiện ở khối tương ứng (LavishErrorState + thử lại);
        // ở đây chỉ cần đợi xong để vòng kéo-làm-mới kết thúc.
      }
    }

    await Future.wait([
      ref.read(myTournamentWorkspaceProvider.notifier).refresh(),
      settle(ref.read(userProfileProvider.future)),
      settle(ref.read(userRankingsProvider.future)),
      settle(ref.read(myFootballTeamsProvider.future)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAuth = ref.watch(authProvider).isAuthenticated;

    if (!isAuth) {
      return LavishScaffold(
        title: l10n.dashboard_title,
        onBack: _back,
        body: LavishEmptyState(
          icon: Icons.dashboard_customize_rounded,
          title: l10n.dashboard_loginPrompt,
          action: l10n.loginButton,
          onAction: () => context.push('/login'),
        ),
      );
    }

    final workspaceAsync = ref.watch(myTournamentWorkspaceProvider);
    return LavishScaffold(
      title: l10n.dashboard_title,
      onBack: _back,
      body: Column(
        children: [
          _SegmentBar(
            controller: _tabController,
            items: [
              (Icons.space_dashboard_rounded, l10n.dashboard_tab_overview),
              (Icons.bolt_rounded, l10n.dashboard_tab_activity),
              (Icons.tune_rounded, l10n.dashboard_tab_manage),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TabScroll(
                  onRefresh: _refreshAll,
                  children: [
                    const _ProfileRow(),
                    _SportFilter(
                      selected: _selectedSport,
                      onSelected: (id) => setState(() => _selectedSport = id),
                    ),
                    _EloSection(selectedSport: _selectedSport),
                  ],
                ),
                _TabScroll(
                  onRefresh: _refreshAll,
                  children: [
                    AchievementsTab(selectedSport: _selectedSport),
                    workspaceAsync.when(
                      loading: () => const LavishRowSkeleton(count: 4),
                      error: (_, _) => LavishErrorState(
                        message: l10n.dashboard_loadErrorTitle,
                        onRetry: () => ref
                            .read(myTournamentWorkspaceProvider.notifier)
                            .refresh(),
                      ),
                      data: (workspace) => _WorkspaceContent(workspace),
                    ),
                  ],
                ),
                _TabScroll(
                  onRefresh: _refreshAll,
                  children: [_ManageSection(workspaceAsync: workspaceAsync)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Khung chung ────────────────────────────────────────────────────────────

/// Segment gọn: icon + nhãn ngắn, thu nhỏ chữ thay vì cắt.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.controller, required this.items});

  final TabController controller;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: AnimatedBuilder(
        animation: controller.animation ?? controller,
        builder: (context, _) {
          final current = (controller.animation?.value ?? controller.index)
              .round();
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _SegmentItem(
                    icon: items[i].$1,
                    label: items[i].$2,
                    selected: current == i,
                    onTap: () => controller.animateTo(i),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final fg = selected ? LavishColors.accent : c.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.soft(LavishTone.accent) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mỗi tab cuộn riêng, cùng khung bề ngang và cùng kéo-để-làm-mới.
class _TabScroll extends StatelessWidget {
  const _TabScroll({required this.children, required this.onRefresh});

  final List<Widget> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tổng quan ──────────────────────────────────────────────────────────────

class _ProfileRow extends ConsumerWidget {
  const _ProfileRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    return ref
        .watch(userProfileProvider)
        .when(
          loading: () => const LavishRowSkeleton(count: 1),
          error: (_, _) => LavishErrorState(
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
          data: (UserProfile profile) {
            final name = profile.fullName?.trim() ?? '';
            final avatar = profile.avatarUrl;
            final rank = ref.watch(myBestRankingProvider);
            return LavishRow(
              leading: RankAvatar(
                imageUrl: avatar,
                name: name,
                elo: rank?.eloPoints ?? 0,
                tierName: rank?.tierName,
                tierSource: rank?.tierSource,
                tierAvailable: rank?.tierAvailable,
                matchesPlayed: rank?.matchesPlayed ?? 0,
                size: 40,
              ),
              title: name.isNotEmpty ? name : l10n.dashboard_user,
              subtitle: profile.email,
              trailing: [Icon(Icons.chevron_right_rounded, color: c.faint)],
              onTap: () => context.push('/profile'),
            );
          },
        );
  }
}

class _SportFilter extends ConsumerWidget {
  const _SportFilter({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];
    final options = <(String, String)>[
      ('all', l10n.infoAll),
      for (final category in categories) (category.slug, category.name),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
          child: Text(
            l10n.dashboard_sportActivityFilterLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: c.muted,
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Center(
              child: LavishChipButton(
                label: options[i].$2,
                selected: selected == options[i].$1,
                onPressed: () => onSelected(options[i].$1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

bool _sportMatches(PlayerRanking ranking, String selected) {
  if (ranking.matchesPlayed <= 0) return false;
  if (selected == 'all') return true;
  final key = (ranking.categoryId ?? ranking.categoryName ?? '')
      .trim()
      .toLowerCase();
  final sel = selected.toLowerCase();
  bool has(List<String> parts) => parts.any(key.contains);
  final matched = switch (sel) {
    'pickleball' => has(['pickle', 'padd']),
    'badminton' => has(['badminton', 'cầu']),
    'table_tennis' => has(['table', 'bàn']),
    'tennis' => key.contains('tennis'),
    'football' => has(['foot', 'socc', 'bóng']),
    _ => false,
  };
  return matched || key == sel;
}

class _EloSection extends ConsumerWidget {
  const _EloSection({required this.selectedSport});

  final String selectedSport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(userRankingsProvider)
        .when(
          loading: () => const _EloSkeleton(),
          error: (_, _) => LavishErrorState(
            onRetry: () => ref.invalidate(userRankingsProvider),
          ),
          data: (rankings) {
            final played =
                rankings.where((r) => _sportMatches(r, selectedSport)).toList()
                  ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));
            if (played.isEmpty) {
              return LavishEmptyState(
                icon: Icons.emoji_events_outlined,
                title: l10n.publicProfileNoPlayedElo,
              );
            }
            final teams =
                ref.watch(myFootballTeamsProvider).asData?.value ??
                const <FootballTeamSummary>[];
            final team = teams.isEmpty
                ? null
                : teams.reduce((a, b) => a.eloPoints >= b.eloPoints ? a : b);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EloSummary(rank: EloHelpers.getBestRankForCategory(played)!),
                if (team != null) _FootballTeamRow(team),
                for (final ranking in played) _RankingRow(ranking),
              ],
            );
          },
        );
  }
}

class _EloSkeleton extends StatelessWidget {
  const _EloSkeleton();

  @override
  Widget build(BuildContext context) => const SkeletonScope(
    child: Padding(
      padding: EdgeInsets.all(14),
      child: Column(
        children: [
          SkeletonBox(height: 44, radius: 10),
          SizedBox(height: 12),
          SkeletonBox(height: 8, radius: 4),
          SizedBox(height: 12),
          SkeletonBox(height: 56, radius: 10),
        ],
      ),
    ),
  );
}

/// ELO to + thanh tiến trình tới mốc kế + 4 số liệu.
class _EloSummary extends StatelessWidget {
  const _EloSummary({required this.rank});

  final PlayerRanking rank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final progress = EloHelpers.getEloProgressInfo(rank.eloPoints, l10n);
    final showProgress = rank.tierSource != 'DUPR';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${rank.eloPoints}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: c.text,
                          ),
                        ),
                        TextSpan(
                          text: ' ELO',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: LavishPill(EloHelpers.getRankDisplayName(rank, l10n)),
                ),
              ),
            ],
          ),
        ),
        if (showProgress)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (progress.percent / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: c.line,
                    valueColor: const AlwaysStoppedAnimation(
                      LavishColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  progress.label,
                  style: TextStyle(fontSize: 11.5, color: c.muted),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        LavishStatGrid(
          items: [
            LavishStat(
              label: l10n.ranking_matchesLabel,
              value: '${rank.matchesPlayed}',
            ),
            LavishStat(
              label: l10n.ranking_winsLabel,
              value: '${rank.matchesWon}',
              tone: LavishTone.ok,
            ),
            LavishStat(
              label: l10n.ranking_winRateLabel,
              value: '${EloHelpers.getRankWinRate(rank)}%',
            ),
            LavishStat(
              label: l10n.ranking_peakLabel,
              value: '${rank.peakElo ?? rank.eloPoints}',
              tone: LavishTone.accent,
            ),
          ],
        ),
      ],
    );
  }
}

class _FootballTeamRow extends StatelessWidget {
  const _FootballTeamRow(this.team);

  final FootballTeamSummary team;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    return LavishRow(
      leading: const LavishIconBox(child: Icon(Icons.groups_rounded)),
      title: l10n.ranking_topFootballTeam(team.name),
      trailing: [
        Text(
          l10n.ranking_eloValue(team.eloPoints),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: c.text,
          ),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow(this.ranking);

  final PlayerRanking ranking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final isDoubles =
        ranking.matchType == 'DOUBLES' || ranking.matchType == 'MIXED_DOUBLES';
    final streak = ranking.currentStreakType?.toUpperCase();
    final streakPill = switch (streak) {
      'WIN' => LavishPill(
        l10n.publicProfileWinStreak(ranking.currentStreakCount),
        tone: LavishTone.ok,
      ),
      'LOSS' => LavishPill(
        l10n.publicProfileLossStreak(ranking.currentStreakCount),
        tone: LavishTone.bad,
      ),
      _ => null,
    };
    final partner = ranking.partnerName;
    return LavishRow(
      leading: LavishIconBox(
        child: Icon(
          isDoubles ? Icons.people_alt_rounded : Icons.person_rounded,
        ),
      ),
      title: ranking.categoryName?.isNotEmpty == true
          ? ranking.categoryName!
          : l10n.publicProfileUserFallback,
      subtitle: [
        EloHelpers.getEloMatchTypeLabel(ranking.matchType, l10n),
        if (isDoubles && partner != null && partner.isNotEmpty) partner,
      ].join(' • '),
      // Wrap: ở 320dp / chữ lớn các phần tử rơi xuống dòng thay vì tràn Row.
      trailing: [
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              ?streakPill,
              Text(
                '${ranking.eloPoints}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.text,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.faint),
            ],
          ),
        ),
      ],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
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
    );
  }
}

// ─── Hoạt động ──────────────────────────────────────────────────────────────

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent(this.workspace);

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = workspace.refereeInvites.where((i) => i.isPending).toList();
    final roles = <(IconData, String, int, LavishTone)>[
      if (workspace.organizedTournaments.isNotEmpty)
        (
          Icons.workspace_premium_rounded,
          l10n.dashboard_organizer,
          workspace.organizedTournaments.length,
          LavishTone.ok,
        ),
      if (workspace.coOrganizerTournaments.isNotEmpty)
        (
          Icons.groups_rounded,
          l10n.dashboard_coOrganizer,
          workspace.coOrganizerTournaments.length,
          LavishTone.accent,
        ),
      if (workspace.refereeTournaments.isNotEmpty)
        (
          Icons.gavel_rounded,
          l10n.infoReferee,
          workspace.refereeTournaments.length,
          LavishTone.warn,
        ),
      if (workspace.participatingTournaments.isNotEmpty)
        (
          Icons.sports_tennis_rounded,
          l10n.infoPlayer,
          workspace.participatingTournaments.length,
          LavishTone.neutral,
        ),
    ];
    final matches = workspace.refereeMatches.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishStatGrid(
          items: [
            LavishStat(
              label: l10n.dashboard_invites,
              value: '${workspace.pendingInviteCount}',
              tone: LavishTone.warn,
            ),
            LavishStat(
              label: l10n.dashboard_roles,
              value: '${workspace.activeRoleCount}',
              tone: LavishTone.accent,
            ),
            LavishStat(
              label: l10n.dashboard_refereeMatchesCount,
              value: '${workspace.refereeMatches.length}',
              tone: LavishTone.ok,
            ),
          ],
        ),
        if (pending.isNotEmpty) ...[
          LavishGroupHeader(
            l10n.dashboard_pendingInvitesTitle,
            trailing: LavishChipButton(
              label: l10n.dashboard_openList,
              onPressed: () => context.push('/referee/invites'),
            ),
          ),
          LavishRow(
            leading: const LavishIconBox(
              tone: LavishTone.warn,
              child: Icon(Icons.gavel_rounded),
            ),
            title: pending.first.tournamentName,
            subtitle: [
              pending.first.categoryName.isNotEmpty
                  ? pending.first.categoryName
                  : l10n.dashboard_refereeInviteFallback,
              if (pending.first.assignedAt != null)
                DateFormatterUtils.formatDateTime(
                  pending.first.assignedAt!.toLocal(),
                ),
            ].join(' • '),
            trailing: [
              Icon(
                Icons.chevron_right_rounded,
                color: LavishColors.of(context).faint,
              ),
            ],
            onTap: () => context.push('/referee/invites'),
          ),
        ],
        LavishGroupHeader(l10n.dashboard_myRoles),
        if (roles.isEmpty)
          LavishEmptyState(
            icon: Icons.verified_user_outlined,
            title: l10n.dashboard_noRolesDesc,
          )
        else
          for (final role in roles)
            LavishRow(
              leading: LavishIconBox(tone: role.$4, child: Icon(role.$1)),
              title: role.$2,
              trailing: [LavishPill('${role.$3}', tone: role.$4)],
            ),
        LavishGroupHeader(
          l10n.dashboard_assignedMatches,
          trailing: matches.isEmpty
              ? null
              : LavishChipButton(
                  label: l10n.dashboard_viewInvites,
                  onPressed: () => context.push('/referee/invites'),
                ),
        ),
        if (matches.isEmpty)
          LavishEmptyState(
            icon: Icons.scoreboard_outlined,
            title: l10n.dashboard_noAssignedMatches,
          )
        else
          for (final match in matches) _AssignedMatchRow(match),
        _TournamentsSection(workspace),
      ],
    );
  }
}

class _AssignedMatchRow extends StatelessWidget {
  const _AssignedMatchRow(this.match);

  final TournamentAssignedMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stage = MatchRoundLabel.formatStageOrGroupName(
      match.stageName,
      l10n: l10n,
    );
    final group = match.groupName.toUpperCase();
    final line = [
      if (stage.isNotEmpty) stage,
      if (match.groupName.isNotEmpty &&
          !group.contains('BRACKET') &&
          !group.contains('MAIN'))
        match.groupName,
      match.localizedMatchLabel(l10n),
      l10n.dashboard_roundLabel(match.roundNumber),
    ].join(' • ');
    final meta = [
      if (match.courtName.isNotEmpty) match.courtName,
      if (match.scheduledAt != null)
        DateFormatterUtils.formatDateTime(match.scheduledAt!.toLocal()),
    ];
    return LavishRow(
      leading: const LavishIconBox(
        tone: LavishTone.warn,
        child: Icon(Icons.scoreboard_rounded),
      ),
      title: match.tournamentName,
      subtitle:
          '$line\n${match.participantLabel}\n'
          '${meta.isEmpty ? l10n.dashboard_waitingSchedule : meta.join(' • ')}',
      subtitleMaxLines: 3,
      trailing: [
        Icon(
          Icons.chevron_right_rounded,
          color: LavishColors.of(context).faint,
        ),
      ],
      onTap: () => context.push(
        NavigationHelper.getLiveMatchRoute(match.tournamentId, match.id),
      ),
    );
  }
}

Widget _tournamentLeading(Tournament t) {
  final logo = t.logoUrl;
  if (logo == null || logo.isEmpty) {
    return const LavishIconBox(child: Icon(Icons.emoji_events_rounded));
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.network(
      logo,
      width: 34,
      height: 34,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const LavishIconBox(child: Icon(Icons.emoji_events_rounded)),
    ),
  );
}

LavishTone _statusTone(String status) {
  if (StatusHelper.isTournamentCompleted(status)) return LavishTone.neutral;
  if (StatusHelper.isTournamentCancelled(status)) return LavishTone.bad;
  if (StatusHelper.normalizeTournamentStatus(status) ==
      AppConstants.statusInProgress) {
    return LavishTone.ok;
  }
  return LavishTone.accent;
}

/// Giải của tôi (tab Hoạt động): tìm kiếm khi nhiều, thu gọn 4 giải.
class _TournamentsSection extends StatefulWidget {
  const _TournamentsSection(this.workspace);

  final TournamentWorkspace workspace;

  @override
  State<_TournamentsSection> createState() => _TournamentsSectionState();
}

class _TournamentsSectionState extends State<_TournamentsSection> {
  static const _collapsed = 4;
  bool _expanded = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workspace = widget.workspace;
    final byId = <String, Tournament>{
      for (final t in workspace.organizedTournaments) t.id: t,
      for (final t in workspace.coOrganizerTournaments) t.id: t,
      for (final t in workspace.participatingTournaments) t.id: t,
    };
    final all = byId.values.toList()
      ..sort((a, b) {
        if (a.isClubLite == b.isClubLite) return 0;
        return a.isClubLite ? -1 : 1;
      });
    final q = _query.trim().toLowerCase();
    final filtered = all
        .where(
          (t) =>
              q.isEmpty ||
              t.name.toLowerCase().contains(q) ||
              t.sport.toLowerCase().contains(q),
        )
        .toList();
    final visible = _expanded ? filtered : filtered.take(_collapsed).toList();
    bool inList(List<Tournament> list, Tournament t) =>
        list.any((item) => item.id == t.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishGroupHeader(l10n.dashboard_myTournaments(all.length)),
        if (all.length > 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: LavishTextField(
              label: l10n.dashboard_searchHint,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        if (filtered.isEmpty)
          LavishEmptyState(
            icon: Icons.emoji_events_outlined,
            title: _query.isNotEmpty
                ? l10n.dashboard_noSearchResults
                : l10n.dashboard_noTournaments,
          )
        else ...[
          for (final t in visible)
            _unifiedRow(
              context,
              t,
              isOwner: inList(workspace.organizedTournaments, t),
              isCoOrg: inList(workspace.coOrganizerTournaments, t),
            ),
          if (filtered.length > _collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: LavishButton(
                label: _expanded
                    ? l10n.dashboard_collapse
                    : l10n.dashboard_showMore(filtered.length - _collapsed),
                kind: LavishButtonKind.outline,
                dense: true,
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ),
        ],
      ],
    );
  }

  Widget _unifiedRow(
    BuildContext context,
    Tournament t, {
    required bool isOwner,
    required bool isCoOrg,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final (roleLabel, roleTone) = isOwner
        ? (l10n.dashboard_organizer, LavishTone.accent)
        : isCoOrg
        ? (l10n.dashboard_coOrganizer, LavishTone.warn)
        : (l10n.dashboard_registered, LavishTone.ok);
    final subtitle = [
      if (t.sport.isNotEmpty) t.sport,
      if (t.startDate != null)
        DateFormatterUtils.formatDate(t.startDate!.toLocal()),
    ].join(' • ');
    return LavishRow(
      leading: _tournamentLeading(t),
      title: t.name,
      subtitle: subtitle.isEmpty ? l10n.dashboard_updateInProgress : subtitle,
      trailing: [
        if (t.isClubLite)
          LavishPill(l10n.dsh28_liteBadge, tone: LavishTone.neutral),
        LavishPill(roleLabel, tone: roleTone),
        Icon(Icons.chevron_right_rounded, color: c.faint),
      ],
      onTap: () {
        if (isOwner || isCoOrg) {
          context.push(
            t.isClubLite
                ? '/lite-manage/${t.id}'
                : '/organizer/tournaments/${t.id}/manage',
          );
        } else {
          context.push('/intro/${t.id}');
        }
      },
    );
  }
}

// ─── Quản lý ────────────────────────────────────────────────────────────────

enum _Role { all, organizer, coOrganizer, participant }

class _Managed {
  const _Managed(this.tournament, this.role);
  final Tournament tournament;
  final _Role role;
}

/// Tab "Quản lý": tìm kiếm + chip vai trò + danh sách giải (chưa kết thúc
/// lên trước, mới tạo lên trước), tải thêm khi cuộn gần đáy.
class _ManageSection extends ConsumerStatefulWidget {
  const _ManageSection({required this.workspaceAsync});

  final AsyncValue<TournamentWorkspace> workspaceAsync;

  @override
  ConsumerState<_ManageSection> createState() => _ManageSectionState();
}

class _ManageSectionState extends ConsumerState<_ManageSection> {
  _Role _role = _Role.all;
  String _query = '';

  /// Gộp ba nhóm giải, giữ vai trò mạnh nhất khi trùng id.
  List<_Managed> _collect(TournamentWorkspace workspace) {
    final map = <String, _Managed>{};
    void put(List<Tournament> list, _Role role) {
      for (final t in list) {
        if (t.id.isEmpty) continue;
        final existing = map[t.id];
        if (existing != null && existing.role.index <= role.index) continue;
        map[t.id] = _Managed(t, role);
      }
    }

    put(workspace.organizedTournaments, _Role.organizer);
    put(workspace.coOrganizerTournaments, _Role.coOrganizer);
    put(workspace.participatingTournaments, _Role.participant);
    return map.values.toList()..sort((a, b) {
      final aDone = StatusHelper.isTournamentCompleted(a.tournament.status);
      final bDone = StatusHelper.isTournamentCompleted(b.tournament.status);
      if (aDone != bDone) return aDone ? 1 : -1;
      return b.tournament.createdAt.compareTo(a.tournament.createdAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    return widget.workspaceAsync.when(
      loading: () => const LavishRowSkeleton(count: 5),
      error: (_, _) => LavishErrorState(
        message: l10n.dashboard_loadErrorTitle,
        onRetry: () =>
            ref.read(myTournamentWorkspaceProvider.notifier).refresh(),
      ),
      data: (workspace) {
        final all = _collect(workspace);
        if (all.isEmpty) {
          return LavishEmptyState(
            icon: Icons.emoji_events_outlined,
            title: l10n.dashboard_noTournaments,
          );
        }
        final notifier = ref.read(myTournamentWorkspaceProvider.notifier);
        int count(_Role r) =>
            r == _Role.all ? all.length : all.where((e) => e.role == r).length;
        final labels = <_Role, String>{
          _Role.all: l10n.infoAll,
          _Role.organizer: l10n.dashboard_organizer,
          _Role.coOrganizer: l10n.dashboard_coOrganizer,
          _Role.participant: l10n.dashboard_participant,
        };
        final q = _query.trim().toLowerCase();
        final visible = all.where((e) {
          if (_role != _Role.all && e.role != _role) return false;
          return q.isEmpty ||
              e.tournament.name.toLowerCase().contains(q) ||
              e.tournament.sport.toLowerCase().contains(q);
        }).toList();

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 400) notifier.loadMore();
            return false;
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: LavishTextField(
                  label: l10n.dashboard_searchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  itemCount: _Role.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final role = _Role.values[i];
                    return Center(
                      child: LavishChipButton(
                        label: '${labels[role]} ${count(role)}',
                        selected: _role == role,
                        onPressed: () => setState(() => _role = role),
                      ),
                    );
                  },
                ),
              ),
              if (visible.isEmpty)
                LavishEmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.dashboard_noSearchResults,
                )
              else
                for (final item in visible)
                  _ManagedRow(item, labels[item.role]!),
              if (notifier.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (!workspace.hasMore && visible.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      l10n.dashboard_noMoreTournaments,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ManagedRow extends StatelessWidget {
  const _ManagedRow(this.entry, this.roleLabel);

  final _Managed entry;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = entry.tournament;
    return LavishRow(
      leading: _tournamentLeading(t),
      title: t.name,
      subtitle: '$roleLabel • ${_relativeCreated(l10n, t.createdAt)}',
      trailing: [
        LavishPill(
          StatusHelper.getTournamentStatusLabel(t.status, l10n: l10n),
          tone: _statusTone(t.status),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: LavishColors.of(context).faint,
        ),
      ],
      onTap: () => context.push('/tournament/${t.id}'),
    );
  }
}

/// Ngày tạo dạng tương đối theo ngôn ngữ đang dùng.
String _relativeCreated(AppLocalizations l10n, DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  final locale = l10n.localeName;
  if (diff.inDays < 1) return DateFormat.Hm(locale).format(createdAt);
  if (diff.inDays < 2) return l10n.dsh28_yesterday;
  if (diff.inDays < 30) return l10n.dsh28_daysAgo(diff.inDays);
  if (diff.inDays < 365) return DateFormat.MMMd(locale).format(createdAt);
  return DateFormat.yMMMd(locale).format(createdAt);
}
