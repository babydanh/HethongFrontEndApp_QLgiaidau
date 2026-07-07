import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final rankingsAsync = ref.watch(userRankingsProvider);
    final workspaceAsync = ref.watch(myTournamentWorkspaceProvider);
    final isAuth = ref.watch(authProvider).isAuthenticated;

    if (!isAuth) {
      return Scaffold(
        backgroundColor: context.colors.bgDark,
        appBar: AppBar(
          title: const Text('Của tôi'),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
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
                    color: context.colors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.dashboard_customize_rounded,
                    size: 40,
                    color: context.colors.info,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đăng nhập để xem khu vực của bạn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: const Text('Của tôi'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
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
        onRefresh: () => ref.read(myTournamentWorkspaceProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(
                profileAsync: profileAsync,
                rankingsAsync: rankingsAsync,
              ),
              const SizedBox(height: 16),
              workspaceAsync.when(
                loading: () => const _DashboardLoadingCard(),
                error: (error, _) => _DashboardErrorCard(
                  onRetry: () => ref.read(myTournamentWorkspaceProvider.notifier).refresh(),
                ),
                data: (workspace) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WorkspaceOverview(workspace: workspace),
                    const SizedBox(height: 16),
                    _PendingInviteSection(workspace: workspace),
                    const SizedBox(height: 16),
                    _RoleSection(workspace: workspace),
                    const SizedBox(height: 16),
                    _OrganizerLiteSection(workspace: workspace),
                    const SizedBox(height: 16),
                    _AssignedMatchesSection(workspace: workspace),
                    const SizedBox(height: 16),
                    _TournamentSection(workspace: workspace),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.profileAsync,
    required this.rankingsAsync,
  });

  final AsyncValue<dynamic> profileAsync;
  final AsyncValue<dynamic> rankingsAsync;

  @override
  Widget build(BuildContext context) {
    final name = profileAsync.asData?.value.fullName ?? 'Người dùng';
    int elo = 0;
    int played = 0;
    int won = 0;
    double winRate = 0;

    if (rankingsAsync.asData?.value != null) {
      final rankings = rankingsAsync.asData!.value;
      if (rankings.isNotEmpty) {
        elo = rankings.first.eloPoints;
        played = rankings.first.matchesPlayed;
        won = rankings.first.matchesWon;
        winRate = played > 0 ? (won / played) * 100 : 0;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$elo ELO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 260.ms),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStat(label: 'Đã đấu', value: '$played'),
              const SizedBox(width: 8),
              _HeaderStat(label: 'Thắng', value: '$won'),
              const SizedBox(width: 8),
              _HeaderStat(label: 'Tỉ lệ', value: '${winRate.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceOverview extends StatelessWidget {
  const _WorkspaceOverview({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OverviewMetric(
            icon: Icons.notifications_active_rounded,
            color: context.colors.warning,
            label: 'Lời mời',
            value: '${workspace.pendingInviteCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewMetric(
            icon: Icons.verified_user_rounded,
            color: AppTheme.primary,
            label: 'Vai trò',
            value: '${workspace.activeRoleCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewMetric(
            icon: Icons.sports_score_rounded,
            color: const Color(0xFF10B981),
            label: 'Trận giao',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textMuted),
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
    final pendingInvites = workspace.refereeInvites.where((invite) => invite.isPending).toList();
    if (pendingInvites.isEmpty) {
      return const SizedBox.shrink();
    }

    final latestInvite = pendingInvites.first;
    return _SectionCard(
      title: 'Lời mời cần xử lý',
      actionLabel: 'Mở danh sách',
      onTap: () => context.push('/referee/invites'),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.gavel_rounded,
            label: latestInvite.tournamentName,
            value: latestInvite.categoryName.isNotEmpty
                ? latestInvite.categoryName
                : 'Lời mời trọng tài',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Ngày mời',
            value: latestInvite.assignedAt != null
                ? DateFormatterUtils.formatDateTime(latestInvite.assignedAt!.toLocal())
                : 'Đang cập nhật',
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
    final items = <Widget>[
      if (workspace.organizedTournaments.isNotEmpty)
        _RoleChip(
          icon: Icons.workspace_premium_rounded,
          label: 'Chủ giải',
          count: workspace.organizedTournaments.length,
          color: const Color(0xFF10B981),
        ),
      if (workspace.coOrganizerTournaments.isNotEmpty)
        _RoleChip(
          icon: Icons.groups_rounded,
          label: 'Ban tổ chức',
          count: workspace.coOrganizerTournaments.length,
          color: AppTheme.primary,
        ),
      if (workspace.refereeTournaments.isNotEmpty)
        _RoleChip(
          icon: Icons.gavel_rounded,
          label: 'Trọng tài',
          count: workspace.refereeTournaments.length,
          color: AppTheme.refereeColor,
        ),
      if (workspace.participatingTournaments.isNotEmpty)
        _RoleChip(
          icon: Icons.sports_tennis_rounded,
          label: 'Vận động viên',
          count: workspace.participatingTournaments.length,
          color: context.colors.info,
        ),
    ];

    return _SectionCard(
      title: 'Vai trò của tôi',
      child: items.isEmpty
          ? const _EmptySectionText('Bạn chưa có vai trò nào trong giải đấu.')
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items,
            ),
    );
  }
}

class _AssignedMatchesSection extends StatelessWidget {
  const _AssignedMatchesSection({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final matches = workspace.refereeMatches.take(3).toList();
    return _SectionCard(
      title: 'Trận được phân công',
      actionLabel: workspace.refereeMatches.isNotEmpty ? 'Xem lời mời' : null,
      onTap: workspace.refereeMatches.isNotEmpty
          ? () => context.push('/referee/invites')
          : null,
      child: matches.isEmpty
          ? const _EmptySectionText('Bạn chưa có trận nào được phân công.')
          : Column(
              children: matches.map((match) {
                final subtitle = [
                  if (match.stageName.isNotEmpty) match.stageName,
                  if (match.groupName.isNotEmpty) match.groupName,
                  'Vòng ${match.roundNumber}',
                ].join(' • ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AssignmentTile(
                    title: match.tournamentName,
                    subtitle: subtitle,
                    participants: match.participantLabel,
                    meta: _formatMatchMeta(match),
                    onTap: () => context.push('/live/${match.id}'),
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _formatMatchMeta(TournamentAssignedMatch match) {
    final parts = <String>[];
    if (match.courtName.isNotEmpty) {
      parts.add(match.courtName);
    }
    if (match.scheduledAt != null) {
      parts.add(DateFormatterUtils.formatDateTime(match.scheduledAt!.toLocal()));
    }
    return parts.isEmpty ? 'Chờ sắp lịch' : parts.join(' • ');
  }
}

class _OrganizerLiteSection extends StatelessWidget {
  const _OrganizerLiteSection({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final managedTournaments = [
      ...workspace.organizedTournaments,
      ...workspace.coOrganizerTournaments,
    ];

    if (managedTournaments.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'Quản lý nhanh',
      child: Column(
        children: managedTournaments.take(3).map((tournament) {
          final isOwner = workspace.organizedTournaments.any((item) => item.id == tournament.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => context.push('/organizer-lite/${tournament.id}'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dashboard_customize_rounded, color: AppTheme.primary),
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
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isOwner ? 'Chủ giải' : 'Ban tổ chức',
                            style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => context.push('/organizer-lite/${tournament.id}'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Mở'),
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
}

class _TournamentSection extends StatelessWidget {
  const _TournamentSection({required this.workspace});

  final TournamentWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tournaments = workspace.visibleTournaments.take(4).toList();
    return _SectionCard(
      title: 'Giải của tôi',
      child: tournaments.isEmpty
          ? const _EmptySectionText('Bạn chưa tham gia hoặc quản lý giải nào.')
          : Column(
              children: tournaments.map((tournament) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TournamentTile(tournament: tournament),
                );
              }).toList(),
            ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            'Tiện ích nhanh',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _QuickActionRow(
            icon: Icons.notifications_rounded,
            title: 'Thông báo',
            subtitle: 'Xem mời giải, cập nhật và nhắc việc',
            onTap: () => context.push('/notifications'),
          ),
          const Divider(height: 24),
          _QuickActionRow(
            icon: Icons.groups_rounded,
            title: 'Lời mời câu lạc bộ',
            subtitle: 'Nhận và phản hồi lời mời CLB',
            onTap: () => context.push('/club-invites'),
          ),
          const Divider(height: 24),
          _QuickActionRow(
            icon: Icons.person_rounded,
            title: 'Hồ sơ cá nhân',
            subtitle: 'Cập nhật thông tin và hồ sơ công khai',
            onTap: () => context.push('/profile'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 180.ms, duration: 260.ms);
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
                    style: TextStyle(fontSize: 11, color: context.colors.textMuted),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label • $count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
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
              child: const Icon(Icons.scoreboard_rounded, color: AppTheme.refereeColor),
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
  const _TournamentTile({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: AppTheme.primary),
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildTournamentMeta(tournament),
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/intro/${tournament.id}'),
                  child: const Text('Xem giải'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/tournament/${tournament.id}/bracket'),
                  child: const Text('Xem bracket'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildTournamentMeta(Tournament tournament) {
    final parts = <String>[];
    if (tournament.sport.isNotEmpty) {
      parts.add(tournament.sport);
    }
    if (tournament.startDate != null) {
      parts.add(DateFormatterUtils.formatDate(tournament.startDate!.toLocal()));
    }
    return parts.isEmpty ? 'Đang cập nhật' : parts.join(' • ');
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
            'Không thể tải khu vực của bạn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thử tải lại để đồng bộ lời mời, vai trò và các trận được giao.',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Tải lại')),
        ],
      ),
    );
  }
}
