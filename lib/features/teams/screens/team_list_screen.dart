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
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TeamListScreen extends ConsumerWidget {
  final String tournamentId;
  final bool isEmbedded;
  const TeamListScreen({super.key, required this.tournamentId, this.isEmbedded = false});

  Future<void> _importExcel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
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
              content: Text(l10n.teamList_invalidImport),
              backgroundColor: context.colors.warning));
        }
        return;
      }

      await ref.read(teamServiceProvider(tournamentId)).importTeams(teams);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.teamList_importSuccess(teams.length)),
            backgroundColor: context.colors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.teamList_importError(e.toString())),
            backgroundColor: context.colors.error));
      }
    }
  }

  Future<void> _deleteAllTeams(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showConfirmDialog(
      context: context,
      title: l10n.teamList_deleteAllTitle,
      content: l10n.teamList_deleteAllContent,
      confirmText: l10n.teamList_deleteAllConfirm,
    );

    if (confirm == true) {
      try {
        await ref.read(teamServiceProvider(tournamentId)).deleteAllTeams();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.teamList_deleteAllDone),
              backgroundColor: context.colors.success));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.teamList_error(e.toString())),
              backgroundColor: context.colors.error));
        }
      }
    }
  }

  @override
    Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.teamList_title),
        actions: [
          if (!isLocked) ...[
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: l10n.teamList_importTooltip,
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
                  child: Text(l10n.teamList_deleteAll, style: TextStyle(color: context.colors.error)),
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
                  Text(l10n.teamList_empty,
                      style: TextStyle(fontSize: 16, color: context.colors.textSecondary)),
                  const SizedBox(height: 24),
                  if (!isLocked)
                    ElevatedButton.icon(
                      onPressed: () => context.go(
                          '/admin/tournament/$tournamentId/teams/add'),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.teamList_addNew),
                    ),
                  if (isLocked)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(l10n.teamList_locked,
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
        error: (e, _) => Center(child: Text(l10n.teamList_error(e.toString))),
      ),
      floatingActionButton: isLocked ? null : FloatingActionButton.extended(
        onPressed: () =>
            context.go('/admin/tournament/$tournamentId/teams/add'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(l10n.teamList_add,
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
    final l10n = AppLocalizations.of(context)!;
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
              child: Text(l10n.teamList_approved,
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
                  title: l10n.teamList_deleteTitle,
                  content: l10n.teamList_deleteContent(team.name),
                  confirmText: l10n.teamList_deleteConfirm,
                );
                if (confirm == true) {
                  try {
                    await ref.read(teamServiceProvider(tournamentId)).deleteTeam(team.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.teamList_deleteError(e.toString())), backgroundColor: context.colors.error)
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
