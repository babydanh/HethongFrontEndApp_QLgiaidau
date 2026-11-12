import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Mgmt implements TournamentManagementRepository {
  _Mgmt(this.division);
  final Map<String, dynamic> division;
  final patches = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async => [
    division,
  ];

  @override
  Future<Map<String, dynamic>> updateDivisionConfig(
    String id,
    String divisionId,
    Map<String, dynamic> payload,
  ) async {
    patches.add(payload);
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Stages implements ITournamentRepository {
  int stageCalls = 0;
  int stagePatches = 0;

  @override
  Future<List<Map<String, dynamic>>> getDivisionStages(
    String tournamentId, {
    required String divisionId,
  }) async {
    stageCalls++;
    return [
      {
        'id': 'stage-1',
        'type': 'SINGLE_ELIMINATION',
        'groups': [
          {
            'name': 'W',
            'matches': [
              {'roundNumber': 1},
            ],
          },
        ],
      },
    ];
  }

  @override
  Future<void> updateStageRoundConfig(
    String tournamentId,
    String stageId,
    Map<String, dynamic> roundConfig,
  ) async => stagePatches++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Cup',
  'sport': 'badminton',
  'format': 'singles',
  'bracketType': 'single_elimination',
  'status': 'IN_PROGRESS',
  'maxTeams': 16,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

Map<String, dynamic> _division({
  String bracketType = 'SINGLE_ELIMINATION',
  Object? maxParticipants = 4,
  Map<String, dynamic>? roundConfig,
}) => {
  'id': 'div-1',
  'name': 'Đơn nam',
  'matchType': 'SINGLES',
  'bracketType': bracketType,
  'maxParticipants': maxParticipants,
  'roundConfig': roundConfig,
};

MatchModel _match() => MatchModel.fromJson({
  'id': 'm-1',
  'tournamentId': 'tournament-1',
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': 'A',
  'team2Name': 'B',
  'divisionId': 'div-1',
}, 'm-1');

Future<void> _pump(
  WidgetTester tester,
  _Mgmt mgmt,
  _Stages stages, {
  List<MatchModel> matches = const [],
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(stages),
        tournamentManagementRepositoryProvider.overrideWithValue(mgmt),
        matchesProvider(
          'tournament-1',
        ).overrideWith((ref) => Stream.value(matches)),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TournamentManagementDivisionsSection(tournament: _tournament()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Mở menu ⋮ của thẻ hạng mục (nếu có nút Luật theo vòng thì bấm).
Future<bool> _openRoundsFromMenu(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<String>).first);
  await tester.pumpAndSettle();
  final item = find.text('Cấu hình từng vòng');
  if (item.evaluate().isEmpty) {
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    return false;
  }
  await tester.tap(item);
  await tester.pumpAndSettle();
  return true;
}

void main() {
  testWidgets(
    'TC-ROUND-DRAFT-10: chưa có sơ đồ — hiện vòng dự kiến, lưu Tứ kết ghi rounds[2] và giữ khóa cũ',
    (tester) async {
      final mgmt = _Mgmt(
        _division(
          maxParticipants: 4,
          roundConfig: {
            'kind': 'BADMINTON',
            'custom': 'giu-lai',
            'rounds': {
              '1': {'setsToWin': 1},
            },
          },
        ),
      );
      final stages = _Stages();
      await _pump(tester, mgmt, stages);
      expect(await _openRoundsFromMenu(tester), isTrue);

      await tester.tap(find.byKey(const ValueKey('stage-round-select')));
      await tester.pumpAndSettle();
      expect(find.text('Bán kết'), findsWidgets);
      await tester.tap(find.text('Chung kết').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stage-round-save')));
      await tester.pumpAndSettle();

      expect(stages.stageCalls, 0);
      expect(stages.stagePatches, 0);
      final roundConfig = mgmt.patches.single['roundConfig'] as Map;
      expect(roundConfig['custom'], 'giu-lai');
      final rounds = roundConfig['rounds'] as Map;
      expect(rounds.containsKey('2'), isTrue);
      expect((rounds['1'] as Map)['setsToWin'], 1);
    },
  );

  testWidgets(
    'TC-ROUND-DRAFT-11: lượt ghi rounds[leg_1], vòng bảng dùng chung ghi lên gốc',
    (tester) async {
      final mgmt = _Mgmt(
        _division(
          bracketType: 'ROUND_ROBIN',
          roundConfig: {'kind': 'BADMINTON', 'custom': 'giu-lai'},
        ),
      );
      await _pump(tester, mgmt, _Stages());
      expect(await _openRoundsFromMenu(tester), isTrue);

      // Vòng đầu tiên = vòng bảng dùng chung: ghi lên gốc roundConfig.
      await tester.enterText(
        find.byKey(const ValueKey('stage-round-venue')),
        'san-1',
      );
      await tester.tap(find.byKey(const ValueKey('stage-round-save')));
      await tester.pumpAndSettle();
      final shared = mgmt.patches.single['roundConfig'] as Map;
      expect(shared['venue_id'], 'san-1');
      expect(shared['custom'], 'giu-lai');

      await _openRoundsFromMenu(tester);
      await tester.tap(find.byKey(const ValueKey('stage-round-select')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lượt 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stage-round-save')));
      await tester.pumpAndSettle();
      final leg = mgmt.patches.last['roundConfig'] as Map;
      expect((leg['rounds'] as Map).containsKey('leg_1'), isTrue);
      expect(leg['custom'], 'giu-lai');
    },
  );

  testWidgets(
    'TC-ROUND-DRAFT-12: đã có sơ đồ — vẫn dùng stage thật, không ghi hạng mục',
    (tester) async {
      final mgmt = _Mgmt(_division());
      final stages = _Stages();
      await _pump(tester, mgmt, stages, matches: [_match()]);
      expect(await _openRoundsFromMenu(tester), isTrue);
      await tester.tap(find.byKey(const ValueKey('stage-round-save')));
      await tester.pumpAndSettle();
      expect(stages.stageCalls, 1);
      expect(stages.stagePatches, 1);
      expect(mgmt.patches, isEmpty);
    },
  );

  testWidgets(
    'TC-ROUND-DRAFT-13: chưa đặt số đội hoặc Thụy Sĩ — ẩn mục, không lỗi',
    (tester) async {
      for (final division in [
        _division(maxParticipants: null),
        _division(bracketType: 'SWISS', maxParticipants: 16),
      ]) {
        await _pump(tester, _Mgmt(division), _Stages());
        expect(await _openRoundsFromMenu(tester), isFalse);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
