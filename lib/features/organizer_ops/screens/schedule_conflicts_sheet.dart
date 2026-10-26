import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_conflicts.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Cảnh báo VĐV bị xếp trùng giờ hai nơi (OpenSpec `quan-ly-giai-web-parity`,
/// task 4.4; port popup "Cảnh báo trùng lịch thi đấu" của Web
/// `CourtScheduleBoard.tsx`): mỗi nhóm là một trận bị trùng người — sân, giờ,
/// hai bên — kèm từng dòng "VĐV "X" cũng đang có lịch đấu tại Y lúc Z".
///
/// Chỉ xem, không ghi gì nên không có trạng thái busy; mở qua [show] và tự
/// ẩn khi [groups] rỗng (gọi sau thao tác ghi mà không có xung đột thì không
/// mở gì).
class ScheduleConflictsSheet extends StatelessWidget {
  const ScheduleConflictsSheet({super.key, required this.groups});

  final List<ScheduleConflictGroup> groups;

  /// Mở sheet cảnh báo; [groups] rỗng thì không mở gì.
  static Future<void> show(
    BuildContext context, {
    required List<ScheduleConflictGroup> groups,
  }) {
    if (groups.isEmpty) return Future.value();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScheduleConflictsSheet(groups: groups),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return TournamentManageSheet(
      title: l10n.scheduleConflictsTitle(groups.length),
      actions: [
        FilledButton(
          key: const ValueKey('schedule-conflicts-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.scheduleConflictsDescription,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final group in groups) ...[
            _groupCard(context, l10n, group),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _groupCard(
    BuildContext context,
    AppLocalizations l10n,
    ScheduleConflictGroup group,
  ) {
    final colors = context.colors;
    final match = group.match;
    final courtName = scheduleCourtNameOf(match);
    final timeStr = match.scheduledTime == null
        ? '—'
        : scheduleConflictTimeText(match.scheduledTime!);
    final pair = '${_sideText(match, 1)} vs ${_sideText(match, 2)}';
    return Container(
      key: ValueKey('schedule-conflict-group-${match.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${courtName.isEmpty ? l10n.scheduleConflictOtherCourt : courtName} ($timeStr)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  pair,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          for (final conflict in group.conflicts) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.warning, width: 2),
                ),
              ),
              child: Text(
                l10n.scheduleConflictsRow(
                  conflict.competitorName,
                  conflict.otherCourtName.isEmpty
                      ? l10n.scheduleConflictOtherCourt
                      : conflict.otherCourtName,
                  conflict.otherTimeStr,
                ),
                style: TextStyle(fontSize: 12, color: colors.textPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Nhãn một bên trận: tên đội, hoặc nối tên các VĐV; trống thì "?" như nhãn
  /// cặp của màn vận hành.
  static String _sideText(MatchModel match, int side) {
    final label = matchSideLabel(match, side).trim();
    return label.isEmpty ? '?' : label;
  }
}
