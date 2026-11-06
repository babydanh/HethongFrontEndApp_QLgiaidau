import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/violation_report.dart';
import 'package:app_quanly_giaidau/domain/repositories/report_repository.dart';
import 'package:app_quanly_giaidau/features/reports/screens/my_reports_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements IReportRepository {
  _FakeRepo(this.handler);
  final Future<ViolationReportPage> Function() handler;
  int calls = 0;
  @override
  Future<ViolationReportPage> getMine({String? cursor, int limit = 10}) {
    calls++;
    return handler();
  }
}

ViolationReport _report(String id, ReportStatus status) => ViolationReport(
  id: id,
  targetType: ReportTargetType.user,
  targetId: id,
  category: ReportCategory.cheating,
  reason: 'Lý do $id',
  evidenceUrls: const [],
  status: status,
  createdAt: DateTime(2026, 1, 2, 3, 4),
);

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [reportRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: theme ?? AppTheme.darkTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MyReportsScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('hien skeleton khi dang tai', (tester) async {
    final repo = _FakeRepo(() => Future.any(<Future<ViolationReportPage>>[]));
    await _pump(tester, repo);
    await tester.pump();
    expect(find.byType(LavishScaffold), findsOneWidget);
    expect(find.byType(LavishRowSkeleton), findsOneWidget);
  });

  testWidgets('hien danh sach LavishRow va pill theo trang thai', (
    tester,
  ) async {
    final repo = _FakeRepo(
      () async => ViolationReportPage(
        items: [
          _report('a', ReportStatus.submitted),
          _report('b', ReportStatus.resolved),
          _report('c', ReportStatus.rejected),
        ],
        nextCursor: null,
        totalPages: 1,
      ),
    );
    await _pump(tester, repo, theme: AppTheme.lightTheme);
    await tester.pump();
    await tester.pump();
    expect(find.byType(LavishRow), findsNWidgets(3));
    expect(find.text('Lý do a'), findsOneWidget);
    final pills = tester
        .widgetList<LavishPill>(find.byType(LavishPill))
        .toList();
    expect(pills.map((p) => p.tone), [
      LavishTone.warn,
      LavishTone.ok,
      LavishTone.bad,
    ]);
  });

  testWidgets('hien trang thai rong', (tester) async {
    final repo = _FakeRepo(
      () async => const ViolationReportPage(
        items: [],
        nextCursor: null,
        totalPages: 1,
      ),
    );
    await _pump(tester, repo);
    await tester.pump();
    await tester.pump();
    expect(find.byType(LavishEmptyState), findsOneWidget);
    expect(find.byType(LavishErrorState), findsNothing);
  });

  testWidgets('loi hien LavishErrorState, khong lo exception, thu lai', (
    tester,
  ) async {
    var fail = true;
    final repo = _FakeRepo(() async {
      if (fail) throw Exception('boom-secret-detail');
      return const ViolationReportPage(
        items: [],
        nextCursor: null,
        totalPages: 1,
      );
    });
    await _pump(tester, repo);
    await tester.pump();
    await tester.pump();
    expect(find.byType(LavishErrorState), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('boom-secret-detail'), findsNothing);
    fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LavishEmptyState), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets('nut refresh tren AppBar co tooltip', (tester) async {
    final repo = _FakeRepo(
      () async => const ViolationReportPage(
        items: [],
        nextCursor: null,
        totalPages: 1,
      ),
    );
    await _pump(tester, repo);
    await tester.pump();
    expect(find.byTooltip('Làm mới báo cáo'), findsOneWidget);
  });
}
