import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Trạng thái quyền/vị trí của user (chỉ dùng foreground).
enum UserLocationStatus {
  /// Chưa hỏi quyền lần nào trong phiên này.
  initial,

  /// Đang xin quyền / đang đọc GPS.
  loading,

  /// Đã có tọa độ (dùng được cho lọc "gần bạn").
  granted,

  /// A location chosen on the map; distance is approximate.
  selected,

  /// User từ chối (còn xin lại được).
  denied,

  /// User từ chối vĩnh viễn ("Không hỏi lại") — cần mở Settings.
  permanentlyDenied,

  /// Tắt dịch vụ vị trí ở cấp hệ thống.
  serviceDisabled,
  error,
}

/// Vị trí hiện tại của user. KHÔNG gửi lên server để lưu —
/// chỉ kèm theo query param khi lọc Social gần bạn.
class UserLocationState {
  final UserLocationStatus status;
  final double? latitude;
  final double? longitude;
  final String? message;
  final String? referenceSource;

  const UserLocationState({
    this.status = UserLocationStatus.initial,
    this.latitude,
    this.longitude,
    this.message,
    this.referenceSource,
  });

  bool get hasPosition =>
      (status == UserLocationStatus.granted ||
          status == UserLocationStatus.selected) &&
      latitude != null &&
      longitude != null;

  bool get isLoading => status == UserLocationStatus.loading;

  UserLocationState copyWith({
    UserLocationStatus? status,
    double? latitude,
    double? longitude,
    String? message,
    bool clearPosition = false,
    String? referenceSource,
  }) {
    return UserLocationState(
      status: status ?? this.status,
      latitude: clearPosition ? null : latitude ?? this.latitude,
      longitude: clearPosition ? null : longitude ?? this.longitude,
      message: message,
      referenceSource: referenceSource ?? this.referenceSource,
    );
  }
}

class UserLocationNotifier extends Notifier<UserLocationState> {
  int _generation = 0;
  @override
  UserLocationState build() => const UserLocationState();

  /// Xin quyền khi user vào tab Social (đúng lúc cần — không xin khi mở app).
  /// Gọi 1 lần khi tab hiện; các lần sau dùng [refreshSilently] nếu đã granted.
  Future<void> requestWhenInUse() async {
    if (state.isLoading || state.status == UserLocationStatus.selected) return;
    if (state.hasPosition) {
      await refreshSilently();
      return;
    }
    final generation = ++_generation;
    state = state.copyWith(
      status: UserLocationStatus.loading,
      message: null,
      clearPosition: true,
    );

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (generation != _generation) return;
    if (!serviceEnabled) {
      state = state.copyWith(
        status: UserLocationStatus.serviceDisabled,
        message: 'Vui lòng bật Dịch vụ vị trí để tìm Social gần bạn.',
      );
      return;
    }

    final permission = await Permission.locationWhenInUse.request();
    if (generation != _generation) return;
    if (permission.isGranted || permission.isLimited) {
      await _fetchPosition(generation: generation);
    } else if (permission.isPermanentlyDenied || permission.isRestricted) {
      state = state.copyWith(
        status: UserLocationStatus.permanentlyDenied,
        message: 'Bạn đã tắt quyền vị trí. Mở Cài đặt để bật lại.',
      );
    } else {
      state = state.copyWith(
        status: UserLocationStatus.denied,
        message: 'Chưa có quyền vị trí — đang hiện danh sách theo giờ.',
      );
    }
  }

  /// Đọc lại GPS im lặng (không hiện loading). Chỉ gọi khi đã granted.
  Future<void> refreshSilently() async {
    if (state.status != UserLocationStatus.granted || !state.hasPosition) {
      return;
    }
    await _fetchPosition(silent: true, generation: ++_generation);
  }

  Future<void> _fetchPosition({
    bool silent = false,
    required int generation,
  }) async {
    if (!silent) {
      state = state.copyWith(status: UserLocationStatus.loading);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      if (generation != _generation ||
          state.status == UserLocationStatus.selected) {
        return;
      }
      state = UserLocationState(
        status: UserLocationStatus.granted,
        latitude: position.latitude,
        longitude: position.longitude,
        referenceSource: 'gps',
      );
    } on TimeoutException {
      if (generation == _generation) {
        await _fallbackToLastKnown(
          'GPS phản hồi chậm — đang dùng vị trí gần nhất.',
          generation,
        );
      }
    } catch (_) {
      if (generation == _generation) {
        await _fallbackToLastKnown(
          'Không đọc được GPS — đang dùng vị trí gần nhất.',
          generation,
        );
      }
    }
  }

  Future<void> _fallbackToLastKnown(String notice, int generation) async {
    try {
      final permission = await Permission.locationWhenInUse.status;
      if (generation != _generation) return;
      if (!permission.isGranted) {
        state = UserLocationState(
          status: UserLocationStatus.denied,
          message: 'Quyền vị trí không còn được cấp.',
        );
        return;
      }
      final last = await Geolocator.getLastKnownPosition();
      if (generation != _generation) return;
      if (last != null) {
        state = UserLocationState(
          status: UserLocationStatus.granted,
          latitude: last.latitude,
          longitude: last.longitude,
          message: notice,
          referenceSource: 'gps_last_known',
        );
        return;
      }
    } catch (_) {
      // Bỏ qua — rớt xuống denied bên dưới.
    }
    state = state.copyWith(
      status: UserLocationStatus.error,
      clearPosition: true,
      message: 'Không lấy được vị trí — đang hiện danh sách theo giờ.',
    );
  }

  void useSelectedPosition(
    double latitude,
    double longitude, {
    String source = 'manual',
  }) {
    _generation++;
    state = UserLocationState(
      status: UserLocationStatus.selected,
      latitude: latitude,
      longitude: longitude,
      message: 'Vị trí đã chọn (ước lượng).',
      referenceSource: source,
    );
  }

  /// Explicit map action always reads the device, even after a saved place was selected.
  Future<void> useCurrentPosition() async {
    _generation++;
    state = const UserLocationState();
    await requestWhenInUse();
  }

  /// Mở Settings hệ thống (dùng khi permanentlyDenied / serviceDisabled).
  Future<void> openSystemSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Mở Cài đặt ứng dụng (dùng khi permanentlyDenied).
  Future<void> openAppLocationSettings() async {
    await openAppSettings();
  }
}

final userLocationProvider =
    NotifierProvider<UserLocationNotifier, UserLocationState>(
      UserLocationNotifier.new,
    );
