import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_diagram_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/group_stage_config.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/swiss_round_state.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_table_row.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/swiss_standings_view.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_stage_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_double_elim_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_editing_host.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_seed_labels.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

enum _Kind { single, double, roundRobin, swiss }

/// Sơ đồ bracket cho trang công khai: CHỈ sơ đồ, không banner/ô tìm/bộ lọc/thẻ
/// vòng. Chọn đúng loại sơ đồ như `BracketViewScreen`:
/// - loại trực tiếp / nhánh thắng-thua -> [PlayoffDoubleElimView]
/// - vòng tròn       -> [GroupStageView]
/// - vòng bảng + knockout -> chỉ phần knockout.
///
/// Sơ đồ mỗi trang hiện 2 vòng, đổi trang bằng Trước/Sau, không zoom, không
/// kéo chéo. Chiều cao theo nội dung; cuộn dọc thuộc trang cha.
class PublicBracketView extends StatelessWidget {
  const PublicBracketView({
    super.key,
    required this.tournamentId,
    required this.matches,
    this.divisionId,
    this.bracketType,
    this.canScoreMatch = false,
    this.editableConfig,
    this.onConfigChanged,
    this.editLocked = false,
    this.canEditSeeds = false,
    this.canEditBracket = false,
  });

  final String tournamentId;
  final String? divisionId;
  final List<MatchModel> matches;
  final String? bracketType;

  /// Organizer may edit the bracket in the full-screen diagram.
  final bool canEditBracket;

  /// Viewer may enter scores (admin / organizer): a tapped match opens the
  /// score-entry popup instead of the read-only detail.
  final bool canScoreMatch;

  /// Group edit mode, forwarded to [GroupStageView] (null = read-only).
  final GroupStageConfig? editableConfig;
  final Future<void> Function(GroupStageConfig next)? onConfigChanged;
  final bool editLocked;
  final bool canEditSeeds;

  _Kind _kindOf(List<MatchModel> all) {
    final raw = (bracketType ?? '').trim().toLowerCase();
    if (raw == 'swiss' || all.any(isSwissMatch)) return _Kind.swiss;
    if (all.any(isDoubleEliminationMatch) ||
        raw == 'double_elimination' ||
        raw == 'doubleelimination') {
      return _Kind.double;
    }
    final hasGroup = all.any(isGroupStageMatch);
    final hasKnockout = all.any(isKnockoutMatch);
    if (raw == 'round_robin' || raw == 'roundrobin') return _Kind.roundRobin;
    if (raw == 'group_stage_knockout' || raw == 'groupstageknockout') {
      return _Kind.single;
    }
    if (hasGroup && hasKnockout) return _Kind.single;
    if (hasGroup) return _Kind.roundRobin;
    return _Kind.single;
  }

  bool _isGroupStageKnockout(List<MatchModel> all) {
    final raw = (bracketType ?? '').trim().toLowerCase();
    if (raw == AppConstants.bracketGroupStageKnockout ||
        raw == 'groupstageknockout') {
      return true;
    }
    if (raw == AppConstants.bracketRoundRobin ||
        raw == 'roundrobin' ||
        raw == 'double_elimination' ||
        raw == 'doubleelimination' ||
        all.any(isDoubleEliminationMatch)) {
      return false;
    }
    return all.any(isGroupStageMatch) && all.any(isKnockoutMatch);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isGroupPlayoff = _isGroupStageKnockout(matches);
    if (matches.isEmpty && !isGroupPlayoff) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Text(
            l10n.bracketView_noMatches,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    final kind = _kindOf(matches);
    if (isGroupPlayoff) {
      return _GroupPlayoffTabs(
        tournamentId: tournamentId,
        divisionId: divisionId,
        bracketType: bracketType,
        canScoreMatch: canScoreMatch,
        editableConfig: editableConfig,
        onConfigChanged: onConfigChanged,
        editLocked: editLocked,
        canEditSeeds: canEditSeeds,
        canEditBracket: canEditBracket,
        matches: matches,
        knockoutMatches: matches.where(isKnockoutMatch).toList(growable: false),
      );
    }

    final hasGroupAndKnockout =
        matches.any(isGroupStageMatch) && matches.any(isKnockoutMatch);
    final knockoutOnly = hasGroupAndKnockout
        ? matches.where(isKnockoutMatch).toList(growable: false)
        : matches;

    return switch (kind) {
      _Kind.swiss => SwissBracketView(
        tournamentId: tournamentId,
        divisionId: divisionId,
        matches: matches,
      ),
      _Kind.roundRobin => GroupStageView(
        matches: matches,
        tournamentId: tournamentId,
        divisionId: divisionId,
        bracketType: bracketType,
        canScoreMatch: canScoreMatch,
        editableConfig: editableConfig,
        onConfigChanged: onConfigChanged,
        editLocked: editLocked,
      ),
      _Kind.double || _Kind.single => PlayoffEditingHost(
        enabled: canEditBracket,
        tournamentId: tournamentId,
        divisionId: divisionId,
        builder: (context, onSlotDrop) => PlayoffDoubleElimView(
          matches: knockoutOnly,
          tournamentId: tournamentId,
          canScoreMatch: canScoreMatch,
          onSlotDrop: onSlotDrop,
          onOpenFull: () => openFullBracket(
            context,
            tournamentId: tournamentId,
            divisionId: divisionId,
            bracketType: bracketType,
            matches: matches,
            canScoreMatch: canScoreMatch,
            canEditBracket: canEditBracket,
          ),
        ),
      ),
    };
  }
}

/// Swiss has no bracket diagram: a compact standings table (top 8) plus the
/// matches of the current round, read-only.
class SwissBracketView extends ConsumerWidget {
  const SwissBracketView({
    super.key,
    required this.tournamentId,
    this.divisionId,
    required this.matches,
  });

