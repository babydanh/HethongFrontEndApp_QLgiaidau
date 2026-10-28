import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Số liệu checklist kết thúc giải, đếm cùng luật với Web
/// `handleOpenEndModal` (useManageState.ts): chỉ tính trận có thật (bỏ trận
/// BYE), trận LIVE (`isLive`: LIVE/ONGOING/IN_PROGRESS) chặn nút kết thúc,
/// trận xong dùng `isCompleted` của App (bao cả WALKOVER/RETIRED...).
class TournamentEndChecklist {
  const TournamentEndChecklist({
    required this.totalMatches,
    required this.completedMatches,
    required this.liveMatches,
    required this.liveMatchList,
    required this.blockingDivisionNames,
  });

  factory TournamentEndChecklist.of(
    List<MatchModel> matches,
    List<TournamentDivision> divisions,
  ) {
    final playable = matches
        .where((match) => !match.isByeMatch)
        .toList(growable: false);
    final liveMatchList = playable
        .where((match) => match.isLive)
        .toList(growable: false);
    String? divisionNameOf(MatchModel match) {
      for (final division in divisions) {
        if (division.id == match.divisionId) return division.name;
      }
      return null;
    }

    // Tên hạng mục còn trận LIVE (bỏ tên rỗng, không lặp) — như Web
    // `blockingDivisionNames`.
    final blockingDivisionNames = liveMatchList
        .map(divisionNameOf)
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return TournamentEndChecklist(
      totalMatches: playable.length,
      completedMatches: playable.where((match) => match.isCompleted).length,
      liveMatches: liveMatchList.length,
      liveMatchList: liveMatchList,
      blockingDivisionNames: blockingDivisionNames,
    );
  }

  /// Tổng trận có thật (không tính BYE).
  final int totalMatches;

  /// Trận đã hoàn tất.
  final int completedMatches;

  /// Số trận LIVE.
  final int liveMatches;

  /// Danh sách trận LIVE để liệt kê trong sheet.
  final List<MatchModel> liveMatchList;

  /// Tên các hạng mục còn trận LIVE.
  final List<String> blockingDivisionNames;

  bool get hasMatches => totalMatches > 0;
  bool get hasLiveMatches => liveMatches > 0;
  bool get allCompleted => totalMatches > 0 && completedMatches == totalMatches;
}

/// Sheet kết thúc giải checklist (OpenSpec `quan-ly-giai-web-parity`
/// task 1.2, đối chiếu Web TournamentStepper "endChecklist"): hiện
/// "trận đã hoàn tất X/Y" và "trận đang diễn ra còn lại", liệt kê từng trận
/// LIVE kèm hạng mục chặn; còn trận LIVE thì nút kết thúc bị khoá (Web cũng
/// chỉ chặn vì trận LIVE, trận chưa xong thì vẫn được kết thúc). Xác nhận gọi
/// `POST /tournaments/:id/complete` sau một hộp xác nhận nêu hậu quả; lỗi
/// server hiển thị nguyên văn trong sheet. Đầu sheet có bục podium hạng 1-3
/// (từ `GET /tournaments/:id/results`) và mô tả giải thưởng. Phân quyền do backend chốt — organizer/co-organizer cũng mở được.
///
/// Stateful và bọc khung [TournamentManageSheet] trong `build` để `busy` đổi
/// được bên trong sheet (giữ pattern `LifecycleOpeningSheet`).
class LifecycleEndSheet extends ConsumerStatefulWidget {
  const LifecycleEndSheet({super.key, required this.tournament});

  final Tournament tournament;

  /// Mở sheet kết thúc giải. Trả về `true` khi giải đã kết thúc thành công.
  ///
  /// Mở bằng `showModalBottomSheet` trực tiếp (thay vì helper của khung) vì
  /// `builder` phải trả sheet stateful này — khung [TournamentManageSheet]
  /// nằm trong `build` của state để nhận `busy` động. Drag tắt từ đầu như
  /// sheet khai mạc: tham số drag của route chốt lúc mở không đổi được sau
  /// này mà sheet có thể vào trạng thái busy ngay khi bấm kết thúc.
  static Future<bool?> show(
    BuildContext context, {
    required Tournament tournament,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => LifecycleEndSheet(tournament: tournament),
  );

  @override
  ConsumerState<LifecycleEndSheet> createState() => _LifecycleEndSheetState();
}

class _LifecycleEndSheetState extends ConsumerState<LifecycleEndSheet> {
  /// Đang gọi `complete-tournament`.
  bool _busy = false;

