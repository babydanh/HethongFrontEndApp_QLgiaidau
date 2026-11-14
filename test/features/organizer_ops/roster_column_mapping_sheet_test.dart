import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_column_mapping_sheet.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_mapping_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';
import 'roster_mapping_fixture.dart';

const _screenSizes = [Size(360, 800), Size(400, 900)];

bool _doubles(String? _) => true;

Future<RosterMappingDraft> _sampleDraft({
  bool Function(String?) isDoublesFor = _doubles,
}) async {
  final sheets = await sampleUserLayoutGrid();
  return RosterMappingDraft.fromReading(
    readSheetByRules(sheets.single)!,
    isDoublesFor: isDoublesFor,
  );
}

/// Sheet thứ hai không có cột nhận diện (đã gỡ cột Tên).
Future<RosterMappingDraft> _nameless() async {
  final sheets = await workbookFrom([
    ['STT', 'Họ và tên'],
    [1, fakeName(0)],
  ], sheetName: 'Sheet2');
  return RosterMappingDraft.fromReading(
    readSheetByRules(sheets.single)!,
    isDoublesFor: _doubles,
  ).assign(1, null);
}

/// Trang chủ có nút mở popup; kết quả popup ghi vào [outcome].
class _Outcome {
  bool popped = false;
  RosterMappingResult? result;
}

