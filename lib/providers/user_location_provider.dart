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

  /// User từ chối (còn xin lại được).
  denied,

  /// User từ chối vĩnh viễn ("Không hỏi lại") — cần mở Settings.
  permanentlyDenied,

  /// Tắt dịch vụ vị trí ở cấp hệ thống.
  serviceDisabled,
}

/// Vị trí hiện tại của user. KHÔNG gửi lên server để lưu —
/// chỉ kèm theo query param khi lọc Social gần bạn.
class UserLocationState {
  final UserLocationStatus status;
  final double? latitude;
  final double? longitude;
  final String? message;

  const UserLocationState({
    this.status = UserLocationStatus.initial,
    this.latitude,
    this.longitude,
    this.message,
  });

  bool get hasPosition =>
      status == UserLocationStatus.granted &&
      latitude != null &&
      longitude != null;

  bool get isLoading => status == UserLocationStatus.loading;

  UserLocationState copyWith({
    UserLocationStatus? status,
    double? latitude,
    double? longitude,
    String? message,
  }) {
    return UserLocationState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      message: message,
    );
  }
}

class UserLocationNotifier extends Notifier<UserLocationState> {
  @override
  UserLocationState build() => const UserLocationState();

  /// Xin quyền khi user vào tab Social (đúng lúc cần — không xin khi mở app).
  /// Gọi 1 lần khi tab hiện; các lần sau dùng [refreshSilently] nếu đã granted.
  Future<void> requestWhenInUse() async {
    if (state.isLoading) return;
    if (state.hasPosition) {
      await refreshSilently();
      return;
    }
    state = state.copyWith(
      status: UserLocationStatus.loading,
      message: null,
    );

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        status: UserLocationStatus.serviceDisabled,
        message: 'Vui lòng bật Dịch vụ vị trí để tìm Social gần bạn.',
      );
      return;
    }

    final permission = await Permission.locationWhenInUse.request();
    if (permission.isGranted || permission.isLimited) {
      await _fetchPosition();
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
    if (!state.hasPosition) return;
    await _fetchPosition(silent: true);
  }

  Future<void> _fetchPosition({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(status: UserLocationStatus.loading);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      state = UserLocationState(
        status: UserLocationStatus.granted,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      await _fallbackToLastKnown('GPS phản hồi chậm — đang dùng vị trí gần nhất.');
    } catch (_) {
      await _fallbackToLastKnown('Không đọc được GPS — đang dùng vị trí gần nhất.');
    }
  }

  Future<void> _fallbackToLastKnown(String notice) async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        state = UserLocationState(
          status: UserLocationStatus.granted,
          latitude: last.latitude,
          longitude: last.longitude,
          message: notice,
        );
        return;
      }
    } catch (_) {
      // Bỏ qua — rớt xuống denied bên dưới.
    }
    state = state.copyWith(
      status: UserLocationStatus.denied,
      message: 'Không lấy được vị trí — đang hiện danh sách theo giờ.',
    );
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
