import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';

/// Phường/Xã thuộc một Tỉnh/Thành theo API địa chỉ v2.
class Ward {
  final String code;
  final String name;
  final String provinceCode;

  Ward({required this.code, required this.name, required this.provinceCode});

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      provinceCode: json['provinceCode']?.toString() ?? '',
    );
  }
}

/// Danh sách Phường/Xã theo mã tỉnh — GET /regions/wards?provinceCode=...
final wardsProvider =
    FutureProvider.family<List<Ward>, String>((ref, provinceCode) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      '/regions/wards',
      queryParameters: {'provinceCode': provinceCode},
    );
    final raw = response.data;
    final List<dynamic> dataList = raw is Map<String, dynamic>
        ? (raw['data'] as List<dynamic>? ?? [])
        : (raw as List<dynamic>? ?? []);
    return dataList
        .map((e) => Ward.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
