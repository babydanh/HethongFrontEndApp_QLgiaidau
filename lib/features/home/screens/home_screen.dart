import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';

import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
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
import 'package:app_quanly_giaidau/features/rankings/screens/leaderboard_screen.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:intl/intl.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';

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
  String _exploreStatus = 'live';
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
  String _tournamentProvinceCode = ''; // mã tỉnh — để tải phường/xã
  String _tournamentWard = ''; // tên phường/xã
  DateTime? _tournamentStartDate;
  DateTime? _tournamentEndDate;

  // ─── Server-side Cursor Pagination states (Tab 1: Giải đấu) ───
  final List<Tournament> _serverTournamentsList = [];
  String? _serverTournamentNextCursor;
  bool _isTournamentInitialLoading = true;
  bool _isTournamentLoadingMore = false;
  bool _serverTournamentHasMore = false;

  // ─── Server-side Cursor Pagination states (Tab 3: Câu lạc bộ) ───
  final List<Community> _serverClubsList = [];
  String? _serverClubNextCursor;
  bool _isClubInitialLoading = true;
  bool _isClubLoadingMore = false;
  bool _serverClubHasMore = false;
  static const int _clubsPageSize = 6;

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
    _resetTournamentCursorPagination();
    _resetClubCursorPagination();
  }

  Future<void> _fetchServerTournamentPage({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (_isTournamentLoadingMore ||
          !_serverTournamentHasMore ||
          _serverTournamentNextCursor == null) {
        return;
      }
      setState(() => _isTournamentLoadingMore = true);
    } else {
      setState(() => _isTournamentInitialLoading = true);
    }

    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final result = await repo.getPublicTournamentsPaged(
        cursor: isLoadMore ? _serverTournamentNextCursor : null,
        limit: 6,
        sport: _tournamentSport,
        status: _tournamentStatus,
        search: _searchQueries[1]?.trim(),
        content: _tournamentContent,
        bracket: _tournamentBracket,
        ranked: _tournamentRanked,
        province: _tournamentProvince.isNotEmpty ? _tournamentProvince : null,
        ward: _tournamentWard.isNotEmpty ? _tournamentWard : null,
        startDate: _tournamentStartDate,
        endDate: _tournamentEndDate,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            final existingIds =
                _serverTournamentsList.map((t) => t.id).toSet();
            final uniqueNew = result.tournaments
                .where((t) => !existingIds.contains(t.id));
            _serverTournamentsList.addAll(uniqueNew);
          } else {
            _serverTournamentsList.clear();
            _serverTournamentsList.addAll(result.tournaments);
          }
          _serverTournamentNextCursor = result.nextCursor;
          _serverTournamentHasMore =
              result.hasMore && (result.nextCursor?.isNotEmpty ?? false);
          _isTournamentInitialLoading = false;
          _isTournamentLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTournamentInitialLoading = false;
          _isTournamentLoadingMore = false;
        });
      }
    }
  }

  void _resetTournamentCursorPagination() {
    _fetchServerTournamentPage(isLoadMore: false);
  }

  Future<void> _fetchServerClubPage({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (_isClubLoadingMore ||
          !_serverClubHasMore ||
          _serverClubNextCursor == null) {
        return;
      }
      setState(() => _isClubLoadingMore = true);
    } else {
      setState(() => _isClubInitialLoading = true);
    }

    try {
      final repo = ref.read(communityRepositoryProvider);
      final result = await repo.getCommunitiesPaged(
        cursor: isLoadMore ? _serverClubNextCursor : null,
        limit: _clubsPageSize,
        search: _searchQueries[3]?.trim(),
        provinceCode: _clubProvinceCode,
        categoryId: _clubSport != 'all' ? _clubSport : null,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            final existingIds = _serverClubsList.map((c) => c.id).toSet();
            final uniqueNew = result.communities
                .where((c) => !existingIds.contains(c.id));
            _serverClubsList.addAll(uniqueNew);
          } else {
            _serverClubsList.clear();
            _serverClubsList.addAll(result.communities);
          }
          _serverClubNextCursor = result.nextCursor;
          _serverClubHasMore =
              result.hasMore && (result.nextCursor?.isNotEmpty ?? false);
          _isClubInitialLoading = false;
          _isClubLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isClubInitialLoading = false;
          _isClubLoadingMore = false;
        });
      }
    }
  }

  void _resetClubCursorPagination() {
    _fetchServerClubPage(isLoadMore: false);
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
  PageController? _carouselController;
  Timer? _carouselTimer;
  int _carouselCurrentPage = 0;

  double get _safeAreaTop => MediaQuery.of(context).padding.top;
  double get _headerHeight => 84.0 + _safeAreaTop;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _carouselController = PageController(viewportFraction: 1.0);
    _fetchServerTournamentPage(isLoadMore: false);
    _fetchServerClubPage(isLoadMore: false);
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
          _carouselController!.positions.length != 1) {
        return;
      }
      _carouselCurrentPage = (_carouselCurrentPage + 1) % itemCount;
      _carouselController!.animateToPage(
        _carouselCurrentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController?.dispose();
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
    if (index == 1 && _serverTournamentsList.isEmpty) {
      _fetchServerTournamentPage(isLoadMore: false);
    } else if (index == 3 && _serverClubsList.isEmpty) {
      _fetchServerClubPage(isLoadMore: false);
    }
  }

  void _submitSearch() {
    _searchFocusNode.unfocus();
    if (_currentIndex == 1) {
      _resetTournamentCursorPagination();
    } else if (_currentIndex == 3) {
      _resetClubCursorPagination();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentsAsync = ref.watch(tournamentsProvider);
    final screenSize = MediaQuery.of(context).size;
    final double safeAreaTop = _safeAreaTop;
    final isHomeTab = _currentIndex == 0;
    final activeHeaderHeight = _headerHeight;

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
            // Shared Fixed Locked Top Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _headerHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: "Sporto_header_bg",
                      child: CustomPaint(
                        size: Size(screenSize.width, _headerHeight),
                        painter: SportoHeaderPainter(
                          isLoggedIn: false,
                          colors: context.colors,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: safeAreaTop + 14.0,
                    left: 16.0,
                    right: 16.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left: Sport filter dropdown
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
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
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
                                  ? l10n.homeClubTab
                                  : _currentIndex == 4
                                  ? l10n.homeRankingsTab
                                  : l10n.sporto,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                        // Right: Notification Bell & Chat
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildNotificationBellHeader(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Floating Sticky Search Bar pinned directly below Header
            if (_shouldShowSearchBar)
              Positioned(
                top: _headerHeight + 6.0,
                left: 16.0,
                right: 16.0,
                child: _buildSearchBar(),
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
    
    switch (_currentIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('explore'),
          child: _buildExploreTab(tournamentsAsync),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('tournaments'),
          child: _buildTournamentsTab(),
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
                      child: SizedBox(height: _headerHeight + 52.0),
                    ),
                    if (!ref.watch(authProvider).isAuthenticated)
                      SliverToBoxAdapter(
                        child: _buildGuestLoginNoticeBanner(l10n),
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
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StatusFilterDelegate(
                        child: _buildExploreSegmentTabBar(l10n),
                      ),
                    ),
                    _TournamentSectionList(
                      tournaments: allTournaments,
                      sectionTitle: null,
                      isLive: _exploreStatus == 'live',
                      filterStatus: _exploreStatus,
                      searchQuery: _searchQueries[0] ?? '',
                      contentFilter: _exploreContent,
                      bracketFilter: _exploreBracket,
                      rankedFilter: _exploreRanked,
                      enabled: true,
                      emptyMessage: _exploreStatus == 'live'
                          ? l10n.noLiveMatches
                          : _exploreStatus == 'scheduled'
                              ? l10n.noUpcomingMatches
                              : l10n.homeNoCompletedMatches,
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
                  SliverToBoxAdapter(
                    child: SizedBox(height: _headerHeight + 52.0),
                  ),
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (e, st) => CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: _headerHeight + 52.0),
                  ),
                  SliverFillRemaining(child: _buildErrorState(e)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBellHeader() {
    final unreadAsync = ref.watch(unreadCountProvider);
    final unread = unreadAsync.value ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            final auth = ref.read(authProvider);
            if (!auth.isAuthenticated) {
              context.push('/login');
            } else {
              context.push('/chat');
            }
          },
          child: Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.forum_outlined,
              color: Colors.white,
              size: 19,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push("/notifications"),
          child: Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
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
        ),
      ],
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

  Widget _buildGuestLoginNoticeBanner(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.homeWelcomeTitle,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.homeLoginForStats,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.loginButton),
          ),
        ],
      ),
    );
  }

  String _searchHintForTab() {
    final l10n = AppLocalizations.of(context)!;
    return switch (_currentIndex) {
      0 => l10n.homeSearchMatchesHint,
      1 => l10n.homeSearchTournamentsHint,
      3 => l10n.homeSearchClubsHint,
      4 => l10n.homeSearchAthletesHint,
      _ => l10n.homeSearchGenericHint,
    };
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
            color: Colors.black.withValues(alpha: 0.04),
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
                    l10n.homeExploreFilterTitle,
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
                      ('live', l10n.homeLiveStatus),
                      ('scheduled', l10n.matchesFilterScheduled),
                      ('completed', l10n.homeCompletedStatus),
                    ],
                    selected: localStatus,
                    onSelected: (v) => setSheetState(() => localStatus = v),
                  ),
                  const SizedBox(height: 16),
                  _buildExploreFilterGroup(
                    context,
                    title: l10n.filterContent,
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
                  _buildExploreFilterGroup(
                    context,
                    title: l10n.filterFormat,
                    items: [
                      ('all', l10n.filterAll),
                      ('SINGLE_ELIMINATION', l10n.eliminationSingle),
                      ('DOUBLE_ELIMINATION', l10n.eliminationDouble),
                      ('ROUND_ROBIN', l10n.roundRobin),
                      ('GROUP_STAGE_KNOCKOUT', l10n.groupStage),
                    ],
                    selected: localBracket,
                    onSelected: (v) => setSheetState(() => localBracket = v),
                  ),
                  const SizedBox(height: 16),
                  _buildExploreFilterGroup(
                    context,
                    title: l10n.homeRankingFilter,
                    items: [
                      ('all', l10n.filterAll),
                      ('ranked', l10n.homeRankedYes),
                      ('unranked', l10n.homeRankedNo),
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
        String localWard = _tournamentWard;
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
                    l10n.homeTournamentFilterTitle,
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
                      ('in_progress', l10n.homeInProgressStatus),
                      ('completed', l10n.matchesStatusCompleted),
                    ],
                    selected: localStatus,
                    onSelected: (v) => setSheetState(() => localStatus = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.homeCompetitionContent,
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
                      ('double_elimination', l10n.homeFormatDoubleElimination),
                      ('round_robin', l10n.roundRobin),
                      (
                        'group_stage_knockout',
                        l10n.homeFormatGroupStagePlayoff,
                      ),
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
                    l10n.homeLocationProvince,
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
                          l10n.filterAll,
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
                              l10n.filterAll,
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
                          localWard = '';
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.homeLocationWard,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Consumer(
                    builder: (context, ref, child) {
                      final wards = ref.watch(wardsProvider(localProvinceCode));
                      final wardsList = wards.value ?? const [];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.colors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: localWard.isEmpty ? null : localWard,
                            isExpanded: true,
                            hint: Text(
                              localProvinceCode.isEmpty
                                  ? l10n.homeSelectProvinceFirst
                                  : l10n.filterAll,
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
                                  l10n.filterAll,
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                              ...wardsList.map(
                                (ward) => DropdownMenuItem<String>(
                                  value: ward.name,
                                  child: Text(
                                    ward.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: localProvinceCode.isEmpty
                                ? null
                                : (v) =>
                                      setSheetState(() => localWard = v ?? ''),
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
                                ? l10n.homeFromDate
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
                                ? l10n.homeToDate
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
                              localWard = '';
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
                              _tournamentWard = localWard;
                              _tournamentStartDate = localStartDate;
                              _tournamentEndDate = localEndDate;
                            });
                            _resetTournamentCursorPagination();
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
                  l10n.homeClubFilterTitle,
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
                  l10n.homeLocationProvince,
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
                        l10n.filterAll,
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
                            l10n.filterAll,
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
                          _resetClubCursorPagination();
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
                  l10n.homeRankingFilterTitle,
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

  Widget _buildExploreSegmentTabBar(AppLocalizations l10n) {
    final colors = context.colors;
    return Container(
      color: colors.bgDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Row(
          children: [
            _buildExploreTabButton(
              label: l10n.homeLiveStatus,
              statusKey: 'live',
              isLive: true,
            ),
            _buildExploreTabButton(
              label: l10n.matchesFilterScheduled,
              statusKey: 'scheduled',
            ),
            _buildExploreTabButton(
              label: l10n.homeCompletedStatus,
              statusKey: 'completed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTabButton({
    required String label,
    required String statusKey,
    bool isLive = false,
  }) {
    final isSelected = _exploreStatus == statusKey;
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _exploreStatus = statusKey);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLive) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ],
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.0,
            height: 72.0,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: Color(0xFFB0BEC5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.homeNoTournaments,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeNoTournamentsHint,
            style: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: GIẢI ĐẤU (Tournaments) — Server-Side Cursor Stream (Load More)
  // ═══════════════════════════════════════════════════════
  Widget _buildTournamentsTab() {
    final l10n = AppLocalizations.of(context)!;
    final currentList = _serverTournamentsList;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: _headerHeight + 52.0)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StatusFilterDelegate(
            child: Container(
              color: context.colors.bgDark,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: StatusSegment(
                selected: _tournamentStatus,
                onChanged: (s) {
                  setState(() => _tournamentStatus = s);
                  _resetTournamentCursorPagination();
                },
                items: [
                  (key: "all", label: l10n.filterAll),
                  (key: "registration", label: l10n.matchesFilterRegistration),
                  (key: "upcoming", label: l10n.matchesFilterScheduled),
                  (key: "in_progress", label: l10n.homeInProgressStatus),
                  (key: "completed", label: l10n.matchesStatusCompleted),
                ],
              ),
            ),
          ),
        ),
        if (_isTournamentInitialLoading && currentList.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          )
        else if (currentList.isEmpty)
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
                    l10n.homeNoMatchingTournaments,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => TournamentCardWithBanner(
                  tournament: currentList[i],
                  onTap: () => context.push("/intro/${currentList[i].id}"),
                ),
                childCount: currentList.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildCursorLoadMoreBar(
              isLoadingMore: _isTournamentLoadingMore,
              hasMore: _serverTournamentHasMore,
              loadMoreLabel: 'Xem thêm giải đấu',
              allLoadedLabel: 'Đã hiển thị tất cả giải đấu',
              onLoadMore: () =>
                  _fetchServerTournamentPage(isLoadMore: true),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCursorLoadMoreBar({
    required bool isLoadingMore,
    required bool hasMore,
    required String loadMoreLabel,
    required String allLoadedLabel,
    required VoidCallback? onLoadMore,
  }) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: Center(
        child: hasMore
            ? SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: isLoadingMore ? null : onLoadMore,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.bgCard,
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(
                        color: colors.border.withValues(alpha: 0.8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppTheme.primary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.expand_more_rounded, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              loadMoreLabel,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        allLoadedLabel,
                        style: TextStyle(
                          color: colors.textMuted.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
      ),
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
    final currentList = _serverClubsList;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: _headerHeight + 52.0)),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        if (_isClubInitialLoading && currentList.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          )
        else if (currentList.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72.0,
                    height: 72.0,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Icon(
                      Icons.group_off_rounded,
                      size: 36,
                      color: Color(0xFFB0BEC5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.homeNoClubs,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.homeNoClubsHint,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          )
        else
          SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildClubCardPremium(currentList[i]),
                    childCount: currentList.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildCursorLoadMoreBar(
                  isLoadingMore: _isClubLoadingMore,
                  hasMore: _serverClubHasMore,
                  loadMoreLabel: 'Xem thêm câu lạc bộ',
                  allLoadedLabel: 'Đã hiển thị tất cả câu lạc bộ',
                  onLoadMore: () =>
                      _fetchServerClubPage(isLoadMore: true),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// ─── Helpers ───
  Color _getSportColor(String sportName) {
    final n = sportName.toLowerCase();
    if (n.contains('badminton') || n.contains('cầu lông')) {
      return const Color(0xFF0284C7);
    }
    if (n.contains('tennis')) {
      return const Color(0xFFEA580C);
    }
    if (n.contains('pickleball')) {
      return const Color(0xFF059669);
    }
    if (n.contains('table tennis') ||
        n.contains('bóng bàn') ||
        n.contains('bong ban')) {
      return const Color(0xFFDC2626);
    }
    if (n.contains('bóng đá') || n.contains('football')) {
      return const Color(0xFF16A34A);
    }
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

  String _getJoinModeLabel(String mode, AppLocalizations l10n) {
    switch (mode) {
      case 'INVITE_ONLY':
        return l10n.homeInviteOnly;
      case 'APPROVAL':
        return l10n.homeApproval;
      default:
        return l10n.homeOpenJoin;
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
    final String joinLabel = _getJoinModeLabel(club.joinMode, l10n);
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
                            errorBuilder: (_, _, _) =>
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
                              l10n.homeMembersCount(
                                club.memberCount > 0 ? club.memberCount : 2,
                              ),
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
                                  final mapped = l10n.sportDisplayName(sTrim);
                                  if (!sports.contains(mapped)) {
                                    sports.add(mapped);
                                  }
                                }
                              }
                              if (sports.isEmpty) {
                                sports.add(l10n.homeSportFallback);
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
                            errorBuilder: (_, _, _) => _buildCardLogoFallback(),
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
            Text(
              l10n.homeDataLoadError,
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
  final String? sectionTitle;
  final bool isLive;

  const _TournamentSectionList({
    required this.tournaments,
    required this.filterStatus,
    this.searchQuery = '',
    this.contentFilter = 'all',
    this.bracketFilter = 'all',
    this.rankedFilter = 'all',
    this.enabled = true,
    required this.emptyMessage,
    this.sectionTitle,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (!enabled) return const SliverToBoxAdapter(child: SizedBox.shrink());
    if (tournaments.isEmpty) {
      if (searchQuery.isNotEmpty) {
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
      return const SliverToBoxAdapter(child: SizedBox.shrink());
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
        if (filterStatus == 'completed') {
          final status = m.status.toUpperCase();
          return m.isCompleted ||
              status == 'COMPLETED' ||
              status == 'FINISHED' ||
              status == 'DONE' ||
              status == 'ENDED' ||
              m.completedAt != null;
        }
        if (filterStatus == 'scheduled') {
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
      if (searchQuery.isNotEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text(
                hasLoadingMatches
                    ? l10n.homeMatchesLoading
                    : hasMatchError
                    ? l10n.homeMatchesLoadError
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
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(
      slivers: [
        if (sectionTitle != null && sectionTitle!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    sectionTitle!,
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
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.zero,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => LiveTournamentWithMatchesCard(
                tournament: activeTournaments[index],
                filterStatus: filterStatus,
              ),
              childCount: activeTournaments.length,
            ),
          ),
        ),
      ],
    );
  }
}
