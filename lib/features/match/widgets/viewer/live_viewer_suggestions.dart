import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Matches worth offering next: live ones first, then upcoming ones; the match
/// being watched and finished/other statuses are left out.
List<MatchModel> pickLiveSuggestions(
  List<MatchModel> matches, {
  required String currentMatchId,
}) {
  final others = matches.where((m) => m.id != currentMatchId);
  return [
    ...others.where((m) => m.isLive),
    ...others.where((m) => !m.isLive && m.isScheduled),
  ];
}

/// "More videos" tab: image-style cards for other matches of the tournament.
class LiveViewerSuggestions extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // The bracket projection also carries Lite matches, which the public flat
    // feed behind matchesProvider leaves out (that made this tab empty).
    final async = ref.watch(bracketMatchesProvider(tournamentId));

    return async.when(
      loading: () => const SkeletonScope(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              SkeletonBox(height: 120, radius: 14),
              SizedBox(height: 10),
              SkeletonBox(height: 120, radius: 14),
              SizedBox(height: 10),
              SkeletonBox(height: 120, radius: 14),
            ],
          ),
        ),
      ),
      error: (_, _) => Center(child: Text(l10n.homeMatchesLoadError)),
      data: (matches) {
        final picked = pickLiveSuggestions(
          matches,
          currentMatchId: currentMatchId,
        );
        if (picked.isEmpty) {
          return Center(child: Text(l10n.liveSuggestionsEmpty));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: picked.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) =>
              _SuggestionCard(match: picked[i], onTap: () => onOpen(picked[i])),
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.match, required this.onTap});

  final MatchModel match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final names =
        '${matchSideLabel(match, 1)} ${l10n.matchVsLabel} ${matchSideLabel(match, 2)}';

    return InkWell(
      key: ValueKey('live-suggestion-${match.id}'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.55),
              scheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (match.isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  l10n.matchLiveStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              names,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            if (match.isLive)
              Text(
                '${match.score1} - ${match.score2}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
