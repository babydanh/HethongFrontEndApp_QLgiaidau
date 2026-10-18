import 'package:app_quanly_giaidau/features/match/widgets/live_stream_stats_badge.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Đếm số lần đo Ping. Không ra mạng.
class _ProbeSpy {
  _ProbeSpy({required this.result});

  final int? result;
  int calls = 0;

  Future<int?> call(Dio dio, String url) async {
    calls++;
    return result;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required String url,
  required _ProbeSpy probe,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [liveStreamPingProbeProvider.overrideWithValue(probe.call)],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LiveStreamStatsBadge(url: url)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('luồng HTTP-FLV không gọi mạng để đo Ping, Ping hiện —', (
    tester,
  ) async {
    final probe = _ProbeSpy(result: 42);

    await _pump(
      tester,
      url: 'https://cdn.example.test/live/stream.flv',
      probe: probe,
    );
    // Vượt quá chu kỳ đo Ping (5 giây): vẫn không được gọi.
    await tester.pump(const Duration(seconds: 12));

    expect(probe.calls, 0);
    expect(find.text('Ping —'), findsOneWidget);
  });

  testWidgets('manifest HLS .m3u8: đo Ping và hiện số ms', (tester) async {
    final probe = _ProbeSpy(result: 42);

    await _pump(
      tester,
      url: 'https://cdn.example.test/live/index.m3u8?token=abc',
      probe: probe,
    );

    expect(probe.calls, greaterThan(0));
    expect(find.text('Ping 42 ms'), findsOneWidget);
  });

  testWidgets('đo Ping thất bại thì Ping hiện —', (tester) async {
    final probe = _ProbeSpy(result: null);

    await _pump(
      tester,
      url: 'https://cdn.example.test/live/index.m3u8',
      probe: probe,
    );

    expect(probe.calls, greaterThan(0));
    expect(find.text('Ping —'), findsOneWidget);
  });
}
