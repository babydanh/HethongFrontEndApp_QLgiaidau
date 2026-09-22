import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Lets an authorized tournament operator choose between the public live view
/// and the referee scoring desk. Viewers never see this dialog.
class MatchScoreEntryChooser extends StatelessWidget {
  final MatchModel match;
  final String tournamentId;

  const MatchScoreEntryChooser({
    super.key,
    required this.match,
    required this.tournamentId,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchModel match,
    required String tournamentId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => MatchScoreEntryChooser(
        match: match,
        tournamentId: tournamentId,
      ),
    );
  }

  String _route({required bool scoring}) {
    final base = NavigationHelper.getLiveMatchRoute(tournamentId, match.id);
    final uri = Uri.parse(base);
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            if (scoring) 'viewer': 'false',
          },
        )
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final team1 = match.team1Name.trim().isEmpty ? l10n.liveUnknownValue : match.team1Name;
    final team2 = match.team2Name.trim().isEmpty ? l10n.liveUnknownValue : match.team2Name;

    return AlertDialog(
      backgroundColor: colors.bgCard,
      title: Row(
        children: [
          Icon(Icons.sports_score_rounded, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.matchScoreEntryChooserTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.matchScoreEntryChooserDescription, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(child: Text(team1, maxLines: 2, overflow: TextOverflow.ellipsis)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('VS', style: TextStyle(fontWeight: FontWeight.w800, color: colors.textMuted)),
                ),
                Expanded(child: Text(team2, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.matchScoreEntryChooserCancel),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push(_route(scoring: false));
          },
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: Text(l10n.matchScoreEntryChooserLive),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push(_route(scoring: true));
          },
          icon: const Icon(Icons.scoreboard_rounded, size: 18),
          label: Text(l10n.matchScoreEntryChooserEnter),
        ),
      ],
    );
  }
}
