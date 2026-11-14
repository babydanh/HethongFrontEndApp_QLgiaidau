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

class _NoAiRepo implements RosterLayoutRepository {
  @override
  Future<RosterLayoutResponse> analyzeRosterLayout(
    String tournamentId, {
    required List<Map<String, dynamic>> sheets,
    String locale = 'vi',
    bool retryEmptyLayout = false,
  }) async => const RosterLayoutResponse(aiAvailable: false, layout: null);
}

/// Repository giả. Khi [holdPreviews]/[importGate] bật thì câu trả lời chờ test mở khóa,
/// để dựng đúng thứ tự đến muộn của preview.
class _Repo implements TournamentManagementRepository {
  final previews = <RosterImportBatchRequest>[];
  final imports = <RosterImportBatchRequest>[];
  final candidatesByEmail = <String, RosterImportBatchCandidate>{};
  bool holdPreviews = false;
  final previewGates = <Completer<void>>[];
  Completer<void>? importGate;
  Object? importFailure;

  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async =>
      const [];

  @override
  Future<RosterImportBatchPreview> previewRosterImportBatch(
    String id,
    RosterImportBatchRequest request,
  ) async {
    previews.add(request);
    if (holdPreviews) {
      final gate = Completer<void>();
      previewGates.add(gate);
      await gate.future;
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
                  status: const ['NOT_FOUND'],
                  isEligible: true,
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
            capacityRemaining: 1000,
            capacityRemainingAfterBatch: 999,
            capacityFits: true,
          ),
      ],
    );
  }

  @override
  Future<RosterImportBatchResult> importRosterBatch(
    String id,
    RosterImportBatchRequest request,
  ) async {
    imports.add(request);
    final gate = importGate;
    if (gate != null) await gate.future;
    final failure = importFailure;
    if (failure != null) {
      importFailure = null;
      throw failure;
    }
    return const RosterImportBatchResult(importedCount: 1, replayed: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _division = TournamentDivision(
  id: 'div-1',
  name: 'Đơn nam',
  matchType: 'SINGLES',
);

final _tournament = Tournament(
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
  divisions: const [_division],
);

FilePickerPlatform? _previousPicker;

Future<void> _open(WidgetTester tester, Uint8List bytes, _Repo repo) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _previousPicker = FilePickerPlatform.instance;
  FilePickerPlatform.instance = _FakePicker(bytes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWith((ref) => repo),
        rosterLayoutRepositoryProvider.overrideWith((ref) => _NoAiRepo()),
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
                    tournament: _tournament,
                    defaultDivision: _division,
                    onRefresh: () async {},
                  ),
                ),
                child: const Text('Mở sheet'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('roster-import-pick-file')));
  await tester.pumpAndSettle();
}

Finder _key(String key) => find.byKey(ValueKey(key));

List<RosterImportBatchItem> _sent(_Repo repo) => [
  for (final group in repo.previews.last.groups) ...group.participants,
];

/// Ba VĐV một dòng, email a/b/c; dòng đầu có thể có email sai định dạng.
Uint8List _file({String firstEmail = 'a@example.com'}) => workbookBytes([
  ['STT', 'Họ và tên VĐV', 'Email'],
  [1, fakeName(0), firstEmail],
  [2, fakeName(1), 'b@example.com'],
  [3, fakeName(2), 'c@example.com'],
]);

Future<void> _tapRow(WidgetTester tester, int index) async {
  await tester.ensureVisible(_key('roster-row-$index'));
  await tester.tap(_key('roster-row-$index'));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(_key(key));
  await tester.enterText(_key(key), text);
  await tester.pump();
}

