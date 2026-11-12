import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_status_badge.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAM-SYNC-14..17: badge trạng thái camera đủ 6 trạng thái như Web.
Future<void> _pump(
  WidgetTester tester,
  String status, {
  Locale locale = const Locale('vi'),
  double width = 360,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: SizedBox(width: width, child: CameraStatusBadge(status: status)),
      ),
    ),
  );
}

void main() {
  testWidgets('TC-CAM-SYNC-14 mỗi trạng thái có chữ riêng và một chấm màu', (
    tester,
  ) async {
    const expected = <String, String>{
      'IDLE': 'Sẵn sàng',
      'ASSIGNED': 'Đã gán',
      'WAITING': 'Chờ tín hiệu',
      'LIVE': 'Đang live',
      'OFFLINE': 'Offline',
      'ERROR': 'Lỗi',
    };
    for (final entry in expected.entries) {
      await _pump(tester, entry.key);
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(find.byKey(const ValueKey('camera-status-dot')), findsOneWidget);
    }
  });

  testWidgets('TC-CAM-SYNC-15 trạng thái lạ hoặc rỗng hiện "Không rõ"', (
    tester,
  ) async {
    for (final status in ['FOO', '', 'live']) {
      await _pump(tester, status);
      expect(find.text('Không rõ'), findsOneWidget, reason: status);
    }
  });

  testWidgets('TC-CAM-SYNC-16 trạng thái được đọc bằng chữ cho trình đọc màn hình', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, 'OFFLINE', locale: const Locale('en'));
    expect(
      find.bySemanticsLabel('Camera status: Offline'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('TC-CAM-SYNC-17 chữ dài ở 360px và cỡ chữ lớn không tràn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: SizedBox(width: 120, child: CameraStatusBadge(status: 'WAITING')),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
