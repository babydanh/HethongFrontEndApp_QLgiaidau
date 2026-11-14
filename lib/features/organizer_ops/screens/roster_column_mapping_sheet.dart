// Popup `Ghép cột` của màn Nhập Excel: mỗi cột của file là một dòng, chạm để chọn trường cho cột.
// Không đọc provider, không gọi mạng: dữ liệu vào qua [drafts], kết quả ra qua `Navigator.pop`.

import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_mapping_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Vùng chạm tối thiểu của dòng cột, chip và nút.
const double _tapTarget = 44;
const double _columnRowHeight = 56;

/// Trả `null` khi người dùng đóng popup mà không bấm `Xong`.
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
  int _selected = 0;
  int? _openColumn;
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _separatorController = TextEditingController();

  RosterMappingDraft get _draft => _drafts[_selected];

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
    _headerController.text = '${_draft.reading.headerRowIndex + 1}';
    _separatorController.text = _draft.reading.separator;
  }

  void _replace(RosterMappingDraft next, {bool closeRow = false}) {
    setState(() {
      _drafts = [
        for (var i = 0; i < _drafts.length; i++)
          i == _selected ? next : _drafts[i],
      ];
      if (closeRow) _openColumn = null;
    });
  }

  void _select(int index) {
    setState(() {
      _selected = index;
      _openColumn = null;
      _syncControllers();
    });
  }

  void _changeHeaderRow(int displayRow) {
    _replace(_draft.withHeaderRow(displayRow - 1), closeRow: true);
    _headerController.text = '${_draft.reading.headerRowIndex + 1}';
  }

  bool get _canFinish {
    final readable = _drafts.where((d) => !d.wasSkipped);
    if (readable.any((d) => !d.hasIdentity)) return false;
    return _drafts.any(
      (d) => (!d.wasSkipped || d.hasIdentity) && d.rowCount > 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
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
                      _buildTitle(l10n, colors),
                      if (_drafts.length > 1) _buildSheetStrip(l10n, colors),
                      Expanded(child: _buildBody(l10n, colors)),
                      _buildFooter(l10n, colors),
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

  Widget _buildTitle(AppLocalizations l10n, AppColorsExtension colors) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.rosterMapTitle,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('roster-map-close'),
              tooltip: l10n.rosterImportClose,
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close_rounded, color: colors.textSecondary),
            ),
          ],
        ),
      );

  Widget _buildSheetStrip(AppLocalizations l10n, AppColorsExtension colors) =>
      SizedBox(
        height: _tapTarget + 8,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          itemCount: _drafts.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final draft = _drafts[index];
            final name = draft.reading.sheetName;
            final label = draft.wasSkipped && !draft.hasIdentity
                ? l10n.rosterMapSkippedSheet(name)
                : name;
            final missing = !draft.wasSkipped && !draft.hasIdentity;
            return _Chip(
              key: ValueKey('roster-map-sheet-$index'),
              label: label,
              selected: index == _selected,
              leading: missing
                  ? Container(
                      key: ValueKey('roster-map-sheet-dot-$index'),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.error,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onTap: () => _select(index),
            );
          },
        ),
      );

  Widget _buildBody(AppLocalizations l10n, AppColorsExtension colors) {
    final draft = _draft;
    if (draft.columns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.rosterMapNoColumns,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderRow(l10n, colors),
          if (draft.headerMayBeShifted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.rosterMapHeaderShifted,
                style: TextStyle(color: colors.warning, fontSize: 13),
              ),
            ),
          if (draft.isDoubles) _buildPairing(l10n, colors),
          for (final column in draft.columns)
            _buildColumn(l10n, colors, column),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(AppLocalizations l10n, AppColorsExtension colors) {
    final lastRow = _draft.reading.grid.rows.length - 1;
    final current = _draft.reading.headerRowIndex + 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.rosterMapHeaderRow,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('roster-map-header-minus'),
            constraints: const BoxConstraints(
              minWidth: _tapTarget,
              minHeight: _tapTarget,
            ),
            onPressed: current > 1 ? () => _changeHeaderRow(current - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 56,
            child: TextField(
              key: const ValueKey('roster-map-header-field'),
              controller: _headerController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (text) =>
                  _changeHeaderRow(int.tryParse(text.trim()) ?? current),
            ),
          ),
          IconButton(
            key: const ValueKey('roster-map-header-plus'),
            constraints: const BoxConstraints(
              minWidth: _tapTarget,
              minHeight: _tapTarget,
            ),
            onPressed: current < lastRow
                ? () => _changeHeaderRow(current + 1)
                : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildPairing(AppLocalizations l10n, AppColorsExtension colors) {
    final options = {
      RosterPairLayout.single: l10n.rosterMapPairSingle,
      RosterPairLayout.columns: l10n.rosterMapPairColumns,
      RosterPairLayout.sameCell: l10n.rosterMapPairSameCell,
      RosterPairLayout.consecutiveRows: l10n.rosterMapPairConsecutiveRows,
    };
    final layout = _draft.effectiveLayout;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in options.entries)
                _Chip(
                  key: ValueKey('roster-map-pair-${entry.key.name}'),
                  label: entry.value,
                  selected: entry.key == layout,
                  onTap: () => _replace(_draft.withLayout(entry.key)),
                ),
            ],
          ),
          if (layout == RosterPairLayout.sameCell)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                key: const ValueKey('roster-map-separator'),
                controller: _separatorController,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.rosterMapSeparator,
                ),
                onChanged: (text) => _replace(
                  _draft.withLayout(RosterPairLayout.sameCell, separator: text),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColumn(
    AppLocalizations l10n,
    AppColorsExtension colors,
    RosterMappingColumn column,
  ) {
    final title = column.header.isEmpty
        ? l10n.rosterMapColumnFallback(_columnLetter(column.index))
        : column.header;
    final locked = column.kind != RosterColumnKind.normal;
    final isOpen = _openColumn == column.index;
    final slotLabel = _slotLabel(l10n, column.slot);
    final pill = Container(
      key: ValueKey('roster-map-pill-${column.index}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: column.slot == null && !locked
            ? colors.bgSurface
            : colors.chipBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (column.kind == RosterColumnKind.sensitive) ...[
            Icon(Icons.lock_outline_rounded, size: 14, color: colors.textMuted),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              switch (column.kind) {
                RosterColumnKind.serial => l10n.rosterMapIndexLabel,
                RosterColumnKind.sensitive => l10n.rosterMapLockedLabel,
                RosterColumnKind.normal => slotLabel,
              },
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: locked || column.slot == null
                    ? colors.textMuted
                    : colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!locked) ...[
            const SizedBox(width: 4),
            Icon(
              isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 16,
              color: colors.textMuted,
            ),
          ],
        ],
      ),
    );
    final content = ConstrainedBox(
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
                      color: locked ? colors.textMuted : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (column.sample.isNotEmpty)
                    Text(
                      column.sample,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: pill),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        locked
            ? Container(
                key: ValueKey('roster-map-col-${column.index}'),
                child: content,
              )
            : InkWell(
                key: ValueKey('roster-map-col-${column.index}'),
                onTap: () =>
                    setState(() => _openColumn = isOpen ? null : column.index),
                child: content,
              ),
        if (isOpen) _buildSlotChips(l10n, column),
        Divider(height: 1, color: colors.border),
      ],
    );
  }

  Widget _buildSlotChips(AppLocalizations l10n, RosterMappingColumn column) {
    final taken = {
      for (final c in _draft.columns)
        if (c.slot != null) c.slot!,
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
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final slot in slots)
            _Chip(
              key: ValueKey('roster-map-chip-${slot.name}'),
              label: _slotLabel(l10n, slot),
              selected: column.slot == slot,
              faded: taken.contains(slot) && column.slot != slot,
              onTap: () =>
                  _replace(_draft.assign(column.index, slot), closeRow: true),
            ),
          _Chip(
            key: const ValueKey('roster-map-chip-note'),
            label: l10n.rosterMapNote,
            selected: column.slot == null,
            onTap: () =>
                _replace(_draft.assign(column.index, null), closeRow: true),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n, AppColorsExtension colors) {
    final draft = _draft;
    final needName = !draft.wasSkipped || draft.columns.isNotEmpty
        ? !draft.hasIdentity
        : false;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: needName
                ? Text(
                    l10n.rosterMapPickName,
                    key: const ValueKey('roster-map-pick-name'),
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Text(
                    l10n.rosterMapRows(draft.rowCount),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            key: const ValueKey('roster-map-done'),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: _canFinish
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

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.faded = false,
  });

  final String label;
  final bool selected;
  final bool faded;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.chipBackground : colors.bgSurface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? colors.textPrimary : colors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _tapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: faded ? colors.textMuted : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _columnLetter(int index) {
  var n = index;
  var letters = '';
  do {
    letters = String.fromCharCode(65 + n % 26) + letters;
    n = n ~/ 26 - 1;
  } while (n >= 0);
  return letters;
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
