import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:graphview/GraphView.dart';
import 'package:app_quanly_giaidau/core/services/bracket_graph_service.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_detail.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_node_card.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_diagram_screen.dart';

// ── Bracket-tree walker (graphview-backed, used only by _buildBracketTree) ──
class SeparatedBuchheimWalkerAlgorithm implements Algorithm {
  final BuchheimWalkerAlgorithm _inner;
  final double separation;

  @override
  EdgeRenderer? get renderer => _inner.renderer;
  @override
  set renderer(EdgeRenderer? value) { _inner.renderer = value; }

  SeparatedBuchheimWalkerAlgorithm(BuchheimWalkerConfiguration config, TreeEdgeRenderer renderer, this.separation)
      : _inner = BuchheimWalkerAlgorithm(config, renderer);

  @override
  void init(Graph? graph) => _inner.init(graph);
  @override
  void setDimensions(double width, double height) => _inner.setDimensions(width, height);

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    final size = _inner.run(graph, shiftX, shiftY);
    if (graph != null && graph.nodes.isNotEmpty) {
      for (var node in graph.nodes) {
        final match = node.key?.value as MatchModel?;
        if (match != null) {
          if (match.bracketPosition.bracket == 'losers') { node.y += separation; }
          else if (['final', 'grand_final', 'grand_final_reset'].contains(match.bracketPosition.bracket)) { node.y += separation / 2; }
        }
      }
      double minX = double.infinity, minY = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity;
      for (var node in graph.nodes) {
        if (node.x < minX) minX = node.x;
        if (node.y < minY) minY = node.y;
      }
      for (var node in graph.nodes) {
        node.x -= minX; node.y -= minY;
        if (node.x + node.width > maxX) maxX = node.x + node.width;
        if (node.y + node.height > maxY) maxY = node.y + node.height;
      }
      return Size(maxX, maxY);
    }
    return size;
  }
}

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
  String _matchFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Mở khóa cho phép xoay ngang riêng ở màn hình Bracket
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transformationController.dispose();

    // Khóa lại màn hình dọc khi thoát khỏi Bracket
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesProvider(widget.tournamentId));
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
          final isDoubleElimination =
              bracketType == AppConstants.bracketDoubleElimination;

          if (isRoundRobin) {
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
                      _buildBracketViewer(
                        matches,
                        isRoundRobin,
                        isDoubleElimination,
                        auth.role == UserRole.viewer,
                      ),
                      _buildStandingsView(),
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
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

    final validMatches = matches.where((m) {
      if (m.isLive || m.isCompleted) return true;
      final hasTeams = m.team1Name != 'TBD' && m.team2Name != 'TBD';
      return m.scheduledTime != null && hasTeams;
    }).toList();

    final filteredMatches = validMatches.where((m) {
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'Tất cả (${validMatches.length})'),
                const SizedBox(width: 8),
                _filterChip('live', 'Đang Live (${validMatches.where((m) => m.isLive).length})'),
                const SizedBox(width: 8),
                _filterChip('scheduled', 'Sắp diễn ra (${validMatches.where((m) => m.isScheduled).length})'),
                const SizedBox(width: 8),
                _filterChip('completed', 'Đã kết thúc (${validMatches.where((m) => m.isCompleted).length})'),
              ],
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
                    child: Text(
                      'Không có trận đấu nào',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredMatches.length,
                    itemBuilder: (context, index) {
                      return _buildMatchTableRow(filteredMatches[index], isReadOnly);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final colors = context.colors;
    final isSelected = _matchFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : colors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _matchFilter = value;
          });
        }
      },
      selectedColor: AppTheme.primary,
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: BorderSide(color: isSelected ? Colors.transparent : colors.border),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildMatchTableRow(MatchModel match, bool isReadOnly) {
    final colors = context.colors;
    String roundName = _getRoundName(match.round, 4);

    String timeStr = 'Chưa xếp lịch';
    if (match.scheduledTime != null) {
      timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(match.scheduledTime!.toLocal());
    }

    Color statusColor;
    String statusLabel;
    if (match.isLive) {
      statusColor = colors.error;
      statusLabel = 'Đang thi đấu';
    } else if (match.isCompleted) {
      statusColor = colors.success;
      statusLabel = 'Đã kết thúc';
    } else {
      statusColor = AppTheme.primary;
      statusLabel = 'Chưa thi đấu';
    }

    final isT1Winner = match.isCompleted && match.winnerId == match.team1Id;
    final isT2Winner = match.isCompleted && match.winnerId == match.team2Id;

    final isT1Loser = match.isCompleted && match.winnerId == match.team2Id;
    final isT2Loser = match.isCompleted && match.winnerId == match.team1Id;

    int maxCols = 3; // default
    int? stw = match.setsToWin;
    if (stw == null && match.sportRules != null) {
      final rules = match.sportRules!;
      final stwVal = rules['setsToWin'] ?? rules['sets_to_win'];
      if (stwVal != null) {
        stw = int.tryParse(stwVal.toString());
      }
    }
    if (stw != null) {
      if (stw == 1) maxCols = 1;
      else if (stw == 2) maxCols = 3;
      else if (stw == 3) maxCols = 5;
    }

    Widget buildSetHeaders() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Expanded(child: SizedBox.shrink()),
          ...List.generate(maxCols, (index) {
            return Container(
              width: 28,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                'S${index + 1}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              'TỔNG',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      );
    }

    Widget buildTeamRow({
      required String name,
      required int score,
      required List<SetScore> sets,
      required bool isTeam1,
      required bool isWinner,
      required bool isLoser,
    }) {
      final nameColor = isLoser ? colors.textMuted : colors.textPrimary;
      final fontWeight = isWinner ? FontWeight.w800 : FontWeight.w600;
      final displayNames = name.split(RegExp(r'[-–\n]'));

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Overlapping circular avatars
            SizedBox(
              width: 38,
              height: 24,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      child: Text(
                        displayNames[0].trim().isNotEmpty ? displayNames[0].trim()[0].toUpperCase() : 'T',
                        style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (displayNames.length > 1 && displayNames[1].trim().isNotEmpty)
                    Positioned(
                      left: 12,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.blue.withValues(alpha: 0.15),
                        child: Text(
                          displayNames[1].trim()[0].toUpperCase(),
                          style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Team Name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: fontWeight,
                  color: nameColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Sets display
            ...List.generate(maxCols, (index) {
              String setScoreStr = '-';
              if (index < sets.length) {
                final setScore = isTeam1 ? sets[index].score1 : sets[index].score2;
                setScoreStr = '$setScore';
              }
              final hasScore = setScoreStr != '-';
              return Container(
                width: 28,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: hasScore ? colors.bgDark.withValues(alpha: 0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasScore ? colors.border.withValues(alpha: 0.5) : colors.border.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    setScoreStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: hasScore ? colors.textSecondary : colors.textMuted.withValues(alpha: 0.5),
                      fontWeight: hasScore ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            // Main score
            Container(
              width: 32,
              height: 28,
              decoration: BoxDecoration(
                color: isWinner
                    ? colors.success.withValues(alpha: 0.15)
                    : (match.isLive ? colors.error.withValues(alpha: 0.1) : colors.bgSurface),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isWinner
                      ? colors.success.withValues(alpha: 0.3)
                      : (match.isLive ? colors.error.withValues(alpha: 0.3) : colors.border),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isWinner
                        ? colors.success
                        : (match.isLive ? colors.error : colors.textPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: match.isLive ? colors.error.withValues(alpha: 0.6) : colors.border,
          width: match.isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (match.isLive)
            BoxShadow(
              color: colors.error.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            context.push('/live/${match.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Status and Round info)
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: match.isLive
                            ? [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colors.textPrimary.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        roundName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Set columns header
                buildSetHeaders(),
                const SizedBox(height: 4),

                // Teams list
                Column(
                  children: [
                    buildTeamRow(
                      name: match.team1Name,
                      score: match.score1,
                      sets: match.sets,
                      isTeam1: true,
                      isWinner: isT1Winner,
                      isLoser: isT1Loser,
                    ),
                    const SizedBox(height: 6),
                    buildTeamRow(
                      name: match.team2Name,
                      score: match.score2,
                      sets: match.sets,
                      isTeam1: false,
                      isWinner: isT2Winner,
                      isLoser: isT2Loser,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.border.withValues(alpha: 0.8)),
                const SizedBox(height: 8),

                // Footer (Court, Sport & Time metadata)
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.location_on_rounded, size: 12, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match.court.isNotEmpty ? match.court : 'Chưa xếp sân',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textMuted,
                          fontStyle: match.court.isNotEmpty ? null : FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isReferee && (match.isLive || match.isScheduled)) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tính điểm',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: match.isLive ? colors.error : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: match.isLive ? colors.error : AppTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetsDisplay(List<SetScore> sets, bool isTeam1) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: sets.map((set) {
        final score = isTeam1 ? set.score1 : set.score2;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 9,
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStandingsView() {
    final standingsAsync = ref.watch(standingsProvider(widget.tournamentId));

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu bảng xếp hạng'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text('Bảng Xếp Hạng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.info_outline, color: AppTheme.primary),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: context.colors.bgCard,
                          title: Text('Giải thích hệ số', style: TextStyle(color: context.colors.textPrimary)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• T: Số trận Thắng', style: TextStyle(color: context.colors.textSecondary)),
                              Text('• H: Số trận Hòa', style: TextStyle(color: context.colors.textSecondary)),
                              Text('• B: Số trận Bại (Thua)', style: TextStyle(color: context.colors.textSecondary)),
                              Text('• BT: Bàn Thắng (Số điểm ghi được)', style: TextStyle(color: context.colors.textSecondary)),
                              Text('• BB: Bàn Bại (Số điểm bị thủng lưới)', style: TextStyle(color: context.colors.textSecondary)),
                              Text('• HS: Hiệu số (BT - BB)', style: TextStyle(color: context.colors.textSecondary)),
                            ],
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
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                    dataTextStyle: TextStyle(color: context.colors.textSecondary),
                    columns: const [
                      DataColumn(label: Text('Hạng')),
                      DataColumn(label: Text('Đội')),
                      DataColumn(label: Text('Trận')),
                      DataColumn(label: Text('T')),
                      DataColumn(label: Text('H')),
                      DataColumn(label: Text('B')),
                      DataColumn(label: Text('BT')),
                      DataColumn(label: Text('BB')),
                      DataColumn(label: Text('HS')),
                      DataColumn(label: Text('Điểm')),
                    ],
                    rows: List.generate(standings.length, (index) {
                      final st = standings[index];
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            Text(
                              st.teamName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(Text('${st.played}')),
                          DataCell(Text('${st.won}')),
                          DataCell(Text('${st.drawn}')),
                          DataCell(Text('${st.lost}')),
                          DataCell(Text('${st.pointsFor}')),
                          DataCell(Text('${st.pointsAgainst}')),
                          DataCell(
                            Text(
                              '${st.pointDifference > 0 ? '+' : ''}${st.pointDifference}',
                            ),
                          ),
                          DataCell(
                            Text(
                              '${st.totalPoints}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildBracketViewer(
    List<MatchModel> matches,
    bool isRoundRobin,
    bool isDoubleElimination,
    bool isReadOnly,
  ) {
    if (!isRoundRobin) {
      return FocusableActionDetector(
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
            child: _buildBracketTree(matches, isReadOnly),
          ),
        ),
      );
    }

    // Round Robin fallback
    return FocusableActionDetector(
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

  Widget _buildBracketTree(List<MatchModel> matches, bool isReadOnly) {
    if (matches.isEmpty) return const SizedBox.shrink();

    // 1. Tính toán Vòng đấu tối đa để đặt tên
    int maxRoundWinners = 0;
    int maxRoundLosers = 0;
    int maxRoundMain = 0;
    
    for (final m in matches) {
      if (m.bracketPosition.bracket == 'winners' && m.round > maxRoundWinners) maxRoundWinners = m.round;
      if (m.bracketPosition.bracket == 'losers' && m.round > maxRoundLosers) maxRoundLosers = m.round;
      if (m.bracketPosition.bracket != 'winners' && m.bracketPosition.bracket != 'losers' && m.bracketPosition.bracket != 'final' && m.bracketPosition.bracket != 'grand_final' && m.round > maxRoundMain) {
        maxRoundMain = m.round;
      }
    }

    // Sử dụng BracketGraphService để tạo Graph (áp dụng cho cả Single và Double)
    final graph = BracketGraphService.buildSingleEliminationGraph(matches);

    final builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = (100)
      ..levelSeparation = (250)
      ..subtreeSeparation = (180)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT);

    return GraphView(
      graph: graph,
      algorithm: SeparatedBuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder), 2200),
      paint: Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.6) // Làm nét nối mềm mại hơn
        ..strokeWidth = 3 // Cho nét nối dày hơn một xíu
        ..style = PaintingStyle.stroke,
      builder: (Node node) {
        final match = node.key!.value as MatchModel;
        
        if (match.id == 'DUMMY_ROOT') {
          return const SizedBox.shrink();
        }

        Widget card = MatchNodeCard(
          match: match,
          isReferee: widget.isReferee,
          isReadOnly: isReadOnly,
          tournamentId: widget.tournamentId,
        );

        final bracket = match.bracketPosition.bracket;
        final round = match.round;
        String roundName = '';
        if (bracket == 'final' || bracket == 'grand_final') {
           roundName = 'Chung Kết Tổng';
        } else if (bracket == 'winners') {
           if (round == maxRoundWinners) roundName = 'Chung Kết Nhánh Thắng';
           else if (round == maxRoundWinners - 1) roundName = 'Bán Kết Nhánh Thắng';
           else if (round == maxRoundWinners - 2) roundName = 'Tứ Kết Nhánh Thắng';
           else roundName = 'Vòng $round Nhánh Thắng';
        } else if (bracket == 'losers') {
           if (round == maxRoundLosers) roundName = 'Chung Kết Nhánh Thua';
           else if (round == maxRoundLosers - 1) roundName = 'Bán Kết Nhánh Thua';
           else if (round == maxRoundLosers - 2) roundName = 'Tứ Kết Nhánh Thua';
           else roundName = 'Vòng $round Nhánh Thua';
        } else {
           if (round == maxRoundMain) roundName = 'Chung Kết';
           else if (round == maxRoundMain - 1) roundName = 'Bán Kết';
           else if (round == maxRoundMain - 2) roundName = 'Tứ Kết';
           else roundName = 'Vòng $round';
        }

        if (roundName.isNotEmpty) {
          card = Stack(
            clipBehavior: Clip.none,
            children: [
              card,
              Positioned(
                top: -36,
                left: -10,
                right: -10,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      roundName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return card;
      },
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
            ? 'Lượt $round'
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

  String _getRoundName(int round, int totalRounds) {
    if (round == totalRounds) return 'Chung kết';
    if (round == totalRounds - 1) return 'Bán kết';
    if (round == totalRounds - 2) return 'Tứ kết';
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

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 48),
      child: Column(
        mainAxisAlignment: isRoundRobin
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: EdgeInsets.only(bottom: verticalMargin),
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              roundName.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
                letterSpacing: 1.2,
              ),
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
