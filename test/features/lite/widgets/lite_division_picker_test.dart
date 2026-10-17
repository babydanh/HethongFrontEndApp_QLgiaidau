import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/lite/widgets/lite_division_picker.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _l10n = lookupAppLocalizations(const Locale('vi'));

final _divisions = [
  TournamentDivision.fromJson({
    'id': 'd1',
    'name': 'Đôi nam',
    'matchType': 'DOUBLES',
  }),
  TournamentDivision.fromJson({
    'id': 'd2',
    'name': 'Đôi nữ',
    'matchType': 'DOUBLES',
  }),
];

void main() {
  /// Mở hộp chọn từ một nút; [onResult] nhận giá trị hộp chọn trả về.
  Future<void> openPicker(
    WidgetTester tester,
    void Function(String?) onResult,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  onResult(await showLiteDivisionPicker(context, _divisions));
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('nút xác nhận bị khoá tới khi BTC chọn nội dung', (tester) async {
    await openPicker(tester, (_) {});
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, _l10n.lite_confirmButton),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('chọn nội dung rồi xác nhận trả đúng id', (tester) async {
    String? result = 'chưa trả';
    await openPicker(tester, (id) => result = id);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đôi nữ').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, _l10n.lite_confirmButton),
    );
    await tester.pumpAndSettle();
    expect(result, 'd2');
  });

  testWidgets('huỷ trả null, không chọn gì', (tester) async {
    String? result = 'chưa trả';
    await openPicker(tester, (id) => result = id);
    await tester.tap(find.widgetWithText(TextButton, _l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
