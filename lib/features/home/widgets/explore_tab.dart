import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';

import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
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
          AppTheme.primary,
          AppTheme.primaryDark,
          Color(0xFF020617),
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
      size.width * 0.65,
      size.height * (0.78 + waveShift / size.height),
      size.width * 0.35,
      size.height * 0.85,
    );
    path.quadraticBezierTo(
      size.width * 0.12,
      size.height * (0.91 + waveShift / size.height),
      0,
      size.height * 0.88, // Trái thấp hơn
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
      size.width * 0.3,
      size.height * (0.45 - waveShift / size.height * 0.5),
      size.width * 0.6,
      size.height * 0.58,
    );
    overlayPath.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.64,
      size.width,
      size.height * 0.52,
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

// ─── Status badge helpers ───
Color _statusColor(BuildContext context, String status) =>
    StatusHelper.getTournamentStatusColor(status, context);

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
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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
      final sportMatch = _selectedSport == 'all' || t.sport == _selectedSport;
      final q = _searchQuery.toLowerCase();
      final nameMatch =
          q.isEmpty ||
          t.name.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
      return sportMatch && nameMatch;
    }).toList();
  }

  List<Tournament> get _upcomingTournaments {
    final list = _filtered
        .where(
          (t) =>
              t.status == AppConstants.statusRegistration ||
              t.status == AppConstants.statusDraft ||
              t.status == AppConstants.statusDrawing,
        )
        .toList();
    return list.isNotEmpty ? list : _filtered;
  }

  List<Tournament> get _liveTournaments => _filtered
      .where((t) => t.status == AppConstants.statusInProgress)
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Wave Header ──
          SliverToBoxAdapter(child: _buildWaveHeader(context)),

          // ── Search ──
          SliverToBoxAdapter(child: _buildSearch(context)),

          // ── Sport Filter ──
          SliverToBoxAdapter(child: _buildSportFilter(context)),

          // ── SECTION: Giải đấu sắp diễn ra / đăng ký ──
          if (_upcomingTournaments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: l10n.exploreFeaturedTitle,
                onMore: widget.onViewAllTournaments,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildTournamentHorizontal(_upcomingTournaments),
            ),
          ],

          // ── SECTION 1: Trận đấu đang diễn ra ──
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              icon: Icons.sensors_rounded,
              iconColor: const Color(0xFFEF4444),
              title: l10n.exploreLiveTitle,
              badge: 'LIVE',
            ),
          ),
          if (_liveTournaments.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    l10n.exploreLiveEmpty,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => LiveTournamentWithMatchesCard(
                  tournament: _liveTournaments[i],
                  filterStatus: 'live',
                ),
                childCount: _liveTournaments.length,
              ),
            ),

          // ── SECTION 2: Kết quả trận đấu vừa qua (CỰC KỲ ĐẦY ĐỦ TRẬN) ──
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF2563EB),
              title: l10n.exploreRecentResultsTitle,
            ),
          ),
          SliverToBoxAdapter(
            child: _RecentCompletedMatches(tournaments: _filtered),
          ),

          // ── SECTION 3: Lịch thi đấu sắp diễn ra ──
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFF16A34A),
              title: l10n.exploreUpcomingTitle,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final list = widget.tournaments.isNotEmpty
                  ? widget.tournaments
                  : _filtered;
              if (list.isEmpty) return const SizedBox.shrink();
              return LiveTournamentWithMatchesCard(
                tournament: list[i % list.length],
                filterStatus: 'scheduled',
              );
            }, childCount: widget.tournaments.isNotEmpty ? 1 : 0),
          ),

          // ── Empty State ──
          if (_filtered.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context)),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  // Wave Header
  // ─────────────────────────────────────
  Widget _buildWaveHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final isAuth = auth.isAuthenticated;

    return SizedBox(
      height: isAuth ? 255 : 185,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/sporto_v1_with_text.png',
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Spacer(),
                      // Chat Button
                      _NavIconBtn(
                        icon: Icons.forum_outlined,
                        onTap: () {
                          if (!isAuth) {
                            context.push('/login');
                          } else {
                            context.push('/chat');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      // Notification with Live Red Badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _NavIconBtn(
                            icon: Icons.notifications_outlined,
                            onTap: () => context.push('/notifications'),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Avatar / login
                      GestureDetector(
                        onTap: () => isAuth ? null : context.go('/login'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            isAuth ? Icons.person_rounded : Icons.login_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Hero text
                  Text(
                    l10n.exploreHeaderTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    l10n.exploreHeaderSubtitle,
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
  // 3D Glassmorphism Athlete ELO Card (khi đã login)
  // ─────────────────────────────────────
  Widget _buildCompactStatsRow() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Rating + Stats
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFD700),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rankingDefaultElo,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    l10n.exploreNationalRanking,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildMiniStat('0', l10n.homeMatchesStat),
              const SizedBox(width: 10),
              _buildMiniStat('0', l10n.exploreWinsStat),
              const SizedBox(width: 10),
              _buildMiniStat(
                '0%',
                l10n.homeWinRateStat,
                color: const Color(0xFF4ADE80),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: ELO Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.35,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD700),
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),

          // Row 3: ELO Subtext & Streak Badge
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFFD700),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.exploreEloToGold,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 10)),
                    SizedBox(width: 2),
                    Text(
                      l10n.exploreHighForm,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
  Widget _buildSearch(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.10),
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
            hintText: l10n.exploreSearchHint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
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
  Widget _buildSportFilter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];
    final sports = [
      (key: 'all', label: l10n.infoAll, icon: Icons.grid_view_rounded),
      ...categories.map(
        (category) => (
          key: category.slug,
          label: category.name,
          icon: _sportIcon(category.slug),
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sports.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = sports[i];
            final selected = _selectedSport == s.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedSport = s.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
                          ),
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
                        color: selected
                            ? Colors.white
                            : const Color(0xFF475569),
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
    final l10n = AppLocalizations.of(context)!;
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
              child: Row(
                children: [
                  Text(
                    l10n.exploreViewAll,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
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
  // Empty State
  // ─────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.exploreEmptyTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.exploreEmptyHint,
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(context, tournament.status);
    final sportLabel = switch (tournament.sport.toLowerCase()) {
      'badminton' => l10n.createClubTournament_sportBadminton,
      'tennis' => l10n.createClubTournament_sportTennis,
      'pickleball' => l10n.createClubTournament_sportPickleball,
      'table_tennis' => l10n.createClubTournament_sportTableTennis,
      'football' => l10n.createClubTournament_sportFootball,
      _ => l10n.homeSportFallback,
    };
    final bracketLabel = switch (tournament.bracketType.toLowerCase()) {
      'single_elimination' => l10n.eliminationSingle,
      'double_elimination' => l10n.eliminationDouble,
      'round_robin' => l10n.roundRobin,
      'group_stage' => l10n.groupStage,
      _ => tournament.bracketType,
    };

    return GestureDetector(
      onTap: () => context.push('/intro/${tournament.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.10),
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
                      AppTheme.primaryDark,
                      AppTheme.primary,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            switch (StatusHelper.normalizeTournamentStatus(
                              tournament.status,
                            )) {
                              AppConstants.statusRegistration =>
                                l10n.profileRegistrationOpen,
                              AppConstants.statusRegistrationClosed =>
                                l10n.registrationClosed,
                              AppConstants.statusInProgress =>
                                l10n.homeInProgressStatus,
                              AppConstants.statusCompleted =>
                                l10n.homeCompletedStatus,
                              AppConstants.statusUpcoming =>
                                l10n.profileUpcoming,
                              _ => StatusHelper.normalizeTournamentStatus(
                                tournament.status,
                              ),
                            },
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
                        const Icon(
                          Icons.group_rounded,
                          color: Colors.white60,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tournament.maxTeams} ${l10n.teamsUnit}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.account_tree_rounded,
                          color: Colors.white60,
                          size: 13,
                        ),
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

class MatchExploreCard extends ConsumerStatefulWidget {
  final MatchModel match;
  final Tournament? tournament;

  const MatchExploreCard({super.key, required this.match, this.tournament});

  @override
  ConsumerState<MatchExploreCard> createState() => _MatchExploreCardState();
}

class _MatchExploreCardState extends ConsumerState<MatchExploreCard> {
  int cheerCount = 0;
  bool isCheered = false;
  bool _cheerInFlight = false;

  @override
  void initState() {
    super.initState();
    _loadCheerCount();
  }

  Future<void> _loadCheerCount() async {
    try {
      final count = await ref
          .read(matchRepositoryProvider)
          .getCheerCount(widget.match.id);
      if (mounted) setState(() => cheerCount = count);
    } catch (_) {
      // Keep the card usable when the count endpoint is temporarily unavailable.
    }
  }

  Future<void> _cheer() async {
    if (_cheerInFlight) return;
    setState(() => _cheerInFlight = true);
    try {
      await ref.read(matchRepositoryProvider).cheerMatch(widget.match.id);
      final count = await ref
          .read(matchRepositoryProvider)
          .getCheerCount(widget.match.id);
      if (mounted) {
        setState(() {
          cheerCount = count;
          isCheered = true;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.matchLiveCheerError ??
                  'Chưa thể gửi cổ vũ. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cheerInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final m = widget.match;
    final isT1Tbd =
        m.team1Name.trim().toUpperCase() == 'TBD' ||
        m.team1Name.trim().toUpperCase() == 'BYE';
    final isT2Tbd =
        m.team2Name.trim().toUpperCase() == 'TBD' ||
        m.team2Name.trim().toUpperCase() == 'BYE';
    final isByeMatch = m.isBye || isT1Tbd || isT2Tbd;

    final statusText = m.isLive
        ? (l10n.exploreMatchStatusLive(m.round))
        : m.isCompleted
        ? (l10n.exploreMatchStatusCompleted(m.round))
        : (l10n.exploreMatchStatusScheduled(m.round));
    String resolveBracketText() {
      final raw = (m.stageName ?? '').trim();
      final upper = raw.toUpperCase();

      if (upper.contains('ROUND_ROBIN') ||
          upper.contains('GROUP') ||
          upper.contains('VÒNG BẢNG') ||
          upper.contains('VONG BANG')) {
        return l10n.exploreBracketGroup;
      }
      if (upper.contains('ELIMINATION') ||
          upper.contains('KNOCKOUT') ||
          upper.contains('LOẠI TRỰC TIẾP') ||
          upper.contains('PLAYOFF')) {
        return l10n.exploreBracketKnockout;
      }
      if (upper.contains('LOSER') || upper.contains('THUA')) {
        return l10n.exploreBracketLosers;
      }
      if (raw.isNotEmpty && !raw.startsWith('{') && !raw.contains('name:')) {
        return raw;
      }

      if (m.bracketPosition.bracket == 'losers') {
        return l10n.exploreBracketLosers;
      }
      return l10n.exploreBracketKnockout;
    }

    final bracketText = resolveBracketText();
    final sportKey = m.sportKey ?? widget.tournament?.sport;
    final sportText = sportKey == null || sportKey.trim().isEmpty
        ? l10n.createClubTournament_sportPickleball
        : l10n.sportDisplayName(sportKey);
    final courtText = m.court.isNotEmpty
        ? m.court
        : (l10n.exploreCourtNotAssigned);

    List<String> getInitials(String name) {
      final parts = name
          .split('-')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
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
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                          : (m.isCompleted
                                ? Icons.check_circle_outline_rounded
                                : Icons.access_time_rounded),
                      size: 13,
                      color: m.isLive
                          ? const Color(0xFFDC2626)
                          : (m.isCompleted
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: m.isLive
                            ? const Color(0xFFDC2626)
                            : (m.isCompleted
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF0284C7)),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Right Badge: VÒNG KNOCKOUT / VÒNG BẢNG
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                      Flexible(
                        child: Text(
                          bracketText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9333EA),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Teams & Vertical Scores Row ──
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isByeMatch && isT2Tbd && !isT1Tbd)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.exploreByeAdvance,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isByeMatch && isT1Tbd && !isT2Tbd)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.exploreByeAdvance,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 10),

          // ── Sub-info Row: Sport & Court ──
          Row(
            children: [
              Icon(
                Icons.sports_handball_rounded,
                size: 14,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                sportText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: colors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                courtText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textMuted,
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
                  onTap: _cheerInFlight ? null : _cheer,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isCheered
                          ? const Color(0xFFFEF2F2)
                          : colors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCheered
                            ? const Color(0xFFFECACA)
                            : colors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _cheerInFlight
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isCheered
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 15,
                                color: isCheered
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFE11D48),
                              ),
                        const SizedBox(width: 6),
                        Text(
                          cheerCount > 0
                              ? '${l10n.exploreCheer} ($cheerCount)'
                              : (l10n.exploreCheer),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCheered
                                ? const Color(0xFFDC2626)
                                : colors.textPrimary,
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
                    context.push('/live/${m.id}');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt_rounded,
                          size: 15,
                          color: colors.info,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.exploreDetails,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.info,
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
                    AppShareModal.show(
                      context: context,
                      title:
                          '${m.team1Name} ${l10n.matchVsLabel} ${m.team2Name}',
                      subtitle: l10n.exploreShareSubtitle(
                        m.tournamentName ?? l10n.exploreFriendlyTournament,
                        m.court.isNotEmpty ? m.court : l10n.matchLiveTitle,
                      ),
                      webUrl: 'https://sporto.asia/live/${m.id}',
                      badgeText: m.isLive
                          ? (l10n.exploreLiveBadge)
                          : (l10n.exploreMatchBadge),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.reply_rounded, size: 15, color: colors.info),
                        const SizedBox(width: 6),
                        Text(
                          l10n.share,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.info,
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
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'
          .toUpperCase();
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
              color: context.colors.bgCard,
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
                color: context.colors.bgCard,
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

class _RecentCompletedMatches extends ConsumerWidget {
  final List<Tournament> tournaments;

  const _RecentCompletedMatches({required this.tournaments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final completedTournaments = <Tournament>[];
    var hasLoadingMatches = false;
    var hasMatchError = false;
    for (final tournament in tournaments) {
      final matchesAsync = ref.watch(matchesProvider(tournament.id));
      if (matchesAsync.isLoading) {
        hasLoadingMatches = true;
        continue;
      }
      if (matchesAsync.hasError) {
        hasMatchError = true;
        continue;
      }
      final matches = matchesAsync.value ?? const <MatchModel>[];
      final hasCompleted = matches.any((match) {
        final status = match.status.toUpperCase();
        return !match.isByeMatch &&
            (match.isCompleted ||
                status == 'COMPLETED' ||
                status == 'FINISHED' ||
                status == 'DONE' ||
                status == 'ENDED' ||
                match.completedAt != null);
      });
      if (hasCompleted) completedTournaments.add(tournament);
      if (completedTournaments.length == 3) break;
    }

    if (completedTournaments.isEmpty && hasLoadingMatches) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text(l10n.exploreRecentResultsLoading)),
      );
    }
    if (completedTournaments.isEmpty && hasMatchError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text(l10n.exploreRecentResultsLoadError)),
      );
    }
    if (completedTournaments.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            l10n.exploreRecentResultsEmpty,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: completedTournaments
          .map(
            (tournament) => LiveTournamentWithMatchesCard(
              tournament: tournament,
              filterStatus: 'completed',
            ),
          )
          .toList(),
    );
  }
}
