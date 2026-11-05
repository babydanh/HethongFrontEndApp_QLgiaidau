import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child, {ThemeData? theme}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.darkTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  for (final dark in [true, false]) {
    testWidgets('scaffold renders title, body, actions, bottom (dark=$dark)', (
      tester,
    ) async {
      await _pump(
        tester,
        const LavishScaffold(
          title: 'Tiêu đề',
          body: Text('thân'),
          actions: [Icon(Icons.add)],
          bottom: Text('đáy'),
        ),
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      );
      expect(find.text('Tiêu đề'), findsOneWidget);
      expect(find.text('thân'), findsOneWidget);
      expect(find.text('đáy'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  }

  testWidgets('scaffold back calls onBack', (tester) async {
    var backed = 0;
    await _pump(
      tester,
      LavishScaffold(
        title: 'T',
        body: const SizedBox(),
        onBack: () => backed++,
      ),
    );
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(backed, 1);
  });

  testWidgets('textfield shows label and errorText', (tester) async {
    await _pump(
      tester,
      const Scaffold(
        body: LavishTextField(label: 'Tên', errorText: 'Sai rồi'),
      ),
    );
    expect(find.text('Tên'), findsOneWidget);
    expect(find.text('Sai rồi'), findsOneWidget);
  });

  testWidgets('textfield reports changes and shows trailing', (tester) async {
    String? last;
    await _pump(
      tester,
      Scaffold(
        body: LavishTextField(
          label: 'Tên',
          trailing: const Icon(Icons.star),
          onChanged: (v) => last = v,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'abc');
    expect(last, 'abc');
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('obscure textfield toggles visibility', (tester) async {
    await _pump(
      tester,
      const Scaffold(body: LavishTextField(label: 'Mật khẩu', obscure: true)),
    );
    bool obscured() =>
        tester.widget<EditableText>(find.byType(EditableText)).obscureText;
    expect(obscured(), isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(obscured(), isTrue);
  });

  testWidgets('sticky bar fires and shows error', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: LavishStickyBar(
          label: 'Lưu',
          error: 'Lỗi lưu',
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.text('Lỗi lưu'), findsOneWidget);
    await tester.tap(find.text('Lưu'));
    expect(taps, 1);
  });

  testWidgets('sticky bar is disabled while busy', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: LavishStickyBar(
          label: 'Lưu',
          busy: true,
          onPressed: () => taps++,
        ),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(taps, 0);
  });

  testWidgets('stat grid renders values and labels', (tester) async {
    await _pump(
      tester,
      const Scaffold(
        body: LavishStatGrid(
          items: [
            LavishStat(label: 'Thắng', value: '12', tone: LavishTone.ok),
            LavishStat(label: 'Thua', value: '3'),
            LavishStat(label: 'Hoà', value: '1'),
          ],
        ),
      ),
    );
    for (final t in ['Thắng', '12', 'Thua', '3', 'Hoà', '1']) {
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('empty state shows title and action', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      Scaffold(
        body: LavishEmptyState(
          icon: Icons.inbox_rounded,
          title: 'Trống',
          action: 'Tạo mới',
          onAction: () => taps++,
        ),
      ),
    );
    expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
    expect(find.text('Trống'), findsOneWidget);
    await tester.tap(find.text('Tạo mới'));
    expect(taps, 1);
  });

  testWidgets('empty state without action has no button', (tester) async {
    await _pump(
      tester,
      const Scaffold(
        body: LavishEmptyState(icon: Icons.inbox_rounded, title: 'Trống'),
      ),
    );
    expect(find.byType(LavishButton), findsNothing);
  });

  testWidgets('error state shows message and retries', (tester) async {
    var retries = 0;
    await _pump(
      tester,
      Scaffold(
        body: LavishErrorState(message: 'Hỏng', onRetry: () => retries++),
      ),
    );
    expect(find.text('Hỏng'), findsOneWidget);
    await tester.tap(find.byType(LavishButton));
    expect(retries, 1);
  });

  testWidgets('error state falls back to the default message', (tester) async {
    await _pump(tester, Scaffold(body: LavishErrorState(onRetry: () {})));
    final context = tester.element(find.byType(LavishErrorState));
    expect(
      find.text(AppLocalizations.of(context)!.lavishErrorDefault),
      findsOneWidget,
    );
  });

  testWidgets('row skeleton renders without overflow', (tester) async {
    await _pump(tester, const Scaffold(body: LavishRowSkeleton(count: 3)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LavishRowSkeleton), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
