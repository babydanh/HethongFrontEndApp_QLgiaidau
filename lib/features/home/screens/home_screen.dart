import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/regions_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_header.dart';
import 'package:app_quanly_giaidau/features/home/widgets/featured_tournament_banner_card.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_card_with_banner.dart';
import 'package:app_quanly_giaidau/core/widgets/status_segment.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/widgets/province_picker.dart';
import 'package:app_quanly_giaidau/core/utils/elo_helpers.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/leaderboard_screen.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/home/widgets/token_input_sheet.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

// ═══════════════════════════════════════════════════════
//  WAVE HEADER PAINTER
//  Sóng lượn: trái 75% thấp hơn phải 85%, đỉnh giữa 100%
//  Giống clip-path: polygon(0% 0%, 100% 0%, 100% 85%, 50% 100%, 0% 75%)
// ═══════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════
//  HOME SCREEN — Full Redesign
// ═══════════════════════════════════════════════════════
class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  // ─── Per-tab search state ───
  final Map<int, String> _searchQueries = {0: '', 1: '', 3: '', 4: ''};
  final Map<int, TextEditingController> _searchControllers = {
    0: TextEditingController(),
    1: TextEditingController(),
    3: TextEditingController(),
    4: TextEditingController(),
  };
  final FocusNode _searchFocusNode = FocusNode();

  String get _activeSearchQuery => _searchQueries[_currentIndex] ?? '';
  TextEditingController get _activeSearchController =>
      _searchControllers[_currentIndex] ?? _searchControllers[0]!;

  // ─── Per-tab filter state ───
  String _exploreSport = 'all';
  String _exploreStatus = 'all';
  String _exploreContent = 'all';
  String _exploreBracket = 'all';
  String _exploreRanked = 'all';
  String _tournamentSport = 'all';
  String _tournamentStatus = 'all';
  String _clubSport = 'all';
  String? _clubProvinceCode;
  String _rankingsSport = 'all';
  String _tournamentContent = 'all';
  String _tournamentBracket = 'all';
  String _tournamentRanked = 'all';
  String _tournamentProvince = ''; // tên tỉnh — để so khớp locationAddress
  String _tournamentProvinceCode = ''; // mã tỉnh — để tải quận/huyện
  String _tournamentDistrict = ''; // tên quận/huyện
  DateTime? _tournamentStartDate;
  DateTime? _tournamentEndDate;

  // Khám phá (tab 0) CÓ thanh search — nhưng gõ tìm sẽ lọc tại chỗ trong tab,
  // KHÔNG tự nhảy sang tab Giải đấu nữa.
  bool get _shouldShowSearchBar =>
      _currentIndex == 0 ||
      _currentIndex == 1 ||
      _currentIndex == 3 ||
      _currentIndex == 4;

  String get _activeSportFilter {
    return switch (_currentIndex) {
      0 => _exploreSport,
      1 => _tournamentSport,
      3 => _clubSport,
      4 => _rankingsSport == 'all' ? 'pickleball' : _rankingsSport,
      _ => 'all',
    };
  }

  void _setActiveSportFilter(String key) {
    setState(() {
      _exploreSport = key;
      _tournamentSport = key;
      _clubSport = key;
      _rankingsSport = key == 'all' ? 'pickleball' : key;
    });
  }

  List<(String, String)> _activeSportFilterItems(AppLocalizations l10n) {
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];
    return [
      ('all', l10n.filterAll),
      ...categories.map((category) => (category.slug, category.name)),
    ];
  }

  final ScrollController _scrollController = ScrollController();
  double _headerScrollProgress = 0.0;
  bool _isAnimatingToTop = false;

  PageController? _carouselController;
  Timer? _carouselTimer;
  int _carouselCurrentPage = 0;

  double get _safeAreaTop => MediaQuery.of(context).padding.top;
  double get _maxHeaderHeight => 240.0 + _safeAreaTop;
  double get _minHeaderHeight => 90.0 + _safeAreaTop;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _scrollController.addListener(_onScroll);
    _carouselController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).init();
    });

    // Home supports landscape/tablet layouts; do not force portrait here.
  }

  void _startCarouselTimer(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselController == null ||
          !_carouselController!.hasClients ||
          _carouselController!.positions.length != 1)
        return;
      _carouselCurrentPage = (_carouselCurrentPage + 1) % itemCount;
      _carouselController!.animateToPage(
        _carouselCurrentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isAnimatingToTop) return;
    final double offset = _scrollController.offset;
    if (offset > 10.0 && _headerScrollProgress == 0.0) {
      setState(() => _headerScrollProgress = 1.0);
    }
  }

  void _expandHeader() async {
    if (_headerScrollProgress == 1.0) {
      setState(() {
        _headerScrollProgress = 0.0;
        _isAnimatingToTop = true;
      });
      await _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (mounted) {
        setState(() {
          _isAnimatingToTop = false;
        });
      }
    }
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;

    String apiBase = 'http://localhost:3000/api/v1';
    try {
      apiBase = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
      if (!kIsWeb && Platform.isAndroid && apiBase.contains('localhost')) {
        apiBase = apiBase.replaceAll('localhost', '10.0.2.2');
      }
    } catch (_) {}

    final host = apiBase.replaceAll('/api/v1', '');
    return '$host$url';
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController?.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    for (final controller in _searchControllers.values) {
      controller.dispose();
    }
    _searchFocusNode.dispose();

    super.dispose();
  }

  void _switchTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (index == 4) {
        final currentSport = _activeSportFilter;
        if (currentSport != 'all') {
          _rankingsSport = currentSport;
        } else if (_rankingsSport == 'all') {
          _rankingsSport = 'pickleball';
        }
      }
      _currentIndex = index;
    });
  }

  void _submitSearch() {
    // Search lọc theo từng ký tự (onChanged) ngay trong tab hiện tại.
    // Không còn tự nhảy sang tab Giải đấu khi tìm ở Khám phá.
    _searchFocusNode.unfocus();
  }

  void _showTokenSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TokenInputSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentsAsync = ref.watch(tournamentsProvider);
    final screenSize = MediaQuery.of(context).size;
    final double safeAreaTop = MediaQuery.of(context).padding.top;
    final isHomeTab = _currentIndex == 0;
    final double p = isHomeTab ? _headerScrollProgress : 1.0;
    final double currentHeaderHeight = isHomeTab
        ? lerpDouble(_maxHeaderHeight, _minHeaderHeight, p)!
        : _minHeaderHeight;
    final double iconsTop = isHomeTab
        ? lerpDouble(safeAreaTop + 4.0, safeAreaTop + 16.0, p)!
        : safeAreaTop + 16.0;
    final double subtitleOpacity = isHomeTab ? (1.0 - p).clamp(0.0, 1.0) : 0.0;
    final double headerDetailsY = lerpDouble(60.0, 16.0, p)!;
    final activeHeaderHeight = currentHeaderHeight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.colors.bgDark,
        extendBody: true,
        body: Stack(
          children: [
            // Body Content filling top to bottom
            Positioned.fill(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: _buildCurrentTabContent(
                    tournamentsAsync,
                    activeHeaderHeight,
                  ),
                ),
              ),
            ),
            // Shared Floating Top Header Stack
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: currentHeaderHeight,
              child: GestureDetector(
                onTap: isHomeTab && _headerScrollProgress == 1.0
                    ? _expandHeader
                    : null,
                behavior: HitTestBehavior.translucent,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: "Sporto_header_bg",
                        child: CustomPaint(
                          size: Size(screenSize.width, currentHeaderHeight),
                          painter: SportoHeaderPainter(
                            isLoggedIn: ref.watch(authProvider).isAuthenticated,
                            colors: context.colors,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: iconsTop,
                      left: 16.0,
                      right: 16.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left: Dropdown
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PopupMenuButton<String>(
                              onSelected: _setActiveSportFilter,
                              offset: const Offset(0, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: context.colors.bgSurface,
                              elevation: 8,
                              itemBuilder: (context) => [
                                if (_currentIndex != 4)
                                  _buildPopupMenuItem(l10n.filterAll, 'all'),
                                ..._activeSportFilterItems(l10n)
                                    .where((item) => item.$1 != 'all')
                                    .map(
                                      (item) =>
                                          _buildPopupMenuItem(item.$2, item.$1),
                                    ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _activeSportFilter == 'all'
                                          ? l10n.filterAll
                                          : AppConstants
                                                    .sportNames[_activeSportFilter] ??
                                                _activeSportFilter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Center: Title for sub-tabs
                          if (!isHomeTab)
                            Center(
                              child: Text(
                                _currentIndex == 1
                                    ? l10n.navTournaments
                                    : _currentIndex == 3
                                    ? 'Câu lạc bộ'
                                    : _currentIndex == 4
                                    ? 'Bảng xếp hạng'
                                    : 'Sporto',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                          // Right: Notification Bell
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildNotificationBellHeader(),
                          ),
                        ],
                      ),
                    ),
                    if (isHomeTab && subtitleOpacity > 0)
                      Positioned(
                        top: safeAreaTop + headerDetailsY,
                        left: 16.0,
                        right: 16.0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          opacity: subtitleOpacity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ref.watch(authProvider).isAuthenticated)
                                GestureDetector(
                                  onTap: () {
                                    if (_headerScrollProgress == 1.0) {
                                      _expandHeader();
                                    } else {
                                      _switchTab(2);
                                    }
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: _buildLoggedInHeaderDetails(),
                                )
                              else
                                _buildLoginPillHeader(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Floating Sticky Search Bar pinned directly below collapsed Header
            if (_shouldShowSearchBar &&
                (!isHomeTab || _headerScrollProgress > 0.0))
              Positioned(
                top: currentHeaderHeight + 4.0,
                left: 16.0,
                right: 16.0,
                child: Opacity(
                  opacity: isHomeTab ? _headerScrollProgress : 1.0,
                  child: _buildSearchBar(),
                ),
              ),
          ],
        ),
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: _currentIndex,
          onTabSelected: _switchTab,
          onProfileTap: () => context.go('/profile'),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(
    AsyncValue<List<Tournament>> tournamentsAsync,
    double headerHeight,
  ) {
    if (_currentIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/profile');
        if (mounted) {
          setState(() => _currentIndex = 0);
        }
      });
      return const SizedBox.shrink();
    }
    switch (_currentIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('explore'),
          child: _buildExploreTab(tournamentsAsync),
        );
      case 1:
        final tournaments = tournamentsAsync.value ?? [];
        return KeyedSubtree(
          key: const ValueKey('tournaments'),
          child: _buildTournamentsTab(tournaments),
        );
      case 3:
        return KeyedSubtree(
          key: const ValueKey('clubs'),
          child: _buildCommunityTab(),
        );
      case 4:
      default:
        return KeyedSubtree(
          key: const ValueKey('ranking'),
          child: LeaderboardScreen(
            selectedSport: _rankingsSport,
            searchQuery: _searchQueries[4] ?? '',
          ),
        );
    }
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 0: KHÁM PHÁ (Explore)
  // ═══════════════════════════════════════════════════════
  Widget _buildExploreTab(AsyncValue<List<Tournament>> tournamentsAsync) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(tournamentsProvider),
            color: AppTheme.primary,
            child: tournamentsAsync.when(
              data: (tournamentsList) {
                final allTournaments = tournamentsList.where((t) {
                  final s = t.status.toUpperCase();
                  if ([
                    'DRAFT',
                    'PENDING_APPROVAL',
                    'SUSPENDED',
                    'CANCELLED',
                    'PENDING_DELETE',
                  ].contains(s)) {
                    return false;
                  }
                  final tSport = t.sport
                      .toLowerCase()
                      .replaceAll('_', '')
                      .replaceAll(' ', '');
                  final selSport = _exploreSport
                      .toLowerCase()
                      .replaceAll('_', '')
                      .replaceAll(' ', '');
                  final sportMatch =
                      selSport == 'all' ||
                      tSport == selSport ||
                      tSport.contains(selSport) ||
                      selSport.contains(tSport);
                  // Search on the match rows below, not only on tournament
                  // names. This lets users find a player/team inside a group.
                  return sportMatch;
                }).toList();

                final now = DateTime.now();
                final featuredTournaments = allTournaments
                    .where((t) {
                      final s = t.status.toLowerCase();
                      if (s == 'completed' || s == 'finished') {
                        final endedDate = t.endDate ?? t.updatedAt;
                        return now.difference(endedDate).inDays <= 14;
                      }
                      return true;
                    })
                    .take(10)
                    .toList();

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: _headerScrollProgress == 1.0
                            ? (_minHeaderHeight + 58.0)
                            : (_maxHeaderHeight + 8.0),
                      ),
                    ),
                    if (featuredTournaments.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          title: l10n.featuredTournaments,
                          actionLabel: l10n.viewAll,
                          onAction: () => _switchTab(1),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: KeyedSubtree(
                            key: ValueKey("featured_$_exploreSport"),
                            child: _buildTournamentCarousel(
                              featuredTournaments,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(
                        title: l10n.liveMatches,
                        isLive: true,
                      ),
                    ),
                    _TournamentSectionList(
                      tournaments: allTournaments,
                      filterStatus: 'live',
                      searchQuery: _searchQueries[0] ?? '',
                      contentFilter: _exploreContent,
                      bracketFilter: _exploreBracket,
                      rankedFilter: _exploreRanked,
                      enabled:
                          _exploreStatus == 'all' || _exploreStatus == 'live',
                      emptyMessage: l10n.noLiveMatches,
                    ),
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(title: l10n.upcomingMatches),
                    ),
                    _TournamentSectionList(
                      tournaments: allTournaments,
                      filterStatus: 'scheduled',
                      searchQuery: _searchQueries[0] ?? '',
                      contentFilter: _exploreContent,
                      bracketFilter: _exploreBracket,
                      rankedFilter: _exploreRanked,
                      enabled:
                          _exploreStatus == 'all' ||
                          _exploreStatus == 'scheduled',
                      emptyMessage: l10n.noUpcomingMatches,
                    ),
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(title: 'Trận đấu vừa kết thúc'),
                    ),
                    _TournamentSectionList(
                      tournaments: allTournaments,
                      filterStatus: 'completed',
                      searchQuery: _searchQueries[0] ?? '',
                      contentFilter: _exploreContent,
                      bracketFilter: _exploreBracket,
                      rankedFilter: _exploreRanked,
                      enabled:
                          _exploreStatus == 'all' ||
                          _exploreStatus == 'completed',
                      emptyMessage: 'Chưa có trận đấu vừa kết thúc',
                    ),

                    if (allTournaments.isEmpty)
                      SliverFillRemaining(child: _buildEmpty()),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
              loading: () => CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: _maxHeaderHeight)),
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (e, st) => CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: _maxHeaderHeight)),
                  SliverFillRemaining(child: _buildErrorState(e)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClubsHorizontalList() {
    final l10n = AppLocalizations.of(context)!;
    final communitiesAsync = ref.watch(
      communitiesProvider((search: null, provinceCode: null)),
    );
    final colors = context.colors;
    final cardWidth = (MediaQuery.of(context).size.width - 44) / 2.05;

    return communitiesAsync.when(
      data: (clubs) {
        if (clubs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: Text(
                l10n.noClubs,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return SizedBox(
          height: 182,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final club = clubs[index];
              final resolvedLogo = _resolveImageUrl(club.logoUrl);
              final resolvedBanner = _resolveImageUrl(club.bannerUrl);
              final hasBanner = resolvedBanner.isNotEmpty;

              // Extract all sports tags
              final List<String> sportsList = [];
              if (club.sports.isNotEmpty) {
                for (final s in club.sports) {
                  final sTrim = s.trim();
                  if (sTrim.isEmpty) continue;
                  final mapped =
                      AppConstants.sportNames[sTrim] ??
                      AppConstants.sportNames[sTrim.toLowerCase()] ??
                      sTrim;
                  if (!sportsList.contains(mapped)) sportsList.add(mapped);
                }
              }
              if (sportsList.isEmpty) {
                sportsList.add(l10n.sportsHeader);
              }

              final displayMemberCount = club.memberCount > 0
                  ? club.memberCount
                  : 2;
              final locationText =
                  (club.locationAddress != null &&
                      club.locationAddress!.trim().isNotEmpty)
                  ? club.locationAddress!.trim()
                  : l10n.vietnam;

              return Container(
                width: cardWidth.clamp(160.0, 220.0),
                margin: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/club/${club.id}'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Banner Header (height 72)
                              SizedBox(
                                height: 72,
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: hasBanner
                                          ? Image.network(
                                              resolvedBanner,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _buildCommunityBannerFallback(),
                                            )
                                          : _buildCommunityBannerFallback(),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withValues(
                                                alpha: 0.15,
                                              ),
                                              Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 2. Card Body Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    20,
                                    10,
                                    10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Title
                                      Text(
                                        club.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: colors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // All Sports Badges (Pills)
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: Row(
                                          children: sportsList.map((s) {
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                right: 4,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                s.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),

                                      // Members & Location line
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people_alt_rounded,
                                            size: 12,
                                            color: colors.textMuted,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '$displayMemberCount TV',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            ' • ',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: colors.textMuted,
                                            ),
                                          ),
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 11,
                                            color: colors.textMuted,
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Text(
                                              locationText,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: colors.textMuted,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // 3. Overlapping Circular Avatar Logo
                          Positioned(
                            top: 50,
                            left: 10,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.bgSurface,
                                border: Border.all(
                                  color: colors.bgCard,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: resolvedLogo.isNotEmpty
                                    ? Image.network(
                                        resolvedLogo,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppTheme.primary.withValues(
                                            alpha: 0.15,
                                          ),
                                          child: const Icon(
                                            Icons.groups_rounded,
                                            color: AppTheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        child: const Icon(
                                          Icons.groups_rounded,
                                          color: AppTheme.primary,
                                          size: 20,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCommunityBannerFallback() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)]
              : const [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SvgPicture.asset(
            AppConstants.logoFullSvg,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBellHeader() {
    final unreadAsync = ref.watch(unreadCountProvider);
    final unread = unreadAsync.value ?? 0;
    return GestureDetector(
      onTap: () => context.push("/notifications"),
      child: Container(
        width: 36.0,
        height: 36.0,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 20,
            ),
            // Ẩn badge khi không có thông báo chưa đọc — không hiện số 0.
            if (unread > 0)
              Positioned(
                top: -2.0,
                right: -2.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 99 ? "99+" : "$unread",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String label, String key) {
    final activeSport = _activeSportFilter;
    final isSelected =
        activeSport == key || (key == '' && activeSport == 'all');
    return PopupMenuItem<String>(
      value: key,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : context.colors.textPrimary,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, color: AppTheme.primary, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginPillHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Chào mừng đến với Tìm và quản lý giải đấu thể thao",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18.0,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.go("/login"),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  "Đăng nhập để xem ELO & thống kê",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInHeaderDetails() {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);
    final rankingsAsync = ref.watch(userRankingsProvider);
    final provincesAsync = ref.watch(provincesProvider);
    return profileAsync.when(
      data: (profile) {
        String fullName = profile.fullName ?? profile.email ?? "Người dùng";
        final provinces = provincesAsync.value ?? [];
        final province = provinces.firstWhere(
          (p) => p.code == profile.provinceCode,
          orElse: () => Province(code: '', name: ''),
        );
        final city = province.name.isNotEmpty
            ? province.name
            : (profile.provinceCode != null && profile.provinceCode!.isNotEmpty
                  ? profile.provinceCode!
                  : l10n.notUpdated);

        return rankingsAsync.when(
          data: (rankings) {
            // Lấy môn có số trận thi đấu nhiều nhất / ELO cao nhất
            final playedRankings =
                rankings.where((r) => r.matchesPlayed > 0).toList()
                  ..sort((a, b) => b.eloPoints.compareTo(a.eloPoints));

            final bestRank = playedRankings.isNotEmpty
                ? playedRankings.first
                : null;
            final hasPlayed = bestRank != null && bestRank.matchesPlayed > 0;

            final sportName = hasPlayed
                ? (bestRank.categoryName?.trim().isNotEmpty == true
                      ? bestRank.categoryName!.trim()
                      : 'Pickleball')
                : (_activeSportFilter != 'all'
                      ? (AppConstants.sportNames[_activeSportFilter] ??
                            'Pickleball')
                      : 'Pickleball');

            final tierName = EloHelpers.getRankTierName(bestRank);
            final elo = hasPlayed ? bestRank.eloPoints : 1000;
            final wins = hasPlayed ? bestRank.matchesWon : 0;
            final totalMatches = hasPlayed ? bestRank.matchesPlayed : 0;
            final winRate = totalMatches > 0
                ? ((wins / totalMatches) * 100).round()
                : 0;

            final progressInfo = EloHelpers.getEloProgressInfo(elo);
            final progressPercent = hasPlayed
                ? (progressInfo.percent / 100.0).clamp(0.0, 1.0)
                : 0.0;
            final progressLabel = hasPlayed
                ? progressInfo.label
                : 'Đánh 1 trận xếp hạng để bắt đầu tiến trình ELO';

            final subtitleText = "$sportName • $city";

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitleText,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                // 3D Glassmorphism Card (Xích lên cao, gọn gàng)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.32),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$elo ELO",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                tierName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _buildStatTableRow(
                            "Trận",
                            "$totalMatches",
                            Colors.white,
                          ),
                          const SizedBox(width: 14),
                          _buildStatTableRow(
                            l10n.infoWin,
                            "$wins",
                            Colors.white,
                          ),
                          const SizedBox(width: 14),
                          _buildStatTableRow(
                            "Rate",
                            "$winRate%",
                            const Color(0xFF4ADE80),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      // Progress bar ELO (0% nếu chưa có trận đấu xếp hạng nào)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFD700),
                          ),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progressLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (e, _) => _buildHeaderErrorState(e.toString()),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => _buildHeaderErrorState(e.toString()),
    );
  }

  Widget _buildHeaderErrorState(String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sporto",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          error.contains("ThrottlerException") ||
                  error.contains("Too Many Requests")
              ? "Hệ thống đang bận, vui lòng thử lại sau"
              : "Tìm và tham gia các giải đấu thể thao",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatTableRow(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10.0,
          ),
        ),
      ],
    );
  }

  String _searchHintForTab() {
    return switch (_currentIndex) {
      0 => 'Tìm trận đấu, đội hoặc người chơi...',
      1 => 'Tìm kiếm giải đấu...',
      3 => 'Tìm kiếm câu lạc bộ...',
      4 => 'Tìm vận động viên...',
      _ => 'Tìm kiếm...',
    };
  }

  String _normalizedQuery(String? q) {
    return (q ?? '').toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  int _activeFilterCountForTab() {
    switch (_currentIndex) {
      case 0:
        return (_exploreSport != 'all' ? 1 : 0) +
            (_exploreStatus != 'all' ? 1 : 0) +
            (_exploreContent != 'all' ? 1 : 0) +
            (_exploreBracket != 'all' ? 1 : 0) +
            (_exploreRanked != 'all' ? 1 : 0);
      case 1:
        return (_tournamentSport != 'all' ? 1 : 0) +
            (_tournamentStatus != 'all' ? 1 : 0) +
            (_tournamentContent != 'all' ? 1 : 0) +
            (_tournamentBracket != 'all' ? 1 : 0) +
            (_tournamentRanked != 'all' ? 1 : 0) +
            (_tournamentProvinceCode.isNotEmpty ? 1 : 0) +
            (_tournamentStartDate != null ? 1 : 0) +
            (_tournamentEndDate != null ? 1 : 0);
      case 3:
        return (_clubSport != 'all' ? 1 : 0) +
            (_clubProvinceCode != null ? 1 : 0);
      case 4:
        return _rankingsSport != 'all' ? 1 : 0;
      default:
        return 0;
    }
  }

  Widget _buildSearchBar() {
    final filterCount = _activeFilterCountForTab();
    return Container(
      height: 38.0,
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: context.colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _activeSearchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onChanged: (v) => setState(() => _searchQueries[_currentIndex] = v),
        onSubmitted: (_) => _submitSearch(),
        style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: context.colors.textPrimary,
        ),
        cursorColor: AppTheme.primary,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: _searchHintForTab(),
          hintStyle: TextStyle(color: context.colors.textMuted, fontSize: 14.0),
          prefixIcon: Icon(
            Icons.search,
            color: context.colors.textSecondary,
            size: 20.0,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_activeSearchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: context.colors.textSecondary,
                    size: 18.0,
                  ),
                  onPressed: () {
                    _activeSearchController.clear();
                    setState(() => _searchQueries[_currentIndex] = '');
                  },
                ),
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.tune_rounded,
                      color: filterCount > 0
                          ? AppTheme.primary
                          : context.colors.textSecondary,
                      size: 20.0,
                    ),
                    onPressed: _showActiveFilterSheet,
                  ),
                  if (filterCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  void _showActiveFilterSheet() {
    switch (_currentIndex) {
      case 0:
        _showExploreFilterSheet();
        break;
      case 1:
        _showTournamentFilterSheet();
        break;
      case 3:
        _showClubFilterSheet();
        break;
      case 4:
        _showRankingFilterSheet();
        break;
    }
  }

  void _showExploreFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String localSport = _exploreSport;
        String localStatus = _exploreStatus;
        String localContent = _exploreContent;
        String localBracket = _exploreBracket;
        String localRanked = _exploreRanked;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.86,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bộ lọc Khám phá',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.filterSport,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChips(
                    items: _activeSportFilterItems(l10n),
                    selected: localSport,
                    onSelected: (v) => setSheetState(() => localSport = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.filterStatus,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChips(
                    items: [
                      ('all', l10n.filterAll),
                      ('live', 'Trực tiếp'),
                      ('scheduled', l10n.matchesFilterScheduled),
                      ('completed', 'Đã kết thúc'),
                    ],
                    selected: localStatus,
                    onSelected: (v) => setSheetState(() => localStatus = v),
                  ),
                  const SizedBox(height: 16),
                  _buildExploreFilterGroup(
                    context,
                    title: 'Nội dung',
                    items: const [
                      ('all', 'Tất cả'),
                      ('SINGLE_MALE', 'Đơn nam'),
                      ('SINGLE_FEMALE', 'Đơn nữ'),
                      ('DOUBLE_MALE', 'Đôi nam'),
                      ('DOUBLE_FEMALE', 'Đôi nữ'),
                      ('DOUBLE_MIXED', 'Đôi nam nữ'),
                    ],
                    selected: localContent,
                    onSelected: (v) => setSheetState(() => localContent = v),
                  ),
                  const SizedBox(height: 16),
                  _buildExploreFilterGroup(
                    context,
                    title: 'Thể thức',
                    items: const [
                      ('all', 'Tất cả'),
                      ('SINGLE_ELIMINATION', 'Loại trực tiếp'),
                      ('DOUBLE_ELIMINATION', 'Nhánh thắng/thua'),
                      ('ROUND_ROBIN', 'Vòng tròn'),
                      ('GROUP_STAGE_KNOCKOUT', 'Vòng bảng + Playoff'),
                    ],
                    selected: localBracket,
                    onSelected: (v) => setSheetState(() => localBracket = v),
                  ),
                  const SizedBox(height: 16),
                  _buildExploreFilterGroup(
                    context,
                    title: 'Xếp hạng',
                    items: const [
                      ('all', 'Tất cả'),
                      ('ranked', 'Có tính ELO'),
                      ('unranked', 'Không tính ELO'),
                    ],
                    selected: localRanked,
                    onSelected: (v) => setSheetState(() => localRanked = v),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              localSport = 'all';
                              localStatus = 'all';
                              localContent = 'all';
                              localBracket = 'all';
                              localRanked = 'all';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.colors.textSecondary,
                            side: BorderSide(color: context.colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            l10n.filterReset,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _exploreSport = localSport;
                              _exploreStatus = localStatus;
                              _exploreContent = localContent;
                              _exploreBracket = localBracket;
                              _exploreRanked = localRanked;
                            });
                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            l10n.filterApply,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExploreFilterGroup(
    BuildContext context, {
    required String title,
    required List<(String, String)> items,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _buildFilterChips(
          items: items,
          selected: selected,
          onSelected: onSelected,
        ),
      ],
    );
  }

  void _showTournamentFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String localSport = _tournamentSport;
        String localStatus = _tournamentStatus;
        String localContent = _tournamentContent;
        String localBracket = _tournamentBracket;
        String localRanked = _tournamentRanked;
        String localProvince = _tournamentProvince;
        String localProvinceCode = _tournamentProvinceCode;
        String localDistrict = _tournamentDistrict;
        DateTime? localStartDate = _tournamentStartDate;
        DateTime? localEndDate = _tournamentEndDate;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bộ lọc Giải đấu',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.filterSport,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChips(
                    items: _activeSportFilterItems(l10n),
                    selected: localSport,
                    onSelected: (v) => setSheetState(() => localSport = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.filterStatus,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChips(
                    items: [
                      ('all', l10n.filterAll),
                      ('registration', l10n.matchesFilterRegistration),
                      ('upcoming', l10n.matchesFilterScheduled),
                      ('in_progress', 'Thi đấu'),
                      ('completed', l10n.matchesStatusCompleted),
                    ],
                    selected: localStatus,
                    onSelected: (v) => setSheetState(() => localStatus = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nội dung thi đấu',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChips(
                    items: [
                      ('all', l10n.filterAll),
                      ('SINGLE_MALE', l10n.singlesMale),
                      ('SINGLE_FEMALE', l10n.singlesFemale),
                      ('DOUBLE_MALE', l10n.doublesMale),
                      ('DOUBLE_FEMALE', l10n.doublesFemale),
                      ('DOUBLE_MIXED', l10n.doublesMixed),
                    ],
                    selected: localContent,
                    onSelected: (v) => setSheetState(() => localContent = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.filterFormat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChips(
                    items: [
                      ('all', l10n.filterAll),
                      ('single_elimination', l10n.eliminationSingle),
                      ('double_elimination', 'Thắng/thua'),
                      ('round_robin', l10n.roundRobin),
                      ('group_stage_knockout', 'Vòng bảng + playoff'),
                    ],
                    selected: localBracket,
                    onSelected: (v) => setSheetState(() => localBracket = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.filterScoring,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChips(
                    items: [
                      ('all', l10n.filterAll),
                      ('ranked', l10n.rankedELO),
                      ('unranked', l10n.unranked),
                    ],
                    selected: localRanked,
                    onSelected: (v) => setSheetState(() => localRanked = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.filterLocation,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tỉnh/Thành',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: context.colors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: localProvinceCode.isEmpty
                            ? null
                            : localProvinceCode,
                        isExpanded: true,
                        hint: Text(
                          'Tất cả',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: context.colors.textMuted,
                        ),
                        dropdownColor: context.colors.bgCard,
                        items: [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text(
                              'Tất cả',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                          ...ProvinceData.all.map(
                            (p) => DropdownMenuItem<String>(
                              value: p.code,
                              child: Text(
                                p.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setSheetState(() {
                          localProvinceCode = v ?? '';
                          localProvince = ProvinceData.all
                              .firstWhere(
                                (p) => p.code == localProvinceCode,
                                orElse: () => ProvinceData(
                                  code: localProvinceCode,
                                  name: '',
                                ),
                              )
                              .name;
                          localDistrict = '';
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Quận/Huyện',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Consumer(
                    builder: (context, ref, child) {
                      final districts = ref.watch(
                        districtsProvider(localProvinceCode),
                      );
                      final districtsList = districts.value ?? const [];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.colors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: localDistrict.isEmpty ? null : localDistrict,
                            isExpanded: true,
                            hint: Text(
                              localProvinceCode.isEmpty
                                  ? 'Chọn Tỉnh/Thành trước'
                                  : 'Tất cả',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.colors.textSecondary,
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: context.colors.textMuted,
                            ),
                            dropdownColor: context.colors.bgCard,
                            items: [
                              DropdownMenuItem<String>(
                                value: '',
                                child: Text(
                                  'Tất cả',
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                              ...districtsList.map(
                                (d) => DropdownMenuItem<String>(
                                  value: d.name,
                                  child: Text(
                                    d.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: localProvinceCode.isEmpty
                                ? null
                                : (v) => setSheetState(
                                    () => localDistrict = v ?? '',
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.filterDate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: localStartDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setSheetState(() => localStartDate = picked);
                            }
                          },
                          icon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                          ),
                          label: Text(
                            localStartDate == null
                                ? 'Từ ngày'
                                : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(localStartDate!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate:
                                  localEndDate ??
                                  localStartDate ??
                                  DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setSheetState(() => localEndDate = picked);
                            }
                          },
                          icon: const Icon(
                            Icons.event_available_rounded,
                            size: 16,
                          ),
                          label: Text(
                            localEndDate == null
                                ? 'Đến ngày'
                                : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(localEndDate!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              localSport = 'all';
                              localStatus = 'all';
                              localContent = 'all';
                              localBracket = 'all';
                              localRanked = 'all';
                              localProvince = '';
                              localProvinceCode = '';
                              localDistrict = '';
                              localStartDate = null;
                              localEndDate = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.colors.textSecondary,
                            side: BorderSide(color: context.colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            l10n.filterReset,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _tournamentSport = localSport;
                              _tournamentStatus = localStatus;
                              _tournamentContent = localContent;
                              _tournamentBracket = localBracket;
                              _tournamentRanked = localRanked;
                              _tournamentProvince = localProvince;
                              _tournamentProvinceCode = localProvinceCode;
                              _tournamentDistrict = localDistrict;
                              _tournamentStartDate = localStartDate;
                              _tournamentEndDate = localEndDate;
                            });
                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            l10n.filterApply,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClubFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String localSport = _clubSport;
        String? localProvinceCode = _clubProvinceCode;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bộ lọc Câu lạc bộ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.filterSport,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFilterChips(
                  items: _activeSportFilterItems(l10n),
                  selected: localSport,
                  onSelected: (v) => setSheetState(() => localSport = v),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tỉnh/Thành',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.colors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: localProvinceCode,
                      isExpanded: true,
                      hint: Text(
                        'Tất cả',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: context.colors.textMuted,
                      ),
                      dropdownColor: context.colors.bgCard,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Tất cả',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ),
                        ...ProvinceData.all.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p.code,
                            child: Text(
                              p.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setSheetState(() => localProvinceCode = v),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSheetState(() {
                            localSport = 'all';
                            localProvinceCode = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.textSecondary,
                          side: BorderSide(color: context.colors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.filterReset,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _clubSport = localSport;
                            _clubProvinceCode = localProvinceCode;
                          });
                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.filterApply,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRankingFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String localSport = _rankingsSport;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bộ lọc Xếp hạng ELO',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.filterSport,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFilterChips(
                  items: _activeSportFilterItems(l10n),
                  selected: localSport,
                  onSelected: (v) => setSheetState(() => localSport = v),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setSheetState(() => localSport = 'all'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.textSecondary,
                          side: BorderSide(color: context.colors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.filterReset,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _rankingsSport = localSport);
                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.filterApply,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips({
    required List<(String key, String label)> items,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSel = item.$1 == selected;
        return GestureDetector(
          onTap: () => onSelected(item.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSel ? AppTheme.primary : context.colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSel ? AppTheme.primary : context.colors.border,
              ),
            ),
            child: Text(
              item.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? Colors.white : context.colors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle({
    IconData? icon,
    Color? color,
    required String title,
    bool isLive = false,
    String? badge,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (isLive) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ],
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _PulsingDot(),
          ],
          const Spacer(),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12.0,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionEmptyCard(String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentCarousel(List<Tournament> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Khởi động timer chuyển trang tự động nếu chưa có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_carouselTimer == null) {
        _startCarouselTimer(items.length);
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth - 32.0; // padding 16 hai bên
            final cardHeight = cardWidth / (16 / 9);
            return SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _carouselController,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                onPageChanged: (index) {
                  setState(() {
                    _carouselCurrentPage = index;
                  });
                },
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FeaturedTournamentBannerCard(
                      tournament: items[i],
                      onTap: () => context.push("/intro/${items[i].id}"),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            final isSelected = _carouselCurrentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : context.colors.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.0,
            height: 72.0,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: Color(0xFFB0BEC5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Không tìm thấy giải đấu",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Thử thay đổi bộ lọc hoặc từ khoá",
            style: TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  /// Lọc "Nội dung thi đấu" — khớp chuẩn web: ưu tiên lọc theo từng division
  /// (match_type + gender_restriction, giống server-side web), fallback về
  /// format cấp cao nhất khi giải không có divisions.
  bool _matchesTournamentContent(Tournament t) {
    final sel = _tournamentContent;
    if (sel == 'all') return true;

    // 1) Lọc theo từng division (chuẩn tournament_divisions).
    for (final div in t.divisions) {
      if (_contentKey(div.matchType, div.genderRestriction) == sel) return true;
    }

    // 2) Fallback: giải đơn — dựa trên format top-level.
    return _contentKeyFromFormat(t.format) == sel;
  }

  /// Map (matchType, genderRestriction) → key nội dung thi đấu (SINGLE_MALE...).
  String? _contentKey(String? matchType, String? gender) {
    final mt = (matchType ?? '').toUpperCase();
    final gr = (gender ?? '').toUpperCase();
    if (mt.contains('MIXED')) return 'DOUBLE_MIXED';
    if (mt.contains('SINGLE')) {
      return gr == 'FEMALE' ? 'SINGLE_FEMALE' : 'SINGLE_MALE';
    }
    if (mt.contains('DOUBLE')) {
      if (gr == 'FEMALE') return 'DOUBLE_FEMALE';
      if (gr == 'MIXED') return 'DOUBLE_MIXED';
      return 'DOUBLE_MALE';
    }
    return null;
  }

  /// Map chuỗi format (men_doubles, women_singles, ...) → key nội dung.
  String? _contentKeyFromFormat(String format) {
    final f = format.toLowerCase();
    if (f.contains('mixed')) return 'DOUBLE_MIXED';
    if (f.contains('doubles')) {
      if (f.contains('women')) return 'DOUBLE_FEMALE';
      return 'DOUBLE_MALE';
    }
    if (f.contains('singles')) {
      if (f.contains('women')) return 'SINGLE_FEMALE';
      return 'SINGLE_MALE';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: GIẢI ĐẤU (Tournaments)
  // ═══════════════════════════════════════════════════════
  Widget _buildTournamentsTab(List<Tournament> tournaments) {
    final l10n = AppLocalizations.of(context)!;
    final String q = _normalizedQuery(_searchQueries[1]);
    final List<Tournament> filtered = tournaments.where((t) {
      final normalizedStatus = t.status.trim().toLowerCase();
      if (_tournamentSport != "all" && t.sport != _tournamentSport) {
        return false;
      }
      if (_tournamentStatus == "registration" &&
          normalizedStatus != "registration" &&
          normalizedStatus != "registration_open" &&
          normalizedStatus != "draft") {
        return false;
      }
      if (_tournamentStatus == "upcoming" &&
          normalizedStatus != "upcoming" &&
          normalizedStatus != "scheduled" &&
          normalizedStatus != "pending") {
        return false;
      }
      if (_tournamentStatus == "in_progress" &&
          normalizedStatus != "in_progress" &&
          normalizedStatus != "ongoing" &&
          normalizedStatus != "live") {
        return false;
      }
      if (_tournamentStatus == "completed" &&
          normalizedStatus != "completed" &&
          normalizedStatus != "finished" &&
          normalizedStatus != "done") {
        return false;
      }
      if (_tournamentContent != 'all' && !_matchesTournamentContent(t)) {
        return false;
      }
      if (_tournamentBracket != 'all' &&
          t.bracketType.toLowerCase() != _tournamentBracket) {
        return false;
      }
      if (_tournamentRanked == 'ranked' && !t.isRanked) {
        return false;
      }
      if (_tournamentRanked == 'unranked' && t.isRanked) {
        return false;
      }
      if (_tournamentProvince.isNotEmpty &&
          !(t.locationAddress ?? '').toLowerCase().contains(
            _tournamentProvince.toLowerCase(),
          )) {
        return false;
      }
      if (_tournamentDistrict.isNotEmpty &&
          !(t.locationAddress ?? '').toLowerCase().contains(
            _tournamentDistrict.toLowerCase(),
          )) {
        return false;
      }
      if (_tournamentStartDate != null &&
          (t.startDate == null ||
              t.startDate!.isBefore(_tournamentStartDate!))) {
        return false;
      }
      if (_tournamentEndDate != null &&
          (t.endDate == null || t.endDate!.isAfter(_tournamentEndDate!))) {
        return false;
      }
      if (q.isNotEmpty) {
        final haystack = [
          t.name,
          t.description,
          t.sport,
          t.format,
          t.bracketType,
          t.locationAddress ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
    final List<Tournament> displayList = filtered;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: _minHeaderHeight + 58.0)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StatusFilterDelegate(
            child: Container(
              color: context.colors.bgDark,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: StatusSegment(
                selected: _tournamentStatus,
                onChanged: (s) => setState(() => _tournamentStatus = s),
                items: [
                  (key: "all", label: l10n.filterAll),
                  (key: "registration", label: "Đăng ký"),
                  (key: "upcoming", label: l10n.matchesFilterScheduled),
                  (key: "in_progress", label: "Thi đấu"),
                  (key: "completed", label: l10n.matchesStatusCompleted),
                ],
              ),
            ),
          ),
        ),
        if (displayList.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48.0,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Không tìm thấy giải đấu phù hợp",
                    style: TextStyle(
                      fontSize: 16.0,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => TournamentCardWithBanner(
                  tournament: displayList[i],
                  onTap: () => context.push("/intro/${displayList[i].id}"),
                ),
                childCount: displayList.length,
              ),
            ),
          ),
      ],
    );
  }

  // ─── HELPERS ───

  // ═══════════════════════════════════════════════════════
  //  TAB 3: CÂU LẠC BỘ (Clubs) — Premium Card Design
  //  Inspired by web communities & profile pages
  // ═══════════════════════════════════════════════════════
  Widget _buildCommunityTab() {
    return _buildClubListWithApi();
  }

  Widget _buildClubListWithApi() {
    final l10n = AppLocalizations.of(context)!;
    final communitiesAsync = ref.watch(
      communitiesProvider((search: null, provinceCode: _clubProvinceCode)),
    );
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: _minHeaderHeight + 58.0)),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        communitiesAsync.when(
          data: (clubs) {
            final filtered = clubs.where((c) {
              if (_clubSport != 'all') {
                final hasSport = c.sports.any((s) {
                  final name = s.toLowerCase();
                  if (_clubSport == 'badminton' &&
                      (name.contains('badminton') ||
                          name.contains('cầu lông') ||
                          name.contains('cau long')))
                    return true;
                  if (_clubSport == 'tennis' && name.contains('tennis'))
                    return true;
                  if (_clubSport == 'pickleball' && name.contains('pickleball'))
                    return true;
                  return name.contains(_clubSport);
                });
                if (!hasSport) return false;
              }
              final q = _normalizedQuery(_searchQueries[3]);
              if (q.isNotEmpty &&
                  !c.name.toLowerCase().contains(q) &&
                  !(c.description ?? '').toLowerCase().contains(q)) {
                return false;
              }
              return true;
            }).toList();

            final display = filtered;
            if (display.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72.0,
                        height: 72.0,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: const Icon(
                          Icons.group_off_rounded,
                          size: 36,
                          color: Color(0xFFB0BEC5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Không tìm thấy câu lạc bộ",
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Thử thay đổi môn thể thao hoặc từ khoá tìm kiếm",
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildClubCardPremium(display[i]),
                  childCount: display.length,
                ),
              ),
            );
          },
          loading: () => SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Đang tải...',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          error: (e, st) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: context.colors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không thể tải danh sách CLB',
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.refresh(
                        communitiesProvider((
                          search: null,
                          provinceCode: _clubProvinceCode,
                        )),
                      ),
                      child: Text(l10n.matchesRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ─── Helpers ───
  Color _getSportColor(String sportName) {
    final n = sportName.toLowerCase();
    if (n.contains('badminton') || n.contains('cầu lông'))
      return const Color(0xFF0284C7);
    if (n.contains('tennis')) return const Color(0xFFEA580C);
    if (n.contains('pickleball')) return const Color(0xFF059669);
    if (n.contains('table tennis') ||
        n.contains('bóng bàn') ||
        n.contains('bong ban'))
      return const Color(0xFFDC2626);
    if (n.contains('bóng đá') || n.contains('football'))
      return const Color(0xFF16A34A);
    if (n.contains('bơi') || n.contains('swim')) return const Color(0xFF2563EB);
    if (n.contains('cờ') || n.contains('chess')) return const Color(0xFF7C3AED);
    return const Color(0xFF0284C7);
  }

  String _getSportEmoji(String sportName) {
    final n = sportName.toLowerCase();
    if (n.contains('badminton') || n.contains('cầu lông')) return '🏸';
    if (n.contains('tennis')) return '🎾';
    if (n.contains('pickleball')) return '🏓';
    if (n.contains('table tennis') || n.contains('bóng bàn')) return '🏓';
    if (n.contains('bóng đá') || n.contains('football')) return '⚽';
    if (n.contains('bơi') || n.contains('swim')) return '🏊';
    if (n.contains('cờ') || n.contains('chess')) return '♟️';
    return '🏆';
  }

  String _getJoinModeLabel(String mode) {
    switch (mode) {
      case 'INVITE_ONLY':
        return 'Chỉ mời';
      case 'APPROVAL':
        return 'Xét duyệt';
      default:
        return 'Tự do';
    }
  }

  Color _getJoinModeColor(String mode) {
    switch (mode) {
      case 'INVITE_ONLY':
        return const Color(0xFFE11D48);
      case 'APPROVAL':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF059669);
    }
  }

  /// ═══════════════════════════════════════════════════════
  ///  PREMIUM CLUB CARD — Full-width, inspired by web
  /// ═══════════════════════════════════════════════════════
  Widget _buildClubCardPremium(Community club) {
    final l10n = AppLocalizations.of(context)!;
    final sportName = club.sports.isNotEmpty ? club.sports.first : "";
    final Color sportColor = _getSportColor(sportName);
    final String emoji = _getSportEmoji(sportName);
    final String joinLabel = _getJoinModeLabel(club.joinMode);
    final Color joinColor = _getJoinModeColor(club.joinMode);
    final bool hasBanner = club.bannerUrl != null && club.bannerUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => context.push("/club/${club.id}"),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: context.colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Banner Area ───
                  SizedBox(
                    height: 185.0,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasBanner)
                          Image.network(
                            club.bannerUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildCardBannerFallback(sportColor, emoji),
                          )
                        else
                          _buildCardBannerFallback(sportColor, emoji),

                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Join mode badge
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: joinColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  joinLabel,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: joinColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Content Area ───
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 32, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Club name (no fake verified tick)
                        Text(
                          club.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: context.colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Stats (Members & Location)
                        Row(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 14,
                              color: context.colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${club.memberCount > 0 ? club.memberCount : 2} thành viên",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: context.colors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                (club.locationAddress != null &&
                                        club.locationAddress!.trim().isNotEmpty)
                                    ? club.locationAddress!.trim()
                                    : l10n.vietnam,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // All Sports Tags (Pills)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: (() {
                              final List<String> sports = [];
                              if (club.sports.isNotEmpty) {
                                for (final s in club.sports) {
                                  final sTrim = s.trim();
                                  if (sTrim.isEmpty) continue;
                                  final mapped =
                                      AppConstants.sportNames[sTrim] ??
                                      AppConstants.sportNames[sTrim
                                          .toLowerCase()] ??
                                      sTrim;
                                  if (!sports.contains(mapped))
                                    sports.add(mapped);
                                }
                              }
                              if (sports.isEmpty) {
                                sports.add('THỂ THAO');
                              }
                              return sports.map((sName) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sportColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: sportColor.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    sName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: sportColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                );
                              }).toList();
                            })(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Floating Circular Logo — centered over bottom edge of banner (top: 157)
              Positioned(
                top: 157,
                left: 14,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.bgCard,
                    border: Border.all(
                      color: context.colors.bgCard,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                        ? Image.network(
                            club.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildCardLogoFallback(),
                          )
                        : _buildCardLogoFallback(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardLogoFallback() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: SvgPicture.asset(AppConstants.logoFullSvg, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildCardBannerFallback(Color sportColor, String emoji) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)]
              : const [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: SvgPicture.asset(
            AppConstants.logoFullSvg,
            width: 180,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  LOADING & ERROR
  // ─────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.primary,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildErrorState(Object e) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFB0BEC5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$e',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => ref.refresh(tournamentsProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.matchesRetry,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TOURNAMENT CARD — Horizontal scroll (Gradient)
// ═══════════════════════════════════════════════════════
class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  const _TournamentCard({required this.tournament, required this.onTap});

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;

    String apiBase = 'http://localhost:3000/api/v1';
    try {
      apiBase = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
      if (!kIsWeb && Platform.isAndroid && apiBase.contains('localhost')) {
        apiBase = apiBase.replaceAll('localhost', '10.0.2.2');
      }
    } catch (_) {}

    final host = apiBase.replaceAll('/api/v1', '');
    return '$host$url';
  }

  List<String> _getCategoryChips(Tournament t) {
    final List<String> chips = [];

    // 1. Kiểm tra chính xác từ danh sách Divisions trả về từ API
    if (t.divisions.isNotEmpty) {
      for (var div in t.divisions) {
        final mt = div.matchType.toUpperCase();
        final gr = div.genderRestriction?.toUpperCase() ?? '';
        if (mt == 'SINGLES') {
          if (gr == 'FEMALE')
            chips.add("Đơn Nữ");
          else if (gr == 'MALE')
            chips.add("Đơn Nam");
          else
            chips.add("Đơn");
        } else if (mt == 'DOUBLES') {
          if (gr == 'FEMALE')
            chips.add("Đôi Nữ");
          else if (gr == 'MALE')
            chips.add("Đôi Nam");
          else if (gr == 'MIXED')
            chips.add("Đôi Nam Nữ");
          else
            chips.add("Đôi Nam");
        } else if (mt == 'MIXED_DOUBLES' || mt == 'MIXED' || gr == 'MIXED') {
          chips.add("Đôi Nam Nữ");
        }
      }
    }

    // 2. Nếu API không chứa Divisions, đọc thuộc tính gốc của Tournament
    if (chips.isEmpty) {
      final mt = t.format.toUpperCase();
      if (mt.contains('DOUBLES') || t.maxPlayersPerTeam == 2) {
        final nameLower = t.name.toLowerCase();
        final descLower = t.description.toLowerCase();
        if (nameLower.contains("nam nữ") ||
            descLower.contains("nam nữ") ||
            descLower.contains("đôi nam nữ")) {
          chips.add("Đôi Nam Nữ");
        } else if (nameLower.contains("đôi nữ") ||
            descLower.contains("đôi nữ")) {
          chips.add("Đôi Nữ");
        } else {
          chips.add("Đôi Nam");
        }
      } else {
        chips.add("Đơn Nam");
      }
    }

    return chips.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = StatusHelper.getTournamentStatusLabel(
      tournament.status,
    ).toUpperCase();
    final sportLabel =
        AppConstants.sportNames[tournament.sport]?.toUpperCase() ??
        tournament.sport.toUpperCase();

    final dateStr = (tournament.startDate != null && tournament.endDate != null)
        ? '${DateFormat('dd/MM/yyyy').format(tournament.startDate!)} - ${DateFormat('dd/MM/yyyy').format(tournament.endDate!)}'
        : 'Chưa cập nhật ngày';

    final categoryChips = _getCategoryChips(tournament);

    final bannerUrlResolved = _resolveImageUrl(tournament.bannerUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top: Banner Image Area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 125,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),
                    child: bannerUrlResolved.isNotEmpty
                        ? Image.network(
                            bannerUrlResolved,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildFallbackBanner(),
                          )
                        : _buildFallbackBanner(),
                  ),
                  // Top left: Sport badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sportLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Top right: Status badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: StatusHelper.getTournamentStatusColor(
                          tournament.status,
                          context,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom: Tournament Details Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tournament Name
                    Text(
                      tournament.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (categoryChips.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: categoryChips.take(3).map((div) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFDBEAFE),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              div,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const Spacer(),

                    // Date & Participant count row
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${tournament.maxTeams} Đội',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  Widget _buildFallbackBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.sports_tennis_rounded, color: Colors.white, size: 42),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TOURNAMENT LIST CARD — For Giải đấu tab
// ═══════════════════════════════════════════════════════
class _TournamentListCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  const _TournamentListCard({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = StatusHelper.getTournamentStatusColor(
      tournament.status,
      context,
    );
    final statusLabel = StatusHelper.getTournamentStatusLabel(
      tournament.status,
    );
    final sportLabel =
        AppConstants.sportNames[tournament.sport] ?? tournament.sport;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sportLabel  •  ${tournament.maxTeams} đội',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: sc,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PULSING DOT — for Live badge
// ═══════════════════════════════════════════════════════
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double p;
  final Widget searchBar;
  final Color backgroundColor;
  final double minHeaderHeight;

  _StickyHeaderDelegate({
    required this.p,
    required this.searchBar,
    required this.backgroundColor,
    required this.minHeaderHeight,
  });

  @override
  double get minExtent => 54.0 * p;

  @override
  double get maxExtent => 54.0 * p;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: p,
              child: Opacity(opacity: p, child: searchBar),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return p != oldDelegate.p ||
        backgroundColor != oldDelegate.backgroundColor ||
        searchBar != oldDelegate.searchBar;
  }
}

class _StatusFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StatusFilterDelegate({required this.child});

  @override
  double get minExtent => 52.0;

  @override
  double get maxExtent => 52.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StatusFilterDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

class _TournamentSectionList extends ConsumerWidget {
  final List<Tournament> tournaments;
  final String filterStatus;
  final String searchQuery;
  final String contentFilter;
  final String bracketFilter;
  final String rankedFilter;
  final bool enabled;
  final String emptyMessage;

  const _TournamentSectionList({
    required this.tournaments,
    required this.filterStatus,
    this.searchQuery = '',
    this.contentFilter = 'all',
    this.bracketFilter = 'all',
    this.rankedFilter = 'all',
    this.enabled = true,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return const SliverToBoxAdapter(child: SizedBox.shrink());
    if (tournaments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final activeTournaments = <Tournament>[];
    var hasLoadingMatches = false;
    var hasMatchError = false;

    for (final t in tournaments) {
      final matchesAsync = ref.watch(matchesProvider(t.id));
      if (matchesAsync.isLoading) {
        hasLoadingMatches = true;
        continue;
      }
      if (matchesAsync.hasError) {
        hasMatchError = true;
        continue;
      }
      final matches = matchesAsync.value ?? const <MatchModel>[];
      final valid = matches.where((m) {
        final t1 = m.team1Name.trim().toUpperCase();
        final t2 = m.team2Name.trim().toUpperCase();
        final isT1Bye = t1 == 'BYE';
        final isT2Bye = t2 == 'BYE';
        final isT1Tbd =
            !isT1Bye && (t1.isEmpty || t1 == 'TBD') && m.team1Id.trim().isEmpty;
        final isT2Tbd =
            !isT2Bye && (t2.isEmpty || t2 == 'TBD') && m.team2Id.trim().isEmpty;
        if (isT1Bye || isT2Bye || (isT1Tbd && isT2Tbd)) return false;

        final q = searchQuery.trim().toLowerCase();
        final matchText = '${m.team1Name} ${m.team2Name} ${m.tournamentName}'
            .toLowerCase();
        if (q.isNotEmpty && !matchText.contains(q)) return false;

        if (filterStatus == 'live') return m.isLive;
        if (filterStatus == 'completed') return m.isCompleted;
        if (filterStatus == 'scheduled') {
          // Do not classify an unknown/failed response as scheduled. Only
          // persisted not-started matches belong in the upcoming section.
          return m.isScheduled ||
              (m.scheduledTime != null && !m.isLive && !m.isCompleted);
        }
        return true;
      });

      if (valid.isNotEmpty) {
        activeTournaments.add(t);
      }
    }

    if (activeTournaments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: Text(
              hasLoadingMatches
                  ? 'Đang tải dữ liệu trận đấu...'
                  : hasMatchError
                  ? 'Không tải được dữ liệu trận đấu. Vui lòng thử lại.'
                  : emptyMessage,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => LiveTournamentWithMatchesCard(
            tournament: activeTournaments[index],
            filterStatus: filterStatus,
          ),
          childCount: activeTournaments.length,
        ),
      ),
    );
  }
}
