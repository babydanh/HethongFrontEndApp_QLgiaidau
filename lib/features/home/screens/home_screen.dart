import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/widgets/liquid_glass_surface.dart';
import 'package:app_quanly_giaidau/core/widgets/app_responsive.dart';

import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_header.dart';
import 'package:app_quanly_giaidau/features/home/widgets/featured_tournament_banner_card.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_card_with_banner.dart';
import 'package:app_quanly_giaidau/core/widgets/status_segment.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/leaderboard_screen.dart';
import 'package:app_quanly_giaidau/features/social/screens/social_list_view.dart';

import 'package:app_quanly_giaidau/data/models/home_projection.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/home/widgets/global_search_screen.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_section_list.dart';
import 'package:app_quanly_giaidau/core/utils/match_status_filter.dart';
import 'package:app_quanly_giaidau/providers/home_match_feed_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/home_skeletons.dart';

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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  // Animation controller for compacting/expanding header on scroll
  late final AnimationController _collapseAnimController;
  late final Animation<double> _collapseProgress;
  double _lastScrollOffset = 0.0;
  // Home query state feeds existing per-tab result filters.
  final Map<int, String> _searchQueries = {0: '', 1: '', 3: '', 4: ''};

  // ─── Per-tab filter state ───
  String _exploreSport = 'all';
  // Mặc định mở tab "Sắp diễn ra": phần lớn người dùng vào app để xem giải
  // sắp diễn ra, còn "Trực tiếp" thường rỗng nên phải bấm mới thấy.
  String _exploreStatus = 'scheduled';
  bool _hasAutoSwitchedLiveTab = false;
  bool _userManuallySelectedLiveTab = false;

  void _handleNoLiveMatches() {
    if (!_hasAutoSwitchedLiveTab &&
        _exploreStatus == 'live' &&
        !_userManuallySelectedLiveTab) {
      _hasAutoSwitchedLiveTab = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _exploreStatus == 'live' &&
            !_userManuallySelectedLiveTab) {
          setState(() {
            _exploreStatus = 'scheduled';
          });
        }
      });
    }
  }

  String _tournamentSport = 'all';
  String _tournamentStatus = 'all';
  String _rankingsSport = 'all';

  // ─── Server-side Cursor Pagination states (Tab 1: Giải đấu) ───
  final List<Tournament> _serverTournamentsList = [];
  String? _serverTournamentNextCursor;
  bool _isTournamentInitialLoading = true;
  bool _isTournamentLoadingMore = false;
  bool _serverTournamentHasMore = false;
  int _tournamentRequestVersion = 0;

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
      4 => _rankingsSport == 'all' ? 'pickleball' : _rankingsSport,
      _ => 'all',
    };
  }

  void _setActiveSportFilter(String key) {
    setState(() {
      _hasAutoSwitchedLiveTab = false;
      _userManuallySelectedLiveTab = false;
      _exploreStatus = 'scheduled';
      _exploreSport = key;
      _tournamentSport = key;
      _rankingsSport = key == 'all' ? 'pickleball' : key;
      if (_currentIndex != 1) {
        ++_tournamentRequestVersion;
        _serverTournamentsList.clear();
        _serverTournamentNextCursor = null;
        _serverTournamentHasMore = false;
        _isTournamentInitialLoading = true;
      }
    });
    if (_currentIndex == 1) _resetTournamentCursorPagination();
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
  double get _pinnedHeaderHeight => _headerHeight;

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
    _carouselController = PageController(viewportFraction: 1.0);
    if (_currentIndex == 1) _fetchServerTournamentPage(isLoadMore: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authProvider.notifier).init();
    });

    // Home supports landscape/tablet layouts; do not force portrait here.
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() {
        _currentIndex = widget.initialTab;
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
    // Warm the sport list so the header filter menu is filled on first open.
    ref.watch(categoriesProvider);
    final tournamentsAsync = _currentIndex == 0
        ? ref.watch(tournamentsProvider)
        : null;
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
            child: Positioned.fill(
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
                  child!,
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

  Widget _buildCurrentTabContent(
    AsyncValue<List<Tournament>>? tournamentsAsync,
    double headerHeight,
  ) {
    switch (_currentIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('explore'),
          child: _buildExploreTab(tournamentsAsync!),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('tournaments'),
          child: _buildTournamentsTab(),
        );
      case 3:
        return KeyedSubtree(
          key: const ValueKey('explore_social'),
          child: SocialListView(topPadding: _pinnedHeaderHeight),
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

  // ═══════════════════════════════════════════════════════
  //  TAB 0: KHÁM PHÁ (Explore)
  // ═══════════════════════════════════════════════════════
  Widget _buildExploreTab(AsyncValue<List<Tournament>> tournamentsAsync) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: () async {
              _hasAutoSwitchedLiveTab = false;
              _userManuallySelectedLiveTab = false;
              ref.invalidate(homeMatchFeedProvider);
              return ref.refresh(tournamentsProvider);
            },
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
                      child: SizedBox(height: _pinnedHeaderHeight),
                    ),
                    if (!ref.watch(authProvider).isAuthenticated)
                      SliverToBoxAdapter(
                        child: _buildGuestLoginNoticeBanner(l10n),
                      ),
                    if (featuredTournaments.isNotEmpty) ...[
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
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
                    SliverToBoxAdapter(child: _buildExploreSegmentTabBar(l10n)),
                    TournamentSectionList(
                      tournaments: allTournaments,
                      filter: MatchStatusFilter.parse(_exploreStatus),
                      emptyMessage: _exploreStatus == 'live'
                          ? l10n.noLiveMatches
                          : _exploreStatus == 'scheduled'
                          ? l10n.noUpcomingMatches
                          : l10n.homeNoCompletedMatches,
                      onNoLiveMatches: _handleNoLiveMatches,
                    ),

                    if (allTournaments.isEmpty)
                      SliverFillRemaining(child: _buildEmpty()),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
              loading: () => CustomScrollView(
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: _pinnedHeaderHeight),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: HomeBannerSkeleton(
                      height: _bannerSlotHeight(context),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildExploreSegmentTabBar(l10n)),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        for (var i = 0; i < 3; i++)
                          const TournamentMatchesCardSkeleton(),
                      ],
                    ),
                  ),
                ],
              ),
              error: (e, st) => CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: _pinnedHeaderHeight),
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
                label: l10n.matchesFilterScheduled,
                statusKey: 'scheduled',
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
          _userManuallySelectedLiveTab = true;
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

  Widget _buildTournamentCarousel(List<Tournament> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Khởi động timer chuyển trang tự động nếu chưa có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_carouselTimer == null) {
        _startCarouselTimer(items.length);
      }
    });

    final registrationStatusById = _featuredRegistrationStatusById();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ô carousel không cao hơn card 16:9 (card cách mép 16px mỗi bên),
        // nên tab trạng thái nằm sát đáy banner. Trần vẫn là bannerHeight.
        SizedBox(
          height: _bannerSlotHeight(context),
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
                  tournament: HomeFeaturedTournament.fromTournament(
                    items[i],
                    registrationStatus: registrationStatusById[items[i].id],
                  ),
                  onTap: () => context.push("/intro/${items[i].id}"),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Trạng thái đăng ký (OPEN/CLOSED) do server tính, lấy từ projection Khám
  /// phá theo id giải. Giải không có trong projection thì không có badge.
  Map<String, String?> _featuredRegistrationStatusById() {
    final statusById = <String, String?>{};
    for (final matchStatus in const ['ONGOING', 'COMPLETED']) {
      final projection = ref.watch(
        homeProjectionProvider((sport: _exploreSport, matchStatus: matchStatus)),
      );
      if (projection case AsyncData(:final value)) {
        for (final featured in value.featuredTournaments) {
          statusById[featured.id] = featured.registrationStatus;
        }
      }
    }
    return statusById;
  }

  double _bannerSlotHeight(BuildContext context) {
    const sidePadding = 16.0;
    final size = MediaQuery.sizeOf(context);
    final cardHeight = (size.width - 2 * sidePadding) * 9 / 16;
    final bannerHeight = AppResponsive.bannerHeight(
      size.height,
      viewportWidth: size.width,
    );
    return cardHeight < bannerHeight ? cardHeight : bannerHeight;
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
            SliverToBoxAdapter(
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    const TournamentBannerCardSkeleton(),
                ],
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
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          allLoadedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textMuted.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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

