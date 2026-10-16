import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/cross_table_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/double_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/single_elim_diagram.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

enum _Kind { single, double, roundRobin }

/// Sơ đồ bracket cho trang công khai: CHỈ sơ đồ, không banner/ô tìm/bộ lọc/thẻ
/// vòng. Chọn đúng loại sơ đồ như `BracketViewScreen`:
/// - loại trực tiếp  -> [SingleElimDiagram]
/// - nhánh thắng-thua -> [DoubleElimDiagram]
/// - vòng tròn       -> [CrossTableView]
/// - vòng bảng + knockout -> chỉ phần knockout.
///
/// Sơ đồ chỉ cuộn ngang (`scrollOnly`), không zoom, không kéo chéo. Chiều cao
/// theo nội dung; cuộn dọc thuộc trang cha.
class PublicBracketView extends StatelessWidget {
  const PublicBracketView({
    super.key,
    required this.tournamentId,
    required this.matches,
    this.divisionId,
    this.bracketType,
  });

  final String tournamentId;
  final String? divisionId;
  final List<MatchModel> matches;
  final String? bracketType;

  _Kind _kindOf(List<MatchModel> all) {
    final raw = (bracketType ?? '').trim().toLowerCase();
    if (all.any(isDoubleEliminationMatch) ||
        raw == 'double_elimination' ||
        raw == 'doubleelimination') {
      return _Kind.double;
    }
    final hasGroup = all.any(isGroupStageMatch);
    final hasKnockout = all.any(isKnockoutMatch);
    if (raw == 'round_robin' || raw == 'roundrobin') return _Kind.roundRobin;
    if (raw == 'group_stage_knockout' || raw == 'groupstageknockout') {
      return _Kind.single;
    }
    if (hasGroup && hasKnockout) return _Kind.single;
    if (hasGroup) return _Kind.roundRobin;
    return _Kind.single;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Text(
            l10n.bracketView_noMatches,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    final kind = _kindOf(matches);
    // Vòng bảng + knockout: chỉ vẽ phần knockout.
    final knockoutOnly = matches.any(isGroupStageMatch) &&
            matches.any(isKnockoutMatch)
        ? matches.where(isKnockoutMatch).toList(growable: false)
        : matches;

    return switch (kind) {
      _Kind.roundRobin => Padding(
        padding: const EdgeInsets.all(12),
        child: CrossTableView(
          matches: matches,
          tournamentId: tournamentId,
          divisionId: divisionId,
        ),
      ),
      _Kind.double => DoubleElimDiagram(
        matches: knockoutOnly,
        tournamentId: tournamentId,
        scrollOnly: true,
      ),
      _Kind.single => SingleElimDiagram(
        matches: knockoutOnly,
        tournamentId: tournamentId,
        scrollOnly: true,
      ),
    };
  }
}

/// Tải trận của một nội dung rồi vẽ [PublicBracketView]. Tách khỏi view để view
/// kiểm thử được mà không cần provider.
class PublicBracketLoader extends ConsumerWidget {
  const PublicBracketLoader({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    this.bracketType,
  });

  final String tournamentId;
  final String? divisionId;
  final String? bracketType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return ref
        .watch(
          bracketMatchesWithDivisionProvider((
            tournamentId: tournamentId,
            divisionId: divisionId,
          )),
        )
        .when(
          data: (matches) => PublicBracketView(
            tournamentId: tournamentId,
            divisionId: divisionId,
            matches: matches,
            bracketType: bracketType,
          ),
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                error.toString().contains('429')
                    ? l10n.bracketView_rateLimited
                    : l10n.bracketView_loadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ),
        );
  }
}
