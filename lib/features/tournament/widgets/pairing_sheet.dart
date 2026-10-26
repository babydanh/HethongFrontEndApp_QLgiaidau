import 'dart:math';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/pairing.dart';
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

class _PairingSheetState extends ConsumerState<PairingSheet>
    with SingleTickerProviderStateMixin {
  /// Web `MAX_PAIRING_SELECTION`: tối đa 24 VĐV mỗi lần ghép (12 cặp).
  static const _maxSelection = 24;

  late final TabController _tab = TabController(length: 2, vsync: this);
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
  void initState() {
    super.initState();
    _tab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tab.indexIsChanging) return;
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isManualTab = _tab.index == 0;
    final pairs = _pairs;
    return TournamentManageSheet(
      title: l10n.pairingSheetTitle,
      busy: _busy,
      actions: [
        if (isManualTab) ...[
          FilledButton(
            key: const ValueKey('pairing-submit'),
            onPressed: (_busy || pairs.isEmpty) ? null : _submitBatch,
            child: Text(
              _busy
                  ? l10n.pairingSubmitting
                  : l10n.pairingSubmitPairs(pairs.length),
            ),
          ),
          OutlinedButton(
            key: const ValueKey('pairing-shuffle'),
            onPressed: (_busy || _selectedIds.length < 2) ? null : _shuffle,
            child: Text(l10n.pairingShuffleButton),
          ),
        ] else
          FilledButton(
            key: const ValueKey('pairing-generate'),
            onPressed: _busy ? null : _submitGenerate,
            child: Text(
              _busy ? l10n.pairingRunning : l10n.pairingRandomConfirmAction,
            ),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.pairingSheetDescription(widget.divisionName),
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TabBar(
            key: const ValueKey('pairing-tabs'),
            controller: _tab,
            tabs: [
              Tab(
                key: const ValueKey('pairing-tab-manual'),
                text: l10n.pairingManualTab,
              ),
              Tab(
                key: const ValueKey('pairing-tab-auto'),
                text: l10n.pairingAutoTab,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isManualTab)
            _buildManualTab(context, l10n, colors)
          else
            _buildAutoTab(l10n, colors),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
        ],
      ),
    );
  }

  // ── Tab thủ công ──────────────────────────────────────────────────────────

  Widget _buildManualTab(
    BuildContext context,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
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
        // Trạng thái đặc biệt (đang tải / lỗi / rỗng) dựng trực tiếp; danh
        // sách row đi qua ListView.builder cho dựng lười (shrinkWrap nằm
        // trong thân cuộn của sheet).
        Widget listArea;
        if (loading && snapshot.data == null) {
          listArea = Padding(
            key: const ValueKey('pairing-loading'),
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  l10n.pairingLoading,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          listArea = Padding(
            key: const ValueKey('pairing-load-error'),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  tournamentSheetServerMessage(snapshot.error!) ??
                      l10n.pairingLoadFailed,
                  style: TextStyle(color: colors.error, fontSize: 13),
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
        } else if (candidates.isEmpty) {
          listArea = Container(
            key: const ValueKey('pairing-empty'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  divisionCandidates.isEmpty
                      ? l10n.pairingEmpty
                      : l10n.pairingNoSearchResults,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.pairingSearchEmptyHint,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else {
          listArea = ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: candidates.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCandidateRow(candidates[index], l10n, colors),
            ),
          );
        }
        final pairs = _pairs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('pairing-search'),
              controller: _searchController,
              enabled: !_busy && !loading,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search_rounded),
                labelText: l10n.pairingSearchLabel,
                hintText: l10n.pairingSearchPlaceholder,
              ),
            ),
            const SizedBox(height: 12),
            listArea,
            if (_hasOddWaiting && snapshot.data != null) ...[
              const SizedBox(height: 4),
              Container(
                key: const ValueKey('pairing-odd-hint'),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  l10n.pairingOddHint,
                  style: TextStyle(color: colors.warning, fontSize: 12),
                ),
              ),
            ],
            for (var index = 0; index < pairs.length; index++)
              _buildPairNameInput(pairs[index], index, l10n),
          ],
        );
      },
    );
  }

  /// Ô đặt tên từng cặp. Khoá theo cặp (`p1|p2`): cặp ở vị trí này đổi người
  /// thì ô được dựng lại trống, như Web xoá tên cặp không còn tồn tại.
  Widget _buildPairNameInput(
    (String, String) pair,
    int index,
    AppLocalizations l10n,
  ) {
    final key = _pairKey(pair);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.pairingOptionalNameLabel(index + 1),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: ValueKey('pairing-name-$key'),
            initialValue: _pairNames[key] ?? '',
            enabled: !_busy,
            onChanged: (value) => _pairNames[key] = value,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: l10n.pairingOptionalNamePlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateRow(
    PairingCandidate candidate,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    final selectionIndex = _selectedIds.indexOf(candidate.id);
    final selected = selectionIndex >= 0;
    final isWaiting =
        selected && _hasOddWaiting && selectionIndex == _selectedIds.length - 1;
    final pairNumber = (selectionIndex ~/ 2) + 1;
    final row = Material(
      color: selected
          ? AppTheme.primary.withValues(alpha: 0.08)
          : colors.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('pairing-row-${candidate.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggle(candidate),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : colors.border,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.pairingWaitingSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_rounded, size: 18, color: AppTheme.primary),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isWaiting ? colors.warning : AppTheme.primary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isWaiting
                        ? l10n.pairingWaitingBadge
                        : l10n.pairingPairBadge(pairNumber),
                    style: TextStyle(
                      color: isWaiting ? colors.warning : AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                  ? Border.all(color: AppTheme.primary, width: 2)
                  : null,
            ),
            child: row,
          );
        },
      ),
    );
  }

  // ── Tab tự động ───────────────────────────────────────────────────────────

  Widget _buildAutoTab(AppLocalizations l10n, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.pairingAutoTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.pairingAutoDescription,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        RadioGroup<PairingStrategy>(
          groupValue: _strategy,
          onChanged: (value) {
            if (_busy || value == null) return;
            setState(() => _strategy = value);
          },
          child: Column(
            children: [
              for (final strategy in PairingStrategy.values)
                _strategyTile(strategy, l10n, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _strategyTile(
    PairingStrategy strategy,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    final (label, hint) = switch (strategy) {
      PairingStrategy.random => (
        l10n.pairingStrategyRandomLabel,
        l10n.pairingStrategyRandomHint,
      ),
      PairingStrategy.eloBalanced => (
        l10n.pairingStrategyEloBalancedLabel,
        l10n.pairingStrategyEloBalancedHint,
      ),
      PairingStrategy.sameLevel => (
        l10n.pairingStrategySameLevelLabel,
        l10n.pairingStrategySameLevelHint,
      ),
    };
    return RadioListTile<PairingStrategy>(
      key: ValueKey('pairing-strategy-${strategy.name}'),
      value: strategy,
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        hint,
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
