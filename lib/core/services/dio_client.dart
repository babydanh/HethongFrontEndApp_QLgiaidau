import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DioClient {
  static const _log = AppLogger('DioClient');
  static const _retryCountKey = '__transient_retry_count';
  static const _authRetryKey = '__auth_retry';
  static const _rateLimitRetryKey = '__rate_limit_retry_count';
  static const _traceStartedAtKey = '__trace_started_at_us';
  static const _maxTransientRetries = 2;
  static const _maxRateLimitRetries = 1;

  /// Refresh token là nút thắt của MỌI request ghi: không có nó thì 401 không
  /// retry được. Một lần nghẽn mạng ngắn phải không làm hỏng lần ghi.
  static const _maxRefreshRetries = 2;

  late final Dio _dio;
  late final Dio _refreshDio;
  final TokenManager _tokenManager;
  final Object Function()? sessionIdentity;
  final Map<String, _CachedGetResponse> _getCache = {};
  Future<_RefreshResult>? _refreshInFlight;
  late final Future<String> _clientId = _loadClientId();

  DioClient({
    required TokenManager tokenManager,
    Dio? dio,
    Dio? refreshDio,
    this.sessionIdentity,
  }) : _tokenManager = tokenManager {
    var baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (!kIsWeb && Platform.isAndroid) {
      if (baseUrl.contains('localhost')) {
        baseUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
      } else if (baseUrl.contains('127.0.0.1')) {
        baseUrl = baseUrl.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }
    _log.info('Initializing Dio with Base URL: $baseUrl');

    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (dotenv.env['APP_API_KEY'] != null &&
                  dotenv.env['APP_API_KEY']!.isNotEmpty)
                'x-app-key': dotenv.env['APP_API_KEY']!,
            },
          ),
        );

    // Cùng timeout với dio chính: refresh mở kết nối mới lúc access token vừa
    // hết hạn, nên bị timeout sớm hơn chính là nghẽn chết một request ghi.
    _refreshDio =
        refreshDio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (dotenv.env['APP_API_KEY']?.isNotEmpty == true)
                'x-app-key': dotenv.env['APP_API_KEY']!,
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final identity = sessionIdentity?.call();
          final scoped = options.path.contains('/social-sessions');
          if (scoped && identity != null) {
            options.extra.putIfAbsent('socialSessionIdentity', () => identity);
          }
          final clientId = await _clientId;
          options.headers['x-client-id'] = clientId;
          final token = await _tokenManager.getAccessToken();
          if (scoped &&
              sessionIdentity != null &&
              !identical(
                options.extra['socialSessionIdentity'],
                sessionIdentity!(),
              )) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                message: 'Session changed',
              ),
            );
          }
          if (scoped) options.headers.remove('Authorization');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (_isSensitiveLocation(options)) {
            options.extra['noCache'] = true;
          }
          if (kDebugMode) {
            options.extra[_traceStartedAtKey] =
                DateTime.now().microsecondsSinceEpoch;
            _logRequest(options);
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) _logResponse(response);
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
              final oldest = _getCache.entries
                  .reduce(
                    (a, b) => a.value.savedAt.isBefore(b.value.savedAt) ? a : b,
                  )
                  .key;
              _getCache.remove(oldest);
            }
          }
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (sessionIdentity != null &&
              error.requestOptions.extra.containsKey('socialSessionIdentity') &&
              !identical(
                error.requestOptions.extra['socialSessionIdentity'],
                sessionIdentity!(),
              )) {
            return handler.reject(error);
          }
          if (kDebugMode) _logError(error);
          final statusCode = error.response?.statusCode;
          if (statusCode == 401 &&
              error.requestOptions.extra[_authRetryKey] != true &&
              !error.requestOptions.path.contains('/auth/mobile/login') &&
              !error.requestOptions.path.contains('/auth/mobile/refresh')) {
            final outcome = await _refreshAccessToken(baseUrl);
            final refreshed = outcome.pair;
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
            } else if (outcome.transientFailure case final transient?) {
              // Refresh chỉ chết vì mạng, token vẫn hợp lệ. Trả lỗi mạng thay
              // vì 401 để UI không bắt host đăng nhập lại oang oàng.
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  type: transient.type,
                  error: transient.error,
                  message: 'Token refresh thất bại do mạng',
                  stackTrace: transient.stackTrace,
                ),
              );
            }
          }

          final transient =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              (statusCode != null && statusCode >= 500);
          final method = error.requestOptions.method.toUpperCase();
          final noCache = error.requestOptions.extra['noCache'] == true;
          final cached = noCache
              ? null
              : _getCache[_cacheKey(error.requestOptions)];

          // A stale-but-valid public snapshot is more useful than waiting for a
          // rate-limit window. Only retry a GET without cache, once, and honor
          // the server's Retry-After with a small jitter to avoid synchronized
          // clients waking up together.
          if (method == 'GET' && statusCode == 429) {
            if (cached != null &&
                DateTime.now().difference(cached.savedAt) <
                    const Duration(minutes: 10)) {
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
            final rateLimitRetryCount =
                (error.requestOptions.extra[_rateLimitRetryKey] as int?) ?? 0;
            if (rateLimitRetryCount < _maxRateLimitRetries) {
              final retryAfterSeconds =
                  int.tryParse(
                    error.response?.headers.value('retry-after') ?? '',
                  ) ??
                  1;
              final jitterMs = math.Random().nextInt(250);
              final delayMs = math.min(
                10000,
                retryAfterSeconds * 1000 + jitterMs,
              );
              await Future<void>.delayed(Duration(milliseconds: delayMs));
              final options = error.requestOptions.copyWith(
                extra: {
                  ...error.requestOptions.extra,
                  _rateLimitRetryKey: rateLimitRetryCount + 1,
                },
              );
              try {
                return handler.resolve(await _dio.fetch<dynamic>(options));
              } on DioException catch (retryError) {
                error = retryError;
              }
            }
          }

          final retryCount =
              (error.requestOptions.extra[_retryCountKey] as int?) ?? 0;
          // `noRetry` is opt-in cho các lần đọc mà độ trễ thêm chỉ làm tệ hơn
          // (danh sách Social): retry lặp lại cùng một lỗi rồi vẫn fail.
          final noRetry = error.requestOptions.extra['noRetry'] == true;
          if (method == 'GET' &&
              transient &&
              !noRetry &&
              retryCount < _maxTransientRetries) {
            await Future<void>.delayed(
              Duration(milliseconds: 350 * (1 << retryCount)),
            );
            final options = error.requestOptions.copyWith(
              extra: {
                ...error.requestOptions.extra,
                _retryCountKey: retryCount + 1,
              },
            );
            try {
              return handler.resolve(await _dio.fetch<dynamic>(options));
            } on DioException catch (retryError) {
              error = retryError;
            }
          }

          final canUseCache =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              statusCode == 429 ||
              (statusCode != null && statusCode >= 500);
          if (method == 'GET' &&
              canUseCache &&
              cached != null &&
              DateTime.now().difference(cached.savedAt) <
                  const Duration(minutes: 10)) {
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
          handler.next(error);
        },
      ),
    );
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

  Future<_RefreshResult> _refreshAccessToken(String baseUrl) {
    return _refreshInFlight ??= _performTokenRefresh(baseUrl).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  static bool _isTransient(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  /// Gọi `/auth/mobile/refresh`, thử lại khi lỗi mạng tạm thời.
  ///
  /// Khi hết số lần thử mà vẫn chỉ là lỗi mạng, trả về [transientFailure] và
  /// **không** xoá token: token còn hợp lệ, chỉ là mạng chết. Request gốc phải
  /// báo lỗi mạng chứ không được báo 401, vì 401 giả sẽ khiến UI tưởng phiên
  /// hết hạn và bắt host đăng nhập lại oan.
  Future<_RefreshResult> _performTokenRefresh(String baseUrl) async {
    final identity = sessionIdentity?.call();
    final refreshToken = await _tokenManager.getRefreshToken();
    if (sessionIdentity != null && !identical(identity, sessionIdentity!())) {
      return const (pair: null, transientFailure: null);
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenManager.clearTokens();
      return const (pair: null, transientFailure: null);
    }
    DioException? lastTransient;
    for (var attempt = 0; attempt <= _maxRefreshRetries; attempt++) {
      try {
        final response = await _refreshDio.post<dynamic>(
          '/auth/mobile/refresh',
          data: {'refreshToken': refreshToken},
        );
        final rawData = response.data;
        final data = rawData is Map && rawData['data'] is Map
            ? rawData['data'] as Map
            : rawData is Map
            ? rawData
            : const <String, dynamic>{};
        final access = data['accessToken']?.toString();
        final nextRefresh = data['refreshToken']?.toString();
        if (access == null || nextRefresh == null) {
          return const (pair: null, transientFailure: null);
        }
        if (sessionIdentity != null &&
            !identical(identity, sessionIdentity!())) {
          return const (pair: null, transientFailure: null);
        }
        await _tokenManager.saveTokens(
          accessToken: access,
          refreshToken: nextRefresh,
        );
        return (pair: _TokenPair(access, nextRefresh), transientFailure: null);
      } on DioException catch (error, stack) {
        _log.error('Failed to refresh token', error, stack);
        final status = error.response?.statusCode;
        // 401/403 là server từ chối token: thử lại cũng vô nghĩa, và token cũ
        // phải bị xoá để auth provider đưa user về màn đăng nhập.
        if (sessionIdentity != null &&
            !identical(identity, sessionIdentity!())) {
          return const (pair: null, transientFailure: null);
        }
        if (status == 401 || status == 403) {
          await _tokenManager.clearTokens();
          return const (pair: null, transientFailure: null);
        }
        if (!_isTransient(error)) {
          return const (pair: null, transientFailure: null);
        }
        lastTransient = error;
        if (attempt < _maxRefreshRetries) {
          await Future<void>.delayed(
            Duration(milliseconds: 400 * (1 << attempt)),
          );
        }
      } catch (error, stack) {
        _log.error('Unexpected refresh token error', error, stack);
        return const (pair: null, transientFailure: null);
      }
    }
    return (pair: null, transientFailure: lastTransient);
  }

  String _cacheKey(RequestOptions options) {
    final auth = options.headers['Authorization']?.toString() ?? 'public';
    return '${options.method}:${options.uri}:$auth';
  }

  Dio get dio => _dio;

  // ── Safe request tracing (debug builds only) ─────────────────────────────
  // Keep payloads, tokens, free-text search and personal data out of logs.

  void _logRequest(RequestOptions options) {
    final rawTrigger = options.extra['trigger']?.toString() ?? 'api_call';
    final trigger = rawTrigger
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_')
        .substring(0, math.min(rawTrigger.length, 64).toInt());
    debugPrint(
      '[DioClient] '
      '[HTTP] start ${options.method} ${_routeTemplate(options)} '
      'query=${_safeQuerySummary(options)} '
      'request_bytes=${_byteLength(options.data) ?? 'unknown'} trigger=$trigger',
    );
  }

  void _logResponse(Response response) {
    final options = response.requestOptions;
    debugPrint(
      '[DioClient] '
      '[HTTP] done ${options.method} ${_routeTemplate(options)} '
      'status=${response.statusCode} duration_ms=${_durationMs(options)} '
      'response_bytes=${_responseByteLength(response)}',
    );
  }

  void _logError(DioException err) {
    final options = err.requestOptions;
    debugPrint(
      '[DioClient] '
      '[HTTP] error ${options.method} ${_routeTemplate(options)} '
      'status=${err.response?.statusCode ?? 'network'} '
      'duration_ms=${_durationMs(options)} type=${err.type.name}',
    );
  }

  String _safeQuerySummary(RequestOptions options) {
    const safeKeys = {'limit', 'status', 'publicOnly', 'page', 'sort', 'order'};
    if (options.queryParameters.isEmpty) return '{}';
    final entries = options.queryParameters.entries.map((entry) {
      final key = entry.key.toString();
      final value = safeKeys.contains(key) ? entry.value : '<redacted>';
      return '$key:$value';
    });
    return '{${entries.join(',')}}';
  }

  String _durationMs(RequestOptions options) {
    final startedAt = options.extra[_traceStartedAtKey];
    if (startedAt is! int) return 'unknown';
    final elapsed = DateTime.now().microsecondsSinceEpoch - startedAt;
    return (elapsed / 1000).toStringAsFixed(1);
  }

  String _responseByteLength(Response response) {
    final contentLength = response.headers.value('content-length');
    if (contentLength != null && int.tryParse(contentLength) != null) {
      return contentLength;
    }
    return _byteLength(response.data)?.toString() ?? 'unknown';
  }

  int? _byteLength(Object? value) {
    if (value == null) return 0;
    try {
      return utf8.encode(value is String ? value : jsonEncode(value)).length;
    } catch (_) {
      return null;
    }
  }

  bool _isSensitiveLocation(RequestOptions options) {
    final keys = options.queryParameters.keys
        .map((key) => key.toString().toLowerCase())
        .toSet();
    final path = Uri.parse(options.path).path;
    return keys.any(
          (key) => {'lat', 'latitude', 'lng', 'lon', 'longitude'}.contains(key),
        ) ||
        RegExp(r'(^|/)(social-sessions|socials|venues)(/|$)').hasMatch(path) ||
        options.path.contains('/nearby') ||
        options.path.contains('/regions/resolve');
  }

  String _routeTemplate(RequestOptions options) => options.path
      .split('?')
      .first
      .replaceAll(
        RegExp(
          r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}',
        ),
        ':id',
      )
      .replaceAll(RegExp(r'(?<=/)\d+(?=/|$)'), ':id');
}

