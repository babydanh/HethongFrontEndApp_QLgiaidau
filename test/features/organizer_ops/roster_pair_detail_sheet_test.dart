import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_pair_detail_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';
import 'roster_list_fixture.dart';

class _Outcome {
  bool popped = false;
  RosterRowEdit? edit;
}

const _candidate = RosterImportBatchCandidate(
  userId: 'u-1',
  email: 'a@example.com',
  fullName: 'Tài khoản A',
);

Future<_Outcome> _open(
  WidgetTester tester, {
  RosterDraftRow? row,
  List<String> reasons = const [],
  bool customError = false,
  List<RosterImportBatchCandidate> candidates1 = const [],
  bool showPlayer2 = true,
  bool readOnly = false,
  Size size = const Size(360, 800),
  Locale locale = const Locale('vi'),
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final outcome = _Outcome();
  final draft =
      row ??
      fakeDraftRow(
        email1: 'a@example.com',
        name2: fakeName(1),
        email2: 'b@example.com',
      );
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const ValueKey('open'),
              onPressed: () async {
                outcome.edit = await showRosterPairDetailSheet(
                  context,
                  row: draft,
                  reasonCodes: reasons,
                  customResponseError: customError,
                  candidates1: candidates1,
                  candidates2: const [],
                  showPlayer2: showPlayer2,
                  readOnly: readOnly,
                );
                outcome.popped = true;
              },
              child: const Text('mở'),
            ),
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

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(_key(key));
  await tester.enterText(_key(key), text);
  await tester.pump();
}

