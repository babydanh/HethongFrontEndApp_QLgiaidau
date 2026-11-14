// Popup "Ghép cột" của màn Nhập Excel: người dùng chỉnh cột, hàng tiêu đề và cách ghép cặp.
// Không đọc provider, không gọi mạng: toàn bộ dữ liệu qua tham số, kết quả qua `Navigator.pop`.

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_mapping_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Vùng chạm tối thiểu của dòng cột, chip và nút.
const double _minTouch = 44;
const double _columnRowHeight = 56;

/// Chip chọn cho cột "Ghi chú" (không phải slot thật, tương ứng `assign(col, null)`).
const String _noteChipId = 'note';

/// Mở popup; trả `null` khi đóng mà không bấm `Xong`.
Future<RosterMappingResult?> showRosterColumnMappingSheet(
  BuildContext context, {
  required List<RosterMappingDraft> drafts,
}) => showModalBottomSheet<RosterMappingResult>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => RosterColumnMappingSheet(drafts: drafts),
);

class RosterColumnMappingSheet extends StatefulWidget {
  const RosterColumnMappingSheet({super.key, required this.drafts});

  final List<RosterMappingDraft> drafts;

  @override
  State<RosterColumnMappingSheet> createState() =>
      _RosterColumnMappingSheetState();
}

class _RosterColumnMappingSheetState extends State<RosterColumnMappingSheet> {
  late List<RosterMappingDraft> _drafts = List.of(widget.drafts);
  final _headerController = TextEditingController();
  final _separatorController = TextEditingController();
  int _active = 0;
  int? _openColumn;
  final _chipsKey = GlobalKey();

