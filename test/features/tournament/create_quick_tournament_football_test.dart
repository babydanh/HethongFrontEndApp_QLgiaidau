import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'create_quick_tournament_harness.dart';

List<Map<String, dynamic>> _divisions(Harness h) =>
    (h.lastBody['divisions'] as List).cast<Map<String, dynamic>>();

/// The switch in the same row as [label].
Finder _switchOf(String label) => find
    .descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
      matching: find.byType(Switch),
    )
    .first;

Future<void> _flip(WidgetTester tester, String label) async {
  await tester.tap(_switchOf(label));
  await tester.pump();
}

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen cấu hình bóng đá', () {
    Future<Harness> football(WidgetTester tester) async {
      final h = await pumpCreateScreen(tester);
      await tester.tap(find.text('Bóng đá'));
      await tester.pump();
      return h;
    }

    testWidgets('chọn bóng đá hiện thẻ cấu hình bóng đá, môn vợt thì không', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      expect(find.text(vi.tournamentCreateFootballOptions), findsNothing);
      await tester.tap(find.text('Bóng đá'));
      await tester.pump();
      expect(find.text(vi.tournamentCreateFootballOptions), findsOneWidget);
    });

    testWidgets('nội dung mặc định của bóng đá là Bóng đá nam', (tester) async {
      final h = await football(tester);
      await enterName(tester, 'Giải bóng đá');
      await tapSubmit(tester);
      expect(h.lastBody['sport'], 'football');
      expect(_divisions(h).single['genderRestriction'], 'MALE');
      expect(_divisions(h).single['matchType'], 'SINGLES');
    });

    testWidgets(
      'bóng đá gửi cấu hình mặc định 7 người, 5 dự bị, 2 hiệp 45 phút',
      (tester) async {
        final h = await football(tester);
        await enterName(tester, 'Giải bóng đá');
        await tapSubmit(tester);
        expect(h.lastBody['teamSize'], 7);
        expect(h.lastBody['maxReserve'], 5);
        expect(h.lastBody['footballHalvesCount'], 2);
        expect(h.lastBody['footballHalfDuration'], 45);
        expect(h.lastBody['footballAllowDraw'], isTrue);
        expect(h.lastBody['minTeamSize'], 7);
        expect(h.lastBody['maxTeamSize'], 12);
      },
    );

    testWidgets('bóng đá không gửi doublesPairingMode', (tester) async {
      final h = await football(tester);
      await enterName(tester, 'Giải bóng đá');
      await tapSubmit(tester);
      expect(h.lastBody.containsKey('doublesPairingMode'), isFalse);
    });

    testWidgets('môn vợt không gửi khoá cấu hình bóng đá', (tester) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'Giải pickleball');
      await tapSubmit(tester);
      for (final key in ['teamSize', 'maxReserve', 'footballHalvesCount']) {
        expect(h.lastBody.containsKey(key), isFalse, reason: key);
      }
    });

    testWidgets('đổi số người mỗi đội sang 11 thì min/max team size đi theo', (
      tester,
    ) async {
      final h = await football(tester);
      await tester.tap(find.text('7 người').first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('11 người').last);
      await tester.pump(const Duration(milliseconds: 400));
      await enterName(tester, 'Giải bóng đá 11');
      await tapSubmit(tester);
      expect(h.lastBody['teamSize'], 11);
      expect(h.lastBody['minTeamSize'], 11);
      expect(h.lastBody['maxTeamSize'], 16);
    });

    testWidgets('tắt cho phép hòa thì gửi footballAllowDraw false', (
      tester,
    ) async {
      final h = await football(tester);
      await _flip(tester, vi.tournamentCreateFootballAllowDraw);
      await enterName(tester, 'Giải không hòa');
      await tapSubmit(tester);
      expect(h.lastBody['footballAllowDraw'], isFalse);
    });

    testWidgets('luật hai lượt, bàn thắng sân khách, luân lưu mặc định tắt', (
      tester,
    ) async {
      final h = await football(tester);
      await enterName(tester, 'Giải mặc định');
      await tapSubmit(tester);
      expect(h.lastBody['twoLegged'], isFalse);
      expect(h.lastBody['awayGoalsRule'], isFalse);
      expect(h.lastBody['penaltyShootout'], isFalse);
    });

    testWidgets(
      'bật hai lượt và luân lưu trong cài đặt nâng cao thì gửi true',
      (tester) async {
        final h = await football(tester);
        await openAdvanced(tester);
        await _flip(tester, vi.tournamentCreateTwoLegged);
        await _flip(tester, vi.footballScore_penaltyShootout);
        await enterName(tester, 'Giải hai lượt');
        await tapSubmit(tester);
        expect(h.lastBody['twoLegged'], isTrue);
        expect(h.lastBody['penaltyShootout'], isTrue);
        expect(h.lastBody['awayGoalsRule'], isFalse);
      },
    );

    testWidgets('môn vợt không có công tắc hai lượt trong cài đặt nâng cao', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await openAdvanced(tester);
      expect(find.text(vi.tournamentCreateTwoLegged), findsNothing);
    });
  });
}
