import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Same live statuses as the Web "Đang diễn ra" tab (it also accepts PLAYING).
const _liveStatuses = {'LIVE', 'ONGOING', 'IN_PROGRESS', 'PLAYING'};

bool _isOfferable(MatchModel m) =>
    !m.isByeMatch && !m.isCompleted && m.winnerId.isEmpty;

bool isLiveSuggestion(MatchModel m) =>
    _liveStatuses.contains(m.normalizedStatus);

/// Matches worth offering next, using the Web rules: no byes, nothing already
/// completed or decided. Live ones first, then upcoming ones; the match being
/// watched and other statuses are left out.
List<MatchModel> pickLiveSuggestions(
  List<MatchModel> matches, {
  required String currentMatchId,
}) {
  final others = matches.where(
    (m) => m.id != currentMatchId && _isOfferable(m),
  );
  return [
    ...others.where(isLiveSuggestion),
    ...others.where((m) => !isLiveSuggestion(m) && m.isScheduled),
  ];
}

enum _SuggestionFilter { all, live, soon }

const _thumbWidth = 128.0;
const _thumbHeight = 72.0;
const _thumbColors = [Color(0xFF0F172A), Color(0xFF1E3A8A)];

/// "More videos" tab: one uniform row per other match (thumbnail + names),
/// with filter chips like the Web match list.
class LiveViewerSuggestions extends ConsumerStatefulWidget {
  const LiveViewerSuggestions({
    super.key,
    required this.tournamentId,
    required this.currentMatchId,
    required this.onOpen,
  });

  final String tournamentId;
  final String currentMatchId;
  final void Function(MatchModel match) onOpen;

  @override
  ConsumerState<LiveViewerSuggestions> createState() =>
      _LiveViewerSuggestionsState();
}

class _LiveViewerSuggestionsState extends ConsumerState<LiveViewerSuggestions> {
  _SuggestionFilter _filter = _SuggestionFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The bracket projection also carries Lite matches, which the public flat
    // feed behind matchesProvider leaves out (that made this tab empty).
    final async = ref.watch(bracketMatchesProvider(widget.tournamentId));

    return async.when(
      loading: () => const SkeletonScope(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              SkeletonBox(height: _thumbHeight, radius: 10),
              SizedBox(height: 12),
              SkeletonBox(height: _thumbHeight, radius: 10),
              SizedBox(height: 12),
              SkeletonBox(height: _thumbHeight, radius: 10),
            ],
          ),
        ),
      ),
      error: (_, _) => Center(child: Text(l10n.homeMatchesLoadError)),
      data: (matches) {
        final picked = pickLiveSuggestions(
          matches,
          currentMatchId: widget.currentMatchId,
        );
        if (picked.isEmpty) {
          return Center(child: Text(l10n.liveSuggestionsEmpty));
        }
        final shown = switch (_filter) {
          _SuggestionFilter.all => picked,
          _SuggestionFilter.live => picked.where(isLiveSuggestion).toList(),
          _SuggestionFilter.soon =>
            picked.where((m) => !isLiveSuggestion(m)).toList(),
        };
        return Column(
          children: [
            _buildFilters(l10n),
            Expanded(
              child: shown.isEmpty
                  ? Center(child: Text(l10n.liveSuggestionsEmpty))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _SuggestionRow(
                        match: shown[i],
                        onTap: () => widget.onOpen(shown[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    final labels = {
      _SuggestionFilter.all: l10n.matchesFilterAll,
      _SuggestionFilter.live: l10n.matchesFilterOngoing,
      _SuggestionFilter.soon: l10n.matchesFilterScheduled,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          for (final entry in labels.entries) ...[
            ChoiceChip(
              key: ValueKey('live-suggestion-filter-${entry.key.name}'),
              label: Text(entry.value),
              selected: _filter == entry.key,
              onSelected: (_) => setState(() => _filter = entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.match, required this.onTap});

  final MatchModel match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final round = MatchRoundLabel.formatRound(
      match: match,
      short: true,
      l10n: l10n,
    );
    final court = TournamentLocationFormatter.matchShortCourt(match.court);
    final subtitle = [round, court].where((s) => s.isNotEmpty).join(' · ');

    return InkWell(
      key: ValueKey('live-suggestion-${match.id}'),
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SuggestionThumb(match: match),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_sideName(l10n, 1)} ${l10n.matchVsLabel} ${_sideName(l10n, 2)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sideName(AppLocalizations l10n, int side) {
    final name = matchSideLabel(match, side).trim();
    return name.isEmpty ? l10n.matchNotDetermined : name;
  }
}

/// No frame image exists for a match, so the thumbnail is drawn from the two
/// sides' logos plus the live score (or "VS") and the start time.
class _SuggestionThumb extends StatelessWidget {
  const _SuggestionThumb({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final live = isLiveSuggestion(match);
    final score = match.currentLiveScore;
    final start = match.scheduledTime;

    return ClipRRect(
      key: ValueKey('live-suggestion-thumb-${match.id}'),
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _thumbWidth,
        height: _thumbHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _thumbColors,
            ),
          ),
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SideLogo(
                    url: match.team1LogoUrl,
                    name: matchSideLabel(match, 1),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          live
                              ? '${score.score1} - ${score.score2}'
                              : l10n.matchVsLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _SideLogo(
                    url: match.team2LogoUrl,
                    name: matchSideLabel(match, 2),
                  ),
                ],
              ),
              if (live)
                Positioned(
                  left: 5,
                  top: 5,
                  child: _ThumbBadge(
                    text: l10n.matchLiveStatus,
                    color: const Color(0xFFDC2626),
                  ),
                )
              else if (start != null)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: _ThumbBadge(
                    text:
                        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbBadge extends StatelessWidget {
  const _ThumbBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SideLogo extends StatelessWidget {
  const _SideLogo({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = Center(
      child: Text(
        trimmed.isEmpty ? '?' : trimmed[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final logo = url;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: logo != null && logo.isNotEmpty
          ? Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => initial,
            )
          : initial,
    );
  }
}
