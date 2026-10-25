import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/stage_round_config_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock repository giải đấu: trả stage của hạng mục, ghi lại lần vá
/// `roundConfig` của stage (PATCH /tournaments/stages/:stageId).
class _StageRepo implements ITournamentRepository {
  _StageRepo(this.stages);

  final List<Map<String, dynamic>> stages;
  final stagePatches = <({String stageId, Map<String, dynamic> roundConfig})>[];

  @override
  Future<List<Map<String, dynamic>>> getDivisionStages(
    String tournamentId, {
    required String divisionId,
  }) async => stages;

  @override
  Future<void> updateStageRoundConfig(
    String tournamentId,
    String stageId,
    Map<String, dynamic> roundConfig,
  ) async {
    stagePatches.add((
      stageId: stageId,
      roundConfig: Map<String, dynamic>.of(roundConfig),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock repository quản lý giải cho test nút mở từ thẻ hạng mục.
class _MgmtRepo implements TournamentManagementRepository {
  _MgmtRepo(this.division);

  final Map<String, dynamic> division;

  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async => [
    division,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'City Badminton Cup',
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
  Map<String, dynamic>? roundConfig,
}) => {
  'id': 'div-1',
  'name': 'Đơn nam',
  'matchType': 'SINGLES',
  'bracketType': bracketType,
  'roundConfig': roundConfig,
};

/// Luật gốc hạng mục (Chuẩn cầu lông 2×21, trần 30): base resolve cho cả
/// thân trên của `roundConfig` stage lẫn giá trị khởi tạo của từng vòng.
const _strictDivisionRules = {
  'kind': 'BADMINTON',
  'mode': 'STRICT',
  'setsToWin': 2,
  'pointsPerSet': 21,
  'winByTwo': true,
  'maxPoints': 30,
  'roundsToPlay': 1,
  'tiebreakerMode': 'split',
};

/// Stage loại trực tiếp 2 vòng (4 đội): vòng 1 (bán kết) có 2 trận, vòng 2
/// (chung kết) có 1 trận.
Map<String, dynamic> _seStage({Map<String, dynamic>? roundConfig}) => {
  'id': 'stage-1',
  'name': 'Knockout',
  'type': 'SINGLE_ELIMINATION',
  'order': 1,
  'venueId': 'venue-stage',
  'scheduledDate': '2026-06-01T02:00:00.000Z',
  'roundConfig': roundConfig,
  'groups': [
    {
      'id': 'g-1',
      'name': 'Winners',
      'matches': [
        {'id': 'm-1', 'roundNumber': 1},
        {'id': 'm-2', 'roundNumber': 1},
        {'id': 'm-3', 'roundNumber': 2},
      ],
    },
  ],
};

/// Stage vòng bảng (không cần trận: danh sách vòng dựng theo cấu hình lượt).
Map<String, dynamic> _rrStage({Map<String, dynamic>? roundConfig}) => {
  'id': 'stage-rr',
  'name': 'Bảng A',
  'type': 'ROUND_ROBIN',
  'order': 1,
  'venueId': 'venue-rr',
  'roundConfig': roundConfig,
  'groups': [
    {
      'id': 'g-1',
      'name': 'Bảng A',
      'matches': [
        {'id': 'm-1', 'roundNumber': 1},
      ],
    },
  ],
};

Widget _app(
  _StageRepo stage, {
  _MgmtRepo? mgmt,
  List<MatchModel> matches = const [],
  required Future<bool?> Function(BuildContext context) openSheet,
}) => ProviderScope(
  overrides: [
    tournamentRepositoryProvider.overrideWithValue(stage),
    if (mgmt != null)
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
    // Ép đồng hồ 24 giờ để nhập giờ trong picker xác định (máy CI/máy dev
    // có thể đặt 12 giờ — nhập '9' buổi chiều sẽ ra 21).
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const ValueKey('open-sheet'),
            onPressed: () => openSheet(context).then((_) {}),
            child: const Text('Mở sheet'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
}

/// Chọn một vòng trong dropdown theo tên hiển thị.
Future<void> _selectRound(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('stage-round-select')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

/// Đặt giờ mặc định qua picker thật: ngày 2 của tháng hiện tại, [hour]:30
/// (time picker mở ở chế độ nhập — cùng initialEntryMode của sheet).
Future<void> _pickTime(WidgetTester tester, int hour) async {
  await tester.tap(find.byKey(const ValueKey('stage-round-pick-time')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(CalendarDatePicker),
      matching: find.text('2'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(Dialog), matching: find.text('OK')),
  );
  await tester.pumpAndSettle();
  final fields = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(fields.first, '$hour');
  // "Next" trên bàn phím commit giờ (onEditingComplete của picker).
  await tester.testTextInput.receiveAction(TextInputAction.next);
  await tester.pumpAndSettle();
  await tester.enterText(fields.last, '30');
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(Dialog), matching: find.text('OK')),
  );
  await tester.pumpAndSettle();
}

/// Trang màn Quản lý giải với thẻ hạng mục thật: nút "Cấu hình từng vòng"
/// nằm trong menu của thẻ, mở sheet trong modal route thật.
Widget _sectionApp(
  _StageRepo stage,
  _MgmtRepo mgmt,
  List<MatchModel> matches,
) => ProviderScope(
  overrides: [
    tournamentRepositoryProvider.overrideWithValue(stage),
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
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
    home: Scaffold(
      body: TournamentManagementDivisionsSection(tournament: _tournament()),
    ),
  ),
);

MatchModel _divisionMatch() => MatchModel.fromJson({
  'id': 'm-1',
  'tournamentId': 'tournament-1',
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': 'A',
  'team2Name': 'B',
  'divisionId': 'div-1',
}, 'm-1');

void main() {
  testWidgets(
    'TC-WP-02-04: sửa giờ mặc định vòng 2 — PATCH stages kèm scheduled_date mới',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stage = _StageRepo([_seStage()]);
      await _open(
        tester,
        _app(
          stage,
          openSheet: (context) => StageRoundConfigSheet.show(
            context,
            tournament: _tournament(),
            division: _division(roundConfig: _strictDivisionRules),
          ),
        ),
      );

      // Hai vòng của sơ đồ 4 đội: bán kết (vòng 1) và chung kết (vòng 2).
      await _selectRound(tester, 'Chung kết');
      await _pickTime(tester, 8);
      await tester.tap(find.byKey(const ValueKey('stage-round-save')));
      await tester.pumpAndSettle();

      final patch = stage.stagePatches.single;
      expect(patch.stageId, 'stage-1');
      final roundConfig = patch.roundConfig;
      final rounds = roundConfig['rounds'] as Map<String, dynamic>;
      // Picker mở ở tháng của giờ sẵn có của vòng (fixture 2026-06-01 giờ
      // địa phương) — chọn ngày 2 trong tháng đó.
      final initialLocal = DateTime.parse('2026-06-01T02:00:00.000Z').toLocal();
      final expectedTime = DateTime(
        initialLocal.year,
        initialLocal.month,
        2,
        8,
        30,
      ).toUtc().toIso8601String();
      final round2 = rounds['2'] as Map<String, dynamic>;
      expect(round2['scheduled_date'], expectedTime);
      // Không nhập sân: rơi về sân mặc định của stage (prefill như Web
      // handleOpenRoundModal — stage.venueId), vẫn gửi trường venue_id.
      expect(round2['venue_id'], 'venue-stage');
      expect(round2['custom_notes'], isNull);
      // Luật vòng rơi về luật gốc hạng mục (không có override đã lưu).
      expect(round2['setsToWin'], 2);
      expect(round2['pointsPerSet'], 21);
      expect(round2['winByTwo'], true);
      expect(round2['maxPoints'], 30);
      // Thân trên stage giữ luật gốc hạng mục + đầy đủ tiebreakerMode/roundsToPlay.
      expect(roundConfig['setsToWin'], 2);
      expect(roundConfig['pointsPerSet'], 21);
      expect(roundConfig['tiebreakerMode'], 'split');
      expect(roundConfig['roundsToPlay'], 1);
      expect(roundConfig['kind'], 'BADMINTON');
      // Chỉ vòng 2 được ghi; vòng 1 chưa có override thì không thêm.
      expect(rounds.containsKey('1'), isFalse);
      // Lưu xong sheet đóng.
      expect(find.byKey(const ValueKey('stage-round-save')), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-02-04: lưu vòng có override — luật vòng thay rounds[key], giữ nguyên key khác của stage',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final savedRound = {
        'kind': 'BADMINTON',
        'setsToWin': 2,
        'pointsPerSet': 21,
        'winByTwo': true,
        'maxPoints': 30,
        'venue_id': 'venue-old',
        'scheduled_date': '2026-06-10T01:00:00.000Z',
        'custom_notes': 'ưu tiên sân trung tâm',
      };
      final stage = _StageRepo([
        _seStage(
          roundConfig: {
            'kind': 'BADMINTON',
            'mode': 'STRICT',
            'setsToWin': 2,
            'pointsPerSet': 21,
            'winByTwo': true,
            'rounds': {
              '1': savedRound,
              '3': {'pointsPerSet': 11},
            },
          },
        ),
      ]);
      await _open(
        tester,
        _app(
          stage,
          openSheet: (context) => StageRoundConfigSheet.show(
            context,
            tournament: _tournament(),
            division: _division(roundConfig: _strictDivisionRules),
          ),
        ),
      );

      await _selectRound(tester, 'Bán kết');
      // Prefill từ override đã lưu của vòng 1.
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('stage-round-venue')))
            .controller!
            .text,
        'venue-old',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('stage-round-note')))
            .controller!
            .text,
        'ưu tiên sân trung tâm',
      );
      await tester.enterText(
        find.byKey(const ValueKey('stage-round-points-per-set')),
        '15',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stage-round-save')));
      await tester.pumpAndSettle();

      final roundConfig = stage.stagePatches.single.roundConfig;
      final rounds = roundConfig['rounds'] as Map<String, dynamic>;
      final round1 = rounds['1'] as Map<String, dynamic>;
      expect(round1['pointsPerSet'], 15);
      expect(round1['format']['pointsPerGame'], 15);
      expect(round1['venue_id'], 'venue-old');
      expect(round1['custom_notes'], 'ưu tiên sân trung tâm');
      expect(round1['scheduled_date'], '2026-06-10T01:00:00.000Z');
      // Vòng khác không đụng tới.
      expect((rounds['3'] as Map<String, dynamic>)['pointsPerSet'], 11);
      // Thân trên giữ key cũ của stage (mode STRICT) qua spread.
      expect(roundConfig['mode'], 'STRICT');
      expect(roundConfig['kind'], 'BADMINTON');
      expect(roundConfig['pointsPerSet'], 21);
    },
  );

  testWidgets(
    'TC-WP-02-04: vòng bảng dùng chung (vòng 0) — venue/giờ/ghi chú ghi ở thân trên, rounds giữ nguyên',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stage = _StageRepo([
        _rrStage(
          roundConfig: {
            'kind': 'BADMINTON',
            'rounds': {
              'leg_1': {'pointsPerSet': 11},
            },
          },
        ),
      ]);
      await _open(
        tester,
        _app(
          stage,
          openSheet: (context) => StageRoundConfigSheet.show(
            context,
            tournament: _tournament(),
            division: _division(
              bracketType: 'ROUND_ROBIN',
              roundConfig: {
                ..._strictDivisionRules,
                'groupsConfig': {'roundsToPlay': 2},
              },
            ),
          ),
        ),
      );

      // Vòng bảng 2 lượt: vòng 0 + Lượt 1 + Lượt 2.
      await _selectRound(tester, 'Vòng bảng dùng chung');
      await tester.enterText(
        find.byKey(const ValueKey('stage-round-venue')),
        'venue-main',
      );
      await tester.enterText(
        find.byKey(const ValueKey('stage-round-note')),
        'gọi đồng loạt 8h',
      );
      await _pickTime(tester, 9);
      await tester.tap(find.byKey(const ValueKey('stage-round-save')));
      await tester.pumpAndSettle();

      final roundConfig = stage.stagePatches.single.roundConfig;
      final now = DateTime.now();
      expect(
        roundConfig['scheduled_date'],
        DateTime(now.year, now.month, 2, 9, 30).toUtc().toIso8601String(),
      );
      expect(roundConfig['venue_id'], 'venue-main');
      expect(roundConfig['custom_notes'], 'gọi đồng loạt 8h');
      // rounds giữ nguyên leg_1 (override từng lượt không bị xoá).
      expect((roundConfig['rounds'] as Map<String, dynamic>)['leg_1'], {
        'pointsPerSet': 11,
      });
      expect(roundConfig['kind'], 'BADMINTON');
    },
  );

