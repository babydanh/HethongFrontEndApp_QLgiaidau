import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_live_status_action.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/match_recording_catalog_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _cameraId = '550e8400-e29b-41d4-a716-446655440000';
const _matchId = '550e8400-e29b-41d4-a716-446655440001';

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

class _FakeCatalogRepository implements IMatchRecordingCatalogRepository {
  _FakeCatalogRepository({
    required this.control,
    required this.days,
    required this.loadFiles,
    this.loadControl,
  });

  final MatchStreamControlStateModel control;
  final MatchRecordingDaysModel days;
  final Future<MatchStreamControlStateModel> Function(String matchId)?
  loadControl;
  final Future<List<MatchRecordingFileModel>> Function(String period) loadFiles;
  final List<String> calls = <String>[];

  @override
  Future<MatchStreamControlStateModel> getMatchControlState(
    String matchId,
  ) async {
    calls.add('control:$matchId');
    final loader = loadControl;
    if (loader != null) return loader(matchId);
    return control;
  }

  @override
  Future<MatchRecordingDaysModel> listRecordingDays(String matchId) async {
    calls.add('days:$matchId');
    return days;
  }

  @override
  Future<List<MatchRecordingFileModel>> listRecordings(
    String matchId, {
    required String period,
  }) {
    calls.add('files:$period');
    return loadFiles(period);
  }

  @override
  Future<MatchRecordingPlaylist> getPlaylist(
    String matchId, {
    required String period,
  }) async {
    calls.add('playlist:$period');
    return MatchRecordingPlaylist(period: period, segments: const []);
  }
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

Future<void> _pumpCatalog(
  WidgetTester tester,
  _FakeCatalogRepository repository, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: ObjectKey(repository),
      overrides: [
        matchRecordingCatalogRepositoryProvider.overrideWithValue(repository),
      ],
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
        home: const Scaffold(
          body: MatchRecordingCatalogSheet(
            matchId: _matchId,
            matchLabel: 'Court 1 final',
          ),
        ),
      ),
    ),
  );
}

const _otherMatchId = '550e8400-e29b-41d4-a716-446655440002';

Future<void> _pumpCatalogHost(
  WidgetTester tester,
  _FakeCatalogRepository repository, {
  required Widget home,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: ObjectKey(repository),
      overrides: [
        matchRecordingCatalogRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: home,
      ),
    ),
  );
}

class _MatchSwitchHost extends StatefulWidget {
  const _MatchSwitchHost();

  @override
  State<_MatchSwitchHost> createState() => _MatchSwitchHostState();
}

class _MatchSwitchHostState extends State<_MatchSwitchHost> {
  String _activeMatchId = _matchId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () => setState(() => _activeMatchId = _otherMatchId),
          child: const Text('Switch match'),
        ),
        Expanded(
          child: MatchRecordingCatalogSheet(
            key: const ValueKey('match-catalog'),
            matchId: _activeMatchId,
            matchLabel: _activeMatchId,
          ),
        ),
      ],
    ),
  );
}

class _CatalogSheetHost extends StatelessWidget {
  const _CatalogSheetHost();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showMatchRecordingCatalogSheet(
          context,
          matchId: _matchId,
          matchLabel: 'Court 1 final',
        ),
        child: const Text('Open catalog'),
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

  testWidgets('no-camera catalog stops before days and files', (tester) async {
    final repository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: false,
      ),
      days: MatchRecordingDaysModel(days: <String>[]),
      loadFiles: (_) async => const <MatchRecordingFileModel>[],
    );

    await _pumpCatalog(tester, repository);
    await tester.pump();
    await tester.pump();

