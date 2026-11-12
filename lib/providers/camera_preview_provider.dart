import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Camera ids whose preview the user switched off on THIS device.
///
/// Purely local: turning a preview off only stops the picture being played
/// here. Nothing is sent to the Backend and the camera keeps streaming.
class CameraPreviewOffNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  bool isOn(String cameraId) => !state.contains(cameraId);

  void toggle(String cameraId) {
    state = state.contains(cameraId)
        ? ({...state}..remove(cameraId))
        : {...state, cameraId};
  }
}

final cameraPreviewOffProvider =
    NotifierProvider<CameraPreviewOffNotifier, Set<String>>(
      CameraPreviewOffNotifier.new,
    );
