import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/widgets/club_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/widgets/liquid_glass_surface.dart';

import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_header.dart';
import 'package:app_quanly_giaidau/features/home/widgets/featured_tournament_banner_card.dart';
import 'package:app_quanly_giaidau/data/models/home_projection.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_card_with_banner.dart';
import 'package:app_quanly_giaidau/core/widgets/status_segment.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/leaderboard_screen.dart';
import 'package:app_quanly_giaidau/features/social/screens/social_list_view.dart';

import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/home/widgets/global_search_screen.dart';

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
  final int initialSubTab;
  const HomeScreen({super.key, this.initialTab = 0, this.initialSubTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _exploreSubTabIndex = 0; // 0: CLB (default), 1: Social
  // Animation controller for compacting/expanding header on scroll
  late final AnimationController _collapseAnimController;
  late final Animation<double> _collapseProgress;
  double _lastScrollOffset = 0.0;
  // Home query state feeds existing per-tab result filters.
  final Map<int, String> _searchQueries = {0: '', 1: '', 3: '', 4: ''};

  // ─── Per-tab filter state ───
  String _exploreSport = 'all';
  String _exploreStatus = 'live';
  String _tournamentSport = 'all';
  String _tournamentStatus = 'all';
  String _clubSport = 'all';
  String? _clubProvinceCode;
  String _rankingsSport = 'all';

  // ─── Server-side Cursor Pagination states (Tab 1: Giải đấu) ───
  final List<Tournament> _serverTournamentsList = [];
  String? _serverTournamentNextCursor;
  bool _isTournamentInitialLoading = true;
  bool _isTournamentLoadingMore = false;
  bool _serverTournamentHasMore = false;
  int _tournamentRequestVersion = 0;

  // ─── Server-side Cursor Pagination states (Tab 3: Câu lạc bộ) ───
  final List<Community> _serverClubsList = [];
  String? _serverClubNextCursor;
  bool _isClubInitialLoading = true;
  bool _isClubLoadingMore = false;
  bool _serverClubHasMore = false;
  int _clubRequestVersion = 0;
  static const int _clubsPageSize = 6;

  // Show the global search action only on searchable public tabs.
  bool get _shouldShowGlobalSearchButton =>
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
      _exploreStatus = 'live';
      _exploreSport = key;
      _tournamentSport = key;
      _clubSport = key;
      _rankingsSport = key == 'all' ? 'pickleball' : key;
      if (_currentIndex != 1) {
        ++_tournamentRequestVersion;
        _serverTournamentsList.clear();
        _serverTournamentNextCursor = null;
        _serverTournamentHasMore = false;
        _isTournamentInitialLoading = true;
      }
      if (_currentIndex != 3) {
        ++_clubRequestVersion;
        _serverClubsList.clear();
        _serverClubNextCursor = null;
        _serverClubHasMore = false;
        _isClubInitialLoading = true;
      }
    });
    if (_currentIndex == 1) _resetTournamentCursorPagination();
    if (_currentIndex == 3) _resetClubCursorPagination();
  }

  Future<String?> _resolveTournamentCategoryId(String sportKey) async {
    if (sportKey == 'all') return null;

    final categories = await ref.read(categoriesProvider.future);
    for (final category in categories) {
      if (category.slug == sportKey) return category.id;
    }
    throw StateError('Selected tournament category is unavailable');
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
    final requestVersion = ++_tournamentRequestVersion;

    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final categoryId = await _resolveTournamentCategoryId(_tournamentSport);
      if (!mounted || requestVersion != _tournamentRequestVersion) return;
      final result = await repo.getPublicTournamentsPaged(
        cursor: isLoadMore ? _serverTournamentNextCursor : null,
        limit: 6,
        categoryId: categoryId,
        status: _tournamentStatus,
        search: _searchQueries[1]?.trim(),
      );

      if (mounted && requestVersion == _tournamentRequestVersion) {
        setState(() {
          if (isLoadMore) {
            final existingIds = _serverTournamentsList.map((t) => t.id).toSet();
            final uniqueNew = result.tournaments.where(
              (t) => !existingIds.contains(t.id),
            );
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
      if (mounted && requestVersion == _tournamentRequestVersion) {
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
    final requestVersion = ++_clubRequestVersion;

    try {
      final repo = ref.read(communityRepositoryProvider);
      final result = await repo.getCommunitiesPaged(
        cursor: isLoadMore ? _serverClubNextCursor : null,
        limit: _clubsPageSize,
        search: _searchQueries[3]?.trim(),
        provinceCode: _clubProvinceCode,
        categoryId: _clubSport != 'all' ? _clubSport : null,
      );

      if (mounted && requestVersion == _clubRequestVersion) {
        setState(() {
          if (isLoadMore) {
            final existingIds = _serverClubsList.map((c) => c.id).toSet();
            final uniqueNew = result.communities.where(
              (c) => !existingIds.contains(c.id),
            );
            _serverClubsList.addAll(uniqueNew);
          } else {
            _serverClubsList.clear();
            _serverClubsList.addAll(result.communities);
          }
          _serverClubsList.sort((a, b) {
            final aRole = a.myRole?.toUpperCase();
            final bRole = b.myRole?.toUpperCase();
            final aIsAdmin =
                aRole == 'OWNER' || aRole == 'ADMIN' || aRole == 'MODERATOR';
            final bIsAdmin =
                bRole == 'OWNER' || bRole == 'ADMIN' || bRole == 'MODERATOR';
            if (aIsAdmin && !bIsAdmin) return -1;
            if (!aIsAdmin && bIsAdmin) return 1;
            return 0;
          });
          _serverClubNextCursor = result.nextCursor;
          _serverClubHasMore =
              result.hasMore && (result.nextCursor?.isNotEmpty ?? false);
          _isClubInitialLoading = false;
          _isClubLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted && requestVersion == _clubRequestVersion) {
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
  double get _pinnedHeaderHeight {
    double h = _headerHeight;
    if (_currentIndex == 3) {
      h += 44.0; // Explore sub-tabs (CLB / Social)
    }
    return h;
  }

  @override
  void initState() {
    super.initState();
    _collapseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _collapseProgress = CurvedAnimation(
      parent: _collapseAnimController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    _currentIndex = widget.initialTab;
    _exploreSubTabIndex = widget.initialSubTab;
    _carouselController = PageController(viewportFraction: 1.0);
    if (_currentIndex == 1) _fetchServerTournamentPage(isLoadMore: false);
    if (_currentIndex == 3) _fetchServerClubPage(isLoadMore: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authProvider.notifier).init();
    });

    // Home supports landscape/tablet layouts; do not force portrait here.
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab ||
        oldWidget.initialSubTab != widget.initialSubTab) {
      setState(() {
        _currentIndex = widget.initialTab;
        _exploreSubTabIndex = widget.initialSubTab;
      });
    }
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
    _collapseAnimController.dispose();

    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return;

    if (notification is ScrollUpdateNotification) {
      final currentOffset = notification.metrics.pixels;
      final delta = currentOffset - _lastScrollOffset;
      _lastScrollOffset = currentOffset;

      // When near top (less than 40px), always smoothly expand header
      if (currentOffset <= 40) {
        if (_collapseAnimController.value > 0.0) {
          _collapseAnimController.reverse();
        }
        return;
      }

      // Scrolling Down: compact header and elements neatly
      if (delta > 6 && currentOffset > 60) {
        if (_collapseAnimController.value < 1.0) {
          _collapseAnimController.forward();
        }
      }
      // Scrolling Up: expand header and restore dynamic waves
      else if (delta < -6) {
        if (_collapseAnimController.value > 0.0) {
          _collapseAnimController.reverse();
        }
      }
    }
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

  Future<void> _showGlobalSearchScreen() async {
    await GlobalSearchScreen.show(
      context: context,
      initialTabIndex: _currentIndex == 0 ? 0 : _currentIndex,
      initialQuery: _searchQueries[_currentIndex] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _handleScrollNotification(notification);
            return false;
          },
          child: AnimatedBuilder(
            animation: _collapseProgress,
            builder: (context, child) {
              final double p =
                  _collapseProgress.value; // 0.0 (full) -> 1.0 (compact)
              final double currentHeaderHeight = lerpDouble(
                _headerHeight,
                52.0 + safeAreaTop,
                p,
              )!;
              final double currentTopPadding = lerpDouble(
                safeAreaTop + 14.0,
                safeAreaTop + 6.0,
                p,
              )!;

              return Stack(
                children: [
                  // Body Content filling top to bottom
                  Positioned.fill(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: _buildCurrentTabContent(activeHeaderHeight),
                      ),
                    ),
                  ),
                  // Shared Fixed Locked Top Header + Search Bar Block
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: context.colors.bgDark,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: currentHeaderHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    size: Size(
                                      screenSize.width,
                                      currentHeaderHeight,
                                    ),
                                    painter: SportoHeaderPainter(
                                      isLoggedIn: false,
                                      colors: context.colors,
                                      waveProgress: (1.0 - p).clamp(0.0, 1.0),
                                      wavePhase: p,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: currentTopPadding,
                                  left: 16.0,
                                  right: 16.0,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Left: Sport filter dropdown
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Transform.scale(
                                          scale: lerpDouble(1.0, 0.9, p)!,
                                          alignment: Alignment.centerLeft,
                                          child: PopupMenuButton<String>(
                                            onSelected: _setActiveSportFilter,
                                            offset: const Offset(0, 40),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            color: context.colors.bgSurface,
                                            elevation: 8,
                                            itemBuilder: (context) => [
                                              if (_currentIndex != 4)
                                                _buildPopupMenuItem(
                                                  l10n.filterAll,
                                                  'all',
                                                ),
                                              ..._activeSportFilterItems(l10n)
                                                  .where(
                                                    (item) => item.$1 != 'all',
                                                  )
                                                  .map(
                                                    (item) =>
                                                        _buildPopupMenuItem(
                                                          item.$2,
                                                          item.$1,
                                                        ),
                                                  ),
                                            ],
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: lerpDouble(
                                                  12.0,
                                                  9.0,
                                                  p,
                                                )!,
                                                vertical: lerpDouble(
                                                  6.0,
                                                  4.0,
                                                  p,
                                                )!,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.16,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: lerpDouble(
                                                        14.0,
                                                        12.5,
                                                        p,
                                                      )!,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons
                                                        .keyboard_arrow_down_rounded,
                                                    color: Colors.white,
                                                    size: lerpDouble(
                                                      18.0,
                                                      15.0,
                                                      p,
                                                    )!,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Center: Title for sub-tabs
                                      if (!isHomeTab)
                                        Center(
                                          child: Transform.scale(
                                            scale: lerpDouble(1.0, 0.92, p)!,
                                            child: Text(
                                              _currentIndex == 1
                                                  ? l10n.navTournaments
                                                  : _currentIndex == 3
                                                  ? 'Khám phá'
                                                  : _currentIndex == 4
                                                  ? l10n.homeRankingsTab
                                                  : l10n.sporto,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: lerpDouble(
                                                  18.0,
                                                  15.5,
                                                  p,
                                                )!,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Search action and notification bell.
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Transform.scale(
                                          scale: lerpDouble(1.0, 0.9, p)!,
                                          alignment: Alignment.centerRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_shouldShowGlobalSearchButton) ...[
                                                Hero(
                                                  tag: 'global_search_hero_box',
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: IconButton(
                                                      tooltip: l10n
                                                          .homeGlobalSearchTitle,
                                                      onPressed:
                                                          _showGlobalSearchScreen,
                                                      style: IconButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .white
                                                            .withValues(
                                                              alpha: 0.16,
                                                            ),
                                                        foregroundColor:
                                                            Colors.white,
                                                        fixedSize: Size(
                                                          lerpDouble(
                                                            40.0,
                                                            34.0,
                                                            p,
                                                          )!,
                                                          lerpDouble(
                                                            40.0,
                                                            34.0,
                                                            p,
                                                          )!,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        shape:
                                                            const CircleBorder(),
                                                      ),
                                                      icon: Icon(
                                                        Icons.search_rounded,
                                                        size: lerpDouble(
                                                          20.0,
                                                          17.0,
                                                          p,
                                                        )!,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              _buildNotificationBellHeader(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_currentIndex == 3)
                            Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: context.colors.bgDark,
                                border: Border(
                                  bottom: BorderSide(
                                    color: context.colors.border.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildExploreSubTabItem(
                                      title: 'CLB',
                                      isSelected: _exploreSubTabIndex == 0,
                                      onTap: () {
                                        if (_exploreSubTabIndex != 0) {
                                          setState(() {
                                            _exploreSubTabIndex = 0;
                                          });
                                          if (_serverClubsList.isEmpty) {
                                            _fetchServerClubPage(
                                              isLoadMore: false,
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildExploreSubTabItem(
                                      title: 'Social',
                                      isSelected: _exploreSubTabIndex == 1,
                                      onTap: () {
                                        if (_exploreSubTabIndex != 1) {
                                          setState(() {
                                            _exploreSubTabIndex = 1;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: _currentIndex,
          onTabSelected: _switchTab,
          onMenuTap: () => AppMenuSheet.show(context),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(double headerHeight) {
    switch (_currentIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('explore'),
          child: _buildExploreTab(),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('tournaments'),
          child: _buildTournamentsTab(),
        );
      case 3:
        return KeyedSubtree(
          key: ValueKey('explore_$_exploreSubTabIndex'),
          child: _exploreSubTabIndex == 0
              ? _buildCommunityTab()
              : SocialListView(topPadding: _pinnedHeaderHeight),
        );
      case 4:
      default:
        return KeyedSubtree(
          key: const ValueKey('ranking'),
          child: LeaderboardScreen(
            selectedSport: _rankingsSport,
            searchQuery: _searchQueries[4] ?? '',
            provinceCode: null,
            isFilterExpanded: false,
          ),
        );
    }
  }

  Widget _buildExploreSubTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? const Color(0xFF4ADE80) : activeColor)
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
              ),
            ),
          ),
          Container(
            height: 3,
            width: 70,
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF4ADE80) : activeColor)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 0: KHÁM PHÁ (Explore)
  // ═══════════════════════════════════════════════════════
  Widget _buildExploreTab() {
    final l10n = AppLocalizations.of(context)!;
    final query = (
      sport: _exploreSport,
      matchStatus: _exploreStatus == 'live' ? 'ONGOING' : 'COMPLETED',
    );
    final projectionAsync = ref.watch(homeProjectionProvider(query));

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async => ref.invalidate(homeProjectionProvider(query)),
      child: projectionAsync.when(
        data: (projection) => CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: _pinnedHeaderHeight)),
            if (!ref.watch(authProvider).isAuthenticated)
              SliverToBoxAdapter(child: _buildGuestLoginNoticeBanner(l10n)),
            if (projection.featuredTournaments.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  title: l10n.featuredTournaments,
                  actionLabel: l10n.viewAll,
                  onAction: () => _switchTab(1),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTournamentCarousel(projection.featuredTournaments),
              ),
            ],
            SliverPersistentHeader(
              pinned: true,
              delegate: _StatusFilterDelegate(
                child: _buildExploreSegmentTabBar(l10n),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSectionTitle(
                title: _exploreStatus == 'live'
                    ? l10n.liveMatches
                    : l10n.completedMatchesLabel,
                isLive: _exploreStatus == 'live',
                actionLabel: l10n.viewAll,
                onAction: () => _switchTab(1),
              ),
            ),
            if (projection.tournaments.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _exploreStatus == 'live'
                          ? l10n.noLiveMatches
                          : l10n.homeNoCompletedMatches,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList.separated(
                  itemCount: projection.tournaments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _HomeTournamentFinalsCard(
                    tournament: projection.tournaments[index],
                  ),
                ),
              ),
            if (projectionAsync.hasError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text(l10n.homeMatchesLoadError)),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(homeProjectionProvider(query)),
                        child: Text(l10n.homeGlobalSearchRetry),
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        loading: () => CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: _pinnedHeaderHeight)),
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (error, _) => CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: _pinnedHeaderHeight)),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.homeMatchesLoadError),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(homeProjectionProvider(query)),
                      child: Text(l10n.homeGlobalSearchRetry),
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

  Widget _buildNotificationBellHeader() {
    final unreadAsync = ref.watch(unreadCountProvider);
    final unread = unreadAsync.value ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    final iconColor = isSelected
        ? AppTheme.primary
        : context.colors.textSecondary;
    return PopupMenuItem<String>(
      value: key,
      child: Row(
        children: [
          if (key == 'all' || key.isEmpty)
            Icon(Icons.sports_rounded, size: 18, color: iconColor)
          else
            SportChoiceTile.buildSportIcon(key, 18, iconColor),
          const SizedBox(width: 10),
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
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
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
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LiquidGlassSurface(
        tintColor: isDark ? const Color(0xFFB9E7FF) : const Color(0xFFB6DFFF),
        fallbackColor: isDark ? colors.bgSurface : const Color(0xFFEAF5FF),
        borderColor: Colors.white.withValues(alpha: isDark ? 0.24 : 0.82),
        borderRadius: BorderRadius.circular(14),
        blurSigma: 18,
        opacity: 0.82,
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: (isDark ? colors.bgSurface : const Color(0xFFEAF5FF))
                .withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildExploreTabButton(
                label: l10n.homeLiveStatus,
                statusKey: 'live',
                isLive: true,
              ),
              const SizedBox(width: 4),
              _buildExploreTabButton(
                label: l10n.homeCompletedStatus,
                statusKey: 'completed',
              ),
            ],
          ),
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
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 1.5),
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
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentCarousel(List<HomeFeaturedTournament> items) {
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
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: GIẢI ĐẤU (Tournaments) — Server-Side Cursor Stream (Load More)
  // ═══════════════════════════════════════════════════════
  Widget _buildTournamentsTab() {
    final l10n = AppLocalizations.of(context)!;
    final currentList = _serverTournamentsList;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isTournamentLoadingMore &&
            _serverTournamentHasMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 400) {
          _fetchServerTournamentPage(isLoadMore: true);
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: _pinnedHeaderHeight)),
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
                    (
                      key: "registration",
                      label: l10n.matchesFilterRegistration,
                    ),
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
                onLoadMore: () => _fetchServerTournamentPage(isLoadMore: true),
              ),
            ),
          ],
        ],
      ),
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
                      color: colors.border.withValues(alpha: 0.8),
                    ),
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

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.depth == 0 &&
            scrollInfo is ScrollUpdateNotification &&
            (scrollInfo.scrollDelta ?? 0) > 0 &&
            !_isClubLoadingMore &&
            _serverClubHasMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 400) {
          _fetchServerClubPage(isLoadMore: true);
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _fetchServerClubPage(isLoadMore: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: _pinnedHeaderHeight)),
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
                  SliverList.separated(
                    itemCount: currentList.length,
                    separatorBuilder: (context, i) => Divider(
                      height: 1,
                      thickness: 0.8,
                      color: context.colors.border.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, i) => _buildClubItem(currentList[i]),
                  ),
                  SliverToBoxAdapter(
                    child: _buildCursorLoadMoreBar(
                      isLoadingMore: _isClubLoadingMore,
                      hasMore: _serverClubHasMore,
                      loadMoreLabel: 'Xem thêm câu lạc bộ',
                      allLoadedLabel: 'Đã hiển thị tất cả câu lạc bộ',
                      onLoadMore: () => _fetchServerClubPage(isLoadMore: true),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3: CÂU LẠC BỘ (Clubs) — Compact List Style ───
  String _resolveClubImageUrl(String? url) {
    final value = url?.trim() ?? '';
    if (value.isEmpty || value.startsWith('data:')) {
      return '';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      if (Platform.isAndroid && value.contains('localhost')) {
        return value.replaceFirst('localhost', '10.0.2.2');
      }
      if (Platform.isAndroid && value.contains('127.0.0.1')) {
        return value.replaceFirst('127.0.0.1', '10.0.2.2');
      }
      return value;
    }

    var apiBase = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (Platform.isAndroid && apiBase.contains('localhost')) {
      apiBase = apiBase.replaceAll('localhost', '10.0.2.2');
    }
    final host = apiBase.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return '${host.replaceFirst(RegExp(r'/$'), '')}/${value.replaceFirst(RegExp(r'^/'), '')}';
  }

  Widget _buildClubItem(Community club) {
    final logoUrl = _resolveClubImageUrl(
      (club.logoUrl?.trim().isNotEmpty ?? false)
          ? club.logoUrl!.split(',').first
          : club.bannerUrl,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push("/club/${club.id}"),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.bgSurface,
                  border: Border.all(
                    color: context.colors.border.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: ClipOval(
                  child: logoUrl.isNotEmpty
                      ? ClubNetworkImage(
                          logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                            AppConstants.appIconPng,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(AppConstants.appIconPng, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      club.name,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (club.myRole != null &&
                        (club.myRole!.toUpperCase() == 'OWNER' ||
                            club.myRole!.toUpperCase() == 'ADMIN' ||
                            club.myRole!.toUpperCase() == 'MODERATOR')) ...[
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shield_rounded,
                                  size: 11,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  club.myRole!.toUpperCase() == 'OWNER'
                                      ? 'Quản lý CLB'
                                      : 'Quản trị viên',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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

class _HomeTournamentFinalsCard extends StatelessWidget {
  final HomeTournamentFinals tournament;

  const _HomeTournamentFinalsCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      color: colors.bgCard,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push('/intro/${tournament.id}'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tournament.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.textSecondary),
                ],
              ),
            ),
          ),
          for (final match in tournament.matches)
            InkWell(
              onTap: () => context.push(
                NavigationHelper.getLiveMatchRoute(tournament.id, match.id),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (match.divisionName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          match.divisionName!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          match.status,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (match.scheduledAt != null)
                          Text(
                            MaterialLocalizations.of(
                              context,
                            ).formatShortDate(match.scheduledAt!.toLocal()),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _teamName(
                            match.team1.name,
                            colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${match.team1Sets}  -  ${match.team2Sets}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Expanded(
                          child: _teamName(
                            match.team2.name,
                            colors.textPrimary,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                    if (match.leg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Lượt ${match.leg}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _teamName(String name, Color color, {bool alignEnd = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      );
}
