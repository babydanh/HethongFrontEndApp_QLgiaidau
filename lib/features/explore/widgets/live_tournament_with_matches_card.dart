import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/core/widgets/tournament_avatar.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/cursor_pagination.dart';
import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';

class LiveTournamentWithMatchesCard extends ConsumerStatefulWidget {
  final Tournament tournament;
  final String? filterStatus; // 'live', 'completed', 'scheduled'

  const LiveTournamentWithMatchesCard({
    super.key,
    required this.tournament,
    this.filterStatus,
  });

  @override
  ConsumerState<LiveTournamentWithMatchesCard> createState() =>
      _LiveTournamentWithMatchesCardState();
}

class _LiveTournamentWithMatchesCardState
    extends ConsumerState<LiveTournamentWithMatchesCard> {
  final Map<String, int> _cheerCounts = {};
  final Set<String> _cheerInFlight = {};

  int _currentPageIndex = 0;
  bool _isLoading = false;
  int _totalMatches = 0;
  final Map<int, List<MatchModel>> _pageMatches = {};
  final Map<int, String?> _pageCursors = {0: null};

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  @override
  void didUpdateWidget(covariant LiveTournamentWithMatchesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournament.id != widget.tournament.id ||
        oldWidget.filterStatus != widget.filterStatus) {
      _pageMatches.clear();
      _pageCursors.clear();
      _pageCursors[0] = null;
      _currentPageIndex = 0;
      _loadPage(0);
    }
  }

  Future<void> _loadPage(int pageIndex) async {
    if (_pageMatches.containsKey(pageIndex)) {
      setState(() => _currentPageIndex = pageIndex);
      return;
    }
    if (_isLoading) return;
    if (pageIndex > 0 && (_pageCursors[pageIndex]?.trim().isNotEmpty != true)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(matchRepositoryProvider);
      var requestCursor = _pageCursors[pageIndex];
      List<MatchModel> visiblePageMatches = const <MatchModel>[];
      String? visiblePageNextCursor;
      var latestTotal = _totalMatches;

      // The API cursor paginates raw fixtures, which can include BYE/TBD or
      // mock participants hidden by the public match filter. Walk over those
      // raw pages so a visible page never renders as an empty card.
      for (var attempt = 0; attempt < 20; attempt++) {
        final result = await repo.getTournamentMatchesPaged(
          tournamentId: widget.tournament.id,
          status: widget.filterStatus == 'all' ? null : widget.filterStatus,
          cursor: requestCursor,
          limit: 4,
        );
        latestTotal = result.total;
        final renderableMatches = result.matches
            .where(isRenderablePublicMatch)
            .toList(growable: false);
        final nextCursor = result.nextCursor?.trim();

        if (renderableMatches.isNotEmpty) {
          visiblePageMatches = result.matches;
          visiblePageNextCursor = nextCursor;
          break;
        }

        if (nextCursor == null ||
            nextCursor.isEmpty ||
            nextCursor == requestCursor) {
          break;
        }
        requestCursor = nextCursor;
      }

      if (mounted) {
        setState(() {
          _totalMatches = latestTotal;
          _isLoading = false;

          if (visiblePageMatches.isNotEmpty) {
            _pageMatches[pageIndex] = visiblePageMatches;
            _currentPageIndex = pageIndex;
            if (visiblePageNextCursor?.isNotEmpty == true) {
              _pageCursors[pageIndex + 1] = visiblePageNextCursor;
            } else {
              _pageCursors.remove(pageIndex + 1);
            }
          } else if (pageIndex == 0) {
            // Cache the empty first result so the widget can collapse cleanly
            // instead of rendering a header and an empty pagination card.
            _pageMatches[0] = const <MatchModel>[];
          } else {
            // Do not advance to a cursor page with no public matches. Removing
            // its cursor also disables the next button on the last visible page.
            _pageCursors.remove(pageIndex);
          }
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final colors = context.colors;
    final currentMatches =
        (_pageMatches[_currentPageIndex] ?? const <MatchModel>[])
            .where(isRenderablePublicMatch)
            .toList(growable: false);

    if (currentMatches.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(color: colors.bgCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Outer Header: Tournament Logo + Name + ELO Tag ──
          GestureDetector(
            onTap: () => context.push('/intro/${widget.tournament.id}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  TournamentAvatar(
                    imageUrl: widget.tournament.logoUrl,
                    tournamentName: widget.tournament.name,
                    sport: widget.tournament.sport,
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tournament.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          widget.tournament.isRanked
                              ? (l10n.exploreRankedTournament)
                              : (l10n.exploreFriendlyTournament),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Matches Content Area ──
          if (_isLoading && currentMatches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (widget.filterStatus == 'live')
            SizedBox(
              height: 144,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: currentMatches.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) =>
                    _buildHorizontalLiveCard(context, currentMatches[i]),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: currentMatches.map((match) {
                  final Widget matchWidget;
                  if (widget.filterStatus == 'scheduled') {
                    matchWidget = _buildHorizontalScheduleRow(
                      context,
                      match,
                      currentMatches,
                    );
                  } else {
                    matchWidget = _buildMatchCard(
                      context,
                      match,
                      currentMatches,
                    );
                  }
                  return Padding(
                    key: ValueKey<String>(match.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: matchWidget,
                  );
                }).toList(),
              ),
            ),

          // ── Cursor Pagination Navigation Bar ──
          if (currentMatches.isNotEmpty &&
              (_currentPageIndex > 0 ||
                  _pageMatches.containsKey(_currentPageIndex + 1) ||
                  _pageCursors[_currentPageIndex + 1]?.trim().isNotEmpty ==
                      true))
            _buildCursorPaginationBar(context, l10n),

          Container(height: 10, color: context.colors.bgDark),
        ],
      ),
    );
  }

  Widget _buildCursorPaginationBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colors = context.colors;
    final canGoPrev = _currentPageIndex > 0 && !_isLoading;
    final canGoNext = canAdvanceCursorPage(
      isLoading: _isLoading,
      hasCachedPage: _pageMatches.containsKey(_currentPageIndex + 1),
      nextCursor: _pageCursors[_currentPageIndex + 1],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Trang ${_currentPageIndex + 1}',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ],
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: canGoPrev
                    ? () => _loadPage(_currentPageIndex - 1)
                    : null,
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: canGoPrev ? colors.bgSurface : colors.bgCard,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: canGoPrev
                          ? colors.border
                          : colors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: canGoPrev
                        ? colors.textPrimary
                        : colors.textMuted.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_currentPageIndex + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: canGoNext
                    ? () => _loadPage(_currentPageIndex + 1)
                    : null,
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: canGoNext ? colors.bgSurface : colors.bgCard,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: canGoNext
                          ? colors.border
                          : colors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: canGoNext
                        ? colors.textPrimary
                        : colors.textMuted.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    MatchModel match, [
    List<MatchModel>? allMatches,
  ]) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isT1Tbd =
        match.team1Name.trim().toUpperCase() == 'TBD' ||
        match.team1Name.trim().toUpperCase() == 'BYE';
    final isT2Tbd =
        match.team2Name.trim().toUpperCase() == 'TBD' ||
        match.team2Name.trim().toUpperCase() == 'BYE';
    final isByeMatch = match.isBye || isT1Tbd || isT2Tbd;
    final cardScore = match.isLive
        ? match.currentLiveScore
        : SetScore(score1: match.score1, score2: match.score2);

    final bracketText = MatchRoundLabel.formatRound(
      match: match,
      allMatches: allMatches,
      tournament: widget.tournament,
      short: false,
      l10n: l10n,
    );
    final sportText = l10n.sportDisplayName(
      match.sportKey ?? widget.tournament.sport,
    );
    final courtText =
        TournamentLocationFormatter.matchShortCourt(
          match.court,
          venueName: widget.tournament.venueName,
        ).isNotEmpty
        ? TournamentLocationFormatter.matchShortCourt(
            match.court,
            venueName: widget.tournament.venueName,
          )
        : (l10n.exploreCourtNotAssigned);

    List<String> getInitials(String name) {
      final parts = name
          .split('-')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return [_getSingleInitials(parts[0]), _getSingleInitials(parts[1])];
      }
      final words = name.trim().split(' ');
      if (words.length >= 2) {
        return ['${words[0][0]}${words[1][0]}'.toUpperCase(), ''];
      }
      return [name.isNotEmpty ? name[0].toUpperCase() : '?', ''];
    }

    final t1Initials = getInitials(match.team1Name);
    final t2Initials = getInitials(match.team2Name);
    final cheerCount = _cheerCounts[match.id] ?? 0;
    final isCheered = cheerCount > 0;

    final isWinner1 = cardScore.score1 > cardScore.score2;
    final isWinner2 = cardScore.score2 > cardScore.score1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(
        NavigationHelper.getLiveMatchRoute(widget.tournament.id, match.id),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? colors.bgSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.border.withValues(alpha: isDark ? 0.7 : 0.8),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Row: Sport Name & Stage Tag (No sport icon) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sportText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
                if (bracketText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.bgElevated
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bracketText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Teams & Score Section ──
            Column(
              children: [
                // Team 1 Row
                Row(
                  children: [
                    _DoubleAvatarWidget(
                      initial1: t1Initials.isNotEmpty ? t1Initials[0] : 'NM',
                      initial2: t1Initials.length > 1 ? t1Initials[1] : '',
                      isTeamOne: true,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              match.team1Name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (isByeMatch && isT2Tbd && !isT1Tbd) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.exploreByeAdvance,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(minWidth: 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isWinner1
                            ? AppTheme.primary
                            : (isDark
                                  ? colors.bgElevated
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${cardScore.score1}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isWinner1 ? Colors.white : colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Team 2 Row
                Row(
                  children: [
                    _DoubleAvatarWidget(
                      initial1: t2Initials.isNotEmpty ? t2Initials[0] : 'VQ',
                      initial2: t2Initials.length > 1 ? t2Initials[1] : '',
                      isTeamOne: false,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              match.team2Name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (isByeMatch && isT1Tbd && !isT2Tbd) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.exploreByeAdvance,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(minWidth: 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isWinner2
                            ? AppTheme.primary
                            : (isDark
                                  ? colors.bgElevated
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${cardScore.score2}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isWinner2 ? Colors.white : colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Single Merged Footer Row: Location & Clean Action Icons ──
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    courtText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Cheer Button (Clean icon without heavy border box)
                InkWell(
                  onTap: () async {
                    if (_cheerInFlight.contains(match.id)) return;
                    _cheerInFlight.add(match.id);
                    final previousCount = _cheerCounts[match.id] ?? 0;
                    setState(() {
                      _cheerCounts[match.id] = previousCount + 1;
                    });
                    try {
                      await ref
                          .read(matchRepositoryProvider)
                          .cheerMatch(match.id);
                      final count = await ref
                          .read(matchRepositoryProvider)
                          .getCheerCount(match.id);
                      if (mounted) {
                        setState(() => _cheerCounts[match.id] = count);
                      }
                    } catch (_) {
                      if (mounted) {
                        setState(() => _cheerCounts[match.id] = previousCount);
                      }
                    } finally {
                      _cheerInFlight.remove(match.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCheered
                              ? Icons.favorite
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: isCheered
                              ? const Color(0xFFDC2626)
                              : colors.textMuted,
                        ),
                        if (cheerCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$cheerCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCheered
                                  ? const Color(0xFFDC2626)
                                  : colors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Share Button (Clean borderless icon)
                InkWell(
                  onTap: () {
                    AppShareModal.show(
                      context: context,
                      title:
                          '${match.team1Name} ${l10n.matchVsLabel} ${match.team2Name}',
                      subtitle: l10n.exploreShareSubtitle(
                        widget.tournament.name,
                        match.court.isNotEmpty
                            ? match.court
                            : l10n.matchLiveTitle,
                      ),
                      webUrl: 'https://sporto.asia/live/${match.id}',
                      imageUrl: widget.tournament.logoUrl,
                      badgeText: match.isLive
                          ? (l10n.exploreLiveBadge)
                          : (l10n.exploreMatchBadge),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalLiveCard(BuildContext context, MatchModel match) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    List<String> getInitials(String name) {
      final parts = name
          .split('-')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return [_getSingleInitials(parts[0]), _getSingleInitials(parts[1])];
      }
      final words = name.trim().split(' ');
      if (words.length >= 3) {
        return ['${words[0][0]}${words[1][0]}${words[2][0]}'.toUpperCase(), ''];
      }
      if (words.length >= 2) {
        return ['${words[0][0]}${words[1][0]}'.toUpperCase(), ''];
      }
      return [name.isNotEmpty ? name[0].toUpperCase() : '?', ''];
    }

    final t1Initials = getInitials(match.team1Name);
    final t2Initials = getInitials(match.team2Name);

    final roundText = MatchRoundLabel.formatRound(
      match: match,
      tournament: widget.tournament,
      short: true,
      l10n: l10n,
    );

    final courtText = TournamentLocationFormatter.matchShortCourt(
      match.court,
      venueName: widget.tournament.venueName,
    );

    return GestureDetector(
      onTap: () => context.push(
        NavigationHelper.getLiveMatchRoute(widget.tournament.id, match.id),
      ),
      child: Container(
        width: 275,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Round Badge (Left) | LIVE indicator (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    roundText.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                // Live status badge with pulsing red dot
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'TRỰC TIẾP',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEF4444),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Middle Row: Centered Team 1 (Avatar + Name) -- Score -- Team 2 (Avatar + Name)
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Team 1
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLargeAvatar(
                            context,
                            initials: t1Initials[0],
                            initials2: t1Initials.length > 1
                                ? t1Initials[1]
                                : '',
                            avatarColor: const Color(0xFF0284C7),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            match.team1Name,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Big Score (Set hiện tại)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '${match.currentLiveScore.score1} - ${match.currentLiveScore.score2}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    // Team 2
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLargeAvatar(
                            context,
                            initials: t2Initials[0],
                            initials2: t2Initials.length > 1
                                ? t2Initials[1]
                                : '',
                            avatarColor: const Color(0xFF16A34A),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            match.team2Name,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Footer: Court Info (Sân thi đấu ở dưới nhỏ gọn)
            if (courtText.isNotEmpty)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        courtText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeAvatar(
    BuildContext context, {
    required String initials,
    String initials2 = '',
    Color avatarColor = AppTheme.primary,
  }) {
    final colors = context.colors;
    if (initials2.isNotEmpty && initials2 != '?') {
      return SizedBox(
        width: 54,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Partner Avatar (placed first in background at left: 18)
            Positioned(
              left: 18,
              top: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: avatarColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials2,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: avatarColor,
                    ),
                  ),
                ),
              ),
            ),
            // Primary / Captain Avatar (placed second in FOREGROUND - ĐÈ LÊN 1 CHÚT)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarColor, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: avatarColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: avatarColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: avatarColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: avatarColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalScheduleRow(
    BuildContext context,
    MatchModel match, [
    List<MatchModel>? allMatches,
  ]) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    List<String> getInitials(String name) {
      final parts = name
          .split('-')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return [_getSingleInitials(parts[0]), _getSingleInitials(parts[1])];
      }
      final words = name.trim().split(' ');
      if (words.length >= 2) {
        return ['${words[0][0]}${words[1][0]}'.toUpperCase(), ''];
      }
      return [name.isNotEmpty ? name[0].toUpperCase() : '?', ''];
    }

    final t1Initials = getInitials(match.team1Name);
    final t2Initials = getInitials(match.team2Name);

    final roundText = MatchRoundLabel.formatRound(
      match: match,
      allMatches: allMatches,
      tournament: widget.tournament,
      short: true,
      l10n: l10n,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(
        NavigationHelper.getLiveMatchRoute(widget.tournament.id, match.id),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? colors.bgSurface : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.border.withValues(alpha: isDark ? 0.7 : 0.85),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Left Pill Badge: Round name (e.g., Chung kết / Bán kết) - compact, less curved
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0284C7).withValues(alpha: 0.18)
                    : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                roundText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0284C7),
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Teams (Team 1 vs Team 2)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _DoubleAvatarWidget(
                        initial1: t1Initials.isNotEmpty ? t1Initials[0] : 'T1',
                        initial2: t1Initials.length > 1 ? t1Initials[1] : '',
                        isTeamOne: true,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.team1Name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _DoubleAvatarWidget(
                        initial1: t2Initials.isNotEmpty ? t2Initials[0] : 'T2',
                        initial2: t2Initials.length > 1 ? t2Initials[1] : '',
                        isTeamOne: false,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.team2Name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSingleInitials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'
          .toUpperCase();
    }
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }
}

class _DoubleAvatarWidget extends StatelessWidget {
  final String initial1;
  final String initial2;
  final bool? isTeamOne;

  const _DoubleAvatarWidget({
    required this.initial1,
    required this.initial2,
    this.isTeamOne,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teamOne = isTeamOne ?? true;
    final Color circleBg = teamOne
        ? (isDark
              ? const Color(0xFF0369A1).withValues(alpha: 0.3)
              : const Color(0xFFBAE6FD))
        : (isDark
              ? const Color(0xFF15803D).withValues(alpha: 0.3)
              : const Color(0xFFBBF7D0));

    final Color textColor = teamOne
        ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1))
        : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D));

    Widget buildCircle(String text) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      );
    }

    if (initial2.isEmpty || initial2 == '?') {
      return buildCircle(initial1);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildCircle(initial1),
        const SizedBox(width: 4),
        buildCircle(initial2),
      ],
    );
  }
}
