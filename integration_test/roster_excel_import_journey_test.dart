import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_sheet.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/organizer_ops/roster_excel_corpus.dart';
import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/organizer_journey.dart';
import 'support/shot.dart';

/// TC-ROSTER-E2E-01..06: BTC ném file Excel giả (bộ `rosterCorpus`) vào màn Nhập Excel trên App thật,
/// Backend thật. File picker hệ thống không thao tác được trên emulator nên thay bằng picker giả trả
/// đúng bytes của file; mọi bước còn lại (đọc file, Ghép cột, xem trước trên máy chủ, sửa chi tiết,
/// Nhập) đi qua giao diện và API thật. Dữ liệu 100% giả.
void main() {
  _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final api = BackendApi();

  setUpAll(initializeAppForTests);

  tearDown(
    () => FilePickerPlatform.instance =
        _realPicker ?? FilePickerPlatform.instance,
  );

  testWidgets(
    'TC-ROSTER-E2E-01: file đơn sạch (5 VĐV), nhập xong Backend có đủ 5 VĐV',
    (tester) async {
      final single = await seedTournament(api, players: 0, maxParticipants: 64);
      final item = _caseOf('single-basic');
      final bytes = await _bytesForTournament(api, single, item);

      final container = await signInAsOrganizer(tester);
      await _openImportSheet(tester, container, single.tournamentId);
      await _pickFile(tester, bytes);
      await _waitForCommitReady(tester, expectedCount: 5);
      await snap(tester, 'single-basic-preview');

      await _commit(tester);
      final names = [for (var i = 1; i <= 5; i++) corpusName(i)];
      await _waitBackendHas(tester, single, names);
    },
    timeout: _timeout,
  );

  testWidgets(
    'TC-ROSTER-E2E-02: file đôi hai dòng một cặp, STT gộp: Backend có 4 cặp đủ hai VĐV',
    (tester) async {
      final doubles = await _seedDoubles(api);
      final item = _caseOf('doubles-two-rows-merged-stt');
      final bytes = await _bytesForTournament(api, doubles, item);

      final container = await signInAsOrganizer(tester);
      await _openImportSheet(tester, container, doubles.tournamentId);
      await _pickFile(tester, bytes);
      await _waitForCommitReady(tester, expectedCount: 4);
      await snap(tester, 'doubles-merged-preview');

      await _commit(tester);
      final names = [for (var i = 0; i < 8; i++) corpusName(i)];
      await _waitBackendHas(tester, doubles, names);
    },
    timeout: _timeout,
  );

  testWidgets(
    'TC-ROSTER-E2E-03: cột email tên "Mail" không tự nhận: Ghép cột chọn tay rồi nhập được',
    (tester) async {
      final single = await seedTournament(api, players: 0, maxParticipants: 64);
      final item = _caseOf('single-header-mail-only');
      final bytes = await _bytesForTournament(api, single, item);

      final container = await signInAsOrganizer(tester);
      await _openImportSheet(tester, container, single.tournamentId);
      await _pickFile(tester, bytes);
      // Chưa ghép cột email thì chưa ai nhập được.
      await expectKey(tester, 'roster-import-open-mapping');
      await snap(tester, 'mail-chua-ghep');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('roster-import-commit')),
            )
            .onPressed,
        isNull,
        reason: 'thiếu email thì nút Nhập phải tắt',
      );

      // Cột C (chỉ số 2) là "Mail": gán thành email VĐV 1 trong popup Ghép cột.
      await tapKey(tester, 'roster-import-open-mapping');
      await tapKey(tester, 'roster-map-column-2');
      await tapKey(tester, 'roster-map-chip-2-player1Email');
      await snap(tester, 'mail-da-chon-cot');
      await tapKey(tester, 'roster-map-done');
      await _waitForCommitReady(tester, expectedCount: 4);

      await _commit(tester);
      final names = [for (var i = 1; i <= 4; i++) corpusName(i)];
      await _waitBackendHas(tester, single, names);
    },
    timeout: _timeout,
  );

  testWidgets(
    'TC-ROSTER-E2E-04: email hỏng và trống: chỉ dòng hợp lệ nhập được, sửa email trong chi tiết thì thêm dòng',
    (tester) async {
      final single = await seedTournament(api, players: 0, maxParticipants: 64);
      final item = _caseOf('single-invalid-email');
      final bytes = await _bytesForTournament(api, single, item);

      final container = await signInAsOrganizer(tester);
      await _openImportSheet(tester, container, single.tournamentId);
      await _pickFile(tester, bytes);
      // 4 dòng: hợp lệ chỉ có dòng 3; dòng 1 email sai, dòng 2 trống, dòng 4 email sai.
      await _waitForCommitReady(tester, expectedCount: 1);
      await snap(tester, 'invalid-email-preview');

      // Sửa email dòng 1 (chỉ số 0) trong sheet chi tiết rồi chờ xem trước chạy lại.
      await tapKey(tester, 'roster-row-0');
      await expectKey(tester, 'roster-detail-email-1');
      await tester.enterText(
        find.byKey(const ValueKey('roster-detail-email-1')),
        corpusEmail(901),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await snap(tester, 'invalid-email-detail');
      await tapKey(tester, 'roster-detail-done');
      await _waitForCommitReady(tester, expectedCount: 2);

      await _commit(tester);
      await _waitBackendHas(tester, single, [corpusName(1), corpusName(3)]);
      final manage = await _fetchManage(single.token, single.tournamentId);
      expect(
        jsonEncode(manage),
        isNot(contains(corpusName(2))),
        reason: 'dòng thiếu email không được nhập',
      );
    },
    timeout: _timeout,
  );

  testWidgets(
    'TC-ROSTER-E2E-05: file 501 dòng vượt giới hạn: báo lý do và tắt nút Nhập',
    (tester) async {
      final single = await seedTournament(api, players: 0, maxParticipants: 64);
      final item = _caseOf('limit-501');
      final bytes = await _bytesForTournament(api, single, item);

      final container = await signInAsOrganizer(tester);
      await _openImportSheet(tester, container, single.tournamentId);
      await _pickFile(tester, bytes);
      await pumpUntilCondition(
        tester,
        () => find.textContaining('501').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 60),
        what: 'thông báo vượt giới hạn dòng (có số 501)',
      );
      await snap(tester, 'limit-501');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('roster-import-commit')),
            )
            .onPressed,
        isNull,
        reason: 'vượt giới hạn thì không được nhập',
      );
      final manage = await _fetchManage(single.token, single.tournamentId);
      expect(manage, isEmpty, reason: 'chưa nhập gì lên Backend');
    },
    timeout: _timeout,
  );

  testWidgets(
    'TC-ROSTER-E2E-06: file không phải xlsx: báo không đọc được, sheet vẫn dùng được',
    (tester) async {
      final single = await seedTournament(api, players: 0, maxParticipants: 64);
      final container = await signInAsOrganizer(tester);
      await _openImportSheet(tester, container, single.tournamentId);
      await _pickFile(tester, Uint8List.fromList(List.filled(64, 7)));
      await pumpUntilCondition(
        tester,
        () => find
            .textContaining('Không đọc được file Excel')
            .evaluate()
            .isNotEmpty,
        what: 'thông báo không đọc được file Excel',
      );
      await snap(tester, 'file-hong');
      await expectKey(tester, 'roster-import-pick-file');
      expect(find.byType(RosterImportSheet), findsOneWidget);
    },
    timeout: _timeout,
  );
}

