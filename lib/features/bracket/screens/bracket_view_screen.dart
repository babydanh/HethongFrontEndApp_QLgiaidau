import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_diagram_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/single_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/double_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_table_row.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/standings_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/swiss_standings_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/filter_chips.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/swiss_round_state.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/swiss_pairing_screen.dart'
    show swissApiErrorText;
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_filter_bottom_sheet.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_filter_segment.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class BracketViewScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? divisionId;
  final String? bracketType;
  final int configuredLegs;
  final bool isReferee;
  final bool isReadOnly;
  final bool canEditBracket;
  final bool isLite;
  final bool isEmbedded;
  final ScrollController? scrollController;

  const BracketViewScreen({
    super.key,
    required this.tournamentId,
    this.divisionId,
    this.bracketType,
    this.configuredLegs = 1,
    this.isReferee = false,
    this.isReadOnly = false,
    this.canEditBracket = false,
    this.isLite = false,
    this.isEmbedded = false,
    this.scrollController,
  });

  @override
  ConsumerState<BracketViewScreen> createState() => _BracketViewScreenState();
}

class _BracketViewScreenState extends ConsumerState<BracketViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  int _selectedGroupTab = 0;
  String _searchQuery = '';
  int _selectedRound = 0;
  int _selectedLeg = 0;
  String _matchFilter = '';
  String _selectedBranch = '';
  String _selectedGroup = '';
  // Swiss: the schedule opens on the current round once, then follows the user.
  bool _swissRoundDefaulted = false;

  BracketFilterState get _currentFilterState => BracketFilterState(
    matchFilter: _matchFilter,
    selectedBranch: _selectedBranch,
    selectedGroup: _selectedGroup,
    selectedLeg: _selectedLeg,
    selectedRound: _selectedRound,
  );

  void _applyFilterState(BracketFilterState state) {
    setState(() {
      _matchFilter = state.matchFilter;
      _selectedBranch = state.selectedBranch;
      _selectedGroup = state.selectedGroup;
      _selectedLeg = state.selectedLeg;
      _selectedRound = state.selectedRound;
    });
  }

  void _openFilterBottomSheet({
    required BuildContext context,
    required bool isDoubleElimination,
    required bool isGroupStageKnockout,
    required bool isRoundRobin,
    required int liveCount,
    required int scheduledCount,
    required int completedCount,
    required List<String> availableGroups,
    required List<int> availableLegs,
    required List<int> availableRounds,
    required int effectiveTotalRounds,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BracketFilterBottomSheet(
        initialState: _currentFilterState,
        isDoubleElimination: isDoubleElimination,
        isGroupStageKnockout: isGroupStageKnockout,
        isRoundRobin: isRoundRobin,
        liveCount: liveCount,
        scheduledCount: scheduledCount,
        completedCount: completedCount,
        availableGroups: availableGroups,
        availableLegs: availableLegs,
        availableRounds: availableRounds,
        effectiveTotalRounds: effectiveTotalRounds,
        onApply: _applyFilterState,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (!widget.isEmbedded) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  String? _selectedDivisionId;

  List<TournamentDivision> get _divisions =>
      ref.read(tournamentProvider(widget.tournamentId)).value?.divisions ??
      const [];

  bool get _hasRequestedDivision {
    final requested = widget.divisionId;
    return requested != null && requested.isNotEmpty;
  }

  /// Giải đang xem: divisionId từ caller, rồi giải người dùng chọn, rồi giải đầu tiên.
  String? get _activeDivisionId {
    if (_hasRequestedDivision) return widget.divisionId;
    if (_selectedDivisionId != null) return _selectedDivisionId;
    final divisions = _divisions;
    return divisions.isEmpty ? null : divisions.first.id;
  }

  Widget _buildDivisionSelector(List<TournamentDivision> divisions) {
    final activeId = _activeDivisionId;
    final selectedName =
        divisions.where((d) => d.id == activeId).firstOrNull?.name ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: DivisionFilterSegment(
        divisions: divisions.map((d) => d.name).toList(),
        selectedDivision: selectedName,
        onDivisionChanged: (name) {
          final picked = divisions.where((d) => d.name == name).firstOrNull;
          if (picked == null) return;
          setState(() => _selectedDivisionId = picked.id);
        },
      ),
    );
  }

  void _handleDoubleTapMatch(MatchModel match) {
    if (!widget.canEditBracket) return;
    final divisionId = _activeDivisionId;
    final queryParameters = <String, String>{
      'focusMatchId': match.id,
      if (divisionId != null && divisionId.isNotEmpty) 'divisionId': divisionId,
    };
    context.push(
      Uri(
        path: '/organizer/tournaments/${widget.tournamentId}/ops',
        queryParameters: queryParameters,
      ).toString(),
    );
  }

  Future<void> _unassignBracketSlot(BracketSlotDragData slot) async {
    if (!widget.canEditBracket || !slot.hasParticipant) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.lite_unassignBracketTitle),
        content: Text(l10n.lite_unassignBracketContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.lite_keepPair),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.lite_unassignBracket),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final tournament = ref
          .read(tournamentProvider(widget.tournamentId))
          .value;
      final isLite = widget.isLite || tournament?.isLite == true;
      await ref
          .read(tournamentRepositoryProvider)
          .updateBracketSlots(
            widget.tournamentId,
            divisionId: _activeDivisionId,
            operations: [
              {
                'operation': 'UNASSIGN',
                'matchId': slot.matchId,
                'slot': slot.slot,
              },
            ],
            isLite: isLite,
          );
      ref.invalidate(bracketMatchesProvider(widget.tournamentId));
      final params = (
        tournamentId: widget.tournamentId,
        divisionId: _activeDivisionId,
      );
      ref.invalidate(bracketMatchesWithDivisionProvider(params));
      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.singleElimUpdateError(_formatBracketError(error))),
        ),
      );
    }
  }

  String _formatBracketError(Object error) {
    if (error is DioException) {
      final payload = error.response?.data;
      if (payload is Map) {
        final message = payload['message'];
        if (message is List) return message.join(', ');
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      if (error.message?.trim().isNotEmpty == true) return error.message!;
    }
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('DioException: ', '');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();

    if (!widget.isEmbedded) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final tournament = tournamentAsync.value;
    final auth = ref.watch(authProvider);

    final waitingForDivisions =
        !_hasRequestedDivision &&
        tournament == null &&
        tournamentAsync.isLoading;
    final matchContent = waitingForDivisions
        ? const _BracketShimmerLoading()
        : ref
              .watch(
                bracketMatchesWithDivisionProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: _activeDivisionId,
                )),
              )
              .when(
                data: (matches) {
                  final divisionBracketType = tournament?.divisions
                      .where((division) => division.id == _activeDivisionId)
                      .firstOrNull
                      ?.bracketType;
                  final rawType =
                      (widget.bracketType ??
                              divisionBracketType ??
                              tournament?.bracketType ??
                              '')
                          .trim()
                          .toLowerCase();
                  final canManageGroupAssignment =
                      widget.canEditBracket || auth.role == UserRole.admin;
                  final hasConfiguredGroupStage =
                      rawType == 'round_robin' ||
                      rawType == 'roundrobin' ||
                      rawType == 'group_stage_knockout' ||
                      rawType == 'groupstageknockout';
                  if (matches.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 60,
                        horizontal: 16,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_tree_outlined,
                              size: 64,
                              color: context.colors.textMuted.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.bracketView_noMatches,
                              style: TextStyle(
                                fontSize: 16,
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.bracketView_drawHint,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colors.textMuted,
                              ),
                            ),
                            if (canManageGroupAssignment &&
                                hasConfiguredGroupStage &&
                                _activeDivisionId != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _buildManageGroupStageButton(l10n),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  final hasDoubleElimMatches = matches.any(
                    isDoubleEliminationMatch,
                  );
                  final hasGroupMatches = matches.any(isGroupStageMatch);
                  final hasKnockoutMatches = matches.any(isKnockoutMatch);

                  final String effectiveBracketType;
                  if (rawType == AppConstants.bracketSwiss ||
                      matches.any(isSwissMatch)) {
                    effectiveBracketType = AppConstants.bracketSwiss;
                  } else if (hasDoubleElimMatches ||
                      rawType == 'double_elimination' ||
                      rawType == 'doubleelimination') {
                    effectiveBracketType =
                        AppConstants.bracketDoubleElimination;
                  } else if (rawType == 'single_elimination' ||
                      rawType == 'singleelimination' ||
                      rawType == 'knockout') {
                    effectiveBracketType =
                        AppConstants.bracketSingleElimination;
                  } else if (rawType == 'round_robin' ||
                      rawType == 'roundrobin') {
                    effectiveBracketType = AppConstants.bracketRoundRobin;
                  } else if (rawType == 'group_stage_knockout' ||
                      rawType == 'groupstageknockout') {
                    effectiveBracketType =
                        AppConstants.bracketGroupStageKnockout;
                  } else if (hasGroupMatches && hasKnockoutMatches) {
                    effectiveBracketType =
                        AppConstants.bracketGroupStageKnockout;
                  } else if (hasGroupMatches) {
                    effectiveBracketType = AppConstants.bracketRoundRobin;
                  } else {
                    effectiveBracketType =
                        AppConstants.bracketSingleElimination;
                  }

                  final isRoundRobin =
                      effectiveBracketType == AppConstants.bracketRoundRobin;
                  final isGroupStageKnockout =
                      effectiveBracketType ==
                      AppConstants.bracketGroupStageKnockout;
                  final hasGroupStage =
                      isRoundRobin || (isGroupStageKnockout && hasGroupMatches);

                  final effectiveIsLite =
                      widget.isLite || tournament?.isLite == true;
                  final canActAsReferee =
                      effectiveIsLite ||
                      auth.role == UserRole.admin ||
                      widget.isReferee;
                  final canScoreMatch =
                      auth.role == UserRole.admin ||
                      widget.canEditBracket ||
                      widget.isReferee;
                  final isReadOnlyMode =
                      !effectiveIsLite && auth.role == UserRole.viewer;

                  if (effectiveBracketType == AppConstants.bracketSwiss) {
                    return _buildSwissContent(
                      matches,
                      isReadOnlyMode,
                      canActAsReferee,
                      canScoreMatch,
                      canManageGroupAssignment,
                    );
                  }

                  if (hasGroupStage) {
                    return Column(
                      mainAxisSize: widget.isEmbedded
                          ? MainAxisSize.min
                          : MainAxisSize.max,
                      children: [
                        _buildGroupStageTabBar(l10n),
                        const SizedBox(height: 8),
                        if (canManageGroupAssignment &&
                            _activeDivisionId != null)
                          _buildManageGroupStageButton(l10n),
                        if (widget.isEmbedded)
                          _buildGroupTabContent(
                            matches,
                            effectiveBracketType,
                            auth,
                            canActAsReferee: canActAsReferee,
                            canScoreMatch: canScoreMatch,
                            isReadOnly: isReadOnlyMode,
                          )
                        else
                          Expanded(
                            child: _buildGroupTabContent(
                              matches,
                              effectiveBracketType,
                              auth,
                              canActAsReferee: canActAsReferee,
                              canScoreMatch: canScoreMatch,
                              isReadOnly: isReadOnlyMode,
                            ),
                          ),
                      ],
                    );
                  } else {
                    return _buildKnockoutMatchTable(
                      matches,
                      effectiveBracketType,
                      isReadOnlyMode,
                      canActAsReferee,
                      canScoreMatch,
                    );
                  }
                },
                loading: () => const _BracketShimmerLoading(),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      e.toString().contains('429')
                          ? l10n.bracketView_rateLimited
                          : l10n.bracketView_loadError,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  ),
                ),
              );
    final divisions = _divisions;
    final bodyContent = !_hasRequestedDivision && divisions.length > 1
        ? Column(
            mainAxisSize: widget.isEmbedded
                ? MainAxisSize.min
                : MainAxisSize.max,
            children: [
              _buildDivisionSelector(divisions),
              if (widget.isEmbedded)
                matchContent
              else
                Expanded(child: matchContent),
            ],
          )
        : matchContent;

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (auth.role == UserRole.admin) {
              context.go('/admin/tournament/${widget.tournamentId}');
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          tournament?.name != null && tournament!.name.isNotEmpty
              ? tournament.name
              : 'Bảng thi đấu',
        ),
        actions: auth.role != UserRole.admin
            ? [
                IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: context.colors.textSecondary,
                  ),
                  onPressed: () {
                    ref.read(authProvider.notifier).signOut();
                    context.go('/home');
                  },
                ),
              ]
            : null,
      ),
      body: bodyContent,
    );
  }

  Widget _buildGroupStageTabBar(AppLocalizations l10n, {bool swiss = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: swiss
            ? [
                _buildGroupTabItem(0, l10n.bracketView_standings),
                _buildGroupTabItem(1, l10n.bracketView_schedule),
              ]
            : [
                _buildGroupTabItem(0, l10n.bracketView_crossTable),
                _buildGroupTabItem(1, l10n.bracketView_standings),
                _buildGroupTabItem(2, l10n.bracketView_schedule),
              ],
      ),
    );
  }

  Widget _buildManageGroupStageButton(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextButton.icon(
          key: const Key('group-stage-assignment-entry'),
          onPressed: _openGroupStageAssignment,
          icon: const Icon(Icons.groups_2_outlined),
          label: Text(l10n.groupAssignmentManage),
        ),
      ),
    );
  }

  void _openGroupStageAssignment() {
    final divisionId = _activeDivisionId;
    if (divisionId == null || divisionId.isEmpty) return;

    final routeBase = ref.read(authProvider).role == UserRole.admin
        ? '/admin/tournament/${widget.tournamentId}'
        : '/organizer/tournaments/${widget.tournamentId}/manage';
    context.push(
      '$routeBase/group-stage-assignment/${Uri.encodeComponent(divisionId)}',
    );
  }

  void _openSwissPairing(String stageId, int round, int totalRounds) {
    final divisionId = _activeDivisionId;
    if (divisionId == null || divisionId.isEmpty) return;

    final routeBase = ref.read(authProvider).role == UserRole.admin
        ? '/admin/tournament/${widget.tournamentId}'
        : '/organizer/tournaments/${widget.tournamentId}/manage';
    context.push(
      Uri(
        path: '$routeBase/swiss-pairing/${Uri.encodeComponent(divisionId)}',
        queryParameters: {
          'stageId': stageId,
          'round': '$round',
          'total': '$totalRounds',
        },
      ).toString(),
    );
  }

  Widget _buildGroupTabItem(int index, String title) {
    final isSelected = _selectedGroupTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedGroupTab != index) {
            setState(() => _selectedGroupTab = index);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : context.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Swiss: two tabs only (standings, schedule), never the cross table.
  Widget _buildSwissContent(
    List<MatchModel> matches,
    bool isReadOnly,
    bool isReferee,
    bool canScoreMatch,
    bool canManage,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final params = (
      tournamentId: widget.tournamentId,
      divisionId: _activeDivisionId,
    );
    final stage = ref.watch(swissStageProvider(params)).value;
    final totalRounds = _computeTotalRounds(matches, AppConstants.bracketSwiss);
    if (!_swissRoundDefaulted) {
      _swissRoundDefaulted = true;
      _selectedRound = swissRoundState(matches, totalRounds).currentRound;
    }
    // Tab 0 = standings, anything else = schedule (the tab state is shared).
    final showStandings = _selectedGroupTab == 0;
    final body = showStandings
        ? _buildSwissStandings(params, l10n)
        : _buildKnockoutMatchTable(
            matches,
            AppConstants.bracketSwiss,
            isReadOnly,
            isReferee,
            canScoreMatch,
          );
    return Column(
      mainAxisSize: widget.isEmbedded ? MainAxisSize.min : MainAxisSize.max,
      children: [
        _buildGroupStageTabBar(l10n, swiss: true),
        // Without a configured total the round count is a guess: no actions.
        if (canManage &&
            stage != null &&
            stage.totalRounds != null &&
            _activeDivisionId != null)
          SwissRoundActions(
            tournamentId: widget.tournamentId,
            divisionId: _activeDivisionId!,
            stageId: stage.stageId,
            matches: matches,
            totalRounds: stage.totalRounds!,
            onOpenPairing: _openSwissPairing,
          ),
        if (widget.isEmbedded) body else Expanded(child: body),
      ],
    );
  }

  Widget _buildSwissStandings(
    ({String tournamentId, String? divisionId}) params,
    AppLocalizations l10n,
  ) {
    final standings = ref.watch(standingsWithDivisionProvider(params));
    final tiebreakOrder =
        ref.watch(swissStageProvider(params)).value?.config.tiebreakOrder ??
        SwissConfig.defaultTiebreakOrder;
    final Widget content = standings.when(
      data: (rows) =>
          SwissStandingsView(standings: rows, tiebreakOrder: tiebreakOrder),
      loading: () => const _BracketShimmerLoading(),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.bracketView_loadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
      ),
    );
    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(standingsWithDivisionProvider(params)),
      child: ListView(
        controller: widget.isEmbedded ? null : widget.scrollController,
        shrinkWrap: widget.isEmbedded,
        physics: widget.isEmbedded
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 160),
        children: [content],
      ),
    );
  }

  Widget _buildGroupTabContent(
    List<MatchModel> matches,
    String bracketType,
    AuthState auth, {
    bool canActAsReferee = false,
    bool canScoreMatch = false,
    bool isReadOnly = true,
  }) {
    switch (_selectedGroupTab) {
      case 0:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: CrossTableView(
            matches: matches,
            tournamentId: widget.tournamentId,
            divisionId: _activeDivisionId,
            configuredLegs: widget.configuredLegs,
            onDoubleTapMatch: widget.canEditBracket
                ? _handleDoubleTapMatch
                : null,
          ),
        );
      case 1:
        return StandingsView(
          matches: matches,
          tournamentId: widget.tournamentId,
          divisionId: _activeDivisionId,
        );
      case 2:
        return _buildKnockoutMatchTable(
          matches,
          bracketType,
          isReadOnly,
          canActAsReferee,
          canScoreMatch,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildKnockoutMatchTable(
    List<MatchModel> matches,
    String bracketType,
    bool isReadOnly,
    bool isReferee,
    bool canScoreMatch,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final tournament = ref.read(tournamentProvider(widget.tournamentId)).value;
    final totalRounds = _computeTotalRounds(matches, bracketType);

    final isDoubleElimination =
        bracketType == AppConstants.bracketDoubleElimination;
    final isGroupStageKnockout =
        bracketType == AppConstants.bracketGroupStageKnockout;
    final isRoundRobin = bracketType == AppConstants.bracketRoundRobin;
    final isSwiss = bracketType == AppConstants.bracketSwiss;

    // Filter valid matches
    // Keep TBD/TBD knockout slots visible. The web shows these scheduled
    // placeholders so users can see every configured round before seeding.
    // Swiss keeps BYE rows: they show who sits out and score a win.
    final validMatches = matches.where((m) => isSwiss || !m.isBye).toList();

    // Status counts (BYE rows are never counted)
    final countable = validMatches.where((m) => !m.isBye);
    final liveCount = countable.where((m) => m.isLive).length;
    final scheduledCount = countable.where((m) => m.isScheduled).length;
    final completedCount = countable.where((m) => m.isCompleted).length;

    final stageScopedMatches = validMatches.where((m) {
      if (isGroupStageKnockout) {
        if (_selectedBranch == 'group_stage') return isGroupStageMatch(m);
        if (_selectedBranch == 'knockout') return isKnockoutMatch(m);
      }
      if (isDoubleElimination) {
        if (_selectedBranch == 'winners') {
          return m.bracketPosition.bracket == 'winners' ||
              m.bracketPosition.bracket == 'grand_final';
        }
        if (_selectedBranch == 'losers') {
          return m.bracketPosition.bracket == 'losers';
        }
      }
      return true;
    }).toList();

    // When viewing knockout stage inside group_stage_knockout, compute totalRounds
    // only from the knockout matches so labels show 'Bán kết'/'Chung kết' correctly.
    // If the knockout stage is double elimination, count rounds from the winners
    // band only (roundNumber restarts per band), otherwise labels drift to
    // 'Vòng 1/16'... because the grand final round has the highest number.
    final effectiveTotalRounds =
        (isGroupStageKnockout && _selectedBranch == 'knockout')
        ? (stageScopedMatches.isEmpty
              ? totalRounds
              : stageScopedMatches.any(isDoubleEliminationMatch)
              ? stageScopedMatches
                    .where((m) => m.bracketPosition.bracket == 'winners')
                    .map((m) => m.round)
                    .fold(0, (a, b) => a > b ? a : b)
              : stageScopedMatches
                    .map((m) => m.round)
                    .fold(0, (a, b) => a > b ? a : b))
        : totalRounds;

    final groupScopedMatches = stageScopedMatches.where((m) {
      if (_selectedGroup.isNotEmpty &&
          _selectedGroup != 'all' &&
          isGroupStageMatch(m) &&
          m.groupName != _selectedGroup) {
        return false;
      }
      if (_selectedLeg != 0 &&
          isGroupStageMatch(m) &&
          (m.leg ?? 1) != _selectedLeg) {
        return false;
      }
      return true;
    }).toList();

    final configuredLegCount = widget.configuredLegs > 0
        ? widget.configuredLegs
        : 1;
    final availableLegs = <int>{
      ...stageScopedMatches.where(isGroupStageMatch).map((m) => m.leg ?? 1),
      ...List<int>.generate(configuredLegCount, (index) => index + 1),
    }.toList()..sort();

    final availableRounds =
        groupScopedMatches.map((m) => m.round).toSet().toList()..sort();
    final availableGroups =
        stageScopedMatches
            .where(isGroupStageMatch)
            .map((m) => m.groupName)
            .where((g) => g != null && g.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();

    // Filter logic: search is applied after this, to group rows only.
    final nonSearchMatches =
        stageScopedMatches.where((m) {
          // Branch filter
          if (_selectedBranch.isNotEmpty && _selectedBranch != 'all') {
            if (_selectedBranch == 'winners' &&
                m.bracketPosition.bracket != 'winners' &&
                m.bracketPosition.bracket != 'grand_final') {
              return false;
            }
            if (_selectedBranch == 'losers' &&
                m.bracketPosition.bracket != 'losers') {
              return false;
            }
            if (_selectedBranch == 'group_stage' && !isGroupStageMatch(m)) {
              return false;
            }
            if (_selectedBranch == 'knockout' && !isKnockoutMatch(m)) {
              return false;
            }
          }
          // Group filter
          if (_selectedGroup.isNotEmpty &&
              _selectedGroup != 'all' &&
              _selectedBranch != 'knockout' &&
              isGroupStageMatch(m) &&
              m.groupName != _selectedGroup) {
            return false;
          }
          // Leg filter for round-robin/group-stage encounters.
          if (_selectedLeg != 0 &&
              isGroupStageMatch(m) &&
              (m.leg ?? 1) != _selectedLeg) {
            return false;
          }
          // Round filter is reserved for knockout stages.
          if (_selectedRound != 0 && m.round != _selectedRound) return false;
          // Status filter
          if (_matchFilter.isNotEmpty && _matchFilter != 'all') {
            if (_matchFilter == 'live' && !m.isLive) return false;
            if (_matchFilter == 'scheduled' && !m.isScheduled) return false;
            if (_matchFilter == 'completed' && !m.isCompleted) return false;
          }

          return true;
        }).toList()..sort((a, b) {
          final aIsGroup = isGroupStageMatch(a);
          final bIsGroup = isGroupStageMatch(b);
          if (aIsGroup != bIsGroup) return aIsGroup ? -1 : 1;
          if (aIsGroup && bIsGroup) {
            final groupCompare = (a.groupName ?? '').compareTo(
              b.groupName ?? '',
            );
            if (groupCompare != 0) return groupCompare;
            final legCompare = (a.leg ?? 1).compareTo(b.leg ?? 1);
            if (legCompare != 0) return legCompare;
          }
          if (isSwiss) {
            final byRound = a.round.compareTo(b.round);
            if (byRound != 0) return byRound;
            final byNumber = a.matchNumber.compareTo(b.matchNumber);
            if (byNumber != 0) return byNumber;
          }
          return a.id.compareTo(b.id);
        });
    final filteredMatches = nonSearchMatches.where((m) {
      if (_searchQuery.isEmpty) return true;
      final sides = [
        participantLabel(
          teamName: matchSideTeamName(m, 1),
          players: matchSidePlayers(m, 1),
        ),
        participantLabel(
          teamName: matchSideTeamName(m, 2),
          players: matchSidePlayers(m, 2),
        ),
      ].join(' ').toLowerCase();
      return sides.contains(_searchQuery);
    }).toList();

    String sectionKey(MatchModel match) {
      if (!isGroupStageMatch(match)) return 'KNOCKOUT';
      return 'GROUP|${match.groupName}|${match.leg ?? 1}';
    }

    String sectionLabel(MatchModel match) {
      if (!isGroupStageMatch(match)) return l10n.bracketView_knockoutStage;
      final groupName = (match.groupName ?? '').trim().isEmpty
          ? l10n.bracketView_groupTitle
          : (match.groupName ?? '').trim();
      return '$groupName • ${l10n.crossTableLegIndicator(match.leg ?? 1, availableLegs.length)}';
    }

    // Swiss lists every match as a plain row (no group sections, no diagram).
    final groupMatches = filteredMatches
        .where((m) => isSwiss || isGroupStageMatch(m))
        .toList();
    // Search narrows only the group rows; the knockout tree must stay whole.
    final bracketMatches = nonSearchMatches
        .where((m) => !isSwiss && !isGroupStageMatch(m))
        .toList();

    return ListView(
      controller: widget.isEmbedded ? null : widget.scrollController,
      shrinkWrap: widget.isEmbedded,
      physics: widget.isEmbedded
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 160),
      children: [
        // ── Diagram Access Banner (Swiss has no bracket diagram) ──
        if (!isSwiss)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withValues(alpha: 0.12), colors.bgCard],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGroupStageKnockout ||
                              bracketType == 'group_stage_knockout'
                          ? l10n.bracketView_knockoutStage
                          : isDoubleElimination ||
                                bracketType == 'double_elimination'
                          ? l10n.bracketView_doubleEliminationMap
                          : isRoundRobin || bracketType == 'round_robin'
                          ? l10n.bracketView_roundRobinMap
                          : l10n.bracketView_knockoutTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      isGroupStageKnockout ||
                              bracketType == 'group_stage_knockout'
                          ? l10n.bracketView_knockoutDescription
                          : isDoubleElimination ||
                                bracketType == 'double_elimination'
                          ? l10n.bracketView_doubleEliminationDescription
                          : isRoundRobin || bracketType == 'round_robin'
                          ? l10n.bracketView_roundRobinDescription
                          : l10n.bracketView_singleEliminationDescription,
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BracketDiagramScreen(
                        tournamentId: widget.tournamentId,
                        divisionId: _activeDivisionId,
                        bracketType: bracketType,
                        initialMatches: matches,
                        isReferee: isReferee,
                        isReadOnly: isReadOnly,
                        canEditBracket: widget.canEditBracket,
                        canScoreMatch: canScoreMatch,
                        isLite: widget.isLite || tournament?.isLite == true,
                      ),
                    ),
                  );
                  ref.invalidate(bracketMatchesProvider(widget.tournamentId));
                  ref.invalidate(
                    liteBracketMatchesProvider(widget.tournamentId),
                  );
                  ref.invalidate(matchesProvider(widget.tournamentId));
                  final params = (
                    tournamentId: widget.tournamentId,
                    divisionId: _activeDivisionId,
                  );
                  ref.invalidate(bracketMatchesWithDivisionProvider(params));
                  ref.invalidate(
                    liteBracketMatchesWithDivisionProvider(params),
                  );
                  ref.invalidate(matchesWithDivisionProvider(params));
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.account_tree_rounded, size: 14),
                label: Text(
                  isGroupStageKnockout || bracketType == 'group_stage_knockout'
                      ? l10n.bracketView_knockoutMap
                      : isDoubleElimination ||
                            bracketType == 'double_elimination'
                      ? l10n.bracketView_doubleEliminationMap
                      : isRoundRobin || bracketType == 'round_robin'
                      ? l10n.bracketView_roundRobinMap
                      : l10n.bracketView_knockoutMap,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Search & Filter Unified Bar ──
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _currentFilterState.hasActiveFilters
                  ? AppTheme.primary
                  : colors.border,
              width: _currentFilterState.hasActiveFilters ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(
                      const Duration(milliseconds: 250),
                      () {
                        if (mounted) {
                          setState(
                            () => _searchQuery = val.trim().toLowerCase(),
                          );
                        }
                      },
                    );
                  },
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.bracketView_searchHint,
                    hintStyle: TextStyle(fontSize: 12, color: colors.textMuted),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: colors.textMuted,
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () {
                            _debounceTimer?.cancel();
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        );
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              Container(height: 22, width: 1, color: colors.border),
              // Unified Filter Button inside search bar
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openFilterBottomSheet(
                    context: context,
                    isDoubleElimination: isDoubleElimination,
                    isGroupStageKnockout: isGroupStageKnockout,
                    isRoundRobin: isRoundRobin,
                    liveCount: liveCount,
                    scheduledCount: scheduledCount,
                    completedCount: completedCount,
                    availableGroups: availableGroups,
                    availableLegs: availableLegs,
                    availableRounds: availableRounds,
                    effectiveTotalRounds: effectiveTotalRounds,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: _currentFilterState.hasActiveFilters
                              ? AppTheme.primary
                              : colors.textMuted,
                        ),
                        if (_currentFilterState.hasActiveFilters) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_currentFilterState.activeCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Active Filter Badges (Only shown when filters are active) ──
        if (_currentFilterState.hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  if (_matchFilter.isNotEmpty)
                    _buildActiveFilterChip(
                      label: _getMatchFilterLabel(_matchFilter, l10n),
                      onRemove: () => setState(() => _matchFilter = ''),
                      context: context,
                    ),
                  if (_selectedBranch.isNotEmpty)
                    _buildActiveFilterChip(
                      label: _getBranchFilterLabel(
                        _selectedBranch,
                        isDoubleElimination,
                        l10n,
                      ),
                      onRemove: () => setState(() => _selectedBranch = ''),
                      context: context,
                    ),
                  if (_selectedGroup.isNotEmpty)
                    _buildActiveFilterChip(
                      label: _selectedGroup,
                      onRemove: () => setState(() => _selectedGroup = ''),
                      context: context,
                    ),
                  if (_selectedLeg != 0)
                    _buildActiveFilterChip(
                      label: l10n.crossTableLegIndicator(
                        _selectedLeg,
                        availableLegs.length,
                      ),
                      onRemove: () => setState(() => _selectedLeg = 0),
                      context: context,
                    ),
                  if (_selectedRound != 0)
                    _buildActiveFilterChip(
                      label: _getRoundLabel(
                        _selectedRound,
                        isRoundRobin || isSwiss,
                        isGroupStageKnockout,
                        _selectedBranch,
                        effectiveTotalRounds,
                        l10n,
                      ),
                      onRemove: () => setState(() => _selectedRound = 0),
                      context: context,
                    ),
                  TextButton(
                    onPressed: () => setState(() {
                      _matchFilter = '';
                      _selectedBranch = '';
                      _selectedGroup = '';
                      _selectedLeg = 0;
                      _selectedRound = 0;
                    }),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Xoá lọc',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Swiss round picker: plain text pills; tap again for all rounds ──
        if (isSwiss && availableRounds.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final r in availableRounds)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: RoundFilterPill(
                        isSelected: _selectedRound == r,
                        label: l10n.swissRoundLabel(r),
                        onTap: () => setState(
                          () => _selectedRound = _selectedRound == r ? 0 : r,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // ── MATCHES LIST ──
        if (filteredMatches.isEmpty && bracketMatches.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: colors.textMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.bracketView_noMatchingMatches,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        for (var index = 0; index < groupMatches.length; index++) ...[
          if (!isSwiss &&
              (index == 0 ||
                  sectionKey(groupMatches[index]) !=
                      sectionKey(groupMatches[index - 1])))
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: colors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      sectionLabel(groupMatches[index]),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colors.border)),
                ],
              ),
            ),
          MatchTableRow(
            match: groupMatches[index],
            isReadOnly: isReadOnly,
            totalRounds: effectiveTotalRounds,
            tournamentId: widget.tournamentId,
            isReferee: isReferee,
            canScoreMatch: canScoreMatch,
            onUnassignSlot: widget.canEditBracket ? _unassignBracketSlot : null,
          ),
        ],
        if (bracketMatches.isNotEmpty)
          SizedBox(
            height: 420,
            child: isDoubleElimination
                ? DoubleElimDiagram(
                    matches: bracketMatches,
                    tournamentId: widget.tournamentId,
                    isReferee: isReferee,
                    isReadOnly: isReadOnly,
                    canScoreMatch: canScoreMatch,
                    onDoubleTapMatch: widget.canEditBracket
                        ? _handleDoubleTapMatch
                        : null,
                  )
                : SingleElimDiagram(
                    matches: bracketMatches,
                    tournamentId: widget.tournamentId,
                    isReferee: isReferee,
                    isReadOnly: isReadOnly,
                    canScoreMatch: canScoreMatch,
                    onDoubleTapMatch: widget.canEditBracket
                        ? _handleDoubleTapMatch
                        : null,
                  ),
          ),
      ],
    );
  }

  String _getMatchFilterLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'live':
        return l10n.bracketView_live;
      case 'scheduled':
        return l10n.bracketView_scheduled;
      case 'completed':
        return l10n.bracketView_completed;
      default:
        return status;
    }
  }

  String _getBranchFilterLabel(
    String branch,
    bool isDoubleElimination,
    AppLocalizations l10n,
  ) {
    if (isDoubleElimination) {
      if (branch == 'winners') return l10n.bracketView_winners;
      if (branch == 'losers') return l10n.bracketView_losers;
    } else {
      if (branch == 'group_stage') return l10n.bracketView_groupStage;
      if (branch == 'knockout') return l10n.bracketView_knockoutStage;
    }
    return branch;
  }

  String _getRoundLabel(
    int round,
    bool isRoundRobin,
    bool isGroupStageKnockout,
    String selectedBranch,
    int effectiveTotalRounds,
    AppLocalizations l10n,
  ) {
    final isGroupStageRound =
        isGroupStageKnockout && selectedBranch != 'knockout';
    return isRoundRobin || isGroupStageRound
        ? l10n.bracketView_round(round)
        : MatchRoundLabel.knockoutRoundName(
            round,
            effectiveTotalRounds,
            l10n: l10n,
          );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onRemove,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 11,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _computeTotalRounds(List<MatchModel> matches, String bracketType) {
    if (matches.isEmpty) return 1;
    if (bracketType == AppConstants.bracketSwiss) {
      final configured = ref
          .watch(
            swissStageProvider((
              tournamentId: widget.tournamentId,
              divisionId: _activeDivisionId,
            )),
          )
          .value
          ?.totalRounds;
      if (configured != null && configured > 0) return configured;
    }
    if (bracketType == AppConstants.bracketDoubleElimination) {
      final winnersRounds = matches
          .where((m) => m.bracketPosition.bracket == 'winners')
          .map((m) => m.round);
      return winnersRounds.isEmpty
          ? 1
          : winnersRounds.reduce((a, b) => a > b ? a : b);
    }
    if (bracketType == AppConstants.bracketGroupStageKnockout) {
      // The knockout round count comes from the knockout matches only — the
      // round-robin stage has its own round numbers. The backend generates
      // exactly as many knockout rounds as the advancing-teams setting allows
      // (advance 4 → bán kết + chung kết, advance 8 → tứ kết, advance 16 →
      // vòng 1/8...), so counting the knockout matches keeps labels aligned
      // with the tournament setting even when viewing the combined list.
      final knockout = matches.where(isKnockoutMatch).toList();
      if (knockout.isEmpty) {
        return matches.map((m) => m.round).reduce((a, b) => a > b ? a : b);
      }
      if (knockout.any(isDoubleEliminationMatch)) {
        final winnersRounds = knockout
            .where((m) => m.bracketPosition.bracket == 'winners')
            .map((m) => m.round);
        return winnersRounds.isEmpty
            ? 1
            : winnersRounds.reduce((a, b) => a > b ? a : b);
      }
      return knockout.map((m) => m.round).reduce((a, b) => a > b ? a : b);
    }
    return matches.map((m) => m.round).reduce((a, b) => a > b ? a : b);
  }
}

