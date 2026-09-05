import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ClubTournamentsScreen extends ConsumerStatefulWidget {
  final String clubId;
  const ClubTournamentsScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubTournamentsScreen> createState() =>
      _ClubTournamentsScreenState();
}

class _ClubTournamentsScreenState extends ConsumerState<ClubTournamentsScreen> {
  static const int _pageSize = 6;

  int _currentPageIndex = 0;
  bool _isLoading = false;
  bool _hasMore = false;
  int _totalTournaments = 0;

  String _statusFilter = 'ALL'; // ALL, IN_PROGRESS, UPCOMING, COMPLETED
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final Map<int, List<CommunityTournamentModel>> _pageTournaments = {};
  final Map<int, String?> _pageCursors = {0: null};

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetAndReload() {
    setState(() {
      _pageTournaments.clear();
      _pageCursors.clear();
      _pageCursors[0] = null;
      _currentPageIndex = 0;
      _hasMore = false;
    });
    _loadPage(0);
  }

  Future<void> _loadPage(int pageIndex) async {
    if (_pageTournaments.containsKey(pageIndex)) {
      setState(() => _currentPageIndex = pageIndex);
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      final result = await repo.getTournamentsPaged(
        widget.clubId,
        cursor: _pageCursors[pageIndex],
        limit: _pageSize,
        status: _statusFilter == 'ALL' ? null : _statusFilter,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );

      if (mounted) {
        setState(() {
          _pageTournaments[pageIndex] = result.tournaments;
          _hasMore = result.hasMore;
          _totalTournaments = result.total;
          if (result.nextCursor != null && result.nextCursor!.isNotEmpty) {
            _pageCursors[pageIndex + 1] = result.nextCursor;
          }
          _currentPageIndex = pageIndex;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final auth = ref.watch(authProvider);
    final membership = ref.watch(myCommunityMembershipProvider(widget.clubId));
    final member = membership.asData?.value;
    final isJoinedClubManager =
        member?.status.toUpperCase() == 'JOINED' &&
        ['OWNER', 'MODERATOR'].contains(member?.role.toUpperCase());
    final canCreateLite = auth.isAdmin || isJoinedClubManager;
    final canCreateAdvanced =
        auth.isAdmin || (auth.isOrganizer && isJoinedClubManager);

    final currentList = _pageTournaments[_currentPageIndex] ?? const [];

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        title: Text(l10n.clubTournamentsTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: canCreateLite || canCreateAdvanced
                ? () => _showTypeSheet(
                      context,
                      widget.clubId,
                      canCreateLite: canCreateLite,
                      canCreateAdvanced: canCreateAdvanced,
                    )
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Navigation Bar ──
          _buildFilterNavBar(colors),

          // ── Tournament Content List ──
          Expanded(
            child: _isLoading && currentList.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _resetAndReload(),
                    child: currentList.isEmpty
                        ? _buildEmpty(
                            context,
                            l10n,
                            canCreateLite: canCreateLite,
                            canCreateAdvanced: canCreateAdvanced,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: currentList.length,
                            itemBuilder: (ctx, i) =>
                                _buildCard(context, currentList[i]),
                          ),
                  ),
          ),

          // ── Cursor Pagination Navigation Bar ──
          if (currentList.isNotEmpty || _totalTournaments > 0)
            _buildCursorPaginationBar(colors),
        ],
      ),
    );
  }

  Widget _buildFilterNavBar(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search box
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (val) {
                _searchQuery = val;
                _resetAndReload();
              },
              style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm giải đấu theo tên...',
                hintStyle: TextStyle(fontSize: 12.5, color: colors.textMuted),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: colors.textMuted,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _resetAndReload();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Status Filter Chips (Nav Bar)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatusChip('ALL', 'Tất cả', colors),
                const SizedBox(width: 8),
                _buildStatusChip(
                  'IN_PROGRESS',
                  'Đang diễn ra',
                  colors,
                  isLive: true,
                ),
                const SizedBox(width: 8),
                _buildStatusChip('UPCOMING', 'Sắp diễn ra', colors),
                const SizedBox(width: 8),
                _buildStatusChip('COMPLETED', 'Đã kết thúc', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String key,
    String label,
    AppColorsExtension colors, {
    bool isLive = false,
  }) {
    final selected = _statusFilter == key;
    return InkWell(
      onTap: () {
        if (_statusFilter == key) return;
        setState(() => _statusFilter = key);
        _resetAndReload();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isLive ? colors.error : AppTheme.primary)
              : colors.bgSurface,
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

  Widget _buildCursorPaginationBar(AppColorsExtension colors) {
    final canGoPrev = _currentPageIndex > 0 && !_isLoading;
    final canGoNext =
        (_hasMore || _pageTournaments.containsKey(_currentPageIndex + 1)) &&
        !_isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          top: BorderSide(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _totalTournaments > 0
                    ? 'Trang ${_currentPageIndex + 1} • Tổng $_totalTournaments giải'
                    : 'Trang ${_currentPageIndex + 1}',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: canGoPrev
                    ? () => _loadPage(_currentPageIndex - 1)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: canGoPrev ? colors.bgSurface : colors.bgDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: canGoPrev
                          ? colors.border
                          : colors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 17,
                        color: canGoPrev
                            ? colors.textPrimary
                            : colors.textMuted.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Trước',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: canGoPrev
                              ? colors.textPrimary
                              : colors.textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: canGoNext
                    ? () => _loadPage(_currentPageIndex + 1)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: canGoNext ? AppTheme.primary : colors.bgDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: canGoNext
                          ? AppTheme.primary
                          : colors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sau',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: canGoNext
                              ? Colors.white
                              : colors.textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: canGoNext
                            ? Colors.white
                            : colors.textMuted.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    AppLocalizations l10n, {
    required bool canCreateLite,
    required bool canCreateAdvanced,
  }) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: context.colors.textMuted.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy giải đấu phù hợp'
                : l10n.clubTournamentsEmpty,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Hãy thử tìm kiếm với từ khóa khác'
                : 'Tạo giải đấu nội bộ nhanh hoặc giải đấu nâng cao cho CLB.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: context.colors.textMuted),
          ),
          const SizedBox(height: 20),
          if (canCreateLite || canCreateAdvanced)
            ElevatedButton.icon(
              onPressed: () => _showTypeSheet(
                context,
                widget.clubId,
                canCreateLite: canCreateLite,
                canCreateAdvanced: canCreateAdvanced,
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.clubTournamentsCreate),
            ),
        ],
      ),
    ),
  );