  String? _actionError;

  /// The confirm button never completes on its own: the dialog states what
  /// the tournament becomes first.
  Future<void> _askThenConfirm() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.lifecycleEndConfirmDialogTitle,
      message: l10n.lifecycleEndConfirmDialogMessage,
      confirmLabel: l10n.lifecycleEndConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _confirm();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .completeTournament(widget.tournament.id);
      ref.invalidate(tournamentProvider(widget.tournament.id));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _actionError =
              _serverMessage(error) ?? AppLocalizations.of(context)!.endError;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Trận để đếm checklist; null = stream chưa trả dữ liệu (chưa an toàn để
    // mở nút kết thúc) hoặc tải lỗi (hiện dòng lỗi).
    final matchesAsync = ref.watch(matchesProvider(widget.tournament.id));
    final matches = matchesAsync.asData?.value;
    final loadFailed = matches == null && matchesAsync.hasError;
    final checklist = matches == null
        ? null
        : TournamentEndChecklist.of(matches, widget.tournament.divisions);
    final blocked = checklist?.hasLiveMatches ?? true;
    // A failed or pending results read just leaves the podium slots empty.
    final results = ref
        .watch(
          tournamentResultProvider((
            tournamentId: widget.tournament.id,
            divisionId: null,
          )),
        )
        .asData
        ?.value;
    return TournamentManageSheet(
      title: l10n.lifecycleEndTitle,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('lifecycle-end-confirm'),
          onPressed: (_busy || blocked) ? null : _askThenConfirm,
          child: Text(l10n.lifecycleEndConfirm),
        ),
        TextButton(
          key: const ValueKey('lifecycle-end-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: _buildBody(
        context,
        l10n,
        checklist: checklist,
        loadFailed: loadFailed,
        podium: podiumTeamNames(results?['awards']),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n, {
    required TournamentEndChecklist? checklist,
    required bool loadFailed,
    required Map<int, String> podium,
  }) {
    final hasMatches = checklist?.hasMatches ?? false;
    final prize = plainPrizeText(widget.tournament.prizeDescription);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultsPodium(names: podium),
        if (prize.isNotEmpty) _PrizeBlock(text: prize),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.lifecycleEndConditionsTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        _EndWarning(text: l10n.lifecycleEndWarning),
        if (checklist != null) ...[
          _EndCheckRow(
            key: const ValueKey('lifecycle-end-check-matches'),
            label: l10n.lifecycleEndCheckMatches(
              checklist.completedMatches,
              checklist.totalMatches,
            ),
            // Không có trận nào thì coi như đạt (Web: vẫn được kết thúc).
            pass: !hasMatches || checklist.allCompleted,
            notPassedText: l10n.lifecycleEndNotPassed,
          ),
          _EndCheckRow(
            key: const ValueKey('lifecycle-end-check-live'),
            label: l10n.lifecycleEndCheckLive(checklist.liveMatches),
            pass: !hasMatches || !checklist.hasLiveMatches,
            notPassedText: l10n.lifecycleEndNotPassed,
          ),
          for (final match in checklist.liveMatchList)
            Padding(
              key: ValueKey('lifecycle-end-live-${match.id}'),
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                l10n.lifecycleEndLiveMatch(match.team1Name, match.team2Name),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (checklist.blockingDivisionNames.isNotEmpty)
            Padding(
              key: const ValueKey('lifecycle-end-blocking-divisions'),
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                checklist.blockingDivisionNames.join(', '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (checklist.hasLiveMatches)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.lifecycleEndBlockedReason(checklist.liveMatches),
                key: const ValueKey('lifecycle-end-blocked-reason'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (!hasMatches)
            Container(
              key: const ValueKey('lifecycle-end-no-matches'),
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.bgSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Text(
                l10n.lifecycleEndNoMatches,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
        ] else if (loadFailed)
          _EndWarning(text: l10n.lifecycleEndLoadMatchesError, error: true)
        else
          Padding(
            key: const ValueKey('lifecycle-end-loading'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.lifecycleEndLoadingMatches)),
              ],
            ),
          ),
        if (_actionError case final error?) ...[
          const SizedBox(height: 12),
          _EndError(text: error),
        ],
      ],
    );
  }
}

/// Thông báo do máy chủ trả về (trường `message`), nếu có.
String? _serverMessage(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;
  final message = data['message'];
  return message is String && message.trim().isNotEmpty ? message : null;
}

/// Dòng cảnh báo vàng trên đầu sheet (đỏ khi [error]).
class _EndWarning extends StatelessWidget {
  const _EndWarning({required this.text, this.error = false});

  final String text;

  /// true: cảnh báo lỗi (đỏ) thay vì nhắc nhở (vàng).
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = error ? colors.error : colors.warning;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: error ? colors.error : colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một dòng checklist (đạt/không đạt) — như hàng check của Web.
class _EndCheckRow extends StatelessWidget {
  const _EndCheckRow({
    super.key,
    required this.label,
    required this.pass,
    required this.notPassedText,
  });

  final String label;
  final bool pass;
  final String notPassedText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = pass ? colors.success : colors.error;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pass
              ? colors.success.withValues(alpha: 0.35)
              : colors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            pass ? Icons.check_rounded : Icons.close_rounded,
            size: 18,
            color: tone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: pass ? colors.textSecondary : colors.textPrimary,
                fontWeight: FontWeight.w700,
                decoration: pass ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (!pass)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.error.withValues(alpha: 0.35)),
              ),
              child: Text(
                notPassedText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lỗi hành động hiển thị trong sheet (nguyên văn message server nếu có).
class _EndError extends StatelessWidget {
  const _EndError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: TextStyle(color: colors.error)),
    );
  }
}

/// Team names of ranks 1 to 3 from the `awards` of the official results; a
/// slot without a team is simply absent.
Map<int, String> podiumTeamNames(Object? rawAwards) {
  final names = <int, String>{};
  if (rawAwards is! List) return names;
  for (final award in rawAwards.whereType<Map<dynamic, dynamic>>()) {
    final rank = (award['rank'] as num?)?.toInt() ?? 0;
    final participant = award['participant'];
    final team = participant is Map ? participant['teamName']?.toString() : null;
    if (rank >= 1 && rank <= 3 && team != null && team.trim().isNotEmpty) {
      names[rank] = team.trim();
    }
  }
  return names;
}

/// The prize description is stored as rich text; the sheet shows it flat.
String plainPrizeText(String? html) => (html ?? '')
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Podium of the three first ranks: silver, gold, bronze from left to right.
class _ResultsPodium extends StatelessWidget {
  const _ResultsPodium({required this.names});

  final Map<int, String> names;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final rank in const [2, 1, 3])
            Expanded(
              child: _PodiumSlot(rank: rank, name: names[rank]),
            ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({required this.rank, required this.name});

  final int rank;
  final String? name;

  static const _medal = {
    1: Color(0xFFF5B301),
    2: Color(0xFF9AA5B1),
    3: Color(0xFFCD7F32),
  };
  static const _stepHeight = {1: 56.0, 2: 40.0, 3: 28.0};

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final tone = _medal[rank] ?? colors.textMuted;
    return Column(
      key: ValueKey('lifecycle-end-podium-$rank'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.emoji_events_rounded, color: tone, size: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            name ?? l10n.lifecycleEndPodiumEmpty,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: name == null ? colors.textMuted : colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          height: _stepHeight[rank],
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.18),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: tone.withValues(alpha: 0.5)),
          ),
          child: Text(
            '$rank',
            style: TextStyle(color: tone, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// Read-only prize description (edited in the information tab).
class _PrizeBlock extends StatelessWidget {
  const _PrizeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.lifecycleEndPrizesTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
