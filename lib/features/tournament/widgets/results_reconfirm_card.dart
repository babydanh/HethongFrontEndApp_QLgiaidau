import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Confirm results again" banner (Web `bracketConfirmResults`): shown only
/// when the tournament is COMPLETED and the Backend flags `needsReconfirm` on
/// `GET /tournaments/:id/results`, i.e. the bracket was edited after the end.
/// The action posts `/tournaments/:id/results/confirm` once.
class ResultsReconfirmCard extends ConsumerStatefulWidget {
  const ResultsReconfirmCard({
    super.key,
    required this.tournamentId,
    required this.status,
  });

  final String tournamentId;
  final String status;

  @override
  ConsumerState<ResultsReconfirmCard> createState() =>
      _ResultsReconfirmCardState();
}

class _ResultsReconfirmCardState extends ConsumerState<ResultsReconfirmCard> {
  bool _busy = false;

  ({String tournamentId, String? divisionId}) get _resultsKey =>
      (tournamentId: widget.tournamentId, divisionId: null);

  Future<void> _confirm() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.lifecycleResultsReconfirmDialogTitle,
      message: l10n.lifecycleResultsReconfirmDialogMessage,
      confirmLabel: l10n.lifecycleResultsReconfirmAction,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    String message = l10n.lifecycleResultsReconfirmed;
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .confirmTournamentResults(widget.tournamentId);
      ref.invalidate(tournamentResultProvider(_resultsKey));
    } on Object {
      message = l10n.tournamentManagementActionError;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status.toUpperCase() != 'COMPLETED') {
      return const SizedBox.shrink();
    }
    final results = ref.watch(tournamentResultProvider(_resultsKey)).asData;
    if (results?.value['needsReconfirm'] != true) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lifecycleResultsReconfirmNeeded,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('results-reconfirm-action'),
            onPressed: _busy ? null : _confirm,
            child: Text(l10n.lifecycleResultsReconfirmAction),
          ),
        ],
      ),
    );
  }
}
