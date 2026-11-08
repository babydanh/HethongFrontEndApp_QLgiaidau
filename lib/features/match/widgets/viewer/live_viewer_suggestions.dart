import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/data/models/match_suggestion_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SuggestionFilter { all, live, replay, sameTournament }

/// A replay shorter than this is not worth suggesting (same rule as the Web).
const _minReplaySec = 180;

/// Starts the next page a little before the viewer reaches the last card.
const _loadMoreMargin = 160.0;

const _thumbWidth = 152.0;

/// Live videos always count; a replay needs at least three minutes of video.
bool isSuggestable(MatchSuggestion item) {
  final duration = item.durationSec;
  return item.isLive || (duration != null && duration >= _minReplaySec);
}

/// Keeps the server order; the server already ranks live first.
List<MatchSuggestion> filterSuggestions(
  Iterable<MatchSuggestion> items,
  SuggestionFilter filter,
) {
  return items.where((item) {
    return switch (filter) {
      SuggestionFilter.all => true,
      SuggestionFilter.live => item.isLive,
      SuggestionFilter.replay => !item.isLive,
      SuggestionFilter.sameTournament => item.sameTournament,
    };
  }).toList();
}

/// Appends a freshly loaded page, keeping the first copy of any match listed.
List<MatchSuggestion> mergeSuggestionPages(
  List<MatchSuggestion> current,
  List<MatchSuggestion> incoming,
) {
  final seen = current.map((item) => item.matchId).toSet();
  return [...current, ...incoming.where((item) => seen.add(item.matchId))];
}

/// `15:38`, or `1:02:05` from one hour up; empty when missing or invalid.
String formatSuggestionDuration(int? seconds) {
  if (seconds == null || seconds < 0) return '';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = (seconds % 60).toString().padLeft(2, '0');
  if (hours == 0) return '$minutes:$secs';
  return '$hours:${minutes.toString().padLeft(2, '0')}:$secs';
}

/// Stable hue (0-359) per tournament, so its cards share a colour without a
/// cover image. Same hash as the Web.
int suggestionThumbHue(String tournamentId) {
  var hash = 0;
  for (final unit in tournamentId.codeUnits) {
    hash = (hash * 31 + unit) % 360;
  }
  return hash;
}

/// "More videos" tab, same content as the Web "Video gợi ý": live matches and
/// replays from the suggestions API, with pill filters and paging by cursor.
class LiveViewerSuggestions extends ConsumerStatefulWidget {
  const LiveViewerSuggestions({
    super.key,
    required this.currentMatchId,
    required this.onOpen,
  });

  final String currentMatchId;
  final void Function(MatchSuggestion suggestion) onOpen;

  @override
  ConsumerState<LiveViewerSuggestions> createState() =>
      _LiveViewerSuggestionsState();
}

class _LiveViewerSuggestionsState extends ConsumerState<LiveViewerSuggestions> {
  final _scroll = ScrollController();
  List<MatchSuggestion>? _items;
  String? _nextCursor;
  var _filter = SuggestionFilter.all;
  var _failed = false;
  var _loadingMore = false;

