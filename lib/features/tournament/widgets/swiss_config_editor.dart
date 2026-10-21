import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/config/app_spacing.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _maxRoundsLimit = 30;

/// Flat editor for `roundConfig.swiss`: round count, first-round pairing and the
/// tiebreak order. One surface (no cards); the only icon is the drag handle.
class SwissConfigEditor extends StatefulWidget {
  const SwissConfigEditor({
    super.key,
    required this.value,
    required this.teamCount,
    required this.minPlayedRounds,
    this.enabled = true,
    required this.onChanged,
  });

  final SwissConfig value;

  /// Valid team count; 0 means unknown (only the contract cap of 30 applies).
  final int teamCount;

  /// Rounds already paired; [SwissConfig.totalRounds] never goes below this.
  final int minPlayedRounds;
  final bool enabled;
  final ValueChanged<SwissConfig> onChanged;

  @override
  State<SwissConfigEditor> createState() => _SwissConfigEditorState();
}

class _SwissConfigEditorState extends State<SwissConfigEditor> {
  late final TextEditingController _rounds;
  final FocusNode _roundsFocus = FocusNode();
  late List<SwissTiebreak> _order;
  late Set<SwissTiebreak> _on;
  late int _totalRounds;
  late String _pairing;
  bool _clampedUp = false;

  @override
  void initState() {
    super.initState();
    _rounds = TextEditingController();
    _roundsFocus.addListener(() {
      if (!_roundsFocus.hasFocus) _commitRounds();
    });
    _load(widget.value);
  }

  @override
  void didUpdateWidget(SwissConfigEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent reverted to a saved value (e.g. after a failed save): follow it.
    if (!_sameConfig(widget.value, _current())) _load(widget.value);
  }

  @override
  void dispose() {
    _roundsFocus.dispose();
    _rounds.dispose();
    super.dispose();
  }

  void _load(SwissConfig value) {
    _totalRounds = value.totalRounds;
    _pairing = value.firstRoundPairing;
    _on = {...value.tiebreakOrder};
    _order = [
      ...value.tiebreakOrder,
      for (final item in SwissTiebreak.values)
        if (!_on.contains(item)) item,
    ];
    _rounds.text = '$_totalRounds';
    _clampedUp = false;
  }

  SwissConfig _current() => SwissConfig(
    totalRounds: _totalRounds,
    tiebreakOrder: [
      for (final item in _order)
        if (_on.contains(item)) item,
    ],
    firstRoundPairing: _pairing,
  );

  bool _sameConfig(SwissConfig a, SwissConfig b) =>
      a.totalRounds == b.totalRounds &&
      a.firstRoundPairing == b.firstRoundPairing &&
      a.tiebreakOrder.length == b.tiebreakOrder.length &&
      [
        for (var i = 0; i < a.tiebreakOrder.length; i++) i,
      ].every((i) => a.tiebreakOrder[i] == b.tiebreakOrder[i]);

  int get _minRounds => math.max(1, widget.minPlayedRounds);

  int get _maxRounds {
    final cap = widget.teamCount > 0
        ? math.max(1, widget.teamCount - 1)
        : _maxRoundsLimit;
    return math.max(_minRounds, math.min(cap, _maxRoundsLimit));
  }

  void _emit() => widget.onChanged(_current());

  void _commitRounds() {
    final parsed = int.tryParse(_rounds.text.trim());
    if (parsed == null) {
      // Empty or invalid: restore the previous value, send nothing.
      setState(() => _rounds.text = '$_totalRounds');
      return;
    }
    final clamped = parsed.clamp(_minRounds, _maxRounds);
    setState(() {
      if (parsed < widget.minPlayedRounds) {
        _clampedUp = true;
      } else if (parsed != _totalRounds) {
        _clampedUp = false;
      }
      _rounds.text = '$clamped';
    });
    if (clamped != _totalRounds) {
      _totalRounds = clamped;
      _emit();
    }
  }

  void _setPairing(String? value) {
    if (value == null || value == _pairing) return;
    setState(() => _pairing = value);
    _emit();
  }

  void _toggle(SwissTiebreak item, bool on) {
    setState(() => on ? _on.add(item) : _on.remove(item));
    _emit();
  }

  void _move(int from, int to) {
    if (to < 0 || to >= _order.length || from == to) return;
    setState(() => _order.insert(to, _order.removeAt(from)));
    _emit();
  }

  String _label(AppLocalizations l10n, SwissTiebreak item) => switch (item) {
    SwissTiebreak.buchholz => l10n.swissTiebreakBuchholz,
    SwissTiebreak.buchholzCut1 => l10n.swissTiebreakBuchholzCut1,
    SwissTiebreak.sonnebornBerger => l10n.swissTiebreakSonnebornBerger,
    SwissTiebreak.pointDiff => l10n.swissTiebreakPointDiff,
    SwissTiebreak.wins => l10n.swissTiebreakWins,
    SwissTiebreak.headToHead => l10n.swissTiebreakHeadToHead,
    SwissTiebreak.seed => l10n.swissTiebreakSeed,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('swiss-config-rounds'),
          controller: _rounds,
          focusNode: _roundsFocus,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _commitRounds(),
          decoration: InputDecoration(
            labelText: l10n.swissConfigTotalRounds,
            helperText: l10n.swissConfigRoundsRange(_maxRounds),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_clampedUp)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.swissConfigRoundsMinPlayed(widget.minPlayedRounds),
              style: TextStyle(color: colors.warning),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.swissConfigFirstRound,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        RadioGroup<String>(
          groupValue: _pairing,
          onChanged: _setPairing,
          child: Column(
            children: [
              RadioListTile<String>(
                key: const Key('swiss-config-first-seed'),
                value: 'SEED',
                enabled: widget.enabled,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.swissConfigFirstRoundSeed),
              ),
              RadioListTile<String>(
                key: const Key('swiss-config-first-random'),
                value: 'RANDOM',
                enabled: widget.enabled,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.swissConfigFirstRoundRandom),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.swissConfigTiebreakTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: _move,
          children: [
            for (var i = 0; i < _order.length; i++) _row(l10n, i, _order[i]),
          ],
        ),
      ],
    );
  }

  Widget _row(AppLocalizations l10n, int index, SwissTiebreak item) {
    final on = _on.contains(item);
    final api = item.apiValue;
    final colors = context.colors;
    return Column(
      key: Key('swiss-tiebreak-row-$api'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              enabled: widget.enabled,
              child: SizedBox(
                key: Key('swiss-tiebreak-handle-$api'),
                width: 48,
                height: 48,
                child: Icon(Icons.drag_indicator, color: colors.textSecondary),
              ),
            ),
            Text(
              '${index + 1}.',
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _label(l10n, item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: on ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
            Switch(
              key: Key('swiss-tiebreak-switch-$api'),
              value: on,
              onChanged: widget.enabled ? (v) => _toggle(item, v) : null,
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                key: Key('swiss-tiebreak-up-$api'),
                onPressed: widget.enabled && index > 0
                    ? () => _move(index, index - 1)
                    : null,
                child: Text(l10n.swissConfigMoveUp),
              ),
              TextButton(
                key: Key('swiss-tiebreak-down-$api'),
                onPressed: widget.enabled && index < _order.length - 1
                    ? () => _move(index, index + 1)
                    : null,
                child: Text(l10n.swissConfigMoveDown),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
