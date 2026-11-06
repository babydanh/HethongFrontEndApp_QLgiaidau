import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_bracket_board.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TC-PLC-01..05: the Playoff match card shows code · court, time, a LIVE tag
// and the score of every set, like the Web bracket card.
MatchModel _match({
  String status = 'SCHEDULED',
  String? code = 'TK01',
  String? court,
  String? time,
  List<List<int>> sets = const [],
  List<String>? members,
}) => MatchModel.fromJson({
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': status,
  'team1Id': 'p1',
  'team2Id': 'p2',
  'team1Name': 'P. T. Tùng',
  'team2Name': 'Đ. Q. Huy',
  'stageType': 'DOUBLE_ELIMINATION',
  'matchCode': code,
  'courtName': court,
  'scheduledTime': time,
  'team1Members': members,
  'scoreDetails': {
    'sets': [
      for (final s in sets) {'team1Score': s[0], 'team2Score': s[1]},
    ],
  },
  'bracketPosition': {'bracket': 'winners', 'round': 1, 'position': 0},
}, 'm1');

Future<void> _pump(WidgetTester tester, MatchModel match) async {
  tester.view.physicalSize = const Size(400, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: PlayoffBracketBoard(
          columns: [
            [match],
          ],
          feeders: const {},
          cardWidth: 176,
          gap: 14,
          onTap: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('TC-PLC-01 header shows code, court and time', (tester) async {
    await _pump(tester, _match(court: 'Sân 2', time: '2026-11-08T09:30:00'));

    expect(find.text('TK01 · Sân 2'), findsOneWidget);
    expect(find.text('09:30 08/11'), findsOneWidget);
  });

  testWidgets('TC-PLC-02 every set is shown for both sides', (tester) async {
    await _pump(
      tester,
      _match(
        status: 'COMPLETED',
        sets: const [
          [11, 7],
          [9, 11],
          [11, 8],
        ],
      ),
    );

    // Side 1: 11, 9, 11. Side 2: 7, 11, 8.
    expect(find.text('11'), findsNWidgets(3));
    expect(find.text('9'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('TC-PLC-03 a live match shows the LIVE tag and its sets so far', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        status: 'LIVE',
        sets: const [
          [11, 9],
          [7, 5],
        ],
      ),
    );

    expect(find.text('Đang đấu'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('TC-PLC-04 no court and no time leaves only the code', (
    tester,
  ) async {
    await _pump(tester, _match());

    expect(find.text('TK01'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
    expect(find.textContaining('/'), findsNothing);
    expect(find.text('Đang đấu'), findsNothing);
  });

  testWidgets('TC-PLC-05 a long court name and doubles do not overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        status: 'LIVE',
        court: 'Sân trung tâm số một rất rất dài',
        time: '2026-11-08T09:30:00',
        sets: const [
          [11, 9],
          [7, 5],
          [10, 12],
        ],
        members: const ['Nguyễn Văn An', 'Trần Quốc Bảo'],
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