  static const int _standingsLimit = 8;

  final String tournamentId;
  final String? divisionId;
  final List<MatchModel> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final params = (tournamentId: tournamentId, divisionId: divisionId);
    final standings =
        ref.watch(standingsWithDivisionProvider(params)).value ?? const [];
    final stage = ref.watch(swissStageProvider(params)).value;
    final config = stage?.config;
    final totalRounds =
        stage?.totalRounds ??
        matches.fold<int>(1, (max, m) => m.round > max ? m.round : max);
    final current = swissRoundState(matches, totalRounds).currentRound;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwissStandingsView(
          standings: standings.take(_standingsLimit).toList(),
          tiebreakOrder:
              config?.tiebreakOrder ?? SwissConfig.defaultTiebreakOrder,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
          child: Text(
            l10n.swissRoundLabel(current),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        for (final match in matches.where((m) => m.round == current))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MatchTableRow(
              match: match,
              isReadOnly: true,
              totalRounds: totalRounds,
              tournamentId: tournamentId,
            ),
          ),
      ],
    );
  }
}

class _GroupPlayoffTabs extends StatefulWidget {
  const _GroupPlayoffTabs({
    required this.tournamentId,
    required this.divisionId,
    required this.bracketType,
    required this.matches,
    required this.knockoutMatches,
    required this.canScoreMatch,
    required this.editableConfig,
    required this.onConfigChanged,
    required this.editLocked,
    required this.canEditSeeds,
    required this.canEditBracket,
  });

  final String tournamentId;
  final String? divisionId;
  final String? bracketType;
  final bool canScoreMatch;
  final GroupStageConfig? editableConfig;
  final Future<void> Function(GroupStageConfig next)? onConfigChanged;
  final bool editLocked;
  final bool canEditSeeds;
  final bool canEditBracket;
  final List<MatchModel> matches;
  final List<MatchModel> knockoutMatches;

  @override
  State<_GroupPlayoffTabs> createState() => _GroupPlayoffTabsState();
}

