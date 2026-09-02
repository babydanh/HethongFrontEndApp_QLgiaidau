import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

class MatchesTab extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? selectedDivisionId;
  final String? selectedDivision;

  const MatchesTab({
    super.key,
    required this.tournamentId,
    this.selectedDivisionId,
    this.selectedDivision,
  });

  @override
  ConsumerState<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<MatchesTab> {
  String _statusFilter = 'all'; // all, live, scheduled, completed
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final matchesAsync = ref.watch(matchesProvider(widget.tournamentId));

    return matchesAsync.when(
      data: (allMatches) {
        // Filter by division if specified
        var matches = allMatches.where((m) {
          if (widget.selectedDivisionId != null &&
              widget.selectedDivisionId!.isNotEmpty) {
            final mDiv = m.tournamentConfig?['divisionId']?.toString() ??
                m.tournamentConfig?['tournamentDivisionId']?.toString();
            if (mDiv != null &&
                mDiv.isNotEmpty &&
                mDiv != widget.selectedDivisionId) {
              return false;
            }
          }
          return true;
        }).toList();

        // Filter by search query
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.trim().toLowerCase();
          matches = matches.where((m) {
            final t1 = m.team1Name.toLowerCase();
            final t2 = m.team2Name.toLowerCase();
            final court = m.court.toLowerCase();
            final referee = (m.refereeName ?? '').toLowerCase();
            return t1.contains(q) ||
                t2.contains(q) ||
                court.contains(q) ||
                referee.contains(q);
          }).toList();
        }

        // Filter by status
        if (_statusFilter == 'live') {
          matches = matches.where((m) => m.isLive).toList();
        } else if (_statusFilter == 'scheduled') {
          matches = matches
              .where((m) =>
                  !m.isLive &&
                  !m.isCompleted &&
                  m.status != AppConstants.matchCompleted)
              .toList();
        } else if (_statusFilter == 'completed') {
          matches = matches
              .where((m) =>
                  m.isCompleted || m.status == AppConstants.matchCompleted)
              .toList();
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Tìm trận đấu, tên đội hoặc VĐV...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: colors.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: colors.textMuted,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter chips: Tất cả / Đang diễn ra / Sắp tới / Đã kết thúc
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'Tất cả (${allMatches.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'live',
                            'Đang diễn ra (${allMatches.where((m) => m.isLive).length})',
                            isLive: true,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'scheduled',
                            'Sắp tới (${allMatches.where((m) => !m.isLive && !m.isCompleted && m.status != AppConstants.matchCompleted).length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'completed',
                            'Đã kết thúc (${allMatches.where((m) => m.isCompleted || m.status == AppConstants.matchCompleted).length})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (matches.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_rounded,
                          size: 48,
                          color: colors.textMuted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có trận đấu nào phù hợp',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lịch thi đấu sẽ được cập nhật khi ban tổ chức xếp lịch.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final match = matches[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LiveMatchCardV2(
                          match: match,
                          isLive: match.isLive,
                          isCompleted: match.isCompleted ||
                              match.status == AppConstants.matchCompleted,
                          onTap: () {
                            if (match.hasTeams) {
                              context.push('/live/${match.id}');
                            }
                          },
                        ),
                      );
                    },
                    childCount: matches.length,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          'Không thể tải danh sách trận đấu: $e',
          style: TextStyle(color: colors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {bool isLive = false}) {
    final selected = _statusFilter == key;
    final colors = context.colors;

    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isLive ? colors.error : AppTheme.primary)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? (isLive ? colors.error : AppTheme.primary)
                : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLive) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white : colors.error,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
