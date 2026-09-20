import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';

/// Renders one public match feed in status order: live, scheduled, completed.
///
/// The web home page starts from one public `/matches` feed and then groups
/// matches by status and tournament. Keeping the same data boundary on mobile
/// prevents one request per tournament and removes the status-tab bottleneck.
class UnifiedPublicMatchFeed extends ConsumerWidget {
  final List<Tournament> tournaments;
  final String sportFilter;
  final String searchQuery;
  final String contentFilter;
  final String bracketFilter;
  final String rankedFilter;

  const UnifiedPublicMatchFeed({
    super.key,
    required this.tournaments,
    this.sportFilter = 'all',
    this.searchQuery = '',
    this.contentFilter = 'all',
    this.bracketFilter = 'all',
    this.rankedFilter = 'all',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final feedAsync = ref.watch(publicMatchesFeedProvider);
    return feedAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: Text(
              l10n.homeMatchesLoadError,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (matches) => _buildSections(context, l10n, matches),
    );
  }

  Widget _buildSections(
    BuildContext context,
    AppLocalizations l10n,
    List<MatchModel> matches,
  ) {
    final tournamentsById = <String, Tournament>{
      for (final tournament in tournaments) tournament.id: tournament,
    };
    final grouped = <String, Map<String, _UnifiedMatchGroup>>{
      'live': <String, _UnifiedMatchGroup>{},
      'scheduled': <String, _UnifiedMatchGroup>{},
      'completed': <String, _UnifiedMatchGroup>{},
    };

    for (final match in matches.where(isRenderablePublicMatch)) {
      final tournamentId = match.tournamentId?.trim() ?? '';
      final tournament =
          tournamentsById[tournamentId] ??
          _fallbackTournament(match, tournamentId);
      if (!_matchesFilter(tournament, match)) continue;
      final status = _statusFor(match);
      final groupKey = tournament.id.isNotEmpty
          ? tournament.id
          : 'match:${match.id}';
      final group = grouped[status]!.putIfAbsent(
        groupKey,
        () => _UnifiedMatchGroup(tournament: tournament),
      );
      group.matches.add(match);
    }

    final slivers = <Widget>[];
    for (final section in const ['live', 'scheduled', 'completed']) {
      final groups = grouped[section]!.values.toList(growable: false);
      if (groups.isEmpty) continue;
      final title = switch (section) {
        'live' => l10n.liveMatches,
        'scheduled' => l10n.upcomingMatches,
        _ => l10n.homeCompletedMatches,
      };
      slivers.add(_buildSectionHeader(context, title, section == 'live'));
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final group = groups[index];
            return LiveTournamentWithMatchesCard(
              tournament: group.tournament,
              filterStatus: section,
              matchesOverride: group.matches.take(4).toList(growable: false),
            );
          }, childCount: groups.length),
        ),
      );
    }

    if (slivers.isEmpty) {
      final message = searchQuery.trim().isEmpty
          ? 'Chưa có trận đấu công khai để hiển thị'
          : 'Không tìm thấy trận đấu phù hợp';
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return SliverMainAxisGroup(slivers: slivers);
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isLive) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            if (isLive) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(Tournament tournament, MatchModel match) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final haystack = [
        tournament.name,
        match.tournamentName ?? '',
        match.team1Name,
        match.team2Name,
      ].join(' ').toLowerCase();
      if (!haystack.contains(query)) return false;
    }
    if (sportFilter != 'all' &&
        !_sameSport(sportFilter, match.sportKey, tournament.sport)) {
      return false;
    }
    if (contentFilter != 'all' &&
        (tournament.category ?? '').toUpperCase() !=
            contentFilter.toUpperCase()) {
      return false;
    }
    if (bracketFilter != 'all' &&
        tournament.bracketType.toUpperCase() != bracketFilter.toUpperCase()) {
      return false;
    }
    if (rankedFilter == 'ranked' && !tournament.isRanked) return false;
    if (rankedFilter == 'unranked' && tournament.isRanked) return false;
    return true;
  }

  bool _sameSport(String selected, String? matchSport, String tournamentSport) {
    final actual =
        (matchSport?.trim().isNotEmpty == true ? matchSport! : tournamentSport)
            .trim()
            .toLowerCase();
    final expected = selected.trim().toLowerCase();
    if (expected == 'all' || actual.isEmpty) return true;
    final normalizedExpected = expected.replaceAll('_', '').replaceAll(' ', '');
    final normalizedActual = actual.replaceAll('_', '').replaceAll(' ', '');
    return normalizedExpected == normalizedActual ||
        normalizedExpected.contains(normalizedActual) ||
        normalizedActual.contains(normalizedExpected);
  }

  String _statusFor(MatchModel match) {
    if (match.isCompleted) return 'completed';
    if (match.isLive ||
        const {'PLAYING', 'STARTED'}.contains(match.normalizedStatus)) {
      return 'live';
    }
    return 'scheduled';
  }

  Tournament _fallbackTournament(MatchModel match, String tournamentId) {
    final id = tournamentId.isNotEmpty ? tournamentId : 'match-${match.id}';
    return Tournament(
      id: id,
      name: match.tournamentName?.trim().isNotEmpty == true
          ? match.tournamentName!.trim()
          : 'Giải đấu',
      sport: match.sportKey ?? '',
      format: '',
      bracketType: '',
      status: 'published',
      visibility: 'PUBLIC',
      adminToken: '',
      refereeToken: '',
      viewerToken: '',
      creatorId: '',
      createdAt: match.updatedAt,
      updatedAt: match.updatedAt,
    );
  }
}

class _UnifiedMatchGroup {
  final Tournament tournament;
  final List<MatchModel> matches = [];

  _UnifiedMatchGroup({required this.tournament});
}
