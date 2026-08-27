import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/single_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/double_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Full-screen bracket diagram for all 3 format types.
/// Navigated to from the "Xem sơ đồ" button in BracketViewScreen.
/// Always fetches bracket data fresh from the repository to ensure
/// nextMatchId connectivity is correct (merged flat data may break links).
class BracketDiagramScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? divisionId;
  final String bracketType;
  final List<MatchModel>? initialMatches;
  final bool isReferee;
  final bool isReadOnly;
  final bool canEditBracket;
  final bool isLite;

  const BracketDiagramScreen({
    super.key,
    required this.tournamentId,
    this.divisionId,
    required this.bracketType,
    this.initialMatches,
    this.isReferee = false,
    this.isReadOnly = true,
    this.canEditBracket = false,
    this.isLite = false,
  });

  @override
  ConsumerState<BracketDiagramScreen> createState() =>
      _BracketDiagramScreenState();
}

class _BracketDiagramScreenState extends ConsumerState<BracketDiagramScreen> {
  List<MatchModel>? _bracketMatches;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bracketMatches = widget.initialMatches;
    _loading = widget.initialMatches == null || widget.initialMatches!.isEmpty;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _fetchBracket();
  }

  Future<void> _fetchBracket() async {
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final matches = await repo.getBracketMatches(
        widget.tournamentId,
        divisionId: widget.divisionId,
      );
      if (mounted) {
        setState(() {
          _bracketMatches = matches;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // If we already have initialMatches, do not show error screen
          if (_bracketMatches == null || _bracketMatches!.isEmpty) {
            _error = e.toString();
          }
          _loading = false;
        });
      }
    }
  }

  void _handleDoubleTapMatch(MatchModel match) {
    if (!widget.canEditBracket) return;
    final queryParameters = <String, String>{
      'focusMatchId': match.id,
      if (widget.divisionId != null && widget.divisionId!.isNotEmpty)
        'divisionId': widget.divisionId!,
    };
    final opsPath = Uri(
      path: '/organizer/tournaments/${widget.tournamentId}/ops',
      queryParameters: queryParameters,
    ).toString();
    context.go(opsPath);
  }

  Future<void> _updateBracketSlots(
    BracketSlotDragData source,
    BracketSlotDragData target,
  ) async {
    if (source.matchId == target.matchId && source.slot == target.slot) return;
    if (!source.hasParticipant || target.isBye) return;
    final repo = ref.read(tournamentRepositoryProvider);
    final operation = target.hasParticipant ? 'SWAP' : 'MOVE';
    await repo.updateBracketSlots(
      widget.tournamentId,
      divisionId: widget.divisionId,
      operations: [
        {
          'operation': operation,
          'fromMatchId': source.matchId,
          'fromSlot': source.slot,
          'toMatchId': target.matchId,
          'toSlot': target.slot,
        },
      ],
      isLite: widget.isLite,
    );
    await _fetchBracket();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final bracketType = widget.bracketType.trim().toLowerCase();
    final isRoundRobin = bracketType == AppConstants.bracketRoundRobin;
    final isDouble = bracketType == AppConstants.bracketDoubleElimination;
    final isGroupStageKnockout =
        bracketType == AppConstants.bracketGroupStageKnockout;

    final String title;
    if (isRoundRobin) {
      title = l10n.bracketDiagramRoundRobinTitle;
    } else if (isDouble) {
      title = l10n.bracketDiagramDoubleEliminationTitle;
    } else if (isGroupStageKnockout) {
      title = l10n.bracketDiagramGroupStageTitle;
    } else {
      title = l10n.bracketDiagramDefaultTitle;
    }

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: l10n.bracketDiagramBack,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pinch_rounded, size: 12, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    l10n.bracketDiagramZoomHint,
                    style: TextStyle(fontSize: 9, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildEmpty(colors, l10n)
          : (_bracketMatches == null || _bracketMatches!.isEmpty)
          ? _buildEmpty(colors, l10n)
          : _buildDiagram(colors, isRoundRobin, isDouble, isGroupStageKnockout),
    );
  }

  Widget _buildDiagram(
    AppColorsExtension colors,
    bool isRoundRobin,
    bool isDouble,
    bool isGroupStageKnockout,
  ) {
    final matches = _bracketMatches!;

    if (isRoundRobin) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: CrossTableView(
          matches: matches,
          tournamentId: widget.tournamentId,
          divisionId: widget.divisionId,
          onDoubleTapMatch: widget.canEditBracket
              ? _handleDoubleTapMatch
              : null,
        ),
      );
    }

    if (isDouble) {
      return DoubleElimDiagram(
        matches: matches,
        tournamentId: widget.tournamentId,
        isReferee: widget.isReferee,
        isReadOnly: widget.isReadOnly,
        isEditable: widget.canEditBracket,
        onSlotDrop: _updateBracketSlots,
        onDoubleTapMatch: widget.canEditBracket ? _handleDoubleTapMatch : null,
      );
    }

    // For group_stage_knockout: filter only knockout stage matches.
    // The knockout stage may itself be a double-elimination bracket (the
    // /bracket API reports stage.type = DOUBLE_ELIMINATION), so pick the
    // diagram type from the actual match data, not the top-level bracketType.
    if (isGroupStageKnockout) {
      final knockoutMatches = matches.where(isKnockoutMatch).toList();
      final isDouble = knockoutMatches.any(isDoubleEliminationMatch);
      if (isDouble) {
        return DoubleElimDiagram(
          matches: knockoutMatches,
          tournamentId: widget.tournamentId,
          isReferee: widget.isReferee,
          isReadOnly: widget.isReadOnly,
          isEditable: widget.canEditBracket,
          onSlotDrop: _updateBracketSlots,
          onDoubleTapMatch: widget.canEditBracket
              ? _handleDoubleTapMatch
              : null,
        );
      }
      return SingleElimDiagram(
        matches: knockoutMatches,
        tournamentId: widget.tournamentId,
        isReferee: widget.isReferee,
        isReadOnly: widget.isReadOnly,
        isEditable: widget.canEditBracket,
        onSlotDrop: _updateBracketSlots,
        onDoubleTapMatch: widget.canEditBracket ? _handleDoubleTapMatch : null,
      );
    }

    // Default: single elimination — use all matches
    return SingleElimDiagram(
      matches: matches,
      tournamentId: widget.tournamentId,
      isReferee: widget.isReferee,
      isReadOnly: widget.isReadOnly,
      isEditable: widget.canEditBracket,
      onSlotDrop: _updateBracketSlots,
      onDoubleTapMatch: widget.canEditBracket ? _handleDoubleTapMatch : null,
    );
  }

  Widget _buildEmpty(AppColorsExtension colors, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 72,
            color: colors.textMuted.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.bracketDiagramEmptyTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bracketDiagramEmptyHint,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
