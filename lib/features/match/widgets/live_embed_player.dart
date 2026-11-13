import 'dart:convert' show HtmlEscape, HtmlEscapeMode;

import 'package:app_quanly_giaidau/features/match/utils/live_embed.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Origin giả lập cho trang chứa iframe: YouTube từ chối phát (lỗi 153) khi
/// khung nhúng không có Referer, nên HTML được nạp với baseUrl này.
const _embedBaseUrl = 'https://sporto.asia';

/// Chỉ cho WebView ở lại trang nhúng hoặc chính hai nền tảng; chạm vào link
/// ra ngoài trong khung phát không được kéo cả WebView đi nơi khác.
bool isEmbedNavigationAllowed(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (url == 'about:blank' || url.startsWith(_embedBaseUrl)) return true;
  if (uri.scheme != 'https') return false;
  const hosts = {
    'www.youtube.com',
    'www.youtube-nocookie.com',
    'www.facebook.com',
    'web.facebook.com',
    'm.facebook.com',
    'static.xx.fbcdn.net',
  };
  return hosts.contains(uri.host);
}

/// Khung phát live YouTube/Facebook bằng WebView (đã có sẵn `webview_flutter`).
/// `embed.embedUrl` do [LiveEmbed.parse] dựng, không bao giờ là chuỗi người
/// dùng nhập, nên HTML dưới đây chỉ chứa URL đã kiểm.
class LiveEmbedPlayer extends StatefulWidget {
  const LiveEmbedPlayer({super.key, required this.embed, this.fill = false});

  final LiveEmbedResult embed;

  /// Lấp hết chiều cao khung cha thay vì ép tỉ lệ 16:9.
  final bool fill;

  @override
  State<LiveEmbedPlayer> createState() => _LiveEmbedPlayerState();
}

class _LiveEmbedPlayerState extends State<LiveEmbedPlayer> {
  late final WebViewController _controller;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              isEmbedNavigationAllowed(request.url)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageFinished: (_) {
            if (mounted) setState(() => _loaded = true);
          },
        ),
      );
    _load();
  }

  @override
  void didUpdateWidget(LiveEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embed.embedUrl != widget.embed.embedUrl) {
      setState(() => _loaded = false);
      _load();
    }
  }

  void _load() {
    final src = widget.embed.embedUrl;
    if (src == null) return;
    final autoplay = widget.embed.platform == LiveEmbedPlatform.youtube
        ? '$src?autoplay=1&mute=1&playsinline=1&rel=0'
        : '$src&autoplay=true&mute=true';
    final escaped = const HtmlEscape(
      HtmlEscapeMode.attribute,
    ).convert(autoplay);
    _controller.loadHtmlString(
      '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">'
      '<style>html,body{margin:0;height:100%;background:#000}iframe{border:0;width:100%;height:100%}</style></head>'
      '<body><iframe src="$escaped" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe></body></html>',
      baseUrl: _embedBaseUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (!_loaded)
          const ColoredBox(
            key: ValueKey('live-embed-loading'),
            color: Colors.black,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
    return widget.fill ? body : AspectRatio(aspectRatio: 16 / 9, child: body);
  }
}