  testWidgets(
    'TC-WP-02-04: lượt vòng bảng lưu dưới key leg_N, không đè thân trên',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stage = _StageRepo([_rrStage()]);
      await _open(
        tester,
        _app(
          stage,
          openSheet: (context) => StageRoundConfigSheet.show(
            context,
            tournament: _tournament(),
            division: _division(
              bracketType: 'ROUND_ROBIN',
              roundConfig: {
                ..._strictDivisionRules,
                'groupsConfig': {'roundsToPlay': 2},
              },
            ),
          ),
        ),
      );

      await _selectRound(tester, 'Lượt 2');
      await tester.enterText(
        find.byKey(const ValueKey('stage-round-venue')),
        'venue-leg2',
      );
      await tester.tap(find.byKey(const ValueKey('stage-round-save')));
      await tester.pumpAndSettle();

      final roundConfig = stage.stagePatches.single.roundConfig;
      final rounds = roundConfig['rounds'] as Map<String, dynamic>;
      expect(
        (rounds['leg_2'] as Map<String, dynamic>)['venue_id'],
        'venue-leg2',
      );
      // Không phải vòng 0: thân trên không nhận venue_id của lượt.
      expect(roundConfig.containsKey('venue_id'), isFalse);
    },
  );

  testWidgets(
    'TC-WP-02-04: giải Lite — khối luật ẩn, lưu vẫn kèm luật gốc và sân/giờ/ghi chú',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stage = _StageRepo([_seStage()]);
      await _open(
        tester,
        _app(
          stage,
          openSheet: (context) => StageRoundConfigSheet.show(
            context,
            tournament: _tournament(),
            division: _division(
              roundConfig: {
                'kind': 'BADMINTON',
                'mode': 'LITE',
                'setsToWin': 1,
                'pointsPerSet': 11,
                'winByTwo': true,
                'maxPoints': 11,
              },
            ),
          ),
        ),
      );

      // Banner Lite hiện, khối luật ẩn.
      expect(find.textContaining('Chế độ Tự do (Lite)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('stage-round-sets-to-win')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('stage-round-note')),
        'nhập tự do',
      );
      await tester.tap(find.byKey(const ValueKey('stage-round-save')));
      await tester.pumpAndSettle();

      final rounds =
          stage.stagePatches.single.roundConfig['rounds']
              as Map<String, dynamic>;
      final round1 = rounds['1'] as Map<String, dynamic>;
      expect(round1['setsToWin'], 1);
      expect(round1['pointsPerSet'], 11);
      expect(round1['custom_notes'], 'nhập tự do');
    },
  );

  testWidgets(
    'TC-WP-02-04: stage Swiss không có vòng riêng — sheet báo rỗng và không lưu',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stage = _StageRepo([
        {
          'id': 'stage-swiss',
          'name': 'Swiss',
          'type': 'SWISS',
          'order': 1,
          'roundConfig': {},
          'groups': [],
        },
      ]);
      await _open(
        tester,
        _app(
          stage,
          openSheet: (context) => StageRoundConfigSheet.show(
            context,
            tournament: _tournament(),
            division: _division(bracketType: 'SWISS'),
          ),
        ),
      );

      expect(
        find.text('Hạng mục này không có vòng nào để cấu hình.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('stage-round-save')),
            )
            .onPressed,
        isNull,
      );
      expect(stage.stagePatches, isEmpty);
    },
  );

  testWidgets(
    'TC-WP-02-04: hạng mục có sơ đồ thì menu thẻ có mục cấu hình từng vòng, mở được sheet',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stage = _StageRepo([_seStage()]);
      await tester.pumpWidget(
        _sectionApp(
          stage,
          _MgmtRepo(_division(roundConfig: _strictDivisionRules)),
          [_divisionMatch()],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Cấu hình từng vòng'), findsOneWidget);
      await tester.tap(find.text('Cấu hình từng vòng'));
      await tester.pumpAndSettle();

      // Sheet mở với danh sách vòng của stage: mở dropdown xem đủ 2 vòng
      // (dropdown đóng chỉ render item đang chọn).
      expect(find.byKey(const ValueKey('stage-round-select')), findsOneWidget);
      expect(find.text('Bán kết'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('stage-round-select')));
      await tester.pumpAndSettle();
      expect(find.text('Chung kết'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-WP-02-04: hạng mục chưa có sơ đồ thì menu ẩn mục cấu hình từng vòng',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stage = _StageRepo(const []);
      await tester.pumpWidget(
        _sectionApp(
          stage,
          _MgmtRepo(_division(roundConfig: _strictDivisionRules)),
          const [],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Cấu hình từng vòng'), findsNothing);
    },
  );
}