const _timeout = Timeout(Duration(minutes: 10));

late IntegrationTestWidgetsFlutterBinding _binding;
FilePickerPlatform? _realPicker;
WidgetTester? _convertedFor;
var _shotCount = 0;

Future<void> snap(WidgetTester tester, String name) async {
  if (!identical(_convertedFor, tester)) {
    await _binding.convertFlutterSurfaceToImage();
    _convertedFor = tester;
  }
  await tester.pump();
  _shotCount++;
  await shot(_binding, 'roster-${_shotCount.toString().padLeft(3, '0')}-$name');
}

RosterCorpusCase _caseOf(String id) =>
    rosterCorpus().firstWhere((item) => item.id == id);

/// Giải đôi dựng bằng API (BTC tạo, ADMIN duyệt), chưa có VĐV nào.
Future<SeededTournament> _seedDoubles(BackendApi api) async {
  final tag = 'E2E${DateTime.now().millisecondsSinceEpoch}D';
  final token = await api.login(kOrganizerEmail, kE2ePassword);
  final created = await api.createLiteTournament(
    token: token,
    name: '$tag Giải đôi',
    matchType: 'DOUBLES',
    maxParticipants: 32,
  );
  await api.approveTournamentAsAdmin(created.tournamentId);
  return SeededTournament(
    token: token,
    tournamentId: created.tournamentId,
    divisionId: created.divisionId,
    name: '$tag Giải đôi',
    tag: tag,
  );
}

