import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_lite.dart';
import 'package:app_quanly_giaidau/providers/organizer_lite_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final teamsAsync = ref.watch(teamsProvider(widget.tournamentId));
    final matchesAsync = ref.watch(matchesProvider(widget.tournamentId));
    final refereesAsync = ref.watch(organizerLiteRefereesProvider(widget.tournamentId));

    return tournamentAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.colors.bgDark,
        appBar: AppBar(
          title: Text(l10n.organizer_title),
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
          title: Text(l10n.organizer_title),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(l10n.organizer_loadError(error.toString()))),
      ),
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(
            backgroundColor: context.colors.bgDark,
            appBar: AppBar(
              title: Text(l10n.organizer_title),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(child: Text(l10n.organizer_notFound)),
          );
        }

        return Scaffold(
          backgroundColor: context.colors.bgDark,
          appBar: AppBar(
            title: Text(l10n.organizer_title),
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
              tabs: [
                Tab(text: l10n.organizer_tabOverview),
                Tab(text: l10n.organizer_tabTeams),
                Tab(text: l10n.organizer_tabSchedule),
                Tab(text: l10n.infoReferee),
                Tab(text: l10n.organizer_tabFinance),
                Tab(text: l10n.organizer_tabPermissions),
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
                    _FinanceTab(
                      tournament: tournament,
                      teamCount: teamsAsync.asData?.value.length ?? 0,
                      teams: teamsAsync.asData?.value ?? const [],
                    ),
                    _PermissionsTab(tournament: tournament),
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
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final dateText = tournament.startDate != null
        ? DateFormatterUtils.formatDate(tournament.startDate!.toLocal())
        : l10n.organizer_noDate;

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
                  label: Text(l10n.viewBracket),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/intro/$tournamentId'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.organizer_tournamentPage),
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
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(label: l10n.organizer_tabTeams, value: '$teamCount', color: AppTheme.primary, icon: Icons.people_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(label: l10n.totalMatchesLabel, value: '$matchCount', color: context.colors.warning, icon: Icons.scoreboard_rounded)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _MetricCard(label: l10n.infoReferee, value: '$refereeCount', color: AppTheme.refereeColor, icon: Icons.gavel_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(label: l10n.organizer_metricLive, value: '$liveCount', color: const Color(0xFF10B981), icon: Icons.wifi_tethering_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        _QuickActionTile(
          icon: Icons.account_tree_rounded,
          title: l10n.organizer_openBracket,
          subtitle: l10n.organizer_openBracketSub,
          onTap: () => context.push('/tournament/$tournamentId/bracket'),
        ),
        const SizedBox(height: 10),
        _QuickActionTile(
          icon: Icons.live_tv_rounded,
          title: l10n.organizer_viewLive,
          subtitle: l10n.organizer_viewLiveSub,
          onTap: () => context.push('/live-matches/$tournamentId'),
        ),
        const SizedBox(height: 10),
        _QuickActionTile(
          icon: Icons.info_outline_rounded,
          title: l10n.organizer_viewPublic,
          subtitle: l10n.organizer_viewPublicSub,
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
    final l10n = AppLocalizations.of(context)!;
    return teamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.organizer_teamsLoadError(error.toString()))),
      data: (teams) {
        if (teams.isEmpty) {
          return _EmptyStateText(l10n.organizer_noTeams);
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
                    team.members.isEmpty ? l10n.organizer_noMembers : team.members.join(', '),
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
    final l10n = AppLocalizations.of(context)!;
    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.organizer_matchesLoadError(error.toString()))),
      data: (matches) {
        if (matches.isEmpty) {
          return _EmptyStateText(l10n.organizer_noMatches);
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
                : l10n.organizer_noTime;
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
                            l10n.organizer_matchTitle(match.round, match.matchNumber),
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
    final l10n = AppLocalizations.of(context)!;
    return refereesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.organizer_refereesLoadError(error.toString()),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (referees) {
        if (referees.isEmpty) {
          return _EmptyStateText(l10n.organizer_noReferees);
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
                        label: l10n.organizer_refereeAccepted,
                        value: '$acceptedCount',
                        color: const Color(0xFF10B981),
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: l10n.organizer_refereeInvited,
                        value: '$invitedCount',
                        color: context.colors.warning,
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: l10n.organizer_refereeAssigned,
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
                              referee.email.isNotEmpty ? referee.email : l10n.organizer_noEmail,
                              style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MiniInfoPill(
                                  label: l10n.organizer_matchCount(assignedMatches.length),
                                  color: AppTheme.primary,
                                ),
                                if (liveAssignedCount > 0)
                                  _MiniInfoPill(
                                    label: l10n.organizer_liveCount(liveAssignedCount),
                                    color: const Color(0xFF10B981),
                                  ),
                                if (nextAssignedMatch != null)
                                  _MiniInfoPill(
                                    label: _buildUpcomingRefereeLabel(nextAssignedMatch, l10n),
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
                              ? l10n.organizer_openAssignedMatch
                              : l10n.organizer_openNearestMatch,
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

String _buildUpcomingRefereeLabel(MatchModel match, AppLocalizations l10n) {
  if (match.scheduledTime == null) {
    return l10n.organizer_noTime;
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
    final l10n = AppLocalizations.of(context)!;
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
        isLive ? l10n.organizer_statusOngoing : isDone ? l10n.organizer_statusCompleted : l10n.organizer_statusScheduled,
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
    final l10n = AppLocalizations.of(context)!;
    final color = referee.isAccepted
        ? const Color(0xFF10B981)
        : referee.isInvited
            ? context.colors.warning
            : context.colors.textMuted;

    final label = referee.isAccepted
        ? l10n.organizer_refereeAccepted
        : referee.isInvited
            ? l10n.organizer_refereeInvited
            : l10n.organizer_refereeDeclined;

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

// ═══════════════════════════════════════════
//  TAB 5: TÀI CHÍNH (Finance)
// ═══════════════════════════════════════════
class _FinanceTab extends StatelessWidget {
  const _FinanceTab({
    required this.tournament,
    required this.teamCount,
    required this.teams,
  });

  final dynamic tournament;
  final int teamCount;
  final List<dynamic> teams;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final fmt = NumberFormat('#,###', 'vi_VN');
    final entryFee = tournament.entryFee ?? 0.0;
    final totalRevenue = entryFee * teamCount;
    final hasFee = entryFee > 0;

    // Tính số đội đã thanh toán (giả lập — dùng team status)
    // Trong thực tế, gọi API payments riêng
    final potentialRevenue = hasFee ? entryFee * tournament.maxTeams : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Revenue overview
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF064E3B), const Color(0xFF065F46)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.organizer_financeTotalRevenue, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        hasFee ? '${fmt.format(totalRevenue.ceil())}đ' : l10n.freePrice,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasFee) ...[
                _financeInfoRow(context, l10n.entryFeeLabel, '${fmt.format(entryFee.ceil())}đ/đội', Colors.white70),
                const SizedBox(height: 6),
                _financeInfoRow(context, l10n.organizer_financeRegisteredTeams, '$teamCount/${tournament.maxTeams}', Colors.white70),
                const SizedBox(height: 6),
                _financeInfoRow(context, l10n.organizer_financeMaxRevenue, '${fmt.format(potentialRevenue.ceil())}đ', Colors.white70),
              ] else ...[
                _financeInfoRow(context, l10n.organizer_financeFreeTournament, l10n.organizer_financeNoFee, Colors.white70),
                const SizedBox(height: 6),
                _financeInfoRow(context, l10n.organizer_financeRegisteredTeams, '$teamCount/${tournament.maxTeams}', Colors.white70),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Revenue details
        _sectionLabel(l10n.organizer_financeDetailTitle, colors),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _detailRow(context, l10n.organizer_financeFeePerTeam, hasFee ? '${fmt.format(entryFee.ceil())}đ' : l10n.freePrice, colors),
              const Divider(height: 1, color: Colors.transparent),
              _detailRow(context, l10n.maxTeamsLabel, '${tournament.maxTeams}', colors),
              const Divider(height: 1, color: Colors.transparent),
              _detailRow(context, l10n.organizer_financeRegisteredTeamsDetail, '$teamCount', colors),
              const Divider(height: 1, color: Colors.transparent),
              _detailRow(context, l10n.organizer_financeRemainingSlots, '${tournament.maxTeams - teamCount}', colors),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status info
        _sectionLabel(l10n.organizer_financePaymentInfo, colors),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: colors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.organizer_financePaymentDesc,
                      style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://giaidau.vnvar.com/lite/tournaments/'
                      '${Uri.encodeComponent(tournament.id.toString())}/manage',
                    );
                    final opened = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.organizer_financeWebError),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(l10n.organizer_financeViewWeb),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _financeInfoRow(BuildContext context, String label, String value, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 12, color: textColor)),
        ),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _sectionLabel(String text, AppColorsExtension colors) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.textSecondary, letterSpacing: 0.5),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          ),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.textPrimary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  TAB 6: PHÂN QUYỀN (Permissions)
// ═══════════════════════════════════════════
class _PermissionsTab extends StatelessWidget {
  const _PermissionsTab({required this.tournament});

  final dynamic tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    // Extract staff info from tournament
    final creatorName = tournament.creatorFullName ?? l10n.organizer_permissionsUnknown;
    final creatorAvatar = tournament.creatorAvatarUrl ?? '';
    final visibility = tournament.visibility ?? 'PUBLIC';
    final adminToken = tournament.adminToken ?? '';
    final refereeToken = tournament.refereeToken ?? '';
    final viewerToken = tournament.viewerToken ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Creator info
        _sectionLabel(l10n.organizer_permissionsCreator, colors),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                backgroundImage: creatorAvatar.isNotEmpty ? NetworkImage(creatorAvatar) : null,
                child: creatorAvatar.isEmpty
                    ? Text(
                        creatorName.isNotEmpty ? creatorName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(creatorName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(l10n.dashboard_organizer, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.verified_rounded, color: AppTheme.primary, size: 22),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Roles & Access
        _sectionLabel(l10n.organizer_permissionsRoles, colors),
        const SizedBox(height: 8),
        _roleCard(
          context,
          l10n: l10n,
          icon: Icons.shield_rounded,
          title: l10n.organizer_permissionsAdmin,
          subtitle: l10n.organizer_permissionsAdminDesc,
          color: const Color(0xFFEF4444),
          token: adminToken,
          tokenLabel: l10n.organizer_permissionsTokenAdmin,
        ),
        const SizedBox(height: 8),
        _roleCard(
          context,
          l10n: l10n,
          icon: Icons.gavel_rounded,
          title: l10n.infoReferee,
          subtitle: l10n.organizer_permissionsRefereeDesc,
          color: AppTheme.refereeColor,
          token: refereeToken,
          tokenLabel: l10n.organizer_permissionsTokenReferee,
        ),
        const SizedBox(height: 8),
        _roleCard(
          context,
          l10n: l10n,
          icon: Icons.visibility_rounded,
          title: l10n.organizer_permissionsViewer,
          subtitle: l10n.organizer_permissionsViewerDesc,
          color: const Color(0xFF10B981),
          token: viewerToken,
          tokenLabel: l10n.organizer_permissionsTokenViewer,
        ),
        const SizedBox(height: 20),

        // Visibility setting
        _sectionLabel(l10n.organizer_permissionsVisibility, colors),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: (visibility == 'PUBLIC' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  visibility == 'PUBLIC' ? Icons.public_rounded : Icons.lock_rounded,
                  color: visibility == 'PUBLIC' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.organizer_permissionsDisplay, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    Text(
                      visibility == 'PUBLIC' ? l10n.organizer_permissionsPublic : l10n.organizer_permissionsPrivate,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Info note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E3A5F).withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: const Color(0xFF60A5FA)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.organizer_permissionsInfoNote,
                  style: TextStyle(fontSize: 12, color: const Color(0xFF93C5FD), height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text, AppColorsExtension colors) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.textSecondary, letterSpacing: 0.5),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required AppLocalizations l10n,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String token,
    required String tokenLabel,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (token.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.vpn_key_rounded, size: 14, color: colors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      token,
                      style: TextStyle(fontSize: 11, color: colors.textMuted, fontFamily: 'monospace'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: token));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l10n.organizer_tokenCopied(tokenLabel)),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ));
                    },
                    child: Icon(Icons.copy_rounded, size: 16, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
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

