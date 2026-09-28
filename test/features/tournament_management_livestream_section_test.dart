import 'dart:async';

import 'dart:convert';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/models/facebook_page_connection_model.dart';
import 'package:app_quanly_giaidau/data/models/live_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/live_session_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_livestream_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/livestream_pairing_qr_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/live_session_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _tournamentId = 'tournament-1';
const _communityId = 'community-1';

CameraDeviceModel _device({
  String id = 'device-1',
  String name = 'Camera A',
  CameraDeviceStatus status = CameraDeviceStatus.online,
}) => CameraDeviceModel(
  id: id,
  communityId: _communityId,
  name: name,
  status: status,
);

LiveSessionModel _session({
  String id = 'session-1',
  String title = 'Court 1 semi-final',
  LiveSessionStatus status = LiveSessionStatus.live,
}) => LiveSessionModel(
  id: id,
  tournamentId: _tournamentId,
  matchId: 'match-1',
  provider: LiveSessionProvider.facebook,
  status: status,
  replayProvider: ReplayProvider.none,
  title: title,
);

FacebookPageConnectionModel _connection({
  FacebookPageConnectionStatus status = FacebookPageConnectionStatus.active,
  DateTime? lastValidatedAt,
}) => FacebookPageConnectionModel(
  id: 'conn-1',
  communityId: _communityId,
  pageId: 'page-1',
  pageName: 'Sporto FC',
  status: status,
  connectedAt: DateTime.utc(2025, 12, 1),
  lastValidatedAt: lastValidatedAt ?? DateTime.utc(2026, 1, 1),
);

DioException _forbidden(String path) => DioException(
  requestOptions: RequestOptions(path: path),
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 403,
  ),
);

/// Records every repository call the section makes and answers only the safe
/// subset. Any un-stubbed method fails loudly through [noSuchMethod], so a
/// screen change that reaches for a blocked route cannot pass quietly.
class _FakeLiveSessionRepository implements ILiveSessionRepository {
  _FakeLiveSessionRepository({
    this.devices = const <CameraDeviceModel>[],
    this.sessions = const <LiveSessionModel>[],
    this.connection,
    this.devicesError,
  });

  List<CameraDeviceModel> devices;
  List<LiveSessionModel> sessions;
  FacebookPageConnectionModel? connection;
  Object? devicesError;
  final String pairingToken = 'token-abc';

  final List<String> calls = <String>[];

  /// Holds the create request open so a test can tap again while the first
  /// one is still in flight.
  Completer<void>? createDeviceGate;
  Object? createDeviceError;
  final List<String> requestedDeviceNames = <String>[];

  @override
  Future<List<CameraDeviceModel>> listDevices(String communityId) async {
    calls.add('listDevices');
    final error = devicesError;
    if (error != null) throw error;
    return devices;
  }

  @override
  Future<CameraDeviceModel> createDevice({
    required String communityId,
    required String name,
  }) async {
    calls.add('createDevice:$communityId');
    requestedDeviceNames.add(name);
    final error = createDeviceError;
    if (error != null) throw error;
    final gate = createDeviceGate;
    if (gate != null) await gate.future;
    final created = _device(
      id: 'device-new',
      name: name,
      status: CameraDeviceStatus.unpaired,
    );
    devices = <CameraDeviceModel>[...devices, created];
    return created;
  }

  @override
  Future<DevicePairingTokenModel> createPairingToken(String deviceId) async {
    calls.add('createPairingToken:$deviceId');
    return DevicePairingTokenModel(
      device: _device(id: deviceId),
      pairingToken: pairingToken,
      expiresAt: DateTime.utc(2026, 1, 1, 0, 10),
    );
  }

  @override
  Future<List<LiveSessionModel>> listSessions(String tournamentId) async {
    calls.add('listSessions');
    return sessions;
  }

  @override
  Future<LiveSessionOperatorResultModel> reconnectSession(
    String sessionId,
  ) async {
    calls.add('reconnectSession:$sessionId');
    return LiveSessionOperatorResultModel(session: _session(id: sessionId));
  }

  @override
  Future<LiveSessionModel> stopSession(String sessionId) async {
    calls.add('stopSession:$sessionId');
    return _session(id: sessionId, status: LiveSessionStatus.ended);
  }

  @override
  Future<FacebookPageConnectionModel?> getFacebookConnection(
    String communityId,
  ) async {
    calls.add('getFacebookConnection');
    return connection;
  }

  @override
  Future<String> createFacebookOAuthUrl(String communityId) async {
    calls.add('createFacebookOAuthUrl:$communityId');
    return 'https://www.facebook.com/oauth';
  }

