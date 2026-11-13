import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_palette.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Bottom bar of the badminton/tennis court: + and − of each team, centred.
/// The first team's buttons read "+ −" and the second team's "− +", so the two
/// minus buttons sit side by side in the middle.
class RacketScoreBar extends StatelessWidget {
  const RacketScoreBar({
    super.key,
    required this.firstTeam,
    required this.onScore,
  });

  final int firstTeam;

  /// Null hides the bar (a viewer cannot score).
  final void Function(int team, bool increment)? onScore;

  @override
  Widget build(BuildContext context) {
    final onScore = this.onScore;
    if (onScore == null) return const SizedBox.shrink();
    final second = 3 - firstTeam;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              _ScoreButton(team: firstTeam, plus: true, onScore: onScore),
              _ScoreButton(team: firstTeam, plus: false, onScore: onScore),
              const SizedBox(width: 14),
              _ScoreButton(team: second, plus: false, onScore: onScore),
              _ScoreButton(team: second, plus: true, onScore: onScore),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({
    required this.team,
    required this.plus,
    required this.onScore,
  });

  final int team;
  final bool plus;
  final void Function(int team, bool increment) onScore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = courtPaletteOf(team).accent;
    return Semantics(
      button: true,
      label: plus
          ? l10n.pickleballCourtAddPoint(team)
          : l10n.pickleballCourtRemovePoint(team),
      excludeSemantics: true,
      child: Opacity(
        // The minus is a correction, so it is quieter than the plus.
        opacity: plus ? 1 : 0.6,
        child: Material(
          color: accent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onScore(team, plus),
            child: SizedBox(
              width: 56,
              height: 48,
              child: Icon(
                plus ? Icons.add_rounded : Icons.remove_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
