import 'dart:math' as math;

import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_view.dart';
import 'package:flutter/material.dart';

/// Score tab body for pickleball: the court plus the scoring block.
///
/// Portrait: stacked in a scroll view so the scoring block keeps the height it
/// needs on a short phone. Landscape: court on the left, scoring block on the
/// right (scrollable), only when the right side is wide enough for the score
/// digits to stay readable; otherwise the portrait layout is used.
///
/// The court and the scoring block keep their State when the screen rotates
/// (GlobalKeys), so a drag or a save in progress survives it.
class CourtScoreLayout extends StatefulWidget {
  const CourtScoreLayout({
    super.key,
    required this.court,
    required this.scorePanel,
  });

  /// Height the scoring block needs without overflowing in portrait, at the
  /// default text scale (measured with the real `PickleballPanel`).
  static const portraitPanelMinHeight = 440.0;

  /// Narrowest scoring block that still shows the score digits at >= 28dp
  /// next to the court (measured: 304dp gives ~10dp digits, 384dp ~46dp).
  static const sideBySidePanelMinWidth = 360.0;
  static const _landscapePanelMinHeight = 260.0;

  /// A stacked court is never wider than this, so on a wide short screen it
  /// does not grow taller than the scoring block.
  static const _stackedCourtMaxWidth = 420.0;
  static const _courtMinWidth = 240.0;
  static const _gap = 8.0;

  final Widget court;
  final Widget scorePanel;

  @override
  State<CourtScoreLayout> createState() => _CourtScoreLayoutState();
}

class _CourtScoreLayoutState extends State<CourtScoreLayout> {
  final _courtKey = GlobalKey();
  final _panelKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // Fonts are scaled by the user's text size, so the panel needs more room.
    final textScale = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(14) / 14,
    );
    final court = KeyedSubtree(key: _courtKey, child: widget.court);
    final panel = KeyedSubtree(key: _panelKey, child: widget.scorePanel);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitsSideBySide =
            constraints.maxWidth >=
            CourtScoreLayout._courtMinWidth +
                CourtScoreLayout._gap +
                CourtScoreLayout.sideBySidePanelMinWidth * textScale;
        return landscape && fitsSideBySide
            ? _sideBySide(constraints, court, panel, textScale)
            : _stacked(constraints, court, panel, textScale, landscape);
      },
    );
  }

  Widget _stacked(
    BoxConstraints constraints,
    Widget court,
    Widget panel,
    double textScale,
    bool landscape,
  ) {
    final courtWidth = math.min(
      constraints.maxWidth,
      CourtScoreLayout._stackedCourtMaxWidth,
    );
    final panelMinHeight = landscape
        ? CourtScoreLayout._landscapePanelMinHeight
        : CourtScoreLayout.portraitPanelMinHeight;
    final needed =
        PickleballCourtView.naturalHeight(courtWidth) +
        CourtScoreLayout._gap +
        panelMinHeight * textScale;
    final height = constraints.hasBoundedHeight
        ? math.max(constraints.maxHeight, needed)
        : needed;
    return SingleChildScrollView(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Center(
              child: SizedBox(width: courtWidth, child: court),
            ),
            const SizedBox(height: CourtScoreLayout._gap),
            Expanded(child: panel),
          ],
        ),
      ),
    );
  }

  Widget _sideBySide(
    BoxConstraints constraints,
    Widget court,
    Widget panel,
    double textScale,
  ) {
    final panelMinWidth = CourtScoreLayout.sideBySidePanelMinWidth * textScale;
    final courtWidth = math.min(
      math.max(
        CourtScoreLayout._courtMinWidth,
        (constraints.maxWidth - CourtScoreLayout._gap) / 2,
      ),
      constraints.maxWidth - CourtScoreLayout._gap - panelMinWidth,
    );
    final panelMinHeight =
        CourtScoreLayout._landscapePanelMinHeight * textScale;
    final panelHeight = constraints.hasBoundedHeight
        ? math.max(constraints.maxHeight, panelMinHeight)
        : panelMinHeight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: courtWidth, child: court),
        const SizedBox(width: CourtScoreLayout._gap),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(height: panelHeight, child: panel),
          ),
        ),
      ],
    );
  }
}
