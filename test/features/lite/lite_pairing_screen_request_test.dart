import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_pairing_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api_adapter.dart';

const _tournamentId = 't1';
const _liteBase = '/tournaments/lite/t1';
const _genPath = '$_liteBase/pairs/generate';
const _bracketPath = '$_liteBase/bracket';

Map<String, dynamic> _pending(
  String id,
  String name, {
  String? divisionId,
}) => {
  'id': id,
  'teamStatus': 'PENDING_PARTNER',
  'teamName': name,
  'customResponses': {'importedFrom': 'ORGANIZER_DIRECT', 'player1Name': name},
  'rosters': <Object>[],
  'tournamentDivisionId': ?divisionId,
};

Map<String, dynamic> _complete(
  String id,
  String name, {
  String? divisionId,
}) => {
  'id': id,
  'teamStatus': 'COMPLETE',
  'teamName': name,
  'customResponses': {'importedFrom': 'ORGANIZER_DIRECT', 'player1Name': name},
  'rosters': <Object>[],
  'tournamentDivisionId': ?divisionId,
};

FakeApiAdapter _adapter({
  required List<Map<String, dynamic>> divisions,
  required List<Map<String, dynamic>> participants,
  Map<String, FakeReply> routes = const {},
}) {
  return FakeApiAdapter({
    'GET /tournaments/$_tournamentId': FakeReply(200, {
      'status': 'OK',
      'data': {
        'id': _tournamentId,
        'name': 'Giải test',
        'matchType': 'DOUBLES',
        'divisions': divisions,
      },
    }),
    'GET $_liteBase/participants': FakeReply(200, {
      'status': 'OK',
      'data': participants,
    }),
    ...routes,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );
  final l10n = lookupAppLocalizations(const Locale('vi'));

  // Bơm theo thời gian cố định: màn có animation lặp nên pumpAndSettle không
  // bao giờ "yên". runAsync cho phép future giả của Dio hoàn tất.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpScreen(WidgetTester tester, FakeApiAdapter adapter) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
        ],
        child: MaterialApp(
          // AppTheme tải font qua google_fonts (mạng), flutter_test chặn mạng.
          // Màn chỉ đọc màu qua context.colors nên fallback sáng là đủ.
          theme: ThemeData.light(),
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LitePairingScreen(tournamentId: _tournamentId),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> confirmInDialog(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(label),
      ),
    );
    await settle(tester);
  }

  Future<void> pickDivisionInDialog(WidgetTester tester, String name) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await settle(tester);
    await tester.tap(find.text(name).last);
    await settle(tester);
  }

  testWidgets('RANDOM sends divisionId of a single-division tournament', (
    tester,
  ) async {
    final adapter = _adapter(
      divisions: [
        {'id': 'd1', 'matchType': 'DOUBLES'},
      ],
      participants: [_pending('p1', 'An'), _pending('p2', 'Bình')],
      routes: {
        'POST $_genPath': const FakeReply(200, {
          'status': 'OK',
          'data': {
            'paired': [
              {
                'participantId': 'p1',
                'memberNames': ['An', 'Bình'],
              },
            ],
            'unpairedParticipantIds': <String>[],
            'unpairedNames': <String>[],
          },
        }),
      },
    );
    await pumpScreen(tester, adapter);

    await tester.tap(find.widgetWithText(OutlinedButton, l10n.lite_random));
    await settle(tester);
    await confirmInDialog(tester, l10n.lite_confirmButton);

    final posts = adapter.postsTo(_genPath).toList();
    expect(posts, hasLength(1));
    expect(posts.single.body, {'strategy': 'RANDOM', 'divisionId': 'd1'});
    expect(
      find.text('${l10n.lite_autoPairSuccess}: An & Bình'),
      findsOneWidget,
    );
  });

  testWidgets(
    'multi-division: RANDOM waits for a division choice, then sends that divisionId',
    (tester) async {
      final adapter = _adapter(
        divisions: [
          {'id': 'd1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
          {'id': 'd2', 'name': 'Đôi nữ', 'matchType': 'DOUBLES'},
        ],
        participants: [
          _pending('p1', 'An', divisionId: 'd1'),
          _pending('p2', 'Bình', divisionId: 'd1'),
          _pending('p3', 'Cường', divisionId: 'd2'),
          _pending('p4', 'Dũng', divisionId: 'd2'),
        ],
        routes: {
          'POST $_genPath': const FakeReply(200, {
            'status': 'OK',
            'data': {
              'paired': [
                {
                  'participantId': 'p3',
                  'memberNames': ['Cường', 'Dũng'],
                },
              ],
              'unpairedParticipantIds': <String>[],
              'unpairedNames': <String>[],
            },
          }),
        },
      );
      await pumpScreen(tester, adapter);

      // Chưa chọn nội dung: không có nút ghép ngẫu nhiên, danh sách chờ trống.
      expect(
        find.widgetWithText(OutlinedButton, l10n.lite_random),
        findsNothing,
      );
      expect(find.text('An'), findsNothing);

      await tester.tap(
        find.widgetWithText(OutlinedButton, l10n.registerSelectDivision),
      );
      await settle(tester);
      await pickDivisionInDialog(tester, 'Đôi nữ');
      await confirmInDialog(tester, l10n.lite_confirmButton);

      // Đã chọn Đôi nữ: chỉ VĐV của Đôi nữ nằm trong danh sách chờ.
      expect(find.text('An'), findsNothing);
      expect(find.text('Cường'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, l10n.lite_random));
      await settle(tester);
      await confirmInDialog(tester, l10n.lite_confirmButton);

      final posts = adapter.postsTo(_genPath).toList();
      expect(posts.single.body, {'strategy': 'RANDOM', 'divisionId': 'd2'});
      expect(
        find.text('${l10n.lite_autoPairSuccess}: Cường & Dũng'),
        findsOneWidget,
      );
    },
  );

  testWidgets('TC-APP-PAIRDIV-01 multi-division: "Đã ghép" only lists pairs of the chosen division', (
    tester,
  ) async {
    final adapter = _adapter(
      divisions: [
        {'id': 'd1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
        {'id': 'd2', 'name': 'Đôi nữ', 'matchType': 'DOUBLES'},
      ],
      participants: [
        _complete('c1', 'Cặp Nam', divisionId: 'd1'),
        _complete('c2', 'Cặp Nữ', divisionId: 'd2'),
        _pending('p3', 'Cường', divisionId: 'd2'),
      ],
    );
    await pumpScreen(tester, adapter);

    await tester.tap(
      find.widgetWithText(OutlinedButton, l10n.registerSelectDivision),
    );
    await settle(tester);
    await pickDivisionInDialog(tester, 'Đôi nữ');
    await confirmInDialog(tester, l10n.lite_confirmButton);

    expect(find.textContaining('Cặp Nữ'), findsWidgets);
    expect(find.textContaining('Cặp Nam'), findsNothing);
    expect(find.text('${l10n.lite_paired} (1)'), findsOneWidget);
  });

  testWidgets(
    'bracket sends divisionId, reports auto-paired and leftover names, never calls pairs/generate',
    (tester) async {
      final adapter = _adapter(
        divisions: [
          {'id': 'd1', 'matchType': 'DOUBLES'},
        ],
        participants: [
          _complete('p1', 'Đội A'),
          _pending('p2', 'Bình'),
          _pending('p3', 'Cường'),
          _pending('p4', 'Dũng'),
        ],
        routes: {
          'POST $_bracketPath': const FakeReply(200, {
            'status': 'OK',
            'data': {
              'autoPaired': [
                {
                  'participantId': 'p2',
                  'memberNames': ['Bình', 'Cường'],
                },
              ],
              'unpairedNames': ['Dũng'],
            },
          }),
        },
      );
      await pumpScreen(tester, adapter);

      await tester.tap(find.text(l10n.lite_createBracket));
      await settle(tester);
      await confirmInDialog(tester, l10n.lite_createBracket);

      expect(adapter.postsTo(_genPath), isEmpty);
      final posts = adapter.postsTo(_bracketPath).toList();
      expect(posts.single.body, {'divisionId': 'd1'});
      expect(
        find.text(
          [
            l10n.lite_bracketCreated,
            '${l10n.lite_autoPairSuccess}: Bình & Cường',
            '${l10n.lite_autoPairSuccessOdd(1)}: Dũng',
          ].join('\n'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('bracket backend 400 is shown verbatim, not swallowed', (
    tester,
  ) async {
    const backendMessage = 'Vui lòng chọn nội dung để tạo sơ đồ.';
    final adapter = _adapter(
      divisions: [
        {'id': 'd1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
        {'id': 'd2', 'name': 'Đôi nữ', 'matchType': 'DOUBLES'},
      ],
      participants: [_complete('p1', 'Đội A'), _pending('p2', 'Bình')],
      routes: {
        'POST $_bracketPath': const FakeReply(400, {
          'status': 'ERROR',
          'message': backendMessage,
        }),
      },
    );
    await pumpScreen(tester, adapter);

    await tester.tap(find.text(l10n.lite_createBracket));
    await settle(tester);
    await pickDivisionInDialog(tester, 'Đôi nữ');
    await confirmInDialog(tester, l10n.lite_confirmButton);
    await confirmInDialog(tester, l10n.lite_createBracket);
    expect(adapter.postsTo(_bracketPath).single.body, {'divisionId': 'd2'});

    expect(find.text(backendMessage), findsOneWidget);
    expect(adapter.postsTo(_genPath), isEmpty);
  });

  testWidgets(
    'multi-division bracket: cancelling the division picker sends nothing',
    (tester) async {
      final adapter = _adapter(
        divisions: [
          {'id': 'd1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
          {'id': 'd2', 'name': 'Đôi nữ', 'matchType': 'DOUBLES'},
        ],
        participants: [
          _complete('p1', 'Đội A'),
          _pending('p2', 'Bình', divisionId: 'd2'),
        ],
        routes: {
          'POST $_bracketPath': const FakeReply(200, {
            'status': 'OK',
            'data': {'autoPaired': <Object>[], 'unpairedNames': <String>[]},
          }),
        },
      );
      await pumpScreen(tester, adapter);

      await tester.tap(find.text(l10n.lite_createBracket));
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l10n.commonCancel),
        ),
      );
      await settle(tester);

      expect(adapter.postsTo(_bracketPath), isEmpty);
      expect(adapter.postsTo(_genPath), isEmpty);
    },
  );
}
