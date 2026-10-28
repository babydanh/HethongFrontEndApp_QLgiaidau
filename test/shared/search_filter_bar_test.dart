import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/shared/widgets/search_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _groups = [
  SearchFilterGroup(
    id: 'court',
    label: 'Sân',
    options: [(value: 's1', label: 'Sân 1'), (value: 's2', label: 'Sân 2')],
  ),
  SearchFilterGroup(
    id: 'status',
    label: 'Trạng thái',
    options: [(value: 'x', label: 'Trùng'), (value: 'u', label: 'Chưa xếp')],
  ),
];

Widget _host({String tabKey = 'a', int count = 3, double textScale = 1}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: [
            Row(children: [SearchFilterToggle(tabKey: tabKey)]),
            SearchFilterBar(
              tabKey: tabKey,
              hint: 'Tìm trận',
              groups: _groups,
              resultCount: count,
            ),
          ],
        ),
      ),
    ),
  );
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold)));

const _toggle = ValueKey('search-filter-toggle');
const _input = ValueKey('search-filter-input');

void main() {
  testWidgets('toggle opens the bar with a focused input and closes it again', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    expect(find.byKey(_input), findsNothing);

    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.byKey(_input), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(_input));
    expect(field.focusNode?.hasFocus, isTrue);

    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.byKey(_input), findsNothing);
  });

  testWidgets('typing updates the query after the debounce', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(_input), 'nam');
    await tester.pump(const Duration(milliseconds: 50));
    expect(_container(tester).read(searchFilterProvider('a')).query, '');
    await tester.pump(const Duration(milliseconds: 250));
    expect(_container(tester).read(searchFilterProvider('a')).query, 'nam');
  });

  testWidgets('chip selection raises the badge and survives closing', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-filter-group-court')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-filter-option-s1')));
    await tester.pumpAndSettle();
    expect(
      _container(tester).read(searchFilterProvider('a')).selected['court'],
      's1',
    );

    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('search-filter-badge')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(_container(tester).read(searchFilterProvider('a')).activeCount, 1);
  });

  testWidgets('clear all resets only its own tab', (tester) async {
    await tester.pumpWidget(_host());
    final container = _container(tester);
    container.read(searchFilterProvider('b').notifier).setQuery('keep');
    container.read(searchFilterProvider('a').notifier).setQuery('x');
    container.read(searchFilterProvider('a').notifier).setFilter('court', 's2');
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-filter-clear-all')));
    await tester.pumpAndSettle();
    final a = container.read(searchFilterProvider('a'));
    expect(a.query, '');
    expect(a.selected, isEmpty);
    expect(a.open, isTrue);
    expect(container.read(searchFilterProvider('b')).query, 'keep');
  });

  testWidgets('zero results shows 0 and the clear action', (tester) async {
    await tester.pumpWidget(_host(count: 0));
    _container(tester).read(searchFilterProvider('a').notifier).setQuery('zz');
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.text('0 kết quả'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-filter-clear-all')), findsOneWidget);
  });

  testWidgets('no overflow at 320dp with text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(textScale: 1.3));
    final container = _container(tester);
    container.read(searchFilterProvider('a').notifier).setQuery('Nguyễn');
    container.read(searchFilterProvider('a').notifier).setFilter('court', 's1');
    container
        .read(searchFilterProvider('a').notifier)
        .setFilter('status', 'u');
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('searchTextMatches ignores case and Vietnamese diacritics', () {
    expect(searchTextMatches('nguyen dinh', ['Nguyễn Đình Hải']), isTrue);
    expect(searchTextMatches('ĐÌNH', ['nguyen dinh']), isTrue);
    expect(searchTextMatches('', ['anything']), isTrue);
    expect(searchTextMatches('zzz', ['Nguyễn']), isFalse);
  });
}
