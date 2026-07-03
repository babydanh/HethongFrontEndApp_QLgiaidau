import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';

/// Admin duyệt CLB mới — danh sách PENDING clubs, nút Duyệt/Từ chối.
class PendingClubsScreen extends ConsumerWidget {
  const PendingClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingCommunitiesProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Duyệt CLB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: pendingAsync.when(
        data: (clubs) {
          if (clubs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 64, color: colors.textMuted),
                  const SizedBox(height: 16),
                  Text('Không có CLB nào chờ duyệt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Tất cả CLB đã được xét duyệt', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: clubs.length,
            itemBuilder: (context, i) => _buildClubCard(context, clubs[i], colors, ref),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
                const SizedBox(height: 12),
                Text('Lỗi tải danh sách', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => ref.invalidate(pendingCommunitiesProvider), child: const Text('Thử lại')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClubCard(BuildContext context, Community club, AppColorsExtension colors, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (club.name.isNotEmpty ? club.name[0] : '?').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (club.description != null && club.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(club.description!, style: TextStyle(fontSize: 12, color: colors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: colors.textMuted),
              const SizedBox(width: 4),
              Text('${club.memberCount} thành viên', style: TextStyle(fontSize: 11, color: colors.textMuted)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: const Text('Chờ duyệt', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    try {
                      await ref.read(communityRepositoryProvider).reviewCommunity(club.id, 'ACTIVE');
                      ref.invalidate(pendingCommunitiesProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Đã duyệt CLB'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating,
                        ));
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Duyệt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showRejectDialog(context, club, colors, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded, color: colors.textSecondary, size: 18),
                        const SizedBox(width: 6),
                        Text('Từ chối', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700, fontSize: 14)),
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

  void _showRejectDialog(BuildContext context, Community club, AppColorsExtension colors, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text('Từ chối CLB', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Từ chối "${club.name}"?', style: TextStyle(color: colors.textPrimary, fontSize: 15)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 200,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Lý do từ chối (bắt buộc)',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await ref.read(communityRepositoryProvider).reviewCommunity(club.id, 'REJECTED', rejectedReason: controller.text.trim());
                ref.invalidate(pendingCommunitiesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Đã từ chối CLB'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
