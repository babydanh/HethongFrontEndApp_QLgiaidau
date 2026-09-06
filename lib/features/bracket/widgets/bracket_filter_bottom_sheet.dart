import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/filter_chips.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Immutable model representing the active filter state for bracket matches.
class BracketFilterState {
  final String matchFilter;
  final String selectedBranch;
  final String selectedGroup;
  final int selectedLeg;
  final int selectedRound;

  const BracketFilterState({
    this.matchFilter = '',
    this.selectedBranch = '',
    this.selectedGroup = '',
    this.selectedLeg = 0,
    this.selectedRound = 0,
  });

  int get activeCount {
    var count = 0;
    if (matchFilter.isNotEmpty && matchFilter != 'all') count++;
    if (selectedBranch.isNotEmpty && selectedBranch != 'all') count++;
    if (selectedGroup.isNotEmpty && selectedGroup != 'all') count++;
    if (selectedLeg != 0) count++;
    if (selectedRound != 0) count++;
    return count;
  }

  bool get hasActiveFilters => activeCount > 0;

  BracketFilterState copyWith({
    String? matchFilter,
    String? selectedBranch,
    String? selectedGroup,
    int? selectedLeg,
    int? selectedRound,
  }) {
    return BracketFilterState(
      matchFilter: matchFilter ?? this.matchFilter,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      selectedLeg: selectedLeg ?? this.selectedLeg,
      selectedRound: selectedRound ?? this.selectedRound,
    );
  }

  static const empty = BracketFilterState();
}

/// A comprehensive bottom sheet that consolidates all match filters
/// (status, branch/stage, group, leg, round) into a single, clean modal view.
class BracketFilterBottomSheet extends StatefulWidget {
  final BracketFilterState initialState;
  final bool isDoubleElimination;
  final bool isGroupStageKnockout;
  final bool isRoundRobin;
  final int liveCount;
  final int scheduledCount;
  final int completedCount;
  final List<String> availableGroups;
  final List<int> availableLegs;
  final List<int> availableRounds;
  final int effectiveTotalRounds;
  final ValueChanged<BracketFilterState> onApply;

  const BracketFilterBottomSheet({
    super.key,
    required this.initialState,
    required this.isDoubleElimination,
    required this.isGroupStageKnockout,
    required this.isRoundRobin,
    required this.liveCount,
    required this.scheduledCount,
    required this.completedCount,
    required this.availableGroups,
    required this.availableLegs,
    required this.availableRounds,
    required this.effectiveTotalRounds,
    required this.onApply,
  });

  @override
  State<BracketFilterBottomSheet> createState() =>
      _BracketFilterBottomSheetState();
}

class _BracketFilterBottomSheetState extends State<BracketFilterBottomSheet> {
  late String _matchFilter;
  late String _selectedBranch;
  late String _selectedGroup;
  late int _selectedLeg;
  late int _selectedRound;

  @override
  void initState() {
    super.initState();
    _matchFilter = widget.initialState.matchFilter;
    _selectedBranch = widget.initialState.selectedBranch;
    _selectedGroup = widget.initialState.selectedGroup;
    _selectedLeg = widget.initialState.selectedLeg;
    _selectedRound = widget.initialState.selectedRound;
  }

  void _resetFilters() {
    setState(() {
      _matchFilter = '';
      _selectedBranch = '';
      _selectedGroup = '';
      _selectedLeg = 0;
      _selectedRound = 0;
    });
  }

  bool get _hasAnyFilterSelected {
    return _matchFilter.isNotEmpty ||
        _selectedBranch.isNotEmpty ||
        _selectedGroup.isNotEmpty ||
        _selectedLeg != 0 ||
        _selectedRound != 0;
  }

