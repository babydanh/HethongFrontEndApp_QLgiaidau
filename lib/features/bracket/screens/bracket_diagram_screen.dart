import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/single_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/double_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';

/// Full-screen bracket diagram for all 3 format types.
/// Navigated to from the "Xem sơ đồ" button in BracketViewScreen.
class BracketDiagramScreen extends StatefulWidget {
  final List<MatchModel> matches;
  final String tournamentId;
  final String bracketType;
  final bool isReferee;
  final bool isReadOnly;

  const BracketDiagramScreen({
    super.key,
    required this.matches,
    required this.tournamentId,
    required this.bracketType,
    this.isReferee = false,
    this.isReadOnly = true,
  });

  @override
  State<BracketDiagramScreen> createState() => _BracketDiagramScreenState();
}

class _BracketDiagramScreenState extends State<BracketDiagramScreen> {
  @override
  void initState() {
    super.initState();
    // Khóa hướng màn hình ngang (Landscape) khi vào sơ đồ để tối ưu hiển thị nhánh đấu
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Lock back to portrait when leaving
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
      body: widget.matches.isEmpty
          ? _buildEmpty(colors)
          : _buildDiagram(colors, isRoundRobin, isDouble, isGroupStageKnockout),
    );
  }

  Widget _buildDiagram(AppColorsExtension colors, bool isRoundRobin, bool isDouble, bool isGroupStageKnockout) {
    if (isRoundRobin) {
      // Round robin — show cross table
      return Padding(
        padding: const EdgeInsets.all(16),
        child: CrossTableView(
          matches: widget.matches,
          tournamentId: widget.tournamentId,
        ),
      );
    }

    if (isDouble) {
      return DoubleElimDiagram(
        matches: widget.matches,
        tournamentId: widget.tournamentId,
        isReferee: widget.isReferee,
        isReadOnly: widget.isReadOnly,
      );
    }

    if (isGroupStageKnockout) {
      // Group stage knockout — show SE diagram (knockout stage only)
      return SingleElimDiagram(
        matches: widget.matches,
        tournamentId: widget.tournamentId,
        isReferee: widget.isReferee,
        isReadOnly: widget.isReadOnly,
      );
    }

    // Default: single elimination
    return SingleElimDiagram(
      matches: widget.matches,
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
