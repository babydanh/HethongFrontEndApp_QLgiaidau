import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';

void main() {
  group('Social nearby (geolocation)', () {
    test('SocialSessionModel parse distanceKm/latitude/longitude từ server', () {
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
    });

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

    test('CreateSocialSessionRequest chỉ gửi lat/lng khi đi cặp', () {
      final withPin = CreateSocialSessionRequest(
        sport: 'pickleball',
        title: 'Kèo ghim',
        startAt: DateTime(2026, 9, 28, 14),
        venueName: 'Sân A',
        venueAddress: 'Địa chỉ A',
        latitude: 10.5,
        longitude: 106.5,
      );
      expect(withPin.toJson()['latitude'], 10.5);
      expect(withPin.toJson()['longitude'], 106.5);

      final withoutPin = CreateSocialSessionRequest(
        sport: 'pickleball',
        title: 'Kèo không ghim',
        startAt: DateTime(2026, 9, 28, 14),
        venueName: 'Sân A',
        venueAddress: 'Địa chỉ A',
      );
      expect(withoutPin.toJson().containsKey('latitude'), isFalse);
      expect(withoutPin.toJson().containsKey('longitude'), isFalse);
    });

    test('SocialFilterState toggle nearbyOnly + radiusKm', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(socialFilterProvider).nearbyOnly, isFalse);
      expect(container.read(socialFilterProvider).radiusKm, defaultNearbyRadiusKm);

      container.read(socialFilterProvider.notifier).setNearbyOnly(true);
      container.read(socialFilterProvider.notifier).setRadiusKm(5);
      final state = container.read(socialFilterProvider);
      expect(state.nearbyOnly, isTrue);
      expect(state.radiusKm, 5);
      expect(nearbyRadiusOptions, contains(5.0));
    });
  });
}
