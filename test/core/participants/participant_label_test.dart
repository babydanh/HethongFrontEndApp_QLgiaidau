import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

const _players = [
  ParticipantPlayer(slot: 1, fullName: 'Nguyễn Văn An'),
  ParticipantPlayer(slot: 2, fullName: 'Trần Văn Bình'),
];

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  double width = 240,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'compact hai VĐV: một dòng viết tắt, hai avatar, tooltip tên đầy đủ',
    (tester) async {
      await _pump(
        tester,
        width: 160,
        child: const ParticipantLabel(
          teamName: null,
          players: _players,
          compact: true,
        ),
      );

      expect(find.text('N. V. An / T. V. Bình'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsNothing);
      expect(find.byTooltip('Nguyễn Văn An / Trần Văn Bình'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('avatar không ảnh chỉ hiện đúng một chữ cái đầu', (tester) async {
    await _pump(
      tester,
      child: const ParticipantLabel(teamName: null, players: _players),
    );

    expect(find.text('N'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
    expect(find.text('NA'), findsNothing);
  });

  testWidgets('hơn hai VĐV: tối đa hai avatar', (tester) async {
    await _pump(
      tester,
      child: const ParticipantLabel(
        teamName: null,
        players: [
          ParticipantPlayer(slot: 1, fullName: 'An'),
          ParticipantPlayer(slot: 2, fullName: 'Bình'),
          ParticipantPlayer(slot: 3, fullName: 'Cường'),
        ],
      ),
    );

    expect(find.byType(CircleAvatar), findsNWidgets(2));
  });

  testWidgets('đầy đủ (danh sách rộng): hiện tên đầy đủ, không viết tắt', (
    tester,
  ) async {
    await _pump(
      tester,
      width: 320,
      child: const ParticipantLabel(teamName: null, players: _players),
    );

    expect(find.text('Nguyễn Văn An / Trần Văn Bình'), findsOneWidget);
    expect(find.text('N. V. An / T. V. Bình'), findsNothing);
  });

  testWidgets('TEAM: hiện tên đội nguyên văn, không viết tắt, không hiện VĐV', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const ParticipantLabel(
        teamName: 'Đội Ánh Dương',
        players: _players,
        compact: true,
      ),
    );

    expect(find.text('Đội Ánh Dương'), findsOneWidget);
    expect(find.textContaining('N. V. An'), findsNothing);
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('tên đội trùng tên VĐV: hiện PLAYERS, không hiện tên đội', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const ParticipantLabel(
        teamName: 'nguyễn văn an',
        players: _players,
      ),
    );

    expect(find.text('nguyễn văn an'), findsNothing);
    expect(find.text('Nguyễn Văn An / Trần Văn Bình'), findsOneWidget);
  });

  testWidgets('không có tên và không có VĐV: hiện "Chưa xác định"', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const ParticipantLabel(teamName: null, players: []),
    );

    expect(find.text('Chưa xác định'), findsOneWidget);
  });

  testWidgets('tên đội dài bị cắt, không tràn khung', (tester) async {
    await _pump(
      tester,
      width: 80,
      child: const ParticipantLabel(
        teamName: 'Đội bóng chuyền siêu dài không vừa khung hiển thị',
        players: [],
        compact: true,
      ),
    );

    final text = tester.widget<Text>(
      find.text('Đội bóng chuyền siêu dài không vừa khung hiển thị'),
    );
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