class _TokenPair {
  final String accessToken;
  final String refreshToken;
  const _TokenPair(this.accessToken, this.refreshToken);
}

/// Kết quả refresh: `pair` khi thành công; `transientFailure` khi hết số lần
/// thử mà nguyên nhân vẫn là lỗi mạng (token vẫn hợp lệ).
typedef _RefreshResult = ({_TokenPair? pair, DioException? transientFailure});

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

// ── Friendly Error Message (tham khảo từ dio_client_EXAMPLE) ───────────────

/// Trả về thông báo lỗi thân thiện bằng tiếng Việt dựa trên loại [DioException].
///
/// Dùng chung cho tất cả repository để đảm bảo thông báo nhất quán.
String friendlyDioErrorMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Kết nối quá hạn. Vui lòng kiểm tra mạng và thử lại.';
    case DioExceptionType.connectionError:
      return 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.';
    case DioExceptionType.badCertificate:
      return 'Chứng chỉ bảo mật không hợp lệ.';
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      return statusCode == null
          ? (e.message ?? 'Máy chủ phản hồi lỗi.')
          : 'Máy chủ phản hồi lỗi ($statusCode).';
    case DioExceptionType.cancel:
      return 'Yêu cầu đã bị hủy.';
    case DioExceptionType.unknown:
      return _mapUnknownError(e);
    // ignore: unreachable_switch_default
    default:
      return e.message ?? 'Lỗi kết nối không xác định. Vui lòng thử lại.';
  }
}

