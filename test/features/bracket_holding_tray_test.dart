import 'dart:async';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_diagram_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_slot_editing_scope.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'holding-tray-fixture';
const _divisionId = 'division-a';

// When set, every (re)load of the bracket provider takes this long.
Duration? _reloadDelay;

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

class _FakeRepo implements ITournamentRepository {
  _FakeRepo(this.matches);

  final List<MatchModel> matches;
  final calls = <List<Map<String, dynamic>>>[];
  Exception? failWith;

  // When set, updateBracketSlots stays pending until the completer finishes.
  Completer<void>? gate;

  @override
  Future<void> updateBracketSlots(
    String tournamentId, {
    String? divisionId,
    required List<Map<String, dynamic>> operations,
    bool isLite = false,
  }) async {
    calls.add(operations);
    await gate?.future;
    final error = failWith;
    if (error != null) throw error;
  }

  @override
  Future<List<MatchModel>> getBracketMatches(
    String tournamentId, {
    String? divisionId,
  }) async => matches;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament(
  id: _tournamentId,
  name: 'Holding tray fixture',
  sport: 'pickleball',
  format: 'DOUBLES',
  bracketType: 'single_elimination',
  status: 'in_progress',
  visibility: 'PUBLIC',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'fixture-owner',
  maxTeams: 16,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  divisions: [
    TournamentDivision(
      id: _divisionId,
      name: 'Đôi Nam Nữ',
      matchType: 'DOUBLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
      participantCount: 3,
    ),
  ],
);

MatchModel _match(
  String id, {
  required int round,
  int position = 0,
  String team1Id = '',
  String team2Id = '',
  String status = 'SCHEDULED',
  bool isBye = false,
}) => MatchModel.fromJson({
  'id': id,
  'isBye': isBye,
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': round,
  'matchNumber': position + 1,
  'status': status,
  'team1Id': team1Id,
  'team2Id': team2Id,
  'team1Name': team1Id.isEmpty ? '' : 'Đội $team1Id',
  'team2Name': team2Id.isEmpty ? '' : 'Đội $team2Id',
  'nextMatchId': '',
  'stageType': 'SINGLE_ELIMINATION',
  'bracketPosition': {
    'bracket': 'winners',
    'round': round,
    'position': position,
  },
}, id);

// m1 is full (p1 vs p2), m2 has one free slot (p3 vs empty).
List<MatchModel> _fixture({
  String m1Status = 'SCHEDULED',
  bool m1Bye = false,
}) => [
  _match(
    'm1',
    round: 1,
    team1Id: 'p1',
    team2Id: 'p2',
    status: m1Status,
    isBye: m1Bye,
  ),
  _match('m2', round: 1, position: 1, team1Id: 'p3'),
  _match('m3', round: 2),
];

BracketSlotDragData _slot(String match, String slot, String? participant) =>
    BracketSlotDragData(matchId: match, slot: slot, participantId: participant);

Future<_FakeRepo> _pump(
  WidgetTester tester,
  Widget home, {
  List<MatchModel>? matches,
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = _FakeRepo(matches ?? _fixture());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(repo),
        tournamentProvider.overrideWith(
          (ref, id) => Stream.value(_tournament()),
        ),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => _reloadDelay == null
              ? Stream.value(repo.matches)
              : Stream.fromFuture(
                  Future.delayed(_reloadDelay!, () => repo.matches),
                ),
        ),
        standingsWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const []),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

BracketDiagramScreen _diagram({
  required bool canEdit,
  String m1Status = 'SCHEDULED',
  bool m1Bye = false,
}) => BracketDiagramScreen(
  tournamentId: _tournamentId,
  divisionId: _divisionId,
  bracketType: 'single_elimination',
  initialMatches: _fixture(m1Status: m1Status, m1Bye: m1Bye),
  canEditBracket: canEdit,
  isReadOnly: !canEdit,
);

Future<void> _longPressDrag(WidgetTester tester, Finder from, Finder to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump(const Duration(milliseconds: 700));
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await tester.pumpAndSettle();
}

final _tray = find.byKey(const Key('bracket-holding-tray'));
Finder _slotKey(String match, String slot) =>
    find.byKey(ValueKey('bracket-slot-$match-$slot'));

void main() {
  group('bracketSlotOperation', () {
    test('slot sang ô trống -> MOVE', () {
      expect(
        bracketSlotOperation(
          _slot('m1', 'participant1', 'p1'),
          _slot('m2', 'participant2', null),
        ),
        {
          'operation': 'MOVE',
          'fromMatchId': 'm1',
          'fromSlot': 'participant1',
          'toMatchId': 'm2',
          'toSlot': 'participant2',
        },
      );
    });

    test('slot sang ô có người -> SWAP', () {
      expect(
        bracketSlotOperation(
          _slot('m1', 'participant1', 'p1'),
          _slot('m2', 'participant1', 'p3'),
        ),
        {
          'operation': 'SWAP',
          'fromMatchId': 'm1',
          'fromSlot': 'participant1',
          'toMatchId': 'm2',
          'toSlot': 'participant1',
        },
      );
    });

    test('khay sang ô trống -> ASSIGN, sang ô có người -> REPLACE', () {
      const chip = BracketSlotDragData.tray(
        participantId: 'p9',
        label: 'Đội 9',
      );
      expect(bracketSlotOperation(chip, _slot('m2', 'participant2', null)), {
        'operation': 'ASSIGN',
        'matchId': 'm2',
        'slot': 'participant2',
        'participantId': 'p9',
      });
      expect(bracketSlotOperation(chip, _slot('m2', 'participant1', 'p3')), {
        'operation': 'REPLACE',
        'matchId': 'm2',
        'slot': 'participant1',
        'participantId': 'p9',
      });
    });

    test('không làm gì: cùng ô, nguồn rỗng, đích là BYE', () {
      final p1 = _slot('m1', 'participant1', 'p1');
      expect(bracketSlotOperation(p1, p1), isNull);
      expect(
        bracketSlotOperation(
          _slot('m1', 'participant2', null),
          _slot('m2', 'participant1', 'p3'),
        ),
        isNull,
      );
      const bye = BracketSlotDragData(
        matchId: 'm2',
        slot: 'participant2',
        participantId: 'BYE',
        isBye: true,
      );
      expect(bracketSlotOperation(p1, bye), isNull);
      expect(
        bracketSlotOperation(
          const BracketSlotDragData.tray(participantId: 'p9', label: 'Đội 9'),
          bye,
        ),
        isNull,
      );
    });

    test('trận đang đấu hoặc đã xong (isLocked) -> không làm gì', () {
      const locked = BracketSlotDragData(
        matchId: 'm1',
        slot: 'participant1',
        participantId: 'p1',
        isLocked: true,
      );
      final open = _slot('m2', 'participant1', 'p3');
      const chip = BracketSlotDragData.tray(
        participantId: 'p9',
        label: 'Đội 9',
      );
      expect(bracketSlotOperation(locked, open), isNull);
      expect(bracketSlotOperation(open, locked), isNull);
      expect(bracketSlotOperation(chip, locked), isNull);
    });
  });

  test('bracketUnassignOperation -> UNASSIGN', () {
    expect(bracketUnassignOperation(_slot('m1', 'participant2', 'p2')), {
      'operation': 'UNASSIGN',
      'matchId': 'm1',
      'slot': 'participant2',
    });
  });

  group('màn sơ đồ toàn màn hình', () {
    testWidgets('quản lý: có khay giữ tạm, không còn nút xoá và pill zoom', (
      tester,
    ) async {
      await _pump(tester, _diagram(canEdit: true));
      final l10n = lookupAppLocalizations(const Locale('vi'));

      expect(_tray, findsOneWidget);
      expect(find.byIcon(Icons.link_off_rounded), findsNothing);
      expect(find.text(l10n.bracketDiagramZoomHint), findsNothing);
    });

    testWidgets('khách: không có khay, không nút xoá, không pill zoom', (
      tester,
    ) async {
      await _pump(tester, _diagram(canEdit: false));
      final l10n = lookupAppLocalizations(const Locale('vi'));

      expect(_tray, findsNothing);
      expect(find.byIcon(Icons.link_off_rounded), findsNothing);
      expect(find.text(l10n.bracketDiagramZoomHint), findsNothing);
    });

    testWidgets(
      'kéo VĐV vào khay -> UNASSIGN, rồi kéo chip sang ô trống -> ASSIGN',
      (tester) async {
        final repo = await _pump(tester, _diagram(canEdit: true));

        await _longPressDrag(tester, _slotKey('m1', 'participant1'), _tray);
        expect(repo.calls, hasLength(1));
        expect(repo.calls.single, [
          {'operation': 'UNASSIGN', 'matchId': 'm1', 'slot': 'participant1'},
        ]);

        final chip = find.byKey(const ValueKey('bracket-tray-chip-p1'));
        expect(chip, findsOneWidget);

        await _longPressDrag(tester, chip, _slotKey('m2', 'participant2'));
        expect(repo.calls, hasLength(2));
        expect(repo.calls.last, [
          {
            'operation': 'ASSIGN',
            'matchId': 'm2',
            'slot': 'participant2',
            'participantId': 'p1',
          },
        ]);
        expect(
          find.byKey(const ValueKey('bracket-tray-chip-p1')),
          findsNothing,
        );
      },
    );

    testWidgets('kéo VĐV sang ô trống ở trận khác -> MOVE', (tester) async {
      final repo = await _pump(tester, _diagram(canEdit: true));

      await _longPressDrag(
        tester,
        _slotKey('m1', 'participant1'),
        _slotKey('m2', 'participant2'),
      );

      expect(repo.calls.single, [
        {
          'operation': 'MOVE',
          'fromMatchId': 'm1',
          'fromSlot': 'participant1',
          'toMatchId': 'm2',
          'toSlot': 'participant2',
        },
      ]);
    });
  });

  group('sơ đồ nhúng trong tab Bảng đấu', () {
    Widget embedded({required bool canEdit}) => Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BracketViewScreen(
              tournamentId: _tournamentId,
              divisionId: _divisionId,
              isEmbedded: true,
              canEditBracket: canEdit,
            ),
          ),
        ],
      ),
    );

    testWidgets('quản lý: có khay và ô kéo thả ngay ngoài tab', (tester) async {
      await _pump(tester, embedded(canEdit: true));

      expect(_tray, findsOneWidget);
      expect(_slotKey('m1', 'participant1'), findsOneWidget);
    });

    testWidgets('khách: không có khay', (tester) async {
      await _pump(tester, embedded(canEdit: false));

      expect(_tray, findsNothing);
    });

    testWidgets('quản lý, màn độc lập (khung 420): vẫn có khay và ô kéo thả', (
      tester,
    ) async {
      await _pump(
        tester,
        BracketViewScreen(
          tournamentId: _tournamentId,
          divisionId: _divisionId,
          canEditBracket: true,
        ),
      );

      expect(_tray, findsOneWidget);
      expect(_slotKey('m1', 'participant1'), findsOneWidget);
    });

    testWidgets('chip vẫn còn trong khay sau khi bảng nạp lại', (tester) async {
      final repo = await _pump(tester, embedded(canEdit: true));
      _reloadDelay = const Duration(milliseconds: 300);
      addTearDown(() => _reloadDelay = null);

      await _longPressDrag(tester, _slotKey('m1', 'participant1'), _tray);

      expect(repo.calls, hasLength(1));
      // The provider is still reloading here: the tray must survive loading.
      expect(
        find.byKey(const ValueKey('bracket-tray-chip-p1')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const ValueKey('bracket-tray-chip-p1')),
        findsOneWidget,
      );
    });
  });

  group('trận đang đấu hoặc đã xong bị khoá kéo thả', () {
    for (final status in ['LIVE', 'COMPLETED']) {
      testWidgets('$status: không kéo VĐV ra khay được', (tester) async {
        final repo = await _pump(
          tester,
          _diagram(canEdit: true, m1Status: status),
          matches: _fixture(m1Status: status),
        );

        await _longPressDrag(tester, _slotKey('m1', 'participant1'), _tray);

        expect(repo.calls, isEmpty);
        expect(
          find.byKey(const ValueKey('bracket-tray-chip-p1')),
          findsNothing,
        );
      });

      testWidgets('$status: không thả VĐV khác vào trận đó được', (
        tester,
      ) async {
        final repo = await _pump(
          tester,
          _diagram(canEdit: true, m1Status: status),
          matches: _fixture(m1Status: status),
        );

        await _longPressDrag(
          tester,
          _slotKey('m2', 'participant1'),
          _slotKey('m1', 'participant2'),
        );

        expect(repo.calls, isEmpty);
      });
    }
  });

  group(
    'trận BYE đã COMPLETED vẫn kéo thả được (Backend không coi là có kết quả)',
    () {
      testWidgets('kéo VĐV nhận BYE ra khay -> UNASSIGN', (tester) async {
        final repo = await _pump(
          tester,
          _diagram(canEdit: true, m1Status: 'COMPLETED', m1Bye: true),
          matches: _fixture(m1Status: 'COMPLETED', m1Bye: true),
        );

        await _longPressDrag(tester, _slotKey('m1', 'participant1'), _tray);

        expect(repo.calls.single, [
          {'operation': 'UNASSIGN', 'matchId': 'm1', 'slot': 'participant1'},
        ]);
      });

      testWidgets('thả VĐV khác vào trận BYE đã COMPLETED -> SWAP', (
        tester,
      ) async {
        final repo = await _pump(
          tester,
          _diagram(canEdit: true, m1Status: 'COMPLETED', m1Bye: true),
          matches: _fixture(m1Status: 'COMPLETED', m1Bye: true),
        );

        await _longPressDrag(
          tester,
          _slotKey('m2', 'participant1'),
          _slotKey('m1', 'participant2'),
        );

        expect(repo.calls.single, [
          {
            'operation': 'SWAP',
            'fromMatchId': 'm2',
            'fromSlot': 'participant1',
            'toMatchId': 'm1',
            'toSlot': 'participant2',
          },
        ]);
      });

      testWidgets('BYE thật (một người, ô kia trống) nhận VĐV khác -> MOVE', (
        tester,
      ) async {
        final soloBye = [
          _match(
            'm1',
            round: 1,
            team1Id: 'p1',
            status: 'COMPLETED',
            isBye: true,
          ),
          _match('m2', round: 1, position: 1, team1Id: 'p3', team2Id: 'p4'),
          _match('m3', round: 2),
        ];
        final repo = await _pump(
          tester,
          _diagram(canEdit: true, m1Status: 'COMPLETED', m1Bye: true),
          matches: soloBye,
        );

        await _longPressDrag(
          tester,
          _slotKey('m2', 'participant1'),
          _slotKey('m1', 'participant2'),
        );

        expect(repo.calls.single, [
          {
            'operation': 'MOVE',
            'fromMatchId': 'm2',
            'fromSlot': 'participant1',
            'toMatchId': 'm1',
            'toSlot': 'participant2',
          },
        ]);
      });
    },
  );

  group('khay giữ tạm', () {
    testWidgets('chip thả lên ô có người -> REPLACE, người cũ vào khay', (
      tester,
    ) async {
      final repo = await _pump(tester, _diagram(canEdit: true));

      await _longPressDrag(tester, _slotKey('m1', 'participant1'), _tray);
      await _longPressDrag(
        tester,
        find.byKey(const ValueKey('bracket-tray-chip-p1')),
        _slotKey('m2', 'participant1'),
      );

      expect(repo.calls.last, [
        {
          'operation': 'REPLACE',
          'matchId': 'm2',
          'slot': 'participant1',
          'participantId': 'p1',
        },
      ]);
      expect(find.byKey(const ValueKey('bracket-tray-chip-p1')), findsNothing);
      expect(
        find.byKey(const ValueKey('bracket-tray-chip-p3')),
        findsOneWidget,
      );
    });

    testWidgets('đang gửi thì thả thêm lần nữa bị bỏ qua', (tester) async {
      final repo = await _pump(tester, _diagram(canEdit: true));
      repo.gate = Completer<void>();

      await _longPressDrag(tester, _slotKey('m1', 'participant1'), _tray);
      await _longPressDrag(tester, _slotKey('m2', 'participant1'), _tray);
      expect(repo.calls, hasLength(1));

      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('bracket-tray-chip-p1')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('bracket-tray-chip-p3')), findsNothing);
    });

    testWidgets('đổi division khi đang gửi -> bỏ kết quả, không refetch', (
      tester,
    ) async {
      final division = ValueNotifier<String>(_divisionId);
      addTearDown(division.dispose);
      var applied = 0;
      final repo = await _pump(
        tester,
        ValueListenableBuilder<String>(
          valueListenable: division,
          builder: (context, id, _) => BracketSlotEditingScope(
            enabled: true,
            tournamentId: _tournamentId,
            divisionId: id,
            onApplied: () => applied++,
            builder: (context, tray, onSlotDrop) => Column(
              children: [
                tray!,
                Draggable<BracketSlotDragData>(
                  data: _slot('m1', 'participant1', 'p1'),
                  feedback: const SizedBox(width: 40, height: 40),
                  child: Container(
                    key: const Key('source'),
                    width: 80,
                    height: 40,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      repo.gate = Completer<void>();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('source'))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(_tray));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      expect(repo.calls, hasLength(1));

      division.value = 'division-b';
      await tester.pump();
      repo.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('bracket-tray-chip-p1')), findsNothing);
      expect(applied, 0);
    });
  });

  group('lỗi từ Backend', () {
    testWidgets('kéo thả thất bại -> báo lỗi, không văng, kéo tiếp được', (
      tester,
    ) async {
      final repo = await _pump(tester, _diagram(canEdit: true));
      repo.failWith = Exception('LIVE match locked');

      await _longPressDrag(
        tester,
        _slotKey('m1', 'participant1'),
        _slotKey('m2', 'participant2'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(repo.calls, hasLength(1));

      repo.failWith = null;
      await tester.pump(const Duration(seconds: 5));
      await _longPressDrag(
        tester,
        _slotKey('m1', 'participant1'),
        _slotKey('m2', 'participant2'),
      );
      expect(repo.calls, hasLength(2));
    });

    testWidgets('thả vào khay thất bại -> chip không xuất hiện', (
      tester,
    ) async {
      final repo = await _pump(tester, _diagram(canEdit: true));
      repo.failWith = Exception('boom');

      await _longPressDrag(tester, _slotKey('m1', 'participant1'), _tray);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(const ValueKey('bracket-tray-chip-p1')), findsNothing);
    });
  });
}
