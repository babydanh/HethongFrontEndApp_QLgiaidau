import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CrossTableView extends ConsumerWidget {
  final List<MatchModel> matches;
  final String tournamentId;

  const CrossTableView({
    super.key,
    required this.matches,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(standingsProvider(tournamentId));

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu đội thi đấu'));
        }

        // Tạo danh sách các đội từ standings để giữ thứ tự hiện tại (hoặc có thể sort theo tên)
        final teams = standings.map((s) => Team(id: s.id, name: s.teamName, createdAt: DateTime.now())).toList();
        
        // Tạo bảng tra cứu tỉ số
        final scores = <String, String>{};
        for (final match in matches) {
          if (match.status == 'completed' || match.status == 'walkover') {
             // team1 vs team2
             scores['${match.team1Id}_${match.team2Id}'] = '${match.score1} - ${match.score2}';
             // team2 vs team1
             scores['${match.team2Id}_${match.team1Id}'] = '${match.score2} - ${match.score1}';
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.primary.withValues(alpha: 0.1)),
              columnSpacing: 24,
              border: TableBorder.all(
                color: context.colors.border.withValues(alpha: 0.5),
                width: 1,
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Đội',
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                    softWrap: false,
                  ),
                ),
                ...teams.map((t) => DataColumn(
                  label: Container(
                    constraints: const BoxConstraints(minWidth: 80),
                    alignment: Alignment.center,
                    child: Text(
                      t.name,
                      style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )),
              ],
              rows: teams.map((rowTeam) {
                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          rowTeam.name,
                          style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    ...teams.map((colTeam) {
                      if (rowTeam.id == colTeam.id) {
                        return DataCell(
                          Container(
                            color: Colors.grey.withValues(alpha: 0.2),
                            alignment: Alignment.center,
                            child: Icon(Icons.close, color: context.colors.textMuted, size: 16),
                          ),
                        );
                      }
                      
                      final score = scores['${rowTeam.id}_${colTeam.id}'];
                      return DataCell(
                        Center(
                          child: Text(
                            score ?? '-',
                            style: TextStyle(
                              fontWeight: score != null ? FontWeight.bold : FontWeight.normal,
                              color: score != null ? AppTheme.primary : context.colors.textMuted,
                            ),
                            softWrap: false,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }
}
