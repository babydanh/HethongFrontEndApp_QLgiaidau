import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart';
import 'package:app_quanly_giaidau/features/home/widgets/token_input_sheet.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'dart:ui' show PathMetric;

// ─── Dashed Border Painter ───
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    for (final PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double nextDistance = distance + gap;
        canvas.drawPath(
          pathMetric.extractPath(distance, nextDistance),
          paint,
        );
        distance = nextDistance + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Tier Rank Data ───
class _TierInfo {
  final String name;
  final Color color;
  final IconData icon;
  const _TierInfo(this.name, this.color, this.icon);
}

_TierInfo _getTierFromElo(int elo) {
  if (elo >= 2400) return const _TierInfo('Grandmaster', Color(0xFFFF6B35), Icons.workspace_premium);
  if (elo >= 2000) return const _TierInfo('Master', Color(0xFF9B59B6), Icons.diamond);
  if (elo >= 1700) return const _TierInfo('Platinum', Color(0xFF1ABC9C), Icons.hexagon);
  if (elo >= 1400) return const _TierInfo('Gold', Color(0xFFF39C12), Icons.star);
  if (elo >= 1100) return const _TierInfo('Silver', Color(0xFF95A5A6), Icons.shield);
  return const _TierInfo('Bronze', Color(0xFFCD7F32), Icons.circle);
}

// ─── HomeScreen ───
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _selectedSportFilter = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _headerAnimController;
  late Animation<double> _headerFade;

  // Mock ELO data (sẽ lấy từ API khi có)
  final int _mockElo = 1520;
  final int _mockWins = 24;
  final int _mockLosses = 8;
  final int _mockNotifications = 3;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).init();
      _headerAnimController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  void _showTokenSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TokenInputSheet(),
    );
  }

  // ─── Bottom Nav Items ───
  static const _navItems = [
    (icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Khám phá'),
    (icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events_rounded, label: 'Giải đấu'),
    (icon: Icons.groups_outlined, activeIcon: Icons.groups_rounded, label: 'CLB'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Cài đặt'),
  ];

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentsProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        // ── Gradient toàn màn hình động theo ThemeMode ──
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                    Color(0xFF020617),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0052FF), // Xanh giữ đến 30%
                    Color(0xFF0052FF), 
                    Color(0xFFFFFFFF), // Bắt đầu chuyển trắng mượt mà
                  ],
                  stops: [0.0, 0.3, 0.8], // Xanh 30%, rồi chuyển mượt qua trắng đến 80% màn hình
                ),
        ),
        child: tournamentsAsync.when(
          data: (tournaments) => _buildBody(tournaments),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (e, _) => Center(
            child: Text('Lỗi tải giải đấu: $e',
                style: const TextStyle(color: Colors.white)), // Chữ trắng sáng
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Bottom Navigation Bar (hoà cùng gradient) ───
  Widget _buildBottomNav() {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Container(
      decoration: BoxDecoration(
        // Navbar tiếp nối gradient tương ứng theo ThemeMode
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF020617),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1F5F9), // tiếp tục dải xám trắng của light mode
                  Color(0xFFFFFFFF),
                ],
              ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x66000000) : const Color(0x220052FF),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) => _buildNavItem(i)),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    
    // Màu cho icon và chữ khi chưa được chọn
    final unselectedColor = isDark 
        ? const Color(0xFF94A3B8) // xám sáng ở Dark Mode
        : const Color(0xFF475569); // đen xám sẫm ở Light Mode
        
    final selectedColor = isDark 
        ? const Color(0xFF60A5FA) // xanh dương sáng ở Dark Mode
        : AppTheme.primary; // xanh dương đậm ở Light Mode

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: selectedColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey(isSelected),
                color: isSelected ? selectedColor : unselectedColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, // Làm đậm lên
                color: isSelected ? selectedColor : unselectedColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Body Router ───
  Widget _buildBody(List<Tournament> tournaments) {
    switch (_currentIndex) {
      case 0:
        return _buildExploreTab(tournaments);
      case 1:
        return _buildTournamentsTab(tournaments);
      case 2:
        return _buildClubTab();
      case 3:
      default:
        return _buildSettingsTab();
    }
  }

  // ─── GRADIENT HEADER with Logo + Profile ───
  Widget _buildGradientHeader() {
    final auth = ref.watch(authProvider);
    final isAuth = auth.isAuthenticated;
    final tier = _getTierFromElo(_mockElo);
    final winRate = _mockWins + _mockLosses > 0
        ? ((_mockWins / (_mockWins + _mockLosses)) * 100).round()
        : 0;

    return FadeTransition(
      opacity: _headerFade,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Logo + Notification + Avatar ──
              Row(
                children: [
                    // Logo VNSport nằm trong khung trắng cố định, ôm sát
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        'assets/images/vndc_sport.png',
                        height: 64, // Giữ logo to nhưng không quá khổ
                        fit: BoxFit.contain,
                        errorBuilder: (_, e, s) => const Text(
                          'VNSPORT',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0052FF),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Notification bell
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
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
                    const SizedBox(width: 10),

                    // Avatar
                    GestureDetector(
                      onTap: () {
                        if (isAuth) {
                          setState(() => _currentIndex = 3);
                        } else {
                          context.go('/login');
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: isAuth
                            ? ClipOval(
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              )
                            : const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                      ),
                    ),
                  ],
                ),

                // ── Row 2: Profile card (chỉ khi đã đăng nhập) ──
                if (isAuth) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar lớn
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.3),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Tên + Tier
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Người chơi',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(tier.icon, color: tier.color, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    tier.name,
                                    style: TextStyle(
                                      color: tier.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ELO $_mockElo',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Thắng / Thua
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                _buildStatBadge('W', '$_mockWins', const Color(0xFF22C55E)),
                                const SizedBox(width: 6),
                                _buildStatBadge('L', '$_mockLosses', const Color(0xFFEF4444)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tỉ lệ thắng $winRate%',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Khi chưa đăng nhập — CTA nổi bật với nền trắng đục và chữ xanh đậm tương phản cao
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white, // Trắng tinh nổi bật hẳn
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0052FF), width: 2), // viền xanh rõ nét
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0038CC).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login_rounded, color: Color(0xFF0052FF), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Đăng nhập để xem ELO & thống kê',
                            style: TextStyle(
                              color: Color(0xFF0052FF), // Chữ xanh chính đậm nét
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ─── TAB 1: KHÁM PHÁ ───
  // ═══════════════════════════════════════
  Widget _buildExploreTab(List<Tournament> tournaments) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final filtered = tournaments.where((t) {
      final matchesSport =
          _selectedSportFilter == 'all' || t.sport == _selectedSportFilter;
      final matchesSearch =
          t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSport && matchesSearch;
    }).toList();

    final liveTournaments =
        filtered.where((t) => t.status == AppConstants.statusInProgress).toList();
    final finishedTournaments =
        filtered.where((t) => t.status == AppConstants.statusCompleted).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(tournamentsProvider),
      color: AppTheme.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header gradient
          SliverToBoxAdapter(child: _buildGradientHeader()),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9), // Trắng rõ ràng, nổi bật trên nền gradient
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0038CC).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600), // Chữ sẫm dễ đọc
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm giải đấu, đội hoặc VĐV...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)), // Hint sẫm màu hơn chút
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: AppTheme.primary, size: 24),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune_rounded,
                          color: Color(0xFF475569)),
                      onPressed: () {},
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ),
          ),

          // Sport filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildSportFilterChip('all', 'Tất cả'),
                    ...AppConstants.sportNames.entries.map((entry) {
                      return _buildSportFilterChip(entry.key, entry.value);
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Live tournaments
          if (liveTournaments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Đang diễn ra',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900, // Làm đậm nét
                            color: isDark ? Colors.white : const Color(0xFF0F172A), // Đen sẫm ở Light Mode, trắng ở Dark Mode
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentIndex = 1),
                      child: Text(
                        'Xem tất cả',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF60A5FA) : AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liveTournaments.length,
                  itemBuilder: (context, index) =>
                      _buildLiveCard(liveTournaments[index]),
                ),
              ),
            ),
          ],

          // Featured banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: const Text(
                'Đang nổi bật',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFeaturedBanner(),
            ),
          ),

          // Enter code card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: CustomPaint(
                painter: DashedBorderPainter(
                    color: isDark ? Colors.white.withValues(alpha: 0.65) : AppTheme.primary.withValues(alpha: 0.6)), // nét đứt màu trắng ở dark, màu xanh ở light
                child: Card(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : AppTheme.primary.withValues(alpha: 0.08), // box thủy tinh nhẹ nhàng tùy theo theme
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _showTokenSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.25) : AppTheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.vpn_key_rounded,
                                color: isDark ? Colors.white : AppTheme.primary, size: 26),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nhập mã giải đấu / trận đấu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A), // Chữ đen sẫm hẳn ở Light Mode
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tham gia quản lý (trọng tài) hoặc theo dõi trực tiếp trận đấu',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF475569), // Chữ phụ xám sẫm ở Light Mode
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Recently finished
          if (finishedTournaments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Text(
                  'Mới kết thúc',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFinishedRow(finishedTournaments[index]),
                ),
                childCount: finishedTournaments.length,
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSportFilterChip(String key, String label) {
    final isSelected = _selectedSportFilter == key;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedSportFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF3B82F6) 
              : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white), // trắng hẳn ở light mode
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF3B82F6) 
                : (isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF0F172A)), // viền đen sẫm hẳn ở light mode
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F172A)), // chữ đen sẫm hẳn ở light mode
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w800, // Làm đậm chữ hẳn
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveCard(Tournament t) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/intro/${t.id}'),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                Icons.sports_tennis_rounded,
                size: 100,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 6),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppConstants.sportNames[t.sport] ?? t.sport,
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thể thức: ${AppConstants.bracketTypeNames[t.bracketType]}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${t.maxTeams} đội',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
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

  Widget _buildFeaturedBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0052FF), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: Opacity(
              opacity: 0.12,
              child: const Icon(Icons.emoji_events_rounded,
                  size: 180, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SỰ KIỆN NỔI BẬT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Racket Masters League 2026',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Giải đấu chuyên nghiệp quy tụ hơn 100 VĐV hàng đầu.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Trung tâm TDTT Thành phố',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedRow(Tournament t) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Card(
      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white, // Tương thích dark/light
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0), width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF), // xanh đậm/nhạt
          child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B)), // Cup vàng nổi bật
        ),
        title: Text(t.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        subtitle: Text(
            'Đã hoàn thành • ${AppConstants.bracketTypeNames[t.bracketType]}',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569))),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0052FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'XEM LẠI',
            style: TextStyle(
                color: Color(0xFF0052FF),
                fontSize: 10,
                fontWeight: FontWeight.w800),
          ),
        ),
        onTap: () => context.go('/intro/${t.id}'),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ─── TAB 2: GIẢI ĐẤU ───
  // ═══════════════════════════════════════
  Widget _buildTournamentsTab(List<Tournament> tournaments) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Giải Đấu',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tournaments.length} giải đấu đang hoạt động',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _buildStatCard(
                  'Đang diễn ra',
                  '${tournaments.where((t) => t.status == AppConstants.statusInProgress).length}',
                  const Color(0xFF22C55E),
                  Icons.play_circle_outline_rounded,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  'Mở đăng ký',
                  '${tournaments.where((t) => t.status == AppConstants.statusRegistration).length}',
                  AppTheme.primary,
                  Icons.how_to_reg_outlined,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  'Đã kết thúc',
                  '${tournaments.where((t) => t.status == AppConstants.statusCompleted).length}',
                  context.colors.textMuted,
                  Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ),
        ),

        // Enter code CTA
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GestureDetector(
              onTap: _showTokenSheet,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15), // box thủy tinh nhẹ nhàng
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.vpn_key_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhập mã tham gia giải đấu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white, // Chữ trắng nổi bật
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Nhập mã mời để tham gia với vai trò trọng tài / khán giả',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Tournament list title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: const Text(
              'Tất cả giải đấu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Tournament cards
        tournaments.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events_outlined,
                              size: 60, color: isDark ? Colors.white54 : const Color(0xFF0F172A)),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có giải đấu nào',
                            style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final t = tournaments[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _buildTournamentCard(t),
                    );
                  },
                  childCount: tournaments.length,
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9), // Trắng đục rõ nét trên gradient
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B), // Xám sẫm tĩnh thay vì textMuted mờ nhạt
                  fontWeight: FontWeight.w700), // Làm đậm lên chút
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentCard(Tournament t) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final statusColor = t.status == AppConstants.statusInProgress
        ? const Color(0xFF22C55E)
        : (t.status == AppConstants.statusCompleted
            ? (isDark ? Colors.white54 : const Color(0xFF475569)) // màu phụ sẫm
            : const Color(0xFF0052FF));
    final statusText = t.status == AppConstants.statusInProgress
        ? 'ĐANG DIỄN RA'
        : (t.status == AppConstants.statusCompleted
            ? 'ĐÃ KẾT THÚC'
            : 'MỞ ĐĂNG KÝ');

    return Card(
      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white, // Thay đổi tuỳ theme
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/intro/${t.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  t.format == 'SINGLES' || t.format == 'singles'
                      ? Icons.person_rounded
                      : Icons.people_rounded,
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A)), // chữ sẫm nổi bật hoặc trắng ở dark mode
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          AppConstants.sportNames[t.sport] ?? t.sport,
                          style: TextStyle(
                              fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 6),
                        Text('•',
                            style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF475569), fontSize: 11)),
                        const SizedBox(width: 6),
                        Text(
                          '${t.maxTeams} đội',
                          style: TextStyle(
                              fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ─── TAB 3: CÂU LẠC BỘ ───
  // ═══════════════════════════════════════
  Widget _buildClubTab() {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Câu Lạc Bộ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tìm kiếm và tham gia các CLB thể thao',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.groups_rounded,
                          color: AppTheme.primary, size: 42),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tính năng sắp ra mắt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hệ thống câu lạc bộ đang trong quá trình phát triển.\nKính mong quý vị chờ đón!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Text(
                        'Sắp ra mắt',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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

  // ═══════════════════════════════════════
  // ─── TAB 4: CÀI ĐẶT ───
  // ═══════════════════════════════════════
  Widget _buildSettingsTab() {
    final auth = ref.watch(authProvider);
    final isAuthenticated = auth.isAuthenticated;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final tier = _getTierFromElo(_mockElo);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  // Avatar lớn
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 44),
                        ),
                        if (isAuthenticated)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: tier.color,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(tier.icon,
                                color: Colors.white, size: 14),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isAuthenticated) ...[
                      Text(
                        'Người chơi',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tier.icon, color: tier.color, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${tier.name} • ELO $_mockElo',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Win/Loss/Rate stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildProfileStat('Thắng', '$_mockWins',
                              const Color(0xFF22C55E)),
                          _buildStatDivider(),
                          _buildProfileStat('Thua', '$_mockLosses',
                              const Color(0xFFEF4444)),
                          _buildStatDivider(),
                          _buildProfileStat(
                            'Tỉ lệ',
                            '${_mockWins + _mockLosses > 0 ? ((_mockWins / (_mockWins + _mockLosses)) * 100).round() : 0}%',
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Chưa đăng nhập',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        // Settings cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Theme
                _buildSettingsCard(
                  icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  title: 'Giao diện',
                  subtitle: isDark ? 'Chế độ tối đang bật' : 'Chế độ sáng đang bật',
                  trailing: Switch(
                    value: isDark,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (_) =>
                        ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                ),
                const SizedBox(height: 10),

                // App info
                _buildSettingsCard(
                  icon: Icons.info_outline_rounded,
                  title: 'Thông tin ứng dụng',
                  subtitle: 'Phiên bản ${AppConstants.appVersion}',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: context.colors.bgCard,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('VNSport'),
                        content: const Text(
                          'Hệ thống quản lý và bốc thăm giải đấu thể thao chuyên nghiệp.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Auth
                _buildSettingsCard(
                  icon: isAuthenticated
                      ? Icons.logout_rounded
                      : Icons.login_rounded,
                  title: isAuthenticated
                      ? 'Đăng xuất tài khoản'
                      : 'Đăng nhập / Đăng ký',
                  subtitle: isAuthenticated
                      ? 'Vai trò: ${auth.role?.name.toUpperCase() ?? "VIEWER"}'
                      : 'Đăng nhập để theo dõi ELO và thống kê của bạn',
                  color: isAuthenticated
                      ? const Color(0xFFEF4444)
                      : AppTheme.primary,
                  onTap: () {
                    if (isAuthenticated) {
                      ref.read(authProvider.notifier).signOut();
                    } else {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildProfileStat(String label, String value, Color color) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Container(
      width: 1,
      height: 30,
      color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFCBD5E1),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppTheme.primary;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Card(
      color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.9), // Phông nền rõ rệt tùy theo theme
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: effectiveColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color != null 
                    ? effectiveColor 
                    : (isDark ? Colors.white : const Color(0xFF0F172A)))), // Chữ đen sẫm hẳn ở Light Mode
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12, 
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))), // Chữ mô tả xám sẫm rõ ràng
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569))
                : null),
        onTap: onTap,
      ),
    );
  }
}
