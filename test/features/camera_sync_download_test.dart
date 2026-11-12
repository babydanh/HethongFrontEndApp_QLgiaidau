import 'dart:async';
import 'dart:io';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/full_recording_download.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/match_recording_player_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAM-SYNC-29..32: "Tải video đầy đủ" (playlist kiểm quyền → tải → chia sẻ).
const _mid = 'match-1';
const _period = '2026-10-09';

DioException _http(int status) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

class _Repo implements IMatchRecordingCatalogRepository {
  Object? playlistError;
  Object? downloadError;
  final List<String> calls = <String>[];
  Future<void>? hold;

  @override
  Future<MatchRecordingPlaylist> getPlaylist(
    String matchId, {
    required String period,
  }) async {
    calls.add('playlist');
    if (playlistError != null) throw playlistError!;
    return MatchRecordingPlaylist(period: period, segments: const []);
  }

  @override
  Future<void> downloadFullRecording(
    String matchId, {
    required String period,
    required String savePath,
  }) async {
    calls.add('download:$savePath');
    await hold;
    if (downloadError != null) throw downloadError!;
    await File(savePath).writeAsBytes(<int>[1, 2, 3]);
  }

  @override
  Future<MatchStreamControlStateModel> getMatchControlState(String matchId) =>
      throw UnimplementedError();

  @override
  Future<MatchRecordingDaysModel> listRecordingDays(String matchId) =>
      throw UnimplementedError();

  @override
  Future<List<MatchRecordingFileModel>> listRecordings(
    String matchId, {
    required String period,
  }) => throw UnimplementedError();

  @override
  Future<MatchStreamCommandResult> startMatchStream(String matchId) =>
      throw UnimplementedError();

  @override
  Future<MatchStreamCommandResult> stopMatchStream(String matchId) =>
      throw UnimplementedError();

  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) => throw UnimplementedError();
}

class _Env {
  _Env(this.repo, this.dir);

  final _Repo repo;
  final Directory dir;
  final List<String> shared = <String>[];
  bool existedWhenShared = false;

  FullRecordingDownloader get downloader => FullRecordingDownloader(
    repo,
    tempDirectory: () async => dir,
    share: (path) async {
      shared.add(path);
      existedWhenShared = File(path).existsSync();
    },
  );
}

class _FakeDownloader extends FullRecordingDownloader {
  _FakeDownloader() : super(_Repo());

  Completer<void>? hold;
  Object? error;
  final List<String> runs = <String>[];

  @override
  Future<void> run(String matchId, String period) async {
    runs.add('$matchId|$period');
    await hold?.future;
    if (error != null) throw error!;
  }
}

Future<_Env> _env() async {
  final dir = await Directory.systemTemp.createTemp('cam_dl');
  addTearDown(() => dir.delete(recursive: true));
  return _Env(_Repo(), dir);
}

void main() {
  test('TC-CAM-SYNC-29 kiểm quyền bằng playlist rồi tải, chia sẻ và dọn file tạm', () async {
    final env = await _env();

    await env.downloader.run(_mid, _period);

    expect(env.repo.calls.first, 'playlist');
    expect(env.repo.calls.last, startsWith('download:${env.dir.path}/'));
    expect(env.repo.calls.last, endsWith('.mp4'));
    expect(env.shared, hasLength(1));
    expect(env.existedWhenShared, isTrue);
    expect(File(env.shared.single).existsSync(), isFalse);
  });

  test('TC-CAM-SYNC-30 playlist 403 thì không tải và không chia sẻ; tải lỗi cũng dọn file', () async {
    final env = await _env();
    env.repo.playlistError = _http(403);
    await expectLater(env.downloader.run(_mid, _period), throwsA(isA<DioException>()));
    expect(env.repo.calls, <String>['playlist']);
    expect(env.shared, isEmpty);

    final failing = await _env();
    failing.repo.downloadError = _http(500);
    await expectLater(failing.downloader.run(_mid, _period), throwsA(isA<DioException>()));
    expect(failing.shared, isEmpty);
    expect(failing.dir.listSync(), isEmpty);
  });

  Future<void> pumpSheet(WidgetTester tester, _FakeDownloader downloader) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchRecordingCatalogRepositoryProvider.overrideWithValue(_Repo()),
          fullRecordingDownloaderProvider.overrideWithValue(downloader),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: MatchRecordingPlayerSheet(matchId: _mid, period: _period),
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('TC-CAM-SYNC-31 bấm Tải: khoá nút, báo đang chuẩn bị, xong thì mở lại', (
    tester,
  ) async {
    final downloader = _FakeDownloader()..hold = Completer<void>();
    await pumpSheet(tester, downloader);
    final button = find.widgetWithText(OutlinedButton, 'Tải video đầy đủ');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));

    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Đang chuẩn bị tải video…'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    expect(downloader.runs, <String>['$_mid|$_period']);

    downloader.hold!.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('Đang chuẩn bị tải video…'), findsNothing);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
  });

  testWidgets('TC-CAM-SYNC-32 thiếu quyền hoặc lỗi: báo lỗi tải video, không crash', (
    tester,
  ) async {
    final downloader = _FakeDownloader()..error = _http(403);
    await pumpSheet(tester, downloader);

    final button = find.widgetWithText(OutlinedButton, 'Tải video đầy đủ');
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Không thể chuẩn bị tải video'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
