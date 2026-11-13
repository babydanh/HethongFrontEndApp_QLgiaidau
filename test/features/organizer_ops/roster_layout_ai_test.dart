import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_roster_layout_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout_digest.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'roster_fixture_workbook.dart';

const _columns = <String, String>{
  'pairCode': '',
  'teamName': '',
  'player1Name': 'B',
  'player1Email': '',
  'player1Phone': 'C',
  'player2Name': '',
  'player2Email': '',
  'player2Phone': '',
  'divisionName': '',
  'isPaid': '',
  'elo': '',
  'notes': '',
};

RosterLayout _layout(Map<String, dynamic> block) => RosterLayout.fromJson({
  'sheets': [
    {
      'sheetName': 'S1',
      'kind': 'ROSTER',
      'blocks': [block],
    },
  ],
  'notes': <String>[],
});

Map<String, dynamic> _block({
  String pairLayout = 'CONSECUTIVE_ROWS',
  Object? singlesFromRow,
  int lastDataRow = 8,
}) => {
  'divisionLabel': 'Đôi Nam',
  'headerRow': 1,
  'firstDataRow': 2,
  'lastDataRow': lastDataRow,
  'columns': _columns,
  'pairLayout': pairLayout,
  'pairSeparator': '',
  'singlesFromRow': ?singlesFromRow,
};

// Hai cặp gộp, rồi ba VĐV có STT riêng: quá ít dòng cặp cho luật, đủ bằng chứng gộp cho AI.
Future<List<List<FixtureCell>>> _mixedRows() async => [
  ['STT', 'Họ và tên VĐV', 'Số điện thoại liên hệ'],
  [1, fakeName(0), fakePhone(0)],
  [null, fakeName(1), fakePhone(1)],
  [2, fakeName(2), fakePhone(2)],
  [null, fakeName(3), fakePhone(3)],
  [3, fakeName(4), fakePhone(4)],
  [4, fakeName(5), fakePhone(5)],
  [5, fakeName(6), fakePhone(6)],
];
const _mixedMerges = ['A2:A3', 'A4:A5'];

class _LayoutAdapter implements HttpClientAdapter {
  RequestOptions? last;
  int status = 200;
  Object body = {
    'data': {'aiAvailable': false, 'layout': null},
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.test/api/v1',
    );
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TC-APP-ROSTER-AI-LAYOUT: guard và AI layout', () {
    test(
      'TC-APP-ROSTER-AI-LAYOUT-01 file mẫu: luật tìm đủ cặp nên tin, không hỏi AI',
      () async {
        final grid = await sampleWorkbook();
        final readings = [for (final s in grid) ?readSheetByRules(s)];

        expect(rosterRulesAreConfident(grid, readings, (_) => true), isTrue);
      },
    );

    test(
      'TC-APP-ROSTER-AI-LAYOUT-02 nội dung đôi có dấu hiệu cặp mà không tìm được cặp nào thì không tin',
      () async {
        final grid = await workbookFrom(
          await _mixedRows(),
          merges: _mixedMerges,
        );
        final readings = [for (final s in grid) ?readSheetByRules(s)];

        expect(
          assembleRosterRows(
            readings.single,
            (_) => true,
          ).every((r) => r.player2Name == null),
          isTrue,
        );
        expect(rosterRulesAreConfident(grid, readings, (_) => true), isFalse);
        // Nội dung đơn không cần cặp, nên không nghi.
        expect(rosterRulesAreConfident(grid, readings, (_) => false), isTrue);
      },
    );

    test(
      'TC-APP-ROSTER-AI-LAYOUT-03 email ngoài cột đã ánh xạ hoặc sheet có bảng chưa đọc làm luật không tin',
      () async {
        final grid = await workbookFrom([
          ['STT', 'Họ và tên VĐV', 'Liên hệ'],
          [1, fakeName(0), 'vdv0@example.test'],
          [2, fakeName(1), ''],
        ]);
        final readings = [for (final s in grid) ?readSheetByRules(s)];

        expect(rosterRulesAreConfident(grid, readings, (_) => false), isFalse);
        expect(rosterRulesAreConfident(grid, const [], (_) => false), isFalse);
      },
    );

    test(
      'TC-APP-ROSTER-AI-LAYOUT-04 AI CONSECUTIVE_ROWS được giữ khi có vùng gộp, hạ về SINGLE khi không có bằng chứng',
      () async {
        final merged = await workbookFrom(
          await _mixedRows(),
          merges: _mixedMerges,
        );
        final kept = applyRosterLayout(merged, _layout(_block()));
        expect(kept.single.layout, RosterPairLayout.consecutiveRows);

        final plain = await workbookFrom([
          ['STT', 'Họ và tên VĐV', 'Số điện thoại liên hệ'],
          [1, fakeName(0), ''],
          [2, fakeName(1), ''],
          [3, fakeName(2), ''],
          [4, fakeName(3), ''],
        ]);
        final downgraded = applyRosterLayout(
          plain,
          _layout(_block(lastDataRow: 5)),
        );
        expect(downgraded.single.layout, RosterPairLayout.single);
      },
    );

