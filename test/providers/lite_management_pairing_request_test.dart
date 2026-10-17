import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/utils/api_error_message.dart';
import 'package:app_quanly_giaidau/core/utils/bracket_generation_summary.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

const _tournamentId = 't1';
const _liteBase = '/tournaments/lite/t1';
const _oneDivision = [
  {'id': 'd1', 'matchType': 'DOUBLES'},
];
const _twoDivisions = [
  {'id': 'd1', 'matchType': 'DOUBLES'},
  {'id': 'd2', 'matchType': 'DOUBLES'},
];

Map<String, dynamic> _pending(String id, String name) => {
  'id': id,
  'teamStatus': 'PENDING_PARTNER',
  'teamName': name,
  'customResponses': {'importedFrom': 'ORGANIZER_DIRECT', 'player1Name': name},
  'rosters': <Object>[],
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
        'tournamentConfig': {'isLite': true},
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

Future<LiteManagementNotifier> _loadedNotifier(FakeApiAdapter adapter) async {
  final container = ProviderContainer(
    overrides: [dioClientProvider.overrideWithValue(fakeDioClient(adapter))],
  );
  addTearDown(container.dispose);
  final notifier = container.read(liteManagementProvider.notifier);
  await notifier.init(_tournamentId);
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('generatePairs', () {
    test('sends divisionId of the single active division', () async {
      final adapter = _adapter(
        divisions: _oneDivision,
        participants: [_pending('p1', 'An'), _pending('p2', 'Bình')],
        routes: {
          'POST $_liteBase/pairs/generate': const FakeReply(200, {
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
      final notifier = await _loadedNotifier(adapter);

      await notifier.generatePairs(_tournamentId, 'RANDOM');

      final posts = adapter.postsTo('$_liteBase/pairs/generate').toList();
      expect(posts, hasLength(1));
      expect(posts.single.body, {'strategy': 'RANDOM', 'divisionId': 'd1'});
    });

    test(
      'omits divisionId for multi-division tournaments and rethrows backend 400',
      () async {
        final adapter = _adapter(
          divisions: _twoDivisions,
          participants: [_pending('p1', 'An'), _pending('p2', 'Bình')],
          routes: {
            'POST $_liteBase/pairs/generate': const FakeReply(400, {
              'status': 'ERROR',
              'message': 'Vui lòng chọn nội dung để ghép đôi.',
            }),
          },
        );
        final notifier = await _loadedNotifier(adapter);

        final error = await notifier
            .generatePairs(_tournamentId, 'RANDOM')
            .then<Object?>((_) => null, onError: (Object e) => e);

        expect(error, isA<DioException>());
        expect(
          backendErrorMessage(error),
          'Vui lòng chọn nội dung để ghép đôi.',
        );
        final posts = adapter.postsTo('$_liteBase/pairs/generate').toList();
        expect(posts.single.body, {'strategy': 'RANDOM'});
      },
    );
  });

  group('createBracket', () {
    test(
      'never pre-pairs client-side, sends divisionId and returns auto-paired result',
      () async {
        final adapter = _adapter(
          divisions: _oneDivision,
          participants: [
            _pending('p1', 'An'),
            _pending('p2', 'Bình'),
            _pending('p3', 'Cường'),
            _pending('p4', 'Dũng'),
          ],
          routes: {
            'POST $_liteBase/bracket': const FakeReply(200, {
              'status': 'OK',
              'data': {
                'autoPaired': [
                  {
                    'participantId': 'p1',
                    'memberNames': ['An', 'Bình'],
                  },
                ],
                'unpairedNames': ['Cường'],
              },
            }),
          },
        );
        final notifier = await _loadedNotifier(adapter);

        final raw = await notifier.createBracket(_tournamentId);

        expect(adapter.postsTo('$_liteBase/pairs/generate'), isEmpty);
        final bracketPosts = adapter.postsTo('$_liteBase/bracket').toList();
        expect(bracketPosts, hasLength(1));
        expect(bracketPosts.single.body?['divisionId'], 'd1');
        expect(bracketAutoPairedLabels(raw), ['An & Bình']);
        expect(bracketUnpairedNames(raw), ['Cường']);
      },
    );

    test('rethrows backend 400 and never pre-pairs client-side', () async {
      final adapter = _adapter(
        divisions: _oneDivision,
        participants: [
          _pending('p1', 'An'),
          _pending('p2', 'Bình'),
          _pending('p3', 'Cường'),
          _pending('p4', 'Dũng'),
        ],
        routes: {
          'POST $_liteBase/bracket': const FakeReply(400, {
            'status': 'ERROR',
            'message': 'Vui lòng chọn nội dung để tạo sơ đồ.',
          }),
        },
      );
      final notifier = await _loadedNotifier(adapter);

      final error = await notifier
          .createBracket(_tournamentId)
          .then<Object?>((_) => null, onError: (Object e) => e);

      expect(
        backendErrorMessage(error),
        'Vui lòng chọn nội dung để tạo sơ đồ.',
      );
      expect(adapter.postsTo('$_liteBase/pairs/generate'), isEmpty);
    });
  });

  group('ghi sơ đồ, reset và VĐV ảo theo nội dung', () {
    final fourPending = [
      _pending('p1', 'An'),
      _pending('p2', 'Bình'),
      _pending('p3', 'Cường'),
      _pending('p4', 'Dũng'),
    ];
    const emptyBracketReply = FakeReply(200, {
      'status': 'OK',
      'data': {'autoPaired': [], 'unpairedNames': []},
    });
    const okReply = FakeReply(200, {'status': 'OK', 'data': {}});

    test(
      'nhiều nội dung chưa chọn: createBracket ném lỗi, không gửi divisionId',
      () async {
        final adapter = _adapter(
          divisions: _twoDivisions,
          participants: fourPending,
        );
        final notifier = await _loadedNotifier(adapter);

        await expectLater(
          notifier.createBracket(_tournamentId),
          throwsA(isA<StateError>()),
        );

        expect(adapter.postsTo('$_liteBase/bracket'), isEmpty);
        expect(notifier.state.creatingBracket, isFalse);
      },
    );

    test(
      'nhiều nội dung chưa chọn: resetBracket, seedMock, clearMock ném lỗi và không gửi request',
      () async {
        final adapter = _adapter(
          divisions: _twoDivisions,
          participants: fourPending,
        );
        final notifier = await _loadedNotifier(adapter);

        await expectLater(
          notifier.resetBracket(_tournamentId),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          notifier.seedMock(_tournamentId, 2),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          notifier.clearMock(_tournamentId),
          throwsA(isA<StateError>()),
        );

        expect(adapter.postsTo('$_liteBase/bracket/reset'), isEmpty);
        expect(
          adapter.requests.where((r) => r.path.endsWith('mock-participants')),
          isEmpty,
        );
        expect(notifier.state.creatingBracket, isFalse);
        expect(notifier.state.mockLoading, isFalse);
      },
    );

    test(
      'selectDivision: createBracket, reset và seedMock gửi đúng nội dung đã chọn',
      () async {
        final adapter = _adapter(
          divisions: _twoDivisions,
          participants: fourPending,
          routes: {
            'POST $_liteBase/bracket': emptyBracketReply,
            'POST $_liteBase/bracket/reset': okReply,
            'POST /tournaments/$_tournamentId/mock-participants': okReply,
          },
        );
        final notifier = await _loadedNotifier(adapter);

        await notifier.selectDivision(_tournamentId, 'd2');
        expect(notifier.state.selectedDivisionId, 'd2');
        expect(notifier.state.displayDivision?.id, 'd2');

        await notifier.createBracket(_tournamentId);
        await notifier.resetBracket(_tournamentId);
        await notifier.seedMock(_tournamentId, 2);

        expect(
          adapter.postsTo('$_liteBase/bracket').single.body?['divisionId'],
          'd2',
        );
        expect(
          adapter.postsTo('$_liteBase/bracket/reset').single.body?['divisionId'],
          'd2',
        );
        expect(
          adapter
              .postsTo('/tournaments/$_tournamentId/mock-participants')
              .single
              .body?['divisionId'],
          'd2',
        );
      },
    );

    test('một nội dung: reset gửi divisionId duy nhất không cần chọn', () async {
      final adapter = _adapter(
        divisions: _oneDivision,
        participants: fourPending,
        routes: {'POST $_liteBase/bracket/reset': okReply},
      );
      final notifier = await _loadedNotifier(adapter);

      await notifier.resetBracket(_tournamentId);

      expect(
        adapter.postsTo('$_liteBase/bracket/reset').single.body?['divisionId'],
        'd1',
      );
    });
  });
}
