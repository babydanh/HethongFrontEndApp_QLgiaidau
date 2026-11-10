import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart'
    show tournamentSheetServerMessage;
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/stage_operations_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Organizer-only action row of the bracket tab, like the Web one: an icon to
/// manage the divisions, then "Tạo bracket" while the division has none, or
/// "Xoá bracket" (confirmed) once it has one. Both buttons lock while a request
/// is in flight and reload the bracket data afterwards.
class BracketManagementBar extends ConsumerStatefulWidget {
  const BracketManagementBar({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    required this.hasBracket,
    required this.matchCount,
    required this.participantCount,
    required this.seedingType,
    this.onManageDivisions,
  });

  final String tournamentId;
  final String divisionId;
  final bool hasBracket;

  /// Matches of the division bracket; shown in the delete confirmation.
  final int matchCount;

  /// Registered players or teams; fewer than 2 disables creation (as on Web).
  final int participantCount;

  /// `SEEDED` or `RANDOM`, sent with `POST /tournaments/:id/generate-bracket`.
  final String seedingType;

  /// Opens the divisions screen; null hides the manage icon.
  final VoidCallback? onManageDivisions;

  @override
  ConsumerState<BracketManagementBar> createState() =>
      _BracketManagementBarState();
}

/// Compact (mini) look shared by Create and Delete bracket.
const _miniIconSize = 16.0;
const _miniMinSize = Size(0, 32);
const _miniPadding = EdgeInsets.symmetric(horizontal: 12);
const _miniText = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

class _BracketManagementBarState extends ConsumerState<BracketManagementBar> {
  /// True while a request is in flight: both buttons are locked (double tap).
  bool _busy = false;

  void _refresh() {
    ref.invalidate(tournamentProvider(widget.tournamentId));
    ref.invalidate(bracketMatchesProvider(widget.tournamentId));
    ref.invalidate(matchesProvider(widget.tournamentId));
    ref.invalidate(
      bracketMatchesWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
      )),
    );
  }

  String _errorText(Object error, AppLocalizations l10n) {
    if (error is DioException) {
      if (error.response == null) return l10n.stageActionNetworkError;
      final status = error.response?.statusCode;
      // Deleting a bracket whose matches already started is refused with 400.
      if (status == 400 && widget.hasBracket) {
        return l10n.stageActionCancelStarted;
      }
      final server = tournamentSheetServerMessage(error);
      if (server != null) return server;
      if (status == 409) return l10n.stageActionConflict;
    }
    return l10n.stageActionGenericError;
  }

  /// Runs [action] with the buttons locked; success or failure is a snackbar
  /// and the bracket data reloads either way, so the screen never goes stale.
  Future<void> _run(
    Future<String> Function(AppLocalizations l10n) action,
  ) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final message = await action(l10n);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(_errorText(error, l10n))));
    } finally {
      if (mounted) {
        _refresh();
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _create() => _run((l10n) async {
    await ref
        .read(tournamentRepositoryProvider)
        .generateBracket(
          widget.tournamentId,
          divisionId: widget.divisionId,
          seedingType: widget.seedingType,
        );
    return l10n.bracketMgmt_createDone;
  });

  Future<void> _confirmDelete() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bracketMgmt_deleteConfirmTitle),
        content: Text(l10n.bracketMgmt_deleteConfirmBody(widget.matchCount)),
        actions: [
          TextButton(
            key: const Key('bracket-mgmt-delete-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.bracketMgmt_cancel),
          ),
          FilledButton(
            key: const Key('bracket-mgmt-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.bracketMgmt_deleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run((l10n) async {
      final result = await ref
          .read(stageOperationsRepositoryProvider)
          .cancelDivisionBracket(widget.tournamentId, widget.divisionId);
      return l10n.bracketMgmt_deleteDone(
        result.cancelledStages,
        result.cancelledMatches,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tooLittle = !widget.hasBracket && widget.participantCount < 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (widget.onManageDivisions != null)
            IconButton(
              key: const Key('bracket-mgmt-manage'),
              tooltip: l10n.bracketMgmt_manageTooltip,
              onPressed: widget.onManageDivisions,
              icon: const Icon(Icons.settings_outlined),
            ),
          const Spacer(),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (widget.hasBracket)
            OutlinedButton.icon(
              key: const Key('bracket-mgmt-delete'),
              onPressed: _busy ? null : _confirmDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                minimumSize: _miniMinSize,
                padding: _miniPadding,
                textStyle: _miniText,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: _miniIconSize,
              ),
              label: Text(l10n.bracketMgmt_delete),
            )
          else
            Tooltip(
              message: tooLittle ? l10n.bracketMgmt_minParticipants : '',
              child: FilledButton.icon(
                key: const Key('bracket-mgmt-create'),
                onPressed: _busy || tooLittle ? null : _create,
                style: FilledButton.styleFrom(
                  minimumSize: _miniMinSize,
                  padding: _miniPadding,
                  textStyle: _miniText,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(
                  Icons.account_tree_outlined,
                  size: _miniIconSize,
                ),
                label: Text(l10n.bracketMgmt_create),
              ),
            ),
        ],
      ),
    );
  }
}
