import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_layout.dart';
import 'package:app_quanly_giaidau/domain/repositories/roster_layout_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';

/// File picker giả: trả về workbook xlsx dựng sẵn, không đụng hệ điều hành.
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
  }) async {
    return FilePickerResult([
      PlatformFile(name: 'roster.xlsx', size: bytes.length, bytes: bytes),
    ]);
  }
}

/// AI layout giả: trả [response] hoặc ném [failure]; ghi lại số lần gọi và retryReason.
class _FakeLayoutRepo implements RosterLayoutRepository {
  _FakeLayoutRepo({this.response, this.failure});

  final RosterLayoutResponse? response;
  final Object? failure;
  final calls = <bool>[];

  @override
  Future<RosterLayoutResponse> analyzeRosterLayout(
    String tournamentId, {
    required List<Map<String, dynamic>> sheets,
    String locale = 'vi',
    bool retryEmptyLayout = false,
  }) async {
    calls.add(retryEmptyLayout);
    final error = failure;
    if (error != null) throw error;
    return response!;
  }
}

/// Mock repository: ghi lại createDivision/preview theo thứ tự để khẳng định
/// preview chỉ chạy sau khi tạo xong hạng mục (task 3.8).
class _Repo implements TournamentManagementRepository {
  final created = <Map<String, dynamic>>[];
  final previews = <RosterImportBatchRequest>[];

  /// Thứ tự sự kiện: `create:<tên>` rồi `preview`.
  final log = <String>[];

  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async =>
      const [];

