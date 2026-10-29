import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// One division shown as a chip of a [DivisionStrip].
class DivisionStripItem {
  const DivisionStripItem({
    required this.id,
    required this.name,
    this.count,
    this.capacity,
  });

  final String id;
  final String name;

  /// Athletes (or teams) registered; null hides the number.
  final int? count;

  /// Maximum entries; shown as `count/capacity` when known.
  final int? capacity;

  String? get countLabel {
    final registered = count;
    if (registered == null) return null;
    final limit = capacity;
    return limit == null ? '$registered' : '$registered/$limit';
  }
}

/// Horizontal division picker shared by the bracket, live and ops screens
/// (Lavish design `noidung-thi-dau-component`): one 40dp line per chip
/// (name + count, no icon), 44dp tap area, auto-scrolls the selected chip
/// into view. Chip keys are `<keyPrefix>-<id>`, plus `-all` and `-manage`.
class DivisionStrip extends StatefulWidget {
  const DivisionStrip({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onChanged,
    this.showAll = false,
    this.onManage,
    this.keyPrefix = 'division-chip',
  });

  final List<DivisionStripItem> items;

  /// Selected division; null selects "Tất cả" when [showAll] is on.
  final String? selectedId;

  /// Called with the tapped division id, or null for "Tất cả".
  final ValueChanged<String?> onChanged;

  /// Adds a leading "Tất cả" chip that clears the filter.
  final bool showAll;

  /// Adds a trailing "Quản lý" chip (organizers only); null hides it.
  final VoidCallback? onManage;

  final String keyPrefix;

  @override
  State<DivisionStrip> createState() => _DivisionStripState();
}

class _DivisionStripState extends State<DivisionStrip> {
  static const _gap = SizedBox(width: 8);
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(DivisionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _scrollToSelected();
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _selectedKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _selectable(bool selected, Widget chip) =>
      KeyedSubtree(key: selected ? _selectedKey : null, child: chip);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefix = widget.keyPrefix;
    // One division has nothing to pick; managers keep the strip for "Quản lý".
    if (widget.items.length <= 1 && widget.onManage == null) {
      return const SizedBox.shrink();
    }
    final chips = <Widget>[
      if (widget.showAll)
        _selectable(
          widget.selectedId == null,
          _StripChip(
            key: ValueKey('$prefix-all'),
            label: l10n.matchesFilterAll,
            selected: widget.selectedId == null,
            onTap: () => widget.onChanged(null),
          ),
        ),
      for (final item in widget.items)
        _selectable(
          item.id == widget.selectedId,
          _StripChip(
            key: ValueKey('$prefix-${item.id}'),
            label: item.name,
            count: item.countLabel,
            selected: item.id == widget.selectedId,
            onTap: () => widget.onChanged(item.id),
          ),
        ),
      if (widget.onManage != null)
        _StripChip(
          key: ValueKey('$prefix-manage'),
          label: l10n.divisionStripManage,
          selected: false,
          outlined: true,
          onTap: widget.onManage!,
        ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < chips.length; index++) ...[
            if (index > 0) _gap,
            chips[index],
          ],
        ],
      ),
    );
  }
}

class _StripChip extends StatelessWidget {
  const _StripChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.outlined = false,
  });

  final String label;
  final String? count;
  final bool selected;

  /// Accent-coloured text chip with an accent border (the "Quản lý" action).
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    const accent = LavishColors.accent;
    final textColor = selected ? Colors.white : (outlined ? accent : c.text);
    final border = selected || outlined ? accent : c.line;
    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? label : '$label $count',
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        // 44dp tap area around a 40dp chip.
        child: SizedBox(
          height: 44,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? accent : c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (count != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          count!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white70 : c.faint,
                          ),
                        ),
                      ],
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
}
