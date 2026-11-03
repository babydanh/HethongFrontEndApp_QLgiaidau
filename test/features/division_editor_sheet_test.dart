import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/sport_rule_presets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_editor_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock repository quản lý giải: ghi lại payload tạo/sửa hạng mục.
class _MgmtRepo implements TournamentManagementRepository {
  final created = <Map<String, dynamic>>[];
  final updated = <({String id, Map<String, dynamic> payload})>[];

  @override
  Future<Map<String, dynamic>> createDivision(
    String id,
    Map<String, dynamic> payload,
  ) async {
    created.add(Map<String, dynamic>.of(payload));
    return {'id': 'new-1', ...payload};
  }

  @override
  Future<Map<String, dynamic>> updateDivision(
    String divisionId,
    Map<String, dynamic> payload,
  ) async {
    updated.add((id: divisionId, payload: Map<String, dynamic>.of(payload)));
    return {'id': divisionId, ...payload};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock repository giải đấu: ghi lại lần vá roundConfig của stage Swiss.
class _StageRepo implements ITournamentRepository {
  final stagePatches = <({String stageId, Map<String, dynamic> roundConfig})>[];

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

Tournament _tournament() => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION',
  'maxTeams': 32,
  'entryFee': '50000',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

Map<String, dynamic> _swissDivision() => {
  'id': 'div-1',
  'name': 'Swiss 16 đội',
  'matchType': 'DOUBLES',
  'bracketType': 'SWISS',
  'maxParticipants': 16,
  'roundConfig': {
    'swiss': {
      'totalRounds': 5,
      'tiebreakOrder': ['BUCHHOLZ'],
      'firstRoundPairing': 'SEED',
    },
  },
  '_count': {'participants': 12},
};

SwissStageInfo _swissStage() {
  final raw = _swissDivision()['roundConfig'] as Map<String, dynamic>;
  return SwissStageInfo(
    stageId: 'stage-1',
    config: SwissConfig.fromJson(raw['swiss'] as Map<String, dynamic>),
    rawRoundConfig: raw,
  );
}

/// Trang chủ có nút mở sheet: sheet chạy trong modal route thật nên các nút
/// bấm được như chạy thật (pattern chung của các sheet test trong repo).
/// Tham số mở sheet do `openSheet` tự chốt (tạo mới hay sửa, có khoá không).
Widget _app(
  _MgmtRepo mgmt,
  _StageRepo stage,
  Future<bool?> Function(BuildContext context) openSheet,
) => ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWithValue(mgmt),
    tournamentRepositoryProvider.overrideWithValue(stage),
  ],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const ValueKey('open-sheet'),
            onPressed: () => openSheet(
              context,
            ).then((_) {}), // kết quả kiểm qua repository mock
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

Future<void> _openSection(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('division-editor-section-$id')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-WP-02-01: tạo hạng mục đôi có ELO và phí riêng — payload đủ trường',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final mgmt = _MgmtRepo();
      final stage = _StageRepo();
      await _open(
        tester,
        _app(
          mgmt,
          stage,
          (context) =>
              DivisionEditorSheet.show(context, tournament: _tournament()),
        ),
      );

      // Chọn "Đôi nam": tên tự điền theo loại (đối chiếu Web handleFormatSelect).
      await tester.tap(
        find.byKey(const ValueKey('division-editor-format-MALE_DOUBLES')),
      );
      await tester.pumpAndSettle();
      final nameField = tester.widget<TextField>(
        find.byKey(const ValueKey('division-editor-name')),
      );
      expect(nameField.controller!.text, 'Đôi nam');

      // Bật ELO riêng và điền min/max (mục ELO của accordion).
      await tester.tap(
        find.byKey(const ValueKey('division-editor-elo-switch')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('division-editor-elo-min')),
        '1000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('division-editor-elo-max')),
        '1600',
      );
      // Phí riêng khác phí giải 50.000 → bật override.
      await tester.enterText(
        find.byKey(const ValueKey('division-editor-fee')),
        '200000',
      );

      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();

      final payload = mgmt.created.single;
      expect(payload['name'], 'Đôi nam');
      expect(payload['matchType'], 'DOUBLES');
      expect(payload['genderRestriction'], 'MALE');
      expect(payload['bracketType'], 'SINGLE_ELIMINATION');
      expect(payload['maxParticipants'], 16);
      expect(payload['minElo'], 1000);
      expect(payload['maxElo'], 1600);
      expect(payload['entryFeeOverrideEnabled'], true);
      expect(payload['entryFee'], 200000);
      expect(payload['isConfigOverride'], true);
      final roundConfig = payload['roundConfig'] as Map<String, dynamic>;
      // Môn suy từ giải pickleball → preset mặc định 2×11, mode Lite.
      expect(roundConfig['kind'], 'PICKLEBALL_RALLY');
      expect(roundConfig['mode'], 'LITE');
      expect(roundConfig['setsToWin'], 2);
      expect(roundConfig['pointsPerSet'], 11);
      expect(mgmt.updated, isEmpty);
      expect(stage.stagePatches, isEmpty);
    },
  );

