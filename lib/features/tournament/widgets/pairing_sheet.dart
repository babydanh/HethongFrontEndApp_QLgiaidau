import 'dart:math';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/pairing.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/pairing_strategy_picker.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sheet ghép cặp nội dung đôi (OpenSpec `quan-ly-giai-web-parity` task
/// 3.6/3.7, đối chiếu Web `PairingParticipantsModal` + modal ghép tự động
/// của `RegistrationTab`): 2 tab.
///
/// - Thủ công: danh sách VĐV chờ của hạng mục (tìm kiếm không dấu), chọn 2
///   người liên tiếp hoặc long-press kéo một người thả lên người khác để thành
///   cặp, nút xáo trộn Fisher-Yates, đặt tên từng cặp, tối đa 24 VĐV, gửi một
///   lần `POST /tournaments/:id/pairing/batch`.
/// - Tự động: 3 radio RANDOM / ELO_BALANCED / SAME_LEVEL →
///   `POST /tournaments/:id/pairing/generate` (đích là hạng mục đang mở).
class PairingSheet extends ConsumerStatefulWidget {
  const PairingSheet({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    required this.divisionName,
    this.onRefresh,
  });

  final String tournamentId;

  /// Hạng mục đang mở sheet: danh sách chờ lọc theo hạng mục này (Web lọc
  /// client-side theo `pairingDivisionId`) và ghép tự động chỉ chạy trong nó.
  final String divisionId;

  /// Tên hạng mục hiển thị trong mô tả.
  final String divisionName;

  /// Gọi sau khi ghép xong để màn cha tải lại dữ liệu.
  final Future<void> Function()? onRefresh;

  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
    required String divisionId,
    required String divisionName,
    Future<void> Function()? onRefresh,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => PairingSheet(
      tournamentId: tournamentId,
      divisionId: divisionId,
      divisionName: divisionName,
      onRefresh: onRefresh,
    ),
  );

  @override
  ConsumerState<PairingSheet> createState() => _PairingSheetState();
}

class _PairingSheetState extends ConsumerState<PairingSheet> {
  /// Web `MAX_PAIRING_SELECTION`: tối đa 24 VĐV mỗi lần ghép (12 cặp).
  static const _maxSelection = 24;

  bool _manualTab = true;
  final _searchController = TextEditingController();
  late Future<List<PairingCandidate>> _candidatesFuture = _load();
  PairingStrategy _strategy = PairingStrategy.random;

  /// VĐV đã chọn theo thứ tự bấm/kéo: cứ 2 người liên tiếp là một cặp,
  /// người lẻ cuối cùng tiếp tục chờ (giống `selectedIds` của Web).
  final List<String> _selectedIds = <String>[];

  /// Tên cặp theo khoá `p1|p2` (giống `pairKeyOf` của Web); cặp không còn
  /// tồn tại thì tên bị bỏ.
  final Map<String, String> _pairNames = <String, String>{};

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PairingCandidate>> _load() => ref
      .read(tournamentManagementRepositoryProvider)
      .getPairingParticipants(widget.tournamentId);

  void _retry() => setState(() => _candidatesFuture = _load());

  /// Tìm kiếm không dấu như Web: bỏ dấu tiếng Việt (kể cả đ→d), chữ thường
  /// (`.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd')`).
  static final Map<String, String> _foldMap = _buildFoldMap();

  static Map<String, String> _buildFoldMap() {
    const baseLetters = {
      'a': 'àáảãạăằắẳẵặâầấẩẫậäå',
      'e': 'èéẻẽẹêềếểễệë',
      'i': 'ìíỉĩịîï',
      'o': 'òóỏõọôồốổỗộơờớởỡợöø',
      'u': 'ùúủũụưừứửữựûü',
      'y': 'ỳýỷỹỵÿ',
      'd': 'đ',
    };
    return {
      for (final entry in baseLetters.entries)
        for (final rune in entry.value.runes)
          String.fromCharCode(rune): entry.key,
    };
  }

