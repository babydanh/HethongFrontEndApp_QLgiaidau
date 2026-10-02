import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

/// Disk-backed HTTP cache for visible Social map tiles only.
///
/// The file service honors Cache-Control, Expires, and ETag response headers,
/// with a one-week fallback when freshness headers are absent. The cache key
/// is the tile URL (z/x/y plus the configured tile host); it never prefetches.
class SocialMapTileProvider extends TileProvider {
  SocialMapTileProvider() : super();

  static final CacheManager _cache = CacheManager(
    Config(
      'sporto_social_map_tiles_v1',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 10000,
      fileService: _SocialTileFileService(),
    ),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _CachedSocialTileImageProvider(
      url: getTileUrl(coordinates, options),
      cache: _cache,
      headers: headers,
    );
  }
}

/// Reads the OSM response headers so `Expires` is honored when Cache-Control
/// is absent. Cache-Control and ETag are kept for normal cache revalidation;
/// responses without either freshness header fall back to seven days.
class _SocialTileFileService extends FileService {
  static final HttpClient _client = HttpClient();

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final request = await _client.getUrl(Uri.parse(url));
    headers?.forEach(request.headers.set);
    final response = await request.close();
    return _SocialTileFileServiceResponse(response, DateTime.now());
  }
}

class _SocialTileFileServiceResponse implements FileServiceResponse {
  _SocialTileFileServiceResponse(this._response, this._receivedAt);

  final HttpClientResponse _response;
  final DateTime _receivedAt;

  @override
  Stream<List<int>> get content => _response;

  @override
  int? get contentLength => _response.contentLength;

  @override
  int get statusCode => _response.statusCode;

  @override
  String? get eTag => _header(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    final contentType = _header(HttpHeaders.contentTypeHeader);
    if (contentType == null) return '';
    final subtype = ContentType.parse(contentType).subType.toLowerCase();
    return switch (subtype) {
      'jpeg' || 'pjpeg' => '.jpg',
      'png' => '.png',
      'webp' => '.webp',
      'gif' => '.gif',
      'bmp' => '.bmp',
      'svg+xml' => '.svg',
      _ => '',
    };
  }

  @override
  DateTime get validTill {
    final cacheControl = _header(HttpHeaders.cacheControlHeader);
    Duration? maxAge;
    if (cacheControl != null) {
      for (final directive in cacheControl.split(',')) {
        final normalized = directive.trim().toLowerCase();
        if (normalized == 'no-cache') return _receivedAt;
        if (normalized.startsWith('max-age=')) {
          final seconds = int.tryParse(normalized.substring(8)) ?? 0;
          maxAge = Duration(seconds: seconds < 0 ? 0 : seconds);
        }
      }
      if (maxAge != null) return _receivedAt.add(maxAge);
    }

    final expires = _header(HttpHeaders.expiresHeader);
    if (expires != null) {
      try {
        return HttpDate.parse(expires);
      } on FormatException {
        // An invalid Expires header falls back to the documented cache TTL.
      }
    }
    return _receivedAt.add(const Duration(days: 7));
  }

  String? _header(String name) => _response.headers.value(name);
}

class _CachedSocialTileImageProvider
    extends ImageProvider<_CachedSocialTileImageProvider> {
  const _CachedSocialTileImageProvider({
    required this.url,
    required this.cache,
    required this.headers,
  });

  final String url;
  final CacheManager cache;
  final Map<String, String> headers;

  @override
  ImageStreamCompleter loadImage(
    _CachedSocialTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode),
      scale: 1,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _load(
    _CachedSocialTileImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final response = await key.cache
        .getFileStream(key.url, headers: key.headers, withProgress: false)
        .where((event) => event is FileInfo)
        .cast<FileInfo>()
        .first;
    final bytes = await response.file.readAsBytes();
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  SynchronousFuture<_CachedSocialTileImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CachedSocialTileImageProvider && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
