import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/repositories/pair_move_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/pair_move_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Một VĐV đang ở một ô của một hồ sơ (cặp hoặc VĐV chờ ghép).
class _Member {
  const _Member({
    required this.participantId,
    required this.slot,
    required this.name,
    required this.key,
  });

  final String participantId;
  final int slot;
  final String name;

  /// Khoá thành viên gửi làm `expected` / `expectedKey` (lệch thì Backend 409).
  final String key;
}

/// Một hồ sơ trong danh sách: tối đa hai ô.
class _Row {
  const _Row(this.participant, this.members);

  final OrganizerOpsParticipant participant;

  /// Thành viên theo ô (chỉ các ô có người).
  final List<_Member> members;

  String get id => participant.id;
  bool get isPair => members.length == 2;
  _Member? memberAt(int slot) {
    for (final member in members) {
      if (member.slot == slot) return member;
    }
    return null;
  }
}

/// Đổi VĐV giữa các cặp của một nội dung đôi (đối chiếu Web `PairDragProvider`):
/// giữ một VĐV rồi kéo thả vào ô của cặp khác, ô trống hoặc khay chờ ghép; hoặc
/// bấm ⋮ trên VĐV để "Chuyển sang…" (cuộn dài thì chọn đích trong danh sách,
/// thay cho kéo thả) và "Gỡ khỏi cặp".
///
/// Danh sách tự tải (`getOrganizerParticipants` của nội dung này) và tải lại
/// sau mỗi thao tác, kể cả khi Backend trả 409 vì dữ liệu đã đổi.
class PairMoveSheet extends ConsumerStatefulWidget {
  const PairMoveSheet({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    this.onRefresh,
  });

  final String tournamentId;
  final String divisionId;

  /// Gọi sau khi đổi/gỡ thành công để màn cha tải lại dữ liệu.
  final Future<void> Function()? onRefresh;

  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
    required String divisionId,
    Future<void> Function()? onRefresh,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => PairMoveSheet(
      tournamentId: tournamentId,
      divisionId: divisionId,
      onRefresh: onRefresh,
    ),
  );

  @override
  ConsumerState<PairMoveSheet> createState() => _PairMoveSheetState();
}

class _PairMoveSheetState extends ConsumerState<PairMoveSheet> {
  /// Backend không cho đổi VĐV ở hồ sơ đã rút / bị từ chối / bị loại.
  static const _inactiveStatuses = {'WITHDRAWN', 'REJECTED', 'KICKED'};

  List<_Row> _rows = const [];
  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await ref
          .read(tournamentRepositoryProvider)
          .getOrganizerParticipants(
            widget.tournamentId,
            divisionId: widget.divisionId,
          );
      if (!mounted) return;
      setState(() {
        _rows = _buildRows(all);
        _loadFailed = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  List<_Row> _buildRows(List<OrganizerOpsParticipant> all) => [
    for (final participant in all)
      if (participant.divisionId == widget.divisionId &&
          !_inactiveStatuses.contains(participant.teamStatus.toUpperCase()))
        _Row(participant, _membersOf(participant)),
  ].where((row) => row.members.isNotEmpty).toList(growable: false);

  /// Khoá khách giống Web `expectedKey`: tên + email ở `player{slot}Email`.
  List<_Member> _membersOf(OrganizerOpsParticipant participant) => [
    for (final player in participant.players)
      if (player.slot == 1 || player.slot == 2)
        _Member(
          participantId: participant.id,
          slot: player.slot,
          name: player.fullName,
          key: pairMemberKey(
            userId: player.userId,
            fullName: player.fullName,
            email: participant.customResponses['player${player.slot}Email']
                ?.toString(),
          ),
        ),
  ];

  _Row? _rowOf(String participantId) {
    for (final row in _rows) {
      if (row.id == participantId) return row;
    }
    return null;
  }

  /// Bộ lọc nhanh phía App; Backend vẫn kiểm đầy đủ.
  bool _canDrop(_Member source, _Row target, int slot) {
    if (_busy) return false;
    if (target.id == source.participantId) {
      // Cùng hồ sơ: chỉ đổi chỗ hai người của một cặp.
      return target.isPair && target.memberAt(slot) != null && slot != source.slot;
    }
    return true;
  }

  bool _canSplit(_Member source) => _rowOf(source.participantId)?.isPair ?? false;

  Future<void> _move(_Member source, PairMoveTarget target) {
    final targetRow = target.tray ? null : _rowOf(target.participantId!);
    if (!target.tray && targetRow == null) return Future.value();
    return _run(
      () => ref
          .read(pairMoveRepositoryProvider)
          .movePairMember(
            widget.tournamentId,
            PairMoveRequest(
              divisionId: widget.divisionId,
              sourceParticipantId: source.participantId,
              sourceSlot: source.slot,
              target: target,
              expectedSource: source.key,
              expectedTarget: targetRow?.memberAt(target.slot!)?.key,
            ),
          ),
      (l10n) => l10n.pairMoveMoved,
    );
  }

  Future<void> _confirmRemove(_Member member) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.pairMoveRemoveConfirmTitle,
      message: l10n.pairMoveRemoveConfirmMessage(member.name),
      confirmLabel: l10n.pairMoveRemoveConfirmAction,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => ref
          .read(pairMoveRepositoryProvider)
          .removePairMember(
            widget.tournamentId,
            participantId: member.participantId,
            slot: member.slot,
            expectedKey: member.key,
          ),
      (l10n) => l10n.pairMoveRemoved,
    );
  }

