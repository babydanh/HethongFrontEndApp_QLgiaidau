import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_create_flow.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/facebook_live_ready_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-FBONE-APP-02..06: one tap creates the Facebook live and the camera.
const _server = 'rtmps://live-api-s.facebook.com:443/rtmp';
const _key = 'FB-SECRET-KEY';
const _live = CreatedFacebookLive(
  providerSessionId: '1234567890123456',
  watchUrl: 'https://www.facebook.com/watch/?v=1234567890123456',
  rtmpUrl: _server,
  streamKey: _key,
);
const _court = TournamentCourtRef(
  id: 'court-1',
  name: 'Sân 1',
  venueName: 'NTĐ',
);

class _LiveRepo implements IFacebookCameraLiveRepository {
  int createCalls = 0;
  Completer<CreatedFacebookLive>? gate;
  Object? createError;

  @override
  Future<FacebookLiveConnection> getConnection(String tournamentId) async =>
      const FacebookLiveConnection(
        communityId: 'c1',
        connected: true,
        pageName: 'CLB Pickle',
      );

  @override
  Future<CreatedFacebookLive> createLive(String tournamentId) {
    createCalls++;
    final error = createError;
    if (error != null) return Future.error(error);
    return gate?.future ?? Future.value(_live);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Admin implements ICameraAdminRepository {
  final created = <Map<String, Object?>>[];
  Object? error;

  @override
  Future<TournamentCameraModel> createCamera({
    required String tournamentId,
    required String name,
    required String mode,
    String? courtId,
    String? playbackUrl,
  }) async {
    created.add({
      'name': name,
      'mode': mode,
      'courtId': courtId,
      'playbackUrl': playbackUrl,
    });
    final failure = error;
    if (failure != null) throw failure;
    return TournamentCameraModel(
      id: 'cam-1',
      name: name,
      mode: mode,
      status: 'IDLE',
      courtId: courtId,
      playbackUrl: playbackUrl,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DioException _dioError(int status, Object data) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: data,
  ),
);

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: home),
);

/// Opens the whole "Thêm camera" flow on the live tab, like the real screen.
Future<void> _openFlow(
  WidgetTester tester,
  _LiveRepo live,
  _Admin admin, {
  Future<void> Function()? refresh,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        facebookCameraLiveRepositoryProvider.overrideWithValue(live),
        cameraAdminRepositoryProvider.overrideWithValue(admin),
      ],
      child: _app(
        Consumer(
          builder: (context, ref, _) => ElevatedButton(
            onPressed: () => runCreateCameraFlow(
              context: context,
              ref: ref,
              tournamentId: 't1',
              courts: const [_court],
              refresh: refresh ?? () async {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('camera-source-live')));
  await tester.pumpAndSettle();
}

final _create = find.byKey(const ValueKey('fb-live-create'));
final _editorSubmit = find.byKey(const ValueKey('camera-editor-submit'));

Future<void> _tapCreate(WidgetTester tester) async {
  await tester.ensureVisible(_create);
  await tester.tap(_create);
}

EditableText _field(WidgetTester tester, String key) =>
    tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      ),
    );

void main() {
  testWidgets('TC-FBONE-APP-02 empty name: one live, one PULL camera, ready '
      'sheet', (tester) async {
    final live = _LiveRepo();
    final admin = _Admin();
    await _openFlow(tester, live, admin);
    final court = find.byKey(const ValueKey('camera-editor-court'));
    await tester.ensureVisible(court);
    await tester.tap(court);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sân 1').last);
    await tester.pumpAndSettle();

    await _tapCreate(tester);
    await tester.pumpAndSettle();

    expect(live.createCalls, 1);
    expect(admin.created, hasLength(1));
    final camera = admin.created.single;
    expect(camera['mode'], 'PULL');
    expect(camera['playbackUrl'], _live.watchUrl);
    expect(camera['courtId'], 'court-1');
    expect(camera['name'], matches(RegExp(r'^Live Facebook \d{2}:\d{2}$')));
    expect(_editorSubmit, findsNothing);
    expect(find.text('Camera is ready'), findsOneWidget);
    expect(_field(tester, 'fb-live-rtmp').controller.text, _server);
    expect(_field(tester, 'fb-live-key').obscureText, isTrue);
  });

  testWidgets('TC-FBONE-APP-02b a typed name is kept', (tester) async {
    final admin = _Admin();
    await _openFlow(tester, _LiveRepo(), admin);
    await tester.enterText(
      find.byKey(const ValueKey('camera-editor-name')),
      'Camera sân chính',
    );
    await _tapCreate(tester);
    await tester.pumpAndSettle();
    expect(admin.created.single['name'], 'Camera sân chính');
  });

  testWidgets('TC-FBONE-APP-03 double tap creates only one camera', (
    tester,
  ) async {
    final live = _LiveRepo()..gate = Completer();
    final admin = _Admin();
    await _openFlow(tester, live, admin);
    await _tapCreate(tester);
    await tester.pump();
    await tester.tap(_create, warnIfMissed: false);
    await tester.pump();
    live.gate!.complete(_live);
    await tester.pumpAndSettle();
    expect(live.createCalls, 1);
    expect(admin.created, hasLength(1));
  });

  testWidgets('TC-FBONE-APP-04 createCamera fails: sheet stays open with the '
      'error, retry creates the camera', (tester) async {
    final live = _LiveRepo();
    final admin = _Admin()..error = _dioError(500, {'message': 'Camera down'});
    await _openFlow(tester, live, admin);
    await _tapCreate(tester);
    await tester.pumpAndSettle();

    expect(_editorSubmit, findsOneWidget);
    expect(find.text('Camera down'), findsOneWidget);
    expect(find.text('Camera is ready'), findsNothing);
    expect(tester.widget<FilledButton>(_create).onPressed, isNotNull);

    admin.error = null;
    await _tapCreate(tester);
    await tester.pumpAndSettle();
    expect(live.createCalls, 2);
    expect(admin.created, hasLength(2));
    expect(find.text('Camera is ready'), findsOneWidget);
  });

  testWidgets('TC-FBONE-APP-05 ready sheet masks the key and shows the RTMP QR', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => FacebookLiveReadySheet.show(
              context,
              live: _live,
              cameraName: 'Camera sân 1',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Camera is ready'), findsOneWidget);
    expect(find.text('Camera sân 1'), findsOneWidget);
    // The QR code is visible right away; the toggle only hides it.
    expect(find.byKey(const ValueKey('fb-live-qr')), findsOneWidget);
    expect(find.textContaining('QR code contains the stream key'), findsOneWidget);
    final qrToggle = find.byKey(const ValueKey('fb-live-qr-toggle'));
    await tester.ensureVisible(qrToggle);
    await tester.tap(qrToggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fb-live-qr')), findsNothing);
    expect(_field(tester, 'fb-live-key').obscureText, isTrue);

    final done = find.byKey(const ValueKey('fb-live-ready-done'));
    await tester.ensureVisible(done);
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.text('Camera is ready'), findsNothing);
  });

  testWidgets('TC-FBONE-APP-07 while the live is being created Save, Cancel and '
      'close are disabled', (tester) async {
    final live = _LiveRepo()..gate = Completer();
    final admin = _Admin();
    await _openFlow(tester, live, admin);
    await _tapCreate(tester);
    await tester.pump();

    expect(tester.widget<FilledButton>(_editorSubmit).onPressed, isNull);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Cancel'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('tournament-manage-sheet-close')),
          )
          .onPressed,
      isNull,
    );

    live.gate!.complete(_live);
    await tester.pumpAndSettle();
    expect(admin.created, hasLength(1));
    expect(find.text('Camera is ready'), findsOneWidget);
  });

