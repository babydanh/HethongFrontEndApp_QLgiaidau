import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/shared/widgets/date_time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  DateTime? value,
  String? errorText,
  VoidCallback? onTap,
}) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: DateTimeField(
          buttonKey: const ValueKey('field'),
          label: 'Hạn chót đăng ký',
          placeholder: 'Chọn ngày',
          value: value,
          errorText: errorText,
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the label above and the full-year value on one line', (
    tester,
  ) async {
    await _pump(tester, value: DateTime(2026, 10, 23, 23, 59));

    expect(find.text('Hạn chót đăng ký'), findsOneWidget);
    final value = find.text('23/10/2026 · 23:59');
    expect(value, findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Hạn chót đăng ký')).dy,
      lessThan(tester.getTopLeft(value).dy),
    );
    final text = tester.widget<Text>(value);
    expect(text.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the placeholder when there is no value', (tester) async {
    await _pump(tester);
    expect(find.text('Chọn ngày'), findsOneWidget);
  });

  testWidgets('shows the error right under the field', (tester) async {
    await _pump(
      tester,
      value: DateTime(2026, 10, 24, 5),
      errorText: 'Bế mạc phải sau khai mạc.',
    );

    final error = find.text('Bế mạc phải sau khai mạc.');
    expect(error, findsOneWidget);
    expect(
      tester.getTopLeft(error).dy,
      greaterThan(
        tester.getBottomLeft(find.byKey(const ValueKey('field'))).dy - 1,
      ),
    );
  });

  testWidgets('forwards taps and is disabled without onTap', (tester) async {
    var taps = 0;
    await _pump(tester, onTap: () => taps++);
    await tester.tap(find.byKey(const ValueKey('field')));
    expect(taps, 1);

    await _pump(tester);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('field')))
          .onPressed,
      isNull,
    );
  });
}
