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

Widget _body({
  String tabKey = 'a',
  int count = 3,
  int hidden = 0,
  List<SearchFilterGroup> groups = _groups,
}) => Column(
  children: [
    Row(
      children: [SearchFilterToggle(tabKey: tabKey, groups: groups)],
    ),
    SearchFilterBar(
      tabKey: tabKey,
      hint: 'Tìm trận',
      groups: groups,
      resultCount: count,
      hiddenCount: hidden,
    ),
  ],
);

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
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
  home: home,
);

Widget _host({
  String tabKey = 'a',
  int count = 3,
  int hidden = 0,
  double textScale = 1,
  List<SearchFilterGroup> groups = _groups,
}) => ProviderScope(
  child: _app(
    Scaffold(
      body: _body(tabKey: tabKey, count: count, hidden: hidden, groups: groups),
    ),
    textScale: textScale,
  ),
);

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold)));

const _toggle = ValueKey('search-filter-toggle');
const _input = ValueKey('search-filter-input');
const _clearAll = ValueKey('search-filter-clear-all');

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

  testWidgets('a bar that is mounted already open does not grab focus', (
    tester,
  ) async {
    final container = ProviderContainer();
    container.read(searchFilterProvider('a').notifier).setOpen(true);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(Scaffold(body: _body())),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byKey(_input));
    expect(field.focusNode?.hasFocus, isFalse);
    // The keep-alive timer is cancelled when the container goes away.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('state survives unmounting and remounting the widgets', (
    tester,
  ) async {
    final container = ProviderContainer();
    Widget mount() => UncontrolledProviderScope(
      container: container,
      child: _app(Scaffold(body: _body())),
    );
    await tester.pumpWidget(mount());
    container.read(searchFilterProvider('a').notifier).setQuery('keep');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(mount());
    expect(container.read(searchFilterProvider('a')).query, 'keep');
    await tester.pumpWidget(const SizedBox());
    container.dispose();
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

    await tester.tap(find.byKey(_clearAll));
    await tester.pumpAndSettle();
    final a = container.read(searchFilterProvider('a'));
    expect(a.query, '');
    expect(a.selected, isEmpty);
    expect(a.open, isTrue);
    expect(container.read(searchFilterProvider('b')).query, 'keep');
  });

  testWidgets('clear all drops text typed but not yet pushed by the debounce', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    final container = _container(tester);
    container.read(searchFilterProvider('a').notifier).setFilter('court', 's1');
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(_input), 'abc');
    await tester.tap(find.byKey(_clearAll));
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(searchFilterProvider('a')).query, '');
    expect(tester.widget<TextField>(find.byKey(_input)).controller?.text, '');
  });

  testWidgets('zero results shows 0 and the clear action', (tester) async {
    await tester.pumpWidget(_host(count: 0));
    _container(tester).read(searchFilterProvider('a').notifier).setQuery('zz');
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.text('0 kết quả'), findsOneWidget);
    expect(find.byKey(_clearAll), findsOneWidget);
  });

  testWidgets('hidden results are reported on their own line', (tester) async {
    await tester.pumpWidget(_host(count: 2, hidden: 3));
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.text('2 kết quả'), findsOneWidget);
    expect(find.text('3 kết quả ở ngày hoặc sân đang ẩn'), findsOneWidget);
  });

  testWidgets('a filter value no longer offered is ignored, not counted', (
    tester,
  ) async {
    // The court group is gone (e.g. only one court left): its old value must
    // not keep filtering invisibly or count in the badge.
    await tester.pumpWidget(_host(groups: [_groups[1]]));
    final container = _container(tester);
    container.read(searchFilterProvider('a').notifier).setFilter('court', 'X');
    container.read(searchFilterProvider('a').notifier).setOpen(true);
    await tester.pumpAndSettle();

    expect(find.byKey(_clearAll), findsNothing);
    // Badge and clear action ignore it; the stored value is kept.
    expect(
      tester
          .widget<Badge>(find.byKey(const ValueKey('search-filter-badge')))
          .isLabelVisible,
      isFalse,
    );
    expect(container.read(searchFilterProvider('a')).selected, {'court': 'X'});
  });

  testWidgets('a filter survives groups that are briefly not offered', (
    tester,
  ) async {
    // e.g. the divisions list is reloading: the chip group disappears for a
    // moment and then comes back. The user's filter must still be there.
    final offered = ValueNotifier<List<SearchFilterGroup>>(_groups);
    await tester.pumpWidget(
      ProviderScope(
        child: _app(
          Scaffold(
            body: ValueListenableBuilder<List<SearchFilterGroup>>(
              valueListenable: offered,
              builder: (_, groups, _) => _body(groups: groups),
            ),
          ),
        ),
      ),
    );
    final container = _container(tester);
    container.read(searchFilterProvider('a').notifier).setFilter('court', 's1');
    container.read(searchFilterProvider('a').notifier).setOpen(true);
    await tester.pumpAndSettle();
    expect(find.byKey(_clearAll), findsOneWidget);

    offered.value = const [];
    await tester.pumpAndSettle();
    // Hidden while not offered, but not thrown away.
    expect(find.byKey(_clearAll), findsNothing);
    expect(container.read(searchFilterProvider('a')).selected, {'court': 's1'});

    offered.value = _groups;
    await tester.pumpAndSettle();
    expect(find.byKey(_clearAll), findsOneWidget);
    expect(container.read(searchFilterProvider('a')).selected, {'court': 's1'});
  });

  test('pruned() drops groups and values that are not offered', () {
    const state = SearchFilterState(
      selected: {'court': 'X', 'status': 'x', 'gone': 'y'},
    );
    expect(state.pruned(_groups).selected, {'status': 'x'});
  });

  testWidgets('Back closes the visible bar but ignores a covered one', (
    tester,
  ) async {
    final covered = ValueNotifier(false);
    await tester.pumpWidget(
      ProviderScope(child: _app(const Scaffold(body: SizedBox.expand()))),
    );
    final navigator = Navigator.of(tester.element(find.byType(Scaffold)));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ValueListenableBuilder<bool>(
          valueListenable: covered,
          builder: (_, isCovered, _) => TickerMode(
            enabled: !isCovered,
            child: Scaffold(key: const ValueKey('page'), body: _body()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('page'))),
    );

    // Visible bar: Back closes the bar, the page stays.
    container.read(searchFilterProvider('a').notifier).setOpen(true);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(container.read(searchFilterProvider('a')).open, isFalse);
    expect(find.byKey(const ValueKey('page')), findsOneWidget);

    // Covered bar (hidden tab): Back leaves the page, the bar is untouched.
    container.read(searchFilterProvider('a').notifier).setOpen(true);
    covered.value = true;
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page')), findsNothing);
    expect(container.read(searchFilterProvider('a')).open, isTrue);
  });

  testWidgets('toggle exposes open state and the filter count to a11y', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    final container = _container(tester);
    container.read(searchFilterProvider('a').notifier).setFilter('court', 's1');
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();

    final button = tester.widget<IconButton>(find.byKey(_toggle));
    expect(button.isSelected, isTrue);
    expect(button.tooltip, contains('1 điều kiện lọc'));
  });

  testWidgets('chips and close button are at least 40dp tall', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    final chip = tester.getSize(
      find.byKey(const ValueKey('search-filter-group-court')),
    );
    expect(chip.height, greaterThanOrEqualTo(40));
    final close = tester.getSize(
      find.byKey(const ValueKey('search-filter-close')),
    );
    expect(close.shortestSide, greaterThanOrEqualTo(40));
  });

  testWidgets('no overflow at 320dp with text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(textScale: 1.3, hidden: 4));
    final container = _container(tester);
    container.read(searchFilterProvider('a').notifier).setQuery('Nguyễn');
    container.read(searchFilterProvider('a').notifier).setFilter('court', 's1');
    container.read(searchFilterProvider('a').notifier).setFilter('status', 'u');
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('searchTextMatches ignores case and Vietnamese diacritics', () {
    expect(
      searchTextMatches(foldSearchText('nguyen dinh'), ['Nguyễn Đình Hải']),
      isTrue,
    );
    expect(searchTextMatches(foldSearchText('ĐÌNH'), ['nguyen dinh']), isTrue);
    expect(searchTextMatches(foldSearchText(''), ['anything']), isTrue);
    expect(searchTextMatches(foldSearchText('zzz'), ['Nguyễn']), isFalse);
  });
}
