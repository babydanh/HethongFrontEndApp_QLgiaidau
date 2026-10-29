import 'package:app_quanly_giaidau/domain/entities/pairing.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Single choice between the three auto-pairing strategies, labels only.
/// Shared by the pairing sheet (tab Tự động) and the "Tự ghép" dialog; each
/// row is keyed `<keyPrefix>-<strategy.name>`.
class PairingStrategyPicker extends StatelessWidget {
  const PairingStrategyPicker({
    super.key,
    required this.keyPrefix,
    required this.value,
    required this.onChanged,
  });

  final String keyPrefix;
  final PairingStrategy value;

  /// Null disables the rows (e.g. while a request is running).
  final ValueChanged<PairingStrategy>? onChanged;

  static String labelOf(AppLocalizations l10n, PairingStrategy strategy) =>
      switch (strategy) {
        PairingStrategy.random => l10n.pairingStrategyRandomLabel,
        PairingStrategy.eloBalanced => l10n.pairingStrategyEloBalancedLabel,
        PairingStrategy.sameLevel => l10n.pairingStrategySameLevelLabel,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final handler = onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final strategy in PairingStrategy.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Option(
              key: ValueKey('$keyPrefix-${strategy.name}'),
              label: labelOf(l10n, strategy),
              selected: strategy == value,
              colors: c,
              onTap: handler == null ? null : () => handler(strategy),
            ),
          ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final LavishColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = LavishColors.accent;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.soft(LavishTone.accent) : colors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? accent : colors.line,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? accent : colors.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
