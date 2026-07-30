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
  final Map<String, _CachedGetResponse> _getCache = {};

  DioClient({required TokenManager tokenManager, Dio? dio})
    : _tokenManager = tokenManager {
    String baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (!kIsWeb && Platform.isAndroid) {
      if (baseUrl.contains('localhost')) {
        baseUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
      } else if (baseUrl.contains('127.0.0.1')) {
        baseUrl = baseUrl.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }
    _log.info('Initializing Dio with Base URL: $baseUrl');

    final dioOptions = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = dio ?? Dio(dioOptions);

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
          if (response.requestOptions.method.toUpperCase() == 'GET' &&
              response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            _getCache[_cacheKey(response.requestOptions)] = _CachedGetResponse(
              data: response.data,
              statusCode: response.statusCode!,
              statusMessage: response.statusMessage,
              headers: response.headers,
              savedAt: DateTime.now(),
            );
            if (_getCache.length > 120) {
              final oldestKey = _getCache.entries
                  .reduce(
                    (a, b) => a.value.savedAt.isBefore(b.value.savedAt) ? a : b,
                  )
                  .key;
              _getCache.remove(oldestKey);
            }
          }
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
                final refreshDio = Dio(
                  BaseOptions(
                    baseUrl: baseUrl,
                    connectTimeout: const Duration(seconds: 8),
                    receiveTimeout: const Duration(seconds: 8),
                    sendTimeout: const Duration(seconds: 8),
                  ),
                );
                final response = await refreshDio
                    .post(
                      '/auth/mobile/refresh',
                      data: {'refreshToken': refreshToken},
                    )
                    .timeout(const Duration(seconds: 10));

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
              } on DioException catch (refreshError, stack) {
                _log.error('Failed to refresh token', refreshError, stack);
                final refreshStatus = refreshError.response?.statusCode;
                // Chỉ xóa phiên khi server xác nhận refresh token không còn hợp lệ.
                // Timeout, mất mạng hoặc lỗi 5xx không được phép làm người dùng đăng xuất.
                if (refreshStatus == 401 || refreshStatus == 403) {
                  await _tokenManager.clearTokens();
                }
              } catch (e, stack) {
                _log.error('Unexpected refresh token error', e, stack);
              }
            } else {
              _log.warning('No refresh token available');
              await _tokenManager.clearTokens();
            }
          }

          final statusCode = error.response?.statusCode;
          final isTransient =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              statusCode == 429 ||
              (statusCode != null && statusCode >= 500);
          if (error.requestOptions.method.toUpperCase() == 'GET' &&
              isTransient) {
            final cached = _getCache[_cacheKey(error.requestOptions)];
            if (cached != null &&
                DateTime.now().difference(cached.savedAt) <
                    const Duration(minutes: 3)) {
              _log.warning(
                'Using recent cached response for ${error.requestOptions.path}',
              );
              return handler.resolve(
                Response(
                  requestOptions: error.requestOptions,
                  data: cached.data,
                  statusCode: cached.statusCode,
                  statusMessage: cached.statusMessage,
                  headers: cached.headers,
                ),
              );
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  String _cacheKey(RequestOptions options) {
    final auth = options.headers['Authorization']?.toString() ?? 'public';
    return '${options.method}:${options.uri}:$auth';
  }

  Dio get dio => _dio;
}

class _CachedGetResponse {
  final dynamic data;
  final int statusCode;
  final String? statusMessage;
  final Headers headers;
  final DateTime savedAt;

  const _CachedGetResponse({
    required this.data,
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.savedAt,
  });
}
