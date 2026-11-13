import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_match_filter.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_tab_header.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMHEAD-APP-01.. / TC-CAMPILL-APP-01..: hàng đầu tab Camera chỉ icon,
/// bấm tìm thì viên thuốc thay chính hàng đó, phễu lọc nằm trong viên.
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
  int streams = 0;
}

Widget _app(Widget body, {bool disableAnimations = false}) => MaterialApp(
  theme: AppTheme.lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: Scaffold(
    body: Align(alignment: Alignment.topCenter, child: body),
  ),
);

/// Bảng A có 2 lượt, rồi tới playoff: đúng kiểu nhãn thật của app.
const _stages = <CameraStage>[
  (label: 'Bảng A • Lượt 1', count: 2),
  (label: 'Bảng A • Lượt 2', count: 1),
  (label: 'Playoff • Tứ kết', count: 1),
];

void _setWidth(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<_Harness> _pump(
  WidgetTester tester, {
  List<TournamentCameraModel>? cameras,
  bool canCreate = true,
  bool canStream = false,
  CameraMatchFilter filter = const CameraMatchFilter(),
  bool disableAnimations = false,
  List<CameraStage> stages = _stages,
}) async {
  _setWidth(tester, 390);
  final h = _Harness()..filter = filter;
  await tester.pumpWidget(
    _app(
      StatefulBuilder(
        builder: (context, setState) => CameraTabHeader(
          cameras: cameras ?? [_camera(1), _camera(2, status: 'IDLE')],
          filter: h.filter,
          stages: stages,
          onFilterChanged: (value) => setState(() => h.filter = value),
          onRefresh: () => h.refreshes++,
          onWatchCameras: () => h.watches++,
          onCreateCamera: canCreate ? () => h.creates++ : null,
          onOpenStreaming: canStream ? () => h.streams++ : null,
        ),
      ),
      disableAnimations: disableAnimations,
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Tìm trận'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Lọc trận'));
  await tester.pumpAndSettle();
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
      'Tạo camera',
      'Xem camera',
      'Thêm tuỳ chọn',
    ]) {
      expect(find.byTooltip(tip), findsOneWidget, reason: tip);
    }
    // Phễu lọc nằm trong viên thuốc tìm kiếm, không ở hàng đầu.
    expect(find.byTooltip('Lọc trận'), findsNothing);
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
    for (final tip in ['Tìm trận', 'Tạo camera', 'Xem camera']) {
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
      _app(
        CameraTabHeader(
          cameras: null,
          filter: const CameraMatchFilter(),
          stages: const [],
          onFilterChanged: (_) {},
          onRefresh: () {},
          onWatchCameras: () {},
        ),
      ),
    );
    expect(find.textContaining('cam ·'), findsNothing);
    expect(find.byTooltip('Xem camera'), findsNothing);
  });

  testWidgets('TC-CAMHEAD-APP-07 search icon swaps the row for the pill', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    // Viên thuốc thay chính hàng đầu: tiêu đề và icon thu lại.
    expect(find.text('Camera của giải'), findsNothing);
    expect(find.byTooltip('Tạo camera'), findsNothing);
    expect(tester.getSize(find.byType(CameraTabHeader)).height, lessThan(64));

    await tester.tap(find.byTooltip('Đóng tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Camera của giải'), findsOneWidget);
  });

  testWidgets('TC-CAMHEAD-APP-08 typing reports the query, closing clears it', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nguyen');
    await tester.pump();
    expect(h.filter.query, 'Nguyen');

    await tester.tap(find.byTooltip('Đóng tìm kiếm'));
    await tester.pumpAndSettle();
    expect(h.filter.query, isEmpty);
  });

  testWidgets('TC-CAMHEAD-APP-09 filter icon sits inside the pill, no chips', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('camTabPill')),
        matching: find.byTooltip('Lọc trận'),
      ),
      findsOneWidget,
    );
    // Không có dải chip chặng bung sẵn.
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.text('Bảng A • Lượt 1'), findsNothing);
  });

  testWidgets('TC-CAMHEAD-APP-10 filter dot and tags appear only when active', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('camTabFilterDot')), findsNothing);
    expect(find.byKey(const ValueKey('camTabTagStage')), findsNothing);

    await _pump(
      tester,
      filter: const CameraMatchFilter(
        stage: 'Bảng A • Lượt 1',
        onlyNoCamera: true,
      ),
    );
    expect(find.byKey(const ValueKey('camTabTagStage')), findsOneWidget);
    expect(find.byKey(const ValueKey('camTabTagNoCamera')), findsOneWidget);
    expect(find.text('Bảng A • Lượt 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pumpAndSettle();
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

  testWidgets('TC-CAMMERGE-03 menu opens phones & live sessions', (
    tester,
  ) async {
    final h = await _pump(tester, canStream: true);
    await tester.tap(find.byTooltip('Thêm tuỳ chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Điện thoại & phiên phát'));
    await tester.pumpAndSettle();
    expect(h.streams, 1);
  });

  testWidgets('TC-CAMMERGE-04 no streaming callback, no menu item', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Thêm tuỳ chọn'));
    await tester.pumpAndSettle();
    expect(find.text('Điện thoại & phiên phát'), findsNothing);
  });

  testWidgets('TC-CAMHEAD-APP-12 reduced motion swaps without animating', (
    tester,
  ) async {
    await _pump(tester, disableAnimations: true);
    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng tìm kiếm'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Camera của giải'), findsOneWidget);
  });

  testWidgets('TC-CAMPILL-APP-01 sheet: stages, no-camera switch, 2 buttons', (
    tester,
  ) async {
    await _pump(tester);
    await _openSheet(tester);
    expect(find.text('Tất cả bảng / vòng'), findsOneWidget);
    // Mỗi chặng kèm số trận.
    expect(find.text('Bảng A • Lượt 1'), findsOneWidget);
    expect(find.text('Bảng A • Lượt 2'), findsOneWidget);
    expect(find.text('Playoff • Tứ kết'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Chưa có cam'), findsOneWidget);
    expect(find.text('Xoá lọc'), findsOneWidget);
    expect(find.text('Áp dụng'), findsOneWidget);
  });

  testWidgets('TC-CAMPILL-APP-02 Áp dụng reports stage and no-camera flag', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _openSheet(tester);
    await tester.tap(find.text('Bảng A • Lượt 2'));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    // Chưa bấm Áp dụng thì chưa đổi.
    expect(h.filter.stage, isNull);
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(h.filter.stage, 'Bảng A • Lượt 2');
    expect(h.filter.onlyNoCamera, isTrue);
    expect(find.byKey(const ValueKey('camTabFilterDot')), findsOneWidget);
  });

  testWidgets('TC-CAMPILL-APP-03 dismissing the sheet keeps the filter', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      filter: const CameraMatchFilter(stage: 'Bảng A • Lượt 1'),
    );
    await _openSheet(tester);
    await tester.tap(find.text('Bảng A • Lượt 2'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // barrier
    await tester.pumpAndSettle();
    expect(find.text('Áp dụng'), findsNothing);
    expect(h.filter.stage, 'Bảng A • Lượt 1');
  });

  testWidgets('TC-CAMPILL-APP-04 Xoá lọc in the sheet clears both filters', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      filter: const CameraMatchFilter(
        stage: 'Bảng A • Lượt 2',
        onlyNoCamera: true,
      ),
    );
    await _openSheet(tester);
    await tester.tap(find.text('Xoá lọc'));
    await tester.pumpAndSettle();
    expect(h.filter.stage, isNull);
    expect(h.filter.onlyNoCamera, isFalse);
  });

  testWidgets('TC-CAMPILL-APP-05 tags: tapping x removes exactly that filter', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      filter: const CameraMatchFilter(
        stage: 'Bảng A • Lượt 2',
        onlyNoCamera: true,
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('camTabTagStage')),
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(h.filter.stage, isNull);
    expect(h.filter.onlyNoCamera, isTrue);
    expect(find.byKey(const ValueKey('camTabTagStage')), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('camTabTagNoCamera')),
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(h.filter.onlyNoCamera, isFalse);
    expect(find.byKey(const ValueKey('camTabTagNoCamera')), findsNothing);
  });

  testWidgets('TC-CAMPILL-APP-06 closing the pill keeps stage/no-camera', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      filter: const CameraMatchFilter(stage: 'Bảng A • Lượt 2'),
    );
    await tester.tap(find.byTooltip('Tìm trận'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    await tester.tap(find.byTooltip('Đóng tìm kiếm'));
    await tester.pumpAndSettle();
    expect(h.filter.query, isEmpty);
    expect(h.filter.stage, 'Bảng A • Lượt 2');
    expect(find.byKey(const ValueKey('camTabTagStage')), findsOneWidget);
  });

  testWidgets(
    'TC-CAMPILL-APP-07 12 stages: header stays one row, list scrolls',
    (tester) async {
      _setWidth(tester, 320);
      await tester.pumpWidget(
        _app(
          CameraTabHeader(
            cameras: [_camera(1)],
            filter: const CameraMatchFilter(),
            stages: [
              for (var i = 1; i <= 12; i++)
                (label: 'Bảng $i • Lượt 1', count: 1),
            ],
            onFilterChanged: (_) {},
            onRefresh: () {},
            onWatchCameras: () {},
            onCreateCamera: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final closedHeight = tester.getSize(find.byType(CameraTabHeader)).height;

      await _openSheet(tester);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(CameraTabHeader)).height,
        lessThanOrEqualTo(closedHeight),
      );
      await tester.scrollUntilVisible(
        find.text('Bảng 12 • Lượt 1'),
        60,
        scrollable: find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Bảng 12 • Lượt 1'), findsOneWidget);
    },
  );

  testWidgets('TC-CAMPILL-APP-08 header never overflows at 320dp and 360dp', (
    tester,
  ) async {
    for (final width in [320.0, 360.0]) {
      _setWidth(tester, width);
      await tester.pumpWidget(
        _app(
          CameraTabHeader(
            key: ValueKey(width), // fresh state per width
            cameras: [_camera(1)],
            filter: const CameraMatchFilter(
              stage: 'Bảng A • Lượt 1',
              onlyNoCamera: true,
            ),
            stages: _stages,
            onFilterChanged: (_) {},
            onRefresh: () {},
            onWatchCameras: () {},
            onCreateCamera: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'closed @$width');
      await tester.tap(find.byTooltip('Tìm trận'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'pill @$width');
    }
  });
}
