import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/core/widgets/vnsport_header.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_card_carousel.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_card_with_banner.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_filter_chips.dart';
import 'package:app_quanly_giaidau/core/widgets/status_segment.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/leaderboard_screen.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
import 'package:app_quanly_giaidau/features/home/widgets/token_input_sheet.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// ═══════════════════════════════════════════════════════
//  WAVE HEADER PAINTER
//  Sóng lượn: trái 75% thấp hơn phải 85%, đỉnh giữa 100%
//  Giống clip-path: polygon(0% 0%, 100% 0%, 100% 85%, 50% 100%, 0% 75%)
// ═══════════════════════════════════════════════════════
class _WavePainter extends CustomPainter {
  final double animValue;
  _WavePainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient xanh nhạt → xanh trung → trắng
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF2979FF),
        Color(0xFF448AFF),
        Color(0xFF82B1FF),
        Color(0xFFE3EEFF),
      ],
      stops: const [0.0, 0.4, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    // Sóng nhẹ theo animation
    final waveAnim = math.sin(animValue * 2 * math.pi) * 4;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    // Phải cao hơn: 85%
    path.lineTo(size.width, size.height * 0.85);

    // Sóng cong mượt: dùng cubic bezier
    // control point 1: từ phải 85% → đỉnh giữa 100%
    path.cubicTo(
      size.width * 0.75, size.height * (0.85 + waveAnim / size.height),
      size.width * 0.6, size.height * (1.0 + waveAnim / size.height),
      size.width * 0.5, size.height * 1.0, // đỉnh 100%
    );
    // control point 2: đỉnh giữa 100% → trái 75%
    path.cubicTo(
      size.width * 0.35, size.height * (1.0 - waveAnim / size.height),
      size.width * 0.18, size.height * 0.78,
      0, size.height * 0.75, // trái thấp nhất
    );
    path.close();

    canvas.drawPath(path, paint);

    // Lớp shimmer nhẹ
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final shimmerPath = Path();
    shimmerPath.moveTo(0, 0);
    shimmerPath.lineTo(size.width * 0.5, 0);
    shimmerPath.quadraticBezierTo(
      size.width * 0.3, size.height * 0.4,
      0, size.height * 0.5,
    );
    shimmerPath.close();
    canvas.drawPath(shimmerPath, shimmerPaint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.animValue != animValue;
}

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
  String _selectedSport = "all";
  String _selectedStatus = "all";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  double _headerScrollProgress = 0.0;
  bool _isAnimatingToTop = false;

  PageController? _carouselController;
  Timer? _carouselTimer;
  int _carouselCurrentPage = 0;

  double get _safeAreaTop => MediaQuery.of(context).padding.top;
  double get _maxHeaderHeight => 240.0 + _safeAreaTop;
  double get _minHeaderHeight => 110.0 + _safeAreaTop;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _scrollController.addListener(_onScroll);
    _carouselController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).init();
    });
  }

  void _startCarouselTimer(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselController == null || !_carouselController!.hasClients) return;
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
      final double targetOffset = offset + (_maxHeaderHeight - _minHeaderHeight);
      _scrollController.jumpTo(targetOffset);
    }
  }

  void _expandHeader() async {
    if (_headerScrollProgress == 1.0) {
      setState(() {
        _headerScrollProgress = 0.0;
        _isAnimatingToTop = true;
      });
      await _scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      if (mounted) {
        setState(() {
          _isAnimatingToTop = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController?.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
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
    final tournamentsAsync = ref.watch(tournamentsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.colors.bgDark,
        extendBody: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildBody(tournamentsAsync),
        ),
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: _currentIndex,
          onTabSelected: _switchTab,
          onProfileTap: () => context.go('/profile'),
        ),
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<Tournament>> tournamentsAsync) {
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
          child: const LeaderboardScreen(),
        );
    }
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 0: KHÁM PHÁ (Explore)
  // ═══════════════════════════════════════════════════════
  Widget _buildExploreTab(AsyncValue<List<Tournament>> tournamentsAsync) {
    final screenSize = MediaQuery.of(context).size;
    final double safeAreaTop = MediaQuery.of(context).padding.top;
    final double p = _headerScrollProgress;
    final double currentHeaderHeight = lerpDouble(_maxHeaderHeight, _minHeaderHeight, p)!;
    final double logoW = lerpDouble(260.0, 160.0, p)!;
    final double logoH = lerpDouble(82.0, 50.0, p)!;
    final double iconsTop = lerpDouble(safeAreaTop + 4.0, safeAreaTop + 16.0, p)!;
    final double subtitleOpacity = (1.0 - p).clamp(0.0, 1.0);
    final double headerDetailsY = lerpDouble(76.0, 16.0, p)!;
    final double searchOpacity = p;

    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(tournamentsProvider),
            color: const Color(0xFF2979FF),
            child: tournamentsAsync.when(
              data: (tournamentsList) {
                final listToUse = tournamentsList.isNotEmpty ? tournamentsList : _getTournamentFallback();
                final allTournaments = listToUse.where((t) {
                  final sportMatch = _selectedSport == 'all' || t.sport == _selectedSport;
                  final q = _searchQuery.toLowerCase();
                  return sportMatch && (q.isEmpty || t.name.toLowerCase().contains(q));
                }).toList();

                final live = allTournaments.where((t) => t.status == 'in_progress').toList();
                final upcoming = allTournaments.where((t) => t.status == 'draft' || t.status == 'registration' || t.status == 'upcoming').toList();
                final finished = allTournaments.where((t) => t.status == 'completed').toList();

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        height: currentHeaderHeight - _minHeaderHeight,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyHeaderDelegate(
                        p: searchOpacity,
                        searchBar: _buildSearchBar(),
                        sportChips: _buildSportChips(),
                        backgroundColor: context.colors.bgDark,
                        minHeaderHeight: _minHeaderHeight,
                      ),
                    ),
                    if (live.isNotEmpty || upcoming.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          title: 'Giải đấu nổi bật',
                          actionLabel: 'Xem tất cả',
                          onAction: () => _switchTab(1),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: KeyedSubtree(
                            key: ValueKey("featured_$_selectedSport"),
                            child: _buildTournamentCarousel([...live, ...upcoming]),
                          ),
                        ),
                      ),
                    ],
                    if (live.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          icon: Icons.sensors_rounded,
                          color: const Color(0xFFEF4444),
                          title: 'Giải đấu đang diễn ra',
                          badge: 'LIVE',
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => LiveTournamentWithMatchesCard(tournament: live[index]),
                            childCount: live.length,
                          ),
                        ),
                      ),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          icon: Icons.calendar_today_rounded,
                          color: const Color(0xFF2979FF),
                          title: 'Giải đấu sắp diễn ra',
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final tournament = upcoming[index];
                              return TournamentCardWithBanner(
                                tournament: tournament,
                                onTap: () => context.push('/intro/${tournament.id}'),
                              );
                            },
                            childCount: upcoming.length,
                          ),
                        ),
                      ),
                    ],
                    if (finished.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                          title: 'Giải đấu đã kết thúc',
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final tournament = finished[index];
                              return LiveTournamentWithMatchesCard(tournament: tournament);
                            },
                            childCount: finished.length,
                          ),
                        ),
                      ),
                    ],
                    if (allTournaments.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmpty(),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
              loading: () => CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      height: currentHeaderHeight - _minHeaderHeight,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      p: searchOpacity,
                      searchBar: _buildSearchBar(),
                      sportChips: _buildSportChips(),
                      backgroundColor: context.colors.bgDark,
                      minHeaderHeight: _minHeaderHeight,
                    ),
                  ),
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                ],
              ),
              error: (e, st) => CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      height: currentHeaderHeight - _minHeaderHeight,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      p: searchOpacity,
                      searchBar: _buildSearchBar(),
                      sportChips: _buildSportChips(),
                      backgroundColor: context.colors.bgDark,
                      minHeaderHeight: _minHeaderHeight,
                    ),
                  ),
                  SliverFillRemaining(child: _buildErrorState(e)),
                ],
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          top: 0.0,
          left: 0.0,
          right: 0.0,
          height: currentHeaderHeight,
          child: Hero(
            tag: "vnsport_header_bg",
            child: CustomPaint(
              size: Size(screenSize.width, currentHeaderHeight),
              painter: VnsportHeaderPainter(
                isLoggedIn: ref.watch(authProvider).isAuthenticated,
                colors: context.colors,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          height: _headerScrollProgress == 1.0 ? (safeAreaTop + 60.0) : currentHeaderHeight,
          child: GestureDetector(
            onTap: _expandHeader,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          top: iconsTop,
          left: 16.0,
          right: 16.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _expandHeader,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: logoW,
                  height: logoH,
                  child: Image.asset(
                    "assets/images/vndc_sport.png",
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
              const Spacer(),
              _buildNotificationBellHeader(),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  _expandHeader();
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _searchFocusNode.requestFocus();
                  });
                },
                child: Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
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
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
            if (unread > 0)
              Positioned(
                top: -1.0,
                right: -1.0,
                child: Container(
                  width: 18.0,
                  height: 18.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 99 ? "99+" : "$unread",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
    final profileAsync = ref.watch(userProfileProvider);
    final rankingsAsync = ref.watch(userRankingsProvider);
    return profileAsync.when(
      data: (profile) {
        String fullName = profile.fullName ?? profile.email ?? "Người dùng";
        final addr = profile.address ?? "TP.HCM";
        String address = "Tennis • $addr";
        return rankingsAsync.when(
          data: (rankings) {
            int elo = 0;
            int wins = 0;
            int losses = 0;
            int totalMatches = 0;
            double winRate = 0.0;
            if (rankings.isNotEmpty) {
              final first = rankings.first;
              elo = first.eloPoints;
              wins = first.matchesWon;
              totalMatches = first.matchesPlayed;
              losses = totalMatches - wins;
              if (losses < 0) losses = 0;
              winRate = totalMatches > 0 ? (wins / totalMatches) * 100 : 0.0;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$elo ELO",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Text(
                            "Xếp hạng Quốc gia",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildStatTableRow("Trận", "$totalMatches", Colors.white),
                      const SizedBox(width: 18),
                      _buildStatTableRow("Thắng", "$wins", Colors.white),
                      const SizedBox(width: 18),
                      _buildStatTableRow("Rate", "${winRate.toStringAsFixed(0)}%", const Color(0xFF4ADE80)),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => _buildHeaderErrorState(e.toString()),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => _buildHeaderErrorState(e.toString()),
    );
  }

  Widget _buildHeaderErrorState(String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Không thể tải thông tin",
          style: TextStyle(
            color: Colors.red.shade100,
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          error,
          style: const TextStyle(color: Colors.white70, fontSize: 12.0),
          maxLines: 2,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 38.0,
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(100.0),
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
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: context.colors.textPrimary),
          cursorColor: const Color(0xFF2979FF),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: "Tìm kiếm giải đấu...",
            hintStyle: TextStyle(color: context.colors.textMuted, fontSize: 14.0),
            prefixIcon: Icon(Icons.search, color: context.colors.textSecondary, size: 20.0),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: context.colors.textSecondary, size: 18.0),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                : Icon(Icons.tune_rounded, color: context.colors.textSecondary, size: 18.0),
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildSportChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: SportFilterChips(
        selectedSport: _selectedSport,
        onSportChanged: (s) => setState(() => _selectedSport = s),
      ),
    );
  }

  Widget _buildSectionTitle({
    IconData? icon,
    Color? color,
    required String title,
    String? badge,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null && color != null) ...[
            Container(
              width: 34.0,
              height: 34.0,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: color, size: 19.0),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
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
                      color: Color(0xFF2979FF),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12.0, color: Color(0xFF2979FF)),
                ],
              ),
            ),
        ],
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
      children: [
        SizedBox(
          height: 285.0,
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
              child: TournamentCardCarousel(
                tournament: items[i],
                onTap: () => context.push("/intro/${items[i].id}"),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            final isSelected = _carouselCurrentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : context.colors.textMuted.withValues(alpha: 0.35),
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
            child: const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFFB0BEC5)),
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

  // ═══════════════════════════════════════════════════════
  //  TAB 1: GIẢI ĐẤU (Tournaments)
  // ═══════════════════════════════════════════════════════
  Widget _buildTournamentsTab(List<Tournament> tournaments) {
    final String q = _searchQuery.toLowerCase().trim();
    final List<Tournament> filtered = tournaments.where((t) {
      if (_selectedSport != "all" && t.sport != _selectedSport) {
        return false;
      }
      if (_selectedStatus == "registration" && t.status != "registration" && t.status != "draft") {
        return false;
      }
      if (_selectedStatus == "in_progress" && t.status != "in_progress") {
        return false;
      }
      if (_selectedStatus == "completed" && t.status != "completed") {
        return false;
      }
      if (q.isNotEmpty && !t.name.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
    final List<Tournament> displayList = filtered.isNotEmpty ? filtered : _getTournamentFallback();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: true,
          backgroundColor: context.colors.bgDark,
          elevation: 0.0,
          title: Text(
            "Giải đấu",
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22.0,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: InkWell(
                  onTap: _showTokenSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.key_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          "Nhập mã",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Container(
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: context.colors.bgSurface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: context.colors.border, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(fontSize: 13.5, color: context.colors.textPrimary),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm giải đấu...",
                      hintStyle: TextStyle(fontSize: 13.5, color: context.colors.textMuted),
                      prefixIcon: Icon(Icons.search, size: 18.0, color: context.colors.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 16.0, color: context.colors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              SportFilterChips(
                selectedSport: _selectedSport,
                onSportChanged: (s) => setState(() => _selectedSport = s),
              ),
              const SizedBox(height: 12),
              StatusSegment(
                selected: _selectedStatus,
                onChanged: (s) => setState(() => _selectedStatus = s),
                items: const [
                  (key: "all", label: "Tất cả"),
                  (key: "registration", label: "Đăng ký"),
                  (key: "in_progress", label: "Thi đấu"),
                  (key: "completed", label: "Hoàn thành"),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (displayList.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48.0, color: context.colors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    "Không tìm thấy giải đấu phù hợp",
                    style: TextStyle(fontSize: 16.0, color: context.colors.textSecondary),
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

  List<Tournament> _getTournamentFallback() {
    return [
      Tournament(
        id: "f1",
        name: "Giải Cầu lông VNDC Mở Rộng 2026",
        sport: "badminton",
        format: "doubles",
        bracketType: "single_elimination",
        status: "registration",
        adminToken: "",
        refereeToken: "",
        viewerToken: "",
        creatorId: "",
        maxTeams: 32,
        description: "",
        roundCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        entryFee: 300000.0,
        startDate: DateTime(2026, 7, 15),
        endDate: DateTime(2026, 7, 20),
        registrationStartDate: DateTime(2026, 6, 1),
        registrationEndDate: DateTime(2026, 7, 10),
        locationAddress: "Nhà thi đấu Phú Thọ, TP.HCM",
      ),
      Tournament(
        id: "f2",
        name: "Tennis Pro Cup 2026",
        sport: "tennis",
        format: "singles",
        bracketType: "single_elimination",
        status: "in_progress",
        adminToken: "",
        refereeToken: "",
        viewerToken: "",
        creatorId: "",
        maxTeams: 16,
        description: "",
        roundCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        startDate: DateTime(2026, 6, 28),
        endDate: DateTime(2026, 7, 2),
        locationAddress: "Khu thể thao Mỹ Đình, Hà Nội",
      ),
      Tournament(
        id: "f3",
        name: "Pickleball Summer Championship",
        sport: "pickleball",
        format: "doubles",
        bracketType: "round_robin",
        status: "completed",
        adminToken: "",
        refereeToken: "",
        viewerToken: "",
        creatorId: "",
        maxTeams: 12,
        description: "",
        roundCount: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        startDate: DateTime(2026, 6, 15),
        endDate: DateTime(2026, 6, 18),
        locationAddress: "Đà Nẵng",
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 3: CÂU LẠC BỘ (Clubs) — Premium Card Design
  //  Inspired by web communities & profile pages
  // ═══════════════════════════════════════════════════════
  Widget _buildCommunityTab() {
    final bool isAuth = ref.watch(authProvider).isAuthenticated;
    if (!isAuth) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people, size: 48.0, color: Color(0xFF2979FF)),
              ),
              const SizedBox(height: 24),
              Text(
                "Câu lạc bộ",
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Đăng nhập để khám phá câu lạc bộ thể thao, tham gia cộng đồng và kết nối với người chơi.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: FilledButton.icon(
                  onPressed: () => context.go("/login"),
                  icon: const Icon(Icons.login),
                  label: const Text("Đăng nhập"),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go("/login"),
                child: const Text(
                  "Chưa có tài khoản? Đăng ký",
                  style: TextStyle(
                    fontSize: 13.0,
                    color: Color(0xFF2979FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _buildClubListWithApi();
  }

  Widget _buildClubListWithApi() {
    final communitiesAsync = ref.watch(communitiesProvider(null));
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: true,
          backgroundColor: context.colors.bgDark,
          elevation: 0.0,
          title: Text(
            "Câu lạc bộ",
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22.0,
            ),
          ),
          actions: [
            const SizedBox(width: 16),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Container(
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: context.colors.bgSurface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: context.colors.border, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(fontSize: 13.5, color: context.colors.textPrimary),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm câu lạc bộ...",
                      hintStyle: TextStyle(fontSize: 13.5, color: context.colors.textMuted),
                      prefixIcon: Icon(Icons.search, size: 18.0, color: context.colors.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 16.0, color: context.colors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              SportFilterChips(
                selectedSport: _selectedSport,
                onSportChanged: (s) => setState(() => _selectedSport = s),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        communitiesAsync.when(
          data: (clubs) {
            final filtered = clubs.where((c) {
              if (_selectedSport != 'all') {
                final hasSport = c.sports.any((s) {
                  final name = s.toLowerCase();
                  if (_selectedSport == 'badminton' && (name.contains('badminton') || name.contains('cầu lông') || name.contains('cau long'))) return true;
                  if (_selectedSport == 'tennis' && name.contains('tennis')) return true;
                  if (_selectedSport == 'pickleball' && name.contains('pickleball')) return true;
                  return name.contains(_selectedSport);
                });
                if (!hasSport) return false;
              }
              final q = _searchQuery.toLowerCase().trim();
              if (q.isNotEmpty && !c.name.toLowerCase().contains(q) && !(c.description ?? '').toLowerCase().contains(q)) {
                return false;
              }
              return true;
            }).toList();

            final display = filtered.isNotEmpty ? filtered : _getClubFallback().where((c) {
              if (_selectedSport != 'all') {
                final hasSport = c.sports.any((s) {
                  final name = s.toLowerCase();
                  if (_selectedSport == 'badminton' && (name.contains('badminton') || name.contains('cầu lông') || name.contains('cau long'))) return true;
                  if (_selectedSport == 'tennis' && name.contains('tennis')) return true;
                  if (_selectedSport == 'pickleball' && name.contains('pickleball')) return true;
                  return name.contains(_selectedSport);
                });
                if (!hasSport) return false;
              }
              final q = _searchQuery.toLowerCase().trim();
              if (q.isNotEmpty && !c.name.toLowerCase().contains(q) && !(c.description ?? '').toLowerCase().contains(q)) {
                return false;
              }
              return true;
            }).toList();
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
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildClubCardPremium(_getClubFallback()[i]),
                childCount: 4,
              ),
            ),
          ),
          error: (e, st) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildClubCardPremium(_getClubFallback()[i]),
                childCount: 4,
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
    if (n.contains('badminton') || n.contains('cầu lông')) return const Color(0xFF0284C7);
    if (n.contains('tennis')) return const Color(0xFFEA580C);
    if (n.contains('pickleball')) return const Color(0xFF059669);
    if (n.contains('table tennis') || n.contains('bóng bàn') || n.contains('bong ban')) return const Color(0xFFDC2626);
    if (n.contains('bóng đá') || n.contains('football')) return const Color(0xFF16A34A);
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
      case 'INVITE_ONLY': return 'Chỉ mời';
      case 'APPROVAL': return 'Xét duyệt';
      default: return 'Tự do';
    }
  }

  Color _getJoinModeColor(String mode) {
    switch (mode) {
      case 'INVITE_ONLY': return const Color(0xFFE11D48);
      case 'APPROVAL': return const Color(0xFFF59E0B);
      default: return const Color(0xFF059669);
    }
  }

  /// ═══════════════════════════════════════════════════════
  ///  PREMIUM CLUB CARD — Full-width, inspired by web
  /// ═══════════════════════════════════════════════════════
  Widget _buildClubCardPremium(Community club) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Banner Area ───
              SizedBox(
                height: 140.0,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasBanner)
                      Image.network(
                        club.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildCardBannerFallback(sportColor, emoji),
                      )
                    else
                      _buildCardBannerFallback(sportColor, emoji),

                    // Gradient overlay
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                          ),
                        ),
                      ),
                    ),

                    // Join mode badge
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(color: joinColor, shape: BoxShape.circle),
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

                    // Logo — half overlapping content
                    Positioned(
                      bottom: -24,
                      left: 14,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.colors.bgCard, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  club.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: BoxDecoration(color: sportColor, borderRadius: BorderRadius.circular(12)),
                                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(color: sportColor, borderRadius: BorderRadius.circular(12)),
                                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Content Area ───
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 30, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Club name + verified
                    Row(
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        if (club.status == 'ACTIVE')
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_rounded, size: 18, color: sportColor),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Stats
                    Row(
                      children: [
                        Icon(Icons.people_rounded, size: 14, color: context.colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          "${club.memberCount} thành viên",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on_rounded, size: 14, color: context.colors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            club.locationAddress ?? "Việt Nam",
                            style: TextStyle(fontSize: 12, color: context.colors.textMuted, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Sport tag
                    if (sportName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: sportColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: sportColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          sportName.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: sportColor, letterSpacing: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBannerFallback(Color sportColor, String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [sportColor, sportColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }

  List<Community> _getClubFallback() {
    return [
      Community(
        id: "1", name: "CLB Cầu lông ABC",
        description: "Câu lạc bộ cầu lông hàng đầu Việt Nam",
        memberCount: 128, sports: const ["Cầu lông"],
        locationAddress: "Hà Nội", joinMode: "OPEN",
      ),
      Community(
        id: "2", name: "CLB Pickleball Pro",
        description: "Sân chơi pickleball chuyên nghiệp",
        memberCount: 86, sports: const ["Pickleball"],
        locationAddress: "TP. Hồ Chí Minh", joinMode: "APPROVAL",
      ),
      Community(
        id: "3", name: "Tennis Elite Club",
        description: "Nơi hội tụ những tay vợt xuất sắc",
        memberCount: 64, sports: const ["Tennis"],
        locationAddress: "Đà Nẵng", joinMode: "OPEN",
      ),
      Community(
        id: "4", name: "CLB Bóng bàn Sao Việt",
        description: "Đam mê bóng bàn - kết nối đam mê",
        memberCount: 52, sports: const ["Bóng bàn"],
        locationAddress: "Hải Phòng", joinMode: "INVITE_ONLY",
      ),
    ];
  }

  // ─────────────────────────────────────────────────────
  //  LOADING & ERROR
  // ─────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF2979FF),
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildErrorState(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFB0BEC5)),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    final statusLabel = AppConstants.statusNames[tournament.status]?.toUpperCase() ?? tournament.status.toUpperCase();
    final sportLabel = AppConstants.sportNames[tournament.sport]?.toUpperCase() ?? tournament.sport.toUpperCase();

    final dateStr = (tournament.startDate != null && tournament.endDate != null)
        ? '${DateFormat('dd/MM/yyyy').format(tournament.startDate!)} - ${DateFormat('dd/MM/yyyy').format(tournament.endDate!)}'
        : 'Chưa cập nhật ngày';

    final divisionsList = tournament.divisions.isNotEmpty
        ? tournament.divisions
        : ['Đơn Nam', 'Đôi Nam', 'Đôi Nữ'];

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                            errorBuilder: (_, __, ___) => _buildFallbackBanner(),
                          )
                        : _buildFallbackBanner(),
                  ),
                  // Top left: Sport badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
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

                    // Division tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: divisionsList.take(3).map((div) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE), width: 0.5),
                          ),
                          child: Text(
                            div,
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
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
                        const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
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
                        const Icon(Icons.people_outline_rounded, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 3),
                        Text(
                          '${tournament.maxTeams} VĐV',
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
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
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

  Color _statusColor(String s) {
    switch (s) {
      case AppConstants.statusInProgress: return const Color(0xFF22C55E);
      case AppConstants.statusRegistration: return const Color(0xFF3B82F6);
      case AppConstants.statusCompleted: return const Color(0xFF94A3B8);
      default: return const Color(0xFFB0BEC5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(tournament.status);
    final statusLabel = AppConstants.statusNames[tournament.status] ?? tournament.status;
    final sportLabel = AppConstants.sportNames[tournament.sport] ?? tournament.sport;

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
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF2979FF), size: 24),
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
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
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
                style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w800),
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

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
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
        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double p;
  final Widget searchBar;
  final Widget sportChips;
  final Color backgroundColor;
  final double minHeaderHeight;

  _StickyHeaderDelegate({
    required this.p,
    required this.searchBar,
    required this.sportChips,
    required this.backgroundColor,
    required this.minHeaderHeight,
  });

  @override
  double get minExtent => minHeaderHeight + 8 + 54.0 * p + 44.0;

  @override
  double get maxExtent => minHeaderHeight + 8 + 54.0 * p + 44.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          SizedBox(height: minHeaderHeight + 8),
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: p,
              child: Opacity(
                opacity: p,
                child: searchBar,
              ),
            ),
          ),
          sportChips,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return p != oldDelegate.p ||
        backgroundColor != oldDelegate.backgroundColor ||
        sportChips != oldDelegate.sportChips ||
        searchBar != oldDelegate.searchBar;
  }
}

