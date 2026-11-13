/// Nhận diện link live YouTube/Facebook của camera sân. Host so khớp CHÍNH XÁC
/// (không endsWith) để `youtube.com.evil.com` không lọt; `embedUrl` luôn dựng từ
/// id/URL đã tách, không bao giờ từ chuỗi người dùng nhập. Cùng quy tắc với
/// `web/src/lib/live-embed.ts` và Backend `live-embed-url.ts`.
enum LiveEmbedPlatform { youtube, facebook }

enum LiveEmbedError { notEmbed, channelPage, noVideoId }

class LiveEmbedResult {
  const LiveEmbedResult._({
    this.platform,
    this.canonicalUrl,
    this.embedUrl,
    this.error,
  });

  const LiveEmbedResult.ok({
    required LiveEmbedPlatform platform,
    required String canonicalUrl,
    required String embedUrl,
  }) : this._(
         platform: platform,
         canonicalUrl: canonicalUrl,
         embedUrl: embedUrl,
       );

  const LiveEmbedResult.failure(LiveEmbedError error) : this._(error: error);

  final LiveEmbedPlatform? platform;
  final String? canonicalUrl;
  final String? embedUrl;
  final LiveEmbedError? error;

  bool get isOk => error == null;
}

abstract final class LiveEmbed {
  static const _youtubeHosts = {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'youtu.be',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
  };
  static const _facebookHosts = {
    'facebook.com',
    'www.facebook.com',
    'm.facebook.com',
    'web.facebook.com',
    'fb.watch',
  };
  static final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final _numericId = RegExp(r'^\d{5,}$');
  static final _shortCode = RegExp(r'^[A-Za-z0-9_-]{4,}$');
  static final _pageName = RegExp(r'^[\w.-]+$');

  static const _notEmbed = LiveEmbedResult.failure(LiveEmbedError.notEmbed);
  static const _channelPage = LiveEmbedResult.failure(
    LiveEmbedError.channelPage,
  );
  static const _noVideoId = LiveEmbedResult.failure(LiveEmbedError.noVideoId);

  static LiveEmbedResult parse(String? raw) {
    final uri = Uri.tryParse((raw ?? '').trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.host.isEmpty) {
      return _notEmbed;
    }
    final host = uri.host.toLowerCase();
    if (_youtubeHosts.contains(host)) return _youtube(host, uri);
    if (_facebookHosts.contains(host)) return _facebook(host, uri);
    return _notEmbed;
  }

  static LiveEmbedResult _youtube(String host, Uri uri) {
    final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    final String? id;
    if (host == 'youtu.be') {
      id = parts.isEmpty ? null : parts[0];
    } else if (parts.isNotEmpty && parts[0] == 'watch') {
      id = uri.queryParameters['v'];
    } else if (parts.isNotEmpty &&
        const ['live', 'embed', 'shorts'].contains(parts[0])) {
      id = parts.length > 1 ? parts[1] : null;
    } else {
      return _channelPage;
    }
    if (id == null || !_youtubeId.hasMatch(id)) return _noVideoId;
    return LiveEmbedResult.ok(
      platform: LiveEmbedPlatform.youtube,
      canonicalUrl: 'https://www.youtube.com/watch?v=$id',
      embedUrl: 'https://www.youtube.com/embed/$id',
    );
  }

  static LiveEmbedResult _facebook(String host, Uri uri) {
    final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    String? part(int i) => i < parts.length ? parts[i] : null;
    String? canonical;
    if (host == 'fb.watch') {
      final code = part(0);
      if (code != null && _shortCode.hasMatch(code)) {
        canonical = 'https://fb.watch/$code/';
      }
    } else if (part(0) == 'watch' || part(0) == 'video.php') {
      final v = uri.queryParameters['v'];
      if (v != null && _numericId.hasMatch(v)) {
        canonical = 'https://www.facebook.com/watch/?v=$v';
      }
    } else if (part(0) == 'reel' &&
        part(1) != null &&
        _numericId.hasMatch(part(1)!)) {
      canonical = 'https://www.facebook.com/reel/${part(1)}';
    } else if (part(0) == 'share' &&
        const ['v', 'r', 'p'].contains(part(1)) &&
        part(2) != null &&
        _shortCode.hasMatch(part(2)!)) {
      canonical = 'https://www.facebook.com/share/${part(1)}/${part(2)}/';
    } else if (part(1) == 'videos' &&
        part(2) != null &&
        _numericId.hasMatch(part(2)!) &&
        _pageName.hasMatch(part(0)!)) {
      canonical = 'https://www.facebook.com/${part(0)}/videos/${part(2)}';
    }
    if (canonical == null) return _channelPage;
    return LiveEmbedResult.ok(
      platform: LiveEmbedPlatform.facebook,
      canonicalUrl: canonical,
      embedUrl:
          'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(canonical)}&show_text=false',
    );
  }
}