  static String _normalizeSearch(String value) {
    final buffer = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      // Dấu tổ hợp U+0300..U+036F bị bỏ, tương ứng web NFD strip.
      if (rune >= 0x0300 && rune <= 0x036F) continue;
      final char = String.fromCharCode(rune);
      buffer.write(_foldMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// Các cặp của lựa chọn hiện tại: 2 người liên tiếp là một cặp
  /// (port `pairsOf` của Web).
  List<(String, String)> get _pairs {
    final pairs = <(String, String)>[];
    for (var index = 0; index + 1 < _selectedIds.length; index += 2) {
      pairs.add((_selectedIds[index], _selectedIds[index + 1]));
    }
    return pairs;
  }

  bool get _hasOddWaiting => _selectedIds.length % 2 == 1;

  static String _pairKey((String, String) pair) => '${pair.$1}|${pair.$2}';

  void _applySelection(List<String> next) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(next);
      final liveKeys = _pairs.map(_pairKey).toSet();
      _pairNames.removeWhere((key, _) => !liveKeys.contains(key));
    });
  }

  /// Chọn/bỏ chọn một VĐV. Vượt giới hạn 24: từ chối chọn và thông báo
  /// (spec `Vượt giới hạn chọn`; Web chỉ vô hiệu hoá dòng).
  void _toggle(PairingCandidate candidate) {
    if (_busy) return;
    if (_selectedIds.contains(candidate.id)) {
      _applySelection(
        _selectedIds.where((id) => id != candidate.id).toList(growable: false),
      );
      return;
    }
    if (_selectedIds.length >= _maxSelection) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pairingSelectionLimit),
          ),
        );
      return;
    }
    _applySelection([..._selectedIds, candidate.id]);
  }

  /// Thả VĐV [dragged] lên VĐV [target]: hai người thành một cặp ở cuối danh
  /// sách; bạn cũ của mỗi người trở lại hàng chờ, người lẻ đang chờ vẫn giữ
  /// chỗ cuối (port `pairTogether` của Web). Kết quả vượt 24 VĐV thì bỏ qua
  /// (Web chặn trước khi áp: `next.length > MAX_PAIRING_SELECTION`).
  void _dragPair(PairingCandidate dragged, PairingCandidate target) {
    if (_busy || dragged.id == target.id) return;
    final ids = _selectedIds;
    final pairs = _pairs;
    bool has((String, String) pair, String id) =>
        pair.$1 == id || pair.$2 == id;
    if (pairs.any((pair) => has(pair, dragged.id) && has(pair, target.id))) {
      return;
    }
    final kept = <String>[
      for (final pair in pairs)
        if (!has(pair, dragged.id) && !has(pair, target.id)) ...[
          pair.$1,
          pair.$2,
        ],
    ];
    final waiting = ids.length % 2 == 1 ? ids.last : null;
    final keepWaiting =
        (waiting != null && waiting != dragged.id && waiting != target.id)
        ? [waiting]
        : const <String>[];
    final next = [...kept, target.id, dragged.id, ...keepWaiting];
    if (next.length > _maxSelection) return;
    _applySelection(next);
  }

  /// Xáo trộn Fisher-Yates thứ tự đã chọn (port `shuffleIds` của Web);
  /// tên cặp bị xoá vì thứ tự đôi đổi hoàn toàn.
  void _shuffle() {
    if (_busy || _selectedIds.length < 2) return;
    final random = Random();
    final next = List.of(_selectedIds);
    for (var index = next.length - 1; index > 0; index -= 1) {
      final swapIndex = random.nextInt(index + 1);
      final tmp = next[index];
      next[index] = next[swapIndex];
      next[swapIndex] = tmp;
    }
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(next);
      _pairNames.clear();
    });
  }

  Future<void> _submitBatch() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final pairs = <PairInput>[];
    for (final pair in _pairs) {
      final name = (_pairNames[_pairKey(pair)] ?? '').trim();
      pairs.add(
        PairInput(
          participant1Id: pair.$1,
          participant2Id: pair.$2,
          teamName: name.isEmpty ? null : name,
        ),
      );
    }
    if (pairs.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .pairBatch(widget.tournamentId, pairs);
      await widget.onRefresh?.call();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.pairingSuccess(pairs.length))),
        );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              tournamentSheetServerMessage(error) ??
              ErrorParser.parse(error, l10n.pairingActionFailed, l10n);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitGenerate() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(tournamentManagementRepositoryProvider)
          .pairGenerate(
            widget.tournamentId,
            strategy: _strategy,
            divisionId: widget.divisionId,
          );
      await widget.onRefresh?.call();
      if (!mounted) return;
      if (result.pairedCount == 0) {
        // Web: 2xx không ghép được cặp nào là thông báo, không phải lỗi;
        // sheet còn nguyên trạng thái để BTC thử chiến lược khác.
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.pairingNoPairsFormed)));
        return;
      }
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.unpairedCount > 0
                  ? l10n.pairingSuccessWithUnpaired(
                      result.pairedCount,
                      result.unpairedCount,
                    )
                  : l10n.pairingSuccess(result.pairedCount),
            ),
          ),
        );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              tournamentSheetServerMessage(error) ??
              ErrorParser.parse(error, l10n.pairingActionFailed, l10n);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// One button of the footer row: 44dp tall (touch target) whatever the kit's
  /// own minimum is.
  Widget _footerButton(Widget button) => SizedBox(height: 44, child: button);

  Widget _buildFooter(AppLocalizations l10n) {
    if (!_manualTab) {
      return _footerButton(
        LavishButton(
          buttonKey: const ValueKey('pairing-generate'),
          label: _busy ? l10n.pairingRunning : l10n.pairingRandomConfirmAction,
          busy: _busy,
          onPressed: _busy ? null : _submitGenerate,
        ),
      );
    }
    final pairCount = _pairs.length;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _footerButton(
            LavishButton(
              buttonKey: const ValueKey('pairing-shuffle'),
              kind: LavishButtonKind.outline,
              label: l10n.pairingShuffleButton,
              onPressed: (_busy || _selectedIds.length < 2) ? null : _shuffle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _footerButton(
            LavishButton(
              buttonKey: const ValueKey('pairing-submit'),
              label: _busy
                  ? l10n.pairingSubmitting
                  : l10n.pairingSubmitPairs(pairCount),
              busy: _busy,
              onPressed: (_busy || pairCount == 0) ? null : _submitBatch,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    return TournamentManageSheet(
      title: l10n.pairingSheetTitle,
      busy: _busy,
      footer: _buildFooter(l10n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            key: const ValueKey('pairing-tabs'),
            children: [
              LavishChipButton(
                key: const ValueKey('pairing-tab-manual'),
                label: l10n.pairingManualTab,
                selected: _manualTab,
                onPressed: _busy ? null : () => _selectTab(manual: true),
              ),
              const SizedBox(width: 8),
              LavishChipButton(
                key: const ValueKey('pairing-tab-auto'),
                label: l10n.pairingAutoTab,
                selected: !_manualTab,
                onPressed: _busy ? null : () => _selectTab(manual: false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_manualTab)
            _buildManualTab(l10n, c)
          else
            PairingStrategyPicker(
              keyPrefix: 'pairing-strategy',
              value: _strategy,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _strategy = value),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: LavishColors.bad, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  void _selectTab({required bool manual}) {
    if (manual != _manualTab) setState(() => _manualTab = manual);
  }

  /// Grey filled field of the Lavish popups (no border until focused).
  InputDecoration _lavishInput(
    LavishColors c, {
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: c.dark ? c.rowLine : const Color(0xFFF2F4F7),
      hintText: hintText,
      hintStyle: TextStyle(color: c.faint, fontSize: 13),
      labelText: labelText,
      prefixIcon: prefixIcon,
      prefixIconColor: c.muted,
      constraints: const BoxConstraints(minHeight: 48),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border(Colors.transparent, 0),
      enabledBorder: border(Colors.transparent, 0),
      disabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(LavishColors.accent, 1.5),
    );
  }

  // ── Tab thủ công ──────────────────────────────────────────────────────────

  Widget _buildManualTab(AppLocalizations l10n, LavishColors c) {
    return FutureBuilder<List<PairingCandidate>>(
      future: _candidatesFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final all = snapshot.data ?? const <PairingCandidate>[];
        // Backend trả MỌI participant trừ WITHDRAWN/KICKED/REJECTED, nên lọc
        // "đang chờ ghép" đúng như Web `handleOpenPairing`
        // (RegistrationTab.tsx:755-758): PENDING_PARTNER + không giữ link mời
        // + giữ đúng 1 VĐV, rồi mới tới hạng mục đang xem.
        final divisionCandidates = all
            .where((item) => item.isWaitingForPartner)
            .where(
              (item) =>
                  widget.divisionId.isEmpty ||
                  item.divisionId == widget.divisionId,
            )
            .toList(growable: false);
        final query = _normalizeSearch(_searchController.text);
        final candidates = query.isEmpty
            ? divisionCandidates
            : divisionCandidates
                  .where((item) => _normalizeSearch(item.name).contains(query))
                  .toList(growable: false);
        final pairs = _pairs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('pairing-search'),
              controller: _searchController,
              enabled: !_busy && !loading,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 14, color: c.text),
              decoration: _lavishInput(
                c,
                hintText: l10n.pairingSearchPlaceholder,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _buildCandidateArea(
              l10n,
              c,
              snapshot: snapshot,
              loading: loading,
              candidates: candidates,
              hasAnyWaiting: divisionCandidates.isNotEmpty,
            ),
            if (_hasOddWaiting && snapshot.data != null) ...[
              const SizedBox(height: 4),
              Container(
                key: const ValueKey('pairing-odd-hint'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: c.soft(LavishTone.warn),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.pairingOddHint,
                  style: TextStyle(
                    color: c.pillText(LavishTone.warn),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (pairs.isNotEmpty) const SizedBox(height: 12),
            for (var index = 0; index < pairs.length; index++)
              _buildPairNameInput(pairs[index], index, l10n, c),
          ],
        );
      },
    );
  }

  /// Loading / error / empty states are built directly; rows go through a
  /// lazy `ListView.builder` (shrink-wrapped inside the sheet's scroll body).
  Widget _buildCandidateArea(
    AppLocalizations l10n,
    LavishColors c, {
    required AsyncSnapshot<List<PairingCandidate>> snapshot,
    required bool loading,
    required List<PairingCandidate> candidates,
    required bool hasAnyWaiting,
  }) {
    if (loading && snapshot.data == null) {
      return Padding(
        key: const ValueKey('pairing-loading'),
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              l10n.pairingLoading,
              style: TextStyle(color: c.muted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (snapshot.hasError) {
      return Padding(
        key: const ValueKey('pairing-load-error'),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              tournamentSheetServerMessage(snapshot.error!) ??
                  l10n.pairingLoadFailed,
              style: const TextStyle(color: LavishColors.bad, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('pairing-retry'),
              onPressed: loading ? null : _retry,
              child: Text(l10n.infoRetry),
            ),
          ],
        ),
      );
    }
    if (candidates.isEmpty) {
      return Container(
        key: const ValueKey('pairing-empty'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: BoxDecoration(
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          hasAnyWaiting ? l10n.pairingNoSearchResults : l10n.pairingEmpty,
          style: TextStyle(
            color: c.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: candidates.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildCandidateRow(candidates[index], l10n, c),
      ),
    );
  }

  /// Ô đặt tên từng cặp. Khoá theo cặp (`p1|p2`): cặp ở vị trí này đổi người
  /// thì ô được dựng lại trống, như Web xoá tên cặp không còn tồn tại.
  Widget _buildPairNameInput(
    (String, String) pair,
    int index,
    AppLocalizations l10n,
    LavishColors c,
  ) {
    final key = _pairKey(pair);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: ValueKey('pairing-name-$key'),
        initialValue: _pairNames[key] ?? '',
        enabled: !_busy,
        onChanged: (value) => _pairNames[key] = value,
        style: TextStyle(fontSize: 14, color: c.text),
        decoration: _lavishInput(
          c,
          labelText: l10n.pairingOptionalNameLabel(index + 1),
        ),
      ),
    );
  }

  Widget _buildCandidateRow(
    PairingCandidate candidate,
    AppLocalizations l10n,
    LavishColors c,
  ) {
    final selectionIndex = _selectedIds.indexOf(candidate.id);
    final selected = selectionIndex >= 0;
    final isWaiting =
        selected && _hasOddWaiting && selectionIndex == _selectedIds.length - 1;
    final pairNumber = (selectionIndex ~/ 2) + 1;
    final row = Material(
      color: selected ? c.soft(LavishTone.accent) : c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('pairing-row-${candidate.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggle(candidate),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? LavishColors.accent : c.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: candidate.avatarUrl == null
                    ? null
                    : NetworkImage(candidate.avatarUrl!),
                onBackgroundImageError: candidate.avatarUrl == null
                    ? null
                    : (_, _) {},
                child: candidate.avatarUrl == null
                    ? Text(
                        candidate.name.isEmpty
                            ? '?'
                            : String.fromCharCode(
                                candidate.name.runes.first,
                              ).toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  candidate.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                LavishPill(
                  isWaiting
                      ? l10n.pairingWaitingBadge
                      : l10n.pairingPairBadge(pairNumber),
                  tone: isWaiting ? LavishTone.warn : LavishTone.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return LongPressDraggable<PairingCandidate>(
      key: ValueKey('pairing-drag-${candidate.id}'),
      data: candidate,
      maxSimultaneousDrags: _busy ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: row,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: DragTarget<PairingCandidate>(
        onWillAcceptWithDetails: _busy
            ? null
            : (details) => details.data.id != candidate.id,
        onAcceptWithDetails: _busy
            ? null
            : (details) => _dragPair(details.data, candidate),
        builder: (context, candidateData, rejectedData) {
          final highlighted = candidateData.isNotEmpty;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: highlighted
                  ? Border.all(color: LavishColors.accent, width: 2)
                  : null,
            ),
            child: row,
          );
        },
      ),
    );
  }
}
