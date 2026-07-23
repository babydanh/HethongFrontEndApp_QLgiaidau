import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

// ─── Wave Header Painter ───
// Sóng lượn: trái thấp hơn phải, bo tròn mượt mà
class _WaveHeaderPainter extends CustomPainter {
  final Animation<double> wave;

  _WaveHeaderPainter({required this.wave}) : super(repaint: wave);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF4DA6FF), // Xanh nhạt trên
          Color(0xFF1A78FF), // Xanh vừa
          Color(0xFF0052FF), // Xanh đậm
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final double animVal = wave.value;

    // Vẽ lớp nền gradient xanh chính
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.72); // Phải cao hơn

    // Điểm kiểm soát sóng lượn: dùng quadraticBezierTo để bo tròn mượt
    // Sóng nhẹ nhàng: phải cao (72%), trái thấp (88%)
    final double waveShift = math.sin(animVal * 2 * math.pi) * 6;
    path.quadraticBezierTo(
      size.width * 0.65, size.height * (0.78 + waveShift / size.height),
      size.width * 0.35, size.height * 0.85,
    );
    path.quadraticBezierTo(
      size.width * 0.12, size.height * (0.91 + waveShift / size.height),
      0, size.height * 0.88, // Trái thấp hơn
    );
    path.close();

    canvas.drawPath(path, paint);

    // Lớp sóng mờ phía trên — tạo chiều sâu
    final overlayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final overlayPath = Path();
    overlayPath.moveTo(0, size.height * 0.55);
    overlayPath.quadraticBezierTo(
      size.width * 0.3, size.height * (0.45 - waveShift / size.height * 0.5),
      size.width * 0.6, size.height * 0.58,
    );
    overlayPath.quadraticBezierTo(
      size.width * 0.82, size.height * 0.64,
      size.width, size.height * 0.52,
    );
    overlayPath.lineTo(size.width, 0);
    overlayPath.lineTo(0, 0);
    overlayPath.close();
    canvas.drawPath(overlayPath, overlayPaint);
  }

  @override
  bool shouldRepaint(_WaveHeaderPainter oldDelegate) => true;
}

// ─── Sport Sport chip enum ───
const _sports = [
  (key: 'all', label: 'Tất cả', icon: Icons.grid_view_rounded),
  (key: 'tennis', label: 'Tennis', icon: Icons.sports_tennis),
  (key: 'badminton', label: 'Cầu lông', icon: Icons.sports),
  (key: 'table_tennis', label: 'Bóng bàn', icon: Icons.circle_outlined),
  (key: 'pickleball', label: 'Pickleball', icon: Icons.sports_handball),
];

// ─── Status badge helpers ───
Color _statusColor(BuildContext context, String status) =>
    StatusHelper.getTournamentStatusColor(status, context);

String _statusLabel(String status) =>
    StatusHelper.getTournamentStatusLabel(status);

IconData _sportIcon(String sport) {
  switch (sport) {
    case 'tennis':
      return Icons.sports_tennis;
    case 'badminton':
      return Icons.air;
    case 'table_tennis':
      return Icons.circle_outlined;
    default:
      return Icons.sports;
  }
}

// ═══════════════════════════════════════
// ─── ExploreTab Widget ───
// ═══════════════════════════════════════
class ExploreTab extends ConsumerStatefulWidget {
  final List<Tournament> tournaments;
  final VoidCallback? onViewAllTournaments;

  const ExploreTab({
    super.key,
    required this.tournaments,
    this.onViewAllTournaments,
  });

  @override
  ConsumerState<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<ExploreTab>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  String _selectedSport = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Tournament> get _filtered {
    return widget.tournaments.where((t) {
      final sportMatch =
          _selectedSport == 'all' || t.sport == _selectedSport;
      final q = _searchQuery.toLowerCase();
      final nameMatch =
          q.isEmpty || t.name.toLowerCase().contains(q) || t.description.toLowerCase().contains(q);
      return sportMatch && nameMatch;
    }).toList();
  }

  List<Tournament> get _upcomingTournaments => _filtered
      .where((t) =>
          t.status == AppConstants.statusRegistration ||
          t.status == AppConstants.statusDraft ||
          t.status == AppConstants.statusDrawing)
      .toList();

