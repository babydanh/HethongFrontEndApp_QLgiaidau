import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'package:intl/intl.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';

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
  bool _hasMore = false;
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

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(matchRepositoryProvider);
      final result = await repo.getTournamentMatchesPaged(
        tournamentId: widget.tournament.id,
        status: widget.filterStatus == 'all' ? null : widget.filterStatus,
        cursor: _pageCursors[pageIndex],
        limit: 4,
      );

      if (mounted) {
        setState(() {
          _pageMatches[pageIndex] = result.matches;
          _hasMore = result.hasMore;
          _totalMatches = result.total;
          if (result.nextCursor != null && result.nextCursor!.isNotEmpty) {
            _pageCursors[pageIndex + 1] = result.nextCursor;
          }
          _currentPageIndex = pageIndex;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;

    String apiBase = 'http://localhost:3000/api/v1';
    try {
      apiBase = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
      if (!kIsWeb && Platform.isAndroid && apiBase.contains('localhost')) {
        apiBase = apiBase.replaceAll('localhost', '10.0.2.2');
      }
    } catch (_) {}

    final host = apiBase.replaceAll('/api/v1', '');
    return '$host$url';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedLogoUrl = _resolveImageUrl(widget.tournament.logoUrl);

    final currentMatches = _pageMatches[_currentPageIndex] ?? const <MatchModel>[];

    if (currentMatches.isEmpty && !_isLoading && _pageMatches.isNotEmpty) {
      return const SizedBox.shrink();
    }
    if (currentMatches.isEmpty && !_isLoading && _pageMatches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero,
      decoration: const BoxDecoration(color: Colors.white),
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
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: resolvedLogoUrl.isNotEmpty
                          ? Image.network(
                              resolvedLogoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      "assets/images/sporto_v1_with_text.png",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                "assets/images/sporto_v1_with_text.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tournament.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
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
              height: 154,
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
          if (currentMatches.isNotEmpty || _totalMatches > 0)
            _buildCursorPaginationBar(context, l10n),

          Container(height: 12, color: context.colors.bgSurface),
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
    final canGoNext =
        (_hasMore || _pageMatches.containsKey(_currentPageIndex + 1)) &&
        !_isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _totalMatches > 0
                    ? '${l10n.userProfileTotalMatches}: $_totalMatches'
                    : 'Trang ${_currentPageIndex + 1}',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${_currentPageIndex + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
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
    final courtText = TournamentLocationFormatter.matchShortCourt(
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

    return GestureDetector(
      onTap: () => context.push('/live/${match.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Row: Stage Tag & Sport ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_handball_rounded,
                      size: 12,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sportText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (bracketText.isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border, width: 1),
                      ),
                      child: Text(
                        bracketText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Teams & Score Section ──
            Column(
              children: [
                // Team 1 Row
                Row(
                  children: [
                    _DoubleAvatarWidget(
                      initial1: t1Initials.isNotEmpty ? t1Initials[0] : 'NM',
                      initial2: t1Initials.length > 1 ? t1Initials[1] : '',
                      color: const Color(0xFF0284C7),
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
                      constraints: const BoxConstraints(minWidth: 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (match.sets.isNotEmpty
                                ? match.sets.last.score1 >
                                      match.sets.last.score2
                                : match.score1 > match.score2)
                            ? AppTheme.primary.withValues(alpha: 0.12)
                            : colors.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              (match.sets.isNotEmpty
                                  ? match.sets.last.score1 >
                                        match.sets.last.score2
                                  : match.score1 > match.score2)
                              ? AppTheme.primary.withValues(alpha: 0.4)
                              : colors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${match.sets.isNotEmpty ? match.sets.last.score1 : match.score1}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Team 2 Row
                Row(
                  children: [
                    _DoubleAvatarWidget(
                      initial1: t2Initials.isNotEmpty ? t2Initials[0] : 'VQ',
                      initial2: t2Initials.length > 1 ? t2Initials[1] : '',
                      color: const Color(0xFF16A34A),
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
                      constraints: const BoxConstraints(minWidth: 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (match.sets.isNotEmpty
                                ? match.sets.last.score2 >
                                      match.sets.last.score1
                                : match.score2 > match.score1)
                            ? AppTheme.primary.withValues(alpha: 0.12)
                            : colors.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              (match.sets.isNotEmpty
                                  ? match.sets.last.score2 >
                                        match.sets.last.score1
                                  : match.score2 > match.score1)
                              ? AppTheme.primary.withValues(alpha: 0.4)
                              : colors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${match.sets.isNotEmpty ? match.sets.last.score2 : match.score2}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.4)),
            const SizedBox(height: 8),

            // ── Single Merged Footer Row: Location & Quick Action Icons ──
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 13,
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

                // Cheer Button (Fresh Bright Capsule Button)
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isCheered
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCheered
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCheered
                              ? Icons.favorite
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: isCheered
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFE11D48),
                        ),
                        if (cheerCount > 0) ...[
                          const SizedBox(width: 5),
                          Text(
                            '$cheerCount',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
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

                // Share Button (Fresh Bright Circle Button)
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.share_rounded,
                        size: 15,
                        color: const Color(0xFF2563EB),
                      ),
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
      onTap: () => context.push('/live/${match.id}'),
      child: Container(
        width: 285,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Round Badge (Left) | LIVE indicator (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
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
                          color: Color(0xFFDC2626),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Middle Row: Team 1 (Avatar + Name) -- Score -- Team 2 (Avatar + Name)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Team 1
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLargeAvatar(
                        initials: t1Initials[0],
                        initials2: t1Initials.length > 1 ? t1Initials[1] : '',
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

                // Big Score & Set Breakdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${match.score1} - ${match.score2}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (match.sets.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            match.sets.map((s) => '${s.score1}-${s.score2}').join('  '),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Team 2
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLargeAvatar(
                        initials: t2Initials[0],
                        initials2: t2Initials.length > 1 ? t2Initials[1] : '',
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

            // Bottom Footer: Court Info (Sân thi đấu ở dưới nhỏ gọn)
            if (courtText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          courtText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeAvatar({
    required String initials,
    String initials2 = '',
    Color avatarColor = AppTheme.primary,
  }) {
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
                  color: Colors.white,
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

    final String? scheduledTimeStr = match.scheduledTime != null
        ? DateFormat('HH:mm').format(match.scheduledTime!)
        : null;

    final courtText = TournamentLocationFormatter.matchShortCourt(
      match.court,
      venueName: widget.tournament.venueName,
    );

    return GestureDetector(
      onTap: () => context.push('/live/${match.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        ),
        child: Row(
          children: [
            // Left Round/Time Pill Badge
            Container(
              constraints: const BoxConstraints(minWidth: 54),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    roundText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (scheduledTimeStr != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      scheduledTimeStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
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
                        color: const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          match.team1Name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _DoubleAvatarWidget(
                        initial1: t2Initials.isNotEmpty ? t2Initials[0] : 'T2',
                        initial2: t2Initials.length > 1 ? t2Initials[1] : '',
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          match.team2Name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Court / Info Badge
            if (courtText.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxWidth: 115),
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border.withValues(alpha: 0.7)),
                ),
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
  final Color color;

  const _DoubleAvatarWidget({
    required this.initial1,
    required this.initial2,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (initial2.isEmpty || initial2 == '?') {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.bgCard,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Text(
            initial1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 48,
      height: 28,
      child: Stack(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Text(
                initial1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  initial2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