Future<void> _tapDone(WidgetTester tester) async {
  await tester.ensureVisible(_key('roster-detail-done'));
  await tester.tap(_key('roster-detail-done'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-ROSTERDETAIL-01 dòng có mã hiện dải lý do đúng màu và chuỗi trạng thái',
    (tester) async {
      await _open(
        tester,
        reasons: ['DUPLICATE_IN_FILE', 'MISSING_EMAIL'],
        customError: true,
      );

      expect(find.text('Trùng trong file'), findsOneWidget);
      expect(find.text('Thiếu email'), findsOneWidget);
      expect(find.text('Ghi chú không hợp lệ'), findsOneWidget);
      final colors = AppTheme.lightTheme.extension<AppColorsExtension>()!;
      Color textColor(String text) =>
          tester.widget<Text>(find.text(text)).style!.color!;
      expect(textColor('Trùng trong file'), colors.error);
      expect(textColor('Thiếu email'), colors.warning);
    },
  );

  testWidgets('TC-ROSTERDETAIL-02 sửa tên rồi đóng bằng nút đóng trả null', (
    tester,
  ) async {
    final outcome = await _open(tester);

    await _type(tester, 'roster-detail-name-1', 'Tên Mới');
    await tester.tap(_key('roster-detail-close'));
    await tester.pumpAndSettle();

    expect(outcome.popped, isTrue);
    expect(outcome.edit, isNull);
  });

  testWidgets(
    'TC-ROSTERDETAIL-03 Xong trả đúng trường đã đổi, email cắt khoảng trắng, ô trống thành null',
    (tester) async {
      final outcome = await _open(tester);

      await _type(tester, 'roster-detail-name-1', 'Tên Mới');
      await _type(tester, 'roster-detail-email-1', '  moi@example.com  ');
      await _type(tester, 'roster-detail-phone-1', '');
      await tester.ensureVisible(_key('roster-detail-paid'));
      await tester.tap(_key('roster-detail-paid'));
      await tester.pump();
      await _tapDone(tester);

      final edit = outcome.edit!;
      expect(edit.delete, isFalse);
      expect(edit.player1Name, 'Tên Mới');
      expect(edit.player1Email, 'moi@example.com');
      expect(edit.player1Phone, isNull);
      expect(edit.player2Name, fakeName(1));
      expect(edit.isPaid, isTrue);
      expect(edit.notes, isNull);
    },
  );

  testWidgets(
    'TC-ROSTERDETAIL-04 email sai báo đỏ ngay khi gõ và Xong vẫn bấm được',
    (tester) async {
      final outcome = await _open(tester);

      await _type(tester, 'roster-detail-email-1', 'sai@');

      expect(find.text('Email chưa đúng'), findsOneWidget);
      await _tapDone(tester);
      expect(outcome.edit!.player1Email, 'sai@');
    },
  );

  testWidgets('TC-ROSTERDETAIL-05 ghi chú cắt ở 2000 ký tự', (tester) async {
    final outcome = await _open(tester);

    await _type(tester, 'roster-detail-notes', 'x' * 2500);
    await _tapDone(tester);

    expect(outcome.edit!.notes!.length, 2000);
  });

  testWidgets('TC-ROSTERDETAIL-06 nội dung đơn không có VĐV 2 chỉ một khối', (
    tester,
  ) async {
    await _open(
      tester,
      row: fakeDraftRow(
        email1: 'a@example.com',
        target: fakeTarget(isDoubles: false),
      ),
      showPlayer2: false,
    );

    expect(_key('roster-detail-name-1'), findsOneWidget);
    expect(_key('roster-detail-name-2'), findsNothing);
  });

  testWidgets(
    'TC-ROSTERDETAIL-07 nút tài khoản liệt kê để trống và ứng viên, chọn ứng viên trả linked',
    (tester) async {
      final outcome = await _open(tester, candidates1: const [_candidate]);

      await tester.ensureVisible(_key('roster-detail-account-1'));
      await tester.tap(_key('roster-detail-account-1'));
      await tester.pumpAndSettle();
      expect(find.text('Để trống (không liên kết)'), findsOneWidget);
      await tester.tap(find.text('Tài khoản A (a@example.com)'));
      await tester.pumpAndSettle();
      await _tapDone(tester);

      final link = outcome.edit!.player1Link;
      expect(link.choice, RosterLinkChoice.linked);
      expect(link.userId, 'u-1');
    },
  );

  testWidgets('TC-ROSTERDETAIL-08 Xóa cặp trả RosterRowEdit.delete', (
    tester,
  ) async {
    final outcome = await _open(tester);

    await tester.ensureVisible(_key('roster-detail-delete'));
    await tester.tap(_key('roster-detail-delete'));
    await tester.pumpAndSettle();

    expect(outcome.edit!.delete, isTrue);
  });

  for (final locale in [const Locale('vi'), const Locale('en')]) {
    testWidgets(
      'TC-ROSTERDETAIL-09 360 dp chế độ tối ${locale.languageCode} không tràn, vùng chạm ≥ 44 dp',
      (tester) async {
        final long = 'Nguyễn Thị ${'Rất Dài ' * 10}';
        await _open(
          tester,
          row: fakeDraftRow(
            name1: long,
            email1: 'a@example.com',
            name2: long,
            email2: 'b@example.com',
          ),
          reasons: ['DUPLICATE_IN_FILE', 'MISSING_EMAIL', 'PLAYER2_REQUIRED'],
          candidates1: const [_candidate],
          theme: AppTheme.darkTheme,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
        for (final key in [
          'roster-detail-done',
          'roster-detail-delete',
          'roster-detail-close',
          'roster-detail-account-1',
        ]) {
          await tester.ensureVisible(_key(key));
          final size = tester.getSize(_key(key));
          expect(size.height, greaterThanOrEqualTo(44), reason: key);
          expect(size.width, greaterThanOrEqualTo(44), reason: key);
        }
      },
    );
  }

  testWidgets('readOnly tắt ô nhập, Xong và Xóa cặp', (tester) async {
    await _open(tester, readOnly: true);

    expect(
      tester.widget<TextField>(_key('roster-detail-name-1')).enabled,
      isFalse,
    );
    expect(
      tester.widget<FilledButton>(_key('roster-detail-done')).onPressed,
      isNull,
    );
    expect(
      tester.widget<TextButton>(_key('roster-detail-delete')).onPressed,
      isNull,
    );
  });
}
