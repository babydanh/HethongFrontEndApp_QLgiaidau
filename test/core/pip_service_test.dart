import 'package:app_quanly_giaidau/core/services/pip_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel(PipService.channelName);

void _mock(Future<Object?>? Function(MethodCall call)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

/// What the Android activity does: sends 'pipChanged' to Dart.
Future<void> _nativePipChanged(bool inPip) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        _channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('pipChanged', inPip),
        ),
        (_) {},
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mock(null));

  test('TC-PIP-01 isSupported follows the native answer on Android', () async {
    _mock((call) async => call.method == 'isSupported' ? true : null);

    expect(await PipService(isAndroid: true).isSupported(), isTrue);

    _mock((call) async => false);
    expect(await PipService(isAndroid: true).isSupported(), isFalse);
  });

  test('TC-PIP-02 not supported off Android, native is never asked', () async {
    var asked = 0;
    _mock((call) async {
      asked++;
      return true;
    });
    final service = PipService(isAndroid: false);

    expect(await service.isSupported(), isFalse);
    expect(await service.enter(), isFalse);
    expect(asked, 0);
  });

  test(
    'TC-PIP-03 a missing native handler means unsupported, no throw',
    () async {
      _mock(null);
      final service = PipService(isAndroid: true);

      expect(await service.isSupported(), isFalse);
      expect(await service.enter(), isFalse);
    },
  );

  test('TC-PIP-04 enter returns what native says (true then false)', () async {
    final answers = [true, false];
    _mock((call) async => call.method == 'enter' ? answers.removeAt(0) : null);
    final service = PipService(isAndroid: true);

    expect(await service.enter(), isTrue);
    expect(await service.enter(), isFalse);
  });

  test('TC-PIP-05 a failing enter is false, not an exception', () async {
    _mock((call) async => throw PlatformException(code: 'boom'));

    expect(await PipService(isAndroid: true).enter(), isFalse);
  });

  test('TC-PIP-06 pipChanged from native flips the active flag', () async {
    final service = PipService(isAndroid: true);
    final seen = <bool>[];
    service.active.addListener(() => seen.add(service.active.value));

    await _nativePipChanged(true);
    expect(service.active.value, isTrue);
    await _nativePipChanged(false);
    expect(service.active.value, isFalse);
    expect(seen, [true, false]);
  });
}
