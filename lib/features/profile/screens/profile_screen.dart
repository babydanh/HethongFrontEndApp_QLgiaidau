import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart' as tp;
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;
  bool _uploadingCover = false;
  int _activeTab = 0;

  Future<void> _pickImage(bool isCover) async {
    final colors = context.colors;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCover ? 'Thay đổi ảnh bìa' : 'Thay đổi ảnh đại diện',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                title: Text('Chụp ảnh mới', style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                title: Text('Chọn từ thư viện', style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final fileName = pickedFile.name;

    if (isCover) {
      setState(() => _uploadingCover = true);
      try {
        final repo = ref.read(userRepositoryProvider);
        await repo.uploadCover(bytes, fileName);
        ref.invalidate(userProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ảnh bìa đã được cập nhật'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      } finally {
        if (mounted) setState(() => _uploadingCover = false);
      }
    } else {
      setState(() => _uploading = true);
      try {
        final repo = ref.read(userRepositoryProvider);
        await repo.uploadAvatar(bytes, fileName);
        ref.invalidate(userProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ảnh đại diện đã được cập nhật'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() => _pickImage(false);
  Future<void> _pickAndUploadCover() => _pickImage(true);

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(tp.themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Hồ sơ',
          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/profile/edit'),
            icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
            label: const Text('Sửa', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _buildBody(context, profile, isDark),
        loading: () => const ProfileShimmerLoading(),
        error: (err, _) => _buildError(context, err.toString()),
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) context.go('/home?tab=$index');
        },
        onProfileTap: () {},
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Hồ sơ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              Text('Xin chào!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const SizedBox(height: 12),
              Text(
                'Đăng nhập để xem hồ sơ, theo dõi giải đấu và kết nối với cộng đồng thể thao.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Chưa có tài khoản? Đăng ký ngay',
                    style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: 2,
        onTabSelected: (index) {
          if (index != 2) context.go('/home?tab=$index');
        },
        onProfileTap: () {},
      ),
    );
  }

  // ─── MAIN BODY ──────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, UserProfile profile, bool isDark) {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Cover + Avatar section
          _buildCoverAndAvatar(context, profile),
          const SizedBox(height: 4),

          // Name + Role + Email + Bio
          _buildUserInfo(context, profile),
          const SizedBox(height: 20),

          // Tab bar selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(0, "Thông tin & Chỉ số"),
                  ),
                  Expanded(
                    child: _buildTabButton(1, "Cài đặt & Tiện ích"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content
          if (_activeTab == 0) ...[
            // Dynamic rankings card list based on actual ELO and category ranks
            _buildRankingsSection(context),
            const SizedBox(height: 12),

            // Info Section
            _buildSectionTitle(colors, 'Thông tin cá nhân'),
            const SizedBox(height: 10),
            _buildInfoCard(context, profile),
            const SizedBox(height: 32),
          ] else ...[
            // Account Section
            _buildSectionTitle(colors, 'Tài khoản & Thiết lập'),
            const SizedBox(height: 10),
            _buildAccountMenu(context),
            const SizedBox(height: 20),

            // Other Section
            _buildSectionTitle(colors, 'Tuỳ chọn hệ thống'),
            const SizedBox(height: 10),
            _buildOtherMenu(context, isDark),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final colors = context.colors;
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ─── COVER + AVATAR ─────────────────────────────────────────────────
  Widget _buildCoverAndAvatar(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover photo
        GestureDetector(
          onTap: _pickAndUploadCover,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: profile.coverUrl != null && profile.coverUrl!.isNotEmpty
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: profile.coverUrl != null && profile.coverUrl!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(profile.coverUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _coverGradient()),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, colors.bgDark.withValues(alpha: 0.5)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  )
                : _coverGradient(),
          ),
        ),
        // Cover upload overlay
        Positioned(
          top: 12,
          right: 16,
          child: GestureDetector(
            onTap: _pickAndUploadCover,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
              ),
              child: _uploadingCover
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.camera_alt_rounded, size: 17, color: Colors.white),
            ),
          ),
        ),
        // Avatar
        Positioned(
          bottom: -46,
          left: 24,
          child: GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: Stack(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.bgSurface),
                      child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(43),
                              child: Image.network(profile.avatarUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarFallback(context, profile),
                              ),
                            )
                          : _avatarFallback(context, profile),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                      border: Border.all(color: colors.bgDark, width: 2.5),
                    ),
                    child: _uploading
                        ? const Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverGradient() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  Widget _avatarFallback(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    return Center(
      child: Text(
        _initials(profile.fullName ?? ''),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.textSecondary),
      ),
    );
  }

  // ─── USER INFO ──────────────────────────────────────────────────────
  Widget _buildUserInfo(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 46, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.fullName ?? 'Người dùng',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colors.textPrimary, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 13, color: colors.textMuted),
              const SizedBox(width: 5),
              Text(profile.email ?? '', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              if (profile.isEmailVerified == true) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF22C55E)),
              ],
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Text(profile.bio!, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4)),
            ),
          ],
          const SizedBox(height: 10),
          // Role badge
          if (profile.role != null && profile.role!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.badge_rounded, size: 13, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(profile.role!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── DYNAMIC RANKINGS SECTION ──────────────────────────────────────────
  Widget _buildRankingsSection(BuildContext context) {
    final colors = context.colors;
    final rankingsAsync = ref.watch(userRankingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return rankingsAsync.when(
      data: (rankings) {
        if (rankings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: colors.textMuted, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chưa có dữ liệu đấu xếp hạng ELO',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final categories = categoriesAsync.asData?.value ?? [];

        return Column(
          children: rankings.map((ranking) {
            final category = categories.firstWhere(
              (c) => c.id == ranking.categoryId,
              orElse: () => CategoryModel(id: '', name: 'Bộ môn', slug: '', description: ''),
            );
            final categoryName = category.name.isNotEmpty ? category.name : 'Xếp hạng';
            
            final tier = ranking.tierName.toLowerCase();
            final List<Color> gradientColors;
            if (tier.contains('vàng') || tier.contains('gold') || tier.contains('cao thủ')) {
              gradientColors = const [Color(0xFFFFD700), Color(0xFFFFA500)];
            } else if (tier.contains('bạc') || tier.contains('silver')) {
              gradientColors = const [Color(0xFFB0C4DE), Color(0xFF708090)];
            } else if (tier.contains('đồng') || tier.contains('bronze')) {
              gradientColors = const [Color(0xFFCD7F32), Color(0xFF8B4513)];
            } else {
              gradientColors = const [Color(0xFF2563EB), Color(0xFF1D4ED8)];
            }

            return Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (ranking.tierName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ranking.tierName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRankStatItem('HẠNG', '#${ranking.rank}'),
                      _buildRankStatItem('ELO', '${ranking.eloPoints}'),
                      _buildRankStatItem('TỔNG TRẬN', '${ranking.matchesPlayed}'),
                      _buildRankStatItem(
                        'THẮNG / BẠI',
                        '${ranking.matchesWon} / ${ranking.matchesLost}',
                      ),
                      _buildRankStatItem(
                        'TỈ LỆ',
                        '${ranking.winRate.toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildRankStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ─── INFO CARD ──────────────────────────────────────────────────────
  Widget _buildInfoCard(BuildContext context, UserProfile profile) {
    final colors = context.colors;
    final items = <_InfoItem>[
      _InfoItem(Icons.phone_rounded, 'Số điện thoại', profile.phoneNumber ?? '—'),
      _InfoItem(Icons.cake_rounded, 'Ngày sinh', profile.dateOfBirth ?? '—'),
      _InfoItem(Icons.wc_rounded, 'Giới tính', profile.gender ?? '—'),
      _InfoItem(Icons.location_on_rounded, 'Địa chỉ', profile.address ?? '—'),
      _InfoItem(Icons.map_rounded, 'Tỉnh/Thành phố', profile.provinceCode ?? '—'),
      _InfoItem(Icons.verified_outlined, 'Email xác thực', profile.isEmailVerified == true ? 'Đã xác thực' : 'Chưa xác thực'),
      _InfoItem(Icons.phone_android_rounded, 'SĐT xác thực', profile.isPhoneVerified == true ? 'Đã xác thực' : 'Chưa xác thực'),
    ];
    if (profile.bankName != null && profile.bankName!.isNotEmpty) {
      items.add(_InfoItem(Icons.account_balance_rounded, 'Ngân hàng', profile.bankName!));
    }
    if (profile.bankAccountNumber != null && profile.bankAccountNumber!.isNotEmpty) {
      items.add(_InfoItem(Icons.numbers_rounded, 'STK', profile.bankAccountNumber!));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(left: 58),
          child: Divider(height: 1, color: colors.borderLight),
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(item.icon, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(item.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── ACCOUNT MENU ──────────────────────────────────────────────────
  Widget _buildAccountMenu(BuildContext context) {
    final colors = context.colors;
    final items = [
      _MenuItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
      _MenuItem(Icons.person_outline_rounded, 'Chỉnh sửa hồ sơ', '/profile/edit'),

      _MenuItem(Icons.account_balance_wallet_rounded, 'Lịch sử thanh toán', '/payments'),
      _MenuItem(Icons.emoji_events_rounded, 'Chuỗi giải đấu', '/series'),
	      _MenuItem(Icons.mail_outline_rounded, 'Lời mời CLB', '/club-invites'),
      _MenuItem(Icons.settings_rounded, 'Cài đặt', '/profile/settings'),
      _MenuItem(Icons.lock_outline_rounded, 'Đổi mật khẩu', '/profile/change-password'),
      _MenuItem(Icons.leaderboard_rounded, 'Lịch sử ELO', null),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderLight, indent: 56),
        itemBuilder: (_, i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return InkWell(
            onTap: item.route != null ? () => context.go(item.route!) : null,
            borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(20)) : BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Icon(item.icon, size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── OTHER MENU ────────────────────────────────────────────────────
  Widget _buildOtherMenu(BuildContext context, bool isDark) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.push('/notifications'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.notifications_outlined, size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text('Thông báo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colors.borderLight, indent: 56),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.dark_mode_rounded, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text('Chế độ tối', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary))),
                Switch(
                  value: isDark,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) => ref.read(tp.themeProvider.notifier).toggleTheme(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.borderLight, indent: 56),
          InkWell(
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              ref.invalidate(userProfileProvider);
              ref.invalidate(userRankingsProvider);
              if (mounted) context.go('/home');
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: 20, color: AppTheme.adminColor),
                  const SizedBox(width: 14),
                  const Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.adminColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION TITLE ────────────────────────────────────────────────
  Widget _buildSectionTitle(AppColorsExtension colors, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(width: 3, height: 18, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textSecondary, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  // ─── ERROR ─────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, String message) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text('Không thể tải thông tin',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => ref.invalidate(userProfileProvider), child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────────────
  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[p.length - 2][0]}${p[p.length - 1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── DATA CLASSES ───────────────────────────────────────────────────
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? route;
  const _MenuItem(this.icon, this.label, this.route);
}

// ─── SHIMMER ────────────────────────────────────────────────────────
class ProfileShimmerLoading extends StatelessWidget {
  const ProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.border,
      highlightColor: colors.bgSurface,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 180, color: colors.border),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 160, height: 22, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 8),
                  Container(width: 200, height: 14, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 16),
                  Container(height: 100, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 20),
                  Container(width: 120, height: 14, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  Container(height: 200, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 20),
                  Container(width: 120, height: 14, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  Container(height: 160, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(20))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
