import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_live_session_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/live_session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final liveSessionRepositoryProvider = Provider<ILiveSessionRepository>((ref) {
  return ApiLiveSessionRepository(ref.watch(dioClientProvider));
});

final cameraDevicesProvider = FutureProvider.autoDispose
    .family<List<CameraDeviceModel>, String>((ref, communityId) async {
  return ref.read(liveSessionRepositoryProvider).listDevices(communityId);
});
