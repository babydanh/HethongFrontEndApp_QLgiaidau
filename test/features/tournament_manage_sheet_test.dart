import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _spinnerKey = ValueKey('tournament-manage-sheet-busy-spinner');
const _closeKey = ValueKey('tournament-manage-sheet-close');
const _actionsKey = ValueKey('tournament-manage-sheet-actions');

/// Mở app tối giản có nút gọi helper `TournamentManageSheet.show` với cờ busy
/// theo tham số; đếm số lần nút hành động trong sheet được bấm.
Widget _harness({required bool busy, required ValueNotifier<int> taps}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () {
              TournamentManageSheet.show(
                context,
                title: 'Sửa hạng mục',
                busy: busy,
                child: const Text('Nội dung hạng mục'),
                actions: [
                  FilledButton(
                    onPressed: () => taps.value++,
                    child: const Text('Lưu'),
                  ),
                  TextButton(
                    onPressed: () => taps.value++,
                    child: const Text('Huỷ'),
                  ),
                ],
              );
            },
            child: const Text('Mở sheet'),
          ),
        ),
      ),
    ),
  );
}

PopScope _sheetPopScope(WidgetTester tester) {
  return tester.widget<PopScope>(
    find.descendant(
      of: find.byType(TournamentManageSheet),
      matching: find.byType(PopScope),
    ),
  );
}

void main() {
  testWidgets(
    'TC-WP-00-01: busy chặn đóng sheet, disable nút hành động, hiện spinner',
    (tester) async {
      final taps = ValueNotifier<int>(0);
      await tester.pumpWidget(_harness(busy: true, taps: taps));

      await tester.tap(find.text('Mở sheet'));
      await tester.pump();
      // Spinner quay vô hạn nên không dùng pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 400));

      // Khung sheet hiển thị đủ: tiêu đề + thân + thanh thao tác.
      expect(find.text('Sửa hạng mục'), findsOneWidget);
      expect(find.text('Nội dung hạng mục'), findsOneWidget);
      expect(find.byKey(_actionsKey), findsOneWidget);

      // PopScope canPop = false khi busy.
      expect(_sheetPopScope(tester).canPop, isFalse);

      // Spinner 16px, strokeWidth 2, nằm trên nút đầu của thanh thao tác.
      final spinnerBox = tester.widget<SizedBox>(find.byKey(_spinnerKey));
      expect(spinnerBox.width, 16);
      expect(spinnerBox.height, 16);
      final spinner = tester.widget<CircularProgressIndicator>(
        find.descendant(
          of: find.byKey(_spinnerKey),
          matching: find.byType(CircularProgressIndicator),
        ),
      );
      expect(spinner.strokeWidth, 2);

      // Nút hành động bị disable: bấm không chạy callback (chống double-tap).
      await tester.tap(find.text('Lưu'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(taps.value, 0);
      await tester.tap(find.text('Huỷ'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(taps.value, 0);

      // Nút đóng ở tiêu đề bị disable.
      final closeButton = tester.widget<IconButton>(find.byKey(_closeKey));
      expect(closeButton.onPressed, isNull);

      // Cố đóng sheet qua barrier: bị chặn, sheet còn nguyên.
      await tester.tapAt(const Offset(400, 20));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TournamentManageSheet), findsOneWidget);
      expect(find.text('Nội dung hạng mục'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-WP-00-01 (không busy): cho đóng sheet, nút hoạt động, không spinner',
    (tester) async {
      final taps = ValueNotifier<int>(0);
      await tester.pumpWidget(_harness(busy: false, taps: taps));

      await tester.tap(find.text('Mở sheet'));
      await tester.pumpAndSettle();

      expect(_sheetPopScope(tester).canPop, isTrue);
      expect(find.byKey(_spinnerKey), findsNothing);

      // Nút hành động bấm được khi không busy.
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(taps.value, 1);

      // Đóng sheet qua barrier được.
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();
      expect(find.byType(TournamentManageSheet), findsNothing);
      expect(find.text('Mở sheet'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-WP-00-01: kéo xuống lúc busy không đóng được sheet (enableDrag tắt)',
    (tester) async {
      final taps = ValueNotifier<int>(0);
      await tester.pumpWidget(_harness(busy: true, taps: taps));

      await tester.tap(find.text('Mở sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Kéo xuống dismiss của SDK gọi thẳng Navigator.pop (bypass PopScope),
      // nên helper phải tắt enableDrag khi busy — kéo không đóng sheet.
      await tester.drag(
        find.byType(TournamentManageSheet),
        const Offset(0, 600),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TournamentManageSheet), findsOneWidget);
      expect(find.text('Nội dung hạng mục'), findsOneWidget);
    },
  );

  testWidgets('TC-WP-00-01 (không busy): kéo xuống đóng được sheet', (
    tester,
  ) async {
    final taps = ValueNotifier<int>(0);
    await tester.pumpWidget(_harness(busy: false, taps: taps));

    await tester.tap(find.text('Mở sheet'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(TournamentManageSheet), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.byType(TournamentManageSheet), findsNothing);
    expect(find.text('Mở sheet'), findsOneWidget);
  });
}
