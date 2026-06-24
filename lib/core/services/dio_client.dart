import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';

class DioClient {
  static const _log = AppLogger('DioClient');
  late final Dio _dio;
  final TokenManager _tokenManager;

  DioClient({required TokenManager tokenManager, Dio? dio})
      : _tokenManager = tokenManager {
    String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (!kIsWeb && Platform.isAndroid) {
      if (baseUrl.contains('localhost')) {
        baseUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
      } else if (baseUrl.contains('127.0.0.1')) {
        baseUrl = baseUrl.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }
    _log.info('Initializing Dio with Base URL: $baseUrl');

    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _log.debug('Request: [${options.method}] ${options.path}');
          
          // Gắn access token nếu có
          final token = await _tokenManager.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _log.debug(
            'Response: [${response.statusCode}] ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          _log.error(
            'Error [${error.response?.statusCode}]: ${error.requestOptions.path}',
            error.message,
          );

          // Xử lý làm mới token khi nhận lỗi 401 Unauthorized
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/mobile/login') &&
              !error.requestOptions.path.contains('/auth/mobile/refresh')) {
            _log.info('401 Unauthorized. Attempting to refresh token...');
            
            final refreshToken = await _tokenManager.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Sử dụng client Dio riêng để tránh vòng lặp interceptor vô hạn
                final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
                final response = await refreshDio.post(
                  '/auth/mobile/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  final data = response.data;
                  final newAccessToken = data['accessToken'] as String?;
                  final newRefreshToken = data['refreshToken'] as String?;

                  if (newAccessToken != null && newRefreshToken != null) {
                    _log.success('Token refreshed successfully');
                    await _tokenManager.saveTokens(
                      accessToken: newAccessToken,
                      refreshToken: newRefreshToken,
                    );

                    // Thử lại request cũ với header mới
                    final options = error.requestOptions;
                    options.headers['Authorization'] = 'Bearer $newAccessToken';
                    
                    final retryResponse = await _dio.fetch(options);
                    return handler.resolve(retryResponse);
                  }
                }
              } catch (e, stack) {
                _log.error('Failed to refresh token', e, stack);
                await _tokenManager.clearTokens();
                // TODO: Điều hướng người dùng về màn hình Login hoặc thông báo session expired
              }
            } else {
              _log.warning('No refresh token available');
              await _tokenManager.clearTokens();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
