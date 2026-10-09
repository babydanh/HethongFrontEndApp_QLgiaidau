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
}
