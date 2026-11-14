import 'dart:async';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_layout.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/roster_layout_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';

/// File picker giả: trả về workbook xlsx dựng sẵn.
class _FakePicker extends FilePickerPlatform {
  _FakePicker(this.bytes);

  final Uint8List bytes;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    AndroidSAFOptions? androidSafOptions,
  }) async => FilePickerResult([
    PlatformFile(name: 'roster.xlsx', size: bytes.length, bytes: bytes),
  ]);
}

/// AI layout giả: trả lời khi test hoàn tất [pending]; [_FakeLayoutRepo.unavailable] trả lời ngay "AI tắt".
class _FakeLayoutRepo implements RosterLayoutRepository {
  _FakeLayoutRepo();

  _FakeLayoutRepo.unavailable() {
    pending.complete(
      const RosterLayoutResponse(aiAvailable: false, layout: null),
    );
  }

  final pending = Completer<RosterLayoutResponse>();
  var calls = 0;

  @override
  Future<RosterLayoutResponse> analyzeRosterLayout(
    String tournamentId, {
    required List<Map<String, dynamic>> sheets,
    String locale = 'vi',
    bool retryEmptyLayout = false,
  }) {
    calls++;
    return pending.future;
  }
}

/// Repository giả: ghi lại preview/createDivision, tuỳ chọn trả ứng viên theo email hoặc ném lỗi preview.
class _Repo implements TournamentManagementRepository {
  final created = <Map<String, dynamic>>[];
  final previews = <RosterImportBatchRequest>[];
  Object? previewFailure;

  /// Email -> ứng viên tài khoản duy nhất trùng email đó.
  final candidatesByEmail = <String, RosterImportBatchCandidate>{};

  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async =>
      const [];

  @override
  Future<Map<String, dynamic>> createDivision(
    String id,
    Map<String, dynamic> payload,
  ) async {
    created.add(Map<String, dynamic>.of(payload));
    return {
      'id': 'div-new-${created.length}',
      'name': payload['name'],
      'matchType': payload['matchType'],
    };
  }

  @override
  Future<RosterImportBatchPreview> previewRosterImportBatch(
    String id,
    RosterImportBatchRequest request,
  ) async {
    previews.add(request);
    final failure = previewFailure;
    if (failure != null) throw failure;
    return RosterImportBatchPreview(
      totalParticipants: request.groups.fold<int>(
        0,
        (total, group) => total + group.participants.length,
      ),
      groups: [
        for (final group in request.groups)
          RosterImportBatchPreviewGroup(
            divisionId: group.divisionId,
            divisionName: null,
            divisionMatched: group.divisionId != null,
            rows: [
              for (final item in group.participants)
                RosterImportBatchPreviewRow(
                  clientRowIndex: item.clientRowIndex,
                  rowIndex: item.clientRowIndex,
                  player1Email: item.player1Email ?? '',
                  player2Email: item.player2Email,
                  status: group.divisionId == null
                      ? const ['DIVISION_UNKNOWN']
                      : const ['FOUND'],
                  isEligible: group.divisionId != null,
                  capacityDelta: 1,
                  customResponses: const {},
                  customResponseError: null,
                  player1Candidates: [?candidatesByEmail[item.player1Email]],
                  player2Candidates: const [],
                  confirmedPlayer1UserId: item.confirmedPlayer1UserId,
                  confirmedPlayer2UserId: item.confirmedPlayer2UserId,
                ),
            ],
            requestedTeamSlots: group.participants.length,
            capacityRemaining: group.divisionId == null ? null : 15,
            capacityRemainingAfterBatch: group.divisionId == null ? null : 14,
            capacityFits: group.divisionId != null,
          ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TournamentDivision _division(String matchType) =>
    TournamentDivision(id: 'div-1', name: 'Đơn nam', matchType: matchType);

Tournament _tournament(String matchType) => Tournament(
  id: 't1',
  name: 'Giải Test',
  sport: 'pickleball',
  format: 'singles',
  bracketType: 'single_elimination',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'creator-1',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  divisions: [_division(matchType)],
);

Widget _app(
  _Repo repo, {
  RosterLayoutRepository? layout,
  String matchType = 'SINGLES',
}) => ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWith((ref) => repo),
    rosterLayoutRepositoryProvider.overrideWith(
      (ref) => layout ?? _FakeLayoutRepo.unavailable(),
    ),
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
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              enableDrag: false,
              builder: (_) => RosterImportSheet(
                tournament: _tournament(matchType),
                defaultDivision: _division(matchType),
                onRefresh: () async {},
              ),
            ),
            child: const Text('Mở sheet'),
          ),
        ),
      ),
    ),
  ),
);

