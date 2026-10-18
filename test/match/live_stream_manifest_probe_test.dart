import 'dart:async';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/features/match/widgets/live_stream_stats_badge.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _manifestUrl = 'https://cdn.example.test/live/index.m3u8';

/// Trả manifest theo từng khối, không ra mạng. [hang] giữ phản hồi mãi mãi để
/// kiểm tra timeout.
class _ManifestAdapter implements HttpClientAdapter {
  _ManifestAdapter(this._chunks, {this.hang = false});

  final List<List<int>> _chunks;
  final bool hang;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (hang) {
      await Completer<void>().future;
    }
    return ResponseBody(
      Stream<Uint8List>.fromIterable(_chunks.map(Uint8List.fromList)),
      200,
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_ManifestAdapter adapter) => Dio()..httpClientAdapter = adapter;

void main() {
  test('manifest nhỏ: trả thời gian đo, không null', () async {
    final dio = _dioWith(
      _ManifestAdapter(<List<int>>['#EXTM3U\n#EXT-X-VERSION:3\n'.codeUnits]),
    );

    final ping = await measureManifestPingMs(dio, _manifestUrl);

    expect(ping, isNotNull);
    expect(ping, greaterThanOrEqualTo(0));
  });

  test('manifest đúng bằng 64 KB vẫn đo được', () async {
    const chunkSize = 16 * 1024;
    final chunk = List<int>.filled(chunkSize, 0x23);
    final dio = _dioWith(
      _ManifestAdapter(<List<int>>[chunk, chunk, chunk, chunk]),
    );

    final ping = await measureManifestPingMs(dio, _manifestUrl);

    expect(ping, isNotNull);
  });

  test('manifest vượt 64 KB: huỷ đọc và trả null', () async {
    const chunkSize = 32 * 1024;
    final chunk = List<int>.filled(chunkSize, 0x23);
    final dio = _dioWith(
      _ManifestAdapter(<List<int>>[chunk, chunk, chunk, chunk]),
    );

    final ping = await measureManifestPingMs(dio, _manifestUrl);

    expect(ping, isNull);
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('quá 4 giây không có phản hồi: huỷ và trả null', () async {
    final dio = _dioWith(_ManifestAdapter(const <List<int>>[], hang: true));

    final ping = await measureManifestPingMs(dio, _manifestUrl);

    expect(ping, isNull);
  }, timeout: const Timeout(Duration(seconds: 15)));
}
