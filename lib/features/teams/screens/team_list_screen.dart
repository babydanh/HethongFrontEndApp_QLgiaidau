import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:uuid/uuid.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/providers/team_notifier.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TeamListScreen extends ConsumerWidget {
  final String tournamentId;
  final bool isEmbedded;
  final String? managementRouteBase;

  const TeamListScreen({
    super.key,
    required this.tournamentId,
    this.isEmbedded = false,
    this.managementRouteBase,
  });

  String get _managementRouteBase =>
      managementRouteBase ?? '/admin/tournament/$tournamentId';

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
          teams.add(
            Team(
              id: id,
              name: teamNameCell,
              members: members,
              qrCode: 'VDV_${id.substring(0, 6).toUpperCase()}',
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      if (teams.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.teamList_invalidImport),
              backgroundColor: context.colors.warning,
            ),
          );
        }
        return;
      }

      await ref.read(teamServiceProvider(tournamentId)).importTeams(teams);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.teamList_importSuccess(teams.length)),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.teamList_importError(e.toString())),
            backgroundColor: context.colors.error,
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.teamList_deleteAllDone),
              backgroundColor: context.colors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.teamList_error(e.toString())),
              backgroundColor: context.colors.error,
            ),
          );
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

    final isLocked =
        tournament?.status == AppConstants.statusInProgress ||
        tournament?.status == AppConstants.statusCompleted;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        leading: isEmbedded
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(_managementRouteBase);
                  }
                },
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
                  child: Text(
                    l10n.teamList_deleteAll,
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: context.colors.textMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.teamList_empty,
                    style: TextStyle(
                      fontSize: 16,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!isLocked)
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.push('$_managementRouteBase/teams/add'),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.teamList_addNew),
                    ),
                  if (isLocked)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        l10n.teamList_locked,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          return _TeamListBody(
            teams: teams,
            isLocked: isLocked,
            tournamentId: tournamentId,
            managementRouteBase: _managementRouteBase,
          );
        },
        loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: ListPageSkeleton(),
        ),
        error: (e, _) => Center(child: Text(l10n.teamList_error(e.toString))),
      ),
      floatingActionButton: isLocked
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('$_managementRouteBase/teams/add'),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                l10n.teamList_add,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

enum _TeamFilter { all, approved, pending }

/// Search box + status chips (with counts) + the team rows.
class _TeamListBody extends StatefulWidget {
  const _TeamListBody({
    required this.teams,
    required this.isLocked,
    required this.tournamentId,
    required this.managementRouteBase,
  });

  final List<Team> teams;
  final bool isLocked;
  final String tournamentId;
  final String managementRouteBase;

  @override
  State<_TeamListBody> createState() => _TeamListBodyState();
}

class _TeamListBodyState extends State<_TeamListBody> {
  String _query = '';
  _TeamFilter _filter = _TeamFilter.all;

  bool _matchesQuery(Team team) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return team.name.toLowerCase().contains(query) ||
        team.members.any((member) => member.toLowerCase().contains(query));
  }

  bool _matchesFilter(Team team) => switch (_filter) {
    _TeamFilter.all => true,
    _TeamFilter.approved => team.isApproved,
    _TeamFilter.pending => team.isPendingApproval,
  };

  Widget _chip(String label, _TeamFilter value, int count) => LavishChipButton(
    label: '$label $count',
    selected: _filter == value,
    onPressed: () => setState(() => _filter = value),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teams = widget.teams;
    final approvedCount = teams.where((team) => team.isApproved).length;
    final pendingCount = teams.where((team) => team.isPendingApproval).length;
    // Keep the original position as the row number so it stays stable while
    // searching or filtering.
    final visible = [
      for (var i = 0; i < teams.length; i++)
        if (_matchesQuery(teams[i]) && _matchesFilter(teams[i])) i,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            style: TextStyle(
              fontSize: 13,
              color: LavishColors.of(context).text,
            ),
            decoration: InputDecoration(
              hintText: l10n.teamList_searchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: LavishColors.of(context).chipLine,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(l10n.teamList_filterAll, _TeamFilter.all, teams.length),
              _chip(
                l10n.teamList_filterApproved,
                _TeamFilter.approved,
                approvedCount,
              ),
              _chip(
                l10n.teamList_filterPending,
                _TeamFilter.pending,
                pendingCount,
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    l10n.teamList_noMatch,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 88),
                  itemCount: visible.length,
                  itemBuilder: (context, row) => TeamListTile(
                    team: teams[visible[row]],
                    index: visible[row] + 1,
                    isLocked: widget.isLocked,
                    tournamentId: widget.tournamentId,
                    managementRouteBase: widget.managementRouteBase,
                  ),
                ),
        ),
      ],
    );
  }
}

class TeamListTile extends ConsumerWidget {
  final Team team;
  final int index;
  final bool isLocked;
  final String tournamentId;
  final String? managementRouteBase;

  const TeamListTile({
    super.key,
    required this.team,
    required this.index,
    required this.isLocked,
    required this.tournamentId,
    this.managementRouteBase,
  });

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: l10n.teamList_deleteTitle,
      content: l10n.teamList_deleteContent(team.name),
      confirmText: l10n.teamList_deleteConfirm,
    );
    if (confirm != true) return;
    try {
      await ref.read(teamServiceProvider(tournamentId)).deleteTeam(team.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.teamList_deleteError(e.toString())),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LavishColors.of(context);
    // Design 20: flat `.li` row, number box, names on two lines, pill, menu.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rowLine)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.soft(LavishTone.accent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: LavishColors.accent,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                if (team.members.isNotEmpty)
                  Text(
                    team.members.join(', '),
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: colors.muted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (team.isApproved) ...[
            const SizedBox(width: 8),
            LavishPill(l10n.teamList_approved, tone: LavishTone.ok),
          ],
          if (!isLocked)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: colors.faint),
              padding: EdgeInsets.zero,
              color: context.colors.bgCard,
              onSelected: (value) {
                if (value == 'edit') {
                  context.push(
                    '${managementRouteBase ?? '/admin/tournament/$tournamentId'}/teams/edit',
                    extra: team,
                  );
                } else if (value == 'delete') {
                  _confirmDelete(context, ref, l10n);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.teamList_edit)),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    l10n.teamList_deleteConfirm,
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