class _GroupPlayoffTabsState extends State<_GroupPlayoffTabs> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    Widget tabButton(String label, int index) {
      final isSelected = _selectedTab == index;
      return Expanded(
        child: TextButton(
          onPressed: () => setState(() => _selectedTab = index),
          style: TextButton.styleFrom(
            backgroundColor: isSelected
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            foregroundColor: isSelected
                ? AppTheme.primary
                : colors.textSecondary,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              tabButton(l10n.publicBracketTabStandings, 0),
              const SizedBox(width: 4),
              tabButton(l10n.publicBracketTabPlayoff, 1),
            ],
          ),
        ),
        if (_selectedTab == 0)
          GroupStageView(
            matches: widget.matches,
            tournamentId: widget.tournamentId,
            divisionId: widget.divisionId,
            bracketType: widget.bracketType,
            canScoreMatch: widget.canScoreMatch,
            editableConfig: widget.editableConfig,
            onConfigChanged: widget.onConfigChanged,
            editLocked: widget.editLocked,
          )
        else if (widget.knockoutMatches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Center(
              child: Text(
                l10n.bracketView_noMatches,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          )
        else
          PlayoffEditingHost(
            enabled: widget.canEditBracket,
            tournamentId: widget.tournamentId,
            divisionId: widget.divisionId,
            builder: (context, onSlotDrop) => PlayoffSeedHost(
              tournamentId: widget.tournamentId,
              divisionId: widget.divisionId,
              matches: widget.knockoutMatches,
              canEdit: widget.canEditSeeds,
              builder: (context, seedLabels) => PlayoffDoubleElimView(
                matches: widget.knockoutMatches,
                tournamentId: widget.tournamentId,
                canScoreMatch: widget.canScoreMatch,
                seedLabels: seedLabels,
                onSlotDrop: onSlotDrop,
                onOpenFull: () => openFullBracket(
                  context,
                  tournamentId: widget.tournamentId,
                  divisionId: widget.divisionId,
                  bracketType: widget.bracketType,
                  matches: widget.matches,
                  canScoreMatch: widget.canScoreMatch,
                  canEditBracket: widget.canEditBracket,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Opens the full-screen diagram (zoom, drag, scoring when allowed). When the
/// viewer may score or edit, the bracket lists are refreshed on return.
Future<void> openFullBracket(
  BuildContext context, {
  required String tournamentId,
  required String? divisionId,
  required String? bracketType,
  required List<MatchModel> matches,
  required bool canScoreMatch,
  required bool canEditBracket,
}) async {
  final container = ProviderScope.containerOf(context);
  final type = (bracketType ?? '').trim().isNotEmpty
      ? bracketType!
      : matches.any(isDoubleEliminationMatch)
      ? AppConstants.bracketDoubleElimination
      : AppConstants.bracketSingleElimination;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BracketDiagramScreen(
        tournamentId: tournamentId,
        divisionId: divisionId,
        bracketType: type,
        initialMatches: matches,
        isReadOnly: !canScoreMatch && !canEditBracket,
        canEditBracket: canEditBracket,
        canScoreMatch: canScoreMatch,
      ),
    ),
  );
  if (!canScoreMatch && !canEditBracket) return;
  final params = (tournamentId: tournamentId, divisionId: divisionId);
  container
    ..invalidate(bracketMatchesWithDivisionProvider(params))
    ..invalidate(liteBracketMatchesWithDivisionProvider(params))
    ..invalidate(matchesWithDivisionProvider(params))
    ..invalidate(managedMatchesWithDivisionProvider(params));
}

/// Tải trận của một nội dung rồi vẽ [PublicBracketView]. Tách khỏi view để view
/// kiểm thử được mà không cần provider.
class PublicBracketLoader extends ConsumerWidget {
  const PublicBracketLoader({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    this.bracketType,
    this.canScoreMatch = false,
    this.editableConfig,
    this.onConfigChanged,
    this.editLocked = false,
    this.canEditSeeds = false,
    this.canEditBracket = false,
  });

  final String tournamentId;
  final String? divisionId;
  final String? bracketType;
  final bool canScoreMatch;
  final bool canEditBracket;
  final GroupStageConfig? editableConfig;
  final Future<void> Function(GroupStageConfig next)? onConfigChanged;
  final bool editLocked;
  final bool canEditSeeds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return ref
        .watch(
          bracketMatchesWithDivisionProvider((
            tournamentId: tournamentId,
            divisionId: divisionId,
          )),
        )
        .when(
          data: (matches) => PublicBracketView(
            tournamentId: tournamentId,
            divisionId: divisionId,
            matches: matches,
            bracketType: bracketType,
            canScoreMatch: canScoreMatch,
            editableConfig: editableConfig,
            onConfigChanged: onConfigChanged,
            editLocked: editLocked,
            canEditSeeds: canEditSeeds,
            canEditBracket: canEditBracket,
          ),
          loading: () => const BoneBracketLoading(),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                error.toString().contains('429')
                    ? l10n.bracketView_rateLimited
                    : l10n.bracketView_loadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ),
        );
  }
}
