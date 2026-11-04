import 'package:flutter/material.dart';

// Court palette follows the Web mock; it is a fixed "painted court" look and
// does not change with the app theme.
const courtColor = Color(0xFF8EBDF0);
const courtNetColor = Color(0xFF94A3B8);
const courtNavy = Color(0xFF12306B);
const courtServingChipColor = Color(0xFFFFF7D1);
const courtBallColor = Color(0xFFFACC15);
const courtLineColor = Colors.white;
const courtLineWidth = 3.0;

/// Colors of one team's half: the cells, the kitchen strip next to the net and
/// the accent of its plus button. They follow the team, not the side, so a team
/// keeps its color when the ends are switched.
class CourtTeamPalette {
  const CourtTeamPalette({
    required this.court,
    required this.kitchen,
    required this.accent,
  });

  final Color court;
  final Color kitchen;
  final Color accent;
}

// Team 1 is orange and team 2 is blue, as on the referee's scoreboard.
const courtTeam1 = CourtTeamPalette(
  court: Color(0xFFF6C3A1),
  kitchen: Color(0xFFFBDCC6),
  accent: Color(0xFFEA580C),
);

const courtTeam2 = CourtTeamPalette(
  court: Color(0xFF8EBDF0),
  kitchen: Color(0xFFB7D4F7),
  accent: Color(0xFF2979FF),
);

CourtTeamPalette courtPaletteOf(int team) =>
    team == 1 ? courtTeam1 : courtTeam2;
