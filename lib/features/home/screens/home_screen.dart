import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart';
import 'package:app_quanly_giaidau/features/home/widgets/token_input_sheet.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'dart:math' as math;

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
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _selectedSport = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  late AnimationController _waveCtrl;
  AnimationController? _pageCtrl;
  Animation<double>? _pageFade;

  // Mock data
  static const int _mockElo = 1340;
  static const int _mockWins = 31;
  static const int _mockLosses = 16;
  static const int _mockTotal = 47;
  static const int _mockNotifications = 3;

  @override
  void initState() {
    super.initState();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    final pc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pageCtrl = pc;
    _pageFade = CurvedAnimation(parent: pc, curve: Curves.easeOut);
    pc.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pageCtrl?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageCtrl?.forward(from: 0);
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
        body: tournamentsAsync.when(
          data: (tournaments) => FadeTransition(
            opacity: _pageFade ?? const AlwaysStoppedAnimation(1.0),
            child: _buildBody(tournaments),
          ),
          loading: () => _buildLoadingState(),
          error: (e, _) => _buildErrorState(e),
        ),
        bottomNavigationBar: _buildFloatingNav(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  BODY ROUTER
  // ─────────────────────────────────────────────────────
  Widget _buildBody(List<Tournament> tournaments) {
    switch (_currentIndex) {
      case 0:
        return _buildExploreTab(tournaments);
      case 1:
        return _buildTournamentsTab(tournaments);
      case 2:
        return _buildRankingTab();
      case 3:
      default:
        return _buildSettingsTab();
    }
  }

  // ─────────────────────────────────────────────────────
  //  FLOATING BOTTOM NAV — Logo curve + floating avatar
  //  Left: Trang chủ + Thi đấu | Center: Avatar | Right: Xếp hạng + Cài đặt
  // ─────────────────────────────────────────────────────
  Widget _buildFloatingNav() {
    final auth = ref.watch(authProvider);
    final isAuth = auth.isAuthenticated;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A2979FF),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Nav items row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // LEFT: Trang chủ
                    Expanded(child: _buildNavItem(0, Icons.explore_outlined, Icons.explore_rounded, 'Khám phá')),
                    // LEFT: Thi đấu
                    Expanded(child: _buildNavItem(1, Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'Giải đấu')),

                    // CENTER SPACER (for floating avatar)
                    const SizedBox(width: 72),

                    // RIGHT: Xếp hạng
                    Expanded(child: _buildNavItem(2, Icons.leaderboard_outlined, Icons.leaderboard_rounded, 'Xếp hạng')),
                    // RIGHT: Cài đặt
                    Expanded(child: _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'Cài đặt')),
                  ],
                ),
              ),

              // FLOATING AVATAR — Elevated center
              Positioned(
                top: -22,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => isAuth ? _switchTab(3) : context.go('/login'),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.bgCard,
                        border: Border.all(
                          color: const Color(0xFF2979FF),
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3D2979FF),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: isAuth
                            ? Container(
                                color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF2979FF),
                                  size: 30,
                                ),
                              )
                            : Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(
                                  Icons.login_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 26,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              // Subtle curve divider behind avatar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 80,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    const selectedColor = Color(0xFF2979FF);
    const unselectedColor = Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? selectedColor : unselectedColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 18 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 0: KHÁM PHÁ (Explore)
  // ═══════════════════════════════════════════════════════
  Widget _buildExploreTab(List<Tournament> tournaments) {
    final allTournaments = tournaments.where((t) {
      final sportMatch = _selectedSport == 'all' || t.sport == _selectedSport;
      final q = _searchQuery.toLowerCase();
      final nameMatch = q.isEmpty || t.name.toLowerCase().contains(q);
      return sportMatch && nameMatch;
    }).toList();

    final upcoming = allTournaments
        .where((t) => t.status == AppConstants.statusRegistration || t.status == AppConstants.statusDraft)
        .toList();
    final live = allTournaments
        .where((t) => t.status == AppConstants.statusInProgress)
        .toList();
    final finished = allTournaments
        .where((t) => t.status == AppConstants.statusCompleted)
        .toList();

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(tournamentsProvider),
      color: const Color(0xFF2979FF),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Wave Header ──
          SliverToBoxAdapter(child: _buildWaveHeader()),

          // ── Search + Filter ──
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildSportChips()),

          // ── Section: Giải đấu (Tournaments) ──
          if (upcoming.isNotEmpty || finished.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionTitle(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Giải đấu',
                actionLabel: 'Xem tất cả',
                onAction: () => _switchTab(1),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildTournamentCarousel([...upcoming, ...finished]),
            ),
          ],

          // ── Section: Đang diễn ra (Live) ──
          if (live.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionTitle(
                icon: Icons.sensors_rounded,
                color: const Color(0xFFEF4444),
                title: 'Đang diễn ra',
                badge: 'LIVE',
              ),
            ),
            SliverToBoxAdapter(child: _buildLiveCarousel(live)),
          ],

          // Empty
          if (allTournaments.isEmpty)
            SliverFillRemaining(child: _buildEmpty()),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  WAVE HEADER
  // ─────────────────────────────────────────────────────
  Widget _buildWaveHeader() {
    final auth = ref.watch(authProvider);
    final isAuth = auth.isAuthenticated;

    return SizedBox(
      height: isAuth ? 230 : 190,
      child: Stack(
        children: [
          // Wave background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => CustomPaint(
                painter: _WavePainter(_waveCtrl.value),
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            right: -30,
            top: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top nav row
                  Row(
                    children: [
                      // Logo
                      _buildLogoBox(),
                      const Spacer(),

                      // Notification
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildNavCircleBtn(
                            icon: Icons.notifications_outlined,
                            onTap: () {},
                          ),
                          if (_mockNotifications > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_mockNotifications',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats / CTA row
                  if (isAuth)
                    _buildCompactStats()
                  else
                    _buildLoginCTA(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoBox() {
    return Image.asset(
      'assets/images/vndc_sport.png',
      height: 48,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Text(
        'VNSPORT',
        style: TextStyle(
          color: Color(0xFF2979FF),
          fontWeight: FontWeight.w900,
          fontSize: 24,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavCircleBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCompactStats() {
    final winRate = (_mockWins * 100 ~/ _mockTotal);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              children: [
                Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 18),
                SizedBox(height: 2),
                Text(
                  'Kim Cương',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ELO
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: '$_mockElo ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: 'ELO',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Divider
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(width: 16),

          // Stats
          _buildStatCol('$_mockTotal', 'Trận'),
          const SizedBox(width: 14),
          _buildStatCol('$_mockWins', 'Thắng'),
          const SizedBox(width: 14),
          _buildStatCol('$winRate%', 'Rate', valueColor: const Color(0xFF4ADE80)),
        ],
      ),
    );
  }

  Widget _buildStatCol(String val, String label, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCTA() {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2979FF).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login_rounded, color: Color(0xFF2979FF), size: 18),
            SizedBox(width: 8),
            Text(
              'Đăng nhập để xem ELO & thống kê',
              style: TextStyle(
                color: Color(0xFF2979FF),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SEARCH BAR
  // ─────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x142979FF),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm giải đấu...',
            hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14.5),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2979FF), size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFB0BEC5), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : const Icon(Icons.tune_rounded, color: Color(0xFFB0BEC5), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SPORT FILTER CHIPS
  // ─────────────────────────────────────────────────────
  static const _sportFilters = [
    (key: 'all', label: 'Tất cả', icon: Icons.grid_view_rounded),
    (key: 'tennis', label: 'Tennis', icon: Icons.sports_tennis),
    (key: 'badminton', label: 'Cầu lông', icon: Icons.air),
    (key: 'table_tennis', label: 'Bóng bàn', icon: Icons.circle_outlined),
    (key: 'pickleball', label: 'Pickleball', icon: Icons.sports_handball),
  ];

  Widget _buildSportChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _sportFilters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = _sportFilters[i];
            final isSelected = _selectedSport == s.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedSport = s.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2979FF) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2979FF) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2979FF).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                          )
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.icon, size: 13, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SECTION TITLE
  // ─────────────────────────────────────────────────────
  Widget _buildSectionTitle({
    required IconData icon,
    required Color color,
    required String title,
    String? badge,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2979FF)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  TOURNAMENT CAROUSEL (Upcoming + Finished)
  // ─────────────────────────────────────────────────────
  Widget _buildTournamentCarousel(List<Tournament> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _TournamentCard(
          tournament: items[i],
          onTap: () => context.go('/intro/${items[i].id}'),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  LIVE CAROUSEL — dark bento cards
  // ─────────────────────────────────────────────────────
  Widget _buildLiveCarousel(List<Tournament> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: items
            .take(3)
            .map((t) => _LiveCard(
                  tournament: t,
                  onTap: () => context.go('/intro/${t.id}'),
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  EMPTY STATE
  // ─────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFFB0BEC5)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy giải đấu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Thử thay đổi bộ lọc hoặc từ khoá',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: GIẢI ĐẤU
  // ═══════════════════════════════════════════════════════
  Widget _buildTournamentsTab(List<Tournament> tournaments) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 110,
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(16, 0, 0, 16),
            title: const Text(
              'Giải đấu',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF0F7FF), Color(0xFFFFFFFF)],
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: _showTokenSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Nhập mã',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (tournaments.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'Chưa có giải đấu nào',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TournamentListCard(
                    tournament: tournaments[i],
                    onTap: () => context.go('/intro/${tournaments[i].id}'),
                  ),
                ),
                childCount: tournaments.length,
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 2: XẾP HẠNG
  // ═══════════════════════════════════════════════════════
  Widget _buildRankingTab() {
    return _SimplePlaceholderTab(
      icon: Icons.leaderboard_rounded,
      title: 'Xếp hạng',
      subtitle: 'Bảng xếp hạng ELO toàn quốc sắp ra mắt',
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 3: CÁ NHÂN
  // ═══════════════════════════════════════════════════════
  Widget _buildSettingsTab() {
    final auth = ref.watch(authProvider);
    final isAuth = auth.isAuthenticated;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Cài đặt',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // User account section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF2979FF).withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF2979FF), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: isAuth
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thành viên VNDC',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              auth.role?.name.toUpperCase() ?? 'PLAYER',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2979FF),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khách',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đăng nhập để lưu lịch sử',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
                if (isAuth)
                  IconButton(
                    icon: Icon(Icons.logout_rounded, color: context.colors.error),
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                  )
                else
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: Color(0xFF2979FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings Section Title
          Text(
            'Giao diện & Cấu hình',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Settings List Card
          Container(
            decoration: BoxDecoration(
              color: context.colors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                // Dark Mode Switch
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined, color: Color(0xFF2979FF)),
                  title: Text(
                    'Chế độ tối (Dark Mode)',
                    style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  trailing: Switch(
                    value: isDark,
                    activeColor: const Color(0xFF2979FF),
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                  ),
                ),
                Divider(height: 1, color: context.colors.border.withValues(alpha: 0.3)),
                // Language
                ListTile(
                  leading: const Icon(Icons.language_outlined, color: Color(0xFF2979FF)),
                  title: Text(
                    'Ngôn ngữ',
                    style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    'Tiếng Việt',
                    style: TextStyle(color: context.colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info section
          Center(
            child: Text(
              'Phiên bản 1.0.0 • VNDC Sport',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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

  static const _gradients = [
    [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF60A5FA)],
    [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF34D399)],
    [Color(0xFF581C87), Color(0xFF7E22CE), Color(0xFFA78BFA)],
    [Color(0xFF7C2D12), Color(0xFFB45309), Color(0xFFFBBF24)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradIndex = tournament.id.hashCode.abs() % _gradients.length;
    final grad = _gradients[gradIndex];
    final statusLabel = AppConstants.statusNames[tournament.status] ?? tournament.status;
    final sportLabel = AppConstants.sportNames[tournament.sport] ?? tournament.sport;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 195,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: grad,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: grad[0].withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative
            Positioned(
              right: -16,
              top: -16,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sportLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    tournament.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.group_rounded, color: Colors.white60, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${tournament.maxTeams} đội',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white60, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  LIVE CARD — Dark bento style (như HTML reference)
// ═══════════════════════════════════════════════════════
class _LiveCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  const _LiveCard({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sportLabel = AppConstants.sportNames[tournament.sport] ?? tournament.sport;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Live badge + Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LIVE badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sensors_rounded, color: Colors.white, size: 10),
                            SizedBox(width: 3),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sportLabel,
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tournament.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.group_rounded, color: Color(0xFF475569), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${tournament.maxTeams} đội',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: Arrow button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2979FF), size: 20),
            ),
          ],
        ),
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
//  SIMPLE PLACEHOLDER TAB
// ═══════════════════════════════════════════════════════
class _SimplePlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SimplePlaceholderTab({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: const Color(0xFF2979FF)),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
        ],
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
