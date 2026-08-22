import 'package:app_quanly_giaidau/core/utils/bracket_generator.dart';
import 'dart:ui';

import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';

class DrawService {
  /// Sinh danh sách các trận đấu tạm thời (preview) để hiển thị trước khi lưu.
  /// Hàm này không có hiệu ứng phụ (side effects), chỉ xử lý logic thuật toán.
  List<MatchModel> generatePreviewMatches({
    required String tournamentId,
    required List<Team> teams,
    required String bracketType,
    int roundCount = 1,
  }) {
    if (teams.length < 2) {
      throw ArgumentError(
        lookupAppLocalizations(
          PlatformDispatcher.instance.locale,
        ).drawService_minTeams,
      );
    }

    final generator = BracketFactory.getGenerator(bracketType);
    return generator.generate(tournamentId, teams, roundCount: roundCount);
  }
}
