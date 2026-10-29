import 'package:app_quanly_giaidau/features/tournament/widgets/division_strip.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = [
  DivisionStripItem(id: 'd1', name: 'Đôi Linh Hoạt', count: 8, capacity: 16),
  DivisionStripItem(id: 'd2', name: 'Đôi Nam Trình cao', count: 12),
  DivisionStripItem(id: 'd3', name: 'Đơn Nữ'),
];

Widget _host(Widget strip, {double width = 400, ThemeData? theme}) =>
    MaterialApp(
      theme: theme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: strip),
        ),
      ),
    );

DivisionStrip _strip({
  List<DivisionStripItem> items = _items,
  String? selectedId = 'd1',
  ValueChanged<String?>? onChanged,
  bool showAll = false,
  VoidCallback? onManage,
}) => DivisionStrip(
  items: items,
  selectedId: selectedId,
  onChanged: onChanged ?? (_) {},
  showAll: showAll,
  onManage: onManage,
);

void main() {
  testWidgets('shows name with count, and capacity only when known', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_strip()));

    expect(find.text('Đôi Linh Hoạt'), findsOneWidget);
    expect(find.text('8/16'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    // No count at all when the caller does not know it.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('division-chip-d3')),
        matching: find.textContaining(RegExp(r'\d')),
      ),
      findsNothing,
    );
  });

  testWidgets('tapping a chip reports its id; chips are at least 44dp tall', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(_host(_strip(onChanged: (id) => picked = id)));

    final chip = find.byKey(const ValueKey('division-chip-d2'));
    expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));
    await tester.tap(chip);
    expect(picked, 'd2');
  });

  testWidgets('the selected chip is exposed as selected to screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_strip(selectedId: 'd2')));

    expect(
      tester.getSemantics(find.byKey(const ValueKey('division-chip-d2'))),
      matchesSemantics(
        isSelected: true,
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
        label: 'Đôi Nam Trình cao 12',
      ),
    );
    handle.dispose();
  });

  testWidgets(
    '"Tất cả" leads, is selected for a null id and clears the filter',
    (tester) async {
      final calls = <String?>[];
      await tester.pumpWidget(
        _host(_strip(selectedId: null, showAll: true, onChanged: calls.add)),
      );

      final all = find.byKey(const ValueKey('division-chip-all'));
      expect(
        find.descendant(of: all, matching: find.text('Tất cả')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(all).dx,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('division-chip-d1'))).dx,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('division-chip-d1')));
      await tester.tap(all);
      expect(calls, ['d1', null]);
    },
  );

  testWidgets('hides when there is a single division and nothing to manage', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_strip(items: [_items.first])));
    expect(find.byKey(const ValueKey('division-chip-d1')), findsNothing);
    expect(find.text('Đôi Linh Hoạt'), findsNothing);

    // A manager still gets the strip so "Quản lý" stays reachable.
    await tester.pumpWidget(
      _host(_strip(items: [_items.first], onManage: () {})),
    );
    expect(find.text('Đôi Linh Hoạt'), findsOneWidget);
    expect(find.text('Quản lý'), findsOneWidget);
  });

  testWidgets('"Quản lý" is last and only shown with a manage action', (
    tester,
  ) async {
    var manage = 0;
    await tester.pumpWidget(_host(_strip()));
    expect(find.text('Quản lý'), findsNothing);

    await tester.pumpWidget(_host(_strip(onManage: () => manage++)));
    final manageChip = find.byKey(const ValueKey('division-chip-manage'));
    expect(
      tester.getTopLeft(manageChip).dx,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('division-chip-d3'))).dx,
      ),
    );
    await tester.ensureVisible(manageChip);
    await tester.tap(manageChip);
    expect(manage, 1);
  });

  testWidgets('scrolls the selected chip into view when it starts off-screen', (
    tester,
  ) async {
    final many = [
      for (var i = 1; i <= 9; i++)
        DivisionStripItem(id: 'x$i', name: 'Nội dung số $i', count: i),
    ];
    await tester.pumpWidget(
      _host(_strip(items: many, selectedId: 'x9'), width: 360),
    );
    await tester.pumpAndSettle();

    final view = tester.getRect(find.byType(DivisionStrip));
    final rect = tester.getRect(find.byKey(const ValueKey('division-chip-x9')));
    expect(rect.right, lessThanOrEqualTo(view.right + 0.5));
    expect(rect.left, greaterThanOrEqualTo(view.left));
  });

  testWidgets('a very long name stays on one line', (tester) async {
    await tester.pumpWidget(
      _host(
        _strip(
          items: const [
            DivisionStripItem(
              id: 'long',
              name:
                  'Đôi Nam Nữ Trình Trung Bình Khá Dành Cho Người Mới Chơi Lâu Năm',
              count: 8,
              capacity: 16,
            ),
            DivisionStripItem(id: 'b', name: 'Đơn Nam'),
          ],
          selectedId: 'long',
        ),
        width: 320,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('division-chip-long'))).height,
      lessThanOrEqualTo(48),
    );
  });
}
