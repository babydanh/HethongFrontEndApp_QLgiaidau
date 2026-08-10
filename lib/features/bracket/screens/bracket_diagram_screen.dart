import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/single_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/double_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';

/// Full-screen bracket diagram for all 3 format types.
/// Navigated to from the "Xem sơ đồ" button in BracketViewScreen.
/// Always fetches bracket data fresh from the repository to ensure
/// nextMatchId connectivity is correct (merged flat data may break links).
class BracketDiagramScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? divisionId;
  final String bracketType;
  final bool isReferee;
  final bool isReadOnly;

  const BracketDiagramScreen({
    super.key,
    required this.tournamentId,
    this.divisionId,
    required this.bracketType,
    this.isReferee = false,
    this.isReadOnly = true,
  });

  @override
  ConsumerState<BracketDiagramScreen> createState() => _BracketDiagramScreenState();
}

class _BracketDiagramScreenState extends ConsumerState<BracketDiagramScreen> {
  List<MatchModel>? _bracketMatches;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _fetchBracket();
  }

  Future<void> _fetchBracket() async {
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final matches = await repo.getBracketMatches(
        widget.tournamentId,
        divisionId: widget.divisionId,
      );
      if (mounted) {
        setState(() {
          _bracketMatches = matches;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRoundRobin = widget.bracketType == AppConstants.bracketRoundRobin;
    final isDouble = widget.bracketType == AppConstants.bracketDoubleElimination;
    final isGroupStageKnockout = widget.bracketType == AppConstants.bracketGroupStageKnockout;

    final String title;
    if (isRoundRobin) {
      title = 'Bảng chéo vòng tròn';
    } else if (isDouble) {
      title = 'Sơ đồ nhánh thắng / thua';
    } else if (isGroupStageKnockout) {
      title = 'Sơ đồ vòng loại';
    } else {
      title = 'Sơ đồ thi đấu';
    }

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Quay lại',
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pinch_rounded, size: 12, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Kéo & thu phóng',
                    style: TextStyle(fontSize: 9, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildEmpty(colors)
              : (_bracketMatches == null || _bracketMatches!.isEmpty)
                  ? _buildEmpty(colors)
                  : _buildDiagram(colors, isRoundRobin, isDouble, isGroupStageKnockout),
    );
  }

  Widget _buildDiagram(AppColorsExtension colors, bool isRoundRobin, bool isDouble, bool isGroupStageKnockout) {
    final matches = _bracketMatches!;

    if (isRoundRobin) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: CrossTableView(
          matches: matches,
          tournamentId: widget.tournamentId,
        ),
      );
    }

    if (isDouble) {
      return DoubleElimDiagram(
        matches: matches,
        tournamentId: widget.tournamentId,
        isReferee: widget.isReferee,
        isReadOnly: widget.isReadOnly,
      );
    }

    // For group_stage_knockout: filter only knockout stage matches.
    // The knockout stage may itself be a double-elimination bracket (the
    // /bracket API reports stage.type = DOUBLE_ELIMINATION), so pick the
    // diagram type from the actual match data, not the top-level bracketType.
    if (isGroupStageKnockout) {
      final knockoutMatches = matches.where(isKnockoutMatch).toList();
      final isDouble = knockoutMatches.any(isDoubleEliminationMatch);
      if (isDouble) {
        return DoubleElimDiagram(
          matches: knockoutMatches,
          tournamentId: widget.tournamentId,
          isReferee: widget.isReferee,
          isReadOnly: widget.isReadOnly,
        );
      }
      return SingleElimDiagram(
        matches: knockoutMatches,
        tournamentId: widget.tournamentId,
        isReferee: widget.isReferee,
        isReadOnly: widget.isReadOnly,
      );
    }

    // Default: single elimination — use all matches
    return SingleElimDiagram(
      matches: matches,
      tournamentId: widget.tournamentId,
      isReferee: widget.isReferee,
      isReadOnly: widget.isReadOnly,
    );
  }

  Widget _buildEmpty(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 72,
            color: colors.textMuted.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có sơ đồ thi đấu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy hoàn tất bốc thăm để tạo sơ đồ',
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
