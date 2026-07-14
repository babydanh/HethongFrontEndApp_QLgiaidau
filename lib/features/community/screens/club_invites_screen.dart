import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/models/community_invite_model.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';

/// Màn hình danh sách lời mời tham gia CLB của người dùng.
///
/// Hiển thị các lời mời PENDING, cho phép Accept/Decline.
/// Gọi API respondToInvite để xử lý từng lời mời.
class ClubInvitesScreen extends ConsumerStatefulWidget {
  const ClubInvitesScreen({super.key});

  @override
  ConsumerState<ClubInvitesScreen> createState() => _ClubInvitesScreenState();
}

class _ClubInvitesScreenState extends ConsumerState<ClubInvitesScreen> {
  static const _log = AppLogger('ClubInvites');

  Future<void> _handleAction(String communityId, String action) async {
    _log.info('$action lời mời CLB $communityId');
    try {
      await ref.read(communityRepositoryProvider).respondToInvite(communityId, action);
      ref.invalidate(myCommunityInvitesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept' ? 'Đã chấp nhận lời mời!' : 'Đã từ chối lời mời'),
            backgroundColor: action == 'accept' ? context.colors.success : context.colors.textSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi $action lời mời', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final invitesAsync = ref.watch(myCommunityInvitesProvider);

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          'Lời mời CLB',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: invitesAsync.when(
        data: (invites) {
          final pending = invites.where((i) => i.isPending).toList();
          if (pending.isEmpty) return _buildEmpty(colors);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myCommunityInvitesProvider),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: pending.length,
              itemBuilder: (context, i) => _buildInviteCard(pending[i], i, colors),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(colors, () => ref.invalidate(myCommunityInvitesProvider)),
      ),
    );
  }

  Widget _buildInviteCard(CommunityInviteModel invite, int index, AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo CLB
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: invite.communityLogoUrl != null && invite.communityLogoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(invite.communityLogoUrl!, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 24),
                        ),
                      )
                    : const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.communityName,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (invite.inviterName.isNotEmpty)
                      Text(
                        'Được mời bởi ${invite.inviterName}',
                        style: TextStyle(fontSize: 12, color: colors.textMuted),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Chờ duyệt',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _handleAction(invite.communityId, 'accept'),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Chấp nhận', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleAction(invite.communityId, 'decline'),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms);
  }

  Widget _buildEmpty(AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.mail_outline_rounded, size: 40, color: colors.textMuted.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có lời mời nào',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Các lời mời tham gia câu lạc bộ sẽ hiển thị tại đây',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(AppColorsExtension colors, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text('Không thể tải lời mời', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