Future<_Outcome> _open(
  WidgetTester tester,
  List<RosterMappingDraft> drafts, {
  Size size = const Size(360, 800),
  Locale locale = const Locale('vi'),
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final outcome = _Outcome();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const ValueKey('open'),
            onPressed: () async {
              outcome.result = await showRosterColumnMappingSheet(
                context,
                drafts: drafts,
              );
              outcome.popped = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
  return outcome;
}

Finder _key(String key) => find.byKey(ValueKey(key));

String _slotLabel(WidgetTester tester, int column) =>
    tester.widget<Text>(_key('roster-map-slot-$column')).data!;

Future<void> _pick(WidgetTester tester, int column, String chip) async {
  await tester.tap(_key('roster-map-column-$column'));
  await tester.pumpAndSettle();
  await tester.tap(_key('roster-map-chip-$column-$chip'));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in _screenSizes) {
    testWidgets(
      'TC-ROSTERMAP-17 mở popup hiện đủ cột, cột khóa có ổ khóa và không mở chip ($size)',
      (tester) async {
        await _open(tester, [await _sampleDraft()], size: size);

        for (var column = 0; column < 9; column++) {
          expect(_key('roster-map-column-$column'), findsOneWidget);
        }
        expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
        expect(find.text('Không lưu'), findsOneWidget);

        await tester.tap(_key('roster-map-column-0'));
        await tester.pumpAndSettle();
        expect(_key('roster-map-chip-0-player1Name'), findsNothing);
        await tester.ensureVisible(_key('roster-map-column-7'));
        await tester.pumpAndSettle();
        await tester.tap(_key('roster-map-column-7'));
        await tester.pumpAndSettle();
        expect(_key('roster-map-chip-7-player1Name'), findsNothing);
      },
    );
  }

  testWidgets('TC-ROSTERMAP-17 ô tiêu đề trống hiện chữ cột', (tester) async {
    final sheets = await workbookFrom([
      ['Họ và tên', 'Số điện thoại', null],
      [fakeName(0), fakePhone(0), 'x'],
    ]);
    final draft = RosterMappingDraft.fromReading(
      readSheetByRules(sheets.single)!,
      isDoublesFor: _doubles,
    );
    await _open(tester, [draft]);

    expect(find.text('Cột C'), findsOneWidget);
  });

  testWidgets(
    'TC-ROSTERMAP-18 chọn chip đổi nhãn cột và đưa cột cũ về Ghi chú',
    (tester) async {
      await _open(tester, [await _sampleDraft()]);
      expect(_slotLabel(tester, 4), 'SĐT');

      await _pick(tester, 5, 'player1Phone');
      expect(_slotLabel(tester, 5), 'SĐT');
      expect(_slotLabel(tester, 4), 'Ghi chú');

      await _pick(tester, 2, 'player1Name');
      expect(_slotLabel(tester, 2), 'Tên');
      expect(_slotLabel(tester, 1), 'Ghi chú');
    },
  );

  testWidgets(
    'TC-ROSTERMAP-19 thiếu nhận diện thì Xong tắt và hiện lời nhắc đỏ',
    (tester) async {
      await _open(tester, [await _sampleDraft()]);
      expect(_key('roster-map-pick-name'), findsNothing);
      expect(
        tester.widget<FilledButton>(_key('roster-map-done')).onPressed,
        isNotNull,
      );

      await _pick(tester, 1, 'note');

      expect(
        tester.widget<FilledButton>(_key('roster-map-done')).onPressed,
        isNull,
      );
      final colors = Theme.of(
        tester.element(find.byType(RosterColumnMappingSheet)),
      ).extension<AppColorsExtension>()!;
      final hint = tester.widget<Text>(find.text('Chọn cột Tên'));
      expect(hint.style?.color, colors.error);
    },
  );

  testWidgets(
    'TC-ROSTERMAP-20 đổi hàng tiêu đề, kẹp giá trị và cảnh báo ô gộp',
    (tester) async {
      await _open(tester, [await _sampleDraft()]);
      String field() => tester
          .widget<TextField>(_key('roster-map-header-field'))
          .controller!
          .text;
      expect(field(), '2');
      expect(_key('roster-map-header-shifted'), findsNothing);

      await tester.enterText(_key('roster-map-header-field'), '0');
      await tester.pumpAndSettle();
      expect(field(), '1');
      expect(_key('roster-map-header-shifted'), findsOneWidget);

      await tester.tap(_key('roster-map-header-plus'));
      await tester.pumpAndSettle();
      expect(field(), '2');
      expect(_key('roster-map-header-shifted'), findsNothing);

      await tester.tap(_key('roster-map-header-minus'));
      await tester.pumpAndSettle();
      expect(field(), '1');
    },
  );

  testWidgets('TC-ROSTERMAP-21 cách ghép cặp chỉ hiện với nội dung đôi', (
    tester,
  ) async {
    await _open(tester, [await _sampleDraft(isDoublesFor: (_) => false)]);
    expect(_key('roster-map-layout-row'), findsNothing);
  });

  testWidgets('TC-ROSTERMAP-21 chọn hai VĐV một ô thì hiện ô ký tự ngăn', (
    tester,
  ) async {
    final outcome = await _open(tester, [await _sampleDraft()]);
    expect(_key('roster-map-layout-row'), findsOneWidget);
    expect(_key('roster-map-separator'), findsNothing);

    await tester.tap(_key('roster-map-layout-sameCell'));
    await tester.pumpAndSettle();
    expect(_key('roster-map-separator'), findsOneWidget);

    await tester.enterText(_key('roster-map-separator'), ' & ');
    await tester.tap(_key('roster-map-done'));
    await tester.pumpAndSettle();
    final reading = outcome.result!.readings.single;
    expect(reading.layout, RosterPairLayout.sameCell);
    expect(reading.separator, ' & ');
  });

  testWidgets('TC-ROSTERMAP-22 đóng bằng nút đóng trả null', (tester) async {
    final outcome = await _open(tester, [await _sampleDraft()]);
    await _pick(tester, 5, 'player1Phone');

    await tester.tap(_key('roster-map-close'));
    await tester.pumpAndSettle();

    expect(outcome.popped, isTrue);
    expect(outcome.result, isNull);
  });

  testWidgets(
    'TC-ROSTERMAP-23 nhiều khối có dải sheet và chấm đỏ khối thiếu nhận diện',
    (tester) async {
      final outcome = await _open(tester, [
        await _sampleDraft(),
        await _nameless(),
      ]);
      expect(_key('roster-map-sheet-0'), findsOneWidget);
      expect(_key('roster-map-sheet-dot-0'), findsNothing);
      expect(_key('roster-map-sheet-dot-1'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(_key('roster-map-done')).onPressed,
        isNull,
      );

      await tester.tap(_key('roster-map-sheet-1'));
      await tester.pumpAndSettle();
      await _pick(tester, 1, 'player1Name');

      expect(_key('roster-map-sheet-dot-1'), findsNothing);
      await tester.tap(_key('roster-map-done'));
      await tester.pumpAndSettle();
      expect(outcome.result!.readings, hasLength(2));
      expect(outcome.result!.skippedSheets, isEmpty);
    },
  );

  for (final dark in [true, false]) {
    for (final locale in const [Locale('vi'), Locale('en')]) {
      testWidgets(
        'TC-ROSTERMAP-24 không tràn chữ và vùng chạm đủ 44 dp (${dark ? 'tối' : 'sáng'}, $locale)',
        (tester) async {
          await _open(
            tester,
            [await _sampleDraft()],
            locale: locale,
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          );
          await tester.tap(_key('roster-map-column-5'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(tester.getSize(_key('roster-map-column-5')).height, ge44);
          final chips = find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'roster-map-chip-5-',
                ),
          );
          expect(chips, findsWidgets);
          for (final chip in chips.evaluate()) {
            expect(tester.getSize(find.byWidget(chip.widget)).height, ge44);
          }
          for (final button in ['plus', 'minus']) {
            expect(
              tester.getSize(_key('roster-map-header-$button')).shortestSide,
              ge44,
            );
          }
        },
      );
    }
  }
}

final Matcher ge44 = greaterThanOrEqualTo(44.0);
