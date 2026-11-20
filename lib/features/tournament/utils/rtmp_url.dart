/// Plain `rtmp(s)://server/app/key` text. As a QR code any scanner can read it;
/// whether the scanning app can publish to it is up to that app. Same secrecy as the key.
String? buildPlainRtmpUrl(String rtmpUrl, String streamKey) {
  final server = rtmpUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  final key = streamKey.trim();
  if (server.isEmpty || key.isEmpty) return null;
  return '$server/$key';
}
