import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/teams_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_team_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _singleEliminationDivision = TournamentDivision(
  id: 'div-se',
  name: 'Đơn nam',
  matchType: 'SINGLES',
  bracketType: AppConstants.bracketSingleElimination,
);

const _groupStageDivision = TournamentDivision(
  id: 'div-gsk',
  name: 'Đơn nữ',
  matchType: 'SINGLES',
  bracketType: AppConstants.bracketGroupStageKnockout,
);

Team _team({
  required String id,
  required String divisionId,
  required int seed,
}) {
  return Team(
    id: id,
    name: 'Đội $id',
    seed: seed,
    divisionId: divisionId,
    createdAt: DateTime(2026, 10, 1),
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AppConstants.supportsSeeding', () {
    test('chỉ đúng với vòng bảng + loại trực tiếp', () {
      expect(AppConstants.supportsSeeding('GROUP_STAGE_KNOCKOUT'), isTrue);
      expect(AppConstants.supportsSeeding(' group_stage_knockout '), isTrue);
      expect(AppConstants.supportsSeeding('SINGLE_ELIMINATION'), isFalse);
      expect(AppConstants.supportsSeeding('DOUBLE_ELIMINATION'), isFalse);
      expect(AppConstants.supportsSeeding('ROUND_ROBIN'), isFalse);
      expect(AppConstants.supportsSeeding(null), isFalse);
    });
  });

  group('TeamsTab seed visibility', () {
    testWidgets('ẩn seed ở nội dung loại trực tiếp, hiện ở nội dung vòng bảng', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TeamsTab(
            teams: [
              _team(id: 'se', divisionId: 'div-se', seed: 1),
              _team(id: 'gsk', divisionId: 'div-gsk', seed: 2),
            ],
            selectedDivision: 'all',
            divisions: const [_singleEliminationDivision, _groupStageDivision],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(TeamsTab)))!;
      expect(find.text('Đội se'), findsOneWidget);
      expect(find.text('Đội gsk'), findsOneWidget);
      expect(find.text('${l10n.seedLabel} #1'), findsNothing);
      expect(find.text('${l10n.seedLabel} #2'), findsOneWidget);
    });

    testWidgets('đội thuộc nội dung không có trong danh sách thì ẩn seed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TeamsTab(
            teams: [_team(id: 'orphan', divisionId: 'div-unknown', seed: 4)],
            selectedDivision: 'all',
            divisions: const [_singleEliminationDivision, _groupStageDivision],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(TeamsTab)))!;
      expect(find.text('Đội orphan'), findsOneWidget);
      expect(find.text('${l10n.seedLabel} #4'), findsNothing);
    });
  });

  group('TournamentTeamCard seed label', () {
    testWidgets('mặc định không hiện seed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TournamentTeamCard(
            team: _team(id: 'x', divisionId: 'div-gsk', seed: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentTeamCard)),
      )!;
      expect(find.text('${l10n.seedLabel} #3'), findsNothing);
    });

    testWidgets('showSeed: true hiện seed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TournamentTeamCard(
            team: _team(id: 'x', divisionId: 'div-gsk', seed: 3),
            showSeed: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentTeamCard)),
      )!;
      expect(find.text('${l10n.seedLabel} #3'), findsOneWidget);
    });
  });
}
