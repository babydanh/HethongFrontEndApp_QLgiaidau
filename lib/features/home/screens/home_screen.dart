import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart';
import 'package:app_quanly_giaidau/features/home/widgets/token_input_sheet.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_card.dart';
import 'package:app_quanly_giaidau/core/widgets/responsive_layout.dart';
import 'package:app_quanly_giaidau/core/widgets/app_focusable.dart';
import 'package:app_quanly_giaidau/core/widgets/app_action_button.dart';
import 'package:app_quanly_giaidau/core/extensions/animation_extensions.dart';
import 'dart:ui';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Đảm bảo auth được khởi tạo (ẩn danh) nếu user vào thẳng /home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).init();
    });
  }

  @override
  void dispose() {
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


  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Text('Tournament Pro', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Phiên bản 1.0.0', style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text('Hệ thống quản lý giải đấu chuyên nghiệp đa môn thể thao, giúp bạn vận hành giải đấu dễ dàng và minh bạch.', 
              style: TextStyle(color: context.colors.textSecondary, height: 1.5)),
            const SizedBox(height: 16),
            _buildInfoRow('🏆', 'Quản lý Đấu loại trực tiếp & Vòng tròn'),
            _buildInfoRow('📊', 'Hệ thống Chấm điểm Live Score'),
            _buildInfoRow('📝', 'Ghi nhận chi tiết Sự kiện (Thẻ, Lỗi)'),
            _buildInfoRow('📥', 'Tự động xuất Biên bản Excel'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: TextStyle(color: context.colors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: context.colors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildGlassQrBubble() {
    return GestureDetector(
      onTap: () => context.push('/scan-qr'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .scaleXY(begin: 1.0, end: 1.08, duration: 2.seconds, curve: Curves.easeInOut)
       .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(myTournamentsProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      floatingActionButton: _buildGlassQrBubble(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Header Banner ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: isDark
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E1E30), Color(0xFF0F0F1A)],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.15),
                            AppTheme.secondary.withValues(alpha: 0.05),
                          ],
                        ),
                    border: Border.all(
                      color: isDark ? context.colors.border : AppTheme.primary.withValues(alpha: 0.2), 
                      width: 1
                    ),
                    boxShadow: isDark ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ] : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // Cúp vàng chuyển động xoay nhẹ phát sáng
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events_rounded,
                                    color: AppTheme.accent,
                                    size: 28,
                                  ),
                                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                 .shimmer(delay: 2.seconds, duration: 1500.ms)
                                 .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tournament Pro',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: context.colors.textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'Hệ thống quản lý chuyên nghiệp',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.colors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: context.colors.bgSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: context.colors.border),
                                ),
                                child: IconButton(
                                  onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                                  icon: Icon(
                                    ref.watch(themeProvider) == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                                    color: context.colors.textSecondary, 
                                    size: 20
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: context.colors.bgSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: context.colors.border),
                                ),
                                child: IconButton(
                                  onPressed: _showAppInfoDialog,
                                  icon: Icon(Icons.info_outline, color: context.colors.textSecondary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Quick Actions Row
                      Row(
                        children: [
                          Expanded(
                            child: AppActionButton(
                              layout: Axis.vertical,
                              label: 'Tạo giải đấu',
                              subtitle: 'Dành cho BTC',
                              icon: Icons.add_box_rounded,
                              color: AppTheme.primary,
                              onTap: () => context.go('/admin/create'),
                            ).fadeInSlide(delay: 100.ms),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppActionButton(
                              layout: Axis.vertical,
                              label: 'Nhập mã',
                              subtitle: 'Tham gia giải',
                              icon: Icons.keyboard_alt_outlined,
                              color: context.colors.info,
                              onTap: _showTokenSheet,
                            ).fadeInSlide(delay: 200.ms),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── List Section Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Giải đấu của bạn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Tournament List ───
            tournamentsAsync.when(
              data: (tournaments) {
                if (tournaments.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: context.colors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có giải đấu nào',
                            style: TextStyle(fontSize: 15, color: context.colors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hãy nhấn "Tạo giải đấu" để bắt đầu giải đấu đầu tiên của bạn!',
                            style: TextStyle(fontSize: 12, color: context.colors.textSecondary.withValues(alpha: 0.6)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverResponsiveLayout(
                    mobile: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TournamentCard(tournament: tournaments[index]),
                          )
                              .animate().fadeIn(
                            delay: (index * 50).ms,
                            duration: 350.ms,
                          ).slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack);
                        },
                        childCount: tournaments.length,
                      ),
                    ),
                    tablet: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 145,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return AppFocusable(
                            child: TournamentCard(tournament: tournaments[index]),
                          ).slideInFromBottom(delay: (index * 50).ms);
                        },
                        childCount: tournaments.length,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Lỗi: $e', style: TextStyle(color: context.colors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
