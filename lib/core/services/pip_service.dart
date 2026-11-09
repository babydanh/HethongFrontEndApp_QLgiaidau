import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Picture-in-picture (small floating window) for the video pages.
///
/// Android only: the native side lives in `MainActivity.kt`. Anywhere else, or
/// when the device switched the feature off, [isSupported] is false and the
/// players hide their button.
class PipService {
  PipService({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? const MethodChannel(channelName),
      _isAndroid =
          isAndroid ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    if (_isAndroid) _channel.setMethodCallHandler(_onNativeCall);
  }

  static const channelName = 'vn.vnsport.quanlygiaidau/pip';

  /// The one instance the app uses (one native channel, one handler).
  static final instance = PipService();

  final MethodChannel _channel;
  final bool _isAndroid;

  /// True while the activity is shown in the small window.
  final ValueNotifier<bool> active = ValueNotifier(false);

  Future<bool> isSupported() => _ask('isSupported');

  /// Opens the small window; false when it could not open.
  Future<bool> enter() => _ask('enter');

  Future<bool> _ask(String method) async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method == 'pipChanged') active.value = call.arguments == true;
  }
}
