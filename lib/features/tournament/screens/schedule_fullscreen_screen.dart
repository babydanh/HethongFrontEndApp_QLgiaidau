import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_spacing.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

/// Không gian toàn màn hình để xếp lịch: xoay ngang, không còn banner/tab của
/// hub, và là chỗ chứa các thao tác hàng loạt.
///
/// Tự theo dõi danh sách trận của nội dung đang chọn, nên sau khi ghi lịch (màn
/// gọi invalidate provider) lưới ở đây tự cập nhật.
class ScheduleFullscreenScreen extends ConsumerStatefulWidget {
  const ScheduleFullscreenScreen({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    required this.scheduleSettings,
    required this.divisions,
    required this.onDivisionSelected,
    this.onScheduleDrop,
    this.onBulkSchedule,
    this.onTapMatch,
  });

  final String tournamentId;
  final String? divisionId;
  final Map<String, dynamic> scheduleSettings;
  final List<ScheduleDivision> divisions;

  /// Đổi nội dung: màn gọi đổi nội dung của cả tab rồi màn này theo lại.
  final ValueChanged<String>? onDivisionSelected;

  /// Ghi lịch khi thả trận; màn gọi lo việc gọi API và tải lại.
  final void Function(
    String matchId,
    String courtId,
    String courtName,
    DateTime scheduledAt,
  )?
  onScheduleDrop;

  /// Xếp nhiều trận vào vùng ô đã chọn; màn gọi lo việc gọi API.
  final void Function(
    List<({String courtId, String courtName, DateTime at})> cells,
    List<MatchModel> waiting,
  )?
  onBulkSchedule;

  final ValueChanged<String>? onTapMatch;

  @override
  ConsumerState<ScheduleFullscreenScreen> createState() =>
      _ScheduleFullscreenScreenState();
}

class _ScheduleFullscreenScreenState
    extends ConsumerState<ScheduleFullscreenScreen> {
  @override
  void initState() {
    super.initState();
    // Xoay ngang để thấy nhiều sân cùng lúc, như bảng lịch của web.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Rời không gian này thì trả màn hình về dọc.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(
      matchesWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
      )),
    );

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('schedule-fullscreen-close'),
          icon: Icon(Icons.close_fullscreen_rounded, color: colors.textPrimary),
          tooltip: l10n.tournamentManagementTabSettings,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.tabSchedule,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.opsLoadFailed,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.error),
            ),
          ),
        ),
        data: (matches) => SingleChildScrollView(
          child: TournamentScheduleCourtGrid(
            tournamentId: widget.tournamentId,
            matches: matches,
            scheduleSettings: widget.scheduleSettings,
            divisions: widget.divisions,
            selectedDivisionId: widget.divisionId,
            onDivisionSelected: widget.onDivisionSelected,
            onScheduleDrop: widget.onScheduleDrop,
            onBulkSchedule: widget.onBulkSchedule,
            onTapMatch: widget.onTapMatch,
          ),
        ),
      ),
    );
  }
}