  // A failed page is retried only after the viewer scrolls again, so a dead
  // connection cannot turn the auto-load into a request loop.
  var _moreFailed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _maybeLoadMore(userScroll: true));
    _loadFirst();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<MatchSuggestion> _suggestable(List<MatchSuggestion> page) => page
      .where((s) => s.matchId != widget.currentMatchId && isSuggestable(s))
      .toList();

  Future<void> _loadFirst() async {
    try {
      final page = await ref
          .read(matchPlaybackRepositoryProvider)
          .getMatchSuggestions(widget.currentMatchId);
      if (!mounted) return;
      setState(() {
        _items = _suggestable(page.items);
        _nextCursor = page.nextCursor;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _items = const [];
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(matchPlaybackRepositoryProvider)
          .getMatchSuggestions(widget.currentMatchId, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _items = mergeSuggestionPages(
          _items ?? const [],
          _suggestable(page.items),
        );
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } on Exception {
      // Keep the cards already shown; scrolling again tries the page again.
      if (!mounted) return;
      setState(() {
        _moreFailed = true;
        _loadingMore = false;
      });
    }
  }

  /// Asks for the next page when the list is short or scrolled near its end.
  void _maybeLoadMore({bool userScroll = false}) {
    if (userScroll) _moreFailed = false;
    if (_nextCursor == null || _loadingMore || _moreFailed) return;
    final nearEnd =
        !_scroll.hasClients || _scroll.position.extentAfter < _loadMoreMargin;
    if (nearEnd) _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _items;
    if (items == null) return const _SuggestionSkeleton(rows: 3);
    if (_failed) return Center(child: Text(l10n.homeMatchesLoadError));

    // Runs before the empty check: a first page that is all filtered out must
    // still pull the next page instead of ending on "no videos".
    if (_nextCursor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeLoadMore();
      });
    }
    if (items.isEmpty) {
      final waitingForPage = _nextCursor != null && !_moreFailed;
      return waitingForPage
          ? const _SuggestionSkeleton(rows: 3)
          : Center(child: Text(l10n.liveSuggestionsEmpty));
    }
    final shown = filterSuggestions(items, _filter);
    return Column(
      children: [
        _FilterPills(
          selected: _filter,
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        Expanded(child: _buildList(l10n, shown)),
      ],
    );
  }

  Widget _buildList(AppLocalizations l10n, List<MatchSuggestion> shown) {
    if (shown.isEmpty) {
      final waitingForPage = _nextCursor != null && !_moreFailed;
      return waitingForPage
          ? const _SuggestionSkeleton(rows: 2)
          : Center(child: Text(l10n.liveSuggestionsEmptyFilter));
    }
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      children: [
        for (final item in shown)
          _SuggestionRow(item: item, onTap: () => widget.onOpen(item)),
        if (_loadingMore) const _SuggestionSkeleton(rows: 2, scrollable: false),
      ],
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.selected, required this.onSelected});

  final SuggestionFilter selected;
  final ValueChanged<SuggestionFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      SuggestionFilter.all: l10n.matchesFilterAll,
      SuggestionFilter.live: l10n.liveSuggestionsFilterLive,
      SuggestionFilter.replay: l10n.liveSuggestionsFilterReplay,
      SuggestionFilter.sameTournament: l10n.liveSuggestionsFilterSameTournament,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final entry in labels.entries)
            _Pill(
              key: ValueKey('live-suggestion-filter-${entry.key.name}'),
              label: entry.value,
              active: entry.key == selected,
              onTap: () => onSelected(entry.key),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? colors.textPrimary : colors.bgSurface,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? colors.bgCard : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.item, required this.onTap});

  final MatchSuggestion item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final subtitle = [
      item.tournamentName,
      item.roundLabel ?? '',
    ].where((part) => part.isNotEmpty).join(' · ');
    final team1 = item.team1Name.isEmpty
        ? l10n.matchNotDetermined
        : item.team1Name;
    final team2 = item.team2Name.isEmpty
        ? l10n.matchNotDetermined
        : item.team2Name;

    return InkWell(
      key: ValueKey('live-suggestion-${item.matchId}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SuggestionThumb(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$team1 ${l10n.matchVsLabel} $team2',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    if (!item.isLive)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          l10n.liveSuggestionsBadgeReplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
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
}

/// No cover image exists yet, so the tile is a court-like card in the
/// tournament's colour with the score on it (same drawing as the Web).
class _SuggestionThumb extends StatelessWidget {
  const _SuggestionThumb({required this.item});

  final MatchSuggestion item;

  @override
  Widget build(BuildContext context) {
    final hue = suggestionThumbHue(item.tournamentId).toDouble();
    final line = Colors.white.withValues(alpha: 0.4);
    final duration = formatSuggestionDuration(item.durationSec);

    return SizedBox(
      width: _thumbWidth,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          key: ValueKey('live-suggestion-thumb-${item.matchId}'),
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HSLColor.fromAHSL(1, hue, 0.55, 0.20).toColor(),
                  HSLColor.fromAHSL(1, hue, 0.60, 0.38).toColor(),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    heightFactor: 0.72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: line),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: SizedBox(width: 1, child: ColoredBox(color: line)),
                      ),
                    ),
                  ),
                ),
                if (item.isLive)
                  const Positioned(left: 8, top: 8, child: _LiveDot())
                else if (duration.isNotEmpty)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: _ThumbBadge(text: duration, alpha: 0.75),
                  ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: _ThumbBadge(
                    text: '${item.team1Score} – ${item.team2Score}',
                    alpha: 0.6,
                    bold: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFDC2626);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: red.withValues(alpha: 0.4), spreadRadius: 2),
        ],
      ),
    );
  }
}

class _ThumbBadge extends StatelessWidget {
  const _ThumbBadge({required this.text, required this.alpha, this.bold = false});

  final String text;
  final double alpha;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: bold ? 11 : 10,
            height: 1,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _SuggestionSkeleton extends StatelessWidget {
  const _SuggestionSkeleton({required this.rows, this.scrollable = true});

  final int rows;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        for (var i = 0; i < rows; i++)
          const Padding(
            padding: EdgeInsets.all(6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: _thumbWidth, height: 85.5, radius: 8),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      SkeletonBox(height: 12, radius: 4),
                      SizedBox(height: 8),
                      SkeletonBox(width: 90, height: 12, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return SkeletonScope(
      child: scrollable
          ? SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(6),
              child: content,
            )
          : content,
    );
  }
}
