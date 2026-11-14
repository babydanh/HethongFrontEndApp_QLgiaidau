import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'create_quick_tournament_harness.dart';

Future<void> _submitNamed(WidgetTester tester) async {
  await enterName(tester, 'Giải thể thức');
  await tapSubmit(tester);
}

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen thể thức thi đấu', () {
    testWidgets('liệt kê bốn thể thức', (tester) async {
      await pumpCreateScreen(tester);
      for (final label in [
        vi.quickCreateBracketSingle,
        vi.quickCreateBracketDouble,
        vi.quickCreateBracketRoundRobin,
        vi.quickCreateBracketGroup,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('mặc định chọn loại trực tiếp: đúng một nút radio được chọn', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      await _submitNamed(tester);
      expect(h.lastBody['bracketType'], 'single_elimination');
    });

    testWidgets('chọn nhánh thắng/nhánh thua thì gửi double_elimination', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await tester.tap(find.text(vi.quickCreateBracketDouble));
      await tester.pump();
      await _submitNamed(tester);
      expect(h.lastBody['bracketType'], 'double_elimination');
    });

    testWidgets('chọn vòng tròn thì gửi round_robin', (tester) async {
      final h = await pumpCreateScreen(tester);
      await tester.tap(find.text(vi.quickCreateBracketRoundRobin));
      await tester.pump();
      await enterMaxTeams(tester, '8');
      await _submitNamed(tester);
      expect(h.lastBody['bracketType'], 'round_robin');
    });

    testWidgets('chọn vòng bảng + knockout thì gửi group_stage_knockout', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await tester.tap(find.text(vi.quickCreateBracketGroup));
      await tester.pump();
      await _submitNamed(tester);
      expect(h.lastBody['bracketType'], 'group_stage_knockout');
    });

    testWidgets(
      'mỗi division mang bracketType viết hoa theo thể thức đã chọn',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await tester.tap(find.text(vi.quickCreateBracketDouble));
        await tester.pump();
        await _submitNamed(tester);
        expect(divisionsOf(h).single['bracketType'], 'DOUBLE_ELIMINATION');
      },
    );

    testWidgets('chọn thể thức khác thì chỉ còn một nút radio được chọn', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await tester.tap(find.text(vi.quickCreateBracketGroup));
      await tester.pump();
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
    });
  });

  group('CreatePublicQuickTournamentScreen số đội tối đa', () {
    testWidgets('mặc định 16 đội cho giải và cho từng nội dung', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _submitNamed(tester);
      expect(h.lastBody['maxTeams'], 16);
      expect(divisionsOf(h).single['maxParticipants'], 16);
    });

    testWidgets('bấm chip 32 thì gửi 32 đội', (tester) async {
      final h = await pumpCreateScreen(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '32'));
      await tester.pump();
      await _submitNamed(tester);
      expect(h.lastBody['maxTeams'], 32);
      expect(divisionsOf(h).single['maxParticipants'], 32);
    });

    testWidgets('nhập số tuỳ chỉnh 20 vào ô Khác thì gửi 20 đội', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await enterMaxTeams(tester, '20');
      await _submitNamed(tester);
      expect(h.lastBody['maxTeams'], 20);
    });

    testWidgets('chip trực tiếp có 128 nhưng không có 15', (tester) async {
      await pumpCreateScreen(tester);
      expect(find.widgetWithText(ChoiceChip, '128'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '15'), findsNothing);
    });

    for (final bad in ['1', '0', '129', 'abc', '']) {
      testWidgets('số đội "$bad" bị từ chối: hiện 2–128, không gửi yêu cầu', (
        tester,
      ) async {
        final h = await pumpCreateScreen(tester);
        await enterMaxTeams(tester, bad);
        await _submitNamed(tester);
        expect(find.text('2–128'), findsOneWidget);
        expect(h.submitCount, 0);
      });
    }

    testWidgets('biên 2 đội hợp lệ', (tester) async {
      final h = await pumpCreateScreen(tester);
      await enterMaxTeams(tester, '2');
      await _submitNamed(tester);
      expect(h.lastBody['maxTeams'], 2);
    });

    testWidgets('biên 128 đội hợp lệ', (tester) async {
      final h = await pumpCreateScreen(tester);
      await enterMaxTeams(tester, '128');
      await _submitNamed(tester);
      expect(h.lastBody['maxTeams'], 128);
    });
  });
}
