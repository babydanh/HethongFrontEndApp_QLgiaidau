import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_double_elim_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/public_bracket_view.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_slot_editing_scope.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

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
  final bool canScoreMatch;
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
    this.canScoreMatch = false,
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

  void _invalidateMatchProviders() {
    ref.invalidate(bracketMatchesProvider(widget.tournamentId));
    ref.invalidate(liteBracketMatchesProvider(widget.tournamentId));
    ref.invalidate(matchesProvider(widget.tournamentId));
    ref.invalidate(liveMatchesProvider(widget.tournamentId));
    final params = (
      tournamentId: widget.tournamentId,
      divisionId: widget.divisionId,
    );
    ref.invalidate(bracketMatchesWithDivisionProvider(params));
    ref.invalidate(liteBracketMatchesWithDivisionProvider(params));
    ref.invalidate(matchesWithDivisionProvider(params));
    ref.invalidate(managedMatchesWithDivisionProvider(params));
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
    final isSwiss = bracketType == AppConstants.bracketSwiss;

    final String title;
    if (isSwiss) {
      title = l10n.swissFormatName;
    } else if (isRoundRobin) {
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
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
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
      ),
      body: _loading
          ? const BoneBracketLoading()
          : _error != null
          ? _buildEmpty(colors, l10n)
          : (_bracketMatches == null || _bracketMatches!.isEmpty)
          ? _buildEmpty(colors, l10n)
          : isSwiss
          ? SingleChildScrollView(
              child: SwissBracketView(
                tournamentId: widget.tournamentId,
                divisionId: widget.divisionId,
                matches: _bracketMatches!,
              ),
            )
          : _buildDiagram(colors, isRoundRobin, isGroupStageKnockout),
    );
  }

  Widget _buildDiagram(
    AppColorsExtension colors,
    bool isRoundRobin,
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

    // For group_stage_knockout: filter only knockout stage matches.
    // The knockout stage may itself be a double-elimination bracket (the
    // /bracket API reports stage.type = DOUBLE_ELIMINATION), so pick the
    // diagram type from the actual match data, not the top-level bracketType.
    final diagramMatches = isGroupStageKnockout
        ? matches.where(isKnockoutMatch).toList()
        : matches;

    return BracketSlotEditingScope(
      enabled: widget.canEditBracket,
      tournamentId: widget.tournamentId,
      divisionId: widget.divisionId,
      isLite: () => widget.isLite,
      onApplied: () {
        _invalidateMatchProviders();
        _fetchBracket();
      },
      builder: (context, tray, onSlotDrop) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tray != null)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: tray),
              PlayoffDoubleElimView(
                matches: diagramMatches,
                tournamentId: widget.tournamentId,
                canScoreMatch: widget.canScoreMatch,
                onSlotDrop: onSlotDrop,
              ),
            ],
          ),
        );
      },
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
