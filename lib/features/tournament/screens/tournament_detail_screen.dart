import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';

import 'package:app_quanly_giaidau/core/widgets/responsive_layout.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/token_management_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/core/widgets/info_chip.dart';
import 'package:app_quanly_giaidau/core/widgets/app_action_button.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_icon_widget.dart';

enum SelectedFeature { none, tokens, teams, draw, bracket }

class TournamentDetailScreen extends ConsumerStatefulWidget {
  static const _log = AppLogger('TournamentDetailScreen');
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});
  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen> {
  SelectedFeature _selectedFeature = SelectedFeature.none;

  @override
  Widget build(BuildContext context) {
    TournamentDetailScreen._log
        .debug('Building with tournamentId = ${widget.tournamentId}');
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
      data: (tournament) {
        if (tournament == null) {
          return const Scaffold(
            body: Center(child: Text('Giải đấu không tồn tại')),
          );
        }

        return Scaffold(
          backgroundColor: context.colors.bgDark,
          appBar: AppBar(
            backgroundColor: context.colors.bgDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/admin'),
            ),
            title: Text(
                tournament.name.isNotEmpty ? tournament.name : '(Chưa có tên)'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                color: context.colors.bgCard,
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
                          .deleteTournament(widget.tournamentId);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Đã xóa giải đấu thành công')),
                          );
                          context.go('/admin');
                        } else {
                          final error =
                              ref.read(tournamentActionProvider).error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi xóa: $error')),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete,
                            color: context.colors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Xóa giải đấu',
                            style: TextStyle(color: context.colors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ResponsiveLayout(
            mobile: _buildMasterView(context, tournament),
            tablet: Row(
              children: [
                SizedBox(
                  width: 320,
                  child: _buildMasterView(context, tournament, isTablet: true),
                ),
                VerticalDivider(width: 1, color: context.colors.border),
                Expanded(
                  child: _buildDetailView(context),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: context.colors.bgDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.colors.bgDark,
        body: Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context) {
    switch (_selectedFeature) {
      case SelectedFeature.tokens:
        return TokenManagementScreen(
            tournamentId: widget.tournamentId, isEmbedded: true);
      case SelectedFeature.teams:
        return TeamListScreen(
            tournamentId: widget.tournamentId, isEmbedded: true);
      case SelectedFeature.draw:
        return AutoDrawScreen(
            tournamentId: widget.tournamentId, isEmbedded: true);
      case SelectedFeature.bracket:
        return BracketViewScreen(
            tournamentId: widget.tournamentId, isEmbedded: true);
      case SelectedFeature.none:
        return Center(
          child: Text(
            'Chọn một chức năng bên trái',
            style:
                TextStyle(color: context.colors.textSecondary, fontSize: 16),
          ),
        );
    }
  }

  Widget _buildMasterView(BuildContext context, dynamic tournament,
      {bool isTablet = false}) {
    final sportIcon = AppConstants.sportIcons[tournament.sport] ?? '🏆';
    final sportName =
        AppConstants.sportNames[tournament.sport] ?? tournament.sport;
    final formatName = AppConstants.formatNames[tournament.format] ?? '';
    final categoryName = tournament.category != null
        ? AppConstants.categoryNames[tournament.category]
        : null;
    final bracketName =
        AppConstants.bracketTypeNames[tournament.bracketType] ?? '';
    final statusName = AppConstants.statusNames[tournament.status] ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Info Card ───
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: context.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            children: [
              SportIconWidget(iconData: sportIcon, size: 48),
              const SizedBox(height: 12),
              Text(
                tournament.name.isNotEmpty
                    ? tournament.name
                    : '(Chưa có tên)',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        InfoChip(label: sportName, color: AppTheme.primary),
                        InfoChip(label: formatName, color: AppTheme.secondary),
                        if (categoryName != null) InfoChip(label: categoryName, color: AppTheme.adminColor),
                        InfoChip(label: bracketName, color: context.colors.warning),
                        InfoChip(label: statusName, color: context.colors.success),
                        InfoChip(label: '${tournament.maxTeams} Đội', color: AppTheme.primary),
                        if (tournament.maxPlayersPerTeam != null) 
                          InfoChip(label: '${tournament.maxPlayersPerTeam} Người/Đội', color: AppTheme.secondary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tokens were moved to Token Management Screen

              // ─── Quick Actions ───
              Text(
                'QUẢN LÝ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              AppActionButton(
                icon: Icons.qr_code_rounded,
                label: 'Quản lý Mã truy cập (Token)',
                subtitle: 'Xem QR Code, Refresh Token, Số người online',
                color: AppTheme.adminColor,
                isSelected: _selectedFeature == SelectedFeature.tokens,
                onTap: () {
                  if (isTablet) {
                    setState(() => _selectedFeature = SelectedFeature.tokens);
                  } else {
                    context.go('/admin/tournament/${widget.tournamentId}/tokens');
                  }
                },
              ),
              const SizedBox(height: 8),
              AppActionButton(
                icon: Icons.people_rounded,
                label: 'Quản lý đội / VĐV',
                subtitle: 'Thêm, sửa, import danh sách',
                color: AppTheme.primary,
                isSelected: _selectedFeature == SelectedFeature.teams,
                onTap: () {
                  if (isTablet) {
                    setState(() => _selectedFeature = SelectedFeature.teams);
                  } else {
                    context.go('/admin/tournament/${widget.tournamentId}/teams');
                  }
                },
              ),
              const SizedBox(height: 8),
              AppActionButton(
                icon: Icons.casino_rounded,
                label: 'Bốc thăm & Phân bảng',
                subtitle: 'Tự động hoặc thủ công',
                color: context.colors.warning,
                isSelected: _selectedFeature == SelectedFeature.draw,
                onTap: () {
                  if (isTablet) {
                    setState(() => _selectedFeature = SelectedFeature.draw);
                  } else {
                    context.go('/admin/tournament/${widget.tournamentId}/draw');
                  }
                },
              ),
              const SizedBox(height: 8),
              AppActionButton(
                icon: Icons.account_tree_rounded,
                label: 'Xem Bracket',
                subtitle: 'Sơ đồ thi đấu & kết quả',
                color: AppTheme.secondary,
                isSelected: _selectedFeature == SelectedFeature.bracket,
                onTap: () {
                  if (isTablet) {
                    setState(() => _selectedFeature = SelectedFeature.bracket);
                  } else {
                    context.go('/admin/tournament/${widget.tournamentId}/bracket');
                  }
                },
              ),
              if (tournament.status == AppConstants.statusInProgress) ...[
                const SizedBox(height: 8),
                AppActionButton(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Kết thúc giải đấu',
                  subtitle: 'Khóa kết quả và trao giải',
                  color: context.colors.success,
                  isSelected: false,
                  onTap: () async {
                    final confirm = await showConfirmDialog(
                      context: context,
                      title: 'Xác nhận kết thúc',
                      content: 'Bạn có chắc chắn muốn kết thúc giải đấu? Thao tác này sẽ khóa toàn bộ các trận đấu.',
                      confirmText: 'Xác nhận kết thúc',
                      cancelText: 'Tiếp tục',
                    );
                    if (confirm == true && context.mounted) {
                      final success = await ref
                          .read(tournamentActionProvider.notifier)
                          .finalizeTournament(widget.tournamentId);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Giải đấu đã kết thúc thành công!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Có lỗi xảy ra khi kết thúc giải đấu.')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 8),
              AppActionButton(
                icon: Icons.download_rounded,
                label: 'Xuất dữ liệu giải đấu',
                subtitle: 'Xuất toàn bộ kết quả ra Excel',
                color: AppTheme.primary,
                isSelected: false,
                onTap: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang tạo file Excel...')),
                    );
                    final matches = await ref.read(matchesProvider(widget.tournamentId).future);
                    await ExcelExportService.exportTournamentData(tournament.name, matches);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Xuất dữ liệu thành công!'), backgroundColor: context.colors.success),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: context.colors.error),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          );
  }





}