/// [settle] false khi preview đang bị giữ: vòng tải chạy mãi nên chỉ bơm vài khung hình.
Future<void> _tapDone(WidgetTester tester, {bool settle = true}) async {
  await tester.ensureVisible(_key('roster-detail-done'));
  await tester.tap(_key('roster-detail-done'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// Mở dòng [index], sửa các ô trong [fields], bấm Xong.
Future<void> _edit(
  WidgetTester tester,
  int index,
  Map<String, String> fields, {
  bool settle = true,
}) async {
  await _tapRow(tester, index);
  for (final entry in fields.entries) {
    await _enter(tester, entry.key, entry.value);
  }
  await _tapDone(tester, settle: settle);
}

Future<void> _deleteRowViaDetail(WidgetTester tester, int index) async {
  await _tapRow(tester, index);
  await tester.ensureVisible(_key('roster-detail-delete'));
  await tester.tap(_key('roster-detail-delete'));
  await tester.pumpAndSettle();
}

bool _commitEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_key('roster-import-commit')).onPressed != null;

RosterImportBatchItem _item(_Repo repo, int clientRowIndex) =>
    _sent(repo).firstWhere((i) => i.clientRowIndex == clientRowIndex);

void main() {
  tearDown(() {
    final previous = _previousPicker;
    if (previous != null) {
      FilePickerPlatform.instance = previous;
      _previousPicker = null;
    }
  });

  testWidgets(
    'TC-ROSTERLIST-10 sửa email sai thành đúng thì hết chặn và preview chạy lại một lần',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _file(firstEmail: 'khong-hop-le'), repo);
      expect(repo.previews, hasLength(1));
      expect(
        _key('roster-card-status-blocked'),
        findsOneWidget,
        reason: 'dòng email sai bị chặn cục bộ',
      );

      await _edit(tester, 0, {'roster-detail-email-1': 'moi@example.com'});

      expect(repo.previews, hasLength(2));
      expect(_item(repo, 0).player1Email, 'moi@example.com');
      expect(_key('roster-card-status-blocked'), findsNothing);
    },
  );

  testWidgets(
    'TC-ROSTERLIST-11 đổi email của VĐV đã tự liên kết thì payload bỏ tài khoản cũ',
    (tester) async {
      final repo = _Repo()
        ..candidatesByEmail['a@example.com'] = const RosterImportBatchCandidate(
          userId: 'u-a',
          email: 'a@example.com',
          fullName: 'Tài khoản A',
        );
      await _open(tester, _file(), repo);
      // Chọn tay tài khoản trong chi tiết: liên kết `linked`, không phải tự liên kết.
      await _tapRow(tester, 0);
      await tester.ensureVisible(_key('roster-detail-account-1'));
      await tester.tap(_key('roster-detail-account-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tài khoản A (a@example.com)'));
      await tester.pumpAndSettle();
      await _tapDone(tester);
      expect(_item(repo, 0).confirmedPlayer1UserId, 'u-a');

      await _edit(tester, 0, {'roster-detail-email-1': 'a2@example.com'});

      expect(_item(repo, 0).player1Email, 'a2@example.com');
      expect(_item(repo, 0).confirmedPlayer1UserId, isNull);
    },
  );

  testWidgets(
    'TC-ROSTERLIST-12 chỉ đổi tên thì payload vẫn có tài khoản đã liên kết',
    (tester) async {
      final repo = _Repo()
        ..candidatesByEmail['a@example.com'] = const RosterImportBatchCandidate(
          userId: 'u-a',
          email: 'a@example.com',
          fullName: 'Tài khoản A',
        );
      await _open(tester, _file(), repo);

      await _edit(tester, 0, {'roster-detail-name-1': 'Tên Mới'});

      expect(_item(repo, 0).player1Name, 'Tên Mới');
      expect(_item(repo, 0).confirmedPlayer1UserId, 'u-a');
    },
  );

  testWidgets(
    'TC-ROSTERLIST-13 sửa thành trùng email dòng khác thì cả hai bị chặn và không vào payload',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _file(), repo);

      await _edit(tester, 1, {'roster-detail-email-1': 'a@example.com'});

      expect(_key('roster-card-status-blocked'), findsNWidgets(2));
      expect(_sent(repo).map((i) => i.player1Email), ['c@example.com']);
    },
  );

  testWidgets(
    'TC-ROSTERLIST-14 xóa cặp bỏ dòng, chạy lại preview, xóa hết thì không preview rỗng',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _file(), repo);

      await _deleteRowViaDetail(tester, 1);

      expect(_key('roster-row-1'), findsNothing);
      expect(repo.previews, hasLength(2));
      expect(_sent(repo).map((i) => i.clientRowIndex), [0, 2]);

      await _deleteRowViaDetail(tester, 0);
      await _deleteRowViaDetail(tester, 2);

      expect(_key('roster-row-0'), findsNothing);
      expect(_key('roster-row-2'), findsNothing);
      expect(
        repo.previews,
        hasLength(3),
        reason: 'xóa dòng cuối: không gửi payload rỗng',
      );
    },
  );

  testWidgets(
    'TC-ROSTERLIST-15 Hoàn tác trong 5 giây trả dòng về đúng vị trí và chỉ số',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _file(), repo);
      await _deleteRowViaDetail(tester, 1);
      expect(_key('roster-list-undo-bar'), findsOneWidget);

      await tester.tap(_key('roster-list-undo'));
      await tester.pumpAndSettle();

      expect(repo.previews, hasLength(3));
      expect(_sent(repo).map((i) => i.clientRowIndex), [0, 1, 2]);
      final y = [
        for (final i in [0, 1, 2]) tester.getTopLeft(_key('roster-row-$i')).dy,
      ];
      expect(y[0] < y[1] && y[1] < y[2], isTrue);
      expect(_key('roster-list-undo-bar'), findsNothing);
    },
  );

  testWidgets('TC-ROSTERLIST-15 thanh Hoàn tác tự mất sau 5 giây', (
    tester,
  ) async {
    final repo = _Repo();
    await _open(tester, _file(), repo);
    await _deleteRowViaDetail(tester, 1);

    await tester.pump(const Duration(seconds: 6));

    expect(_key('roster-list-undo-bar'), findsNothing);
  });

  testWidgets(
    'TC-ROSTERLIST-16 sửa dòng khác sau khi xóa thì Hoàn tác hết tác dụng',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _file(), repo);
      await _deleteRowViaDetail(tester, 1);

      await _edit(tester, 0, {'roster-detail-name-1': 'Tên Mới'});

      expect(_key('roster-list-undo-bar'), findsNothing);
      expect(_key('roster-row-1'), findsNothing);
    },
  );

  testWidgets(
    'TC-ROSTERLIST-17 thêm cặp: chỉ số nhỏ nhất chưa dùng, không có dòng nguồn trong JSON',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _file(), repo);
      await _deleteRowViaDetail(tester, 1);

      await tester.tap(_key('roster-import-add'));
      await tester.pumpAndSettle();
      await _enter(tester, 'roster-detail-name-1', 'Người Mới');
      await _enter(tester, 'roster-detail-email-1', 'new@example.com');
      await _tapDone(tester);

      expect(_key('roster-row-1'), findsOneWidget);
      expect(repo.previews.last.groups, hasLength(1));
      final json = _item(repo, 1).toJson();
      expect(json['player1Name'], 'Người Mới');
      expect(json.containsKey('sourceRowIndex'), isFalse);
      expect(json.containsKey('sourceSheetName'), isFalse);
    },
  );

  testWidgets(
    'TC-ROSTERLIST-18 thêm cặp rồi Xong khi rỗng thì không có gì mới',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _file(), repo);

      await tester.tap(_key('roster-import-add'));
      await tester.pumpAndSettle();
      await _tapDone(tester);

      expect(_key('roster-row-3'), findsNothing);
      expect(repo.previews, hasLength(1));
    },
  );

  testWidgets('TC-ROSTERLIST-19 đủ 500 dòng thì nút thêm bị tắt', (
    tester,
  ) async {
    final repo = _Repo();
    final bytes = workbookBytes([
      ['STT', 'Họ và tên VĐV', 'Email'],
      for (var i = 0; i < 500; i++) [i + 1, 'Mẫu Văn $i', 'u$i@example.com'],
    ]);
    await _open(tester, bytes, repo);

    expect(
      tester.widget<IconButton>(_key('roster-import-add')).onPressed,
      isNull,
    );
  });

  testWidgets(
    'TC-ROSTERLIST-20 sửa xong mà preview mới chưa về thì nút Nhập tắt',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _file(), repo);
      expect(_commitEnabled(tester), isTrue);

      repo.holdPreviews = true;
      await _edit(tester, 0, {
        'roster-detail-name-1': 'Tên Mới',
      }, settle: false);

      expect(_commitEnabled(tester), isFalse);
      repo.previewGates.single.complete();
      await tester.pumpAndSettle();
      expect(_commitEnabled(tester), isTrue);
    },
  );

  testWidgets('TC-ROSTERLIST-21 preview của lần sửa trước đến muộn thì bị bỏ', (
    tester,
  ) async {
    final repo = _Repo();
    await _open(tester, _file(), repo);
    repo.holdPreviews = true;

    await _edit(tester, 0, {'roster-detail-name-1': 'Lần Một'}, settle: false);
    await _edit(tester, 0, {'roster-detail-name-1': 'Lần Hai'}, settle: false);
    expect(repo.previewGates, hasLength(2));

    repo.previewGates[1].complete();
    await tester.pumpAndSettle();
    repo.previewGates[0].complete();
    await tester.pumpAndSettle();

    expect(
      _commitEnabled(tester),
      isTrue,
      reason: 'preview lần một không được đè preview lần hai',
    );
  });

  testWidgets('TC-ROSTERLIST-22 đang nhập thì chạm thẻ không mở chi tiết', (
    tester,
  ) async {
    final repo = _Repo()..importGate = Completer<void>();
    await _open(tester, _file(), repo);

    await tester.tap(_key('roster-import-commit'));
    await tester.pump();
    await tester.tap(_key('roster-row-0'));
    await tester.pump();

    expect(_key('roster-detail-name-1'), findsNothing);
    expect(
      tester.widget<IconButton>(_key('roster-import-add')).onPressed,
      isNull,
    );
    repo.importGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('TC-ROSTERLIST-23 bấm Nhập hai lần chỉ gửi một request', (
    tester,
  ) async {
    final repo = _Repo()..importGate = Completer<void>();
    await _open(tester, _file(), repo);

    await tester.tap(_key('roster-import-commit'));
    await tester.tap(_key('roster-import-commit'), warnIfMissed: false);
    await tester.pump();

    expect(repo.imports, hasLength(1));
    repo.importGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('TC-ROSTERLIST-24 nhập lỗi mạng rồi bấm lại gửi cùng payload', (
    tester,
  ) async {
    final repo = _Repo()..importFailure = Exception('mạng');
    await _open(tester, _file(), repo);

    await tester.tap(_key('roster-import-commit'));
    await tester.pumpAndSettle();
    await tester.tap(_key('roster-import-commit'));
    await tester.pumpAndSettle();

    expect(repo.imports, hasLength(2));
    expect(repo.imports[1].toJson(), repo.imports[0].toJson());
  });

  testWidgets(
    'TC-ROSTERLIST-25 đã sửa tay rồi bấm Ghép cột thì hỏi xác nhận, hủy thì không đổi gì',
    (tester) async {
      final repo = _Repo();
      await _open(tester, _file(), repo);
      await _edit(tester, 0, {'roster-detail-name-1': 'Tên Mới'});
      final previews = repo.previews.length;

      await tester.ensureVisible(_key('roster-import-open-mapping'));
      await tester.tap(_key('roster-import-open-mapping'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ghép lại sẽ bỏ các sửa tay trong danh sách. Tiếp tục?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(_key('roster-map-done'), findsNothing);
      expect(repo.previews, hasLength(previews));
      expect(_item(repo, 0).player1Name, 'Tên Mới');

      await tester.tap(_key('roster-import-open-mapping'));
      await tester.pumpAndSettle();
      await tester.tap(_key('roster-list-reset-confirm'));
      await tester.pumpAndSettle();
      expect(_key('roster-map-done'), findsOneWidget);
    },
  );
}
