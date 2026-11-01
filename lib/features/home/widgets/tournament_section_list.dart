import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tournaments scanned per step. The home feed asks the API for matches of
/// this many tournaments first and scans the next batch only when the user
/// scrolls near the end, instead of fetching every tournament on open.
const _tournamentPageSize = 6;

class TournamentSectionList extends ConsumerStatefulWidget {
  final List<Tournament> tournaments;
  final String filterStatus;
  final String searchQuery;
  final String contentFilter;
  final String bracketFilter;
  final String rankedFilter;
  final bool enabled;
  final String emptyMessage;
  final VoidCallback? onNoLiveMatches;

  const TournamentSectionList({
    super.key,
    required this.tournaments,
    required this.filterStatus,
    this.searchQuery = '',
    this.contentFilter = 'all',
    this.bracketFilter = 'all',
    this.rankedFilter = 'all',
    this.enabled = true,
    required this.emptyMessage,
    this.onNoLiveMatches,
  });

  @override
  ConsumerState<TournamentSectionList> createState() =>
      _TournamentSectionListState();
}

class _TournamentSectionListState extends ConsumerState<TournamentSectionList> {
  int _scanLimit = _tournamentPageSize;
  bool _scanScheduled = false;

  @override
  void didUpdateWidget(covariant TournamentSectionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterStatus != widget.filterStatus ||
        oldWidget.searchQuery != widget.searchQuery) {
      _scanLimit = _tournamentPageSize;
    }
  }

  /// Widens the scan by one batch after the current frame. Safe to call from
  /// build: repeated calls within one frame collapse into a single step.
  void _scanNextPage() {
    if (_scanScheduled) return;
    _scanScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanScheduled = false;
      if (!mounted) return;
      setState(() => _scanLimit += _tournamentPageSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.enabled) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (widget.tournaments.isEmpty) {
      if (widget.filterStatus == 'live' && widget.searchQuery.isEmpty) {
        widget.onNoLiveMatches?.call();
      }
      if (widget.searchQuery.isNotEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text(
                widget.emptyMessage,
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
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final activeTournaments = <Tournament>[];
    var hasLoadingMatches = false;
    var hasMatchError = false;
    final failedMatchTournamentIds = <String>[];

    final hasMoreToScan = _scanLimit < widget.tournaments.length;
    for (final t in widget.tournaments.take(_scanLimit)) {
      final matchesAsync = ref.watch(matchesProvider(t.id));
      if (matchesAsync.isLoading) {
        hasLoadingMatches = true;
        continue;
      }
      if (matchesAsync.hasError) {
        hasMatchError = true;
        failedMatchTournamentIds.add(t.id);
        continue;
      }
      final matches = matchesAsync.value ?? const <MatchModel>[];
      final valid = matches.where((m) {
        final t1 = m.team1Name.trim().toUpperCase();
        final t2 = m.team2Name.trim().toUpperCase();
        final isT1Bye = t1 == 'BYE';
        final isT2Bye = t2 == 'BYE';
        final isT1Tbd =
            !isT1Bye && (t1.isEmpty || t1 == 'TBD') && m.team1Id.trim().isEmpty;
        final isT2Tbd =
            !isT2Bye && (t2.isEmpty || t2 == 'TBD') && m.team2Id.trim().isEmpty;
        if (isT1Bye || isT2Bye || (isT1Tbd && isT2Tbd)) return false;

        final q = widget.searchQuery.trim().toLowerCase();
        final matchText = '${m.team1Name} ${m.team2Name} ${m.tournamentName}'
            .toLowerCase();
        if (q.isNotEmpty && !matchText.contains(q)) return false;

        if (widget.filterStatus == 'live') return m.isLive;
        if (widget.filterStatus == 'completed') {
          final status = m.status.toUpperCase();
          return m.isCompleted ||
              status == 'COMPLETED' ||
              status == 'FINISHED' ||
              status == 'DONE' ||
              status == 'ENDED' ||
              m.completedAt != null;
        }
        if (widget.filterStatus == 'scheduled') {
          return m.isScheduled ||
              (m.scheduledTime != null && !m.isLive && !m.isCompleted);
        }
        return true;
      });

      if (valid.isNotEmpty) {
        activeTournaments.add(t);
      }
    }

    // Nothing to show yet but more tournaments remain: keep scanning instead
    // of announcing an empty tab.
    final isScanning =
        hasLoadingMatches || (activeTournaments.isEmpty && hasMoreToScan);

    if (activeTournaments.isEmpty &&
        widget.filterStatus == 'live' &&
        !isScanning &&
        !hasMatchError &&
        widget.searchQuery.isEmpty) {
      widget.onNoLiveMatches?.call();
    }

    final statusMessage = isScanning
        ? l10n.homeMatchesLoading
        : hasMatchError
        ? l10n.homeMatchesLoadError
        : widget.emptyMessage;
    final statusFeedback = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isScanning) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            statusMessage,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasMatchError && !isScanning)
            TextButton.icon(
              key: const ValueKey('home-match-feed-retry'),
              onPressed: () {
                for (final tournamentId in failedMatchTournamentIds) {
                  ref.invalidate(matchesProvider(tournamentId));
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.homeGlobalSearchRetry),
            ),
        ],
      ),
    );
    final hasProviderFeedback = isScanning || hasMatchError;
    // The sentinel row is built lazily, so it exists only once the user has
    // scrolled close to the end of the cards (or no card is on screen).
    final showScanSentinel = hasMoreToScan && !hasLoadingMatches;

    return SliverMainAxisGroup(
      slivers: [
        if (activeTournaments.isEmpty)
          SliverToBoxAdapter(child: statusFeedback),
        if (activeTournaments.isNotEmpty || showScanSentinel)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < activeTournaments.length) {
                  return LiveTournamentWithMatchesCard(
                    tournament: activeTournaments[index],
                    filterStatus: widget.filterStatus,
                  );
                }
                _scanNextPage();
                return const SizedBox(height: 1);
              },
              childCount: activeTournaments.length + (showScanSentinel ? 1 : 0),
            ),
          ),
        if (activeTournaments.isNotEmpty && hasProviderFeedback)
          SliverToBoxAdapter(child: statusFeedback),
      ],
    );
  }
}
