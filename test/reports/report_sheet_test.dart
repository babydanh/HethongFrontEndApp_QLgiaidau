import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/shared/widgets/report_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      201,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeDioClient extends Fake implements DioClient {
  _FakeDioClient(this.dio);
  @override
  final Dio dio;
}

const _uuid = '11111111-1111-4111-8111-111111111111';

Future<_CaptureAdapter> _open(
  WidgetTester tester, {
  required String targetType,
}) async {
  final adapter = _CaptureAdapter();
  final dio = Dio()..httpClientAdapter = adapter;
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dioClientProvider.overrideWithValue(_FakeDioClient(dio))],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportSheet(targetId: _uuid, targetType: targetType),
          ),
        ),
      ),
    ),
  );
  return adapter;
}

void main() {
  testWidgets('gui POST /users/reports voi targetType COMMUNITY', (
    tester,
  ) async {
    final adapter = await _open(tester, targetType: 'community');
    await tester.tap(find.text('Gian lận'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 50));
    expect(adapter.requests, hasLength(1));
    final r = adapter.requests.single;
    expect(r.path, '/users/reports');
    final body = r.data as Map;
    expect(body['targetType'], 'COMMUNITY');
    expect(body['targetId'], _uuid);
    expect(body['category'], 'CHEATING');
    expect((body['reason'] as String).length, greaterThanOrEqualTo(10));
  });

  testWidgets('community_post cu duoc anh xa ve COMMUNITY', (tester) async {
    final adapter = await _open(tester, targetType: 'community_post');
    await tester.tap(find.text('Gian lận'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 50));
    expect((adapter.requests.single.data as Map)['targetType'], 'COMMUNITY');
  });

  testWidgets('mo ta tu nhap duoi 10 ky tu khong duoc gui', (tester) async {
    final adapter = await _open(tester, targetType: 'match');
    await tester.tap(find.text('Gian lận'));
    await tester.enterText(find.byType(TextField), 'ngắn');
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(adapter.requests, isEmpty);
    await tester.enterText(find.byType(TextField), 'mô tả đủ dài rồi');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 50));
    final body = adapter.requests.single.data as Map;
    expect(body['targetType'], 'MATCH');
    expect(body['reason'], 'mô tả đủ dài rồi');
  });
}
