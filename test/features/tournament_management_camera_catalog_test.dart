import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_live_status_action.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _cameraId = '550e8400-e29b-41d4-a716-446655440000';

DioException _httpError(int statusCode) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
    ),
  );
}

class _FakeCourtCameraRepository implements ICourtCameraRepository {
  _FakeCourtCameraRepository(this.loadStatus);

  final Future<CameraLiveStatusModel> Function(String cameraId) loadStatus;
  int statusRequests = 0;

  @override
  Future<CameraLiveStatusModel> getCameraLiveStatus(String cameraId) {
    statusRequests++;
    return loadStatus(cameraId);
  }

  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      const <TournamentCameraModel>[];

  @override
  Future<String?> setCourtPlaybackUrl({
    required String tournamentId,
    required String courtId,
    required String playbackUrl,
  }) async => null;

  @override
  Future<void> assignCamera({
    required String matchId,
    required String cameraId,
  }) async {}
}

Future<void> _pumpStatusAction(
  WidgetTester tester,
  _FakeCourtCameraRepository repository, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: ObjectKey(repository),
      overrides: [courtCameraRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: CameraLiveStatusAction(cameraId: _cameraId)),
      ),
    ),
  );
}

void main() {
  testWidgets('camera status loads only on tap and ignores duplicate taps', (
    tester,
  ) async {
    final gate = Completer<CameraLiveStatusModel>();
    final repository = _FakeCourtCameraRepository((_) => gate.future);

    await _pumpStatusAction(tester, repository);
    expect(repository.statusRequests, 0);

    await tester.tap(find.text('Check camera signal'));
    await tester.pump();
    expect(repository.statusRequests, 1);
    expect(find.text('Checking signal…'), findsOneWidget);

    await tester.tap(find.text('Checking signal…'));
    expect(repository.statusRequests, 1);

    gate.complete(
      const CameraLiveStatusModel(
        cameraId: _cameraId,
        online: true,
        status: CameraLiveStatus.live,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Signal detected'), findsOneWidget);
  });

  testWidgets('camera status distinguishes offline from archived', (
    tester,
  ) async {
    final offlineRepository = _FakeCourtCameraRepository(
      (_) async => const CameraLiveStatusModel(
        cameraId: _cameraId,
        online: false,
        status: CameraLiveStatus.idle,
      ),
    );
    await _pumpStatusAction(tester, offlineRepository);
    await tester.tap(find.text('Check camera signal'));
    await tester.pump();
    await tester.pump();
    expect(find.text('No signal detected'), findsOneWidget);

    final archivedRepository = _FakeCourtCameraRepository(
      (_) async => const CameraLiveStatusModel(
        cameraId: _cameraId,
        online: true,
        status: CameraLiveStatus.archived,
      ),
    );
    await _pumpStatusAction(tester, archivedRepository);
    await tester.tap(find.text('Check camera signal'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Camera archived'), findsOneWidget);
    expect(find.text('Signal detected'), findsNothing);
  });
  testWidgets('camera errors are generic and can be retried', (tester) async {
    final repository = _FakeCourtCameraRepository((_) async {
      throw StateError('AQVISION_API_SECRET=do-not-render');
    });

    await _pumpStatusAction(tester, repository);
    await tester.tap(find.text('Check camera signal'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not check camera signal.'), findsOneWidget);
    expect(find.textContaining('AQVISION_API_SECRET'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(repository.statusRequests, 2);
  });
  testWidgets('camera 401 shows session-expired copy without retry', (
    tester,
  ) async {
    final repository = _FakeCourtCameraRepository((_) async {
      throw _httpError(401);
    });
    await _pumpStatusAction(tester, repository, locale: const Locale('vi'));
    await tester.tap(find.text('Kiểm tra tín hiệu camera'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Phiên đăng nhập đã hết hạn hoặc mã truy cập đã được đổi.'),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsNothing);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('camera 403 and 404 are specific; 409 is generic and terminal', (
    tester,
  ) async {
    var deniedRequests = 0;
    final deniedRepository = _FakeCourtCameraRepository((_) async {
      deniedRequests++;
      if (deniedRequests == 1) {
        return const CameraLiveStatusModel(
          cameraId: _cameraId,
          online: true,
          status: CameraLiveStatus.live,
        );
      }
      throw _httpError(403);
    });
    await _pumpStatusAction(
      tester,
      deniedRepository,
      locale: const Locale('vi'),
    );
    await tester.tap(find.text('Kiểm tra tín hiệu camera'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Đã có tín hiệu'), findsOneWidget);
    await tester.tap(find.text('Kiểm tra lại'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Bạn không có quyền xem camera này.'), findsOneWidget);
    expect(find.text('Đã có tín hiệu'), findsNothing);
    expect(find.text('Thử lại'), findsNothing);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    final missingRepository = _FakeCourtCameraRepository((_) async {
      throw _httpError(404);
    });
    await _pumpStatusAction(tester, missingRepository);
    await tester.tap(find.text('Check camera signal'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Camera information is unavailable.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    final conflictRepository = _FakeCourtCameraRepository((_) async {
      throw _httpError(409);
    });
    await _pumpStatusAction(tester, conflictRepository);
    await tester.tap(find.text('Check camera signal'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not check camera signal.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('status action fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cameraRepository = _FakeCourtCameraRepository(
      (_) async => const CameraLiveStatusModel(
        cameraId: _cameraId,
        online: true,
        status: CameraLiveStatus.live,
      ),
    );
    await _pumpStatusAction(tester, cameraRepository, textScale: 1.4);
    await tester.tap(find.text('Check camera signal'));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Vietnamese status labels are localized', (tester) async {
    final statusRepository = _FakeCourtCameraRepository(
      (_) async => const CameraLiveStatusModel(
        cameraId: _cameraId,
        online: true,
        status: CameraLiveStatus.live,
      ),
    );
    await _pumpStatusAction(
      tester,
      statusRepository,
      locale: const Locale('vi'),
    );
    expect(find.text('Kiểm tra tín hiệu camera'), findsOneWidget);
  });
  testWidgets('camera status is announced as a live region', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final repository = _FakeCourtCameraRepository(
        (_) async => const CameraLiveStatusModel(
          cameraId: _cameraId,
          online: false,
          status: CameraLiveStatus.idle,
        ),
      );

      await _pumpStatusAction(tester, repository);
      await tester.tap(find.text('Check camera signal'));
      await tester.pump();
      await tester.pump();

      final status = tester.getSemantics(find.text('No signal detected'));
      expect(status.label, 'No signal detected');
      expect(status.flagsCollection.isLiveRegion, isTrue);
    } finally {
      semantics.dispose();
    }
  });
}
