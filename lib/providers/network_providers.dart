import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:dio/dio.dart';

final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  return DioClient(tokenManager: tokenManager);
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});
