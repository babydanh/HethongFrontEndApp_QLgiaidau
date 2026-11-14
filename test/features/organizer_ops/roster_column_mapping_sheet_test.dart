import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_column_mapping_sheet.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_mapping_draft.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_mapping_fixture.dart';

bool _allDoubles(String? _) => true;
bool _noDoubles(String? _) => false;

Future<RosterMappingDraft> _sampleDraft({
  bool Function(String?) doubles = _allDoubles,
}) async {
  final grid = await sampleUserLayoutGrid();
  return RosterMappingDraft.fromReading(
    readSheetByRules(grid.single)!,
    isDoublesFor: doubles,
  );
}

class _Opened {
  RosterMappingResult? result;
  bool closed = false;
}

Future<_Opened> _open(
  WidgetTester tester,
  List<RosterMappingDraft> drafts, {
  Size size = const Size(400, 900),
  ThemeData? theme,
  Locale locale = const Locale('vi'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final opened = _Opened();
  // Bỏ cây cũ để route popup của lần mở trước không còn trên Navigator.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const ValueKey('open'),
            onPressed: () async {
              opened.result = await showRosterColumnMappingSheet(
                context,
                drafts: drafts,
              );
              opened.closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
  return opened;
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Finder _pillText(String column, String text) => find.descendant(
  of: _key('roster-map-pill-$column'),
  matching: find.text(text),
);

bool _doneEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_key('roster-map-done')).onPressed != null;

const _sizes = [Size(360, 800), Size(400, 900)];

void main() {
  for (final size in _sizes) {
    group('RosterColumnMappingSheet ${size.width.toInt()}x${size.height.toInt()}', () {
      testWidgets(
        'TC-ROSTERMAP-17 hiện đủ cột, cột khóa có ổ khóa và không mở chip',
        (tester) async {
          final draft = await _sampleDraft();
          await _open(tester, [draft], size: size);

          for (final column in draft.columns) {
            expect(
              _key('roster-map-col-${column.index}'),
              findsOneWidget,
              reason: column.header,
            );
          }
          expect(_pillText('0', 'STT'), findsOneWidget);
          expect(_pillText('7', 'Không lưu'), findsOneWidget);
          expect(
            find.descendant(
              of: _key('roster-map-pill-7'),
              matching: find.byIcon(Icons.lock_outline_rounded),
            ),
            findsOneWidget,
          );

          await _tap(tester, 'roster-map-col-7');
          await _tap(tester, 'roster-map-col-0');
          expect(_key('roster-map-chip-player1Name'), findsNothing);
        },
      );

      testWidgets(
        'TC-ROSTERMAP-18 chọn chip đổi nhãn cột, chiếm lại trường thì cột cũ về Ghi chú',
        (tester) async {
          final draft = await _sampleDraft();
          await _open(tester, [draft], size: size);
          expect(_pillText('4', 'SĐT'), findsOneWidget);

          await _tap(tester, 'roster-map-col-4');
          await _tap(tester, 'roster-map-chip-player1Email');
          expect(_pillText('4', 'Email'), findsOneWidget);

          await _tap(tester, 'roster-map-col-2');
          await _tap(tester, 'roster-map-chip-player1Name');
          expect(_pillText('2', 'Tên'), findsOneWidget);
          expect(_pillText('1', 'Ghi chú'), findsOneWidget);
        },
      );

      testWidgets(
        'TC-ROSTERMAP-19 thiếu nhận diện thì Xong tắt và hiện lời nhắc màu lỗi',
        (tester) async {
          final draft = await _sampleDraft();
          await _open(tester, [draft], size: size);
          expect(_key('roster-map-pick-name'), findsNothing);
          expect(_doneEnabled(tester), isTrue);

          await _tap(tester, 'roster-map-col-1');
          await _tap(tester, 'roster-map-chip-note');

          expect(_doneEnabled(tester), isFalse);
          final hint = tester.widget<Text>(_key('roster-map-pick-name'));
          expect(hint.data, 'Chọn cột Tên');
          expect(
            hint.style?.color,
            AppTheme.darkTheme.extension<AppColorsExtension>()!.error,
          );
        },
      );

      testWidgets(
        'TC-ROSTERMAP-20 hàng tiêu đề đổi bằng nút, kẹp giá trị và cảnh báo ô gộp',
        (tester) async {
          final draft = await _sampleDraft();
          await _open(tester, [draft], size: size);
          String field() => tester
              .widget<TextField>(_key('roster-map-header-field'))
              .controller!
              .text;
          expect(field(), '2');
          expect(find.text('Hàng tiêu đề'), findsOneWidget);

          await _tap(tester, 'roster-map-header-plus');
          expect(field(), '3');
          await _tap(tester, 'roster-map-header-minus');
          expect(field(), '2');

          await tester.enterText(_key('roster-map-header-field'), '0');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(field(), '1');
          expect(
            find.textContaining('Tiêu đề đang nằm trong ô gộp'),
            findsOneWidget,
          );

          await _tap(tester, 'roster-map-header-plus');
          expect(field(), '2');
          expect(
            find.textContaining('Tiêu đề đang nằm trong ô gộp'),
            findsNothing,
          );
        },
      );

      testWidgets(
        'TC-ROSTERMAP-21 cách ghép cặp chỉ hiện với nội dung đôi, ô ngăn hiện khi chọn hai VĐV một ô',
        (tester) async {
          await _open(tester, [
            await _sampleDraft(doubles: _noDoubles),
          ], size: size);
          expect(_key('roster-map-pair-single'), findsNothing);

          await _open(tester, [await _sampleDraft()], size: size);
          expect(_key('roster-map-pair-single'), findsOneWidget);
          expect(_key('roster-map-separator'), findsNothing);

          await _tap(tester, 'roster-map-pair-sameCell');
          expect(_key('roster-map-separator'), findsOneWidget);
        },
      );

      testWidgets('TC-ROSTERMAP-22 đóng bằng nút đóng trả null', (
        tester,
      ) async {
        final opened = await _open(tester, [await _sampleDraft()], size: size);

        await _tap(tester, 'roster-map-close');

        expect(opened.closed, isTrue);
        expect(opened.result, isNull);
      });

      testWidgets(
        'TC-ROSTERMAP-23 nhiều khối có dải chip, chấm đỏ ở khối thiếu nhận diện',
        (tester) async {
          final good = await _sampleDraft();
          final bad = RosterMappingDraft.fromReading(
            good.reading.copyWith(mapping: const RosterColumnMapping({})),
            isDoublesFor: _allDoubles,
          );
          final opened = await _open(tester, [good, bad], size: size);

          expect(_key('roster-map-sheet-0'), findsOneWidget);
          expect(_key('roster-map-sheet-1'), findsOneWidget);
          expect(_key('roster-map-sheet-dot-0'), findsNothing);
          expect(_key('roster-map-sheet-dot-1'), findsOneWidget);
          expect(_doneEnabled(tester), isFalse);

          await _tap(tester, 'roster-map-sheet-1');
          await _tap(tester, 'roster-map-col-1');
          await _tap(tester, 'roster-map-chip-player1Name');
          expect(_key('roster-map-sheet-dot-1'), findsNothing);
          expect(_doneEnabled(tester), isTrue);

          await _tap(tester, 'roster-map-done');
          expect(opened.result!.readings, hasLength(2));
          expect(opened.result!.skippedSheets, isEmpty);
        },
      );

      testWidgets(
        'TC-ROSTERMAP-24 chế độ tối và tiếng Anh không tràn, vùng chạm đủ 44 dp',
        (tester) async {
          final draft = await _sampleDraft();
          for (final theme in [AppTheme.darkTheme, AppTheme.lightTheme]) {
            await _open(
              tester,
              [draft],
              size: size,
              theme: theme,
              locale: const Locale('en'),
            );
            await _tap(tester, 'roster-map-col-2');

            expect(tester.takeException(), isNull);
            for (final column in draft.columns) {
              expect(
                tester.getSize(_key('roster-map-col-${column.index}')).height,
                greaterThanOrEqualTo(44),
              );
            }
            for (final chip in tester.widgetList(
              find.byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith(
                      'roster-map-chip-',
                    ),
              ),
            )) {
              expect(
                tester.getSize(find.byWidget(chip)).height,
                greaterThanOrEqualTo(44),
              );
            }
            await tester.pumpWidget(const SizedBox());
          }
        },
      );
    });
  }

  test(
    'RosterMappingResult.fromDrafts đưa sheet bỏ qua đã đủ nhận diện vào khối đọc được',
    () async {
      final grid = await sampleUserLayoutGrid();
      final skipped = RosterMappingDraft.forSkippedSheet(
        grid.single,
        isDoublesFor: _allDoubles,
      );

      final result = RosterMappingResult.fromDrafts([skipped]);

      expect(result.readings, hasLength(1));
      expect(result.skippedSheets, isEmpty);
    },
  );
}
