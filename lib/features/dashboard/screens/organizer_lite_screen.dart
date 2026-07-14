import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_lite.dart';
import 'package:app_quanly_giaidau/providers/organizer_lite_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrganizerLiteScreen extends ConsumerStatefulWidget {
  const OrganizerLiteScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<OrganizerLiteScreen> createState() => _OrganizerLiteScreenState();
}

class _OrganizerLiteScreenState extends ConsumerState<OrganizerLiteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final teamsAsync = ref.watch(teamsProvider(widget.tournamentId));
    final matchesAsync = ref.watch(matchesProvider(widget.tournamentId));
    final refereesAsync = ref.watch(organizerLiteRefereesProvider(widget.tournamentId));

    return tournamentAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.colors.bgDark,
        appBar: AppBar(
          title: const Text('Quản lý nhanh'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: context.colors.bgDark,
        appBar: AppBar(
          title: const Text('Quản lý nhanh'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text('Không thể tải giải đấu: $error')),
      ),
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(
            backgroundColor: context.colors.bgDark,
            appBar: AppBar(
              title: const Text('Quản lý nhanh'),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Text('Giải đấu không tồn tại')),
          );
        }

        return Scaffold(
          backgroundColor: context.colors.bgDark,
          appBar: AppBar(
            title: const Text('Quản lý nhanh'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
              onPressed: () => context.pop(),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primary,
              unselectedLabelColor: context.colors.textMuted,
              indicatorColor: AppTheme.primary,
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Đội / VĐV'),
                Tab(text: 'Lịch đấu'),
                Tab(text: 'Trọng tài'),
              ],
            ),
          ),
          body: Column(
            children: [
              _OrganizerHeader(tournamentId: widget.tournamentId, tournament: tournament),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OrganizerOverview(
                      tournamentId: widget.tournamentId,
                      teamCount: teamsAsync.asData?.value.length ?? 0,
                      matchCount: matchesAsync.asData?.value.length ?? 0,
                      refereeCount: refereesAsync.asData?.value.length ?? 0,
                      liveCount: _countLiveMatches(matchesAsync.asData?.value ?? const []),
                    ),
                    _TeamsTab(teamsAsync: teamsAsync),
                    _MatchesTab(matchesAsync: matchesAsync),
                    _RefereesTab(
                      refereesAsync: refereesAsync,
                      matches: matchesAsync.asData?.value ?? const [],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrganizerHeader extends StatelessWidget {
  const _OrganizerHeader({
    required this.tournamentId,
    required this.tournament,
  });

  final String tournamentId;
  final dynamic tournament;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateText = tournament.startDate != null
        ? DateFormatterUtils.formatDate(tournament.startDate!.toLocal())
        : 'Chưa chốt ngày';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: context.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tournament.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$dateText • ${StatusHelper.getTournamentStatusLabel(tournament.status)}',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push('/tournament/$tournamentId/bracket'),
                  icon: const Icon(Icons.account_tree_rounded, size: 18),
                  label: const Text('Xem bracket'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/intro/$tournamentId'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Trang giải'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrganizerOverview extends StatelessWidget {
  const _OrganizerOverview({
    required this.tournamentId,
    required this.teamCount,
    required this.matchCount,
    required this.refereeCount,
    required this.liveCount,
  });

  final String tournamentId;
  final int teamCount;
  final int matchCount;
  final int refereeCount;
  final int liveCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(label: 'Đội / VĐV', value: '$teamCount', color: AppTheme.primary, icon: Icons.people_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(label: 'Trận đấu', value: '$matchCount', color: context.colors.warning, icon: Icons.scoreboard_rounded)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _MetricCard(label: 'Trọng tài', value: '$refereeCount', color: AppTheme.refereeColor, icon: Icons.gavel_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(label: 'Đang live', value: '$liveCount', color: const Color(0xFF10B981), icon: Icons.wifi_tethering_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        _QuickActionTile(
          icon: Icons.account_tree_rounded,
          title: 'Mở sơ đồ thi đấu',
          subtitle: 'Xem bracket hiện tại để kiểm tra nhánh và kết quả',
          onTap: () => context.push('/tournament/$tournamentId/bracket'),
        ),
        const SizedBox(height: 10),
        _QuickActionTile(
          icon: Icons.live_tv_rounded,
          title: 'Xem trận đang diễn ra',
          subtitle: 'Đi vào màn live để theo dõi và điều phối nhanh',
          onTap: () => context.push('/live-matches/$tournamentId'),
        ),
        const SizedBox(height: 10),
        _QuickActionTile(
          icon: Icons.info_outline_rounded,
          title: 'Mở trang giải công khai',
          subtitle: 'Kiểm tra giao diện người xem và thông tin hiển thị',
          onTap: () => context.push('/intro/$tournamentId'),
        ),
      ],
    );
  }
}

class _TeamsTab extends StatelessWidget {
  const _TeamsTab({required this.teamsAsync});

  final AsyncValue<List<Team>> teamsAsync;

  @override
  Widget build(BuildContext context) {
    return teamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Không thể tải danh sách đội: $error')),
      data: (teams) {
        if (teams.isEmpty) {
          return const _EmptyStateText('Chưa có đội hoặc VĐV nào trong giải.');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    team.members.isEmpty ? 'Chưa có thành viên' : team.members.join(', '),
                    style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({required this.matchesAsync});

  final AsyncValue<List<MatchModel>> matchesAsync;

  @override
  Widget build(BuildContext context) {
    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Không thể tải lịch đấu: $error')),
      data: (matches) {
        if (matches.isEmpty) {
          return const _EmptyStateText('Chưa có trận đấu nào được tạo.');
        }

        final sortedMatches = [...matches]
          ..sort((a, b) {
            final aTime = a.scheduledTime?.millisecondsSinceEpoch ?? 0;
            final bTime = b.scheduledTime?.millisecondsSinceEpoch ?? 0;
            if (aTime != bTime) return aTime.compareTo(bTime);
            return a.round.compareTo(b.round);
          });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: sortedMatches.length,
          itemBuilder: (context, index) {
            final match = sortedMatches[index];
            final timeLabel = match.scheduledTime != null
                ? DateFormatterUtils.formatDateTime(match.scheduledTime!.toLocal())
                : 'Chưa xếp giờ';
            return InkWell(
              onTap: () => context.push('/live/${match.id}'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Vòng ${match.round} • Trận ${match.matchNumber}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                        _StatusPill(status: match.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${match.team1Name} vs ${match.team2Name}',
                      style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (match.court.isNotEmpty) match.court,
                        timeLabel,
                      ].join(' • '),
                      style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RefereesTab extends StatelessWidget {
  const _RefereesTab({
    required this.refereesAsync,
    required this.matches,
  });

  final AsyncValue<List<OrganizerLiteReferee>> refereesAsync;
  final List<MatchModel> matches;

  @override
  Widget build(BuildContext context) {
    return refereesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Không thể tải danh sách trọng tài.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (referees) {
        if (referees.isEmpty) {
          return const _EmptyStateText('Giải này chưa có trọng tài nào được gắn.');
        }
        final assignedCount = matches.where((match) => (match.refereeId?.isNotEmpty ?? false)).length;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: referees.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              final acceptedCount = referees.where((item) => item.isAccepted).length;
              final invitedCount = referees.where((item) => item.isInvited).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Đã nhận',
                        value: '$acceptedCount',
                        color: const Color(0xFF10B981),
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: 'Đã mời',
                        value: '$invitedCount',
                        color: context.colors.warning,
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: 'Đã giao trận',
                        value: '$assignedCount',
                        color: AppTheme.primary,
                        icon: Icons.assignment_ind_rounded,
                      ),
                    ),
                  ],
                ),
              );
            }
            final referee = referees[index - 1];
            final assignedMatches = _findAssignedMatches(referee, matches);
            final liveAssignedCount = assignedMatches.where((match) {
              final status = match.status.toLowerCase();
              return status == 'live' || status == 'ongoing' || status == 'in_progress';
            }).length;
            final nextAssignedMatch = _findNextAssignedMatch(assignedMatches);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.refereeColor.withValues(alpha: 0.12),
                        backgroundImage: referee.avatarUrl.isNotEmpty ? NetworkImage(referee.avatarUrl) : null,
                        child: referee.avatarUrl.isEmpty
                            ? const Icon(Icons.gavel_rounded, color: AppTheme.refereeColor)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              referee.fullName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              referee.email.isNotEmpty ? referee.email : 'Chưa có email',
                              style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MiniInfoPill(
                                  label: '${assignedMatches.length} trận',
                                  color: AppTheme.primary,
                                ),
                                if (liveAssignedCount > 0)
                                  _MiniInfoPill(
                                    label: '$liveAssignedCount đang live',
                                    color: const Color(0xFF10B981),
                                  ),
                                if (nextAssignedMatch != null)
                                  _MiniInfoPill(
                                    label: _buildUpcomingRefereeLabel(nextAssignedMatch),
                                    color: context.colors.warning,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _RefereeStatusPill(referee: referee),
                    ],
                  ),
                  if (assignedMatches.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/live/${assignedMatches.first.id}'),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(
                          assignedMatches.length == 1
                              ? 'Mở trận đã giao'
                              : 'Mở trận gần nhất',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

List<MatchModel> _findAssignedMatches(OrganizerLiteReferee referee, List<MatchModel> matches) {
  final normalizedName = referee.fullName.trim().toLowerCase();
  final assigned = matches.where((match) {
    final byId = referee.userId.isNotEmpty && match.refereeId == referee.userId;
    final byName = !byId &&
        normalizedName.isNotEmpty &&
        (match.refereeName?.trim().toLowerCase() == normalizedName);
    return byId || byName;
  }).toList();

  assigned.sort((a, b) {
    final aTime = a.scheduledTime?.millisecondsSinceEpoch ?? 0;
    final bTime = b.scheduledTime?.millisecondsSinceEpoch ?? 0;
    if (aTime != bTime) return aTime.compareTo(bTime);
    return a.round.compareTo(b.round);
  });
  return assigned;
}

MatchModel? _findNextAssignedMatch(List<MatchModel> matches) {
  final now = DateTime.now();
  for (final match in matches) {
    final status = match.status.toLowerCase();
    if (status == 'completed') {
      continue;
    }
    if (match.scheduledTime == null || match.scheduledTime!.isAfter(now.subtract(const Duration(hours: 6)))) {
      return match;
    }
  }
  return matches.isNotEmpty ? matches.first : null;
}

String _buildUpcomingRefereeLabel(MatchModel match) {
  if (match.scheduledTime == null) {
    return 'Chưa xếp giờ';
  }
  return DateFormatterUtils.formatDateTime(match.scheduledTime!.toLocal());
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.colors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
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
              child: Icon(icon, color: AppTheme.primary),
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
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isLive = normalized == 'live' || normalized == 'ongoing' || normalized == 'in_progress';
    final isDone = normalized == 'completed';
    final color = isLive
        ? const Color(0xFF10B981)
        : isDone
            ? context.colors.textMuted
            : context.colors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isLive ? 'Đang đấu' : isDone ? 'Kết thúc' : 'Sắp đấu',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _RefereeStatusPill extends StatelessWidget {
  const _RefereeStatusPill({required this.referee});

  final OrganizerLiteReferee referee;

  @override
  Widget build(BuildContext context) {
    final color = referee.isAccepted
        ? const Color(0xFF10B981)
        : referee.isInvited
            ? context.colors.warning
            : context.colors.textMuted;

    final label = referee.isAccepted
        ? 'Đã nhận'
        : referee.isInvited
            ? 'Đã mời'
            : 'Đã từ chối';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _EmptyStateText extends StatelessWidget {
  const _EmptyStateText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: context.colors.textMuted),
        ),
      ),
    );
  }
}

int _countLiveMatches(List<MatchModel> matches) {
  return matches.where((match) {
    final status = match.status.toLowerCase();
    return status == 'live' || status == 'ongoing' || status == 'in_progress';
  }).length;
}
