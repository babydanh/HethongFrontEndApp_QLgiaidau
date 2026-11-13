import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/recording_access.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/match_recording_player_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/match_stream_actions.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAM-SYNC-18..26: nút Bắt đầu/Dừng/Xem bản ghi trên thẻ trận.
const _tid = 'tour-1';
const _mid = 'match-1';

DioException _http(int status) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

class _Repo implements IMatchRecordingCatalogRepository {
  List<MatchLivestreamSummary> rows = const [];
  Object? listError;
  Object? commandError;
  MatchStreamCommandResult startResult = const MatchStreamCommandResult(
    streamStatus: MatchStreamStatus.live,
  );
  int starts = 0;
  int stops = 0;
  int lists = 0;

  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) async {
    lists++;
    if (listError != null) throw listError!;
    return rows;
  }

  @override
  Future<MatchStreamCommandResult> startMatchStream(String matchId) async {
    starts++;
    if (commandError != null) throw commandError!;
    return startResult;
  }

  @override
  Future<MatchStreamCommandResult> stopMatchStream(String matchId) async {
    stops++;
    if (commandError != null) throw commandError!;
    return const MatchStreamCommandResult(streamStatus: MatchStreamStatus.idle);
  }

  @override
  Future<MatchStreamControlStateModel> getMatchControlState(String matchId) async =>
      MatchStreamControlStateModel(matchId: matchId, hasCamera: true);

  @override
  Future<MatchRecordingDaysModel> listRecordingDays(String matchId) async =>
      MatchRecordingDaysModel(days: const []);

  @override
  Future<List<MatchRecordingFileModel>> listRecordings(
    String matchId, {
    required String period,
  }) async => const [];

  @override
  Future<MatchRecordingPlaylist> getPlaylist(
    String matchId, {
    required String period,
  }) async => MatchRecordingPlaylist(period: period, segments: const []);

  @override
  Future<void> downloadFullRecording(
    String matchId, {
    required String period,
    required String savePath,
  }) async {}
}

