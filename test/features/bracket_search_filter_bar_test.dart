import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_search_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<TextEditingController> _pump(
  WidgetTester tester, {
  bool hasActiveFilters = false,
  int activeCount = 0,
  ValueChanged<String>? onChanged,
  VoidCallback? onClear,
  VoidCallback? onFilterTap,
}) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BracketSearchFilterBar(
          controller: controller,
          hint: 'Tìm đội',
          hasActiveFilters: hasActiveFilters,
          activeCount: activeCount,
          onChanged: onChanged ?? (_) {},
          onClear: onClear ?? () {},
          onFilterTap: onFilterTap ?? () {},
        ),
      ),
    ),
  );
  return controller;
}

void main() {
  testWidgets('hiện gợi ý, cao thấp và nút lọc gọi callback', (tester) async {
    var taps = 0;
    await _pump(tester, onFilterTap: () => taps++);

    expect(find.text('Tìm đội'), findsOneWidget);
    expect(tester.getSize(find.byType(BracketSearchFilterBar)).height, 44);
    await tester.tap(find.byKey(const Key('bracket-filter-button')));
    expect(taps, 1);
  });

  testWidgets('chỉ hiện badge số lọc khi có lọc đang bật', (tester) async {
    await _pump(tester);
    expect(find.text('3'), findsNothing);

    await _pump(tester, hasActiveFilters: true, activeCount: 3);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets(
    'gõ chữ gọi onChanged, nút X chỉ hiện khi có chữ và gọi onClear',
    (tester) async {
      var cleared = 0;
      String? typed;
      await _pump(
        tester,
        onChanged: (v) => typed = v,
        onClear: () => cleared++,
      );

      expect(find.byKey(const Key('bracket-search-clear')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('bracket-search-field')),
        'an',
      );
      await tester.pump();
      expect(typed, 'an');

      await tester.tap(find.byKey(const Key('bracket-search-clear')));
      expect(cleared, 1);
    },
  );
}