  @override
  Future<FacebookPageConnectionModel> validateFacebookConnection(
    String connectionId,
  ) async {
    calls.add('validateFacebookConnection:$connectionId');
    return _connection();
  }

  @override
  Future<FacebookPageConnectionModel?> disconnectFacebookConnection(
    String communityId,
  ) async {
    calls.add('disconnectFacebookConnection');
    return _connection(status: FacebookPageConnectionStatus.disconnected);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AppLocalizations> _pumpSection(
  WidgetTester tester,
  _FakeLiveSessionRepository repository, {
  String? communityId = _communityId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [liveSessionRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: TournamentManagementLivestreamSection(
            tournamentId: _tournamentId,
            communityId: communityId,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(TournamentManagementLivestreamSection)),
  )!;
}

void main() {
  testWidgets(
    'without a community no community-scoped call is made, but sessions still load',
    (tester) async {
      final repository = _FakeLiveSessionRepository(
        devices: <CameraDeviceModel>[_device()],
        sessions: <LiveSessionModel>[_session()],
        connection: _connection(),
      );

      final l10n = await _pumpSection(tester, repository, communityId: null);

      expect(
        find.text(l10n.tournamentManagementLivestreamDevicesUnavailable),
        findsOneWidget,
      );
      expect(
        find.text(l10n.tournamentManagementLivestreamDevices),
        findsNothing,
      );
      expect(find.text(l10n.contactFacebook), findsNothing);
      // Session monitoring is tournament-scoped, so it still runs.
      expect(
        find.text(l10n.tournamentManagementLivestreamSessions),
        findsOneWidget,
      );
      expect(find.text('Court 1 semi-final'), findsOneWidget);
      expect(repository.calls, ['listSessions']);
    },
  );

  testWidgets(
    'tapping a device opens a QR sheet and never renders the token as text',
    (tester) async {
      final repository = _FakeLiveSessionRepository(
        devices: <CameraDeviceModel>[_device()],
      );

      final l10n = await _pumpSection(tester, repository);
      await tester.tap(
        find.widgetWithText(
          OutlinedButton,
          l10n.tournamentManagementLivestreamCreatePairingQr,
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.calls, contains('createPairingToken:device-1'));
      expect(find.byType(QrImageView), findsOneWidget);
      expect(
        find.text(l10n.tournamentManagementLivestreamPairingQrTitle),
        findsOneWidget,
      );
      // The one-time secret is rendered as pixels only.
      expect(find.textContaining('token-abc'), findsNothing);
    },
  );

  test('the QR payload is the exact object the pairing scanner parses', () {
    final payload = buildLivestreamPairingPayload(
      deviceId: 'device-1',
      pairingToken: 'token-abc',
    );

    expect(payload, '{"deviceId":"device-1","pairingToken":"token-abc"}');
    // `DevicePairingScreen` reads exactly these two keys, nothing else.
    expect(jsonDecode(payload), {
      'deviceId': 'device-1',
      'pairingToken': 'token-abc',
    });
  });

  testWidgets(
    'a 403 on the device fleet renders the forbidden state, not a retry',
    (tester) async {
      final repository = _FakeLiveSessionRepository(
        devicesError: _forbidden('/livestream/devices'),
      );

      final l10n = await _pumpSection(tester, repository);

      expect(find.text(l10n.tournamentManagementForbidden), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, l10n.tournamentManagementRetry),
        findsNothing,
      );
    },
  );

  testWidgets(
    'a reconnecting session offers a status re-check and an end action, an ended one offers neither',
    (tester) async {
      final repository = _FakeLiveSessionRepository(
        sessions: <LiveSessionModel>[
          _session(
            id: 'session-live',
            title: 'Live now',
            status: LiveSessionStatus.live,
          ),
          _session(
            id: 'session-retry',
            title: 'Reconnecting now',
            status: LiveSessionStatus.reconnecting,
          ),
          _session(
            id: 'session-ended',
            title: 'All done',
            status: LiveSessionStatus.ended,
          ),
        ],
      );

      final l10n = await _pumpSection(tester, repository);
      await tester.scrollUntilVisible(
        find.text('Reconnecting now'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      final recheck = find.widgetWithText(
        OutlinedButton,
        l10n.tournamentManagementLivestreamRecheckStatus,
      );
      final stop = find.widgetWithText(
        TextButton,
        l10n.tournamentManagementLivestreamStopSession,
      );
      expect(recheck, findsOneWidget);
      expect(stop, findsNWidgets(2));
      // The LIVE and RECONNECTING sessions can end; only RECONNECTING supports
      // status re-check. ENDED sessions offer neither action.
      final endedTile = find.ancestor(
        of: find.text('All done'),
        matching: find.byType(Column),
      );
      expect(
        find.descendant(of: endedTile.first, matching: stop),
        findsNothing,
      );
      expect(
        find.descendant(of: endedTile.first, matching: recheck),
        findsNothing,
      );
    },
  );

  testWidgets(
    're-check re-polls the session and end asks for confirmation first',
    (tester) async {
      final repository = _FakeLiveSessionRepository(
        sessions: <LiveSessionModel>[
          _session(id: 'session-1', status: LiveSessionStatus.reconnecting),
        ],
      );

      final l10n = await _pumpSection(tester, repository);
      await tester.scrollUntilVisible(
        find.text('Court 1 semi-final'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final recheck = find.widgetWithText(
        OutlinedButton,
        l10n.tournamentManagementLivestreamRecheckStatus,
      );
      await tester.ensureVisible(recheck);
      await tester.pumpAndSettle();
      await tester.tap(recheck);
      await tester.pumpAndSettle();
      expect(repository.calls, contains('reconnectSession:session-1'));

      final stop = find.widgetWithText(
        TextButton,
        l10n.tournamentManagementLivestreamStopSession,
      );
      await tester.ensureVisible(stop);
      await tester.pumpAndSettle();
      await tester.tap(stop);
      await tester.pumpAndSettle();
      expect(repository.calls, isNot(contains('stopSession:session-1')));
      expect(
        find.text(l10n.tournamentManagementLivestreamStopSessionConfirm),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(
          FilledButton,
          l10n.tournamentManagementLivestreamStopSession,
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.calls, contains('stopSession:session-1'));
    },
  );

  testWidgets('returning to the app re-polls the Facebook connection status', (
    tester,
  ) async {
    final repository = _FakeLiveSessionRepository(connection: _connection());

    final l10n = await _pumpSection(tester, repository);
    expect(find.text('Sporto FC'), findsOneWidget);
    expect(
      repository.calls.where((c) => c == 'getFacebookConnection').length,
      1,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      repository.calls.where((c) => c == 'getFacebookConnection').length,
      2,
    );
    // A re-check is what the UI offers; the copy must never promise a restart.
    expect(
      find.widgetWithText(
        OutlinedButton,
        l10n.tournamentManagementLivestreamFacebookRevalidate,
      ),
      findsOneWidget,
    );
  });

  testWidgets('a community with no Page offers the connect action', (
    tester,
  ) async {
    final repository = _FakeLiveSessionRepository();

    final l10n = await _pumpSection(tester, repository);

    expect(
      find.text(l10n.tournamentManagementLivestreamFacebookNotConnected),
      findsOneWidget,
    );
    final connect = find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementLivestreamFacebookConnect,
    );
    await tester.ensureVisible(connect);
    await tester.pumpAndSettle();
    expect(connect, findsOneWidget);
  });

  testWidgets(
    'an existing Page offers re-check and disconnect, never a Page token',
    (tester) async {
      final repository = _FakeLiveSessionRepository(connection: _connection());

      final l10n = await _pumpSection(tester, repository);
      final revalidate = find.widgetWithText(
        OutlinedButton,
        l10n.tournamentManagementLivestreamFacebookRevalidate,
      );
      await tester.ensureVisible(revalidate);
      await tester.pumpAndSettle();
      expect(revalidate, findsOneWidget);

      await tester.tap(revalidate);
      await tester.pumpAndSettle();
      expect(repository.calls, contains('validateFacebookConnection:conn-1'));

      final disconnect = find.widgetWithText(
        TextButton,
        l10n.tournamentManagementLivestreamFacebookDisconnect,
      );
      await tester.ensureVisible(disconnect);
      await tester.pumpAndSettle();
      await tester.tap(disconnect);
      await tester.pumpAndSettle();
      expect(repository.calls, contains('disconnectFacebookConnection'));
      // The re-polled status, not any secret, is what the screen renders.
      expect(repository.calls, isNot(contains('createFacebookOAuthUrl')));
    },
  );

  testWidgets('a disconnected Page can start a fresh Facebook authorization', (
    tester,
  ) async {
    final repository = _FakeLiveSessionRepository(
      connection: _connection(
        status: FacebookPageConnectionStatus.disconnected,
      ),
    );

    final l10n = await _pumpSection(tester, repository);
    final connect = find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementLivestreamFacebookConnect,
    );
    expect(connect, findsOneWidget);
    await tester.ensureVisible(connect);
    await tester.pumpAndSettle();
    await tester.tap(connect);
    await tester.pumpAndSettle();

    expect(repository.calls, contains('createFacebookOAuthUrl:$_communityId'));
  });

  testWidgets(
    'a community with no camera devices can create the first one from the empty state',
    (tester) async {
      final repository = _FakeLiveSessionRepository();

      final l10n = await _pumpSection(tester, repository);
      expect(
        find.text(l10n.tournamentManagementLivestreamDevicesEmpty),
        findsOneWidget,
      );
      final create = find.widgetWithText(
        FilledButton,
        l10n.tournamentManagementLivestreamCreateDevice,
      );
      await tester.ensureVisible(create);
      await tester.pumpAndSettle();
      // The form must stay available while the fleet is empty, otherwise the
      // first device of a community could never be registered.
      expect(create, findsOneWidget);

      await tester.enterText(find.byType(TextField), '  Court 1 phone  ');
      await tester.tap(create);
      await tester.pumpAndSettle();

      // Surrounding spaces are trimmed before the call, not sent as typed.
      expect(repository.requestedDeviceNames, ['Court 1 phone']);
      expect(repository.calls, contains('createDevice:$_communityId'));

      // Success is the re-polled fleet, not a message echoing the response.
      expect(find.text('Court 1 phone'), findsOneWidget);
      expect(
        repository.calls.where((call) => call == 'listDevices'),
        hasLength(2),
      );
    },
  );

  testWidgets('a whitespace-only name is refused without reaching the API', (
    tester,
  ) async {
    final repository = _FakeLiveSessionRepository();

    final l10n = await _pumpSection(tester, repository);
    final create = find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementLivestreamCreateDevice,
    );
    await tester.ensureVisible(create);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(create);
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.tournamentManagementLivestreamDeviceNameRequired),
      findsOneWidget,
    );
    expect(repository.requestedDeviceNames, isEmpty);
  });
  testWidgets('device name follows the backend two-to-255 character boundary', (
    tester,
  ) async {
    final repository = _FakeLiveSessionRepository();
    final l10n = await _pumpSection(tester, repository);
    final create = find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementLivestreamCreateDevice,
    );
    await tester.ensureVisible(create);
    await tester.pumpAndSettle();

    final errorMessage =
        l10n.tournamentManagementLivestreamDeviceNameLengthInvalid;
    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text(errorMessage), findsOneWidget);
    expect(repository.requestedDeviceNames, isEmpty);

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(create);
    await tester.pumpAndSettle();
    final maxName = List.filled(255, 'x').join();
    await tester.enterText(find.byType(TextField), maxName);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(repository.requestedDeviceNames, ['ab', maxName]);

    final tooLongName = List.filled(256, 'x').join();
    await tester.enterText(find.byType(TextField), tooLongName);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text(errorMessage), findsOneWidget);
    expect(repository.requestedDeviceNames, ['ab', maxName]);
  });

