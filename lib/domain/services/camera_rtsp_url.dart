/// Builds the RTSP address of an IP camera on the venue network, and scrubs
/// the credentials out of any text that may contain it. Pure.
library;

enum CameraBrand { dahua, hikvision }

/// RTSP URL of one camera stream. [user] and [password] are percent-encoded so
/// characters such as `@`, `:` or `/` cannot break the userinfo part.
///
/// Throws [ArgumentError] on a blank [host] or a [port] outside 1..65535.
String buildCameraRtspUrl({
  required CameraBrand brand,
  required String host,
  required int port,
  required String user,
  required String password,
  required bool mainStream,
}) {
  final cleanHost = host.trim();
  if (cleanHost.isEmpty) {
    throw ArgumentError.value(host, 'host', 'must not be blank');
  }
  if (port < 1 || port > 65535) {
    throw ArgumentError.value(port, 'port', 'must be 1..65535');
  }

  final path = switch (brand) {
    CameraBrand.dahua =>
      '/cam/realmonitor?channel=1&subtype=${mainStream ? 0 : 1}',
    CameraBrand.hikvision => '/Streaming/Channels/${mainStream ? 101 : 102}',
  };
  final credentials =
      '${Uri.encodeComponent(user)}:${Uri.encodeComponent(password)}';
  return 'rtsp://$credentials@$cleanHost:$port$path';
}

final RegExp _rtspUserInfo = RegExp(r'rtsp://[^/@\s]+@');

/// Replaces the `user:password@` part of every RTSP URL in [text] with `***@`.
/// FFmpeg echoes the input URL in its own log lines, so run its output through
/// this before it reaches a log or an error message.
String redactRtspCredentials(String text) =>
    text.replaceAll(_rtspUserInfo, 'rtsp://***@');
