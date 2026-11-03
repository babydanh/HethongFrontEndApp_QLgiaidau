import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
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
      bodyPadding: const EdgeInsets.only(bottom: 16),
      child: _buildBody(
        context,
        l10n,
        checklist: checklist,
        loadFailed: loadFailed,
        blocked: blocked,
        podium: podiumTeamNames(results?['awards']),
      ),
    );
  }

  /// Design screen 7: podium, prize lines, condition rows, then the big
  /// confirm button (grey with a red reason while a match is still live).
  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n, {
    required TournamentEndChecklist? checklist,
    required bool loadFailed,
    required bool blocked,
    required Map<int, String> podium,
  }) {
    final prizes = prizeLines(widget.tournament.prizeDescription);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultsPodium(names: podium),
        if (prizes.isNotEmpty) ...[
          LavishGroupHeader(l10n.lifecycleEndPrizesTitle),
          for (final line in prizes) LavishRow(title: line),
        ],
        LavishGroupHeader(l10n.lifecycleEndConditionsTitle),
        ..._buildConditions(l10n, checklist, loadFailed),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: LavishButton(
            buttonKey: const ValueKey('lifecycle-end-confirm'),
            label: l10n.lifecycleEndConfirm,
            busy: _busy,
            onPressed: (_busy || blocked) ? null : _askThenConfirm,
          ),
        ),
        if (checklist != null && checklist.hasLiveMatches)
          _RedLine(
            key: const ValueKey('lifecycle-end-blocked-reason'),
            text: l10n.lifecycleEndBlockedReason(checklist.liveMatches),
          ),
        if (_actionError case final error?) _RedLine(text: error),
      ],
    );
  }

  List<Widget> _buildConditions(
    AppLocalizations l10n,
    TournamentEndChecklist? checklist,
    bool loadFailed,
  ) {
    if (checklist == null) {
      if (loadFailed) {
        return [_RedLine(text: l10n.lifecycleEndLoadMatchesError)];
      }
      return [
        Padding(
          key: const ValueKey('lifecycle-end-loading'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      ];
    }
    final hasMatches = checklist.hasMatches;
    return [
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
        _EndDetailLine(
          key: ValueKey('lifecycle-end-live-${match.id}'),
          text: l10n.lifecycleEndLiveMatch(match.team1Name, match.team2Name),
        ),
      if (checklist.blockingDivisionNames.isNotEmpty)
        _EndDetailLine(
          key: const ValueKey('lifecycle-end-blocking-divisions'),
          text: checklist.blockingDivisionNames.join(', '),
        ),
      if (!hasMatches)
        Padding(
          key: const ValueKey('lifecycle-end-no-matches'),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Text(
            l10n.lifecycleEndNoMatches,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LavishColors.of(context).muted,
            ),
          ),
        ),
    ];
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

/// Team names of ranks 1 to 3 from the `awards` of the official results; a
/// slot without a team is simply absent.
Map<int, String> podiumTeamNames(Object? rawAwards) {
  final names = <int, String>{};
  if (rawAwards is! List) return names;
  for (final award in rawAwards.whereType<Map<dynamic, dynamic>>()) {
    final rank = (award['rank'] as num?)?.toInt() ?? 0;
    final participant = award['participant'];
    final team = participant is Map
        ? participant['teamName']?.toString()
        : null;
    if (rank >= 1 && rank <= 3 && team != null && team.trim().isNotEmpty) {
      names[rank] = team.trim();
    }
  }
  return names;
}

/// One condition row (design `.li` with a green check or a red cross box).
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
  Widget build(BuildContext context) => LavishRow(
    leading: LavishIconBox(
      tone: pass ? LavishTone.ok : LavishTone.bad,
      child: Icon(pass ? Icons.check_rounded : Icons.close_rounded, size: 18),
    ),
    title: label,
    trailing: [if (!pass) LavishPill(notPassedText, tone: LavishTone.bad)],
  );
}

/// Small red detail under a failed condition (a live match, its division).
class _EndDetailLine extends StatelessWidget {
  const _EndDetailLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(59, 6, 14, 0),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: LavishColors.bad,
      ),
    ),
  );
}

/// Centered red reason line under the confirm button.
class _RedLine extends StatelessWidget {
  const _RedLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: LavishColors.bad,
      ),
    ),
  );
}

/// The prize description is stored as rich text; the sheet shows one row per
/// line (block ends and `<br>` split lines, other tags are dropped).
List<String> prizeLines(String? html) => (html ?? '')
    .replaceAll(
      RegExp(r'<\s*(br|/p|/li|/div|/h[1-6])[^>]*>', caseSensitive: false),
      '\n',
    )
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .split('\n')
    .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
    .where((line) => line.isNotEmpty)
    .toList(growable: false);

/// Design `.pod`: silver, gold, bronze steps from left to right, bottom
/// aligned, 96 / 78 / 64 tall.
class _ResultsPodium extends StatelessWidget {
  const _ResultsPodium({required this.names});

  final Map<int, String> names;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final rank in const [2, 1, 3]) ...[
            if (rank != 2) const SizedBox(width: 8),
            Expanded(
              child: _PodiumSlot(rank: rank, name: names[rank]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({required this.rank, required this.name});

  final int rank;
  final String? name;

  static const _medal = {1: '🥇', 2: '🥈', 3: '🥉'};
  static const _fill = {
    1: Color(0xFFFEF0C7),
    2: Color(0xFFEAECF0),
    3: Color(0xFFFDEADD),
  };
  // Label colours follow the medal: gold and bronze warm, silver neutral slate
  // (each keeps at least 4.5:1 contrast on its fill).
  static const _ink = {
    1: Color(0xFF93370D),
    2: Color(0xFF344054),
    3: Color(0xFFB54708),
  };
  static const _height = {1: 96.0, 2: 78.0, 3: 64.0};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: ValueKey('lifecycle-end-podium-$rank'),
      constraints: BoxConstraints(minHeight: _height[rank] ?? 64),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
        color: _fill[rank],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_medal[rank] ?? '', style: const TextStyle(fontSize: 13)),
          Text(
            name ?? l10n.lifecycleEndPodiumEmpty,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: _ink[rank],
            ),
          ),
        ],
      ),
    );
  }
}
