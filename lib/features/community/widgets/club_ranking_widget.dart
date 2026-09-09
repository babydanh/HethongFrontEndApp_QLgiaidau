import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class ClubRankingWidget extends ConsumerStatefulWidget {
  final String clubId;
  final bool compact;

  /// Các môn thể thao CLB đã đăng ký (key như 'pickleball', 'tennis'...).
  /// Nếu có, bộ lọc Môn chỉ hiện các môn này (giống web dùng
  /// `community.categories`); rỗng/null → hiện toàn bộ môn toàn cục.
  final List<String>? clubSportKeys;

  /// Category UUIDs already returned with the club detail response. Using
  /// them avoids a second `/categories` round-trip before the first ranking.
  final Map<String, String>? clubSportCategoryIds;

  const ClubRankingWidget({
    super.key,
    required this.clubId,
    this.compact = false,
    this.clubSportKeys,
    this.clubSportCategoryIds,
  });

  @override
  ConsumerState<ClubRankingWidget> createState() => _ClubRankingWidgetState();
}

class _ClubRankingWidgetState extends ConsumerState<ClubRankingWidget>
    with AutomaticKeepAliveClientMixin {
  static const _rankingPageSize = 10;

  List<PlayerRanking>? _rankings;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _nextCursor;
  int _requestVersion = 0;
  String? _error;
  String? _loadMoreError;
  String _selectedMatchType = 'SINGLES';
  String _selectedGender = 'MALE';
  String? _selectedCategoryId;
  List<dynamic> _availableCategories = const [];
  Timer? _pollingTimer;

  @override
  bool get wantKeepAlive => true;

  /// Số bộ lọc đang lệch mặc định (để hiện chấm badge trên icon bộ lọc).
  int get _activeFilterCount =>
      (_selectedMatchType != 'SINGLES' ? 1 : 0) +
      (_selectedGender != 'MALE' ? 1 : 0) +
      (_selectedCategoryId != null &&
              _availableCategories.isNotEmpty &&
              _selectedCategoryId != _availableCategories.first.id
          ? 1
          : 0);

  @override
  void initState() {
    super.initState();
    _fetchRankings();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Không làm mất các trang người dùng đã mở bằng nút "Hiện thêm".
      // Bản xếp hạng mở rộng sẽ chỉ tải lại khi đổi bộ lọc hoặc refresh.
      if ((_rankings?.length ?? 0) > _rankingPageSize) return;
      _fetchRankings(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  List<dynamic> _responseRows(dynamic raw) {
    if (raw is Map && raw['data'] is List) {
      return List<dynamic>.from(raw['data'] as List);
    }
    return raw is List ? List<dynamic>.from(raw) : const <dynamic>[];
  }

  String? _responseNextCursor(dynamic raw, String? currentCursor) {
    if (raw is! Map || raw['meta'] is! Map) return null;
    final meta = Map<String, dynamic>.from(raw['meta'] as Map);
    if (meta['hasMore'] != true) return null;
    final next = meta['nextCursor']?.toString().trim();
    if (next == null || next.isEmpty || next == currentCursor) return null;
    return next;
  }

  List<PlayerRanking> _mergeRankingRows(
    List<PlayerRanking> current,
    List<PlayerRanking> incoming,
  ) {
    final byId = <String, PlayerRanking>{};
    for (final ranking in [...current, ...incoming]) {
      final key = ranking.id.isNotEmpty
          ? ranking.id
          : '${ranking.userId}:${ranking.categoryId}:${ranking.matchType}';
      if (key.isNotEmpty) byId[key] = ranking;
    }
    return byId.values.toList(growable: false);
  }

  void _applyRankingPage(
    List<PlayerRanking> page, {
    required String? nextCursor,
    required bool loadMore,
    required int requestVersion,
  }) {
    if (!mounted || requestVersion != _requestVersion) return;
    final current = _rankings ?? const <PlayerRanking>[];
    final merged = loadMore ? _mergeRankingRows(current, page) : page;
    final visibleRows = loadMore
        ? merged
        : merged.take(widget.compact ? 3 : _rankingPageSize).toList();
    setState(() {
      _rankings = visibleRows;
      _nextCursor = nextCursor;
      _hasMore = nextCursor != null;
      _loading = false;
      _loadingMore = false;
      _error = null;
      _loadMoreError = null;
    });
  }

  Future<void> _fetchRankings({
    bool showLoading = true,
    bool loadMore = false,
  }) async {
    if (loadMore && (_loadingMore || !_hasMore || _nextCursor == null)) {
      return;
    }
    if (!loadMore && !showLoading && _loading) return;
    final requestVersion = ++_requestVersion;
    final currentCursor = loadMore ? _nextCursor : null;
    if (!loadMore) {
      _nextCursor = null;
      _hasMore = false;
      _loadingMore = false;
      _loadMoreError = null;
    }
    if (loadMore) {
      if (mounted) {
        setState(() {
          _loadingMore = true;
          _loadMoreError = null;
        });
      }
    } else if (showLoading && _rankings == null) {
      if (!_loading || _error != null) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
    }
    try {
      final dio = ref.read(dioProvider);

      // 1. Tải danh mục với timeout ngắn để bảng xếp hạng không bị treo lâu.
      // Nếu detail CLB đã trả category UUID thì dùng ngay, không tạo thêm
      // round-trip `/categories` trước khi tải bảng xếp hạng đầu tiên.
      List<dynamic> allCategories = _availableCategories;
      final clubCategoryIds = widget.clubSportCategoryIds ?? const {};
      if (allCategories.isEmpty && clubCategoryIds.isNotEmpty) {
        final seenCategoryIds = <String>{};
        allCategories = clubCategoryIds.entries
            .where((entry) => seenCategoryIds.add(entry.value))
            .map(
              (entry) => CategoryModel(
                id: entry.value,
                name: entry.key,
                slug: entry.key.toLowerCase().replaceAll(' ', '_'),
                description: '',
                isActive: true,
              ),
            )
            .toList(growable: false);
      }
      if (allCategories.isEmpty) {
        allCategories = await ref
            .read(categoriesProvider.future)
            .timeout(
              const Duration(milliseconds: 1200),
              onTimeout: () => const [],
            );
      }

      var categories = allCategories;
      final clubKeys = widget.clubSportKeys;
      if (clubKeys != null && clubKeys.isNotEmpty) {
        final norm = clubKeys
            .map((k) => k.toLowerCase().replaceAll(' ', ''))
            .where((k) => k.isNotEmpty)
            .toSet();
        final matched = allCategories.where((c) {
          final slug = c.slug.toLowerCase().replaceAll(' ', '');
          final name = c.name.toLowerCase().replaceAll(' ', '');
          return norm.contains(slug) || norm.contains(name);
        }).toList();
        categories = matched;
      }
      _availableCategories = categories;

      final categoryId =
          _selectedCategoryId ??
          (categories.isNotEmpty ? categories.first.id : null);
      _selectedCategoryId = (categoryId == null || categoryId.isEmpty)
          ? null
          : categoryId;

      final selectedCategory = categories
          .cast<dynamic>()
          .where((c) => c.id == categoryId)
          .firstOrNull;
      final categoryLabel = selectedCategory == null
          ? ''
          : '${selectedCategory.slug} ${selectedCategory.name}'.toLowerCase();
      final isFootball =
          categoryLabel.contains('football') ||
          categoryLabel.contains('bóng đá') ||
          categoryLabel.contains('bong da');

      if (isFootball && categoryId != null && categoryId.isNotEmpty) {
        final response = await dio
            .get(
              '/rankings/football-teams',
              queryParameters: {
                'categoryId': categoryId,
                'communityId': widget.clubId,
                'limit': widget.compact ? 3 : _rankingPageSize,
                ...?(currentCursor == null
                    ? null
                    : <String, dynamic>{'cursor': currentCursor}),
              },
            )
            .timeout(const Duration(seconds: 6));
        final raw = response.data;
        final dataList = _responseRows(raw);
        final teams = dataList
            .map((item) {
              final json = item as Map<String, dynamic>;
              final rawName =
                  (json['teamName'] ?? json['team_name'])?.toString().trim();
              final id =
                  (json['id'] ?? json['teamId'] ?? rawName ?? '').toString();
              final name = (rawName != null && rawName.isNotEmpty)
                  ? rawName
                  : '';
              return PlayerRanking(
                id: id.isNotEmpty ? id : name,
                userId: '',
                fullName: name,
                avatarUrl:
                    json['logoUrl']?.toString() ?? json['logo_url']?.toString(),
                categoryId: categoryId,
                matchType: 'SINGLES',
                genderRestriction: 'MIXED',
                eloPoints:
                    ((json['eloPoints'] ?? json['elo_points'] ?? 1000) as num)
                        .toInt(),
                peakElo: ((json['peakElo'] ?? json['peak_elo']) as num?)
                    ?.toInt(),
                matchesPlayed:
                    ((json['matchesPlayed'] ?? json['matches_played'] ?? 0)
                            as num)
                        .toInt(),
                matchesWon:
                    ((json['matchesWon'] ?? json['matches_won'] ?? 0) as num)
                        .toInt(),
                winStreak:
                    ((json['winStreak'] ?? json['win_streak'] ?? 0) as num)
                        .toInt(),
                tierName: json['tierName']?.toString() ?? '',
              );
            })
            .where((team) => team.matchesPlayed > 0)
            .toList();
        _applyRankingPage(
          teams,
          nextCursor: _responseNextCursor(raw, currentCursor),
          loadMore: loadMore,
          requestVersion: requestVersion,
        );
        return;
      }

      // 2. Tải bảng xếp hạng theo đúng category. API này yêu cầu categoryId.
      // Không fallback sang projection cũ vì projection đó không có bộ lọc
      // môn/match type và có thể hiển thị nhầm bảng xếp hạng.
      var rankings = <PlayerRanking>[];
      String? rankingNextCursor;
      if (categoryId != null && categoryId.isNotEmpty) {
        final queryParams = <String, dynamic>{
          'communityId': widget.clubId,
          'scope': 'COMMUNITY',
          'matchType': _selectedMatchType,
          'genderRestriction': _selectedGender,
          'categoryId': categoryId,
          'limit': widget.compact ? 3 : _rankingPageSize,
          ...?(currentCursor == null
              ? null
              : <String, dynamic>{'cursor': currentCursor}),
        };
        final response = await dio
            .get('/rankings', queryParameters: queryParams)
            .timeout(const Duration(seconds: 5));
        final raw = response.data;
        rankingNextCursor = _responseNextCursor(raw, currentCursor);
        final dataList = _responseRows(raw);
        rankings = dataList
            .map((json) => PlayerRanking.fromJson(json as Map<String, dynamic>))
            .where((ranking) => ranking.matchesPlayed > 0)
            .toList();
      }

      _applyRankingPage(
        rankings,
        nextCursor: rankingNextCursor,
        loadMore: loadMore,
        requestVersion: requestVersion,
      );
    } on DioException catch (e) {
      if (mounted && requestVersion == _requestVersion) {
        setState(() {
          if (loadMore) {
            _loadMoreError = e.message;
          } else {
            _error = e.message;
            _loading = false;
          }
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted && requestVersion == _requestVersion) {
        setState(() {
          if (loadMore) {
            _loadMoreError = e.toString();
          } else {
            _error = e.toString();
            _loading = false;
          }
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Không early-return khi rỗng/lỗi: header + icon bộ lọc phải LUÔN hiện
    // để người dùng đổi được bộ lọc. Tìm kiếm dùng màn hình search chung
    // từ header CLB, không lặp lại trong tab Xếp hạng.
    final allRankings = _rankings ?? const <PlayerRanking>[];
    final filteredRankings = allRankings;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.clubRankingTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (!widget.compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l10n.clubRankingFilterTooltip,
                  onPressed: _openFilterSheet,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.tune_rounded, size: 19),
                      if (_activeFilterCount > 0)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // ── Nội dung: dữ liệu / trống / lỗi ──
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildEmptyRanking(colors, l10n, error: true),
            )
          else if (allRankings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildEmptyRanking(colors, l10n),
            )
          else if (filteredRankings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildEmptyRanking(colors, l10n, searching: true),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPodiumRow(filteredRankings, l10n),
            ),
            // ── Ranks 4 onward (10 per explicit page) ──
            if (!widget.compact && filteredRankings.length > 3) ...[
              const SizedBox(height: 10),
              ...List.generate(filteredRankings.length - 3, (i) {
                final index = i + 3;
                final r = filteredRankings[index];
                final actualRank = allRankings.indexOf(r) + 1;
                return _buildListRow(r, actualRank, colors, l10n);
              }),
            ],
          ],
          if (!widget.compact && _hasMore && allRankings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton(
                  onPressed: _loadingMore
                      ? null
                      : () => _fetchRankings(loadMore: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Hiện thêm 10 người',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            if (_loadMoreError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: TextButton(
                    onPressed: _loadingMore
                        ? null
                        : () => _fetchRankings(loadMore: true),
                    child: Text(
                      'Không tải được. Thử lại',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          // ── Xem tất cả (compact mode) ──
          if (!widget.compact) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.clubRankingAutoRefresh,
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
            ),
          ],

          if (widget.compact) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.push('/club/${widget.clubId}'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    l10n.clubRankingViewAll,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.clubRankingFilterTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  l10n.clubRankingFilterHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                if (_availableCategories.length > 1) ...[
                  Text(
                    l10n.clubRankingSport,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableCategories
                        .map(
                          (category) => ChoiceChip(
                            label: Text(category.name),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (_) {
                              setState(() => _selectedCategoryId = category.id);
                              setSheetState(() {});
                              _fetchRankings();
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  l10n.clubRankingFormat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChoice(
                      l10n.clubRankingSingles,
                      'SINGLES',
                      setSheetState,
                    ),
                    _filterChoice(
                      l10n.clubRankingDoubles,
                      'DOUBLES',
                      setSheetState,
                    ),
                    _filterChoice(
                      l10n.clubRankingMixedDoubles,
                      'MIXED_DOUBLES',
                      setSheetState,
                    ),
                  ],
                ),
                if (_selectedMatchType != 'MIXED_DOUBLES') ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.clubRankingGender,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _genderChoice(
                        l10n.clubRankingMale,
                        'MALE',
                        setSheetState,
                      ),
                      _genderChoice(
                        l10n.clubRankingFemale,
                        'FEMALE',
                        setSheetState,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(l10n.clubRankingApply),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChoice(String label, String value, StateSetter setSheetState) =>
      ChoiceChip(
        label: Text(label),
        selected: _selectedMatchType == value,
        onSelected: (_) {
          setState(() {
            _selectedMatchType = value;
            if (value == 'MIXED_DOUBLES') _selectedGender = 'MALE';
          });
          setSheetState(() {});
          _fetchRankings();
        },
      );

  Widget _genderChoice(String label, String value, StateSetter setSheetState) =>
      ChoiceChip(
        label: Text(label),
        selected: _selectedGender == value,
        onSelected: (_) {
          setState(() => _selectedGender = value);
          setSheetState(() {});
          _fetchRankings();
        },
      );

  // ─── Gender Filter ───

  // ─── Empty / Error card (hiện dưới thanh tìm kiếm khi không có dữ liệu) ───

  Widget _buildEmptyRanking(
    AppColorsExtension colors,
    AppLocalizations l10n, {
    bool error = false,
    bool searching = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: i == 1 ? 52 : 44,
                height: i == 1 ? 52 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderLight, width: 1.5),
                  color: colors.bgSurface,
                ),
                child: Center(
                  child: Text(
                    '#${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error
                ? l10n.clubRankingError
                : searching
                ? l10n.clubRankingSearchEmpty
                : l10n.clubRankingEmpty,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Text(
            error ? l10n.clubRankingErrorHint : l10n.clubRankingEmptyHint,
            style: TextStyle(
              fontSize: 11,
              color: colors.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Podium ───

  Widget _buildPodiumRow(List<PlayerRanking> rankings, AppLocalizations l10n) {
    final rank1 = rankings[0];
    final rank2 = rankings.length > 1 ? rankings[1] : null;
    final rank3 = rankings.length > 2 ? rankings[2] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 148,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Silver (rank 2) - left
          if (rank2 != null)
            Expanded(
              flex: 3,
              child: _buildPodiumCard(rank2, 2, isCenter: false, l10n: l10n),
            )
          else
            const Expanded(flex: 3, child: SizedBox()),

          const SizedBox(width: 6),

          // Gold (rank 1) - center, tallest
          Expanded(
            flex: 4,
            child: _buildPodiumCard(rank1, 1, isCenter: true, l10n: l10n),
          ),

          const SizedBox(width: 6),

          // Bronze (rank 3) - right
          if (rank3 != null)
            Expanded(
              flex: 3,
              child: _buildPodiumCard(rank3, 3, isCenter: false, l10n: l10n),
            )
          else
            const Expanded(flex: 3, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(
    PlayerRanking player,
    int rank, {
    required bool isCenter,
    required AppLocalizations l10n,
  }) {
    final colors = context.colors;
    final medalColors = _medalColors(rank);
    final avatarSize = isCenter ? 40.0 : 32.0;
    final winRate = player.winRate;
    final displayName = player.fullName.isNotEmpty
        ? player.fullName
        : l10n.clubRankingTeamFallback;

    return Container(
      height: isCenter ? 144 : 124,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: isCenter ? 8 : 6),
      decoration: BoxDecoration(
        color: medalColors.bg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: medalColors.border.withValues(alpha: 0.4),
          width: isCenter ? 1.5 : 1,
        ),
        boxShadow: isCenter
            ? [
                BoxShadow(
                  color: medalColors.border.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: medalColors.border.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rank == 1
                      ? Icons.emoji_events_rounded
                      : rank == 2
                      ? Icons.military_tech_rounded
                      : Icons.workspace_premium_rounded,
                  size: isCenter ? 13 : 11,
                  color: medalColors.icon,
                ),
                const SizedBox(width: 2),
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: isCenter ? 11 : 9.5,
                    fontWeight: FontWeight.w900,
                    color: medalColors.icon,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          _buildPodiumAvatars(player, avatarSize, l10n: l10n),
          const SizedBox(height: 5),

          // Name
          Text(
            displayName,
            style: TextStyle(
              fontSize: isCenter ? 11.5 : 10,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPodiumStat(
                'ELO',
                '${player.eloPoints}',
                medalColors.elo,
                isCenter,
              ),
              const SizedBox(width: 4),
              _buildPodiumStat(
                'TL thắng',
                '${winRate.toStringAsFixed(0)}%',
                colors.success,
                isCenter,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStat(
    String label,
    String value,
    Color color,
    bool isCenter,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: isCenter ? 8.5 : 7.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // ─── Rows 4-10 ───

  Widget _buildListRow(
    PlayerRanking player,
    int rank,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final winRate = player.matchesPlayed > 0
        ? (player.matchesWon / player.matchesPlayed) * 100
        : 0.0;
    final displayName = player.fullName.isNotEmpty
        ? player.fullName
        : l10n.clubRankingTeamFallback;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          bottom: BorderSide(color: colors.borderLight, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 22,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),

          // Đôi hiển thị đủ avatar của cả hai người trong cùng một hạng.
          if (player.partnerName != null) ...[
            _buildMiniAvatar(
              displayName.split(' / ').first,
              player.avatarUrl,
              player,
            ),
            const SizedBox(width: 2),
            _buildMiniAvatar(
              player.partnerName!,
              player.partnerAvatarUrl,
              player,
            ),
          ] else
            _buildMiniAvatar(displayName, player.avatarUrl, player),
          const SizedBox(width: 7),

          // Name
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),

          // Chỉ hiển thị hai chỉ số người chơi cần: ELO và tỉ lệ thắng.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              'ELO ${player.eloPoints}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              'Thắng ${winRate.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(
    String name,
    String? avatarUrl,
    PlayerRanking player,
  ) {
    return RankAvatar(
      imageUrl: avatarUrl,
      name: name,
      elo: player.eloPoints,
      tierName: player.tierName,
      matchesPlayed: player.matchesPlayed,
      size: 24,
      ringWidth: 1.5,
    );
  }

  Widget _buildPodiumAvatars(
    PlayerRanking player,
    double avatarSize, {
    required AppLocalizations l10n,
  }) {
    final displayName = player.fullName.isNotEmpty
        ? player.fullName
        : l10n.clubRankingTeamFallback;
    final firstName = displayName.split(' / ').first;
    final avatars = <Widget>[
      _buildMiniAvatar(firstName, player.avatarUrl, player),
    ];
    if (player.partnerName != null) {
      avatars.add(
        _buildMiniAvatar(player.partnerName!, player.partnerAvatarUrl, player),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: avatars
          .map(
            (avatar) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: FittedBox(child: avatar),
              ),
            ),
          )
          .toList(),
    );
  }

  // ─── Helpers ───

  _MedalColors _medalColors(int rank) {
    switch (rank) {
      case 1:
        return const _MedalColors(
          bg: Color(0xFFFFB300),
          border: Color(0xFFFFB300),
          icon: Color(0xFFFFB300),
          elo: Color(0xFFFFB300),
        );
      case 2:
        return const _MedalColors(
          bg: Color(0xFF9E9E9E),
          border: Color(0xFF9E9E9E),
          icon: Color(0xFF9E9E9E),
          elo: Color(0xFF9E9E9E),
        );
      case 3:
        return const _MedalColors(
          bg: Color(0xFFCD7F32),
          border: Color(0xFFCD7F32),
          icon: Color(0xFFCD7F32),
          elo: Color(0xFFCD7F32),
        );
      default:
        return const _MedalColors(
          bg: Colors.transparent,
          border: Colors.transparent,
          icon: Colors.grey,
          elo: Colors.grey,
        );
    }
  }
}

class _MedalColors {
  final Color bg;
  final Color border;
  final Color icon;
  final Color elo;

  const _MedalColors({
    required this.bg,
    required this.border,
    required this.icon,
    required this.elo,
  });
}
