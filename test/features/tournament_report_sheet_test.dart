import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_report_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(
  WidgetTester tester,
  Future<void> Function(Set<TournamentReportSection>) onExport,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                TournamentReportSheet.show(context, onExport: onExport),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Finder exportButton(String label) => find.widgetWithText(FilledButton, label);

  testWidgets('all sheets are ticked and the button counts the selection', (
    tester,
  ) async {
    await _open(tester, (_) async {});

    expect(exportButton(l10n.tournamentReportExport(2)), findsOneWidget);
    await tester.tap(find.text(l10n.tournamentReportSheetMatches));
    await tester.pump();
    expect(exportButton(l10n.tournamentReportExport(1)), findsOneWidget);

    await tester.tap(find.text(l10n.tournamentReportSheetParticipants));
    await tester.pump();
    final none = tester.widget<FilledButton>(
      exportButton(l10n.tournamentReportExport(0)),
    );
    expect(none.onPressed, isNull);
  });

  testWidgets('export sends the selection once and locks against double tap', (
    tester,
  ) async {
    final gate = Completer<void>();
    final calls = <Set<TournamentReportSection>>[];
    await _open(tester, (sections) {
      calls.add(sections);
      return gate.future;
    });
    await tester.tap(find.text(l10n.tournamentReportSheetMatches));
    await tester.pump();

    await tester.tap(exportButton(l10n.tournamentReportExport(1)));
    await tester.pump();
    final busy = tester.widget<FilledButton>(
      exportButton(l10n.tournamentReportExporting),
    );
    expect(busy.onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(calls, [
      {TournamentReportSection.participants},
    ]);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a failed export keeps the sheet and the selection for retry', (
    tester,
  ) async {
    var attempts = 0;
    await _open(tester, (_) async {
      attempts++;
      if (attempts == 1) throw Exception('boom');
    });
    await tester.tap(find.text(l10n.tournamentReportSheetMatches));
    await tester.pump();

    await tester.tap(exportButton(l10n.tournamentReportExport(1)));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentReportError), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(exportButton(l10n.tournamentReportExport(1)), findsOneWidget);

    await tester.tap(exportButton(l10n.tournamentReportExport(1)));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(BottomSheet), findsNothing);
  });
}
