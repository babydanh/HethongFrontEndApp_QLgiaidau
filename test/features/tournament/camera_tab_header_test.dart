import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_match_filter.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_tab_header.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMHEAD-APP-01..: hàng đầu tab Camera chỉ icon, dải tìm/lọc bung co.
TournamentCameraModel _camera(int n, {String status = 'LIVE'}) =>
    TournamentCameraModel(
      id: 'cam-$n',
      name: 'Camera $n',
      mode: 'PULL',
      status: status,
      courtId: 'court-1',
      playbackUrl: 'https://p.example/$n.m3u8',
    );

class _Harness {
  CameraMatchFilter filter = const CameraMatchFilter();
  int refreshes = 0;
  int watches = 0;
  int creates = 0;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  List<TournamentCameraModel>? cameras,
  bool canCreate = true,
  CameraMatchFilter filter = const CameraMatchFilter(),
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = const Size(390, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = _Harness()..filter = filter;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: StatefulBuilder(
            builder: (context, setState) => CameraTabHeader(
              cameras: cameras ?? [_camera(1), _camera(2, status: 'IDLE')],
              filter: h.filter,
              rounds: const [1, 2],
              onFilterChanged: (value) => setState(() => h.filter = value),
              onRefresh: () => h.refreshes++,
              onWatchCameras: () => h.watches++,
              onCreateCamera: canCreate ? () => h.creates++ : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('TC-CAMHEAD-APP-01 one row with title, short summary and icons', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Camera của giải'), findsOneWidget);
    expect(find.text('2 cam · 1 LIVE'), findsOneWidget);
    for (final tip in [
      'Tìm trận',
      'Lọc trận',
      'Tạo camera',
      'Xem camera',
      'Thêm tuỳ chọn',
    ]) {
      expect(find.byTooltip(tip), findsOneWidget, reason: tip);
    }
    // Không còn nút chữ "Xem camera", nút "?" hay nút làm mới rời.
    expect(find.widgetWithText(FilledButton, 'Xem camera'), findsNothing);
    expect(find.byTooltip('Hướng dẫn tab Camera'), findsNothing);
    expect(find.byTooltip('Làm mới'), findsNothing);
    expect(tester.getSize(find.byType(CameraTabHeader)).height, lessThan(64));
  });

  testWidgets('TC-CAMHEAD-APP-02 every icon has a 48dp touch target', (
    tester,
  ) async {
    await _pump(tester);
    for (final tip in ['Tìm trận', 'Lọc trận', 'Tạo camera', 'Xem camera']) {
      final size = tester.getSize(find.byTooltip(tip));
      expect(size.width, greaterThanOrEqualTo(48), reason: tip);
      expect(size.height, greaterThanOrEqualTo(48), reason: tip);
    }
  });

  testWidgets('TC-CAMHEAD-APP-03 hides Tạo camera when not allowed', (
    tester,
  ) async {
    await _pump(tester, canCreate: false);
    expect(find.byTooltip('Tạo camera'), findsNothing);
  });

  testWidgets('TC-CAMHEAD-APP-04 Tạo camera and Xem camera call back', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.byTooltip('Tạo camera'));
    await tester.tap(find.byTooltip('Xem camera'));
    expect(h.creates, 1);
    expect(h.watches, 1);
  });

  testWidgets('TC-CAMHEAD-APP-05 hides Xem camera when there is no camera', (
    tester,
  ) async {
    await _pump(tester, cameras: const []);
    expect(find.byTooltip('Xem camera'), findsNothing);
    expect(find.byTooltip('Tạo camera'), findsOneWidget);
  });

  testWidgets('TC-CAMHEAD-APP-06 no count is printed while cameras load', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: CameraTabHeader(
            cameras: null,
            filter: const CameraMatchFilter(),
            rounds: const [],
            onFilterChanged: (_) {},
            onRefresh: () {},
            onWatchCameras: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('cam ·'), findsNothing);
    expect(find.byTooltip('Xem camera'), findsNothing);
  });

  testWidgets('TC-CAMHEAD-APP-07 search icon opens and closes the strip', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tất cả vòng'), findsNothing);

    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('TC-CAMHEAD-APP-08 typing reports the query', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nguyen');
    expect(h.filter.query, 'Nguyen');
  });

  testWidgets('TC-CAMHEAD-APP-09 filter icon shows rounds and no-camera chip', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.byTooltip('Lọc trận'));
    await tester.pumpAndSettle();
    expect(find.text('Tất cả vòng'), findsOneWidget);
    expect(find.text('Vòng 1'), findsOneWidget);
    expect(find.text('Vòng 2'), findsOneWidget);
    expect(find.text('Chưa có cam'), findsOneWidget);

    await tester.tap(find.text('Vòng 2'));
    await tester.pumpAndSettle();
    expect(h.filter.round, 2);
    await tester.tap(find.text('Tất cả vòng'));
    await tester.pumpAndSettle();
    expect(h.filter.round, isNull);
    await tester.tap(find.text('Chưa có cam'));
    await tester.pumpAndSettle();
    expect(h.filter.onlyNoCamera, isTrue);
  });

  testWidgets('TC-CAMHEAD-APP-10 dots appear only for the active filters', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('camTabSearchDot')), findsNothing);
    expect(find.byKey(const ValueKey('camTabFilterDot')), findsNothing);

    await _pump(
      tester,
      filter: const CameraMatchFilter(query: 'a', onlyNoCamera: true),
    );
    expect(find.byKey(const ValueKey('camTabSearchDot')), findsOneWidget);
    expect(find.byKey(const ValueKey('camTabFilterDot')), findsOneWidget);

    await _pump(tester, filter: const CameraMatchFilter(round: 1));
    expect(find.byKey(const ValueKey('camTabSearchDot')), findsNothing);
    expect(find.byKey(const ValueKey('camTabFilterDot')), findsOneWidget);
  });

  testWidgets('TC-CAMHEAD-APP-11 menu holds Làm mới and Hướng dẫn', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.byTooltip('Thêm tuỳ chọn'));
    await tester.pumpAndSettle();
    expect(find.text('Hướng dẫn'), findsOneWidget);
    await tester.tap(find.text('Làm mới'));
    await tester.pumpAndSettle();
    expect(h.refreshes, 1);
  });

  testWidgets('TC-CAMHEAD-APP-12 reduced motion collapses without animating', (
    tester,
  ) async {
    await _pump(tester, disableAnimations: true);
    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
  });
}
