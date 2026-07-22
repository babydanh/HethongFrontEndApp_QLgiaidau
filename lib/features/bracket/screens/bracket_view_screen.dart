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
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_detail.dart';



class BracketViewScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isReferee;
  final bool isEmbedded;

  const BracketViewScreen({
    super.key,
    required this.tournamentId,
    this.isReferee = false,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<BracketViewScreen> createState() => _BracketViewScreenState();
}

class _BracketViewScreenState extends ConsumerState<BracketViewScreen>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController(Matrix4.identity()..scale(0.6)..translate(50.0, 50.0));
  late TabController _tabController;
  int _selectedRound = 0;
  String _matchFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Chỉ cho phép xoay ngang nếu không phải là Widget nhúng (Embedded)
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
    _transformationController.dispose();

    // Khóa lại màn hình dọc khi thoát khỏi Bracket (nếu không phải là Embedded)
    if (!widget.isEmbedded) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(bracketMatchesProvider(widget.tournamentId));
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
          debugPrint('DEBUG_BRACKET: Matches loaded count = ${matches.length}, tournamentId = ${widget.tournamentId}');
          for (var i = 0; i < matches.length && i < 3; i++) {
            debugPrint('  match[$i]: id=${matches[i].id}, rnd=${matches[i].round}, ord=${matches[i].matchNumber}, team1=${matches[i].team1Name}, team2=${matches[i].team2Name}');
          }
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
          final isDoubleElimination =
              bracketType == AppConstants.bracketDoubleElimination;
          final isGroupStageKnockout =
              bracketType == AppConstants.bracketGroupStageKnockout;

          if (isRoundRobin || isGroupStageKnockout) {
            return Column(
              children: [
                if (isGroupStageKnockout)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vòng bảng: các đội thi đấu vòng tròn tính điểm. ',
                              style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      _buildBracketViewer(
                        matches,
                        isRoundRobin,
                        isDoubleElimination,
                        auth.role == UserRole.viewer,
                      ),
                      StandingsView(matches: matches, tournamentId: widget.tournamentId),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CrossTableView(matches: matches, tournamentId: widget.tournamentId),
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
        error: (e, _) => Center(child: Text('Lỗi: $e')),
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

    // Tính tổng số vòng dựa trên bracket type
    final totalRounds = _computeTotalRounds(matches, bracketType);

    final validMatches = matches.where((m) {
      if (m.isLive || m.isCompleted) return true;
      // Hiển thị các trận ở Vòng 1 hoặc các trận đã xác định được ít nhất 1 đội đấu
      return m.round == 1 || m.team1Name != 'TBD' || m.team2Name != 'TBD';
    }).toList();

    // Tách các vòng đấu thực tế có trong danh sách trận đấu
    final availableRounds = validMatches.map((m) => m.round).toSet().toList()..sort();

    final filteredMatches = validMatches.where((m) {
      if (_selectedRound != 0 && m.round != _selectedRound) return false;
      if (_matchFilter == 'live') return m.isLive;
      if (_matchFilter == 'scheduled') return m.isScheduled;
      if (_matchFilter == 'completed') return m.isCompleted;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  colors.bgCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sơ đồ nhánh đấu Knockout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Xem trực quan phân nhánh đấu & sơ đồ thắng/thua.',
                        style: TextStyle(
                          fontSize: 11,
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  icon: const Icon(Icons.account_tree_rounded, size: 18),
                  label: const Text(
                    'Xem sơ đồ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── BỘ LỌC VÒNG ĐẤU (Redesigned Pills) ──
          if (availableRounds.length > 1) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'VÒNG ĐẤU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: availableRounds.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return RoundFilterPill(
                      isSelected: _selectedRound == 0,
                      label: 'Tất cả',
                      onTap: () => setState(() => _selectedRound = 0),
                    );
                  }
                  final r = availableRounds[index - 1];
                  final label = _getRoundName(r, totalRounds);
                  return RoundFilterPill(
                    isSelected: _selectedRound == r,
                    label: '$label (${validMatches.where((m) => m.round == r).length})',
                    onTap: () => setState(() => _selectedRound = r),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          // ── BỘ LỌC TRẠNG THÁI (Redesigned Pills) ──
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final items = [
                  ('all', 'Tất cả'),
                  ('live', 'Đang Live'),
                  ('scheduled', 'Sắp diễn ra'),
                  ('completed', 'Đã kết thúc'),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'DANH SÁCH TRẬN ĐẤU',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredMatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_esports_outlined,
                          size: 48,
                          color: colors.textMuted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không có trận đấu nào',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thử thay đổi bộ lọc để xem thêm kết quả',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
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



  Widget _buildBracketViewer(
    List<MatchModel> matches,
    bool isRoundRobin,
    bool isDoubleElimination,
    bool isReadOnly,
  ) {
    if (!isRoundRobin) {
      return Column(
        children: [
          _buildScheduleHeader(),
          Expanded(
            child: FocusableActionDetector(
              autofocus: true,
              shortcuts: {
                SingleActivator(LogicalKeyboardKey.arrowUp): const ScrollIntent(
                  direction: AxisDirection.up,
                ),
                SingleActivator(LogicalKeyboardKey.arrowDown): const ScrollIntent(
                  direction: AxisDirection.down,
                ),
                SingleActivator(LogicalKeyboardKey.arrowLeft): const ScrollIntent(
                  direction: AxisDirection.left,
                ),
                SingleActivator(LogicalKeyboardKey.arrowRight): const ScrollIntent(
                  direction: AxisDirection.right,
                ),
              },
              actions: {
                ScrollIntent: CallbackAction<ScrollIntent>(
                  onInvoke: (intent) {
                    final matrix = _transformationController.value.clone();
                    double dx = 0;
                    double dy = 0;
                    final step = 100.0;
                    if (intent.direction == AxisDirection.up) dy = step;
                    if (intent.direction == AxisDirection.down) dy = -step;
                    if (intent.direction == AxisDirection.left) dx = step;
                    if (intent.direction == AxisDirection.right) dx = -step;
                    // ignore: deprecated_member_use
                    matrix.translate(dx, dy);
                    _transformationController.value = matrix;
                    return null;
                  },
                ),
              },
              child: InteractiveViewer(
                alignment: Alignment.topLeft,
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(500),
                minScale: 0.1,
                maxScale: 2.0,
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: _buildHorizontalRounds(matches, isRoundRobin, isReadOnly),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Round Robin fallback
    return Column(
      children: [
        _buildScheduleHeader(),
        Expanded(
          child: FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        SingleActivator(LogicalKeyboardKey.arrowUp): const ScrollIntent(
          direction: AxisDirection.up,
        ),
        SingleActivator(LogicalKeyboardKey.arrowDown): const ScrollIntent(
          direction: AxisDirection.down,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): const ScrollIntent(
          direction: AxisDirection.left,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight): const ScrollIntent(
          direction: AxisDirection.right,
        ),
      },
      actions: {
        ScrollIntent: CallbackAction<ScrollIntent>(
          onInvoke: (intent) {
            final matrix = _transformationController.value.clone();
            double dx = 0;
            double dy = 0;
            final step = 100.0;
            if (intent.direction == AxisDirection.up) dy = step;
            if (intent.direction == AxisDirection.down) dy = -step;
            if (intent.direction == AxisDirection.left) dx = step;
            if (intent.direction == AxisDirection.right) dx = -step;
            // ignore: deprecated_member_use
            matrix.translate(dx, dy);
            _transformationController.value = matrix;
            return null;
          },
        ),
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.5,
        maxScale: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildHorizontalRounds(matches, isRoundRobin, isReadOnly),
        ),
      ),
      ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppTheme.primary, width: 4)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildScheduleHeader() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Lịch thi đấu vòng bảng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.info_outline, color: AppTheme.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: colors.bgCard,
                  title: Text('Cách tính điểm', style: TextStyle(color: colors.textPrimary)),
                  content: Text(
                    'Thắng: +${AppConstants.pointsForWin}đ  •  Thua: +${AppConstants.pointsForLoss}đ  •  Tie-breaker: Head-to-Head',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalRounds(List<MatchModel> matches, bool isRoundRobin, bool isReadOnly) {
    final roundMap = <int, List<MatchModel>>{};
    for (final match in matches) {
      roundMap.putIfAbsent(match.round, () => []).add(match);
    }
    final rounds = roundMap.keys.toList()..sort();

    return Row(
      crossAxisAlignment: isRoundRobin
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: rounds.map((round) {
        final roundMatches = roundMap[round]!;
        final roundName = isRoundRobin
            ? 'Vòng $round'
            : _getRoundName(round, rounds.length);
        return _buildRoundColumn(
          context,
          roundName,
          roundMatches,
          round,
          rounds.length,
          isRoundRobin,
          isReadOnly,
        );
      }).toList(),
    );
  }

  int _computeTotalRounds(List<MatchModel> matches, String bracketType) {
    if (matches.isEmpty) return 1;
    if (bracketType == AppConstants.bracketDoubleElimination) {
      // DE: chỉ tính số vòng từ nhánh thắng (winners)
      final winnersRounds = matches
          .where((m) => m.bracketPosition.bracket == 'winners')
          .map((m) => m.round);
      return winnersRounds.isEmpty ? 1 : winnersRounds.reduce((a, b) => a > b ? a : b);
    }
    // SE, RR: max round của tất cả match
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

  Widget _buildRoundColumn(
    BuildContext context,
    String roundName,
    List<MatchModel> matches,
    int round,
    int totalRounds,
    bool isRoundRobin,
    bool isReadOnly,
  ) {
    final double verticalMargin = isRoundRobin
        ? 16.0
        : 16.0 * (1 << (round - 1));
    final double cardWidth = (MediaQuery.of(context).size.width * 0.6)
        .clamp(220, 320);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 48),
      child: Column(
        mainAxisAlignment: isRoundRobin
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: EdgeInsets.only(bottom: verticalMargin),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Text(
                  roundName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'VS ${matches.length} trận',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ...matches.map((match) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: verticalMargin / 2),
              child: MatchCardDetail(
                match: match,
                isReferee: widget.isReferee,
                isReadOnly: isReadOnly,
                tournamentId: widget.tournamentId,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder for bracket view.
class _BracketShimmerLoading extends StatelessWidget {
  const _BracketShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.bgSurface,
      highlightColor: colors.bgCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerBox(width: 200, height: 16),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildShimmerBox(width: 80, height: 32, radius: 20),
                const SizedBox(width: 8),
                _buildShimmerBox(width: 100, height: 32, radius: 20),
                const SizedBox(width: 8),
                _buildShimmerBox(width: 90, height: 32, radius: 20),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double width, required double height, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