  List<Tournament> get _liveTournaments => _filtered
      .where((t) => t.status == AppConstants.statusInProgress)
      .toList();

  List<Tournament> get _completedTournaments => _filtered
      .where((t) => t.status == AppConstants.statusCompleted)
      .toList()
    ..sort((a, b) => _completedTimestamp(b).compareTo(_completedTimestamp(a)));

  DateTime _completedTimestamp(Tournament tournament) {
    return tournament.endDate ?? tournament.updatedAt;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Wave Header ──
          SliverToBoxAdapter(child: _buildWaveHeader()),

          // ── Search ──
          SliverToBoxAdapter(child: _buildSearch()),

          // ── Sport Filter ──
          SliverToBoxAdapter(child: _buildSportFilter()),

          // ── SECTION: Giải đấu sắp diễn ra / đăng ký ──
          if (_upcomingTournaments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Giải đấu nổi bật',
                onMore: widget.onViewAllTournaments,
              ),
            ),
            SliverToBoxAdapter(child: _buildTournamentHorizontal(_upcomingTournaments)),
          ],

          // ── SECTION: Trận đấu đang diễn ra (Chuẩn Hình 1) ──
          if (_liveTournaments.isNotEmpty || _upcomingTournaments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                icon: Icons.sensors_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Trận đấu đang diễn ra',
                badge: 'LIVE',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final list = _liveTournaments.isNotEmpty ? _liveTournaments : _upcomingTournaments;
                  return _TournamentLiveMatchesSection(tournament: list[i]);
                },
                childCount: (_liveTournaments.isNotEmpty ? _liveTournaments : _upcomingTournaments).length,
              ),
            ),
          ],

          // ── SECTION: Đã kết thúc ──
          if (_completedTournaments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                icon: Icons.history_rounded,
                iconColor: const Color(0xFF94A3B8),
                title: 'Đã hoàn thành',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildCompactTournamentRow(_completedTournaments[i]),
                childCount: _completedTournaments.length,
              ),
            ),
          ],

          // ── Empty State ──
          if (_filtered.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  // Wave Header
  // ─────────────────────────────────────
  Widget _buildWaveHeader() {
    final auth = ref.watch(authProvider);
    final isAuth = auth.isAuthenticated;

    return SizedBox(
      height: isAuth ? 220 : 185,
      child: Stack(
        children: [
          // Wave background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) => CustomPaint(
                painter: _WaveHeaderPainter(wave: _waveController),
              ),
            ),
          ),

          // Content on top of wave
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nav Row
                  Row(
                    children: [
                      // Logo / App name
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/vndcsport.svg',
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Spacer(),
                      // Notification
                      _NavIconBtn(
                        icon: Icons.notifications_outlined,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      // Avatar / login
                      GestureDetector(
                        onTap: () => isAuth
                            ? null
                            : context.go('/login'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            isAuth
                                ? Icons.person_rounded
                                : Icons.login_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Hero text
                  const Text(
                    'Khám phá',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const Text(
                    'Tìm giải đấu phù hợp với bạn',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (isAuth) ...[
                    const SizedBox(height: 12),
                    _buildCompactStatsRow(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  // Compact stats row (khi đã login)
  // ─────────────────────────────────────
  Widget _buildCompactStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 18),
          const SizedBox(width: 6),
          const Text(
            'Kim Cương  •  1340 ELO',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          _buildMiniStat('47', 'Trận'),
          const SizedBox(width: 12),
          _buildMiniStat('31', 'Thắng'),
          const SizedBox(width: 12),
          _buildMiniStat('66%', 'Rate', color: const Color(0xFF4ADE80)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String val, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────
  // Search Bar
  // ─────────────────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0052FF).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Tìm giải đấu, môn thể thao...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // Sport Filter Chips
  // ─────────────────────────────────────
  Widget _buildSportFilter() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _sports.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = _sports[i];
            final selected = _selectedSport == s.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedSport = s.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primary
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      s.icon,
                      size: 14,
                      color: selected ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : const Color(0xFF475569),
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

  // ─────────────────────────────────────
  // Section Header
  // ─────────────────────────────────────
  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badge,
    VoidCallback? onMore,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _PulseDot(),
          ],
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: const Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  // Horizontal Tournament Cards
  // ─────────────────────────────────────
  Widget _buildTournamentHorizontal(List<Tournament> items) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _TournamentCard(tournament: items[i]),
      ),
    );
  }



  // ─────────────────────────────────────
  // Compact row for Completed
  // ─────────────────────────────────────
  Widget _buildCompactTournamentRow(Tournament t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _sportIcon(t.sport),
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConstants.sportNames[t.sport] ?? t.sport,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7280).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Hoàn thành',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // Empty State
  // ─────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy giải đấu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Thử thay đổi bộ lọc hoặc từ khoá tìm kiếm',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// ─── Tournament Card (Upcoming) ───
// ═══════════════════════════════════════
class _TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, tournament.status);
    final sportLabel = AppConstants.sportNames[tournament.sport] ?? tournament.sport;
    final bracketLabel = AppConstants.bracketTypeNames[tournament.bracketType] ?? tournament.bracketType;

    return GestureDetector(
      onTap: () => context.push('/intro/${tournament.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0052FF).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Gradient background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF1D4ED8),
                      Color(0xFF3B82F6),
                    ],
                  ),
                ),
              ),
              // Decorative circle
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                left: -10,
                bottom: -10,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sport + Status row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sportLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            _statusLabel(tournament.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Name
                    Text(
                      tournament.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Meta row
                    Row(
                      children: [
                        const Icon(Icons.group_rounded, color: Colors.white60, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${tournament.maxTeams} đội',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.account_tree_rounded, color: Colors.white60, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bracketLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
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
            ],
          ),
        ),
      ),
    );
  }
}



// ─── Nav Icon Button ───
class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─── Pulse Dot for Live ───
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
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
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
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

// ═══════════════════════════════════════
// ─── Match Section & Card (Image 1 Style) ───
// ═══════════════════════════════════════
class _TournamentLiveMatchesSection extends ConsumerWidget {
  final Tournament tournament;

  const _TournamentLiveMatchesSection({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider(tournament.id));
    final teamsAsync = ref.watch(teamsProvider(tournament.id));

    return matchesAsync.when(
      data: (matches) {
        if (matches.isNotEmpty) {
          return Column(
            children: matches.map((m) => MatchExploreCard(match: m, tournament: tournament)).toList(),
          );
        }
        return teamsAsync.when(
          data: (teams) {
            final t1 = teams.isNotEmpty ? teams[0].name : 'Nguyễn Minh Danh - Phạm Hải Dũng';
            final t2 = teams.length >= 2 ? teams[1].name : 'Vũ Quốc Phong - Đặng Khánh Linh';
            final fallbackMatch = MatchModel(
              id: 'match_${tournament.id}',
              round: 1,
              matchNumber: 1,
              team1Name: t1,
              team2Name: t2,
              score1: 0,
              score2: 0,
              status: tournament.status,
              bracketPosition: const BracketPosition(round: 1, position: 1),
              updatedAt: DateTime.now(),
              tournamentName: tournament.name,
              sportKey: tournament.sport,
              court: tournament.locationAddress ?? 'Chưa xếp sân',
            );
            return MatchExploreCard(match: fallbackMatch, tournament: tournament);
          },
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
        ),
      ),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class MatchExploreCard extends StatefulWidget {
  final MatchModel match;
  final Tournament? tournament;

  const MatchExploreCard({
    super.key,
    required this.match,
    this.tournament,
  });

  @override
  State<MatchExploreCard> createState() => _MatchExploreCardState();
}

class _MatchExploreCardState extends State<MatchExploreCard> {
  int cheerCount = 0;
  bool isCheered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final isT1Tbd = m.team1Name.trim().toUpperCase() == 'TBD' || m.team1Name.trim().toUpperCase() == 'BYE';
    final isT2Tbd = m.team2Name.trim().toUpperCase() == 'TBD' || m.team2Name.trim().toUpperCase() == 'BYE';
    final isByeMatch = m.isBye || isT1Tbd || isT2Tbd;

    final statusText = m.isLive
        ? 'ĐANG DIỄN RA • VÒNG ${m.round}'
        : m.isCompleted
            ? 'ĐÃ HOÀN THÀNH • VÒNG ${m.round}'
            : 'SẮP DIỄN RA • VÒNG ${m.round}';
    final bracketText = m.stageName ?? (m.bracketPosition.bracket == 'losers' ? 'NHÁNH THUA' : 'VÒNG KNOCKOUT');
    final sportText = AppConstants.sportNames[m.sportKey ?? widget.tournament?.sport] ?? m.sportKey ?? widget.tournament?.sport ?? 'Pickleball';
    final courtText = m.court.isNotEmpty ? m.court : 'Chưa xếp sân';

    List<String> getInitials(String name) {
      final parts = name.split('-').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (parts.length >= 2) {
        return parts.map((p) => _getSingleInitials(p)).take(2).toList();
      }
      return [_getSingleInitials(name), _getSingleInitials(name)];
    }

    final t1Initials = getInitials(m.team1Name);
    final t2Initials = getInitials(m.team2Name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Badges Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: m.isLive
                      ? const Color(0xFFFEF2F2)
                      : (m.isCompleted
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFE0F2FE)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      m.isLive
                          ? Icons.sensors_rounded
                          : (m.isCompleted ? Icons.check_circle_outline_rounded : Icons.access_time_rounded),
                      size: 13,
                      color: m.isLive
                          ? const Color(0xFFDC2626)
                          : (m.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: m.isLive
                            ? const Color(0xFFDC2626)
                            : (m.isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7)),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Right Badge: VÒNG KNOCKOUT / VÒNG BẢNG
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 13,
                      color: Color(0xFF9333EA),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bracketText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9333EA),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Teams & Vertical Scores Row (No VS, no hyphen) ──
          Column(
            children: [
              // Team 1 Row
              Row(
                children: [
                  _DoubleAvatar(
                    initial1: t1Initials.isNotEmpty ? t1Initials[0] : 'NM',
                    initial2: t1Initials.length > 1 ? t1Initials[1] : 'HD',
                    color: const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m.team1Name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isByeMatch && isT2Tbd && !isT1Tbd)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Vô thẳng',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    )
                  else
                    Text(
                      '${m.score1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Team 2 Row
              Row(
                children: [
                  _DoubleAvatar(
                    initial1: t2Initials.isNotEmpty ? t2Initials[0] : 'VQ',
                    initial2: t2Initials.length > 1 ? t2Initials[1] : 'KL',
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m.team2Name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isByeMatch && isT1Tbd && !isT2Tbd)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Vô thẳng',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    )
                  else
                    Text(
                      '${m.score2}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // ── Sub-info Row: Sport & Court ──
          Row(
            children: [
              const Icon(Icons.sports_handball_rounded, size: 14, color: Color(0xFF475569)),
              const SizedBox(width: 4),
              Text(
                sportText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                courtText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Action Buttons Row (3 buttons) ──
          Row(
            children: [
              // Button 1: Cổ vũ
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      isCheered = !isCheered;
                      if (isCheered) {
                        cheerCount++;
                      } else {
                        cheerCount--;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isCheered ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCheered ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCheered ? Icons.favorite : Icons.favorite_border,
                          size: 15,
                          color: isCheered ? const Color(0xFFDC2626) : const Color(0xFFE11D48),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cheerCount > 0 ? 'Cổ vũ ($cheerCount)' : 'Cổ vũ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCheered ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Button 2: Chi tiết
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (widget.tournament != null) {
                      context.push('/intro/${widget.tournament!.id}');
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt_rounded, size: 15, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Button 3: Chia sẻ
              Expanded(
                child: InkWell(
                  onTap: () {
                    final text = '${m.team1Name} vs ${m.team2Name} - ${m.tournamentName ?? 'Giải đấu'}';
                    SharePlus.instance.share(ShareParams(text: text));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.reply_rounded, size: 15, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Chia sẻ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSingleInitials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }
}

class _DoubleAvatar extends StatelessWidget {
  final String initial1;
  final String initial2;
  final Color color;

  const _DoubleAvatar({
    required this.initial1,
    required this.initial2,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 28,
      child: Stack(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Text(
                initial1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  initial2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
