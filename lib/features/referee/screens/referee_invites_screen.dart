import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RefereeInvitesScreen extends ConsumerWidget {
  const RefereeInvitesScreen({super.key});

  static const _log = AppLogger('RefereeInvitesScreen');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final invitesAsync = ref.watch(myRefereeInvitesProvider);

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Lời mời trọng tài',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: invitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _InviteErrorView(
          onRetry: () => ref.read(myTournamentWorkspaceProvider.notifier).refresh(),
        ),
        data: (invites) {
          final pendingInvites = invites.where((invite) => invite.isPending).toList();
          if (pendingInvites.isEmpty) {
            return const _InviteEmptyView();
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(myTournamentWorkspaceProvider.notifier).refresh(),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: pendingInvites.length,
              itemBuilder: (context, index) {
                return _InviteCard(
                  invite: pendingInvites[index],
                  index: index,
                  onAccept: () => _handleAction(
                    context,
                    ref,
                    pendingInvites[index],
                    'ACCEPT',
                  ),
                  onDecline: () => _handleAction(
                    context,
                    ref,
                    pendingInvites[index],
                    'DECLINE',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    TournamentRefereeInvite invite,
    String action,
  ) async {
    try {
      await ref.read(myTournamentWorkspaceProvider.notifier).respondToRefereeInvite(
            tournamentId: invite.tournamentId,
            refereeId: invite.refereeId,
            action: action,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'ACCEPT'
                ? 'Đã nhận lời mời trọng tài'
                : 'Đã từ chối lời mời trọng tài',
          ),
          backgroundColor:
              action == 'ACCEPT' ? const Color(0xFF10B981) : context.colors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stack) {
      _log.error('Lỗi xử lý lời mời trọng tài', e, stack);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xử lý lời mời: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.index,
    required this.onAccept,
    required this.onDecline,
  });

  final TournamentRefereeInvite invite;
  final int index;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final assignedText = invite.assignedAt != null
        ? DateFormatterUtils.formatDateTime(invite.assignedAt!.toLocal())
        : 'Chưa rõ lịch';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.refereeColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.refereeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: AppTheme.refereeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.tournamentName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invite.categoryName.isNotEmpty
                          ? invite.categoryName
                          : 'Phân công trọng tài',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.refereeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Chờ phản hồi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.refereeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InviteMetaRow(
            icon: Icons.schedule_rounded,
            label: 'Ngày mời',
            value: assignedText,
          ),
          const SizedBox(height: 8),
          _InviteMetaRow(
            icon: Icons.flag_rounded,
            label: 'Trạng thái giải',
            value: _mapTournamentStatus(invite.tournamentStatus),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'Nhận nhiệm vụ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text(
                    'Từ chối',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms, delay: (index * 60).ms);
  }
}

class _InviteMetaRow extends StatelessWidget {
  const _InviteMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _InviteEmptyView extends StatelessWidget {
  const _InviteEmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.mail_outline_rounded,
                size: 40,
                color: colors.textMuted.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có lời mời nào',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Khi ban tổ chức mời bạn làm trọng tài, lời mời sẽ hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteErrorView extends StatelessWidget {
  const _InviteErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Không thể tải lời mời trọng tài',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

String _mapTournamentStatus(String status) {
  switch (status.toUpperCase()) {
    case 'DRAFT':
      return 'Bản nháp';
    case 'REGISTRATION_OPEN':
      return 'Đang mở đăng ký';
    case 'REGISTRATION_CLOSED':
      return 'Đã đóng đăng ký';
    case 'ONGOING':
    case 'IN_PROGRESS':
      return 'Đang diễn ra';
    case 'COMPLETED':
      return 'Đã hoàn thành';
    default:
      return 'Đang cập nhật';
  }
}