  testWidgets('TC-FBONE-APP-08 invalid typed name: no live is created, name '
      'error shown', (tester) async {
    final live = _LiveRepo();
    final admin = _Admin();
    await _openFlow(tester, live, admin);
    await tester.enterText(find.byKey(const ValueKey('camera-editor-name')), 'A');
    await _tapCreate(tester);
    await tester.pumpAndSettle();
    expect(live.createCalls, 0);
    expect(admin.created, isEmpty);
    final message = lookupAppLocalizations(
      const Locale('en'),
    ).tournamentCameraNameInvalid(2, 255);
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('TC-FBONE-APP-09 refresh fails after the camera exists: sheet '
      'closes, one camera, ready sheet opens', (tester) async {
    final live = _LiveRepo();
    final admin = _Admin();
    await _openFlow(
      tester,
      live,
      admin,
      refresh: () async => throw StateError('refresh down'),
    );
    await _tapCreate(tester);
    await tester.pumpAndSettle();
    expect(admin.created, hasLength(1));
    expect(live.createCalls, 1);
    expect(_editorSubmit, findsNothing);
    expect(find.text('Camera is ready'), findsOneWidget);
  });

  testWidgets('TC-FBONE-APP-06 page not eligible: message shown, no camera', (
    tester,
  ) async {
    final live = _LiveRepo()
      ..createError = _dioError(400, {'code': 'FACEBOOK_PAGE_NOT_ELIGIBLE'});
    final admin = _Admin();
    await _openFlow(tester, live, admin);
    await _tapCreate(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('100 followers'), findsOneWidget);
    expect(admin.created, isEmpty);
    expect(_editorSubmit, findsOneWidget);
  });
}
