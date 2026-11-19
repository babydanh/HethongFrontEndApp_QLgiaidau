/// Larix Broadcaster "Grove" setup link: opening it lets Larix import an RTMP
/// connection without typing the long stream key. The key rides inside the URL
/// path, so the whole link is as secret as the key.
/// Format: https://softvelum.com/larix/grove/
String? buildLarixSetupUrl(String rtmpUrl, String streamKey, String name) {
  final plain = buildPlainRtmpUrl(rtmpUrl, streamKey);
  if (plain == null) return null;
  final enc = Uri.encodeComponent;
  return 'larix://set/v1?conn[][url]=${enc(plain)}'
      '&conn[][name]=${enc(name)}&conn[][overwrite]=on&conn[][active]=on';
}

/// Plain `rtmp(s)://server/app/key` text. As a QR code any scanner can read it;
/// whether the scanning app can publish to it is up to that app. Same secrecy as the key.
String? buildPlainRtmpUrl(String rtmpUrl, String streamKey) {
  final server = rtmpUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  final key = streamKey.trim();
  if (server.isEmpty || key.isEmpty) return null;
  return '$server/$key';
}
