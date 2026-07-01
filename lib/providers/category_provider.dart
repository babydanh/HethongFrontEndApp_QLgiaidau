import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/categories');
  final raw = response.data;
  // NestJS standard transform payload: { data: [...] } or direct list
  final List<dynamic> dataList = raw is Map<String, dynamic>
      ? (raw['data'] as List<dynamic>? ?? [])
      : (raw as List<dynamic>? ?? []);
  return dataList.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
});
