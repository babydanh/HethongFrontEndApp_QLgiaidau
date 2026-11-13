import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/match_recording_player_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake chỉ cần `getPlaylist`; ba hàm còn lại không dùng trong trình phát.
class _FakePlaylistRepository implements IMatchRecordingCatalogRepository {
  _FakePlaylistRepository(this._loadPlaylist, {this.days});

  final Future<MatchRecordingPlaylist> Function(String matchId, String period)
  _loadPlaylist;

  /// Ngày có bản ghi; null = không ai được gọi hàm này.
  final List<String>? days;
  final List<String> askedPeriods = <String>[];

  @override
  Future<MatchStreamCommandResult> startMatchStream(String matchId) async =>
      const MatchStreamCommandResult();

  @override
  Future<MatchStreamCommandResult> stopMatchStream(String matchId) async =>
      const MatchStreamCommandResult();

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

  @override
  Future<MatchRecordingPlaylist> getPlaylist(
    String matchId, {
    required String period,
  }) {
    askedPeriods.add(period);
    return _loadPlaylist(matchId, period);
  }

  @override
  Future<MatchStreamControlStateModel> getMatchControlState(String matchId) =>
      throw UnimplementedError('không dùng trong test trình phát');

  @override
  Future<MatchRecordingDaysModel> listRecordingDays(String matchId) async {
    final value = days;
    if (value == null) throw UnimplementedError('không truyền ngày');
    return MatchRecordingDaysModel(days: value);
  }

  @override
  Future<List<MatchRecordingFileModel>> listRecordings(
    String matchId, {
    required String period,
  }) => throw UnimplementedError('không dùng trong test trình phát');
}

MatchRecordingPlaylist _playlist(List<String> names) => MatchRecordingPlaylist(
  period: '2026-10-09',
  segments: <MatchRecordingSegment>[
    for (final name in names)
      MatchRecordingSegment(
        name: name,
        startAt: null,
        url: Uri.parse('https://media.example.test/$name'),
      ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  IMatchRecordingCatalogRepository repository, {
  String? period = '2026-10-09',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRecordingCatalogRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MatchRecordingPlayerSheet(
            matchId: 'match-player',
            period: period,
          ),
        ),
      ),
    ),
  );
  // Không dùng pumpAndSettle: spinner quay vô hạn trong lúc mở đoạn.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('mọi đoạn không phát được thì báo không phát được bản ghi nào', (
    tester,
  ) async {
    // Môi trường test không có plugin video: mở đoạn nào cũng lỗi.
    final repository = _FakePlaylistRepository(
      (matchId, period) async =>
          _playlist(<String>['part-01.mp4', 'part-02.mp4']),
    );

    await _pump(tester, repository);

    expect(find.text('Không phát được bản ghi nào'), findsOneWidget);
    expect(find.text('Đoạn này không phát được, đã bỏ qua.'), findsNWidgets(2));
  });

  testWidgets('danh sách rỗng báo ngày này không có đoạn phát lại', (
    tester,
  ) async {
    final repository = _FakePlaylistRepository(
      (matchId, period) async => _playlist(const <String>[]),
    );

    await _pump(tester, repository);

    expect(find.text('Ngày này không có đoạn phát lại.'), findsOneWidget);
  });

  testWidgets('lỗi tải danh sách hiện thông báo và nút thử lại', (
    tester,
  ) async {
    final repository = _FakePlaylistRepository(
      (matchId, period) async => throw StateError('mạng lỗi'),
    );

    await _pump(tester, repository);

    expect(find.text('Không tải được danh sách đoạn.'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets(
    'TC-REC-PLAYER-DAY-01 mở không kèm ngày thì tự lấy ngày gần nhất và có nút tải',
    (tester) async {
      final repository = _FakePlaylistRepository(
        (matchId, period) async => _playlist(const <String>[]),
        days: const <String>['2026-11-11', '2026-11-10'],
      );

      await _pump(tester, repository, period: null);

      expect(repository.askedPeriods, <String>['2026-11-11']);
      expect(find.text('2026-11-11'), findsOneWidget);
      expect(find.text('Tải video đầy đủ'), findsOneWidget);
    },
  );

  testWidgets('TC-REC-PLAYER-DAY-02 nhiều ngày thì chọn ngày khác để phát', (
    tester,
  ) async {
    final repository = _FakePlaylistRepository(
      (matchId, period) async => _playlist(const <String>[]),
      days: const <String>['2026-11-11', '2026-11-10'],
    );

    await _pump(tester, repository, period: null);
    await tester.tap(find.byKey(const ValueKey('recording-day-selector')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('2026-11-10').last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(repository.askedPeriods, <String>['2026-11-11', '2026-11-10']);
  });

  testWidgets(
    'TC-REC-PLAYER-DAY-03 không có ngày nào thì báo không có bản ghi, ẩn nút tải',
    (tester) async {
      final repository = _FakePlaylistRepository(
        (matchId, period) async => _playlist(const <String>[]),
        days: const <String>[],
      );

      await _pump(tester, repository, period: null);

      expect(
        find.text('Không tìm thấy ngày có bản ghi của trận này.'),
        findsOneWidget,
      );
      expect(find.text('Tải video đầy đủ'), findsNothing);
      expect(repository.askedPeriods, isEmpty);
    },
  );
}