/// Bytes của file, sheet đầu mang đúng tên nội dung của giải để dòng vào thẳng nội dung có sẵn
/// (tên sheet khác thì màn Nhập hỏi tạo nội dung mới, là luồng khác).
Future<Uint8List> _bytesForTournament(
  BackendApi api,
  SeededTournament tournament,
  RosterCorpusCase item,
) async {
  final divisions = await api.listDivisions(tournament.tournamentId);
  final name = divisions.first['name'] as String;
  final first = item.sheets.first;
  return rosterCorpusBytes([
    RosterCorpusSheet(name, first.rows, merges: first.merges),
    ...item.sheets.skip(1),
  ]);
}

Future<void> _openImportSheet(
  WidgetTester tester,
  ProviderContainer container,
  String tournamentId,
) async {
  await openManageHub(tester, container, tournamentId);
  await openHubTab(tester, 'VĐV');
  await tapKey(tester, 'athletes-more');
  await tapKey(tester, 'athletes-import-excel');
  await expectKey(tester, 'roster-import-sheet', step: 'sheet Nhập Excel');
}

/// Gắn picker giả trả [bytes] rồi bấm nút chọn file như người dùng.
Future<void> _pickFile(WidgetTester tester, Uint8List bytes) async {
  _realPicker ??= FilePickerPlatform.instance;
  FilePickerPlatform.instance = _FakePicker(bytes);
  await tapKey(tester, 'roster-import-pick-file');
}

/// Chờ xem trước trên máy chủ xong: nút Nhập bật và nhãn có đúng [expectedCount] dòng nhập được.
Future<void> _waitForCommitReady(
  WidgetTester tester, {
  required int expectedCount,
}) async {
  final commit = find.byKey(const ValueKey('roster-import-commit'));
  await pumpUntilCondition(
    tester,
    () {
      if (commit.evaluate().isEmpty) return false;
      final button = tester.widget<FilledButton>(commit);
      final label = find
          .descendant(of: commit, matching: find.byType(Text))
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .join(' ');
      return button.onPressed != null && label.contains('$expectedCount');
    },
    timeout: const Duration(seconds: 90),
    what: 'nút Nhập bật với $expectedCount dòng (xem trước trên máy chủ xong)',
  );
}

Future<void> _commit(WidgetTester tester) async {
  await tapKey(tester, 'roster-import-commit');
  await pumpUntilCondition(
    tester,
    () => find.byKey(const ValueKey('roster-import-sheet')).evaluate().isEmpty,
    timeout: const Duration(seconds: 90),
    what: 'sheet Nhập Excel đóng sau khi nhập xong',
  );
}

Future<void> _waitBackendHas(
  WidgetTester tester,
  SeededTournament tournament,
  List<String> names,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (true) {
    final dump = jsonEncode(
      await _fetchManage(tournament.token, tournament.tournamentId),
    );
    final missing = names.where((name) => !dump.contains(name)).toList();
    if (missing.isEmpty) return;
    if (DateTime.now().isAfter(deadline)) {
      fail('Hết 60s mà Backend chưa có đủ VĐV; thiếu: $missing');
    }
    await tester.pump(const Duration(seconds: 1));
  }
}

final _http = Dio(
  BaseOptions(
    baseUrl: kE2eApiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    contentType: Headers.jsonContentType,
    validateStatus: (_) => true,
  ),
);

/// Danh sách đầy đủ cho BTC (`GET /tournaments/:id/manage/participants`), cùng nguồn với màn VĐV.
Future<List<Map<String, dynamic>>> _fetchManage(
  String token,
  String tournamentId,
) async {
  final response = await _http.get<Object?>(
    '/tournaments/$tournamentId/manage/participants',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  final code = response.statusCode ?? 0;
  if (code < 200 || code >= 300) {
    throw StateError('manage/participants -> HTTP $code');
  }
  final body = response.data;
  final data = body is Map && body.containsKey('data') ? body['data'] : body;
  if (data is! List) {
    throw StateError('manage/participants không trả danh sách');
  }
  return data
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// File picker giả: trả về workbook dựng sẵn như người dùng vừa chọn.
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