  void _handleApply() {
    widget.onApply(
      BracketFilterState(
        matchFilter: _matchFilter,
        selectedBranch: _selectedBranch,
        selectedGroup: _selectedGroup,
        selectedLeg: _selectedLeg,
        selectedRound: _selectedRound,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    final cleanGroups = widget.availableGroups.where((g) {
      final lower = g.toLowerCase();
      return !lower.contains('winners') &&
          !lower.contains('losers') &&
          !lower.contains('grand') &&
          !lower.contains('bracket');
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.bgDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bộ lọc trận đấu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_hasAnyFilterSelected)
                    TextButton(
                      onPressed: _resetFilters,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        'Đặt lại',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.error,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: colors.textMuted,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Filter Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Trạng thái
                    _buildSectionTitle(l10n.bracketView_statusTitle),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        RoundFilterPill(
                          isSelected: _matchFilter.isEmpty || _matchFilter == 'all',
                          label: 'Tất cả',
                          onTap: () => setState(() => _matchFilter = ''),
                        ),
                        RoundFilterPill(
                          isSelected: _matchFilter == 'live',
                          label: l10n.bracketView_live,
                          count: widget.liveCount,
                          onTap: () => setState(
                            () => _matchFilter = _matchFilter == 'live' ? '' : 'live',
                          ),
                        ),
                        RoundFilterPill(
                          isSelected: _matchFilter == 'scheduled',
                          label: l10n.bracketView_scheduled,
                          count: widget.scheduledCount,
                          onTap: () => setState(
                            () => _matchFilter = _matchFilter == 'scheduled' ? '' : 'scheduled',
                          ),
                        ),
                        RoundFilterPill(
                          isSelected: _matchFilter == 'completed',
                          label: l10n.bracketView_completed,
                          count: widget.completedCount,
                          onTap: () => setState(
                            () => _matchFilter = _matchFilter == 'completed' ? '' : 'completed',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section 2: Nhánh thi đấu / Giai đoạn
                    if (widget.isDoubleElimination) ...[
                      _buildSectionTitle(l10n.bracketView_branchTitle),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          RoundFilterPill(
                            isSelected: _selectedBranch.isEmpty || _selectedBranch == 'all',
                            label: 'Tất cả nhánh',
                            onTap: () => setState(() {
                              _selectedBranch = '';
                              _selectedRound = 0;
                            }),
                          ),
                          RoundFilterPill(
                            isSelected: _selectedBranch == 'winners',
                            label: l10n.bracketView_winners,
                            onTap: () => setState(() {
                              _selectedBranch = _selectedBranch == 'winners' ? '' : 'winners';
                              _selectedRound = 0;
                            }),
                          ),
                          RoundFilterPill(
                            isSelected: _selectedBranch == 'losers',
                            label: l10n.bracketView_losers,
                            onTap: () => setState(() {
                              _selectedBranch = _selectedBranch == 'losers' ? '' : 'losers';
                              _selectedRound = 0;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (widget.isGroupStageKnockout) ...[
                      _buildSectionTitle(l10n.bracketView_stageTitle),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          RoundFilterPill(
                            isSelected: _selectedBranch.isEmpty,
                            label: 'Tất cả giai đoạn',
                            onTap: () => setState(() {
                              _selectedBranch = '';
                              _selectedGroup = '';
                              _selectedLeg = 0;
                              _selectedRound = 0;
                            }),
                          ),
                          RoundFilterPill(
                            isSelected: _selectedBranch == 'group_stage',
                            label: l10n.bracketView_groupStage,
                            onTap: () => setState(() {
                              _selectedBranch = _selectedBranch == 'group_stage' ? '' : 'group_stage';
                              _selectedRound = 0;
                            }),
                          ),
                          RoundFilterPill(
                            isSelected: _selectedBranch == 'knockout',
                            label: l10n.bracketView_knockoutStage,
                            onTap: () => setState(() {
                              _selectedBranch = _selectedBranch == 'knockout' ? '' : 'knockout';
                              _selectedGroup = '';
                              _selectedLeg = 0;
                              _selectedRound = 0;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Section 3: Bảng đấu
                    if (cleanGroups.isNotEmpty && _selectedBranch != 'knockout') ...[
                      _buildSectionTitle(l10n.bracketView_groupTitle),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          RoundFilterPill(
                            isSelected: _selectedGroup.isEmpty,
                            label: 'Tất cả bảng',
                            onTap: () => setState(() {
                              _selectedGroup = '';
                              _selectedRound = 0;
                            }),
                          ),
                          ...cleanGroups.map(
                            (group) => RoundFilterPill(
                              isSelected: _selectedGroup == group,
                              label: group,
                              onTap: () => setState(() {
                                _selectedGroup = _selectedGroup == group ? '' : group;
                                _selectedRound = 0;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Section 4: Lượt đấu
                    if (widget.availableLegs.length > 1 && _selectedBranch != 'knockout') ...[
                      _buildSectionTitle(l10n.seriesLegCount),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          RoundFilterPill(
                            isSelected: _selectedLeg == 0,
                            label: 'Tất cả lượt',
                            onTap: () => setState(() {
                              _selectedLeg = 0;
                              _selectedRound = 0;
                            }),
                          ),
                          ...widget.availableLegs.map(
                            (leg) => RoundFilterPill(
                              isSelected: _selectedLeg == leg,
                              label: l10n.crossTableLegIndicator(leg, widget.availableLegs.length),
                              onTap: () => setState(() {
                                _selectedLeg = _selectedLeg == leg ? 0 : leg;
                                _selectedRound = 0;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Section 5: Vòng đấu (Knockout)
                    if (!widget.isRoundRobin &&
                        (!widget.isGroupStageKnockout || _selectedBranch == 'knockout') &&
                        widget.availableRounds.length > 1) ...[
                      _buildSectionTitle(l10n.bracketView_roundTitle),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          RoundFilterPill(
                            isSelected: _selectedRound == 0,
                            label: 'Tất cả vòng',
                            onTap: () => setState(() => _selectedRound = 0),
                          ),
                          ...widget.availableRounds.map((r) {
                            final isGroupStageRound = widget.isGroupStageKnockout &&
                                _selectedBranch != 'knockout';
                            final label = widget.isRoundRobin || isGroupStageRound
                                ? l10n.bracketView_round(r)
                                : MatchRoundLabel.knockoutRoundName(
                                    r,
                                    widget.effectiveTotalRounds,
                                    l10n: l10n,
                                  );
                            return RoundFilterPill(
                              isSelected: _selectedRound == r,
                              label: label,
                              onTap: () => setState(
                                () => _selectedRound = _selectedRound == r ? 0 : r,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Apply Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _handleApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Áp dụng bộ lọc',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.colors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
