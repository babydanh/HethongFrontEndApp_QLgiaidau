import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_date_time_picker_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('date, hour and minute wheels preserve the selected time', (
    tester,
  ) async {
    final initial = DateTime.now().add(const Duration(days: 1));
    final selected = DateTime(initial.year, initial.month, initial.day, 10, 37);
    DateTime? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await SocialDateTimePickerSheet.show(
                  context,
                  selected,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
    expect(find.text('Chọn ngày và giờ'), findsOneWidget);

    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(result, selected);
  });

  group('shared options', () {
    final base = DateTime.now().add(const Duration(days: 3));
    final initial = DateTime(base.year, base.month, base.day, 10, 30);

    Future<void> open(
      WidgetTester tester,
      void Function(DateTime?) onResult, {
      String? subtitle,
      DateTime? minDate,
      DateTime? maxDate,
      bool showEndOfDayChip = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => onResult(
                  await SocialDateTimePickerSheet.show(
                    context,
                    initial,
                    subtitle: subtitle,
                    minDate: minDate,
                    maxDate: maxDate,
                    showEndOfDayChip: showEndOfDayChip,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the subtitle under the title and no chip by default', (
      tester,
    ) async {
      await open(tester, (_) {}, subtitle: 'Ngày khai mạc');
      expect(find.text('Ngày khai mạc'), findsOneWidget);
      expect(find.text('23:59'), findsNothing);
    });

    testWidgets('chip 23:59 selects the deadline time without confirming', (
      tester,
    ) async {
      DateTime? result;
      var closed = false;
      await open(tester, (value) {
        result = value;
        closed = true;
      }, showEndOfDayChip: true);

      await tester.tap(find.text('23:59'));
      await tester.pumpAndSettle();
      expect(closed, isFalse);

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(
        result,
        DateTime(initial.year, initial.month, initial.day, 23, 59),
      );
    });

    testWidgets('confirm is disabled when the date is before minDate', (
      tester,
    ) async {
      var closed = false;
      await open(
        tester,
        (_) => closed = true,
        minDate: initial.add(const Duration(days: 1)),
      );
      final confirm = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Xác nhận'),
      );
      expect(confirm.onPressed, isNull);
      expect(closed, isFalse);
    });

    testWidgets('confirm is disabled when the date is after maxDate', (
      tester,
    ) async {
      await open(
        tester,
        (_) {},
        maxDate: initial.subtract(const Duration(days: 1)),
      );
      final confirm = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Xác nhận'),
      );
      expect(confirm.onPressed, isNull);
    });

    testWidgets('confirm works when the date is inside the range', (
      tester,
    ) async {
      DateTime? result;
      await open(
        tester,
        (value) => result = value,
        minDate: initial,
        maxDate: initial,
      );
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(result, initial);
    });
  });
}