FilePickerPlatform? _previousPicker;

Future<void> _open(
  WidgetTester tester,
  Uint8List bytes,
  _Repo repo, {
  RosterLayoutRepository? layout,
  String matchType = 'SINGLES',
  bool aiPending = false,
}) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _previousPicker = FilePickerPlatform.instance;
  FilePickerPlatform.instance = _FakePicker(bytes);
  await tester.pumpWidget(_app(repo, layout: layout, matchType: matchType));
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('roster-import-pick-file')));
  // AI đang đọc thì có spinner chạy mãi: chỉ bơm vài khung hình.
  if (aiPending) {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  } else {
    await tester.pumpAndSettle();
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

List<RosterImportBatchItem> _sent(_Repo repo) => [
  for (final group in repo.previews.last.groups) ...group.participants,
];

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(RosterImportSheet)))!;

Future<void> _openMapping(WidgetTester tester) async {
  await tester.ensureVisible(_key('roster-import-open-mapping'));
  await tester.tap(_key('roster-import-open-mapping'));
  await tester.pumpAndSettle();
}

Future<void> _assign(WidgetTester tester, int column, String chip) async {
  await tester.tap(_key('roster-map-column-$column'));
  await tester.pumpAndSettle();
  await tester.tap(_key('roster-map-chip-$column-$chip'));
  await tester.pumpAndSettle();
}

Future<void> _done(WidgetTester tester) async {
  await tester.tap(_key('roster-map-done'));
  await tester.pumpAndSettle();
}

/// File một VĐV mỗi dòng: cột Tên gọi khác chưa ghép.
Uint8List _nicknameFile() => workbookBytes([
  ['STT', 'Họ và tên VĐV', 'Tên gọi khác', 'Email'],
  [1, fakeName(0), 'Biệt A', 'a@example.com'],
  [2, fakeName(1), 'Biệt B', 'b@example.com'],
]);

/// File luật không đủ tin (cặp theo STT gộp lẫn VĐV lẻ) nên màn hỏi AI; cùng bố cục với test `roster_import_sheet_test`.
Uint8List _aiFile() => workbookBytes(
  [
    ['STT', 'Họ và tên VĐV', 'Số điện thoại liên hệ'],
    [1, fakeName(0), fakePhone(0)],
    [null, fakeName(1), fakePhone(1)],
    [2, fakeName(2), fakePhone(2)],
    [null, fakeName(3), fakePhone(3)],
    [3, fakeName(4), fakePhone(4)],
    [4, fakeName(5), fakePhone(5)],
    [5, fakeName(6), fakePhone(6)],
  ],
  merges: ['A2:A3', 'A4:A5'],
);

/// Sheet không có dòng tiêu đề nhận diện được: tiêu đề thật nằm ở dòng 3.
Uint8List _headerlessFile() => workbookBytes([
  ['Danh sách tham gia'],
  ['Tạo ngày', '2026'],
  ['Cột 1', 'Cột 2'],
  [fakeName(0), 'a@example.com'],
  [fakeName(1), 'b@example.com'],
]);