    expect(find.text('No camera is assigned to this match.'), findsOneWidget);
    expect(repository.calls, <String>['control:$_matchId']);
  });

  testWidgets(
    'late files from an older selected day cannot replace current data',
    (tester) async {
      final latestFiles = Completer<List<MatchRecordingFileModel>>();
      final repository = _FakeCatalogRepository(
        control: const MatchStreamControlStateModel(
          matchId: _matchId,
          hasCamera: true,
        ),
        days: MatchRecordingDaysModel(
          days: <String>['2026-10-09', '2026-10-08'],
        ),
        loadFiles: (period) {
          if (period == '2026-10-09') return latestFiles.future;
          return Future.value(const <MatchRecordingFileModel>[
            MatchRecordingFileModel(name: 'older-day.mp4'),
          ]);
        },
      );

      await _pumpCatalog(tester, repository);
      await tester.pump();
      await tester.pump();
      expect(repository.calls.last, 'files:2026-10-09');

      await tester.tap(find.byKey(const ValueKey('recording-day-selector')));
      await tester.pump();
      await tester.tap(find.text('2026-10-08').last);
      await tester.pump();
      await tester.pump();
      expect(find.text('older-day.mp4'), findsOneWidget);

      latestFiles.complete(const <MatchRecordingFileModel>[
        MatchRecordingFileModel(name: 'late-newest.mp4'),
      ]);
      await tester.pump();
      await tester.pump();

      expect(find.text('older-day.mp4'), findsOneWidget);
      expect(find.text('late-newest.mp4'), findsNothing);
    },
  );
  testWidgets('changing matches invalidates pending recording files', (
    tester,
  ) async {
    final oldFiles = Completer<List<MatchRecordingFileModel>>();
    var fileRequests = 0;
    final repository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: true,
      ),
      days: MatchRecordingDaysModel(days: <String>['2026-10-09']),
      loadFiles: (_) {
        fileRequests++;
        if (fileRequests == 1) return oldFiles.future;
        return Future.value(const <MatchRecordingFileModel>[
          MatchRecordingFileModel(name: 'current-match.mp4'),
        ]);
      },
    );

    await _pumpCatalogHost(tester, repository, home: const _MatchSwitchHost());
    await tester.pump();
    await tester.pump();
    expect(repository.calls.last, 'files:2026-10-09');

    await tester.tap(find.text('Switch match'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(repository.calls, contains('control:$_otherMatchId'));
    expect(find.text('current-match.mp4'), findsOneWidget);

    oldFiles.complete(const <MatchRecordingFileModel>[
      MatchRecordingFileModel(name: 'stale-match.mp4'),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('current-match.mp4'), findsOneWidget);
    expect(find.text('stale-match.mp4'), findsNothing);
  });

  testWidgets('closing and reopening starts fresh and ignores the old sheet', (
    tester,
  ) async {
    final oldFiles = Completer<List<MatchRecordingFileModel>>();
    var fileRequests = 0;
    final repository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: true,
      ),
      days: MatchRecordingDaysModel(days: <String>['2026-10-09']),
      loadFiles: (_) {
        fileRequests++;
        if (fileRequests == 1) return oldFiles.future;
        return Future.value(const <MatchRecordingFileModel>[
          MatchRecordingFileModel(name: 'reopened-sheet.mp4'),
        ]);
      },
    );

    await _pumpCatalogHost(tester, repository, home: const _CatalogSheetHost());
    await tester.tap(find.text('Open catalog'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump();
    expect(fileRequests, 1);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byTooltip('Close'), findsNothing);

    await tester.tap(find.text('Open catalog'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump();
    expect(fileRequests, 2);
    expect(find.text('reopened-sheet.mp4'), findsOneWidget);

    oldFiles.complete(const <MatchRecordingFileModel>[
      MatchRecordingFileModel(name: 'closed-sheet.mp4'),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('reopened-sheet.mp4'), findsOneWidget);
    expect(find.text('closed-sheet.mp4'), findsNothing);
  });
  testWidgets('catalog errors are generic and retry the selected day', (
    tester,
  ) async {
    var fileRequests = 0;
    final repository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: true,
      ),
      days: MatchRecordingDaysModel(days: <String>['2026-10-09']),
      loadFiles: (_) {
        fileRequests++;
        if (fileRequests == 1) {
          return Future<List<MatchRecordingFileModel>>.error(
            StateError('AQVISION_API_SECRET=do-not-render'),
          );
        }
        return Future.value(const <MatchRecordingFileModel>[
          MatchRecordingFileModel(name: 'retry-success.mp4'),
        ]);
      },
    );

    await _pumpCatalog(tester, repository);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Could not load recording list.'), findsOneWidget);
    expect(find.textContaining('AQVISION_API_SECRET'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(fileRequests, 2);
    expect(find.text('retry-success.mp4'), findsOneWidget);
  });
  testWidgets('catalog 401 shows session-expired copy without retry', (
    tester,
  ) async {
    final repository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: false,
      ),
      days: MatchRecordingDaysModel(days: <String>[]),
      loadControl: (_) async => throw _httpError(401),
      loadFiles: (_) async => const <MatchRecordingFileModel>[],
    );
    await _pumpCatalog(tester, repository, locale: const Locale('vi'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Phiên đăng nhập đã hết hạn hoặc mã truy cập đã được đổi.'),
      findsOneWidget,
    );
    expect(repository.calls, <String>['control:$_matchId']);
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('catalog 403/404 are specific; 409 is generic and not retried', (
    tester,
  ) async {
    final deniedRepository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: false,
      ),
      days: MatchRecordingDaysModel(days: <String>[]),
      loadControl: (_) async => throw _httpError(403),
      loadFiles: (_) async => const <MatchRecordingFileModel>[],
    );
    await _pumpCatalog(tester, deniedRepository, locale: const Locale('vi'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Bạn không có quyền xem bản ghi của trận đấu này.'),
      findsOneWidget,
    );
    expect(deniedRepository.calls, <String>['control:$_matchId']);
    expect(find.text('Thử lại'), findsNothing);

    final missingRepository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: true,
      ),
      days: MatchRecordingDaysModel(days: <String>['2026-10-09']),
      loadFiles: (_) =>
          Future<List<MatchRecordingFileModel>>.error(_httpError(404)),
    );
    await _pumpCatalog(tester, missingRepository);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Recording information is unavailable.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(
      tester
          .widget<DropdownButton<String>>(
            find.byKey(const ValueKey('recording-day-selector')),
          )
          .onChanged,
      isNull,
    );

    final conflictRepository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: true,
      ),
      days: MatchRecordingDaysModel(days: <String>['2026-10-09']),
      loadFiles: (_) =>
          Future<List<MatchRecordingFileModel>>.error(_httpError(409)),
    );
    await _pumpCatalog(tester, conflictRepository);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load recording list.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(
      tester
          .widget<DropdownButton<String>>(
            find.byKey(const ValueKey('recording-day-selector')),
          )
          .onChanged,
      isNull,
    );
  });
  testWidgets('status action and recording catalog fit a narrow phone', (
    tester,
  ) async {
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

    final catalogRepository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: true,
      ),
      days: MatchRecordingDaysModel(days: <String>['2026-10-09']),
      loadFiles: (_) async => const <MatchRecordingFileModel>[
        MatchRecordingFileModel(
          name:
              'court-final-very-long-recording-name-that-wraps-on-a-small-phone.mp4',
          sizeBytes: 3456,
        ),
      ],
    );
    await _pumpCatalog(tester, catalogRepository, textScale: 1.4);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('catalog distinguishes no days from an empty selected day', (
    tester,
  ) async {
    final noDaysRepository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: true,
      ),
      days: MatchRecordingDaysModel(days: <String>[]),
      loadFiles: (_) async => const <MatchRecordingFileModel>[],
    );
    await _pumpCatalog(tester, noDaysRepository);
    await tester.pump();
    await tester.pump();
    expect(
      find.text('No recordings were found for this match.'),
      findsOneWidget,
    );
    expect(noDaysRepository.calls, <String>[
      'control:$_matchId',
      'days:$_matchId',
    ]);

    final noFilesRepository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: true,
      ),
      days: MatchRecordingDaysModel(days: <String>['2026-10-09']),
      loadFiles: (_) async => const <MatchRecordingFileModel>[],
    );
    await _pumpCatalog(tester, noFilesRepository);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('No recordings found for this day.'), findsOneWidget);
  });
  testWidgets('Vietnamese status and catalog labels are localized', (
    tester,
  ) async {
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

    final catalogRepository = _FakeCatalogRepository(
      control: const MatchStreamControlStateModel(
        matchId: _matchId,
        hasCamera: false,
      ),
      days: MatchRecordingDaysModel(days: <String>[]),
      loadFiles: (_) async => const <MatchRecordingFileModel>[],
    );
    await _pumpCatalog(tester, catalogRepository, locale: const Locale('vi'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Trận đấu chưa được gán camera.'), findsOneWidget);
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
