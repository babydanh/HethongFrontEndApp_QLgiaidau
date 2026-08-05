import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';

/// Quận/Huyện thuộc một Tỉnh/Thành (theo chuẩn bảng `districts`).
class District {
  final String code;
  final String name;
  final String provinceCode;

  District({required this.code, required this.name, required this.provinceCode});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      provinceCode: json['provinceCode']?.toString() ?? '',
    );
  }
}

/// Danh sách Quận/Huyện theo mã tỉnh — GET /regions/districts?provinceCode=...
final districtsProvider =
    FutureProvider.family<List<District>, String>((ref, provinceCode) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      '/regions/districts',
      queryParameters: {'provinceCode': provinceCode},
    );
    final raw = response.data;
    final List<dynamic> dataList = raw is Map<String, dynamic>
        ? (raw['data'] as List<dynamic>? ?? [])
        : (raw as List<dynamic>? ?? []);
    return dataList
        .map((e) => District.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
