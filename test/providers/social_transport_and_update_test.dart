import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_social_session_repository.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  _NoTokenManager() : super(secureStorage: null);
  @override
  Future<String?> getAccessToken() async => null;
}

/// Adapter luôn ném lỗi transport (không có HTTP response) — đúng trạng thái
/// `DioException` mà log `code=network_error` mô tả.
class _OfflineAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}

class _StaticAdapter implements HttpClientAdapter {
  _StaticAdapter(this.body, {this.statusCode = 200});

  final Map<String, dynamic> body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

DioClient _clientWith(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  return DioClient(tokenManager: _NoTokenManager(), dio: dio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GET /social-sessions không retry và không throw khi offline', () {
    test('transient GET vẫn retry mặc định', () async {
      final adapter = _OfflineAdapter();
      final client = _clientWith(adapter);

      await expectLater(
        client.dio.get<String>('/social-sessions'),
        throwsA(isA<DioException>()),
      );
      // 1 lần gọi đầu + 2 lần retry.
      expect(adapter.calls, 3);
    });

    test("extra noRetry chặn retry cho GET", () async {
      final adapter = _OfflineAdapter();
      final client = _clientWith(adapter);

      await expectLater(
        client.dio.get<String>(
          '/social-sessions',
          options: Options(extra: {'noCache': true, 'noRetry': true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
    });

    test('listByDate trả list rỗng thay vì throw khi lỗi transport', () async {
      final repository = ApiSocialSessionRepository(
        _clientWith(_OfflineAdapter()),
      );

      final response = await repository.listByDate(date: '2026-10-05');

      expect(response.items, isEmpty);
      expect(response.total, 0);
    });

    test(
      'listByDate vẫn ném SocialApiException khi server trả 4xx/5xx',
      () async {
        final repository = ApiSocialSessionRepository(
          _clientWith(_StaticAdapter({'message': 'boom'}, statusCode: 500)),
        );

        await expectLater(
          repository.listByDate(date: '2026-10-05'),
          throwsA(isA<SocialApiException>()),
        );
      },
    );

    test('listByDate đọc được payload bình thường', () async {
      final repository = ApiSocialSessionRepository(
        _clientWith(
          _StaticAdapter({
            'data': {
              'items': [
                {
                  'id': 's1',
                  'hostUserId': 'u1',
                  'title': 'Kèo gần bạn',
                  'playFormat': 'Giao lưu',
                  'startAt': '2026-10-05T14:00:00+07:00',
                  'venueName': 'Sân A',
                  'venueAddress': 'Địa chỉ A',
                  'sport': 'pickleball',
                },
              ],
              'meta': {'page': 1, 'limit': 20, 'total': 1},
            },
          }),
        ),
      );

      final response = await repository.listByDate(date: '2026-10-05');

      expect(response.items, hasLength(1));
      expect(response.items.single.title, 'Kèo gần bạn');
    });
  });

  group('PATCH /social-sessions payload khớp UpdateSocialSessionDto', () {
    SocialPlace place({
      String? venueId,
      double? latitude = 10.7769,
      double? longitude = 106.7009,
    }) => SocialPlace(
      name: 'Sân A',
      formattedAddress: 'Địa chỉ A',
      latitude: latitude,
      longitude: longitude,
      venueId: venueId,
    );

    test(
      'địa điểm ghim tay thì gửi newVenue để backend tạo/tái dùng venue',
      () {
        final payload = buildSocialSessionUpdatePayload(
          title: 'Kèo test',
          description: 'ghi chú',
          playFormat: 'Giao lưu',
          startAt: DateTime(2026, 10, 5, 14),
          durationMinutes: 120,
          locationChanged: true,
          place: place(),
          venueName: 'Sân A',
          venueAddress: 'Địa chỉ A',
          maxSlots: 6,
          feePerSlot: 50000,
          visibility: 'PUBLIC',
        );

        // forbidNonWhitelisted -> 400 nếu có 2 field này.
        expect(payload.containsKey('sport'), isFalse);
        expect(payload.containsKey('communityId'), isFalse);
        // Không gửi lat/lng trần: backend chỉ cập nhật social_sessions nên sân
        // không vào thư viện, search sau đó không ra.
        expect(payload.containsKey('latitude'), isFalse);
        expect(payload.containsKey('longitude'), isFalse);
        expect(payload['newVenue'], {
          'name': 'Sân A',
          'locationAddress': 'Địa chỉ A',
          'latitude': 10.7769,
          'longitude': 106.7009,
        });
        expect(payload['playFormat'], 'Giao lưu');
        expect(payload['durationMinutes'], 120);
        expect(payload['maxSlots'], 6);
        expect(payload['feePerSlot'], 50000);
        expect(payload['levelRequirement'], 'ALL');
        expect(payload['visibility'], 'PUBLIC');
        expect(payload['startAt'], DateTime(2026, 10, 5, 14).toIso8601String());
      },
    );

    test(
      'ghim tay mà thiếu tên/địa chỉ thì không gửi newVenue sẽ bị backend từ chối',
      () {
        final payload = buildSocialSessionUpdatePayload(
          title: 'Kèo test',
          description: null,
          playFormat: 'Giao lưu',
          startAt: DateTime(2026, 10, 5, 14),
          durationMinutes: 90,
          locationChanged: true,
          place: place(),
          venueName: 'Sân A',
          venueAddress: '',
          maxSlots: 8,
          feePerSlot: 0,
          visibility: 'PUBLIC',
        );

        expect(payload.containsKey('newVenue'), isFalse);
      },
    );

    test('địa điểm đã có venueId thì gửi venueId, không gửi newVenue', () {
      final payload = buildSocialSessionUpdatePayload(
        title: 'Kèo test',
        description: null,
        playFormat: 'Giao lưu',
        startAt: DateTime(2026, 10, 5, 14),
        durationMinutes: 90,
        locationChanged: true,
        place: place(venueId: '3fa85f64-5717-4562-b3fc-2c963f66afa6'),
        venueName: 'Sân B',
        venueAddress: 'Địa chỉ B',
        maxSlots: 8,
        feePerSlot: 0,
        visibility: 'CLUB_ONLY',
      );

      expect(payload['venueId'], '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(payload.containsKey('latitude'), isFalse);
      expect(payload.containsKey('longitude'), isFalse);
      expect(payload.containsKey('description'), isFalse);
      expect(payload['visibility'], 'CLUB_ONLY');
    });

    test('không đổi vị trí thì không gửi toạ độ nào', () {
      final payload = buildSocialSessionUpdatePayload(
        title: 'Kèo test',
        description: '',
        playFormat: 'Đánh đôi',
        startAt: DateTime(2026, 10, 5, 14),
        durationMinutes: 60,
        locationChanged: false,
        place: place(),
        venueName: 'Sân A',
        venueAddress: 'Địa chỉ A',
        maxSlots: 6,
        feePerSlot: 0,
        visibility: 'PUBLIC',
      );

      for (final key in const [
        'venueId',
        'latitude',
        'longitude',
        'venueName',
        'venueAddress',
        'newVenue',
      ]) {
        expect(payload.containsKey(key), isFalse, reason: 'không gửi $key');
      }
    });

    test('pin không có toạ độ thì không gửi newVenue lệch', () {
      final payload = buildSocialSessionUpdatePayload(
        title: 'Kèo test',
        description: null,
        playFormat: 'Giao lưu',
        startAt: DateTime(2026, 10, 5, 14),
        durationMinutes: 60,
        locationChanged: true,
        place: place(latitude: null, longitude: null),
        venueName: 'Sân A',
        venueAddress: 'Địa chỉ A',
        maxSlots: 6,
        feePerSlot: 0,
        visibility: 'PUBLIC',
      );

      expect(payload.containsKey('newVenue'), isFalse);
      expect(payload.containsKey('latitude'), isFalse);
      expect(payload.containsKey('longitude'), isFalse);
    });

    test('tiêu đề dài hơn 100 ký tự bị cắt', () {
      final payload = buildSocialSessionUpdatePayload(
        title: 'K' * 130,
        description: null,
        playFormat: 'Giao lưu',
        startAt: DateTime(2026, 10, 5, 14),
        durationMinutes: 60,
        locationChanged: false,
        place: place(),
        venueName: 'Sân A',
        venueAddress: 'Địa chỉ A',
        maxSlots: 6,
        feePerSlot: 0,
        visibility: 'PUBLIC',
      );

      expect((payload['title']! as String).length, 100);
    });
  });
}
