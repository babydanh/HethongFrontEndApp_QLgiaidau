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

class BracketViewScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? divisionId;
  final bool isReferee;
  final bool isEmbedded;

  const BracketViewScreen({
    super.key,
    required this.tournamentId,
    this.divisionId,
    this.isReferee = false,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<BracketViewScreen> createState() => _BracketViewScreenState();
}

class _BracketViewScreenState extends ConsumerState<BracketViewScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedRound = 0;
  String _matchFilter = 'all';
  String _selectedBranch = 'all';
  String _selectedGroup = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
    final tournament = tournamentAsync.value;
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        elevation: 0,
        leading: widget.isEmbedded
            ? const SizedBox.shrink()
            : IconButton(
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
        actions: (!widget.isEmbedded && auth.role != UserRole.admin)
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
      body: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
            );
          }

          final bracketType =
              tournamentAsync.value?.bracketType ??
              AppConstants.bracketSingleElimination;
          final isRoundRobin = bracketType == AppConstants.bracketRoundRobin;
          final isGroupStageKnockout =
              bracketType == AppConstants.bracketGroupStageKnockout;

          if (isRoundRobin || isGroupStageKnockout) {
            return Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: context.colors.textSecondary,
                  indicatorColor: AppTheme.primary,
                  tabs: const [
                    Tab(text: 'Lịch thi đấu'),
                    Tab(text: 'Bảng xếp hạng'),
                    Tab(text: 'Bảng chéo'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildKnockoutMatchTable(
                        matches,
                        bracketType,
                        auth.role == UserRole.viewer,
                        auth.role == UserRole.admin || widget.isReferee,
                      ),
                      StandingsView(
                        matches: matches,
                        tournamentId: widget.tournamentId,
                        divisionId: widget.divisionId,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CrossTableView(
                          matches: matches,
                          tournamentId: widget.tournamentId,
                          divisionId: widget.divisionId,
                        ),
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
      return !(t1 == 'TBD' && t2 == 'TBD' && !m.isLive && !m.isCompleted && m.round > 1);
    }).toList();

    // Available branches/groups/rounds
    final availableRounds = validMatches.map((m) => m.round).toSet().toList()..sort();
    final availableGroups = validMatches
        .map((m) => m.groupName)
        .where((g) => g != null && g.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();

    // Filter logic
    final filteredMatches = validMatches.where((m) {
      // Branch filter
      if (_selectedBranch != 'all') {
        if (_selectedBranch == 'winners' && m.bracketPosition.bracket != 'winners') return false;
        if (_selectedBranch == 'losers' && m.bracketPosition.bracket != 'losers') return false;
        if (_selectedBranch == 'grand_final' &&
            m.bracketPosition.bracket != 'grand_final' &&
            m.bracketPosition.bracket != 'grand_final_reset') {
          return false;
        }
        if (_selectedBranch == 'group_stage' && (m.stageName != null && m.stageName!.contains('Knockout'))) return false;
        if (_selectedBranch == 'knockout' && (m.stageName != null && m.stageName!.contains('Bảng'))) return false;
      }
      // Group filter
      if (_selectedGroup != 'all' && m.groupName != _selectedGroup) return false;
      // Round filter
      if (_selectedRound != 0 && m.round != _selectedRound) return false;
      // Status filter
      if (_matchFilter == 'live' && !m.isLive) return false;
      if (_matchFilter == 'scheduled' && !m.isScheduled) return false;
      if (_matchFilter == 'completed' && !m.isCompleted) return false;

      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sơ đồ phân nhánh thi đấu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Xem nhánh thắng/thua & hình cây giải đấu',
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BracketDiagramScreen(
                            matches: matches,
                            tournamentId: widget.tournamentId,
                            bracketType: bracketType,
                            isReferee: widget.isReferee,
                            isReadOnly: isReadOnly,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_tree_rounded, size: 14),
                    label: const Text(
                      'Sơ đồ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // ── FILTER ROW 1: Branch / Format Specific Filter ──
          if (isDoubleElimination) ...[
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  RoundFilterPill(
                    isSelected: _selectedBranch == 'all',
                    label: 'Tất cả nhánh',
                    onTap: () => setState(() => _selectedBranch = 'all'),
                  ),
                  const SizedBox(width: 6),
                  RoundFilterPill(
                    isSelected: _selectedBranch == 'winners',
                    label: 'Nhánh thắng',
                    onTap: () => setState(() => _selectedBranch = 'winners'),
                  ),
                  const SizedBox(width: 6),
                  RoundFilterPill(
                    isSelected: _selectedBranch == 'losers',
                    label: 'Nhánh thua',
                    onTap: () => setState(() => _selectedBranch = 'losers'),
                  ),
                  const SizedBox(width: 6),
                  RoundFilterPill(
                    isSelected: _selectedBranch == 'grand_final',
                    label: 'Chung kết',
                    onTap: () => setState(() => _selectedBranch = 'grand_final'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (isGroupStageKnockout) ...[
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  RoundFilterPill(
                    isSelected: _selectedBranch == 'all',
                    label: 'Tất cả giai đoạn',
                    onTap: () => setState(() => _selectedBranch = 'all'),
                  ),
                  const SizedBox(width: 6),
                  RoundFilterPill(
                    isSelected: _selectedBranch == 'group_stage',
                    label: 'Vòng bảng',
                    onTap: () => setState(() => _selectedBranch = 'group_stage'),
                  ),
                  const SizedBox(width: 6),
                  RoundFilterPill(
                    isSelected: _selectedBranch == 'knockout',
                    label: 'Vòng Knockout',
                    onTap: () => setState(() => _selectedBranch = 'knockout'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── FILTER ROW 2: Groups Filter (Bảng A, Bảng B...) ──
          if (availableGroups.length > 1) ...[
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: availableGroups.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return RoundFilterPill(
                      isSelected: _selectedGroup == 'all',
                      label: 'Tất cả bảng',
                      onTap: () => setState(() => _selectedGroup = 'all'),
                    );
                  }
                  final group = availableGroups[index - 1];
                  return RoundFilterPill(
                    isSelected: _selectedGroup == group,
                    label: group,
                    onTap: () => setState(() => _selectedGroup = group),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── FILTER ROW 3: Rounds Filter (Vòng 1, Vòng 2, Tứ kết...) ──
          if (availableRounds.length > 1) ...[
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: availableRounds.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return RoundFilterPill(
                      isSelected: _selectedRound == 0,
                      label: 'Tất cả vòng',
                      onTap: () => setState(() => _selectedRound = 0),
                    );
                  }
                  final r = availableRounds[index - 1];
                  final label = isRoundRobin ? 'Vòng $r' : _getRoundName(r, totalRounds);
                  return RoundFilterPill(
                    isSelected: _selectedRound == r,
                    label: '$label (${validMatches.where((m) => m.round == r).length})',
                    onTap: () => setState(() => _selectedRound = r),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── FILTER ROW 4: Status Filter (Tất cả, LIVE, Sắp đấu, Đã xong) ──
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final items = [
                  ('all', 'Tất cả trạng thái'),
                  ('live', '🔴 LIVE'),
                  ('scheduled', '⏰ Sắp diễn ra'),
                  ('completed', '✅ Đã kết thúc'),
                ];
                final item = items[index];
                return RoundFilterPill(
                  isSelected: _matchFilter == item.$1,
                  label: item.$2,
                  onTap: () => setState(() => _matchFilter = item.$1),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ── MATCHES LIST ──
          Expanded(
            child: filteredMatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_esports_outlined,
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
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredMatches.length,
                    itemBuilder: (context, index) {
                      return MatchTableRow(
                        match: filteredMatches[index],
                        isReadOnly: isReadOnly,
                        totalRounds: totalRounds,
                        tournamentId: widget.tournamentId,
                        isReferee: widget.isReferee,
                      );
                    },
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
    final fromEnd = totalRounds - round;
    if (fromEnd == 0) return 'Chung kết';
    if (fromEnd == 1) return 'Bán kết';
    if (fromEnd == 2) return 'Tứ kết';
    if (fromEnd == 3) return 'Vòng 1/8';
    if (fromEnd == 4) return 'Vòng 1/16';
    if (fromEnd == 5) return 'Vòng 1/32';
    if (fromEnd >= 6) return 'Vòng 1/${1 << fromEnd}';
    return 'Vòng $round';
  }
}

class _BracketShimmerLoading extends StatelessWidget {
  const _BracketShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.bgSurface,
      highlightColor: colors.bgCard,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(
            4,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