  testWidgets(
    'TC-WP-02-03: ELO min > max — báo lỗi tại trường, nút lưu bị chặn',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final mgmt = _MgmtRepo();
      final stage = _StageRepo();
      await _open(
        tester,
        _app(
          mgmt,
          stage,
          (context) =>
              DivisionEditorSheet.show(context, tournament: _tournament()),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('division-editor-elo-switch')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('division-editor-elo-min')),
        '1600',
      );
      await tester.enterText(
        find.byKey(const ValueKey('division-editor-elo-max')),
        '1000',
      );
      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();

      // Không gửi request; sheet vẫn mở với lỗi tại trường ELO.
      expect(
        find.text('ELO tối thiểu phải nhỏ hơn hoặc bằng ELO tối đa.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('division-editor-save')),
        findsOneWidget,
      );
      expect(mgmt.created, isEmpty);
      expect(mgmt.updated, isEmpty);
    },
  );

  testWidgets('TC-WP-02-03: preset theo môn điền sẵn luật, vẫn sửa tay được', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mgmt = _MgmtRepo();
    final stage = _StageRepo();
    await _open(
      tester,
      _app(
        mgmt,
        stage,
        (context) =>
            DivisionEditorSheet.show(context, tournament: _tournament()),
      ),
    );

    // Bật Luật chuẩn để hiện khối cấu hình luật (mục Luật vòng).
    await tester.tap(
      find.byKey(const ValueKey('division-editor-standard-rules')),
    );
    await tester.pumpAndSettle();

    // Preset "Chuẩn rally" (2×11) của pickleball rally.
    await tester.tap(
      find.byKey(
        const ValueKey('division-editor-preset-pickleball-rally-standard'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const ValueKey('division-editor-sets-to-win')),
          )
          .initialValue,
      2,
    );

    // Vẫn sửa tay được: đổi điểm/set thành 15 rồi lưu.
    await tester.enterText(
      find.byKey(const ValueKey('division-editor-points-per-set')),
      '15',
    );
    await tester.tap(find.byKey(const ValueKey('division-editor-save')));
    await tester.pumpAndSettle();

    final roundConfig =
        mgmt.created.single['roundConfig'] as Map<String, dynamic>;
    expect(roundConfig['setsToWin'], 2);
    expect(roundConfig['pointsPerSet'], 15);
    expect(roundConfig['maxPoints'], 15);
    expect(roundConfig['mode'], 'STRICT');
    expect(roundConfig.containsKey('tiebreakPoints'), isFalse);
  });

  testWidgets(
    'TC-WP-02-02: sửa hạng mục Swiss đã có sơ đồ — kết cấu khoá, chỉ vá stage',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final mgmt = _MgmtRepo();
      final stage = _StageRepo();
      await _open(
        tester,
        _app(
          mgmt,
          stage,
          (context) => DivisionEditorSheet.show(
            context,
            tournament: _tournament(),
            division: _swissDivision(),
            swissStage: _swissStage(),
            swissMinPlayedRounds: 2,
            lockContent: true,
          ),
        ),
      );

      // Kết cấu bị khoá: định dạng và thể thức không chọn được nữa.
      expect(
        tester
            .widget<LavishChoiceTile>(
              find.byKey(const ValueKey('division-editor-format-MALE_DOUBLES')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<LavishChoiceTile>(
              find.byKey(
                const ValueKey('division-editor-bracket-SINGLE_ELIMINATION'),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();

      // Không gọi create/updateDivision — chỉ vá stage giữ nguyên Swiss đã lưu.
      expect(mgmt.created, isEmpty);
      expect(mgmt.updated, isEmpty);
      expect(stage.stagePatches.length, 1);
      expect(stage.stagePatches.single.stageId, 'stage-1');
      final swiss = stage.stagePatches.single.roundConfig['swiss'];
      expect(swiss, isA<Map>());
      expect((swiss as Map)['totalRounds'], 5);
    },
  );

  testWidgets(
    'TC-WP-02-02: sửa hạng mục thường đã có sơ đồ — kết cấu khoá, giới hạn vẫn sửa',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final mgmt = _MgmtRepo();
      final stage = _StageRepo();
      await _open(
        tester,
        _app(
          mgmt,
          stage,
          (context) => DivisionEditorSheet.show(
            context,
            tournament: _tournament(),
            division: {
              'id': 'div-2',
              'name': 'Đơn nam',
              'matchType': 'SINGLES',
              'genderRestriction': 'MALE',
              'bracketType': 'SINGLE_ELIMINATION',
              'maxParticipants': 8,
            },
            lockContent: true,
          ),
        ),
      );

      expect(
        tester
            .widget<LavishChoiceTile>(
              find.byKey(const ValueKey('division-editor-bracket-ROUND_ROBIN')),
            )
            .onPressed,
        isNull,
      );
      // Giới hạn vẫn mở: tăng sức chứa 8 → 12.
      await tester.enterText(
        find.byKey(const ValueKey('division-editor-max')),
        '12',
      );

      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();

      final payload = mgmt.updated.single.payload;
      expect(mgmt.updated.single.id, 'div-2');
      expect(payload['maxParticipants'], 12);
      expect(payload['bracketType'], 'SINGLE_ELIMINATION');
      expect(mgmt.created, isEmpty);
    },
  );

  testWidgets(
    'Review 2.1: legacy không mode → theo mode giải; max "0" tự chuẩn về 2; payload gửi startDate giải',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final mgmt = _MgmtRepo();
      final stage = _StageRepo();
      // Giải bật mode STRICT; legacy roundConfig không ghi mode tường minh.
      final tournament = Tournament.fromJson({
        'name': 'City Pickleball Cup',
        'sport': 'pickleball',
        'format': 'doubles',
        'bracketType': 'single_elimination',
        'status': 'REGISTRATION',
        'maxTeams': 32,
        'entryFee': '50000',
        'startDate': '2026-06-01T00:00:00Z',
        'sportRules': {'mode': 'STRICT', 'kind': 'PICKLEBALL_RALLY'},
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, 'tournament-1');
      await _open(
        tester,
        _app(
          mgmt,
          stage,
          (context) => DivisionEditorSheet.show(
            context,
            tournament: tournament,
            division: {
              'id': 'div-3',
              'name': 'Đơn tự do',
              'matchType': 'SINGLES',
              'bracketType': 'SINGLE_ELIMINATION',
              'roundConfig': {
                'kind': 'PICKLEBALL_RALLY',
                'setsToWin': 2,
                'pointsPerSet': 11,
              },
            },
          ),
        ),
      );

      // Sức chứa "0": không chặn lưu như Web, tự chuẩn về 2.
      await tester.tap(
        find.byKey(const ValueKey('division-editor-limit-switch')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('division-editor-max')),
        '0',
      );
      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();

      final payload = mgmt.updated.single.payload;
      expect(payload['roundConfig']['mode'], 'STRICT');
      expect(payload['maxParticipants'], 2);
      // Ngày giải làm lịch mặc định cho hạng mục (Web handleCreateDivision).
      expect(payload['startDate'], contains('2026-06-01'));
    },
  );

  testWidgets('accordion: Cơ bản mở sẵn, bấm lại thì đóng; ELO luôn hiện sẵn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) =>
            DivisionEditorSheet.show(context, tournament: _tournament()),
      ),
    );

    // Cơ bản mở sẵn; ELO và giới hạn hiện luôn, không cần bấm mở.
    expect(find.byKey(const ValueKey('division-editor-name')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('division-editor-limit-switch')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('division-editor-elo-switch')),
      findsOneWidget,
    );
    // Tóm tắt một dòng, thể thức viết tiếng Việt (không lộ mã API).
    expect(find.textContaining('Loại trực tiếp · 16 đội'), findsOneWidget);
    expect(find.textContaining('SINGLE_ELIMINATION'), findsNothing);

    // Bấm mục đang mở thì đóng lại; ELO vẫn nguyên.
    await _openSection(tester, 'basic');
    expect(find.byKey(const ValueKey('division-editor-name')), findsNothing);
    expect(
      find.byKey(const ValueKey('division-editor-elo-switch')),
      findsOneWidget,
    );
    await _openSection(tester, 'basic');
    expect(find.byKey(const ValueKey('division-editor-name')), findsOneWidget);
  });

  testWidgets('Luật vòng: công tắc ngay trên hàng, bật hiện ô luật, tắt thì ẩn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) =>
            DivisionEditorSheet.show(context, tournament: _tournament()),
      ),
    );

    final points = find.byKey(const ValueKey('division-editor-points-per-set'));
    final toggle = find.byKey(const ValueKey('division-editor-standard-rules'));
    expect(toggle, findsOneWidget);
    expect(points, findsNothing);
    expect(find.text('Luật nhanh (mặc định)'), findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(points, findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(points, findsNothing);
  });

  testWidgets('giao diện như Web: chip viền xanh, nhãn nằm trên ô nhập, ELO không nền xám', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) =>
            DivisionEditorSheet.show(context, tournament: _tournament()),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('division-editor-standard-rules')),
    );
    await tester.pumpAndSettle();

    // Chọn một trong nhiều: ô viền như Web, không phải ChoiceChip tô nền.
    expect(find.byType(ChoiceChip), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is LavishChoiceTile &&
            w.key == const ValueKey('division-editor-scoring-PICKLEBALL_RALLY'),
      ),
      findsOneWidget,
    );

    // Nhãn nằm phía trên ô nhập (Web: label rồi input), không đè lên viền ô.
    final label = find.text('Số set chạm thắng');
    final field = find.byKey(const ValueKey('division-editor-sets-to-win'));
    expect(
      tester.getBottomLeft(label).dy,
      lessThanOrEqualTo(tester.getTopLeft(field).dy),
    );
    final limit = find.text('Số lượng tối đa');
    final limitField = find.byKey(const ValueKey('division-editor-max'));
    await tester.ensureVisible(limitField);
    expect(
      tester.getBottomLeft(limit).dy,
      lessThanOrEqualTo(tester.getTopLeft(limitField).dy),
    );
  });

  testWidgets('accordion: tóm tắt Luật vòng và Vòng bảng theo cấu hình', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) => DivisionEditorSheet.show(
          context,
          tournament: _tournament(),
          division: {
            'id': 'div-g',
            'name': 'Bảng đấu',
            'matchType': 'DOUBLES',
            'bracketType': 'GROUP_STAGE_KNOCKOUT',
            'maxParticipants': 16,
            'minElo': 1000,
            'maxElo': 1600,
            'roundConfig': {
              'groupsConfig': {'numGroups': 4, 'teamsPerGroup': 4},
              'advancementConfig': {'teamsAdvancing': 2},
            },
          },
        ),
      ),
    );

    expect(find.text('Luật nhanh (mặc định)'), findsOneWidget);
    expect(find.text('4 bảng · 2 đội đi tiếp'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('division-editor-elo-min')),
          )
          .controller
          ?.text,
      '1000',
    );
    // Mục Vòng bảng mở ra mới thấy ô cấu hình.
    expect(
      find.byKey(const ValueKey('division-editor-num-groups')),
      findsNothing,
    );
    await _openSection(tester, 'stage');
    expect(
      find.byKey(const ValueKey('division-editor-num-groups')),
      findsOneWidget,
    );
  });

  testWidgets('minh hoạ thể thức: mở hộp thoại mô tả đúng thể thức', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) => DivisionEditorSheet.show(
          context,
          tournament: _tournament(),
          division: _swissDivision(),
        ),
      ),
    );

    // Nút ▶ nằm ngay trên ô thể thức (như Web), không đổi thể thức đang chọn.
    await tester.tap(
      find.byKey(const ValueKey('division-editor-illustration-SWISS')),
    );
    // The illustration loops, so settle never ends: advance a fixed time.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('format-illustration-dialog')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Mỗi vòng ghép người cùng điểm'),
      findsOneWidget,
    );
  });

  testWidgets('TC-HIDE-SWISS-01: tạo mới ẩn Thụy Sĩ, nội dung Swiss đã có vẫn hiện', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const swissTile = ValueKey('division-editor-bracket-SWISS');
    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) =>
            DivisionEditorSheet.show(context, tournament: _tournament()),
      ),
    );
    expect(
      find.byKey(const ValueKey('division-editor-bracket-ROUND_ROBIN')),
      findsOneWidget,
    );
    expect(find.byKey(swissTile), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) => DivisionEditorSheet.show(
          context,
          tournament: _tournament(),
          division: _swissDivision(),
        ),
      ),
    );
    expect(find.byKey(swissTile), findsOneWidget);
  });

  testWidgets('sửa: nút xoá nội dung đóng sheet rồi gọi onDelete; tạo mới thì không có', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var deleted = 0;
    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) => DivisionEditorSheet.show(
          context,
          tournament: _tournament(),
          division: _swissDivision(),
          onDelete: () => deleted++,
        ),
      ),
    );

    final deleteButton = find.byKey(const ValueKey('division-editor-delete'));
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(deleted, 1);
    expect(find.byKey(const ValueKey('division-editor-save')), findsNothing);

    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) => DivisionEditorSheet.show(
          context,
          tournament: _tournament(),
          onDelete: () => deleted++,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('division-editor-delete')), findsNothing);
  });

  testWidgets('đã có sơ đồ: không còn khung chữ khoá ở đầu, công tắc luật bị khoá', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(
      tester,
      _app(
        _MgmtRepo(),
        _StageRepo(),
        (context) => DivisionEditorSheet.show(
          context,
          tournament: _tournament(),
          division: {
            'id': 'div-2',
            'name': 'Đơn nam',
            'matchType': 'SINGLES',
            'bracketType': 'SINGLE_ELIMINATION',
          },
          lockContent: true,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('division-editor-locked-notice')),
      findsNothing,
    );
    expect(find.textContaining('Nội dung này đã có sơ đồ thi đấu'), findsNothing);

    // Luật vòng đã khoá: bấm công tắc không mở thêm ô luật.
    await tester.tap(
      find.byKey(const ValueKey('division-editor-standard-rules')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('division-editor-points-per-set')),
      findsNothing,
    );
  });

  testWidgets('bấm đúp Lưu chỉ gửi một lần', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mgmt = _MgmtRepo();
    await _open(
      tester,
      _app(
        mgmt,
        _StageRepo(),
        (context) =>
            DivisionEditorSheet.show(context, tournament: _tournament()),
      ),
    );

    final save = find.byKey(const ValueKey('division-editor-save'));
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(mgmt.created.length, 1);
  });

  group('port Web registration-fee (divisionFeePayload/feeInputValue)', () {
    test('ô trống hoặc bằng phí giải → theo phí giải, không override', () {
      final payload = divisionFeePayload('', 50000);
      expect(payload.entryFeeOverrideEnabled, false);
      expect(payload.entryFee, isNull);
      final same = divisionFeePayload('50000', 50000);
      expect(same.entryFeeOverrideEnabled, false);
      expect(same.entryFee, isNull);
    });

    test('số khác (kể cả 0) → bật phí riêng', () {
      final custom = divisionFeePayload('200000', 50000);
      expect(custom.entryFeeOverrideEnabled, true);
      expect(custom.entryFee, 200000);
      final free = divisionFeePayload('0', 50000);
      expect(free.entryFeeOverrideEnabled, true);
      expect(free.entryFee, 0);
    });

    test(
      'giá trị khởi tạo: phí riêng nội dung khi override, không thì phí giải',
      () {
        expect(
          divisionFeeInputValue({
            'entryFeeOverrideEnabled': true,
            'entryFee': 200000,
          }, 50000),
          '200000',
        );
        expect(divisionFeeInputValue(null, 50000), '50000');
        expect(divisionFeeInputValue(null, null), '0');
      },
    );
  });

  group('port Web match-format-options (mapping hai chiều)', () {
    test('lựa chọn UI → matchType + genderRestriction như Web', () {
      expect(matchFormatApiMapping('MALE_SINGLES'), (
        matchType: 'SINGLES',
        genderRestriction: 'MALE',
      ));
      expect(matchFormatApiMapping('OPEN_DOUBLES'), (
        matchType: 'DOUBLES',
        genderRestriction: null,
      ));
      expect(matchFormatApiMapping('MIXED_DOUBLES'), (
        matchType: 'MIXED_DOUBLES',
        genderRestriction: 'MIXED',
      ));
    });

    test('từ trường đã lưu suy lại lựa chọn UI', () {
      expect(
        matchFormatOptionFromDivision('SINGLES', 'FEMALE'),
        'FEMALE_SINGLES',
      );
      expect(matchFormatOptionFromDivision('SINGLES', null), 'OPEN_SINGLES');
      expect(matchFormatOptionFromDivision('DOUBLES', null), 'OPEN_DOUBLES');
      expect(matchFormatOptionFromDivision('DOUBLES', 'MALE'), 'MALE_DOUBLES');
      expect(
        matchFormatOptionFromDivision('MIXED_DOUBLES', 'MIXED'),
        'MIXED_DOUBLES',
      );
    });
  });

  group('port Web sport-rules (preset/defaults/payload)', () {
    test('preset theo môn đúng dữ liệu Web', () {
      final badminton = getSportRulePresets(SportRulePresetKind.badminton);
      expect(badminton, hasLength(3));
      expect(badminton.first.id, 'badminton-quick');
      expect(badminton.first.pointsPerSet, 21);
      expect(badminton.first.maxPoints, 30);
      final sideOut = getSportRulePresets(
        SportRulePresetKind.pickleballSideOut,
      );
      expect(sideOut.first.tiebreakPoints, 11);
      final football = getSportRulePresets(SportRulePresetKind.football);
      expect(football.single.winByTwo, false);
    });

    test('buildSportRulesPayload đủ khối scoring/format theo môn', () {
      final payload = buildSportRulesPayload(
        kind: SportRulePresetKind.tennis,
        setsToWin: 2,
        pointsPerSet: 6,
        winByTwo: true,
        maxPoints: 7,
        tiebreakPoints: 7,
        roundsToPlay: 1,
        mode: 'STRICT',
      );
      expect(payload['kind'], 'TENNIS');
      expect(payload['mode'], 'STRICT');
      expect(payload['setsToWin'], 2);
      expect(payload['maxPoints'], 7);
      // Scoring lồng chép mặc định môn (kèm maxPoints/tiebreakPoints riêng)
      // rồi ghi đè bằng lựa chọn — port payload.ts đầy đủ.
      expect(payload['scoring']['setsToWin'], 2);
      expect(payload['scoring']['maxPoints'], 7);
      expect(payload['scoring']['tiebreakPoints'], 7);
      final format = payload['format'] as Map<String, dynamic>;
      expect(format['bestOfSets'], 3);
      expect(format['gamesPerSet'], 6);
      expect(format['tiebreakPoints'], 7);
      // Override khác mặc định môn: scoring.maxPoints nhận override (30 → 25).
      final badminton = buildSportRulesPayload(
        kind: SportRulePresetKind.badminton,
        setsToWin: 2,
        pointsPerSet: 21,
        winByTwo: true,
        maxPoints: 25,
        mode: 'LITE',
      );
      expect(badminton['scoring']['maxPoints'], 25);
      expect(badminton['maxPoints'], 25);
    });

    test('resolveSportRuleView đọc cấu hình đã lưu và lấp mặc định', () {
      final view = resolveSportRuleView({
        'kind': 'BADMINTON',
        'setsToWin': 2,
        'pointsPerSet': 21,
        'winByTwo': true,
        'maxPoints': 30,
        'mode': 'STRICT',
        'roundsToPlay': 2,
      });
      expect(view.kind, SportRulePresetKind.badminton);
      expect(view.mode, 'STRICT');
      expect(view.setsToWin, 2);
      expect(view.roundsToPlay, 2);
      expect(view.hasCustomTiebreakTarget, isFalse);
      // Thiếu gì lấp từ mặc định môn (side-out mặc định tiebreak 11).
      final sideOut = resolveSportRuleView({
        'kind': 'PICKLEBALL_SIDE_OUT',
        'setsToWin': 1,
        'pointsPerSet': 11,
      });
      expect(sideOut.maxPoints, 15);
      expect(sideOut.tiebreakPoints, 11);
      // `PICKLEBALL` cũ quy về rally.
      expect(
        resolveSportRuleView({'kind': 'PICKLEBALL'}).kind,
        SportRulePresetKind.pickleballRally,
      );
    });

    test('inferSportRuleKindFromText nhận tên tiếng Việt có dấu', () {
      expect(
        inferSportRuleKindFromText(null, 'Cầu lông phong trào'),
        SportRulePresetKind.badminton,
      );
      expect(
        inferSportRuleKindFromText(null, 'Bóng bàn'),
        SportRulePresetKind.tableTennis,
      );
      expect(
        inferSportRuleKindFromText(null, 'Quần vợt'),
        SportRulePresetKind.tennis,
      );
      expect(
        inferSportRuleKindFromText(null, 'Bóng đá sân 7'),
        SportRulePresetKind.football,
      );
      expect(
        inferSportRuleKindFromText(null, 'Pickleball'),
        SportRulePresetKind.pickleballRally,
      );
    });
  });

  group('mốc DUPR', () {
    Tournament badmintonTournament() => Tournament.fromJson({
      'name': 'City Badminton Cup',
      'sport': 'badminton',
      'format': 'doubles',
      'bracketType': 'single_elimination',
      'status': 'REGISTRATION',
      'maxTeams': 32,
      'entryFee': '50000',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    }, 'tournament-2');

    Future<void> pickDupr(WidgetTester tester, String field, String label) async {
      await tester.tap(find.byKey(ValueKey('division-editor-dupr-$field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    void bigView(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('chọn 3.0 – 3.5 ra payload đúng', (tester) async {
      bigView(tester);
      final mgmt = _MgmtRepo();
      await _open(
        tester,
        _app(
          mgmt,
          _StageRepo(),
          (context) =>
              DivisionEditorSheet.show(context, tournament: _tournament()),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('division-editor-format-MALE_DOUBLES')),
      );
      await tester.pumpAndSettle();

      await _openSection(tester, 'dupr');
      await pickDupr(tester, 'min', '3.0');
      await pickDupr(tester, 'max', '3.5');
      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();

      final payload = mgmt.created.single;
      expect(payload['minDupr'], 3.0);
      expect(payload['maxDupr'], 3.5);
    });

    testWidgets('chọn Từ lớn hơn Đến thì Đến về không giới hạn', (
      tester,
    ) async {
      bigView(tester);
      final mgmt = _MgmtRepo();
      await _open(
        tester,
        _app(
          mgmt,
          _StageRepo(),
          (context) =>
              DivisionEditorSheet.show(context, tournament: _tournament()),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('division-editor-format-MALE_DOUBLES')),
      );
      await tester.pumpAndSettle();

      await _openSection(tester, 'dupr');
      await pickDupr(tester, 'max', '3.0');
      await pickDupr(tester, 'min', '4.0');
      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();

      final payload = mgmt.created.single;
      expect(payload['minDupr'], 4.0);
      expect(payload['maxDupr'], isNull);
    });

    testWidgets('môn khác: không có mục DUPR và payload không có hai trường', (
      tester,
    ) async {
      bigView(tester);
      final mgmt = _MgmtRepo();
      await _open(
        tester,
        _app(
          mgmt,
          _StageRepo(),
          (context) => DivisionEditorSheet.show(
            context,
            tournament: badmintonTournament(),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('division-editor-format-MALE_DOUBLES')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('division-editor-section-dupr')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();

      final payload = mgmt.created.single;
      expect(payload.containsKey('minDupr'), isFalse);
      expect(payload.containsKey('maxDupr'), isFalse);
    });

    testWidgets('mở nội dung có mốc rồi xoá mốc ra null', (tester) async {
      bigView(tester);
      final mgmt = _MgmtRepo();
      await _open(
        tester,
        _app(
          mgmt,
          _StageRepo(),
          (context) => DivisionEditorSheet.show(
            context,
            tournament: _tournament(),
            division: {
              'id': 'div-9',
              'name': 'Đôi có mốc',
              'matchType': 'DOUBLES',
              'bracketType': 'SINGLE_ELIMINATION',
              'minDupr': 3,
              'maxDupr': '3.50',
              'roundConfig': {
                'kind': 'PICKLEBALL_RALLY',
                'setsToWin': 2,
                'pointsPerSet': 11,
              },
            },
          ),
        ),
      );

      await _openSection(tester, 'dupr');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('division-editor-dupr-min')),
          matching: find.text('3.0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('division-editor-dupr-max')),
          matching: find.text('3.5'),
        ),
        findsOneWidget,
      );

      await pickDupr(tester, 'min', 'Không giới hạn');
      await pickDupr(tester, 'max', 'Không giới hạn');
      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();

      final payload = mgmt.updated.single.payload;
      expect(payload.containsKey('minDupr'), isTrue);
      expect(payload['minDupr'], isNull);
      expect(payload['maxDupr'], isNull);
    });

    testWidgets('mốc lệch (Đến nhỏ hơn Từ) nạp vào thì Đến về không giới hạn', (
      tester,
    ) async {
      bigView(tester);
      final mgmt = _MgmtRepo();
      await _open(
        tester,
        _app(
          mgmt,
          _StageRepo(),
          (context) => DivisionEditorSheet.show(
            context,
            tournament: _tournament(),
            division: {
              'id': 'div-10',
              'name': 'Đôi dữ liệu lệch',
              'matchType': 'DOUBLES',
              'bracketType': 'SINGLE_ELIMINATION',
              'minDupr': 4,
              'maxDupr': 3,
              'roundConfig': {
                'kind': 'PICKLEBALL_RALLY',
                'setsToWin': 2,
                'pointsPerSet': 11,
              },
            },
          ),
        ),
      );

      await _openSection(tester, 'dupr');
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('division-editor-dupr-max')),
          matching: find.text('Không giới hạn'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();
      final payload = mgmt.updated.single.payload;
      expect(payload['minDupr'], 4.0);
      expect(payload['maxDupr'], isNull);
    });

    testWidgets('mốc ngoài danh sách (1.0 và 7.0) hiện đúng và giữ nguyên', (
      tester,
    ) async {
      bigView(tester);
      final mgmt = _MgmtRepo();
      await _open(
        tester,
        _app(
          mgmt,
          _StageRepo(),
          (context) => DivisionEditorSheet.show(
            context,
            tournament: _tournament(),
            division: {
              'id': 'div-11',
              'name': 'Đôi mốc rộng',
              'matchType': 'DOUBLES',
              'bracketType': 'SINGLE_ELIMINATION',
              'minDupr': '1.00',
              'maxDupr': 7,
              'roundConfig': {
                'kind': 'PICKLEBALL_RALLY',
                'setsToWin': 2,
                'pointsPerSet': 11,
              },
            },
          ),
        ),
      );

      await _openSection(tester, 'dupr');
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('division-editor-dupr-min')),
          matching: find.text('1.0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('division-editor-dupr-max')),
          matching: find.text('7.0'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('division-editor-save')));
      await tester.pumpAndSettle();
      final payload = mgmt.updated.single.payload;
      expect(payload['minDupr'], 1.0);
      expect(payload['maxDupr'], 7.0);
    });
  });
}
