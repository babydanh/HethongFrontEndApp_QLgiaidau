import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_stage_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _an = 'Nguyễn Văn An';
const _binh = 'Trần Thị Bình';
const _cuong = 'Lê Hoàng Cường';
const _dung = 'Phạm Minh Dũng';

Map<String, dynamic> _participant(List<String> names) => {
  'players': [
    for (final n in names) {'fullName': n},
  ],
};

MatchModel _match({
  required String id,
  bool done = true,
  int round = 1,
  String? winnerId,
}) => MatchModel.fromJson({
  'tournamentId': 't-1',
  'round': round,
  'matchNumber': 1,
  'status': done ? 'COMPLETED' : 'SCHEDULED',
  'team1Id': 't1',
  'team2Id': 't2',
  'team1Name': '',
  'team2Name': '',
  'participant1': _participant([_an, _binh]),
  'participant2': _participant([_cuong, _dung]),
  'groupName': 'A',
  'winnerId': ?winnerId,
  if (done)
    'sets': [
      {'score1': 11, 'score2': 8},
      {'score1': 9, 'score2': 11},
      {'score1': 11, 'score2': 5},
    ],
}, id);

final _standings = [
  Standing(
    id: 't1',
    teamName: '',
    group: 'A',
    played: 1,
    won: 1,
    players: const [
      ParticipantPlayer(slot: 1, fullName: _an),
      ParticipantPlayer(slot: 2, fullName: _binh),
    ],
  ),
  Standing(
    id: 't2',
    teamName: '',
    group: 'A',
    played: 1,
    lost: 1,
    players: const [
      ParticipantPlayer(slot: 1, fullName: _cuong),
      ParticipantPlayer(slot: 2, fullName: _dung),
    ],
  ),
];

Future<void> _pump(WidgetTester tester, List<MatchModel> matches) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        standingsWithDivisionProvider((
          tournamentId: 't-1',
          divisionId: null,
        )).overrideWith((ref) => Stream.value(_standings)),
        matchesWithDivisionProvider((
          tournamentId: 't-1',
          divisionId: null,
        )).overrideWith((ref) => Stream.value(matches)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: GroupStageView(matches: matches, tournamentId: 't-1'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-GSV-10 matrix: explicit group name, abbreviated doubles, '
      'one line per set, no hint text or scrollbar', (tester) async {
    await _pump(tester, [_match(id: 'm1', winnerId: 't1')]);

    expect(find.text('Bảng A'), findsOneWidget);
    expect(find.text('2 Đội'), findsOneWidget);
    expect(find.text('STT'), findsOneWidget);
    expect(find.text('VĐV / Đội'), findsOneWidget);
    expect(find.text('T / B'), findsOneWidget);
    expect(find.text(abbreviateName(_an)), findsOneWidget);
    expect(find.text(abbreviateName(_dung)), findsOneWidget);
    expect(find.text(_an), findsNothing);
    for (final line in ['11-8', '9-11', '11-5', '8-11', '11-9', '5-11']) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    expect(find.text('1 / 0'), findsOneWidget);
    expect(find.textContaining('Cách tính'), findsNothing);
    expect(find.byType(Scrollbar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'TC-GSV-11 tapping a played cell opens the sheet with full names',
    (tester) async {
      await _pump(tester, [_match(id: 'm1', winnerId: 't1')]);

      await tester.tap(find.text('11-8'));
      await tester.pumpAndSettle();

      expect(find.text('Bảng A · Lượt 1'), findsOneWidget);
      expect(find.text(_an), findsOneWidget);
      expect(find.text(_dung), findsOneWidget);
      expect(find.text('THẮNG'), findsOneWidget);
      expect(find.text('THUA'), findsOneWidget);
      expect(find.text('Xem trận'), findsOneWidget);
      expect(find.text('Đã xong'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-GSV-12 unplayed cell shows a dash and still opens the sheet',
    (tester) async {
      await _pump(tester, [_match(id: 'm1', done: false)]);

      expect(find.text('-'), findsNWidgets(2));
      await tester.tap(find.text('-').first);
      await tester.pumpAndSettle();

      expect(find.text('Sắp diễn ra'), findsOneWidget);
      expect(find.text('Chưa xếp sân'), findsOneWidget);
      expect(find.text('THẮNG'), findsNothing);
    },
  );

  testWidgets('TC-GSV-13 modes: standings columns and by-round list', (
    tester,
  ) async {
    await _pump(tester, [_match(id: 'm1', winnerId: 't1')]);

    await tester.tap(find.text('Bảng xếp hạng'));
    await tester.pumpAndSettle();
    expect(find.text('Điểm'), findsOneWidget);
    expect(find.text('Hiệu số'), findsOneWidget);

    await tester.tap(find.text('Theo lượt'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vòng'), findsNothing);
    expect(find.text('Đã xong'), findsOneWidget);

    await tester.tap(find.text('Bảng chéo'));
    await tester.pumpAndSettle();
    expect(find.text('STT'), findsOneWidget);
  });
}
