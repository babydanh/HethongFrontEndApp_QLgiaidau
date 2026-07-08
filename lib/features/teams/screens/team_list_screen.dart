import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:uuid/uuid.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/providers/team_notifier.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';

class TeamListScreen extends ConsumerWidget {
  final String tournamentId;
  final bool isEmbedded;
  const TeamListScreen({super.key, required this.tournamentId, this.isEmbedded = false});

  Future<void> _importExcel(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        // ignore: deprecated_member_use
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      // ignore: deprecated_member_use
      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final excel = Excel.decodeBytes(bytes);
      final teams = <Team>[];

      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        for (int i = 0; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty) continue;

          final teamNameCell = row[0]?.value?.toString().trim();
          if (teamNameCell == null || teamNameCell.isEmpty) continue;
          if (i == 0 && teamNameCell.toLowerCase().contains('tên')) continue;

          final members = <String>[];
          for (int j = 1; j < row.length; j++) {
            final memberName = row[j]?.value?.toString().trim();
            if (memberName != null && memberName.isNotEmpty) {
              members.add(memberName);
            }
          }

          final id = const Uuid().v4();
          teams.add(Team(
            id: id,
            name: teamNameCell,
            members: members,
            qrCode: 'VDV_${id.substring(0, 6).toUpperCase()}',
            createdAt: DateTime.now(),
          ));
        }
      }

      if (teams.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Không tìm thấy dữ liệu hợp lệ trong file'),
              backgroundColor: context.colors.warning));
        }
        return;
      }

      await ref.read(teamServiceProvider(tournamentId)).importTeams(teams);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Import thành công ${teams.length} đội!'),
            backgroundColor: context.colors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Lỗi import: $e'),
            backgroundColor: context.colors.error));
      }
    }
  }

  Future<void> _deleteAllTeams(BuildContext context, WidgetRef ref) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Xóa toàn bộ?',
      content: 'Bạn có chắc chắn muốn xóa TOÀN BỘ các đội bóng?\n\nHành động này cũng sẽ xóa toàn bộ sơ đồ/kết quả thi đấu của giải.',
      confirmText: 'Xóa tất cả',
    );

    if (confirm == true) {
      try {
        await ref.read(teamServiceProvider(tournamentId)).deleteAllTeams();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Đã xóa toàn bộ đội bóng!'),
              backgroundColor: context.colors.success));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: context.colors.error));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider(tournamentId));
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));
    final tournament = tournamentAsync.value;
    
    final isLocked = tournament?.status == AppConstants.statusInProgress || 
                     tournament?.status == AppConstants.statusCompleted;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        leading: isEmbedded ? const SizedBox.shrink() : IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/tournament/$tournamentId'),
        ),
        title: const Text('Quản lý đội / VĐV'),
        actions: [
          if (!isLocked) ...[
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Import từ Excel',
              onPressed: () => _importExcel(context, ref),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              color: context.colors.bgCard,
              onSelected: (value) {
                if (value == 'delete_all') {
                  _deleteAllTeams(context, ref);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete_all',
                  child: Text('Xóa toàn bộ đội', style: TextStyle(color: context.colors.error)),
                ),
              ],
            ),
          ]
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64,
                      color: context.colors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Chưa có đội nào',
                      style: TextStyle(fontSize: 16, color: context.colors.textSecondary)),
                  const SizedBox(height: 24),
                  if (!isLocked)
                    ElevatedButton.icon(
                      onPressed: () => context.go(
                          '/admin/tournament/$tournamentId/teams/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm đội mới'),
                    ),
                  if (isLocked)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text('Giải đấu đang diễn ra. Không thể thêm đội.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.error, fontSize: 13)),
                    )
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 88),
            itemCount: teams.length,
            itemBuilder: (context, index) => TeamListTile(
              team: teams[index],
              index: index + 1,
              isLocked: isLocked,
              tournamentId: tournamentId,
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: isLocked ? null : FloatingActionButton.extended(
        onPressed: () =>
            context.go('/admin/tournament/$tournamentId/teams/add'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm đội',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class TeamListTile extends ConsumerWidget {
  final Team team;
  final int index;
  final bool isLocked;
  final String tournamentId;

  const TeamListTile({
    super.key,
    required this.team,
    required this.index,
    required this.isLocked,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                if (team.members.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    team.members.join(', '),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ],
            ),
          ),
          if (team.isApproved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('✓ Đã duyệt',
                  style: TextStyle(fontSize: 10, color: context.colors.success, fontWeight: FontWeight.w600)),
            ),
          if (!isLocked) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 20, color: context.colors.textMuted),
              onPressed: () {
                context.go('/admin/tournament/$tournamentId/teams/edit', extra: team);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: context.colors.error),
              onPressed: () async {
                final confirm = await showConfirmDialog(
                  context: context,
                  title: 'Xóa đội',
                  content: 'Xóa đội ${team.name}?',
                  confirmText: 'Xóa',
                );
                if (confirm == true) {
                  try {
                    await ref.read(teamServiceProvider(tournamentId)).deleteTeam(team.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: context.colors.error)
                      );
                    }
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
