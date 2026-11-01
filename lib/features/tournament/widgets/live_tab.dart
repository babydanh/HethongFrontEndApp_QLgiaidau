import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_accordion.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:flutter/material.dart';

/// "Đang diễn ra" tab: the match board (live box + one box per round). With
/// several divisions each one opens its own board under its row.
class LiveTab extends StatefulWidget {
  final String tournamentId;
  final bool isLite;
  final List<TournamentDivision> divisions;
  final String? selectedDivisionId;
  final ValueChanged<TournamentDivision>? onSelectDivision;

  /// Organisers see match codes and the score / schedule buttons.
  final bool canManage;

  const LiveTab({
    super.key,
    required this.tournamentId,
    this.isLite = false,
    this.divisions = const [],
    this.selectedDivisionId,
    this.onSelectDivision,
    this.canManage = false,
  });

  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> {
  String? _selectedDivisionId;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _selectedDivisionId =
        widget.selectedDivisionId ??
        (widget.divisions.isNotEmpty ? widget.divisions.first.id : null);
  }

  @override
  void didUpdateWidget(covariant LiveTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDivisionId != oldWidget.selectedDivisionId &&
        widget.selectedDivisionId != null) {
      setState(() {
        _selectedDivisionId = widget.selectedDivisionId;
        _expanded = true;
      });
    }
  }

  Widget _board(String? divisionId) => ResultsMatchBoard(
    tournamentId: widget.tournamentId,
    isLite: widget.isLite,
    canManage: widget.canManage,
    divisionId: divisionId,
  );

  void _tapDivision(TournamentDivision division) {
    setState(() {
      if (_selectedDivisionId == division.id) {
        _expanded = !_expanded;
      } else {
        _selectedDivisionId = division.id;
        _expanded = true;
      }
    });
    widget.onSelectDivision?.call(division);
  }

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(12, 12, 12, 140);
    if (widget.divisions.length < 2) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: padding,
        children: [_board(null)],
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 140),
      children: [
        DivisionAccordion(
          divisions: widget.divisions,
          selectedDivisionId: _selectedDivisionId,
          expanded: _expanded,
          contentBuilder: (division) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _board(division.id),
          ),
          onTapDivision: _tapDivision,
        ),
      ],
    );
  }
}