void main() {
  tearDown(() {
    final previous = _previousPicker;
    if (previous != null) {
      FilePickerPlatform.instance = previous;
      _previousPicker = null;
    }
  });

  testWidgets(
    'TC-ROSTERMAP-25 đổi cột rồi Xong gửi preview mới với tên từ cột mới',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _nicknameFile(), repo);
      expect(repo.previews, hasLength(1));
      expect(_sent(repo).map((i) => i.player1Name), [fakeName(0), fakeName(1)]);

      await _openMapping(tester);
      await _assign(tester, 2, 'player1Name');
      await _done(tester);

      expect(repo.previews, hasLength(2));
      expect(_sent(repo).map((i) => i.player1Name), ['Biệt A', 'Biệt B']);
    },
  );

  testWidgets('TC-ROSTERMAP-26 đóng popup không Xong thì không đổi gì', (
    tester,
  ) async {
    final repo = _Repo();
    await _open(tester, _nicknameFile(), repo);

    await _openMapping(tester);
    await _assign(tester, 2, 'player1Name');
    await tester.tap(_key('roster-map-close'));
    await tester.pumpAndSettle();

    expect(repo.previews, hasLength(1));
    expect(find.text(fakeName(0)), findsWidgets);
    expect(find.text('Biệt A'), findsNothing);
  });

  testWidgets(
    'TC-ROSTERMAP-27 nút Ghép cột tắt khi AI đang đọc và bật sau khi AI trả lời',
    (tester) async {
      final layout = _FakeLayoutRepo();
      final repo = _Repo();
      await _open(
        tester,
        _aiFile(),
        repo,
        layout: layout,
        matchType: 'DOUBLES',
        aiPending: true,
      );
      await tester.pump();
      expect(_key('roster-import-ai-checking'), findsOneWidget);
      expect(
        tester
            .widget<ButtonStyleButton>(_key('roster-import-open-mapping'))
            .onPressed,
        isNull,
      );

      layout.pending.complete(
        const RosterLayoutResponse(aiAvailable: false, layout: null),
      );
      await tester.pumpAndSettle();

      expect(_key('roster-import-ai-checking'), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(_key('roster-import-open-mapping'))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'TC-ROSTERMAP-28 sau khi AI trả lời, Ghép cột + Xong giữ bản sửa và không hiện lại thông báo AI',
    (tester) async {
      final layout = _FakeLayoutRepo();
      final repo = _Repo();
      await _open(
        tester,
        _aiFile(),
        repo,
        layout: layout,
        matchType: 'DOUBLES',
        aiPending: true,
      );
      layout.pending.complete(
        RosterLayoutResponse.fromJson({
          'aiAvailable': true,
          'layout': {
            'sheets': [
              {
                'sheetName': 'Đôi Nam',
                'kind': 'ROSTER',
                'blocks': [
                  {
                    'divisionLabel': '',
                    'headerRow': 1,
                    'firstDataRow': 2,
                    'lastDataRow': 8,
                    'columns': {'player1Name': 'B', 'player1Phone': 'C'},
                    'pairLayout': 'CONSECUTIVE_ROWS',
                    'pairSeparator': '',
                    'singlesFromRow': 6,
                  },
                ],
              },
            ],
            'notes': <String>[],
          },
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text(_l10n(tester).rosterImportAiDone), findsOneWidget);

      await _openMapping(tester);
      await _assign(tester, 2, 'teamName');
      await _done(tester);

      expect(find.text(_l10n(tester).rosterImportAiDone), findsNothing);
      expect(layout.calls, 1);
      expect(_sent(repo).map((i) => i.teamName), contains(fakePhone(0)));
    },
  );

  testWidgets(
    'TC-ROSTERMAP-29 nội dung đã tạo không hỏi tạo lại sau Ghép cột + Xong',
    (tester) async {
      final repo = _Repo();
      await _open(
        tester,
        workbookBytes([
          ['Họ và tên VĐV 1', 'Email', 'Nội dung'],
          [fakeName(0), 'a@example.com', 'Trình độ mở'],
          [fakeName(1), 'b@example.com', 'Trình độ mở'],
        ]),
        repo,
      );
      await tester.ensureVisible(_key('roster-import-create-divisions'));
      await tester.tap(_key('roster-import-create-divisions'));
      await tester.pumpAndSettle();
      expect(repo.created, hasLength(1));
      expect(repo.previews, hasLength(1));

      await _openMapping(tester);
      await _done(tester);

      expect(_key('roster-import-create-divisions'), findsNothing);
      expect(repo.created, hasLength(1));
      expect(repo.previews, hasLength(2));
    },
  );

  testWidgets('TC-ROSTERMAP-30 sheet không có tiêu đề được cứu qua popup', (
    tester,
  ) async {
    final repo = _Repo();
    await _open(tester, _headerlessFile(), repo);
    final l10n = _l10n(tester);
    final warning = l10n.rosterImportNoSheetHeader('Đôi Nam');
    expect(find.text(warning), findsOneWidget);
    expect(repo.previews, isEmpty);

    await _openMapping(tester);
    await tester.tap(_key('roster-map-header-plus'));
    await tester.pumpAndSettle();
    await _assign(tester, 0, 'player1Name');
    await _done(tester);

    expect(find.text(warning), findsNothing);
    expect(repo.previews, hasLength(1));
    expect(_sent(repo).map((i) => i.player1Name), [fakeName(0), fakeName(1)]);
  });

  testWidgets(
    'TC-ROSTERMAP-31 preview lỗi sau Xong hiện Thử lại và tắt nút nhập',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _nicknameFile(), repo);

      repo.previewFailure = StateError('mất mạng');
      await _openMapping(tester);
      await _assign(tester, 2, 'player1Name');
      await _done(tester);

      final l10n = _l10n(tester);
      expect(find.text(l10n.rosterImportRetry), findsOneWidget);
      final commit = find.byWidgetPredicate(
        (w) =>
            w is FilledButton &&
            w.key == const ValueKey('roster-import-commit'),
      );
      expect(commit, findsOneWidget);
      expect(tester.widget<FilledButton>(commit).onPressed, isNull);
    },
  );

  testWidgets(
    'TC-ROSTERMAP-32 tài khoản tự liên kết vẫn do _effectiveLink quyết định và liên kết tay bị đặt lại',
    (tester) async {
      final repo = _Repo()
        ..candidatesByEmail['a@example.com'] = const RosterImportBatchCandidate(
          userId: 'u-a',
          email: 'a@example.com',
          fullName: 'Tài khoản A',
        );
      await _open(tester, _nicknameFile(), repo);
      expect(
        _sent(repo)
            .firstWhere((i) => i.player1Email == 'a@example.com')
            .confirmedPlayer1UserId,
        'u-a',
      );

      // Chọn tay "Không liên kết" cho VĐV A.
      await tester.ensureVisible(_key('roster-row-0'));
      await tester.tap(_key('roster-row-0'));
      await tester.pumpAndSettle();
      await tester.tap(_key('roster-detail-account-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n(tester).rosterImportLeaveUnlinked));
      await tester.pumpAndSettle();
      await tester.tap(_key('roster-detail-done'));
      await tester.pumpAndSettle();
      expect(
        _sent(repo)
            .firstWhere((i) => i.player1Email == 'a@example.com')
            .confirmedPlayer1UserId,
        isNull,
      );

      // Đã sửa tay nên Ghép cột hỏi xác nhận trước khi bỏ các sửa tay.
      await _openMapping(tester);
      await tester.tap(_key('roster-list-reset-confirm'));
      await tester.pumpAndSettle();
      await _done(tester);

      final items = _sent(repo);
      expect(
        items
            .firstWhere((i) => i.player1Email == 'a@example.com')
            .confirmedPlayer1UserId,
        'u-a',
      );
      expect(
        items
            .firstWhere((i) => i.player1Email == 'b@example.com')
            .confirmedPlayer1UserId,
        isNull,
      );
    },
  );
}
