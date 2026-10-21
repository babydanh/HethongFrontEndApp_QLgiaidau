import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/swiss_standings_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    // Plain theme: AppTheme loads google_fonts assets, unavailable without .env.
    theme: ThemeData.light(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

const _rows = [
  Standing(
    id: 'p1',
    teamName: 'Đội Một',
    rank: 1,
    played: 3,
    won: 3,
    totalPoints: 9,
    buchholz: 7.5,
    buchholzCut1: 5,
    sonnebornBerger: 6,
    pointDifference: 12,
  ),
  Standing(
    id: 'p2',
    teamName: 'Đội Hai',
    rank: 2,
    played: 3,
    won: 2,
    lost: 1,
    totalPoints: 6,
    buchholz: 8,
  ),
];

void main() {
  testWidgets('shows base columns and only the enabled tiebreak columns', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SwissStandingsView(
          standings: _rows,
          tiebreakOrder: [SwissTiebreak.buchholz, SwissTiebreak.wins],
        ),
      ),
    );

    for (final label in [
      'Hạng',
      'Đội',
      'Trận',
      'Thắng',
      'Hòa',
      'Thua',
      'Điểm',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Buchholz'), findsOneWidget);
    expect(find.text('Số trận thắng'), findsOneWidget);
    expect(find.text('Sonneborn–Berger'), findsNothing);
    expect(find.text('Hiệu số'), findsNothing);
    expect(find.text('Buchholz (bỏ điểm thấp nhất)'), findsNothing);
    expect(find.text('7.5'), findsOneWidget);
  });

  testWidgets('headToHead and seed have no column', (tester) async {
    await tester.pumpWidget(
      _host(
        const SwissStandingsView(
          standings: _rows,
          tiebreakOrder: [SwissTiebreak.headToHead, SwissTiebreak.seed],
        ),
      ),
    );
    expect(find.text('Buchholz'), findsNothing);
    expect(find.text('Điểm'), findsOneWidget);
  });

  testWidgets('tiebreak columns follow tiebreakOrder', (tester) async {
    await tester.pumpWidget(
      _host(
        const SwissStandingsView(
          standings: _rows,
          tiebreakOrder: [SwissTiebreak.pointDiff, SwissTiebreak.buchholz],
        ),
      ),
    );
    final diffX = tester.getTopLeft(find.text('Hiệu số')).dx;
    final buchholzX = tester.getTopLeft(find.text('Buchholz')).dx;
    expect(diffX, lessThan(buchholzX));
  });

  testWidgets('rows keep the given (Backend rank) order and rank values', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SwissStandingsView(
          standings: _rows,
          tiebreakOrder: [SwissTiebreak.buchholz],
        ),
      ),
    );
    final first = tester.getTopLeft(find.text('Đội Một')).dy;
    final second = tester.getTopLeft(find.text('Đội Hai')).dy;
    expect(first, lessThan(second));
    // Rank column shows the Backend rank, not a recomputed index.
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('empty list shows swissStandingsEmpty', (tester) async {
    await tester.pumpWidget(
      _host(
        const SwissStandingsView(
          standings: [],
          tiebreakOrder: [SwissTiebreak.buchholz],
        ),
      ),
    );
    expect(find.text('Chưa có bảng xếp hạng'), findsOneWidget);
    expect(find.text('Hạng'), findsNothing);
  });

  testWidgets('320 dp wide with long names does not overflow, no Card/Icon', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        const SwissStandingsView(
          standings: [
            Standing(
              id: 'p1',
              teamName:
                  'Câu lạc bộ có một cái tên cực kỳ dài để thử việc cắt chữ',
              rank: 1,
              totalPoints: 9,
              buchholz: 7.5,
            ),
          ],
          tiebreakOrder: SwissConfig.defaultTiebreakOrder,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Card), findsNothing);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(Divider), findsWidgets);
  });
}