class _BracketShimmerLoading extends StatelessWidget {
  const _BracketShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: context.colors.bgSurface,
          highlightColor: context.colors.bgCard,
          child: Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
          ),
        );
      },
    );
  }
}

/// Manager-only strip above the Swiss tabs: open the pairing screen for the
/// next round, undo the newest round, or a status line when neither applies.
class SwissRoundActions extends ConsumerWidget {
  const SwissRoundActions({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    required this.stageId,
    required this.matches,
    required this.totalRounds,
    required this.onOpenPairing,
  });

  final String tournamentId;
  final String divisionId;
  final String stageId;
  final List<MatchModel> matches;
  final int totalRounds;

  /// Called with `(stageId, nextRound, totalRounds)`.
  final void Function(String stageId, int round, int totalRounds)
  onOpenPairing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = swissRoundState(matches, totalRounds);
    if (state.currentRound == 0) return const SizedBox.shrink();

    final nextRound = state.nextRound;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (nextRound != null)
            TextButton(
              key: const Key('swiss-next-round'),
              onPressed: () => onOpenPairing(stageId, nextRound, totalRounds),
              child: Text(l10n.swissActionGenerateNextRound(nextRound)),
            )
          else
            Text(
              state.roundComplete
                  ? l10n.swissActionAllRoundsDone(totalRounds)
                  : l10n.swissActionRoundInProgress(state.currentRound),
              key: const Key('swiss-round-status'),
              style: TextStyle(color: context.colors.textSecondary),
            ),
          if (state.canUndo)
            TextButton(
              key: const Key('swiss-undo-round'),
              onPressed: () => _undo(context, ref, state.currentRound),
              child: Text(l10n.swissActionUndoRound(state.currentRound)),
            ),
        ],
      ),
    );
  }

  Future<void> _undo(BuildContext context, WidgetRef ref, int round) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(l10n.swissActionUndoRound(round)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.swissPairingCancel),
          ),
          TextButton(
            key: const Key('swiss-undo-round-confirm'),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.swissActionUndoRound(round)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    String message;
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .swissUndoRound(
            tournamentId,
            round,
            divisionId: divisionId,
            stageId: stageId,
          );
      ref.invalidate(
        bracketMatchesWithDivisionProvider((
          tournamentId: tournamentId,
          divisionId: divisionId,
        )),
      );
      ref.invalidate(
        swissStageProvider((tournamentId: tournamentId, divisionId: divisionId)),
      );
      message = l10n.swissPairingUndone(round);
    } on SwissApiException catch (error) {
      message = swissApiErrorText(
        l10n,
        error.code ?? (error.status == null ? 'NETWORK' : 'UNKNOWN'),
      );
    } catch (_) {
      message = l10n.swissApiErrorUnknown;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
