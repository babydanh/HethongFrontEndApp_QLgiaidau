import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DioClient {
  static const _log = AppLogger('DioClient');
  static const _retryCountKey = '__transient_retry_count';
  static const _authRetryKey = '__auth_retry';
  static const _rateLimitRetryKey = '__rate_limit_retry_count';
  static const _maxTransientRetries = 2;
  static const _maxRateLimitRetries = 1;

  late final Dio _dio;
  final TokenManager _tokenManager;
  final Map<String, _CachedGetResponse> _getCache = {};
  Future<_TokenPair?>? _refreshInFlight;
  late final Future<String> _clientId = _loadClientId();

  DioClient({required TokenManager tokenManager, Dio? dio})
      : _tokenManager = tokenManager {
    var baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (!kIsWeb && Platform.isAndroid) {
      if (baseUrl.contains('localhost')) {
        baseUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
      } else if (baseUrl.contains('127.0.0.1')) {
        baseUrl = baseUrl.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }
    _log.info('Initializing Dio with Base URL: $baseUrl');

    _dio = dio ?? Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (dotenv.env['APP_API_KEY'] != null && dotenv.env['APP_API_KEY']!.isNotEmpty)
          'x-app-key': dotenv.env['APP_API_KEY']!,
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final clientId = await _clientId;
        options.headers['x-client-id'] = clientId;
        final token = await _tokenManager.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Dữ liệu realtime (thông báo...) không nên bị cache — luôn lấy mới.
        final noCache = response.requestOptions.extra['noCache'] == true;
        if (!noCache &&
            response.requestOptions.method.toUpperCase() == 'GET' &&
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
            final oldest = _getCache.entries.reduce(
              (a, b) => a.value.savedAt.isBefore(b.value.savedAt) ? a : b,
            ).key;
            _getCache.remove(oldest);
          }
        }
        handler.next(response);
      },
      onError: (DioException error, handler) async {
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 &&
            error.requestOptions.extra[_authRetryKey] != true &&
            !error.requestOptions.path.contains('/auth/mobile/login') &&
            !error.requestOptions.path.contains('/auth/mobile/refresh')) {
          final refreshed = await _refreshAccessToken(baseUrl);
          if (refreshed != null) {
            final options = error.requestOptions.copyWith(
              extra: {...error.requestOptions.extra, _authRetryKey: true},
              headers: {
                ...error.requestOptions.headers,
                'Authorization': 'Bearer ${refreshed.accessToken}',
              },
            );
            try {
              return handler.resolve(await _dio.fetch<dynamic>(options));
            } on DioException catch (retryError) {
              error = retryError;
            }
          }
        }

        final transient = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError ||
            (statusCode != null && statusCode >= 500);
        final method = error.requestOptions.method.toUpperCase();
        final noCache = error.requestOptions.extra['noCache'] == true;
        final cached = noCache ? null : _getCache[_cacheKey(error.requestOptions)];

        // A stale-but-valid public snapshot is more useful than waiting for a
        // rate-limit window. Only retry a GET without cache, once, and honor
        // the server's Retry-After with a small jitter to avoid synchronized
        // clients waking up together.
        if (method == 'GET' && statusCode == 429) {
          if (cached != null &&
              DateTime.now().difference(cached.savedAt) < const Duration(minutes: 10)) {
            return handler.resolve(Response(
              requestOptions: error.requestOptions,
              data: cached.data,
              statusCode: cached.statusCode,
              statusMessage: cached.statusMessage,
              headers: cached.headers,
            ));
          }
          final rateLimitRetryCount =
              (error.requestOptions.extra[_rateLimitRetryKey] as int?) ?? 0;
          if (rateLimitRetryCount < _maxRateLimitRetries) {
            final retryAfterSeconds = int.tryParse(
                  error.response?.headers.value('retry-after') ?? '',
                ) ??
                1;
            final jitterMs = math.Random().nextInt(250);
            final delayMs = math.min(10000, retryAfterSeconds * 1000 + jitterMs);
            await Future<void>.delayed(Duration(milliseconds: delayMs));
            final options = error.requestOptions.copyWith(extra: {
              ...error.requestOptions.extra,
              _rateLimitRetryKey: rateLimitRetryCount + 1,
            });
            try {
              return handler.resolve(await _dio.fetch<dynamic>(options));
            } on DioException catch (retryError) {
              error = retryError;
            }
          }
        }

        final retryCount = (error.requestOptions.extra[_retryCountKey] as int?) ?? 0;
        if (method == 'GET' && transient && retryCount < _maxTransientRetries) {
          await Future<void>.delayed(Duration(milliseconds: 350 * (1 << retryCount)));
          final options = error.requestOptions.copyWith(extra: {
            ...error.requestOptions.extra,
            _retryCountKey: retryCount + 1,
          });
          try {
            return handler.resolve(await _dio.fetch<dynamic>(options));
          } on DioException catch (retryError) {
            error = retryError;
          }
        }

        final canUseCache = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError ||
            statusCode == 429 ||
            (statusCode != null && statusCode >= 500);
        if (method == 'GET' && canUseCache && cached != null &&
            DateTime.now().difference(cached.savedAt) < const Duration(minutes: 10)) {
          return handler.resolve(Response(
            requestOptions: error.requestOptions,
            data: cached.data,
            statusCode: cached.statusCode,
            statusMessage: cached.statusMessage,
            headers: cached.headers,
          ));
        }
        handler.next(error);
      },
    ));
  }

  Future<String> _loadClientId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'sporto_anonymous_client_id_v1';
      final existing = prefs.getString(key);
      if (existing != null && existing.length >= 8 && existing.length <= 128) {
        return existing;
      }
      final generated = const Uuid().v4();
      await prefs.setString(key, generated);
      return generated;
    } catch (error, stack) {
      _log.error('Unable to persist anonymous client id', error, stack);
      return const Uuid().v4();
    }
  }

  Future<_TokenPair?> _refreshAccessToken(String baseUrl) {
    return _refreshInFlight ??= _performTokenRefresh(baseUrl).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<_TokenPair?> _performTokenRefresh(String baseUrl) async {
    final refreshToken = await _tokenManager.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenManager.clearTokens();
      return null;
    }
    try {
      final response = await Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (dotenv.env['APP_API_KEY']?.isNotEmpty == true)
            'x-app-key': dotenv.env['APP_API_KEY']!,
        },
      )).post('/auth/mobile/refresh', data: {'refreshToken': refreshToken});
      final rawData = response.data;
      final data = rawData is Map && rawData['data'] is Map
          ? rawData['data'] as Map
          : rawData is Map
              ? rawData
              : const <String, dynamic>{};
      final access = data['accessToken']?.toString();
      final nextRefresh = data['refreshToken']?.toString();
      if (access == null || nextRefresh == null) return null;
      await _tokenManager.saveTokens(accessToken: access, refreshToken: nextRefresh);
      return _TokenPair(access, nextRefresh);
    } on DioException catch (error, stack) {
      _log.error('Failed to refresh token', error, stack);
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) await _tokenManager.clearTokens();
      return null;
    } catch (error, stack) {
      _log.error('Unexpected refresh token error', error, stack);
      return null;
    }
  }

  String _cacheKey(RequestOptions options) {
    final auth = options.headers['Authorization']?.toString() ?? 'public';
    return '${options.method}:${options.uri}:$auth';
  }

  Dio get dio => _dio;
}

class _TokenPair {
  final String accessToken;
  final String refreshToken;
  const _TokenPair(this.accessToken, this.refreshToken);
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
