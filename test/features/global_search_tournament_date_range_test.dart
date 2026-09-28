// import 'package:app_quanly_giaidau/core/config/app_theme.dart';
// import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
// import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
// import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
// import 'package:app_quanly_giaidau/features/home/widgets/global_search_screen.dart';
// import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
// import 'package:app_quanly_giaidau/providers/category_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// void main() {
//   testWidgets(
//     'tournament date filter forwards the selected end date',
//     (tester) async {
//       tester.view.physicalSize = const Size(390, 844);
//       tester.view.devicePixelRatio = 1;
//       addTearDown(tester.view.resetPhysicalSize);
//       addTearDown(tester.view.resetDevicePixelRatio);
//
//       final repository = _RecordingTournamentRepository();
//       await tester.pumpWidget(
//         ProviderScope(
//           overrides: [
//             tournamentRepositoryProvider.overrideWith((ref) => repository),
//             categoriesProvider.overrideWith((ref) async => const []),
//           ],
//           child: MaterialApp(
//             theme: AppTheme.darkTheme,
//             locale: const Locale('en'),
//             localizationsDelegates: AppLocalizations.localizationsDelegates,
//             supportedLocales: AppLocalizations.supportedLocales,
//             home: const GlobalSearchScreen(
//               initialTabIndex: 1,
//               initialQuery: '',
//               showFiltersInitially: true,
//             ),
//           ),
//         ),
//       );
//       await tester.pumpAndSettle();
//
//       await tester.tap(find.byIcon(Icons.calendar_month_rounded));
//       await tester.pumpAndSettle();
//
//       final localizations = MaterialLocalizations.of(
//         tester.element(find.byType(GlobalSearchScreen)),
//       );
//       final start = DateUtils.dateOnly(DateTime.now());
//       final end = start.add(const Duration(days: 1));
//       await tester.tap(
//         find.bySemanticsLabel(
//           RegExp(
//             '${start.day}, ${RegExp.escape(localizations.formatFullDate(start))}',
//           ),
//         ),
//       );
//       await tester.pumpAndSettle();
//       if (end.month != start.month || end.year != start.year) {
//         await tester.tap(find.byTooltip(localizations.nextMonthTooltip));
//         await tester.pumpAndSettle();
//       }
//       await tester.tap(
//         find.bySemanticsLabel(
//           RegExp(
//             '${end.day}, ${RegExp.escape(localizations.formatFullDate(end))}',
//           ),
//         ),
//       );
//       await tester.pumpAndSettle();
//       final datePicker = find.byType(DateRangePickerDialog);
//       if (datePicker.evaluate().isNotEmpty) {
//         final actions = find.descendant(
//           of: datePicker,
//           matching: find.byType(TextButton),
//         );
//         await tester.ensureVisible(actions.last);
//         await tester.tap(actions.last);
//         await tester.pumpAndSettle();
//       }
//       await tester.pumpAndSettle();
//
//       final l10n = AppLocalizations.of(
//         tester.element(find.byType(GlobalSearchScreen)),
//       )!;
//       await tester.tap(find.text(l10n.filterApply));
//       await tester.pumpAndSettle();
//
//       expect(repository.lastEndDate, DateUtils.dateOnly(end));
//     },
//   );
// }
//
// class _RecordingTournamentRepository implements ITournamentRepository {
//   DateTime? lastEndDate;
//
//   @override
//   Future<({List<Tournament> tournaments, String? nextCursor, bool hasMore})>
//   getPublicTournamentsPaged({
//     String? cursor,
//     int limit = 6,
//     String? sport,
//     String? status,
//     String? search,
//     String? content,
//     String? bracket,
//     String? ranked,
//     String? province,
//     String? ward,
//     DateTime? startDate,
//     DateTime? endDate,
//     bool rethrowOnError = false,
//   }) async {
//     lastEndDate = endDate;
//     return (tournaments: const <Tournament>[], nextCursor: null, hasMore: false);
//   }
//
//   @override
//   dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
// }
