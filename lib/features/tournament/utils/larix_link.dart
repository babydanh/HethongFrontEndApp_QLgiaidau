/// Larix Broadcaster "Grove" setup link: opening it lets Larix import an RTMP
/// connection without typing the long stream key. The key rides inside the URL
/// path, so the whole link is as secret as the key.
/// Format: https://softvelum.com/larix/grove/
String? buildLarixSetupUrl(String rtmpUrl, String streamKey, String name) {
  final server = rtmpUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  final key = streamKey.trim();
  if (server.isEmpty || key.isEmpty) return null;
  final enc = Uri.encodeComponent;
  return 'larix://set/v1?conn[][url]=${enc('$server/$key')}'
      '&conn[][name]=${enc(name)}&conn[][overwrite]=on&conn[][active]=on';
}
