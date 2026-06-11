import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/widgets/status_indicator.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/saved_tournaments_provider.dart';
import 'package:app_quanly_giaidau/features/home/widgets/token_input_sheet.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_icon_widget.dart';
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';

class TournamentCard extends ConsumerWidget {
  final Tournament tournament;

  const TournamentCard({super.key, required this.tournament});

  void _showTokenSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TokenInputSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportIcon = AppConstants.sportIcons[tournament.sport] ?? '🏆';
    final sportName =
        AppConstants.sportNames[tournament.sport] ?? tournament.sport;
    final statusName =
        AppConstants.statusNames[tournament.status] ?? tournament.status;
    final bracketName =
        AppConstants.bracketTypeNames[tournament.bracketType] ?? '';

    final statusColor = StatusHelper.getStatusColor(tournament.status, context);
    final ledIndicator = StatusIndicator(status: tournament.status);

    final fbAuth = ref.watch(firebaseAuthProvider);
    final isCreator =
        tournament.creatorId.isNotEmpty &&
        fbAuth.currentUser?.uid == tournament.creatorId;

    return GestureDetector(
      onTap: () async {
        final auth = ref.read(authProvider);

        // Kiểm tra xem giải này có trong danh sách đã lưu không
        final savedList = ref.read(savedTournamentsProvider).value ?? [];
        final savedItem = savedList
            .where((t) => t.id == tournament.id)
            .firstOrNull;

        if (auth.isAuthenticated && auth.tournamentId == tournament.id) {
          final route = NavigationHelper.getTournamentRoute(
            auth.role,
            auth.tournamentId!,
          );
          context.go(route);
        } else if (savedItem != null) {
          // Tự động đăng nhập bằng token đã lưu
          final roleEnum = switch (savedItem.role) {
            'admin' => UserRole.admin,
            'referee' => UserRole.referee,
            'viewer' => UserRole.viewer,
            _ => UserRole.viewer,
          };

          await ref
              .read(authProvider.notifier)
              .loginLocally(
                tokenCode: savedItem.tokenCode,
                role: roleEnum,
                tournamentId: tournament.id,
              );

          if (context.mounted) {
            final route = switch (roleEnum) {
              UserRole.admin => '/admin/tournament/${tournament.id}',
              UserRole.referee => '/intro/${tournament.id}',
              UserRole.viewer => '/intro/${tournament.id}',
            };
            context.go(route);
          }
        } else if (isCreator) {
          // Tự động đăng nhập với tư cách admin vì họ là người tạo
          await ref
              .read(authProvider.notifier)
              .loginLocally(
                tokenCode: tournament.adminToken,
                role: UserRole.admin,
                tournamentId: tournament.id,
              );
          if (context.mounted) {
            context.go('/admin/tournament/${tournament.id}');
          }
        } else {
          _showTokenSheet(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border, width: 0.5),
              ),
              child: Center(
                child: SportIconWidget(iconData: sportIcon),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name.isNotEmpty
                          ? tournament.name
                          : '(Chưa có tên)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tournament.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tournament.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '$sportName • $bracketName',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ledIndicator,
                        const SizedBox(width: 6),
                        Text(
                          statusName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isCreator)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: context.colors.textSecondary,
                ),
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showConfirmDialog(
                      context: context,
                      title: 'Xóa giải đấu?',
                      content: 'Thao tác này không thể hoàn tác.',
                      confirmText: 'Xóa',
                    );
                    if (confirm == true && context.mounted) {
                      final success = await ref
                          .read(tournamentActionProvider.notifier)
                          .deleteTournament(tournament.id);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xóa giải đấu thành công'),
                            ),
                          );
                        } else {
                          final error = ref
                              .read(tournamentActionProvider)
                              .error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi xóa: $error')),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Xóa giải đấu',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            else
              Icon(Icons.chevron_right, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}
