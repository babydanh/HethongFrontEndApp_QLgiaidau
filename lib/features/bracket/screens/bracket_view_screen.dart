import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';

import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_detail.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_diagram_screen.dart';



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
                      _buildStandingsView(matches),
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
          const SizedBox(height: 16),
          // ── BỘ LỌC VÒNG ĐẤU ──
          if (availableRounds.length > 1) ...[
            Text(
              'BỘ LỌC VÒNG ĐẤU',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _roundChip(0, 'Tất cả các vòng (${validMatches.length})'),
                  const SizedBox(width: 6),
                  ...availableRounds.map((r) {
                    final label = _getRoundName(r, totalRounds);
                    final count = validMatches.where((m) => m.round == r).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _roundChip(r, '$label ($count)'),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // ── BỘ LỌC TRẠNG THÁI ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'Tất cả trạng thái (${validMatches.length})'),
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
                      return _buildMatchTableRow(filteredMatches[index], isReadOnly, totalRounds);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _selectedRound = 0;

  Widget _roundChip(int roundValue, String label) {
    final colors = context.colors;
    final isSelected = _selectedRound == roundValue;
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
            _selectedRound = roundValue;
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

  Widget _buildMatchTableRow(MatchModel match, bool isReadOnly, int totalRounds) {
    final colors = context.colors;

    // Xác định tên vòng theo bracket branch
    final branch = match.bracketPosition.bracket;
    String roundName;
    if (branch == 'grand_final' || branch == 'grand_final_reset') {
      roundName = 'Chung kết tổng';
    } else if (branch == 'losers') {
      roundName = 'Nhánh thua Vòng ${match.round}';
    } else {
      roundName = _getRoundName(match.round, totalRounds);
    }

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
          color: match.isLive ? AppTheme.primary : colors.border,
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
              color: AppTheme.primary.withValues(alpha: 0.08),
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

  Widget _buildStandingsView(List<MatchModel> matches) {
    final standingsAsync = ref.watch(standingsProvider(widget.tournamentId));
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final tournament = tournamentAsync.value;
    final isGsknockout = tournament?.bracketType == AppConstants.bracketGroupStageKnockout;

    // Map tên đội với groupName từ matches
    final teamGroupMap = <String, String>{};
    for (final m in matches) {
      if (m.groupName != null && m.groupName!.isNotEmpty) {
        if (m.team1Name.isNotEmpty && m.team1Name != 'TBD') {
          teamGroupMap[m.team1Name] = m.groupName!;
        }
        if (m.team2Name.isNotEmpty && m.team2Name != 'TBD') {
          teamGroupMap[m.team2Name] = m.groupName!;
        }
      }
    }

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu bảng xếp hạng'));
        }

        // Nhóm standings theo Group
        final groupedStandings = <String, List<dynamic>>{};
        for (final st in standings) {
          final groupName = (st.group.isNotEmpty ? st.group : teamGroupMap[st.teamName]) ?? 'Bảng A';
          groupedStandings.putIfAbsent(groupName, () => []).add(st);
        }

        final groupsList = groupedStandings.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bảng Xếp Hạng Vòng Tròn (${groupsList.length} Bảng)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                          return Dialog.fullscreen(
                            backgroundColor: context.colors.bgDark,
                            child: Scaffold(
                              backgroundColor: context.colors.bgDark,
                              appBar: AppBar(
                                backgroundColor: context.colors.bgDark,
                                elevation: 0,
                                leading: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                                    Navigator.pop(ctx);
                                  },
                                ),
                                title: const Text('Bảng Xếp Hạng Vòng Tròn (Toàn Màn Hình)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              body: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: groupsList.length,
                                itemBuilder: (context, gIdx) {
                                  final gName = groupsList[gIdx];
                                  final gStandings = groupedStandings[gName]!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          gName.toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          columns: const [
                                            DataColumn(label: Text('Hạng')),
                                            DataColumn(label: Text('Đội VĐV')),
                                            DataColumn(label: Text('Trận')),
                                            DataColumn(label: Text('T')),
                                            DataColumn(label: Text('B')),
                                            DataColumn(label: Text('BT')),
                                            DataColumn(label: Text('BB')),
                                            DataColumn(label: Text('HS')),
                                            DataColumn(label: Text('Điểm')),
                                          ],
                                          rows: List.generate(gStandings.length, (index) {
                                            final st = gStandings[index];
                                            return DataRow(
                                              cells: [
                                                DataCell(Text('${index + 1}')),
                                                DataCell(Text(st.teamName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                                DataCell(Text('${st.played}')),
                                                DataCell(Text('${st.won}')),
                                                DataCell(Text('${st.lost}')),
                                                DataCell(Text('${st.pointsFor}')),
                                                DataCell(Text('${st.pointsAgainst}')),
                                                DataCell(Text('${st.pointDifference > 0 ? '+' : ''}${st.pointDifference}')),
                                                DataCell(Text('${st.totalPoints}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary))),
                                              ],
                                            );
                                          }),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.screen_rotation_rounded, size: 15),
                    label: const Text('Xoay ngang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: groupsList.length,
                itemBuilder: (context, gIdx) {
                  final gName = groupsList[gIdx];
                  final gStandings = groupedStandings[gName]!;
                  final advancingCount = isGsknockout ? (gStandings.length / 2).ceil() : 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: context.colors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                            border: Border(bottom: BorderSide(color: context.colors.border)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 18, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                gName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${gStandings.length} Đội',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                              fontSize: 12,
                            ),
                            dataTextStyle: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                            ),
                            columns: const [
                              DataColumn(label: Text('Hạng')),
                              DataColumn(label: Text('Đội VĐV')),
                              DataColumn(label: Text('Trận')),
                              DataColumn(label: Text('T')),
                              DataColumn(label: Text('B')),
                              DataColumn(label: Text('BT')),
                              DataColumn(label: Text('BB')),
                              DataColumn(label: Text('HS')),
                              DataColumn(label: Text('Điểm')),
                            ],
                            rows: List.generate(gStandings.length, (index) {
                              final st = gStandings[index];
                              final isAdvancing = isGsknockout && index < advancingCount;
                              return DataRow(
                                color: isAdvancing
                                    ? WidgetStateProperty.all(context.colors.success.withValues(alpha: 0.06))
                                    : null,
                                cells: [
                                  DataCell(
                                    isAdvancing
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: context.colors.success.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: context.colors.success.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: context.colors.success,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : Text('${index + 1}'),
                                  ),
                                  DataCell(
                                    Text(
                                      st.teamName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataCell(Text('${st.played}')),
                                  DataCell(Text('${st.won}')),
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
                                      style: const TextStyle(
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
                      ],
                    ),
                  );
                },
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
                  '⚔️ ${matches.length} trận',
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