Future<void> _pump(
  WidgetTester tester,
  _Repo repo, {
  bool hasCamera = true,
  bool readOnly = false,
  double width = 360,
  String label = 'Đội A rất dài – Đội B cũng rất dài',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRecordingCatalogRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: MatchStreamActions(
              tournamentId: _tid,
              matchId: _mid,
              matchLabel: label,
              hasCamera: hasCamera,
              readOnly: readOnly,
              onWatchLive: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _start => find.widgetWithText(OutlinedButton, 'Bắt đầu');
Finder get _stop => find.widgetWithText(OutlinedButton, 'Dừng');
Finder get _mp4 => find.widgetWithText(OutlinedButton, 'MP4');

MatchLivestreamSummary _row({
  MatchStreamStatus? status = MatchStreamStatus.idle,
  bool hasRecording = false,
  String? cameraId,
}) => MatchLivestreamSummary(
  matchId: _mid,
  cameraId: cameraId,
  streamStatus: status,
  hasRecording: hasRecording,
);

void main() {
  test('TC-CAM-SYNC-18 canShowRecordingButton = hasCamera hoặc hasRecording đúng true', () {
    expect(canShowRecordingButton(hasCamera: true), isTrue);
    expect(canShowRecordingButton(hasCamera: false, hasRecording: true), isTrue);
    expect(canShowRecordingButton(hasCamera: false, hasRecording: false), isFalse);
    expect(canShowRecordingButton(hasCamera: false, hasRecording: null), isFalse);
    expect(canShowRecordingButton(hasCamera: false), isFalse);
  });

  testWidgets('TC-CAM-SYNC-19 chưa camera: Bắt đầu bị khoá kèm gợi ý, không có MP4', (
    tester,
  ) async {
    await _pump(tester, _Repo(), hasCamera: false);

    expect(tester.widget<OutlinedButton>(_start).onPressed, isNull);
    expect(find.byTooltip('Sân này chưa khai URL camera'), findsOneWidget);
    expect(_mp4, findsNothing);
    expect(_stop, findsNothing);
  });

  testWidgets('TC-CAM-SYNC-20 start kiểu PULL: gọi start, báo URL của sân, tải lại danh sách', (
    tester,
  ) async {
    final repo = _Repo();
    await _pump(tester, repo);
    final listsBefore = repo.lists;
    expect(tester.getSize(_start).height, greaterThanOrEqualTo(44));

    await tester.tap(_start);
    await tester.pumpAndSettle();

    expect(repo.starts, 1);
    expect(find.text('Đã bắt đầu phát từ URL của sân.'), findsOneWidget);
    expect(repo.lists, greaterThan(listsBefore));
  });

  testWidgets('TC-CAM-SYNC-21 start có publish: sao chép liên kết và báo đã tạo', (
    tester,
  ) async {
    final clipboard = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String);
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
    final repo = _Repo()
      ..startResult = const MatchStreamCommandResult(
        streamStatus: MatchStreamStatus.live,
        publishUrl: 'rtmp://ingest/x',
      );
    await _pump(tester, repo);

    await tester.tap(_start);
    await tester.pumpAndSettle();

    expect(clipboard, <String>['rtmp://ingest/x']);
    expect(find.textContaining('Đã tạo link bắt đầu phát'), findsOneWidget);
  });

  testWidgets('TC-CAM-SYNC-22 đang LIVE: có Dừng, ẩn MP4; Dừng gọi stop và báo đã tắt', (
    tester,
  ) async {
    final repo = _Repo()
      ..rows = [_row(status: MatchStreamStatus.live, hasRecording: true)];
    await _pump(tester, repo);

    expect(_stop, findsOneWidget);
    expect(_start, findsNothing);
    expect(_mp4, findsNothing);

    await tester.tap(_stop);
    await tester.pumpAndSettle();

    expect(repo.stops, 1);
    expect(find.textContaining('Đã tắt phát trực tiếp'), findsOneWidget);
  });

  testWidgets('TC-CAM-SYNC-23 đã có bản ghi, camera đã gỡ: MP4 hiện và mở thẳng trình phát bản ghi', (
    tester,
  ) async {
    final repo = _Repo()..rows = [_row(hasRecording: true)];
    await _pump(tester, repo, hasCamera: false);

    expect(_mp4, findsOneWidget);
    expect(tester.getSize(_mp4).height, greaterThanOrEqualTo(44));
    await tester.tap(_mp4);
    await tester.pumpAndSettle();

    expect(find.byType(MatchRecordingPlayerSheet), findsOneWidget);
  });

  testWidgets('TC-CAM-SYNC-24 lỗi tải danh sách: thẻ vẫn hiện, nút theo hasCamera', (
    tester,
  ) async {
    final repo = _Repo()..listError = _http(500);
    await _pump(tester, repo);

    expect(tester.takeException(), isNull);
    expect(tester.widget<OutlinedButton>(_start).onPressed, isNotNull);
    expect(_mp4, findsOneWidget);
  });

  testWidgets('TC-CAM-SYNC-25 403 báo không có quyền; PENDING cảnh báo ghi hình', (
    tester,
  ) async {
    final repo = _Repo()..commandError = _http(403);
    await _pump(tester, repo);
    await tester.tap(_start);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chỉ Ban tổ chức hoặc Trọng tài'), findsOneWidget);

    final pending = _Repo()
      ..startResult = const MatchStreamCommandResult(
        streamStatus: MatchStreamStatus.live,
        recordingStatus: MatchRecordingStatus.pending,
      );
    await _pump(tester, pending);
    await tester.tap(_start);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa xác nhận được trạng thái ghi hình'), findsOneWidget);
  });

  testWidgets('TC-CAM-SYNC-26 giải chỉ-đọc: không có Bắt đầu/Dừng nhưng vẫn xem live và MP4', (
    tester,
  ) async {
    await _pump(tester, _Repo(), readOnly: true);

    expect(_start, findsNothing);
    expect(_stop, findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Xem live'), findsOneWidget);
    expect(_mp4, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