  testWidgets('a second tap while the create is in flight is ignored', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = _FakeLiveSessionRepository()..createDeviceGate = gate;

    final l10n = await _pumpSection(tester, repository);
    final create = find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementLivestreamCreateDevice,
    );
    await tester.ensureVisible(create);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Court 1 phone');
    await tester.tap(create);
    await tester.pump();

    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    await tester.tap(create);
    await tester.pump();
    expect(repository.requestedDeviceNames, hasLength(1));

    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.requestedDeviceNames, hasLength(1));
    expect(find.text('Court 1 phone'), findsOneWidget);
  });

  testWidgets(
    'a rejected create shows the fixed error, never the response body',
    (tester) async {
      final request = RequestOptions(path: '/livestream/devices');
      final repository = _FakeLiveSessionRepository()
        ..createDeviceError = DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: request,
            statusCode: 400,
            data: <String, dynamic>{
              'message': 'streamKey rtsp://admin:hunter2@cam/1 was rejected',
            },
          ),
        );

      final l10n = await _pumpSection(tester, repository);
      final create = find.widgetWithText(
        FilledButton,
        l10n.tournamentManagementLivestreamCreateDevice,
      );
      await tester.ensureVisible(create);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Court 1 phone');
      await tester.tap(create);
      await tester.pumpAndSettle();

      expect(find.text(l10n.tournamentManagementActionError), findsOneWidget);
      // Neither the Dio payload nor anything in it reaches the screen.
      expect(find.textContaining('hunter2'), findsNothing);
      expect(find.textContaining('streamKey'), findsNothing);
      // The rejected device is absent from the fleet, which stays empty.
      expect(
        find.text(l10n.tournamentManagementLivestreamDevicesEmpty),
        findsOneWidget,
      );
    },
  );
}
