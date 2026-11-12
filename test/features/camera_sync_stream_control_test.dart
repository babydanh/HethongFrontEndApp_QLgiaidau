import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_stream_toggle_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAM-SYNC-07..13: nút Bắt đầu/Dừng phát ở trang chấm điểm.
const _matchId = 'match-1';

DioException _http(int status) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

class _FakeRepo implements IMatchRecordingCatalogRepository {
  _FakeRepo(this.control);

  MatchStreamControlStateModel control;
  Object? controlError;
  Object? commandError;
  Completer<MatchStreamCommandResult>? hold;
  MatchStreamCommandResult startResult = const MatchStreamCommandResult(
    streamStatus: MatchStreamStatus.live,
  );
  MatchStreamCommandResult stopResult = const MatchStreamCommandResult(
    streamStatus: MatchStreamStatus.idle,
  );
  int starts = 0;
  int stops = 0;

  @override
  Future<MatchStreamControlStateModel> getMatchControlState(
    String matchId,
  ) async {
    if (controlError != null) throw controlError!;
    return control;
  }

  @override
  Future<MatchStreamCommandResult> startMatchStream(String matchId) async {
    starts++;
    if (hold != null) return hold!.future;
    if (commandError != null) throw commandError!;
    return startResult;
  }

  @override
  Future<MatchStreamCommandResult> stopMatchStream(String matchId) async {
    stops++;
    if (commandError != null) throw commandError!;
    return stopResult;
  }

  @override
  Future<MatchRecordingDaysModel> listRecordingDays(String matchId) =>
      throw UnimplementedError();

  @override
  Future<List<MatchRecordingFileModel>> listRecordings(
    String matchId, {
    required String period,
  }) => throw UnimplementedError();

  @override
  Future<MatchRecordingPlaylist> getPlaylist(
    String matchId, {
    required String period,
  }) => throw UnimplementedError();

  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) async => const <MatchLivestreamSummary>[];

  @override
  Future<void> downloadFullRecording(
    String matchId, {
    required String period,
    required String savePath,
  }) async {}
}

MatchStreamControlStateModel _control({
  bool hasCamera = true,
  MatchStreamStatus? status = MatchStreamStatus.idle,
}) => MatchStreamControlStateModel(
  matchId: _matchId,
  hasCamera: hasCamera,
  streamStatus: status,
);

int _playbackReads = 0;

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  _playbackReads = 0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRecordingCatalogRepositoryProvider.overrideWithValue(repo),
        matchPlaybackProvider.overrideWith((ref, id) async {
          _playbackReads++;
          return null;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              ref.watch(matchPlaybackProvider(_matchId));
              return const MatchStreamToggleRow(
                matchId: _matchId,
                matchLabel: 'A – B',
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _start => find.widgetWithText(FilledButton, 'Bắt đầu');
Finder get _stop => find.widgetWithText(FilledButton, 'Dừng');

void main() {
  testWidgets('TC-CAM-SYNC-07 không camera hoặc trạng thái lạ thì không có nút', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo(_control(hasCamera: false, status: null)));
    expect(_start, findsNothing);
    expect(_stop, findsNothing);

    await _pump(tester, _FakeRepo(_control(status: null)));
    expect(_start, findsNothing);
    expect(_stop, findsNothing);
  });

  testWidgets('TC-CAM-SYNC-08 chưa live: nút Bắt đầu gọi start rồi đổi thành Dừng', (
    tester,
  ) async {
    final repo = _FakeRepo(_control());
    await _pump(tester, repo);
    expect(find.text('Trực tiếp'), findsOneWidget);
    expect(_start, findsOneWidget);
    expect(tester.getSize(_start).height, greaterThanOrEqualTo(44));

    await tester.tap(_start);
    await tester.pumpAndSettle();

    expect(repo.starts, 1);
    expect(_stop, findsOneWidget);
    expect(_start, findsNothing);
  });

  testWidgets('TC-CAM-SYNC-09 đang live: nút Dừng gọi stop rồi đổi thành Bắt đầu', (
    tester,
  ) async {
    final repo = _FakeRepo(_control(status: MatchStreamStatus.live));
    await _pump(tester, repo);
    expect(_stop, findsOneWidget);

    await tester.tap(_stop);
    await tester.pumpAndSettle();

    expect(repo.stops, 1);
    expect(_start, findsOneWidget);
  });

  testWidgets('TC-CAM-SYNC-10 bấm đúp khi đang gửi chỉ gửi một lệnh, nút khoá', (
    tester,
  ) async {
    final repo = _FakeRepo(_control())..hold = Completer();
    await _pump(tester, repo);

    await tester.tap(_start);
    await tester.pump();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(repo.starts, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repo.hold!.complete(repo.startResult);
    await tester.pumpAndSettle();
    expect(_stop, findsOneWidget);
  });

  testWidgets('TC-CAM-SYNC-11 403: ẩn nút và báo không có quyền', (tester) async {
    final repo = _FakeRepo(_control())..commandError = _http(403);
    await _pump(tester, repo);

    await tester.tap(_start);
    await tester.pumpAndSettle();

    expect(_start, findsNothing);
    expect(
      find.text(
        'Chỉ Ban tổ chức hoặc Trọng tài được phân công mới có quyền điều khiển trận này.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-CAM-SYNC-12 lỗi 5xx im lặng, nút vẫn còn; lỗi khác có thông báo', (
    tester,
  ) async {
    final repo = _FakeRepo(_control())..commandError = _http(500);
    await _pump(tester, repo);

    await tester.tap(_start);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(_start, findsOneWidget);

    repo.commandError = _http(422);
    await tester.tap(_start);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(_start, findsOneWidget);
  });

  testWidgets('TC-CAM-SYNC-13 PENDING cảnh báo ghi hình và làm mới playback', (
    tester,
  ) async {
    final repo = _FakeRepo(_control())
      ..startResult = const MatchStreamCommandResult(
        streamStatus: MatchStreamStatus.live,
        recordingStatus: MatchRecordingStatus.pending,
      );
    await _pump(tester, repo);
    final before = _playbackReads;

    await tester.tap(_start);
    await tester.pumpAndSettle();

    expect(
      find.text('Chưa xác nhận được trạng thái ghi hình; hệ thống sẽ tự thử lại.'),
      findsOneWidget,
    );
    expect(_playbackReads, greaterThan(before));
  });
}
