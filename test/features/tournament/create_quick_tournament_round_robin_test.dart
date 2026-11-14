import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'create_quick_tournament_harness.dart';

Future<Harness> _roundRobin(WidgetTester tester) async {
  final h = await pumpCreateScreen(tester);
  await tester.tap(find.text(vi.quickCreateBracketRoundRobin));
  await tester.pump();
  return h;
}

Future<void> _submitNamed(WidgetTester tester) async {
  await enterName(tester, 'Giải vòng tròn');
  await tapSubmit(tester);
}

final _hint = find.textContaining('Vòng tròn chỉ hợp lệ tới 15 đội');

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen vòng tròn tối đa 15 đội', () {
    testWidgets('chọn vòng tròn khi đang 16 đội thì kẹp xuống 15', (
      tester,
    ) async {
      final h = await _roundRobin(tester);
      await _submitNamed(tester);
      expect(h.lastBody['maxTeams'], 15);
      expect(divisionsOf(h).single['maxParticipants'], 15);
    });

    testWidgets('chọn vòng tròn khi đang 8 đội thì giữ nguyên 8', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '8'));
      await tester.pump();
      await tester.tap(find.text(vi.quickCreateBracketRoundRobin));
      await tester.pump();
      await _submitNamed(tester);
      expect(h.lastBody['maxTeams'], 8);
    });

    testWidgets('chip của vòng tròn là 4 đến 15, không còn 128', (
      tester,
    ) async {
      await _roundRobin(tester);
      expect(find.widgetWithText(ChoiceChip, '15'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '128'), findsNothing);
    });

    testWidgets('bấm chip 12 thì gửi 12 đội', (tester) async {
      final h = await _roundRobin(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '12'));
      await tester.pump();
      await _submitNamed(tester);
      expect(h.lastBody['maxTeams'], 12);
    });

    testWidgets('nhập 15 đội cho vòng tròn là hợp lệ', (tester) async {
      final h = await _roundRobin(tester);
      await enterMaxTeams(tester, '15');
      await _submitNamed(tester);
      expect(h.lastBody['maxTeams'], 15);
    });

    testWidgets('nhập 16 đội cho vòng tròn bị từ chối bằng "Tối đa 15"', (
      tester,
    ) async {
      final h = await _roundRobin(tester);
      await enterMaxTeams(tester, '16');
      await _submitNamed(tester);
      expect(find.text('Tối đa 15'), findsOneWidget);
      expect(h.submitCount, 0);
    });

    testWidgets('đủ 15 đội thì không hiện gợi ý đổi thể thức', (tester) async {
      await _roundRobin(tester);
      expect(_hint, findsNothing);
    });

    testWidgets('quá 15 đội hiện gợi ý đổi sang vòng bảng + knockout', (
      tester,
    ) async {
      await _roundRobin(tester);
      await enterMaxTeams(tester, '20');
      expect(_hint, findsOneWidget);
    });

    testWidgets('bấm Đổi chuyển sang vòng bảng + knockout với 16 đội', (
      tester,
    ) async {
      final h = await _roundRobin(tester);
      await enterMaxTeams(tester, '20');
      await tester.tap(find.text('Đổi'));
      await tester.pump();
      expect(_hint, findsNothing);
      await _submitNamed(tester);
      expect(h.lastBody['bracketType'], 'group_stage_knockout');
      expect(h.lastBody['maxTeams'], 16);
    });

    testWidgets(
      'từ vòng tròn quay về loại trực tiếp thì cho phép trên 15 đội',
      (tester) async {
        final h = await _roundRobin(tester);
        await tester.tap(find.text(vi.quickCreateBracketSingle));
        await tester.pump();
        await enterMaxTeams(tester, '64');
        await _submitNamed(tester);
        expect(h.lastBody['bracketType'], 'single_elimination');
        expect(h.lastBody['maxTeams'], 64);
      },
    );
  });
}
