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
import 'package:app_quanly_giaidau/features/bracket/widgets/match_table_row.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/standings_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_filter_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
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

  void _handleDoubleTapMatch(MatchModel match) {
    if (!widget.canEditBracket) return;
    final queryParameters = <String, String>{
      'focusMatchId': match.id,
      if (widget.divisionId != null && widget.divisionId!.isNotEmpty)
        'divisionId': widget.divisionId!,
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
            divisionId: widget.divisionId,
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
        divisionId: widget.divisionId,
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
    final matchesAsync = ref.watch(
      bracketMatchesWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
      )),
    );
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final tournament = tournamentAsync.value;
    final auth = ref.watch(authProvider);

    final bodyContent = matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 64,
                    color: context.colors.textMuted.withValues(alpha: 0.4),
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
                ],
              ),
            ),
          );
        }

        final divisionBracketType = tournamentAsync.value?.divisions
            .where((d) => d.id == widget.divisionId)
            .firstOrNull
            ?.bracketType;

        final rawType =
            (widget.bracketType ??
                    divisionBracketType ??
                    tournamentAsync.value?.bracketType ??
                    '')
                .trim()
                .toLowerCase();

        final hasDoubleElimMatches = matches.any(isDoubleEliminationMatch);
        final hasGroupMatches = matches.any(isGroupStageMatch);
        final hasKnockoutMatches = matches.any(isKnockoutMatch);

        final String effectiveBracketType;
        if (hasDoubleElimMatches ||
            rawType == 'double_elimination' ||
            rawType == 'doubleelimination') {
          effectiveBracketType = AppConstants.bracketDoubleElimination;
        } else if (rawType == 'single_elimination' ||
            rawType == 'singleelimination' ||
            rawType == 'knockout') {
          effectiveBracketType = AppConstants.bracketSingleElimination;
        } else if (rawType == 'round_robin' || rawType == 'roundrobin') {
          effectiveBracketType = AppConstants.bracketRoundRobin;
        } else if (rawType == 'group_stage_knockout' ||
            rawType == 'groupstageknockout') {
          effectiveBracketType = AppConstants.bracketGroupStageKnockout;
        } else if (hasGroupMatches && hasKnockoutMatches) {
          effectiveBracketType = AppConstants.bracketGroupStageKnockout;
        } else if (hasGroupMatches) {
          effectiveBracketType = AppConstants.bracketRoundRobin;
        } else {
          effectiveBracketType = AppConstants.bracketSingleElimination;
        }

        final isRoundRobin =
            effectiveBracketType == AppConstants.bracketRoundRobin;
        final isGroupStageKnockout =
            effectiveBracketType == AppConstants.bracketGroupStageKnockout;
        final hasGroupStage =
            isRoundRobin || (isGroupStageKnockout && hasGroupMatches);

        final effectiveIsLite = widget.isLite || tournament?.isLite == true;
        final canActAsReferee =
            effectiveIsLite || auth.role == UserRole.admin || widget.isReferee;
        final isReadOnlyMode = !effectiveIsLite && auth.role == UserRole.viewer;

        if (hasGroupStage) {
          return Column(
            mainAxisSize: widget.isEmbedded
                ? MainAxisSize.min
                : MainAxisSize.max,
            children: [
              _buildGroupStageTabBar(l10n),
              const SizedBox(height: 8),
              if (widget.isEmbedded)
                _buildGroupTabContent(
                  matches,
                  effectiveBracketType,
                  auth,
                  canActAsReferee: canActAsReferee,
                  isReadOnly: isReadOnlyMode,
                )
              else
                Expanded(
                  child: _buildGroupTabContent(
                    matches,
                    effectiveBracketType,
                    auth,
                    canActAsReferee: canActAsReferee,
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

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (auth.role == UserRole.admin) {
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

  Widget _buildGroupStageTabBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          _buildGroupTabItem(0, l10n.bracketView_crossTable),
          _buildGroupTabItem(1, l10n.bracketView_standings),
          _buildGroupTabItem(2, l10n.bracketView_schedule),
        ],
      ),
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

  Widget _buildGroupTabContent(
    List<MatchModel> matches,
    String bracketType,
    AuthState auth, {
    bool canActAsReferee = false,
    bool isReadOnly = true,
  }) {
    switch (_selectedGroupTab) {
      case 0:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: CrossTableView(
            matches: matches,
            tournamentId: widget.tournamentId,
            divisionId: widget.divisionId,
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
          divisionId: widget.divisionId,
        );
      case 2:
        return _buildKnockoutMatchTable(
          matches,
          bracketType,
          isReadOnly,
          canActAsReferee,
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

    // Filter valid matches
    // Keep TBD/TBD knockout slots visible. The web shows these scheduled
    // placeholders so users can see every configured round before seeding.
    final validMatches = matches.where((m) => !m.isBye).toList();

    // Status counts
    final liveCount = validMatches.where((m) => m.isLive).length;
    final scheduledCount = validMatches.where((m) => m.isScheduled).length;
    final completedCount = validMatches.where((m) => m.isCompleted).length;

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

    // Filter logic
    final filteredMatches =
        stageScopedMatches.where((m) {
          // Search query filter
          if (_searchQuery.isNotEmpty) {
            final t1 = m.team1Name.toLowerCase();
            final t2 = m.team2Name.toLowerCase();
            if (!t1.contains(_searchQuery) && !t2.contains(_searchQuery)) {
              return false;
            }
          }
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
          return a.id.compareTo(b.id);
        });

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
        // ── Diagram Access Banner ──
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BracketDiagramScreen(
                        tournamentId: widget.tournamentId,
                        divisionId: widget.divisionId,
                        bracketType: bracketType,
                        initialMatches: matches,
                        isReferee: isReferee,
                        isReadOnly: isReadOnly,
                        canEditBracket: widget.canEditBracket,
                        isLite: widget.isLite || tournament?.isLite == true,
                      ),
                    ),
                  );
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
                        isRoundRobin,
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

        // ── MATCHES LIST ──
        if (filteredMatches.isEmpty)
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
        for (var index = 0; index < filteredMatches.length; index++) ...[
          if (index == 0 ||
              sectionKey(filteredMatches[index]) !=
                  sectionKey(filteredMatches[index - 1]))
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: colors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      sectionLabel(filteredMatches[index]),
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
            match: filteredMatches[index],
            isReadOnly: isReadOnly,
            totalRounds: effectiveTotalRounds,
            tournamentId: widget.tournamentId,
            isReferee: isReferee,
            onUnassignSlot: widget.canEditBracket ? _unassignBracketSlot : null,
          ),
        ],
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
