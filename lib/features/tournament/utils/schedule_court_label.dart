import 'package:flutter/painting.dart';

/// Chip colours for one court on the schedule grid.
typedef CourtChipColors = ({Color background, Color border, Color foreground});

/// Court label shown on the schedule: "Sân 1" -> "1". Display only, the stored
/// name is untouched. A name that is only "Sân" keeps its text.
String formatCourtShortName(String? name) {
  final trimmed = (name ?? '').trim();
  final withoutPrefix = trimmed
      .replaceFirst(RegExp(r'^sân\s+', caseSensitive: false), '')
      .trim();
  return withoutPrefix.isEmpty ? trimmed : withoutPrefix;
}

/// Tints that tell courts apart (same 8 as the web). Rose/red and violet are
/// left out: those hues already mean "live" and "draft" on a card.
const List<CourtChipColors> _courtChipPalette = [
  // sky
  (
    background: Color(0xFFE0F2FE),
    border: Color(0xFF7DD3FC),
    foreground: Color(0xFF0C4A6E),
  ),
  // emerald
  (
    background: Color(0xFFD1FAE5),
    border: Color(0xFF6EE7B7),
    foreground: Color(0xFF064E3B),
  ),
  // orange
  (
    background: Color(0xFFFFEDD5),
    border: Color(0xFFFDBA74),
    foreground: Color(0xFF7C2D12),
  ),
  // teal
  (
    background: Color(0xFFCCFBF1),
    border: Color(0xFF5EEAD4),
    foreground: Color(0xFF134E4A),
  ),
  // fuchsia
  (
    background: Color(0xFFFAE8FF),
    border: Color(0xFFF0ABFC),
    foreground: Color(0xFF701A75),
  ),
  // lime
  (
    background: Color(0xFFECFCCB),
    border: Color(0xFFBEF264),
    foreground: Color(0xFF365314),
  ),
  // cyan
  (
    background: Color(0xFFCFFAFE),
    border: Color(0xFF67E8F9),
    foreground: Color(0xFF164E63),
  ),
  // stone
  (
    background: Color(0xFFE7E5E4),
    border: Color(0xFFD6D3D1),
    foreground: Color(0xFF1C1917),
  ),
];

/// Stable tint for the court at column [index]; wraps after eight courts.
CourtChipColors courtChipColors(int index) {
  final size = _courtChipPalette.length;
  return _courtChipPalette[((index % size) + size) % size];
}