  RosterMappingDraft get _draft => _drafts[_active];

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _separatorController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final header = (_draft.reading.headerRowIndex + 1).toString();
    if (_headerController.text != header) _headerController.text = header;
    if (_separatorController.text != _draft.reading.separator) {
      _separatorController.text = _draft.reading.separator;
    }
  }

  void _update(RosterMappingDraft next, {bool closeChips = true}) {
    setState(() {
      _drafts = [
        for (var i = 0; i < _drafts.length; i++)
          i == _active ? next : _drafts[i],
      ];
      if (closeChips) _openColumn = null;
    });
    _syncControllers();
  }

  void _toggleColumn(int column) {
    setState(() => _openColumn = _openColumn == column ? null : column);
    // Chip mở ra có thể nằm dưới chân sheet: cuộn tới để chạm được.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chipsContext = _chipsKey.currentContext;
      if (chipsContext == null || !chipsContext.mounted) return;
      Scrollable.ensureVisible(
        chipsContext,
        duration: const Duration(milliseconds: 150),
      );
    });
  }

  void _selectSheet(int index) {
    setState(() {
      _active = index;
      _openColumn = null;
    });
    _syncControllers();
  }

  void _setHeaderRow(int oneBased) =>
      _update(_draft.withHeaderRow(oneBased - 1));

  bool get _allIdentified =>
      _drafts.every((draft) => draft.wasSkipped || draft.hasIdentity);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SizedBox.expand(
                child: Material(
                  key: const ValueKey('roster-map-sheet'),
                  color: colors.bgCard,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _titleBar(context),
                      if (_drafts.length > 1) _sheetStrip(context),
                      Expanded(child: _body(context)),
                      _footer(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleBar(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.rosterMapTitle,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('roster-map-close'),
            constraints: const BoxConstraints(
              minWidth: _minTouch,
              minHeight: _minTouch,
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _sheetStrip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return SizedBox(
      height: _minTouch + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _drafts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final draft = _drafts[i];
          final name = draft.reading.sheetName;
          final label = draft.wasSkipped && !draft.hasIdentity
              ? l10n.rosterMapSkippedSheet(name)
              : name;
          final needsAttention = !draft.wasSkipped && !draft.hasIdentity;
          return _Pill(
            key: ValueKey('roster-map-sheet-$i'),
            selected: i == _active,
            onTap: () => _selectSheet(i),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (needsAttention)
                  Container(
                    key: ValueKey('roster-map-sheet-dot-$i'),
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: colors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final columns = _draft.columns;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_draft.reading.grid.rows.length >= 2) _headerRowControl(context),
          if (_draft.headerMayBeShifted)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.rosterMapHeaderShifted,
                      key: const ValueKey('roster-map-header-shifted'),
                      style: TextStyle(color: colors.warning, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (_draft.isDoubles && columns.isNotEmpty) _layoutControl(context),
          const SizedBox(height: 8),
          if (columns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.rosterMapNoColumns,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textMuted),
              ),
            )
          else
            for (final column in columns) _columnRow(context, column),
        ],
      ),
    );
  }

  Widget _headerRowControl(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final maxRow = _draft.reading.grid.rows.length - 1;
    final current = _draft.reading.headerRowIndex + 1;
    Widget step(String id, IconData icon, int target, bool enabled) =>
        IconButton(
          key: ValueKey('roster-map-header-$id'),
          constraints: const BoxConstraints(
            minWidth: _minTouch,
            minHeight: _minTouch,
          ),
          onPressed: enabled ? () => _setHeaderRow(target) : null,
          icon: Icon(icon, color: colors.textSecondary),
        );
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.rosterMapHeaderRow,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ),
        step('minus', Icons.remove_rounded, current - 1, current > 1),
        SizedBox(
          width: 56,
          child: TextField(
            key: const ValueKey('roster-map-header-field'),
            controller: _headerController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              final value = int.tryParse(text.trim());
              if (value != null) _setHeaderRow(value.clamp(1, maxRow));
            },
          ),
        ),
        step('plus', Icons.add_rounded, current + 1, current < maxRow),
      ],
    );
  }

  Widget _layoutControl(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final labels = {
      RosterPairLayout.single: l10n.rosterMapPairSingle,
      RosterPairLayout.columns: l10n.rosterMapPairColumns,
      RosterPairLayout.sameCell: l10n.rosterMapPairSameCell,
      RosterPairLayout.consecutiveRows: l10n.rosterMapPairConsecutiveRows,
    };
    final effective = _draft.effectiveLayout;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            key: const ValueKey('roster-map-layout-row'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in labels.entries)
                _Pill(
                  key: ValueKey('roster-map-layout-${entry.key.name}'),
                  selected: effective == entry.key,
                  onTap: () => _update(_draft.withLayout(entry.key)),
                  child: Text(entry.value),
                ),
            ],
          ),
          if (effective == RosterPairLayout.sameCell)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                key: const ValueKey('roster-map-separator'),
                controller: _separatorController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.rosterMapSeparator,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (text) => _update(
                  _draft.withLayout(RosterPairLayout.sameCell, separator: text),
                  closeChips: false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _slotLabel(AppLocalizations l10n, RosterSlot? slot) => switch (slot) {
    RosterSlot.player1Name => l10n.rosterMapSlotPlayer1Name,
    RosterSlot.player1Phone => l10n.rosterMapSlotPlayer1Phone,
    RosterSlot.player1Email => l10n.rosterMapSlotPlayer1Email,
    RosterSlot.player2Name => l10n.rosterMapSlotPlayer2Name,
    RosterSlot.player2Phone => l10n.rosterMapSlotPlayer2Phone,
    RosterSlot.player2Email => l10n.rosterMapSlotPlayer2Email,
    RosterSlot.teamName => l10n.rosterMapSlotTeamName,
    RosterSlot.pairCode => l10n.rosterMapSlotPairCode,
    RosterSlot.divisionName => l10n.rosterMapSlotDivisionName,
    RosterSlot.isPaid => l10n.rosterMapSlotIsPaid,
    RosterSlot.elo => l10n.rosterMapSlotElo,
    RosterSlot.notes || null => l10n.rosterMapNote,
  };

  Widget _columnRow(BuildContext context, RosterMappingColumn column) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final locked = column.kind != RosterColumnKind.normal;
    final title = column.header.isNotEmpty
        ? column.header
        : l10n.rosterMapColumnFallback(rosterColumnLetter(column.index));
    final tag = switch (column.kind) {
      RosterColumnKind.serial => l10n.rosterMapIndexLabel,
      RosterColumnKind.sensitive => l10n.rosterMapLockedLabel,
      RosterColumnKind.normal => _slotLabel(l10n, column.slot),
    };
    final open = _openColumn == column.index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: ValueKey('roster-map-column-${column.index}'),
          onTap: locked ? null : () => _toggleColumn(column.index),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _columnRowHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: locked
                                ? colors.textMuted
                                : colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (column.sample.isNotEmpty)
                          Text(
                            column.sample,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (locked)
                    Icon(Icons.lock_rounded, size: 16, color: colors.textMuted),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      tag,
                      key: ValueKey('roster-map-slot-${column.index}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: locked
                            ? colors.textMuted
                            : column.slot == null ||
                                  column.slot == RosterSlot.notes
                            ? colors.textSecondary
                            : AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open) _chips(context, column),
        Divider(height: 1, color: colors.border),
      ],
    );
  }

  Widget _chips(BuildContext context, RosterMappingColumn column) {
    final l10n = AppLocalizations.of(context)!;
    final used = {
      for (final c in _draft.columns)
        if (c.slot != null && c.index != column.index) c.slot!,
    };
    final slots = [
      RosterSlot.player1Name,
      RosterSlot.player1Phone,
      RosterSlot.player1Email,
      if (_draft.isDoubles) ...[
        RosterSlot.player2Name,
        RosterSlot.player2Phone,
        RosterSlot.player2Email,
      ],
      RosterSlot.teamName,
      RosterSlot.pairCode,
      RosterSlot.divisionName,
      RosterSlot.isPaid,
      RosterSlot.elo,
    ];
    final noteSelected = column.slot == null || column.slot == RosterSlot.notes;
    return Padding(
      key: _chipsKey,
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final slot in slots)
            _Pill(
              key: ValueKey('roster-map-chip-${column.index}-${slot.name}'),
              selected: column.slot == slot,
              faded: used.contains(slot),
              onTap: () => _update(_draft.assign(column.index, slot)),
              child: Text(_slotLabel(l10n, slot)),
            ),
          _Pill(
            key: ValueKey('roster-map-chip-${column.index}-$_noteChipId'),
            selected: noteSelected,
            onTap: () => _update(_draft.assign(column.index, null)),
            child: Text(l10n.rosterMapNote),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: !_draft.hasIdentity && _draft.reading.grid.rows.length >= 2
                ? Text(
                    l10n.rosterMapPickName,
                    key: const ValueKey('roster-map-pick-name'),
                    style: TextStyle(
                      color: colors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    l10n.rosterMapRows(_draft.rowCount),
                    key: const ValueKey('roster-map-row-count'),
                    style: TextStyle(color: colors.textSecondary),
                  ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            key: const ValueKey('roster-map-done'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, _minTouch),
            ),
            onPressed: _allIdentified
                ? () => Navigator.of(
                    context,
                  ).pop(RosterMappingResult.fromDrafts(_drafts))
                : null,
            child: Text(l10n.rosterMapDone),
          ),
        ],
      ),
    );
  }
}

/// Chip/viên thuốc bấm được, cao tối thiểu 44 dp.
class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.faded = false,
  });

  final bool selected;
  final bool faded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: faded && !selected ? 0.55 : 1,
      child: Material(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.18)
            : colors.chipBackground,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppTheme.primary : colors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: _minTouch,
              minWidth: _minTouch,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: selected ? AppTheme.primary : colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