    test(
      'TC-APP-ROSTER-AI-LAYOUT-05 singlesFromRow giữ các dòng lẻ không bị ghép theo vị trí',
      () async {
        final grid = await workbookFrom(
          await _mixedRows(),
          merges: _mixedMerges,
        );
        final readings = applyRosterLayout(
          grid,
          _layout(_block(singlesFromRow: 6)),
        );

        final rows = assembleRosterRows(readings.single, (_) => true);

        expect(rows.map((r) => [r.player1Name, r.player2Name]), [
          [fakeName(0), fakeName(1)],
          [fakeName(2), fakeName(3)],
          [fakeName(4), null],
          [fakeName(5), null],
          [fakeName(6), null],
        ]);
      },
    );

    test(
      'TC-APP-ROSTER-AI-LAYOUT-06 singlesFromRow ngoài khối bị bỏ',
      () async {
        final grid = await workbookFrom(
          await _mixedRows(),
          merges: _mixedMerges,
        );
        for (final value in [1, 2, 99]) {
          final readings = applyRosterLayout(
            grid,
            _layout(_block(singlesFromRow: value)),
          );
          expect(readings.single.singlesFromRow, 0, reason: '$value');
        }
      },
    );

    test(
      'TC-APP-ROSTER-AI-LAYOUT-07 digest che tên, email và SĐT, giữ nhãn cột và gửi vùng gộp',
      () async {
        final grid = await workbookFrom(
          [
            ['STT', 'Họ và tên VĐV', 'Email', 'Số điện thoại liên hệ'],
            [1, fakeName(0), 'vdv0@example.test', fakePhone(0)],
            [null, fakeName(1), '', fakePhone(1)],
          ],
          merges: ['A2:A3'],
        );

        final digest = buildRosterLayoutDigest(grid);
        final json = jsonEncode(digest);

        expect(digest.single['name'], 'S1');
        expect(digest.single['mergedRegions'], ['A2:A3']);
        expect(json, contains('Họ và tên VĐV'));
        expect(json, isNot(contains('Mẫu')));
        expect(json, isNot(contains('example.test')));
        expect(json, isNot(contains('0900000')));
      },
    );

    test(
      'TC-APP-ROSTER-AI-LAYOUT-08 repository gọi POST roster-layout, retryReason trên query và đọc aiAvailable:false',
      () async {
        final adapter = _LayoutAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
          ..httpClientAdapter = adapter;
        final repository = ApiRosterLayoutRepository(
          DioClient(tokenManager: _NoTokenManager(), dio: dio),
        );

        final response = await repository.analyzeRosterLayout(
          't-1',
          sheets: [
            {'name': 'S1', 'rowCount': 3, 'columnCount': 2, 'rows': <Object>[]},
          ],
          retryEmptyLayout: true,
        );

        expect(response.aiAvailable, isFalse);
        expect(response.layout, isNull);
        expect(adapter.last!.path, '/ai/tournaments/t-1/roster-layout');
        expect(adapter.last!.queryParameters['retryReason'], 'EMPTY_LAYOUT');
        expect((adapter.last!.data as Map)['locale'], 'vi');
      },
    );

    test(
      'TC-APP-ROSTER-AI-LAYOUT-09 429 và 503 là lỗi để màn giữ kết quả luật',
      () async {
        for (final status in [429, 503]) {
          final adapter = _LayoutAdapter()
            ..status = status
            ..body = {'message': 'busy'};
          final dio = Dio(
            BaseOptions(baseUrl: 'https://api.example.test/api/v1'),
          )..httpClientAdapter = adapter;
          final repository = ApiRosterLayoutRepository(
            DioClient(tokenManager: _NoTokenManager(), dio: dio),
          );

          await expectLater(
            repository.analyzeRosterLayout('t-1', sheets: const []),
            throwsA(isA<DioException>()),
            reason: '$status',
          );
        }
      },
    );

    test(
      'TC-APP-ROSTER-AI-LAYOUT-10 layout hợp lệ từ server được đọc thành khối',
      () {
        final response = RosterLayoutResponse.fromJson({
          'aiAvailable': true,
          'layout': {
            'sheets': [
              {
                'sheetName': 'S1',
                'kind': 'ROSTER',
                'blocks': [_block(singlesFromRow: 6)],
              },
            ],
            'notes': ['ghi chú'],
          },
        });

        expect(response.aiAvailable, isTrue);
        expect(response.layout!.sheets.single.blocks.single.singlesFromRow, 6);
        expect(
          response.layout!.sheets.single.blocks.single.pairLayout,
          'CONSECUTIVE_ROWS',
        );
      },
    );
  });
}