  @override
  Future<Map<String, dynamic>> createDivision(
    String id,
    Map<String, dynamic> payload,
  ) async {
    created.add(Map<String, dynamic>.of(payload));
    log.add('create:${payload['name']}');
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
    log.add('preview');
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
                  player1Candidates: const [],
                  player2Candidates: const [],
                  confirmedPlayer1UserId: null,
                  confirmedPlayer2UserId: null,
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

TournamentDivision _division(String id, String name, {String? matchType}) =>
    TournamentDivision(id: id, name: name, matchType: matchType ?? 'SINGLES');

Tournament _tournament({String matchType = 'SINGLES'}) => Tournament(
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
  divisions: [_division('div-1', 'Đơn nam', matchType: matchType)],
);

/// Workbook một sheet: dòng đầu là header, các dòng sau là dữ liệu.
Uint8List _workbook(List<List<String>> rows) {
  final excel = Excel.createExcel();
  final sheet = excel['VĐV'];
  for (final row in rows) {
    sheet.appendRow([for (final cell in row) TextCellValue(cell)]);
  }
  excel.delete('Sheet1');
  return Uint8List.fromList(excel.encode()!);
}

/// Trang chủ có nút mở sheet: sheet chạy trong modal route thật nên đóng
/// được bằng Navigator.pop (như các test sheet khác).
Widget _app(
  _Repo repo, {
  String matchType = 'SINGLES',
  RosterLayoutRepository? layout,
}) => ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWith((ref) => repo),
    if (layout != null)
      rosterLayoutRepositoryProvider.overrideWith((ref) => layout),
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
                tournament: _tournament(matchType: matchType),
                defaultDivision: _division(
                  'div-1',
                  'Đơn nam',
                  matchType: matchType,
                ),
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

void _installPicker(Uint8List bytes) {
  _previousPicker = FilePickerPlatform.instance;
  FilePickerPlatform.instance = _FakePicker(bytes);
}

Future<void> _open(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('roster-import-pick-file')));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    final previous = _previousPicker;
    if (previous != null) {
      FilePickerPlatform.instance = previous;
      _previousPicker = null;
    }
  });

  testWidgets(
    'TC-WP-03-13: tên nội dung chưa khớp — dừng xác nhận, tạo từng hạng mục rồi mới preview server',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      _installPicker(
        _workbook([
          ['Họ và tên VĐV 1', 'Email', 'Nội dung'],
          ['Nguyễn Văn A', 'a@test.vn', 'Đôi nam'],
          ['Trần Thị B', 'b@test.vn', 'Đôi nam nữ'],
          ['Lê Văn C', 'c@test.vn', 'Trình độ mở'],
          ['Phạm Thị D', 'd@test.vn', 'Đôi Men Nữ'],
        ]),
      );
      await _open(tester, _app(repo));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RosterImportSheet)),
      )!;

      // Bước xác nhận hiện ra, preview server chưa chạy.
      expect(find.text(l10n.rosterImportCreateTitle), findsOneWidget);
      expect(
        find.byKey(const ValueKey('roster-import-create-divisions')),
        findsOneWidget,
      );
      expect(repo.created, isEmpty);
      expect(repo.previews, isEmpty);

      // Bốn hạng mục được chọn sẵn; nút hiển thị đúng số lượng.
      expect(find.text(l10n.rosterImportCreateRow('Đôi nam')), findsOneWidget);
      expect(
        find.text(l10n.rosterImportCreateRow('Đôi nam nữ')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.rosterImportCreateRow('Trình độ mở')),
        findsOneWidget,
      );
      expect(find.text(l10n.rosterImportCreateAndCheck(4)), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('roster-import-create-divisions')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('roster-import-create-divisions')),
      );
      await tester.pumpAndSettle();

      // Tạo đúng payload suy từ tên, đúng thứ tự, rồi mới preview với id mới.
      // "Đôi Men Nữ" lẫn 2 ngôn ngữ: matchType DOUBLES nhưng giới tính lẫn
      // MALE+FEMALE → không gửi genderRestriction (Backend chỉ nhận MIXED cho
      // MIXED_DOUBLES, như web).
      expect(repo.created, [
        {
          'name': 'Đôi nam',
          'matchType': 'DOUBLES',
          'genderRestriction': 'MALE',
        },
        {
          'name': 'Đôi nam nữ',
          'matchType': 'MIXED_DOUBLES',
          'genderRestriction': 'MIXED',
        },
        {'name': 'Trình độ mở', 'matchType': 'SINGLES'},
        {'name': 'Đôi Men Nữ', 'matchType': 'DOUBLES'},
      ]);
      expect(repo.previews, hasLength(1));
      expect(repo.log, [
        'create:Đôi nam',
        'create:Đôi nam nữ',
        'create:Trình độ mở',
        'create:Đôi Men Nữ',
        'preview',
      ]);
      expect(repo.previews.single.groups.map((group) => group.divisionId), [
        'div-new-1',
        'div-new-2',
        'div-new-3',
        'div-new-4',
      ]);

      // Bước xác nhận tắt, preview hiện bình thường.
      expect(find.text(l10n.rosterImportCreateTitle), findsNothing);
      expect(find.text(l10n.rosterImportCreateRow('Đôi nam')), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-03-13b: bỏ chọn rồi kiểm tra trực tiếp — không tạo gì, preview giữ divisionId null như cũ',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      _installPicker(
        _workbook([
          ['Họ và tên VĐV 1', 'Email', 'Nội dung'],
          ['Nguyễn Văn A', 'a@test.vn', 'Đôi nam'],
        ]),
      );
      await _open(tester, _app(repo));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RosterImportSheet)),
      )!;

      // Bỏ chọn nội dung: nút tạo về 0 và bị khoá.
      await tester.ensureVisible(
        find.byKey(const ValueKey('roster-import-create-unmatched:doi nam')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('roster-import-create-unmatched:doi nam')),
      );
      await tester.pump();
      expect(find.text(l10n.rosterImportCreateAndCheck(0)), findsOneWidget);
      final createButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('roster-import-create-divisions')),
      );
      expect(createButton.onPressed, isNull);

      await tester.ensureVisible(
        find.byKey(const ValueKey('roster-import-skip-create')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('roster-import-skip-create')));
      await tester.pumpAndSettle();

      // Không gọi createDivision; preview chạy như cũ với divisionId null,
      // nhập bị chặn vì nội dung chưa khớp (text hiện ở header và footer).
      expect(repo.created, isEmpty);
      expect(repo.previews, hasLength(1));
      expect(repo.previews.single.groups.single.divisionId, isNull);
      expect(
        find.text(l10n.rosterImportDivisionUnmatched('Đôi nam')),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'TC-WP-03-13c: file khớp hết hạng mục có sẵn — không hiện bước xác nhận, preview tự chạy',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      _installPicker(
        _workbook([
          ['Họ và tên VĐV 1', 'Email', 'Nội dung'],
          ['Nguyễn Văn A', 'a@test.vn', 'Đơn nam'],
        ]),
      );
      await _open(tester, _app(repo));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RosterImportSheet)),
      )!;

      expect(find.text(l10n.rosterImportCreateTitle), findsNothing);
      expect(
        find.byKey(const ValueKey('roster-import-create-divisions')),
        findsNothing,
      );
      expect(repo.created, isEmpty);
      expect(repo.previews, hasLength(1));
      expect(repo.previews.single.groups.single.divisionId, 'div-1');
    },
  );

  testWidgets(
    'TC-WP-03-13d: tên hạng mục đảo thứ tự từ khớp hạng mục có sẵn (so khớp bộ từ như web)',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      _installPicker(
        _workbook([
          ['Họ và tên VĐV 1', 'Email', 'Nội dung'],
          ['Nguyễn Văn A', 'a@test.vn', 'Nam đơn'],
        ]),
      );
      await _open(tester, _app(repo));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RosterImportSheet)),
      )!;

      // "Nam đơn" cùng bộ từ với "Đơn nam" có sẵn → khớp, không hiện bước
      // xác nhận tạo hạng mục.
      expect(find.text(l10n.rosterImportCreateTitle), findsNothing);
      expect(repo.created, isEmpty);
      expect(repo.previews, hasLength(1));
      expect(repo.previews.single.groups.single.divisionId, 'div-1');
    },
  );

  group('TC-APP-ROSTER-SHEET: màn nhập ghép cặp, thanh toán và AI', () {
    Future<void> openWith(
      WidgetTester tester,
      Uint8List bytes,
      _Repo repo, {
      String matchType = 'DOUBLES',
      RosterLayoutRepository? layout,
    }) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      _installPicker(bytes);
      await _open(tester, _app(repo, matchType: matchType, layout: layout));
    }

    List<RosterImportBatchItem> sent(_Repo repo) => [
      for (final group in repo.previews.last.groups) ...group.participants,
    ];

    testWidgets(
      'TC-APP-ROSTER-SHEET-01: file mẫu gửi 11 cặp và 7 VĐV lẻ, không ai đã thanh toán, không hỏi AI',
      (tester) async {
        final repo = _Repo();
        final layout = _FakeLayoutRepo(failure: StateError('không được gọi'));
        await openWith(tester, sampleWorkbookBytes(), repo, layout: layout);

        final items = sent(repo);
        expect(items, hasLength(18));
        expect(items.where((i) => i.player2Name != null), hasLength(11));
        expect(items.where((i) => i.player2Name == null), hasLength(7));
        expect(items.every((i) => i.isPaid == false), isTrue);
        expect(items.first.player1Phone, fakePhone(0));
        expect(items.first.player2Phone, fakePhone(1));
        expect(layout.calls, isEmpty);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(RosterImportSheet)),
        )!;
        expect(
          find.text(l10n.rosterImportPendingPartnerCount(7)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TC-APP-ROSTER-SHEET-02: AI không sẵn sàng (aiAvailable:false) giữ kết quả luật và báo trạng thái',
      (tester) async {
        final sample = workbookBytes(
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
        final repo = _Repo();
        final layout = _FakeLayoutRepo(
          response: const RosterLayoutResponse(
            aiAvailable: false,
            layout: null,
          ),
        );
        await openWith(tester, sample, repo, layout: layout);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(RosterImportSheet)),
        )!;
        expect(layout.calls, [false]);
        expect(find.text(l10n.rosterImportAiUnavailable), findsOneWidget);
        // Luật không thấy cặp nào (quá ít dòng cặp), nên cả bảy dòng vẫn được kiểm tra, đều là VĐV lẻ.
        expect(sent(repo), hasLength(7));
        expect(sent(repo).every((i) => i.player2Name == null), isTrue);
      },
    );

    testWidgets(
      'TC-APP-ROSTER-SHEET-03: AI hết lượt (429) hoặc lỗi 503 giữ kết quả luật và báo lỗi',
      (tester) async {
        final sample = workbookBytes(
          [
            ['STT', 'Họ và tên VĐV', 'Số điện thoại liên hệ'],
            [1, fakeName(0), ''],
            [null, fakeName(1), ''],
            [2, fakeName(2), ''],
            [null, fakeName(3), ''],
            [3, fakeName(4), ''],
            [4, fakeName(5), ''],
            [5, fakeName(6), ''],
          ],
          merges: ['A2:A3', 'A4:A5'],
        );
        final repo = _Repo();
        final layout = _FakeLayoutRepo(
          failure: DioException(
            requestOptions: RequestOptions(path: '/ai'),
            response: Response(
              requestOptions: RequestOptions(path: '/ai'),
              statusCode: 429,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        await openWith(tester, sample, repo, layout: layout);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(RosterImportSheet)),
        )!;
        expect(find.text(l10n.rosterImportAiError), findsOneWidget);
        expect(sent(repo), hasLength(7));
      },
    );

    testWidgets(
      'TC-APP-ROSTER-SHEET-04: AI trả CONSECUTIVE_ROWS kèm singlesFromRow thì dùng bố cục AI: 2 cặp và 3 VĐV lẻ',
      (tester) async {
        final sample = workbookBytes(
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
        final repo = _Repo();
        final layout = _FakeLayoutRepo(
          response: RosterLayoutResponse.fromJson({
            'aiAvailable': true,
            'layout': {
              'sheets': [
                {
                  'sheetName': 'S1',
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
        await openWith(tester, sample, repo, layout: layout);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(RosterImportSheet)),
        )!;
        expect(find.text(l10n.rosterImportAiDone), findsOneWidget);
        final items = sent(repo);
        expect(items, hasLength(5));
        expect(items.where((i) => i.player2Name != null), hasLength(2));
        expect(items.every((i) => i.isPaid == false), isTrue);
      },
    );

    testWidgets(
      'TC-APP-ROSTER-SHEET-05: cột Xác nhận BTC được gửi lên theo file, ô gộp theo cặp áp cho cả hai',
      (tester) async {
        final bytes = workbookBytes(
          [
            ['STT', 'Họ và tên VĐV', 'Xác nhận BTC'],
            [1, fakeName(0), 'x'],
            [null, fakeName(1), null],
            [2, fakeName(2), null],
            [null, fakeName(3), null],
          ],
          merges: ['A2:A3', 'C2:C3', 'A4:A5', 'C4:C5'],
        );
        final repo = _Repo();
        await openWith(tester, bytes, repo);

        expect(sent(repo).map((i) => i.isPaid), [true, false]);
        expect(sent(repo).map((i) => i.toJson()['isPaid']), [true, false]);
      },
    );
  });
}