/// Phân tích chi tiết lỗi `DioExceptionType.unknown` để trả thông báo chính xác.
String _mapUnknownError(DioException e) {
  final inner = e.error?.toString() ?? '';

  // HandshakeException → lỗi TLS/SSL trên thiết bị cũ
  if (inner.contains('HandshakeException') ||
      inner.contains('CERTIFICATE_VERIFY_FAILED')) {
    return 'Chứng chỉ bảo mật không phù hợp với thiết bị. Vui lòng liên hệ hỗ trợ.';
  }

  // SocketException → mất mạng hoặc DNS fail
  if (inner.contains('SocketException') ||
      inner.contains('HOST_UNREACHABLE') ||
      inner.contains('Connection refused')) {
    return 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.';
  }

  return e.message ?? 'Lỗi kết nối không xác định. Vui lòng thử lại.';
}

// ── Parse response chuẩn {status: OK/ER} (tham khảo từ dio_client_EXAMPLE) ──

/// Parse response theo format chuẩn:
/// { "status": "OK"/"ER", "message": "...", "data": ... }
///
/// Ném [ApiException] nếu status là "ER".
/// Trả về `data` nếu status là "OK".
T parseApiResponse<T>(Response response, T Function(dynamic data) fromData) {
  final body = response.data as Map<String, dynamic>;
  final status = body['status'] as String?;

  if (status != 'OK') {
    throw ApiException(
      message: body['message'] as String? ?? 'Lỗi không xác định',
      statusCode: response.statusCode,
    );
  }

  return fromData(body['data']);
}

/// Exception khi API trả về status "ER".
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException: $message (HTTP $statusCode)';
}
