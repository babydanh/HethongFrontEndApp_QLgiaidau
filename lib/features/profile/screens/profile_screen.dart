import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Hồ sơ',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/profile/edit'),
            icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF2979FF)),
            label: const Text(
              'Sửa',
              style: TextStyle(
                color: Color(0xFF2979FF),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _buildBody(context, ref, profile, isDark),
        loading: () => const ProfileShimmerLoading(),
        error: (err, _) => _buildError(context, err.toString()),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Hồ sơ',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
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
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, size: 48, color: Color(0xFF2979FF)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Xin chào!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Đăng nhập để xem hồ sơ, theo dõi giải đấu và kết nối với cộng đồng thể thao.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Chưa có tài khoản? Đăng ký',
                  style: TextStyle(fontSize: 13, color: Color(0xFF2979FF), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, UserProfile profile, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildAvatarSection(context, profile),
          const SizedBox(height: 20),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Thông tin cá nhân'),
          const SizedBox(height: 12),
          _buildInfoCard(context, profile),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Tài khoản'),
          const SizedBox(height: 12),
          _buildAccountMenu(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Khác'),
          const SizedBox(height: 12),
          _buildOtherMenu(context, isDark, ref),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFB0BEC5)),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải thông tin',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, UserProfile profile) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2979FF), Color(0xFF448AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2979FF).withOpacity( 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF1F5F9),
                  ),
                  child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(41),
                          child: Image.network(profile.avatarUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.person_rounded, size: 46, color: Color(0xFF2979FF)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2979FF),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          profile.fullName ?? 'Người dùng',
          style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A), letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email ?? '',
          style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF2979FF).withOpacity( 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2979FF).withOpacity( 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_esports_rounded, size: 14, color: Color(0xFF2979FF)),
              const SizedBox(width: 6),
              Text(
                profile.role ?? 'Player',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2979FF)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 3, height: 18,
            decoration: BoxDecoration(color: const Color(0xFF2979FF), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, UserProfile profile) {
    final items = <(IconData, String, String?)>[
      (Icons.phone_rounded, 'Số điện thoại', profile.phoneNumber ?? 'Chưa cập nhật'),
      (Icons.cake_rounded, 'Ngày sinh', profile.dateOfBirth ?? 'Chưa cập nhật'),
      (Icons.wc_rounded, 'Giới tính', profile.gender ?? 'Chưa cập nhật'),
      (Icons.location_on_rounded, 'Địa chỉ', profile.address ?? 'Chưa cập nhật'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2979FF).withOpacity( 0.06), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity( 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final (icon, label, value) = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFF2979FF).withOpacity( 0.08), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, size: 18, color: const Color(0xFF2979FF)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 3),
                          Text(value ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
              if (!isLast) Padding(
                padding: const EdgeInsets.only(left: 66),
                child: Divider(height: 1, color: const Color(0xFFF1F5F9)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAccountMenu(BuildContext context) {
    final items = [
      (icon: Icons.settings_rounded, label: 'Cài đặt', route: '/profile/settings'),
      (icon: Icons.edit_rounded, label: 'Sửa thông tin', route: '/profile/edit'),
      (icon: Icons.lock_outline_rounded, label: 'Đổi mật khẩu', route: '/profile/change-password'),
      (icon: Icons.bar_chart_rounded, label: 'Lịch sử ELO', route: null),
      (icon: Icons.emoji_events_rounded, label: 'Thành tích', route: null),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2979FF).withOpacity( 0.06), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity( 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item.route != null ? () => context.go(item.route!) : null,
                borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(20)) : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: const Color(0xFF2979FF).withOpacity( 0.08), borderRadius: BorderRadius.circular(10)),
                        child: Icon(item.icon, size: 18, color: const Color(0xFF2979FF)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(item.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, color: const Color(0xFFF1F5F9), indent: 66),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildOtherMenu(BuildContext context, bool isDark, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2979FF).withOpacity( 0.06), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity( 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {},
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFF2979FF).withOpacity( 0.08), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF2979FF)),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text('Thông báo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: const Color(0xFFF1F5F9), indent: 66),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFF2979FF).withOpacity( 0.08), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.dark_mode_rounded, size: 18, color: Color(0xFF2979FF)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Chế độ tối', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                ),
                Switch(
                  value: isDark,
                  activeThumbColor: const Color(0xFF2979FF),
                  onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: const Color(0xFFF1F5F9), indent: 66),
          InkWell(
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/home');
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                  SizedBox(width: 14),
                  Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileShimmerLoading extends StatelessWidget {
  const ProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(width: 88, height: 88, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
            const SizedBox(height: 16),
            Container(width: 160, height: 20, decoration: BoxDecoration(color: Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            Container(width: 180, height: 14, decoration: BoxDecoration(color: Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 24),
            Container(height: 120, decoration: BoxDecoration(color: Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 24),
            Container(width: 120, height: 14, decoration: BoxDecoration(color: Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Container(height: 200, decoration: BoxDecoration(color: Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }
}
