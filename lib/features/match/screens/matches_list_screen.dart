import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/cursor_pagination.dart';
import 'package:app_quanly_giaidau/core/utils/match_status_filter.dart';
import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';
import 'dart:async';
import 'package:intl/intl.dart';

/// Trang hiển thị danh sách trận đấu với filter và search.
class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen>
    with WidgetsBindingObserver {
  static const _pageSize = 20;
  static const _loadMoreDistance = 600.0;
  static const _minVisibleBeforeStop = 6;
  static const _maxFillLoads = 3;
  static const _searchDebounce = Duration(milliseconds: 400);
  static const _backgroundRefresh = Duration(minutes: 2);

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  MatchStatusFilter _status = MatchStatusFilter.all;
  String _selectedSport = '';
  DateTimeRange? _selectedDateRange;
  String _selectedLocation = '';

  List<MatchModel> _matches = [];
  List<MatchModel> _filteredMatches = [];
  String? _nextCursor;
  bool _isLoadingFirst = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  String? _error;
  int _version = 0;
  int _pagesLoaded = 0;
  int _fillLoads = 0;
  Timer? _refreshTimer;
  Timer? _searchTimer;

  String _statusLabel(MatchStatusFilter status) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      MatchStatusFilter.live => l10n.matchesFilterOngoing,
      MatchStatusFilter.scheduled => l10n.matchesFilterScheduled,
      MatchStatusFilter.completed => l10n.matchesFilterEnded,
      MatchStatusFilter.all => l10n.matchesStatusAll,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    unawaited(_reload(clear: true));
    _refreshTimer = Timer.periodic(_backgroundRefresh, (_) => _refreshQuietly());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _searchTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshQuietly();
  }

  /// Làm mới nền chỉ khi người dùng chưa cuộn qua trang đầu, để không làm
  /// nhảy danh sách đã tải thêm.
  void _refreshQuietly() {
    if (_pagesLoaded <= 1 && !_isLoadingFirst) unawaited(_reload(clear: false));
  }

  void _onSearchChanged() {
    setState(() {}); // nút xoá ô tìm
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () => unawaited(_reload(clear: true)));
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreDistance) {
      unawaited(_loadMore());
    }
  }

  String? _categoryId() {
    if (_selectedSport.isEmpty) return null;
    final categories = ref.read(categoriesProvider).asData?.value;
    for (final category in categories ?? const <CategoryModel>[]) {
      if (category.slug == _selectedSport) return category.id;
    }
    return null;
  }

  Future<CursorPage<MatchModel>> _fetchPage(String? cursor) {
    final repo = ref.read(matchRepositoryProvider);
    final query = _searchController.text.trim();
    final range = _selectedDateRange;
    final categoryId = _categoryId();
    return fetchCursorPageWhere<MatchModel>(
      startCursor: cursor,
      accept: isRenderablePublicMatch,
      fetchPage: (pageCursor) async {
        final result = await repo.getPublicMatchesPaged(
          cursor: pageCursor,
          limit: _pageSize,
          search: query.isEmpty ? null : query,
          categoryId: categoryId,
          status: _status.toServerParam(),
          startDate: range?.start,
          endDate: range?.end,
          trigger: 'matches_list',
        );
        return (items: result.matches, nextCursor: result.nextCursor);
      },
    );
  }

  /// Tải lại từ trang đầu. [clear] xoá danh sách cũ trước (đổi bộ lọc); không
  /// clear (làm mới) thì giữ danh sách đang hiển thị, lỗi cũng không xoá nó.
  Future<void> _reload({required bool clear}) async {
    final version = ++_version;
    setState(() {
      if (clear) {
        _matches = [];
        _filteredMatches = [];
        _nextCursor = null;
        _pagesLoaded = 0;
      }
      _isLoadingFirst = _matches.isEmpty;
      _isLoadingMore = false;
      _loadMoreFailed = false;
      _error = null;
      _fillLoads = 0;
    });
    try {
      final page = await _fetchPage(null);
      if (!mounted || version != _version) return;
      setState(() {
        _matches = page.items;
        _nextCursor = page.nextCursor;
        _pagesLoaded = 1;
        _isLoadingFirst = false;
        _applyFilters();
      });
      _fillIfShort();
    } catch (_) {
      if (!mounted || version != _version) return;
      setState(() {
        _isLoadingFirst = false;
        _error = _matches.isEmpty
            ? 'Không thể tải danh sách trận đấu. Hãy thử lại.'
            : null;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoadingMore || _isLoadingFirst) return;
    final version = _version;
    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });
    try {
      final page = await _fetchPage(cursor);
      if (!mounted || version != _version) return;
      final known = {for (final match in _matches) match.id};
      setState(() {
        _matches = [
          ..._matches,
          ...page.items.where((match) => !known.contains(match.id)),
        ];
        _nextCursor = page.nextCursor;
        _pagesLoaded++;
        _isLoadingMore = false;
        _applyFilters();
      });
      _fillIfShort();
    } catch (_) {
      if (!mounted || version != _version) return;
      setState(() {
        _isLoadingMore = false;
        _loadMoreFailed = true;
      });
    }
  }

  /// Bộ lọc sân/môn chạy ở client nên một trang có thể bị lọc gần hết: tải
  /// thêm vài trang để màn không trống, có trần để không chạy mãi.
  void _fillIfShort() {
    if (_nextCursor != null &&
        _filteredMatches.length < _minVisibleBeforeStop &&
        _fillLoads < _maxFillLoads) {
      _fillLoads++;
      unawaited(_loadMore());
    }
  }

  /// Lọc ở client cho phần server không lọc được (môn, sân).
  void _applyFilters() {
    _filteredMatches = _matches.where((match) {
      if (_selectedSport.isNotEmpty && match.sportKey != _selectedSport) {
        return false;
      }
      if (_selectedLocation.isNotEmpty &&
          !match.court.toLowerCase().contains(_selectedLocation.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      _selectedDateRange = picked;
      await _reload(clear: true);
    }
  }

  void _toggleStatus(MatchStatusFilter status) {
    _status = _status == status ? MatchStatusFilter.all : status;
    unawaited(_reload(clear: true));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.matchesTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
            onPressed: () => _reload(clear: false),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(colors),
          _buildFilterRow(colors),
          _buildActiveFilters(colors),
          Expanded(child: _buildContent(colors)),
        ],
      ),
    );
  }

  Widget _buildContent(AppColorsExtension colors) {
    if (_isLoadingFirst) return _buildRowsSkeleton(6);
    if (_error != null) return _buildError(colors);
    if (_filteredMatches.isEmpty) {
      return _isLoadingMore ? _buildRowsSkeleton(4) : _buildEmpty(colors);
    }
    return _buildGroupedList(colors);
  }

  Widget _buildRowsSkeleton(int count) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    children: [for (var i = 0; i < count; i++) const MatchRowSkeleton()],
  );

  Widget _buildSearchBar(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: l10n.matchesSearchHint,
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.textMuted,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: colors.textMuted,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Status Pills: chỉ các trạng thái mà trận thật sự có.
            _StatusFilterPill(
              label: l10n.matchesFilterOngoing,
              isSelected: _status == MatchStatusFilter.live,
              activeBgColor: const Color(0xFFEBF5FF),
              activeTextColor: const Color(0xFF1E56A0),
              onTap: () => _toggleStatus(MatchStatusFilter.live),
            ),
            const SizedBox(width: 8),
            _StatusFilterPill(
              label: l10n.matchesFilterScheduled,
              isSelected: _status == MatchStatusFilter.scheduled,
              activeBgColor: const Color(0xFFFFF5E6),
              activeTextColor: const Color(0xFF995C00),
              onTap: () => _toggleStatus(MatchStatusFilter.scheduled),
            ),
            const SizedBox(width: 8),
            _StatusFilterPill(
              label: l10n.matchesFilterEnded,
              isSelected: _status == MatchStatusFilter.completed,
              activeBgColor: const Color(0xFFF1F5F9),
              activeTextColor: const Color(0xFF64748B),
              onTap: () => _toggleStatus(MatchStatusFilter.completed),
            ),
            const SizedBox(width: 12),
            // Sport filter
            _FilterChip(
              label: _selectedSport.isEmpty
                  ? l10n.matchesFilterSport
                  : l10n.sportDisplayName(_selectedSport),
              icon: Icons.sports_rounded,
              isActive: _selectedSport.isNotEmpty,
              colors: colors,
              onTap: () => _showSportPicker(colors),
            ),
            const SizedBox(width: 8),
            // Date filter
            _FilterChip(
              label: _selectedDateRange != null
                  ? DateFormat('dd/MM').format(_selectedDateRange!.start)
                  : l10n.matchesFilterDate,
              icon: Icons.calendar_month_rounded,
              isActive: _selectedDateRange != null,
              colors: colors,
              onTap: _pickDateRange,
            ),
            const SizedBox(width: 8),
            // Location filter
            _FilterChip(
              label: _selectedLocation.isEmpty
                  ? l10n.matchesFilterLocation
                  : _selectedLocation,
              icon: Icons.location_on_rounded,
              isActive: _selectedLocation.isNotEmpty,
              colors: colors,
              onTap: () => _showLocationInput(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(AppColorsExtension colors) {
    final chips = <Widget>[];
    if (_selectedSport.isNotEmpty) {
      chips.add(
        _buildActiveChip(
          AppLocalizations.of(context)!.sportDisplayName(_selectedSport),
          () {
            _selectedSport = '';
            unawaited(_reload(clear: true));
          },
          colors,
        ),
      );
    }
    if (_status != MatchStatusFilter.all) {
      chips.add(
        _buildActiveChip(
          _statusLabel(_status),
          () => _toggleStatus(_status),
          colors,
        ),
      );
    }
    if (_selectedDateRange != null) {
      final fmt = DateFormat('dd/MM');
      chips.add(
        _buildActiveChip(
          '${fmt.format(_selectedDateRange!.start)} - ${fmt.format(_selectedDateRange!.end)}',
          () {
            _selectedDateRange = null;
            unawaited(_reload(clear: true));
          },
          colors,
        ),
      );
    }
    if (_selectedLocation.isNotEmpty) {
      chips.add(
        _buildActiveChip(
          _selectedLocation,
          () => setState(() {
            _selectedLocation = '';
            _applyFilters();
          }),
          colors,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }

  Widget _buildActiveChip(
    String label,
    VoidCallback onRemove,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.info,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: colors.info),
          ),
        ],
      ),
    );
  }

  void _showSportPicker(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.matchesPickSport,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSportOption(ctx, colors, '', l10n.matchesFilterAll, null),
            ...[
              AppConstants.sportPickleball,
              AppConstants.sportBadminton,
              AppConstants.sportTennis,
              AppConstants.sportTableTennis,
              AppConstants.sportFootball,
            ].map(
              (sportKey) => _buildSportOption(
                ctx,
                colors,
                sportKey,
                l10n.sportDisplayName(sportKey),
                sportKey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportOption(
    BuildContext ctx,
    AppColorsExtension colors,
    String value,
    String label,
    String? sportKey,
  ) {
    final isSelected = _selectedSport == value;
    return ListTile(
      leading: Icon(
        sportKey != null
            ? Icons.sports_tennis_rounded
            : Icons.all_inclusive_rounded,
        color: isSelected ? colors.info : colors.textMuted,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? colors.info : colors.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: colors.info)
          : null,
      onTap: () {
        _selectedSport = value;
        unawaited(_reload(clear: true));
        Navigator.pop(ctx);
      },
    );
  }

  void _showLocationInput(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _selectedLocation);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.matchesEnterLocation,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.matchesLocationHint,
            hintStyle: TextStyle(color: colors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.matchesCancel,
              style: TextStyle(color: colors.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _selectedLocation = controller.text.trim();
                _applyFilters();
              });
              Navigator.pop(ctx);
            },
            child: Text(l10n.matchesApply),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    // Group matches by tournament name
    final grouped = <String, List<MatchModel>>{};
    for (final m in _filteredMatches) {
      final key = m.tournamentName ?? l10n.matchesOther;
      grouped.putIfAbsent(key, () => []).add(m);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final hasFooter = _isLoadingMore || _loadMoreFailed;

    return RefreshIndicator(
      onRefresh: () => _reload(clear: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sortedKeys.length + (hasFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == sortedKeys.length) return _buildListFooter(l10n);
          final tournamentName = sortedKeys[index];
          final matches = grouped[tournamentName]!;
          return _buildTournamentGroup(tournamentName, matches, colors);
        },
      ),
    );
  }

  Widget _buildListFooter(AppLocalizations l10n) {
    if (_loadMoreFailed) {
      return Center(
        child: TextButton(
          onPressed: _loadMore,
          child: Text(l10n.matchesRetry),
        ),
      );
    }
    return const Column(children: [MatchRowSkeleton(), MatchRowSkeleton()]);
  }

  Widget _buildTournamentGroup(
    String tournamentName,
    List<MatchModel> matches,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 16, color: colors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tournamentName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                l10n.matchesCount(matches.length),
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ],
          ),
        ),
        ...matches.map((m) => _buildMatchCard(m, colors)),
      ],
    );
  }

  Widget _buildMatchCard(MatchModel match, AppColorsExtension colors) {
    final isLive = match.isLive;
    final cardScore = isLive
        ? match.currentLiveScore
        : SetScore(score1: match.score1, score2: match.score2);

    return GestureDetector(
      onTap: () {
        if (match.tournamentName != null) {
          // Navigate to the match detail via live-score
          context.push(
            NavigationHelper.getLiveMatchRoute(
              match.tournamentId ?? '',
              match.id,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLive
                ? const Color(0xFF2979FF).withValues(alpha: 0.3)
                : colors.border,
          ),
        ),
        child: Row(
          children: [
            // Team 1
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.team1Name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (match.team1Members != null &&
                      match.team1Members!.isNotEmpty)
                    Text(
                      match.team1Members!.join(', '),
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Score / vs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                match.isCompleted || match.isLive
                    ? '${cardScore.score1} - ${cardScore.score2}'
                    : 'VS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isLive
                      ? const Color(0xFF2979FF)
                      : match.isCompleted
                      ? colors.success
                      : colors.textPrimary,
                ),
              ),
            ),
            // Team 2
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    match.team2Name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                  if (match.team2Members != null &&
                      match.team2Members!.isNotEmpty)
                    Text(
                      match.team2Members!.join(', '),
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.sports_tennis_rounded,
              size: 40,
              color: colors.textMuted.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.matchesNoMatchesFound,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.matchesTryChangeFilter,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _reload(clear: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.matchesRetry),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip Widget ───

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final AppColorsExtension colors;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = colors.info;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.12) : colors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.4)
                : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : colors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Filter Pill (Hình 1 design) ───

class _StatusFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeBgColor;
  final Color activeTextColor;
  final VoidCallback onTap;

  const _StatusFilterPill({
    required this.label,
    required this.isSelected,
    required this.activeBgColor,
    required this.activeTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeTextColor.withValues(alpha: 0.3)
                : colors.border,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? activeTextColor : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
