import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';

void main() {
  group('Social nearby (geolocation)', () {
    test(
      'SocialSessionModel parse distanceKm/latitude/longitude từ server',
      () {
        final model = SocialSessionModel.fromJson({
          'id': 's1',
          'hostUserId': 'u1',
          'title': 'Kèo gần bạn',
          'playFormat': 'Giao lưu',
          'startAt': '2026-09-28T14:00:00+07:00',
          'venueName': 'Sân A',
          'venueAddress': 'Địa chỉ A',
          'sport': 'pickleball',
          'latitude': 10.7769,
          'longitude': 106.7009,
          'distanceKm': 1.25,
        });
        expect(model.latitude, 10.7769);
        expect(model.longitude, 106.7009);
        expect(model.distanceKm, 1.25);
      },
    );

    test('distanceKm mặc định 0.0 khi server không trả (kèo chưa ghim)', () {
      final model = SocialSessionModel.fromJson({
        'id': 's2',
        'hostUserId': 'u1',
        'title': 'Kèo cũ',
        'playFormat': 'Giao lưu',
        'startAt': '2026-09-28T14:00:00+07:00',
        'venueName': 'Sân B',
        'venueAddress': 'Địa chỉ B',
        'sport': 'tennis',
      });
      expect(model.distanceKm, 0.0);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
    });

    test('CreateSocialSessionRequest serialize bắt buộc lat/lng', () {
      final request = CreateSocialSessionRequest(
        sport: 'pickleball',
        title: 'Kèo ghim',
        startAt: DateTime(2026, 9, 28, 14),
        venueName: 'Sân A',
        venueAddress: 'Địa chỉ A',
        latitude: 10.5,
        longitude: 106.5,
      );
      expect((request.toJson()['newVenue'] as Map)['latitude'], 10.5);
      expect((request.toJson()['newVenue'] as Map)['longitude'], 106.5);
    });

    test('CreateSocialSessionRequest can defer the location', () {
      final request = CreateSocialSessionRequest(
        sport: 'pickleball',
        title: 'Kèo chưa có sân',
        startAt: DateTime(2026, 9, 28, 14),
        venueName: 'Quyết định sau',
        venueAddress: 'Quyết định sau',
        locationDeferred: true,
      );
      final payload = request.toJson();
      expect(payload['locationDeferred'], isTrue);
      expect(payload, isNot(contains('newVenue')));
      expect(payload, isNot(contains('venueId')));
      expect(payload, isNot(contains('latitude')));
      expect(payload, isNot(contains('longitude')));
    });

    test('SocialSessionModel parse distance_m và distanceDisplay', () {
      final inMetres = SocialSessionModel.fromJson({
        'id': 's1',
        'hostUserId': 'u1',
        'title': 'Kèo gần',
        'playFormat': 'Giao lưu',
        'startAt': '2026-09-28T14:00:00+07:00',
        'venueName': 'Sân A',
        'venueAddress': 'Địa chỉ A',
        'sport': 'pickleball',
        'latitude': 10.7769,
        'longitude': 106.7009,
        'distance_m': 350.0,
      });
      expect(inMetres.distanceM, 350.0);
      expect(inMetres.distanceDisplay, '350 m');

      final inKm = SocialSessionModel.fromJson({
        'id': 's2',
        'hostUserId': 'u1',
        'title': 'Kèo xa',
        'playFormat': 'Giao lưu',
        'startAt': '2026-09-28T14:00:00+07:00',
        'venueName': 'Sân B',
        'venueAddress': 'Địa chỉ B',
        'sport': 'pickleball',
        'latitude': 10.7769,
        'longitude': 106.7009,
        'distance_m': 2500.0,
      });
      expect(inKm.distanceM, 2500.0);
      expect(inKm.distanceDisplay, '2.5 km');
    });

    test('SocialFilterState toggle nearbyOnly + radiusKm', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(socialFilterProvider).nearbyOnly, isFalse);
      expect(
        container.read(socialFilterProvider).radiusKm,
        defaultNearbyRadiusKm,
      );

      container.read(socialFilterProvider.notifier).setNearbyOnly(true);
      container.read(socialFilterProvider.notifier).setRadiusKm(5);
      final state = container.read(socialFilterProvider);
      expect(state.nearbyOnly, isTrue);
      expect(state.radiusKm, 5);
      expect(nearbyRadiusOptions, contains(5.0));
    });

    test('nearbyOnly bật mà chưa có toạ độ thì không gọi listByDate', () async {
      // Không có toạ độ thì list trước đây rơi xuống listByDate (không geo)
      // trong khi chip vẫn ghi "Gần bạn" — bộ lọc không có tác dụng.
      final repository = _RecordingSocialRepository();
      final container = ProviderContainer(
        overrides: [
          socialSessionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(socialFilterProvider.notifier).setNearbyOnly(true);

      final sessions = await container.read(socialSessionsProvider.future);

      expect(sessions, isEmpty);
      expect(repository.listNearbyCalls, 0);
      expect(repository.listByDateCalls, 0);
    });

    test(
      'có toạ độ thì nearby gọi listNearby với bán kính đang chọn',
      () async {
        final repository = _RecordingSocialRepository();
        final container = ProviderContainer(
          overrides: [
            socialSessionRepositoryProvider.overrideWithValue(repository),
            userLocationProvider.overrideWith(
              () => _FixedLocation(
                UserLocationStatus.selected,
                10.7769,
                106.7009,
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(socialFilterProvider.notifier)
          ..setNearbyOnly(true)
          ..setRadiusKm(5);

        final sessions = await container.read(socialSessionsProvider.future);

        expect(sessions, hasLength(1));
        expect(repository.listNearbyCalls, 1);
        expect(repository.lastRadiusKm, 5);
        expect(repository.lastLat, 10.7769);
        expect(repository.listByDateCalls, 0);
      },
    );
  });
}

class _FixedLocation extends UserLocationNotifier {
  _FixedLocation(this.status, this.lat, this.lng);

  final UserLocationStatus status;
  final double lat;
  final double lng;

  @override
  UserLocationState build() =>
      UserLocationState(status: status, latitude: lat, longitude: lng);
}

class _RecordingSocialRepository extends Fake
    implements ISocialSessionRepository {
  int listByDateCalls = 0;
  int listNearbyCalls = 0;
  double? lastRadiusKm;
  double? lastLat;

  @override
  Future<SocialSessionListResponse> listByDate({
    String? date,
    String? sport,
    String? communityId,
    String? search,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    listByDateCalls++;
    return SocialSessionListResponse(
      items: [
        SocialSessionModel.fromJson(const {
          'id': 'by-date',
          'hostUserId': 'u1',
          'title': 'Kèo theo ngày',
          'playFormat': 'Giao lưu',
          'startAt': '2026-10-05T14:00:00+07:00',
          'venueName': 'Sân A',
          'venueAddress': 'Địa chỉ A',
          'sport': 'pickleball',
        }),
      ],
    );
  }

  @override
  Future<NearbySocialSessionsResponse> listNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int page = 1,
    int limit = 20,
  }) async {
    listNearbyCalls++;
    lastRadiusKm = radiusKm;
    lastLat = lat;
    return NearbySocialSessionsResponse(
      items: [
        SocialSessionModel.fromJson(const {
          'id': 'nearby',
          'hostUserId': 'u1',
          'title': 'Kèo gần bạn',
          'playFormat': 'Giao lưu',
          'startAt': '2026-10-05T14:00:00+07:00',
          'venueName': 'Sân A',
          'venueAddress': 'Địa chỉ A',
          'sport': 'pickleball',
          'distanceMeters': 800,
        }),
      ],
      total: 1,
    );
  }
}
