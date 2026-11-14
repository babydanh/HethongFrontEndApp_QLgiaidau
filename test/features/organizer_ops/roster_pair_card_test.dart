import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_pair_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';
import 'roster_list_fixture.dart';

RosterCardStatus _status({
  required RosterDraftRow row,
  RosterImportBatchPreviewRow? server,
  bool previewing = false,
  bool doubles = false,
}) => rosterCardStatus(
  row: row,
  server: server,
  previewing: previewing,
  isDoublesDivision: doubles,
);

void main() {
  group('rosterCardStatus', () {
    test('TC-ROSTERLIST-04 blocked khi có DUPLICATE_IN_FILE cục bộ', () {
      final row = fakeDraftRow(localStatus: ['DUPLICATE_IN_FILE']);

      expect(_status(row: row), RosterCardStatus.blocked);
    });

    test('TC-ROSTERLIST-05 blocked khi server báo isEligible false', () {
      final row = fakeDraftRow(email1: 'a@example.com');

      expect(
        _status(row: row, server: fakeServerRow(isEligible: false)),
        RosterCardStatus.blocked,
      );
    });

    test('TC-ROSTERLIST-06 warning khi thiếu email', () {
      final row = fakeDraftRow(localStatus: ['MISSING_EMAIL']);

      expect(
        _status(
          row: row,
          server: fakeServerRow(status: ['MISSING_EMAIL']),
        ),
        RosterCardStatus.warning,
      );
    });

    test('TC-ROSTERLIST-06 warning khi nội dung đôi chưa có VĐV 2', () {
      final row = fakeDraftRow(email1: 'a@example.com');

      expect(
        _status(row: row, server: fakeServerRow(), doubles: true),
        RosterCardStatus.warning,
      );
    });

    test('TC-ROSTERLIST-07 NOT_FOUND một mình vẫn là ok', () {
      final row = fakeDraftRow(email1: 'a@example.com');

      expect(
        _status(
          row: row,
          server: fakeServerRow(status: ['NOT_FOUND']),
        ),
        RosterCardStatus.ok,
      );
    });

    test('TC-ROSTERLIST-08 loading khi chưa có server và đang preview', () {
      final row = fakeDraftRow(email1: 'a@example.com');

      expect(_status(row: row, previewing: true), RosterCardStatus.loading);
    });
  });

  group('TC-ROSTERLIST-09 RosterPairCard', () {
    Future<void> pump(
      WidgetTester tester,
      RosterPairCard card, {
      Size size = const Size(360, 800),
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: card)),
        ),
      );
    }

    RosterPairCard card({
      required RosterDraftRow row,
      RosterImportBatchPreviewRow? server,
      bool previewing = false,
      bool linked1 = false,
      bool hasCandidate1 = false,
      VoidCallback? onTap,
    }) => RosterPairCard(
      row: row,
      server: server,
      previewing: previewing,
      isDoublesDivision: true,
      linked1: linked1,
      linked2: false,
      hasAccountCandidate1: hasCandidate1,
      hasAccountCandidate2: false,
      onTap: onTap,
    );

    testWidgets('hiện hai tên, tròn ✓ xanh và icon liên kết khi đủ điều kiện', (
      tester,
    ) async {
      final row = fakeDraftRow(
        email1: 'a@example.com',
        name2: fakeName(1),
        email2: 'b@example.com',
      );
      await pump(
        tester,
        card(row: row, server: fakeServerRow(), linked1: true),
      );

      expect(find.text(fakeName(0)), findsOneWidget);
      expect(find.text(fakeName(1)), findsOneWidget);
      expect(
        find.byKey(const ValueKey('roster-card-status-ok')),
        findsOneWidget,
      );
      final colors = AppTheme.lightTheme.extension<AppColorsExtension>()!;
      final dot = tester.widget<Container>(
        find.byKey(const ValueKey('roster-card-status-ok')),
      );
      expect(
        (dot.decoration as BoxDecoration).color,
        colors.success.withValues(alpha: 0.16),
      );
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    });

    testWidgets(
      'chưa có preview thì hiện vòng tải và không hiện icon tài khoản',
      (tester) async {
        final row = fakeDraftRow(email1: 'a@example.com');
        await pump(tester, card(row: row, previewing: true));

        expect(
          find.byKey(const ValueKey('roster-card-status-loading')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.link_rounded), findsNothing);
        expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
      },
    );

    testWidgets('NOT_FOUND hiện icon người mờ, không hiện chữ', (tester) async {
      final row = fakeDraftRow(email1: 'a@example.com');
      await pump(
        tester,
        card(
          row: row,
          server: fakeServerRow(status: ['NOT_FOUND']),
        ),
      );

      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      expect(find.text('Chưa có tài khoản'), findsNothing);
    });

    testWidgets('bị chặn thì hiện ✕ và chữ lý do', (tester) async {
      final row = fakeDraftRow(localStatus: ['DUPLICATE_IN_FILE']);
      await pump(tester, card(row: row));

      expect(
        find.byKey(const ValueKey('roster-card-status-blocked')),
        findsOneWidget,
      );
      expect(find.text('Trùng trong file'), findsOneWidget);
    });

    testWidgets('vùng chạm cao ít nhất 44 dp và gọi onTap', (tester) async {
      var taps = 0;
      final row = fakeDraftRow(email1: 'a@example.com');
      await pump(tester, card(row: row, onTap: () => taps++));

      expect(
        tester.getSize(find.byKey(const ValueKey('roster-row-0'))).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.byKey(const ValueKey('roster-row-0')));
      expect(taps, 1);
    });

    testWidgets('tên rất dài ở 360 dp chế độ tối không tràn', (tester) async {
      final long = 'Nguyễn Thị ${'Rất Dài ' * 12}';
      final row = fakeDraftRow(
        name1: long,
        email1: 'a@example.com',
        name2: long,
        email2: 'b@example.com',
      );
      await pump(
        tester,
        card(row: row, server: fakeServerRow(), linked1: true),
        theme: AppTheme.darkTheme,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
