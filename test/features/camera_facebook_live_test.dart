import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/facebook_live_error.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_editor_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/facebook_live_panel.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/facebook_live_ready_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMFB-APP-01..10: "Tạo live trên Facebook" trong form tạo camera.
const _live = CreatedFacebookLive(
  providerSessionId: '1234567890123456',
  watchUrl: 'https://www.facebook.com/watch/?v=1234567890123456',
  rtmpUrl: 'rtmps://live-api-s.facebook.com:443/rtmp',
  streamKey: 'FB-SECRET-KEY',
);

class _FakeRepo implements IFacebookCameraLiveRepository {
  _FakeRepo({this.connected = true, this.hasCommunity = true});

  bool connected;
  final bool hasCommunity;
  int createCalls = 0;
  Completer<CreatedFacebookLive>? gate;
  Object? createError;

  @override
  Future<FacebookLiveConnection> getConnection(String tournamentId) async =>
      FacebookLiveConnection(
        communityId: hasCommunity ? 'c1' : null,
        connected: connected,
        pageName: connected ? 'CLB Pickle' : null,
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

DioException _dioError(int? status, [Object? data]) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: status,
          data: data,
        ),
);

Widget _host(Widget child, {double width = 320}) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

Future<void> _pumpPanel(
  WidgetTester tester,
  _FakeRepo repo, {
  Future<void> Function(CreatedFacebookLive live)? onCreated,
  double width = 320,
}) async {
  await tester.pumpWidget(
    _host(
      FacebookLivePanel(
        tournamentId: 't1',
        repository: repo,
        onCreated: onCreated ?? (_) async {},
      ),
      width: width,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpReady(WidgetTester tester) async {
  await tester.pumpWidget(
    _host(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => FacebookLiveReadySheet.show(
            context,
            live: _live,
            cameraName: 'Camera A',
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

final _create = find.byKey(const ValueKey('fb-live-create'));
final _connect = find.byKey(const ValueKey('fb-live-connect'));
final _error = find.byKey(const ValueKey('fb-live-error'));
final _notConfigured = find.byKey(const ValueKey('fb-live-not-configured'));

void main() {
  test('TC-CAMFB-APP-01 parse response and never prints the key', () {
    final live = CreatedFacebookLive.fromJson(const {
      'providerSessionId': '123',
      'watchUrl': 'https://www.facebook.com/watch/?v=123',
      'rtmpUrl': 'rtmps://a/rtmp',
      'streamKey': 'SECRET',
    });
    expect(live.streamKey, 'SECRET');
    expect(live.toString(), isNot(contains('SECRET')));
    expect(
      () => CreatedFacebookLive.fromJson(const {'watchUrl': 'x'}),
      throwsFormatException,
    );
    final off = FacebookLiveConnection.fromJson(const {
      'communityId': null,
      'connected': false,
      'pageName': null,
    });
    expect(off.connected, isFalse);
    expect(off.communityId, isNull);
  });

  test('TC-CAMFB-APP-02 error mapping', () {
    FacebookLiveError map(Object e) => facebookLiveError(e);
    expect(
      map(_dioError(400, {'code': 'FACEBOOK_NOT_CONNECTED'})),
      FacebookLiveError.notConnected,
    );
    expect(
      map(_dioError(400, {'code': 'FACEBOOK_CONNECTION_EXPIRED'})),
      FacebookLiveError.expired,
    );
    expect(
      map(_dioError(400, {'code': 'FACEBOOK_PERMISSION_MISSING'})),
      FacebookLiveError.permission,
    );
    expect(
      map(_dioError(400, {'code': 'PROVIDER_UNAVAILABLE'})),
      FacebookLiveError.unavailable,
    );
    expect(map(_dioError(403)), FacebookLiveError.forbidden);
    expect(map(_dioError(503)), FacebookLiveError.unavailable);
    expect(map(_dioError(null)), FacebookLiveError.network);
    expect(map(_dioError(400, 'x')), FacebookLiveError.generic);
    expect(map(StateError('x')), FacebookLiveError.generic);
  });

  test('TC-FBONE-APP-01 maps FACEBOOK_PAGE_NOT_ELIGIBLE, tells 100 followers', () {
    final error = facebookLiveError(
      _dioError(400, {'code': 'FACEBOOK_PAGE_NOT_ELIGIBLE'}),
    );
    expect(error, FacebookLiveError.pageNotEligible);
    expect(
      facebookLiveErrorText(lookupAppLocalizations(const Locale('en')), error),
      contains('100 followers'),
    );
    expect(
      facebookLiveErrorText(lookupAppLocalizations(const Locale('vi')), error),
      contains('100 người theo dõi'),
    );
    expect(
      facebookLiveDefaultCameraName(DateTime(2026, 11, 15, 9, 5)),
      'Live Facebook 09:05',
    );
  });

  testWidgets('TC-FBPAGE-APP-01 shared page not configured: no Connect or Create, '
      'tells the user to contact an administrator', (tester) async {
    await _pumpPanel(tester, _FakeRepo(connected: false));
    expect(_connect, findsNothing);
    expect(_create, findsNothing);
    expect(_notConfigured, findsOneWidget);
    expect(find.textContaining('contact an administrator'), findsOneWidget);
  });

  testWidgets('TC-FBPAGE-APP-02 tournament without a club can still create a live', (
    tester,
  ) async {
    final filled = <CreatedFacebookLive>[];
    await _pumpPanel(
      tester,
      _FakeRepo(hasCommunity: false),
      onCreated: (live) async => filled.add(live),
    );
    expect(tester.widget<FilledButton>(_create).onPressed, isNotNull);
    await tester.tap(_create);
    await tester.pumpAndSettle();
    expect(filled, [_live]);
  });

  testWidgets('TC-FBPAGE-APP-03 expired token tells the user to contact an '
      'administrator, never to press Connect page', (tester) async {
    final repo = _FakeRepo()
      ..createError = _dioError(400, {'code': 'FACEBOOK_CONNECTION_EXPIRED'});
    await _pumpPanel(tester, repo);
    await tester.tap(_create);
    await tester.pumpAndSettle();
    expect(_error, findsOneWidget);
    expect(find.textContaining('contact an administrator'), findsOneWidget);
    expect(find.textContaining('Connect page'), findsNothing);
  });

  testWidgets('TC-CAMFB-APP-06 double tap calls create once, shows spinner', (
    tester,
  ) async {
    final repo = _FakeRepo()..gate = Completer();
    final filled = <CreatedFacebookLive>[];
    await _pumpPanel(
      tester,
      repo,
      onCreated: (live) async => filled.add(live),
    );
    await tester.tap(_create);
    await tester.pump();
    expect(tester.widget<FilledButton>(_create).onPressed, isNull);
    expect(find.text('Creating camera...'), findsOneWidget);
    await tester.tap(_create, warnIfMissed: false);
    await tester.pump();
    expect(repo.createCalls, 1);
    repo.gate!.complete(_live);
    await tester.pumpAndSettle();
    expect(repo.createCalls, 1);
    expect(filled, [_live]);
  });

  testWidgets('TC-CAMFB-APP-07 ready sheet key block: masked, toggle, copy', (
    tester,
  ) async {
    final clip = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clip.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpReady(tester);

    EditableText field(String key) => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      ),
    );
    expect(field('fb-live-rtmp').obscureText, isFalse);
    expect(field('fb-live-key').obscureText, isTrue);
    await tester.tap(find.byKey(const ValueKey('fb-live-key-toggle')));
    await tester.pump();
    expect(field('fb-live-key').obscureText, isFalse);
    await tester.tap(find.byKey(const ValueKey('fb-live-key-toggle')));
    await tester.pump();
    expect(field('fb-live-key').obscureText, isTrue);

    await tester.tap(find.byKey(const ValueKey('fb-live-rtmp-copy')));
    await tester.tap(find.byKey(const ValueKey('fb-live-key-copy')));
    await tester.pump();
    expect(clip, [_live.rtmpUrl, _live.streamKey]);
  });

  testWidgets('TC-CAMFB-APP-08 failure shows mapped message, retry works', (
    tester,
  ) async {
    final repo = _FakeRepo()..createError = _dioError(null);
    await _pumpPanel(tester, repo);
    await tester.tap(_create);
    await tester.pumpAndSettle();
    expect(find.textContaining('network is down'), findsOneWidget);
    repo.createError = null;
    await tester.tap(_create);
    await tester.pumpAndSettle();
    expect(repo.createCalls, 2);
    expect(_error, findsNothing);
  });

  testWidgets('TC-CAMFB-APP-09 no overflow at 320dp with key shown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpReady(tester);
    await tester.tap(find.byKey(const ValueKey('fb-live-key-toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-CAMFB-APP-10 pasted link still previews and saves as before', (
    tester,
  ) async {
    CameraEditorValue? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => CameraEditorSheet.show(
                context,
                courts: const <TournamentCourtRef>[],
                onSubmit: (value) async => saved = value,
                facebookLiveTournamentId: 't1',
                facebookLiveRepository: _FakeRepo(),
                previewBuilder: (context, embed) =>
                    Text(embed.embedUrl!, key: const ValueKey('preview')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fb-live-panel')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('camera-source-live')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('camera-editor-name')),
      'Camera A',
    );
    await tester.enterText(
      find.byKey(const ValueKey('camera-live-link')),
      _live.watchUrl,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('camera-editor-submit')));
    await tester.pumpAndSettle();
    expect(saved?.mode, 'PULL');
    expect(saved?.playbackUrl, _live.watchUrl);
    expect(saved?.facebookLive, isNull);
  });
}
