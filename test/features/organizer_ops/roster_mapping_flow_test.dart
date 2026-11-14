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
import 'roster_mapping_fixture.dart';

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

/// AI layout giả: trả lời khi test cho phép ([release]) hoặc ngay lập tức.
class _GatedLayoutRepo implements RosterLayoutRepository {
  _GatedLayoutRepo(this.response, {this.gated = false});

  final RosterLayoutResponse response;
  final bool gated;
  final _gate = Completer<void>();
  int calls = 0;

  void release() => _gate.complete();

  @override
  Future<RosterLayoutResponse> analyzeRosterLayout(
    String tournamentId, {
    required List<Map<String, dynamic>> sheets,
    String locale = 'vi',
    bool retryEmptyLayout = false,
  }) async {
    calls++;
    if (gated) await _gate.future;
    return response;
  }
}

const _noAi = RosterLayoutResponse(aiAvailable: false, layout: null);

/// Repository giả: ghi payload preview, có thể ném lỗi từ lần preview thứ [failFromCall],
/// và trả ứng viên tài khoản cho các email trong [candidatesByEmail].
class _Repo implements TournamentManagementRepository {
  _Repo({this.failFromCall, this.candidatesByEmail = const {}});

  final int? failFromCall;
  final Map<String, RosterImportBatchCandidate> candidatesByEmail;
  final created = <Map<String, dynamic>>[];
  final previews = <RosterImportBatchRequest>[];

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
    final failFrom = failFromCall;
    if (failFrom != null && previews.length >= failFrom) {
      throw StateError('preview lỗi');
    }
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
                  player1Candidates: [
                    ?candidatesByEmail[item.player1Email],
                  ],
                  player2Candidates: const [],
                  confirmedPlayer1UserId: item.confirmedPlayer1UserId,
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

Widget _app(_Repo repo, RosterLayoutRepository layout, String matchType) =>
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWith((ref) => repo),
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

/// Mở màn nhập, chọn file giả và chờ đọc xong.
Future<AppLocalizations> _start(
  WidgetTester tester,
  Uint8List bytes,
  _Repo repo, {
  RosterLayoutRepository? layout,
  String matchType = 'SINGLES',
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  _previousPicker = FilePickerPlatform.instance;
  FilePickerPlatform.instance = _FakePicker(bytes);
  await tester.pumpWidget(
    _app(repo, layout ?? _GatedLayoutRepo(_noAi), matchType),
  );
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('roster-import-pick-file')));
  // Vòng quay "AI đang đọc" không bao giờ yên, nên không chờ pumpAndSettle khi AI chưa trả lời.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
  return AppLocalizations.of(tester.element(find.byType(RosterImportSheet)))!;
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openMapping(WidgetTester tester) =>
    _tap(tester, _key('roster-import-open-mapping'));

/// Gán cột [column] vào chip [chip] (`player1Name`, `note`...) trong popup đang mở.
Future<void> _assign(WidgetTester tester, int column, String chip) async {
  await _tap(tester, _key('roster-map-col-$column'));
  await _tap(tester, _key('roster-map-chip-$chip'));
}

List<RosterImportBatchItem> _sent(_Repo repo) => [
  for (final group in repo.previews.last.groups) ...group.participants,
];

VoidCallback? _onPressed(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(_key(key)).onPressed;

/// Bảy dòng: hai cặp gộp STT và ba VĐV lẻ; luật không đủ tin với nội dung đôi nên hỏi AI.
Uint8List _aiTriggerBytes() => workbookBytes(
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

void main() {
  tearDown(() {
    final previous = _previousPicker;
    if (previous != null) {
      FilePickerPlatform.instance = previous;
      _previousPicker = null;
    }
  });

  testWidgets(
    'TC-ROSTERMAP-25 đổi cột rồi Xong: preview mới mang tên từ cột mới, đúng một lần',
    (tester) async {
      final repo = _Repo();
      await _start(tester, sampleUserLayoutBytes(), repo);
      expect(repo.previews, hasLength(1));
      expect(_sent(repo).first.player1Name, fakeName(0));

      await _openMapping(tester);
      await _assign(tester, 2, 'player1Name');
      await _tap(tester, _key('roster-map-done'));

      expect(repo.previews, hasLength(2));
      expect(_sent(repo).first.player1Name, 'Công ty X');
    },
  );

  testWidgets(
    'TC-ROSTERMAP-26 đóng popup không Xong: không preview mới, danh sách không đổi',
    (tester) async {
      final repo = _Repo();
      await _start(tester, sampleUserLayoutBytes(), repo);

      await _openMapping(tester);
      await _assign(tester, 2, 'player1Name');
      await _tap(tester, _key('roster-map-close'));

      expect(repo.previews, hasLength(1));
      expect(find.text(fakeName(0)), findsWidgets);
      expect(find.text('Công ty X'), findsNothing);
    },
  );

  testWidgets(
    'TC-ROSTERMAP-27 nút Ghép cột tắt khi AI đang đọc và bật sau khi AI trả lời',
    (tester) async {
      final layout = _GatedLayoutRepo(_noAi, gated: true);
      await _start(
        tester,
        _aiTriggerBytes(),
        _Repo(),
        layout: layout,
        matchType: 'DOUBLES',
        settle: false,
      );

      expect(_key('roster-import-ai-checking'), findsOneWidget);
      expect(_onPressed(tester, 'roster-import-open-mapping'), isNull);

      layout.release();
      await tester.pumpAndSettle();

      expect(_key('roster-import-ai-checking'), findsNothing);
      expect(_onPressed(tester, 'roster-import-open-mapping'), isNotNull);
    },
  );

  testWidgets(
    'TC-ROSTERMAP-28 sau khi Xong, thông báo bố cục AI biến mất và bản sửa được giữ',
    (tester) async {
      final repo = _Repo();
      final layout = _GatedLayoutRepo(
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
      final l10n = await _start(
        tester,
        _aiTriggerBytes(),
        repo,
        layout: layout,
        matchType: 'DOUBLES',
      );
      expect(find.text(l10n.rosterImportAiDone), findsOneWidget);

      await _openMapping(tester);
      await _assign(tester, 2, 'note');
      await _tap(tester, _key('roster-map-done'));

      expect(find.text(l10n.rosterImportAiDone), findsNothing);
      expect(layout.calls, 1);
      expect(repo.previews, hasLength(2));
      expect(_sent(repo).first.player1Name, fakeName(0));
      expect(_sent(repo).first.player1Phone, isNull);
    },
  );

  testWidgets(
    'TC-ROSTERMAP-29 nội dung đã tạo không bị hỏi tạo lại sau Ghép cột',
    (tester) async {
      final repo = _Repo();
      final l10n = await _start(
        tester,
        workbookBytes([
          ['Họ và tên VĐV 1', 'Email', 'Nội dung'],
          ['Nguyễn Văn A', 'a@test.vn', 'Hạng mục lạ'],
        ]),
        repo,
      );
      expect(find.text(l10n.rosterImportCreateTitle), findsOneWidget);
      await _tap(tester, _key('roster-import-create-divisions'));
      expect(repo.created, hasLength(1));
      expect(repo.previews, hasLength(1));

      await _openMapping(tester);
      await _assign(tester, 1, 'note');
      await _tap(tester, _key('roster-map-done'));

      expect(find.text(l10n.rosterImportCreateTitle), findsNothing);
      expect(repo.created, hasLength(1));
      expect(repo.previews, hasLength(2));
    },
  );

  testWidgets(
    'TC-ROSTERMAP-30 sheet không có dòng tiêu đề được cứu qua popup',
    (tester) async {
      final repo = _Repo();
      final l10n = await _start(
        tester,
        workbookBytes([
          ['aaa', 'bbb'],
          [fakeName(0), fakePhone(0)],
          [fakeName(1), fakePhone(1)],
        ]),
        repo,
      );
      expect(
        find.text(l10n.rosterImportNoSheetHeader('Đôi Nam')),
        findsOneWidget,
      );
      expect(repo.previews, isEmpty);

      await _openMapping(tester);
      await _assign(tester, 0, 'player1Name');
      await _tap(tester, _key('roster-map-done'));

      expect(
        find.text(l10n.rosterImportNoSheetHeader('Đôi Nam')),
        findsNothing,
      );
      expect(repo.previews, hasLength(1));
      expect(_sent(repo).map((i) => i.player1Name), [fakeName(0), fakeName(1)]);
    },
  );

  testWidgets(
    'TC-ROSTERMAP-31 preview lỗi sau Xong hiện Thử lại và tắt nút nhập',
    (tester) async {
      final repo = _Repo(failFromCall: 2);
      final l10n = await _start(tester, sampleUserLayoutBytes(), repo);
      expect(_onPressed(tester, 'roster-import-commit'), isNotNull);

      await _openMapping(tester);
      await _assign(tester, 2, 'player1Name');
      await _tap(tester, _key('roster-map-done'));

      expect(find.text(l10n.rosterImportRetry), findsOneWidget);
      expect(_onPressed(tester, 'roster-import-commit'), isNull);
    },
  );

  testWidgets(
    'TC-ROSTERMAP-32 sau Ghép cột, tài khoản tự liên kết do màn quyết định và lựa chọn tay bị đặt lại',
    (tester) async {
      const candidate = RosterImportBatchCandidate(
        userId: 'user-1',
        email: 'x@example.com',
        fullName: 'Mẫu X',
      );
      final repo = _Repo(candidatesByEmail: {'x@example.com': candidate});
      final l10n = await _start(
        tester,
        workbookBytes([
          ['Họ và tên VĐV', 'Email', 'Số điện thoại'],
          [fakeName(0), 'x@example.com', fakePhone(0)],
        ]),
        repo,
      );
      expect(_sent(repo).single.confirmedPlayer1UserId, 'user-1');

      await _tap(tester, _key('roster-account-0-1'));
      await tester.tap(find.text(l10n.rosterImportLeaveUnlinked).last);
      await tester.pumpAndSettle();
      expect(_sent(repo).single.confirmedPlayer1UserId, isNull);

      await _openMapping(tester);
      await _assign(tester, 2, 'note');
      await _tap(tester, _key('roster-map-done'));

      expect(_sent(repo).single.confirmedPlayer1UserId, 'user-1');
    },
  );
}
