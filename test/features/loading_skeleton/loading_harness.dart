import 'dart:async';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Adapter whose requests never finish: the screen stays in its loading state.
class _PendingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => Completer<ResponseBody>().future;

  @override
  void close({bool force = false}) {}
}

class _PendingDioClient extends Fake implements DioClient {
  @override
  final Dio dio = Dio()..httpClientAdapter = _PendingAdapter();
}

/// Override that makes every `dioClientProvider`/`dioProvider` request hang.
final pendingDioOverride = dioClientProvider.overrideWithValue(
  _PendingDioClient(),
);

/// Pumps [home] in a themed MaterialApp at [size] without settling (skeletons
/// animate forever, so `pumpAndSettle` would hang).
Future<void> pumpLoading(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps [skeleton] at the three reference sizes and expects no layout error.
Future<void> expectNoOverflowAtAllSizes(
  WidgetTester tester,
  Widget skeleton,
) async {
  for (final size in const [Size(360, 640), Size(412, 915), Size(820, 1180)]) {
    await pumpLoading(tester, Scaffold(body: skeleton), size: size);
    expect(tester.takeException(), isNull, reason: 'overflow at $size');
  }
}
