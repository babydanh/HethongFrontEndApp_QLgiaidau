import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  final String clubId;
  const ClubDetailScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(communityDetailProvider(widget.clubId));
    final themeColors = context.colors;

    return Scaffold(
      backgroundColor: themeColors.bgDark,
      body: clubAsync.when(
        data: (club) {
          if (club == null) return _buildNotFound();
          return _buildContent(club, themeColors);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildContent(_fallbackClub(), themeColors),
      ),
    );
  }

  Community _fallbackClub() {
    return Community(
      id: widget.clubId,
      name: 'CLB Cầu lông ABC',
      description: 'Câu lạc bộ cầu lông hàng đầu Việt Nam với hơn 10 năm hoạt động. Chúng tôi tổ chức các giải đấu thường xuyên và có các huấn luyện viên chuyên nghiệp.',
      memberCount: 128,
      sports: ['Cầu lông'],
      locationAddress: 'Hà Nội',
      logoUrl: null,
      bannerUrl: null,
      joinMode: 'OPEN',
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: context.colors.textMuted),
          const SizedBox(height: 16),
          Text('Không tìm thấy câu lạc bộ', style: TextStyle(color: context.colors.textSecondary, fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => context.pop(), child: const Text('Quay lại')),
        ],
      ),
    );
  }

  Widget _buildContent(Community club, AppColorsExtension colors) {
    final sportName = club.sports.isNotEmpty ? club.sports.first : 'Thể thao';

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // ─── Banner SliverAppBar ───
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          floating: false,
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Banner image
                club.bannerUrl != null && club.bannerUrl!.isNotEmpty
                    ? Image.network(club.bannerUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildBannerGradient(club))
                    : _buildBannerGradient(club),
                // Gradient overlay để chữ dễ đọc
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                      ),
                    ),
                  ),
                ),
                // Logo + tên CLB ở dưới banner
                Positioned(
                  bottom: 60, left: 20, right: 20,
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(14),
                                child: Image.network(club.logoUrl!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(Icons.groups_rounded, color: AppTheme.primary, size: 28)))
                            : Icon(Icons.groups_rounded, color: AppTheme.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(club.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                            const SizedBox(height: 4),
                            Text('$sportName · ${club.memberCount} thành viên', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
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

        // ─── TabBar ───
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            tabController: _tabController,
            colors: colors,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutTab(club, colors),
          _buildTournamentsTab(club, colors),
          _buildMembersTab(club, colors),
          _buildRankingsTab(club, colors),
        ],
      ),
    );
  }

  Widget _buildBannerGradient(Community club) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark, Colors.black],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Text(club.name.isNotEmpty ? club.name[0].toUpperCase() : 'C',
            style: TextStyle(fontSize: 80, color: Colors.white.withValues(alpha: 0.08), fontWeight: FontWeight.w900)),
      ),
    );
  }

  // ─── TAB 1: GIỚI THIỆU ───
  Widget _buildAboutTab(Community club, AppColorsExtension colors) {
    final sportName = club.sports.isNotEmpty ? club.sports.first : 'Thể thao';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Mô tả
        if (club.description != null && club.description!.isNotEmpty) ...[
          const Text('GIỚI THIỆU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Text(club.description!, style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.6)),
          ),
          const SizedBox(height: 24),
        ],

        // Thông tin
        const Text('THÔNG TIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _infoRow(Icons.people_rounded, 'Số thành viên', '${club.memberCount}', colors),
              const Divider(height: 20, color: Color(0xFF2D2D2D)),
              _infoRow(Icons.location_on_rounded, 'Địa điểm', club.locationAddress ?? 'Chưa cập nhật', colors),
              const Divider(height: 20, color: Color(0xFF2D2D2D)),
              _infoRow(Icons.how_to_reg_rounded, 'Hình thức tham gia',
                  club.joinMode == 'OPEN' ? 'Tự do' : club.joinMode == 'APPROVAL' ? 'Cần phê duyệt' : 'Chỉ mời', colors),
              const Divider(height: 20, color: Color(0xFF2D2D2D)),
              _infoRow(Icons.sports_rounded, 'Môn thi đấu', sportName, colors),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Nút tham gia
        SizedBox(
          width: double.infinity, height: 52,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.login_rounded, size: 20),
            label: const Text('Tham gia câu lạc bộ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, AppColorsExtension colors) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, color: colors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── TAB 2: GIẢI ĐẤU ───
  Widget _buildTournamentsTab(Community club, AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: colors.textMuted),
          const SizedBox(height: 12),
          Text('Chưa có giải đấu nào', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  // ─── TAB 3: THÀNH VIÊN ───
  Widget _buildMembersTab(Community club, AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: colors.textMuted),
          const SizedBox(height: 12),
          Text('${club.memberCount} thành viên', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  // ─── TAB 4: BẢNG XẾP HẠNG ───
  Widget _buildRankingsTab(Community club, AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 48, color: colors.textMuted),
          const SizedBox(height: 12),
          Text('Bảng xếp hạng nội bộ', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── TAB BAR DELEGATE ───
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final AppColorsExtension colors;

  _TabBarDelegate({required this.tabController, required this.colors});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: colors.bgDark,
      child: TabBar(
        controller: tabController,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        labelColor: AppTheme.primary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Giới thiệu'),
          Tab(text: 'Giải đấu'),
          Tab(text: 'Thành viên'),
          Tab(text: 'Bảng xếp hạng'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