  Widget _buildCard(
    BuildContext context,
    CommunityTournamentModel t,
  ) {
    final name = t.name;
    final status = t.status;
    final date = t.startDate != null ? DateTime.tryParse(t.startDate!) : null;
    final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : '';
    final isLive = StatusHelper.isTournamentInProgress(status);
    final isLite = t.isLite;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLive
              ? context.colors.error.withValues(alpha: 0.3)
              : context.colors.border,
        ),
      ),
      child: InkWell(
        onTap: () => context.push(
          isLite ? '/lite-manage/${t.id}' : '/intro/${t.id}',
        ),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    (isLite
                            ? const Color(0xFFF59E0B)
                            : (isLive
                                  ? context.colors.error
                                  : context.colors.info))
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLite ? Icons.bolt_rounded : Icons.emoji_events_rounded,
                color: isLite
                    ? const Color(0xFFF59E0B)
                    : (isLive ? context.colors.error : context.colors.info),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isLite
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isLite
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                : const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLite
                                  ? Icons.bolt_rounded
                                  : Icons.workspace_premium_rounded,
                              size: 10,
                              color: isLite
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              isLite ? 'Giải Nhanh' : 'Nâng Cao',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: isLite
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (dateStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showTypeSheet(
    BuildContext context,
    String clubId, {
    required bool canCreateLite,
    required bool canCreateAdvanced,
  }) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.clubTournamentsChooseType,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.clubTournamentsChooseTypeHint,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 20),

            // Option 1: Super Quick nội bộ CLB (Lite)
            if (canCreateLite)
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/club/$clubId/create-tournament');
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFFF59E0B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.clubTournamentsLiteTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '30s',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.clubTournamentsLiteDescription,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Option 3: Giải Nâng Cao (Full) - Native Mobile Wizard
            if (canCreateAdvanced)
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/tournaments/create-advanced?communityId=$clubId',
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF3B82F6,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.clubTournamentsAdvancedTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l10n.clubTournamentsAdvancedBadge,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.clubTournamentsAdvancedCardDescription,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
