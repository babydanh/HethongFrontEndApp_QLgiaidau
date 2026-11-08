import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/lite_pickleball_scoring.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Side-out / Rally choice of a Lite pickleball tournament. The caller shows
/// its own title and only builds this for pickleball.
class LitePickleballScoringPicker extends StatelessWidget {
  const LitePickleballScoringPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final LitePickleballScoring value;
  final ValueChanged<LitePickleballScoring> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      LitePickleballScoring.sideOut: l10n.divisionEditorSideOutScoring,
      LitePickleballScoring.rally: l10n.divisionEditorRallyScoring,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final scoring in LitePickleballScoring.values)
          LavishChoiceTile(
            key: ValueKey('lite-pickleball-scoring-${scoring.apiValue}'),
            label: labels[scoring]!,
            selected: value == scoring,
            onPressed: () => onChanged(scoring),
          ),
      ],
    );
  }
}