  /// Chạy một lệnh ghi một lần (khoá `_busy` chống bấm đúp). Thành công: tải
  /// lại + báo cha. 409: tải lại và báo dữ liệu đã đổi. Lỗi khác: báo lỗi
  /// server hoặc lỗi chung (mạng/timeout).
  Future<void> _run(
    Future<Object?> Function() call,
    String Function(AppLocalizations) successText,
  ) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    void say(String text) => messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
    setState(() => _busy = true);
    var succeeded = false;
    try {
      await call();
      succeeded = true;
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 409) {
        await _load();
        say(l10n.pairMoveConflict);
      } else {
        say(tournamentSheetServerMessage(error) ?? l10n.pairMoveFailed);
      }
    }
    if (succeeded) {
      await _load();
      await widget.onRefresh?.call();
      say(successText(l10n));
    }
    if (mounted) setState(() => _busy = false);
  }

  /// Phương án thay cho kéo thả: chọn ô đích trong danh sách.
  Future<void> _pickTargetAndMove(_Member source) async {
    if (_busy) return;
    final target = await showModalBottomSheet<PairMoveTarget>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TargetPicker(
        source: source,
        rows: _rows,
        canSplit: _canSplit(source),
      ),
    );
    if (target == null || !mounted) return;
    await _move(source, target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    return TournamentManageSheet(
      title: l10n.pairMoveSheetTitle,
      busy: _busy,
      footer: _buildTray(l10n, c),
      child: _buildBody(l10n, c),
    );
  }

  Widget _buildBody(AppLocalizations l10n, LavishColors c) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadFailed && _rows.isEmpty) {
      return Column(
        key: const ValueKey('pair-move-load-error'),
        children: [
          Text(
            l10n.pairMoveLoadFailed,
            style: const TextStyle(color: LavishColors.bad, fontSize: 13),
          ),
          TextButton(
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            child: Text(l10n.infoRetry),
          ),
        ],
      );
    }
    if (_rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.pairMoveEmpty,
          key: const ValueKey('pair-move-empty'),
          textAlign: TextAlign.center,
          style: TextStyle(color: c.muted, fontSize: 13),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.pairMoveHint, style: TextStyle(color: c.muted, fontSize: 12)),
        const SizedBox(height: 12),
        for (var index = 0; index < _rows.length; index++)
          _buildRow(_rows[index], index + 1, l10n, c),
      ],
    );
  }

  /// Khay chờ ghép (cố định dưới sheet để luôn với tới được khi danh sách dài).
  Widget _buildTray(AppLocalizations l10n, LavishColors c) {
    return DragTarget<_Member>(
      key: const ValueKey('pair-move-tray'),
      onWillAcceptWithDetails: (details) => !_busy && _canSplit(details.data),
      onAcceptWithDetails: (details) =>
          _move(details.data, const PairMoveTarget.tray()),
      builder: (context, candidates, _) {
        final hot = candidates.isNotEmpty;
        return Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hot ? c.soft(LavishTone.accent) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hot ? LavishColors.accent : c.line,
              width: hot ? 2 : 1,
            ),
          ),
          child: Text(
            l10n.pairMoveTrayLabel,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontSize: 12.5),
          ),
        );
      },
    );
  }

  Widget _buildRow(_Row row, int number, AppLocalizations l10n, LavishColors c) {
    return Container(
      key: ValueKey('pair-move-row-${row.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.pairMovePairLabel(number),
                style: TextStyle(
                  color: c.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!row.isPair) ...[
                const SizedBox(width: 8),
                LavishPill(l10n.pairMoveWaitingLabel, tone: LavishTone.warn),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildSlot(row, 1, l10n, c)),
              const SizedBox(width: 8),
              Expanded(child: _buildSlot(row, 2, l10n, c)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(_Row row, int slot, AppLocalizations l10n, LavishColors c) {
    final member = row.memberAt(slot);
    return DragTarget<_Member>(
      onWillAcceptWithDetails: (details) => _canDrop(details.data, row, slot),
      onAcceptWithDetails: (details) =>
          _move(details.data, PairMoveTarget.slot(row.id, slot)),
      builder: (context, candidates, _) {
        final hot = candidates.isNotEmpty;
        final border = Border.all(
          color: hot ? LavishColors.accent : c.line,
          width: hot ? 2 : 1,
        );
        if (member == null) {
          return Container(
            key: ValueKey('pair-move-empty-${row.id}-$slot'),
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: border,
            ),
            child: Text(
              l10n.pairMoveEmptySlot,
              style: TextStyle(color: c.faint, fontSize: 12.5),
            ),
          );
        }
        final chip = _buildMemberChip(row, member, border, l10n, c);
        return LongPressDraggable<_Member>(
          key: ValueKey('pair-move-member-${row.id}-$slot'),
          data: member,
          maxSimultaneousDrags: _busy ? 0 : 1,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: 160, child: chip),
          ),
          childWhenDragging: Opacity(opacity: 0.4, child: chip),
          child: chip,
        );
      },
    );
  }

  Widget _buildMemberChip(
    _Row row,
    _Member member,
    BoxBorder border,
    AppLocalizations l10n,
    LavishColors c,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: c.soft(LavishTone.accent),
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              member.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuButton<String>(
            key: ValueKey('pair-move-menu-${member.participantId}-${member.slot}'),
            tooltip: l10n.pairMoveMenuMoveTo,
            enabled: !_busy,
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert_rounded, size: 20, color: c.muted),
            onSelected: (value) => value == 'remove'
                ? _confirmRemove(member)
                : _pickTargetAndMove(member),
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'move',
                child: Text(l10n.pairMoveMenuMoveTo),
              ),
              if (row.isPair)
                PopupMenuItem<String>(
                  value: 'remove',
                  child: Text(l10n.pairMoveMenuRemove),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Danh sách đích để chuyển [source] (thay cho kéo thả): ô của cặp khác, ô
/// trống của VĐV chờ ghép, đổi chỗ trong cùng cặp, hoặc khay chờ ghép.
class _TargetPicker extends StatelessWidget {
  const _TargetPicker({
    required this.source,
    required this.rows,
    required this.canSplit,
  });

  final _Member source;
  final List<_Row> rows;
  final bool canSplit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = <Widget>[];
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final number = index + 1;
      for (final slot in const [1, 2]) {
        if (row.id == source.participantId && slot == source.slot) continue;
        final occupant = row.memberAt(slot);
        // Ô trống chỉ có ở hồ sơ một người, và không phải hồ sơ của chính nguồn.
        if (occupant == null && (row.isPair || row.id == source.participantId)) {
          continue;
        }
        tiles.add(
          ListTile(
            key: ValueKey('pair-move-pick-${row.id}-$slot'),
            title: Text(
              occupant == null
                  ? l10n.pairMovePickerEmpty(number)
                  : l10n.pairMovePickerSwap(number, occupant.name),
            ),
            onTap: () =>
                Navigator.pop(context, PairMoveTarget.slot(row.id, slot)),
          ),
        );
      }
    }
    if (canSplit) {
      tiles.add(
        ListTile(
          key: const ValueKey('pair-move-pick-tray'),
          title: Text(l10n.pairMovePickerTray),
          onTap: () => Navigator.pop(context, const PairMoveTarget.tray()),
        ),
      );
    }
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              l10n.pairMovePickerTitle(source.name),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(child: ListView(shrinkWrap: true, children: tiles)),
        ],
      ),
    );
  }
}
