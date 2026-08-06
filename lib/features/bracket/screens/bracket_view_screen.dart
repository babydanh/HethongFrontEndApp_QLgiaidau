import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:app_quanly_giaidau/features/bracket/widgets/filter_chips.dart' show RoundFilterPill;
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';

class BracketViewScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? divisionId;
  final bool isReferee;
  final bool isEmbedded;
  final ScrollController? scrollController;

  const BracketViewScreen({
    super.key,
    required this.tournamentId,
    this.divisionId,
    this.isReferee = false,
    this.isEmbedded = false,
    this.scrollController,
  });

  @override
  ConsumerState<BracketViewScreen> createState() => _BracketViewScreenState();
}

class _BracketViewScreenState extends ConsumerState<BracketViewScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedRound = 0;
  String _matchFilter = '';
  String _selectedBranch = '';
  String _selectedGroup = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (mounted) setState(() {});
    });

    if (!widget.isEmbedded) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();

    if (!widget.isEmbedded) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(bracketMatchesWithDivisionProvider((
      tournamentId: widget.tournamentId,
      divisionId: widget.divisionId,
    )));
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final resultAsync = ref.watch(tournamentResultProvider((
      tournamentId: widget.tournamentId,
      divisionId: widget.divisionId,
    )));
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
                    'Chưa có trận đấu nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy bốc thăm để tạo sơ đồ thi đấu',
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

        final bracketType =
            tournamentAsync.value?.bracketType ??
            AppConstants.bracketSingleElimination;
        final isRoundRobin = bracketType == AppConstants.bracketRoundRobin;
        final isGroupStageKnockout =
            bracketType == AppConstants.bracketGroupStageKnockout;

        if (isRoundRobin || isGroupStageKnockout) {
          if (widget.isEmbedded) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 34,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: context.colors.textSecondary,
                    indicatorColor: AppTheme.primary,
                    indicatorWeight: 2,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                    tabs: const [
                      Tab(height: 30, text: 'Bảng chéo'),
                      Tab(height: 30, text: 'Bảng xếp hạng'),
                      Tab(height: 30, text: 'Lịch thi đấu'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: _tabController,
                  builder: (context, _) {
                    switch (_tabController.index) {
                      case 0:
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CrossTableView(
                            matches: matches,
                            tournamentId: widget.tournamentId,
                            divisionId: widget.divisionId,
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
                          auth.role == UserRole.viewer,
                          auth.role == UserRole.admin || widget.isReferee,
                        );
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            );
          }

          return Column(
            children: [
              SizedBox(
                height: 34,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: context.colors.textSecondary,
                  indicatorColor: AppTheme.primary,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                  tabs: const [
                    Tab(height: 30, text: 'Bảng chéo'),
                    Tab(height: 30, text: 'Bảng xếp hạng'),
                    Tab(height: 30, text: 'Lịch thi đấu'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CrossTableView(
                        matches: matches,
                        tournamentId: widget.tournamentId,
                        divisionId: widget.divisionId,
                      ),
                    ),
                    StandingsView(
                      matches: matches,
                      tournamentId: widget.tournamentId,
                      divisionId: widget.divisionId,
                    ),
                    _buildKnockoutMatchTable(
                      matches,
                      bracketType,
                      auth.role == UserRole.viewer,
                      auth.role == UserRole.admin || widget.isReferee,
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          return _buildKnockoutMatchTable(
            matches,
            bracketType,
            auth.role == UserRole.viewer,
            auth.role == UserRole.admin || widget.isReferee,
          );
        }
      },
      loading: () => const _BracketShimmerLoading(),
      error: (e, st) => Center(child: Text('Lỗi: $e')),
    );

    if (widget.isEmbedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildResultAwards(resultAsync),
          bodyContent,
        ],
      );
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
      body: Column(
        children: [
          _buildResultAwards(resultAsync),
          Expanded(child: bodyContent),
        ],
      ),
    );
  }

  Widget _buildResultAwards(AsyncValue<Map<String, dynamic>> resultAsync) {
    final snapshot = resultAsync.value;
    if (snapshot == null || snapshot['finalized'] != true) {
      return const SizedBox.shrink();
    }

    final rawAwards = snapshot['awards'];
    if (rawAwards is! List || rawAwards.isEmpty) {
      return const SizedBox.shrink();
    }

    final awards = rawAwards.whereType<Map>().map((raw) {
      final award = Map<String, dynamic>.from(raw);
      final participant = award['participant'];
      final participantMap = participant is Map
          ? Map<String, dynamic>.from(participant)
          : const <String, dynamic>{};
      return (
        rank: (award['rank'] as num?)?.toInt() ?? 0,
        shared: award['shared'] == true,
        name: (participantMap['teamName'] ?? 'Chưa xác định').toString(),
      );
    }).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết quả chính thức',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: awards.map((award) {
              final label = award.shared
                  ? 'Hạng ${award.rank} đồng hạng'
                  : 'Hạng ${award.rank}';
              return Container(
                constraints: const BoxConstraints(minWidth: 130),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(award.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKnockoutMatchTable(
    List<MatchModel> matches,
    String bracketType,
    bool isReadOnly,
    bool isReferee,
  ) {
    final colors = context.colors;
    final totalRounds = _computeTotalRounds(matches, bracketType);

    final isDoubleElimination = bracketType == AppConstants.bracketDoubleElimination;
    final isGroupStageKnockout = bracketType == AppConstants.bracketGroupStageKnockout;
    final isRoundRobin = bracketType == AppConstants.bracketRoundRobin;

    // Filter valid matches
    final validMatches = matches.where((m) {
      final t1 = m.team1Name.trim().toUpperCase();
      final t2 = m.team2Name.trim().toUpperCase();
      return !(t1 == 'TBD' && t2 == 'TBD' && !m.isLive && !m.isCompleted);
    }).toList();

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

    final groupScopedMatches =
        isGroupStageKnockout && _selectedGroup.isNotEmpty && _selectedGroup != 'all'
            ? stageScopedMatches.where((m) => m.groupName == _selectedGroup).toList()
            : stageScopedMatches;

    final availableRounds = groupScopedMatches.map((m) => m.round).toSet().toList()
      ..sort();
    final availableGroups = stageScopedMatches
        .where(isGroupStageMatch)
        .map((m) => m.groupName)
        .where((g) => g != null && g.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();

    // Filter logic
    final filteredMatches = stageScopedMatches.where((m) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final t1 = m.team1Name.toLowerCase();
        final t2 = m.team2Name.toLowerCase();
        if (!t1.contains(_searchQuery) && !t2.contains(_searchQuery)) return false;
      }
      // Branch filter
      if (_selectedBranch.isNotEmpty && _selectedBranch != 'all') {
        if (_selectedBranch == 'winners' && m.bracketPosition.bracket != 'winners' && m.bracketPosition.bracket != 'grand_final') return false;
        if (_selectedBranch == 'losers' && m.bracketPosition.bracket != 'losers') return false;
        if (_selectedBranch == 'group_stage' && !isGroupStageMatch(m)) return false;
        if (_selectedBranch == 'knockout' && !isKnockoutMatch(m)) return false;
      }
      // Group filter
      if (_selectedGroup.isNotEmpty && _selectedGroup != 'all' && _selectedBranch != 'knockout' && m.groupName != _selectedGroup) return false;
      // Round filter
      if (_selectedRound != 0 && m.round != _selectedRound) return false;
      // Status filter
      if (_matchFilter.isNotEmpty && _matchFilter != 'all') {
        if (_matchFilter == 'live' && !m.isLive) return false;
        if (_matchFilter == 'scheduled' && !m.isScheduled) return false;
        if (_matchFilter == 'completed' && !m.isCompleted) return false;
      }

      return true;
    }).toList();

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
          if (!isRoundRobin)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.12),
                    colors.bgCard,
                  ],
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
                          isGroupStageKnockout || bracketType == 'group_stage_knockout'
                              ? 'Sơ đồ Vòng Knockout (Playoffs)'
                              : isDoubleElimination || bracketType == 'double_elimination'
                                  ? 'Sơ đồ Đấu loại kép'
                                  : isRoundRobin || bracketType == 'round_robin'
                                      ? 'Sơ đồ Vòng tròn tính điểm'
                                      : 'Sơ đồ Loại trực tiếp',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          isGroupStageKnockout || bracketType == 'group_stage_knockout'
                              ? 'Xem nhánh đấu loại trực tiếp các đội vượt qua vòng bảng'
                              : isDoubleElimination || bracketType == 'double_elimination'
                                  ? 'Xem phân nhánh thắng & nhánh thua (Double Elimination)'
                                  : isRoundRobin || bracketType == 'round_robin'
                                      ? 'Xem sơ đồ thi đấu các lượt trận vòng tròn'
                                      : 'Xem phân nhánh đấu loại trực tiếp (Single Elimination)',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textMuted,
                          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      final diagramMatches = isGroupStageKnockout
                          ? matches.where(isKnockoutMatch).toList()
                          : matches;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BracketDiagramScreen(
                            matches: diagramMatches,
                            tournamentId: widget.tournamentId,
                            bracketType: bracketType,
                            isReferee: widget.isReferee,
                            isReadOnly: isReadOnly,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_tree_rounded, size: 14),
                    label: Text(
                      isGroupStageKnockout || bracketType == 'group_stage_knockout'
                          ? 'Sơ đồ Knockout'
                          : isDoubleElimination || bracketType == 'double_elimination'
                              ? 'Sơ đồ loại kép'
                              : isRoundRobin || bracketType == 'round_robin'
                                  ? 'Sơ đồ Vòng tròn'
                                  : 'Sơ đồ Knockout',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // ── Search Input Field ──
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên người chơi hoặc tên đội...',
                hintStyle: TextStyle(fontSize: 12, color: colors.textMuted),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: colors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                isDense: true,
              ),
            ),
          ),

          // ── ROW 1: TRẠNG THÁI (Toggle Filter) ──
          _buildFilterRow(
            title: 'TRẠNG THÁI:',
            children: [
              RoundFilterPill(
                isSelected: _matchFilter == 'live',
                label: 'Trực tiếp',
                count: liveCount,
                onTap: () => setState(() => _matchFilter = _matchFilter == 'live' ? '' : 'live'),
              ),
              RoundFilterPill(
                isSelected: _matchFilter == 'scheduled',
                label: 'Chưa đấu',
                count: scheduledCount,
                onTap: () => setState(() => _matchFilter = _matchFilter == 'scheduled' ? '' : 'scheduled'),
              ),
              RoundFilterPill(
                isSelected: _matchFilter == 'completed',
                label: 'Đã xong',
                count: completedCount,
                onTap: () => setState(() => _matchFilter = _matchFilter == 'completed' ? '' : 'completed'),
              ),
            ],
          ),

          // ── ROW 2: NHÁNH THI ĐẤU (Double Elimination: Nhánh thắng / Nhánh thua Toggle) ──
          if (isDoubleElimination)
            _buildFilterRow(
              title: 'NHÁNH THI ĐẤU:',
              children: [
                RoundFilterPill(
                  isSelected: _selectedBranch == 'winners',
                  label: 'Nhánh thắng',
                  onTap: () => setState(() {
                    _selectedBranch = _selectedBranch == 'winners' ? '' : 'winners';
                    _selectedRound = 0;
                  }),
                ),
                RoundFilterPill(
                  isSelected: _selectedBranch == 'losers',
                  label: 'Nhánh thua',
                  onTap: () => setState(() {
                    _selectedBranch = _selectedBranch == 'losers' ? '' : 'losers';
                    _selectedRound = 0;
                  }),
                ),
              ],
            ),

          if (isGroupStageKnockout)
            _buildFilterRow(
              title: 'GIAI ĐOẠN:',
              children: [
                RoundFilterPill(
                  isSelected: _selectedBranch == 'group_stage',
                  label: 'Vòng bảng',
                  onTap: () => setState(() {
                    _selectedBranch = _selectedBranch == 'group_stage' ? '' : 'group_stage';
                    _selectedRound = 0;
                  }),
                ),
                RoundFilterPill(
                  isSelected: _selectedBranch == 'knockout',
                  label: 'Vòng Knockout',
                  onTap: () => setState(() {
                    _selectedBranch = _selectedBranch == 'knockout' ? '' : 'knockout';
                    _selectedGroup = '';
                    _selectedRound = 0;
                  }),
                ),
              ],
            ),

          // ── ROW 3: BẢNG ĐẤU (Group Stage only - filter out duplicate branch names) ──
          Builder(
            builder: (context) {
              final cleanGroups = availableGroups.where((g) {
                final lower = g.toLowerCase();
                return !lower.contains('winners') &&
                    !lower.contains('losers') &&
                    !lower.contains('grand') &&
                    !lower.contains('bracket');
              }).toList();

              if (cleanGroups.length <= 1 || _selectedBranch == 'knockout') return const SizedBox.shrink();

              return _buildFilterRow(
                title: 'BẢNG ĐẤU:',
                children: cleanGroups.map(
                  (group) => RoundFilterPill(
                    isSelected: _selectedGroup == group,
                    label: group,
                    onTap: () => setState(() {
                      _selectedGroup = _selectedGroup == group ? '' : group;
                      _selectedRound = 0;
                    }),
                  ),
                ).toList(),
              );
            },
          ),

          // ── ROW 4: VÒNG ĐẤU (Toggle Filter) ──
          if (availableRounds.length > 1)
            _buildFilterRow(
              title: 'VÒNG ĐẤU:',
              children: availableRounds.map((r) {
                final label = isRoundRobin ? 'Vòng $r' : _getRoundName(r, totalRounds);
                final count = groupScopedMatches.where((m) => m.round == r).length;
                return RoundFilterPill(
                  isSelected: _selectedRound == r,
                  label: label,
                  count: count,
                  onTap: () => setState(() => _selectedRound = _selectedRound == r ? 0 : r),
                );
              }).toList(),
            ),

          const SizedBox(height: 6),

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
                    'Không tìm thấy trận đấu phù hợp',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          for (final match in filteredMatches)
            MatchTableRow(
              match: match,
              isReadOnly: isReadOnly,
              totalRounds: totalRounds,
              tournamentId: widget.tournamentId,
              isReferee: widget.isReferee,
            ),
        ],
      );
  }

  Widget _buildFilterRow({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: children.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) => children[index],
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
      return winnersRounds.isEmpty ? 1 : winnersRounds.reduce((a, b) => a > b ? a : b);
    }
    return matches.map((m) => m.round).reduce((a, b) => a > b ? a : b);
  }

  String _getRoundName(int round, int totalRounds) {
    if (totalRounds <= 1) return 'Chung kết';
    if (round == totalRounds) return 'Chung kết';
    if (round == totalRounds - 1) return 'Bán kết';
    if (round == totalRounds - 2) return 'Tứ kết';
    return 'Vòng $round';
  }
}

class _BracketShimmerLoading extends StatelessWidget {
  const _BracketShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
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
            ),
          ),
        );
      },
    );
  }
}
