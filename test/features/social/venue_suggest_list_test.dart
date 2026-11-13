import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/venue_suggest_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _FakeRepo implements ISocialLocationRepository {
  _FakeRepo(this.results, {this.fail = false});
  final List<SocialPlace> results;
  final bool fail;
  final List<String> queries = [];

  @override
  Future<List<SocialPlace>> search(
    String query, {
    LatLng? bias,
    String? categoryId,
  }) async {
    queries.add(query);
    if (fail) throw const LocationNetworkFailure();
    return results;
  }

  @override
  Future<SocialPlace> getVenueDetail(String venueId) => throw UnimplementedError();
  @override
  Future<SocialPlace> getPlaceDetail(String placeId) => throw UnimplementedError();
  @override
  Future<SocialPlace> resolveInput(String addressOrMapsUrl) =>
      throw UnimplementedError();
  @override
  Future<SocialPlace> reverseLookup(LatLng pin) => throw UnimplementedError();
}

const _mocChau = SocialPlace(
  name: 'Pickleball Mộc Châu',
  formattedAddress: 'Ngõ 247 đường Hoàng Văn Thụ, Mộc Châu, Sơn La',
  latitude: 20.8,
  longitude: 104.7,
  venueId: 'v1',
);

Widget _app(_FakeRepo repo, String query, void Function(SocialPlace) onPick) =>
    ProviderScope(
      overrides: [socialLocationRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: VenueSuggestList(query: query, onPick: onPick),
        ),
      ),
    );

void main() {
  // TC-VENUE-TEXT-APP-04
  group('VenueSuggestList', () {
    testWidgets('does not search for fewer than 3 characters', (tester) async {
      final repo = _FakeRepo(const [_mocChau]);
      await tester.pumpWidget(_app(repo, 'pi', (_) {}));
      await tester.pump(const Duration(milliseconds: 600));
      expect(repo.queries, isEmpty);
      expect(find.text('Pickleball Mộc Châu'), findsNothing);
    });

    testWidgets('lists directory venues after the debounce and picks one', (
      tester,
    ) async {
      final repo = _FakeRepo(const [_mocChau]);
      SocialPlace? picked;
      await tester.pumpWidget(_app(repo, 'pick', (p) => picked = p));
      expect(repo.queries, isEmpty); // still inside the debounce window
      await tester.pump(const Duration(milliseconds: 600));
      expect(repo.queries, ['pick']);
      expect(find.text('Pickleball Mộc Châu'), findsOneWidget);
      expect(find.textContaining('Hoàng Văn Thụ'), findsOneWidget);

      await tester.tap(find.text('Pickleball Mộc Châu'));
      expect(picked?.venueId, 'v1');
    });

    // TC-VENUE-UI-APP-05
    testWidgets('marks verified venues and keeps unverified ones plain', (
      tester,
    ) async {
      final repo = _FakeRepo(const [
        SocialPlace(
          name: 'Sân A',
          formattedAddress: '1 Đường X, Hà Nội',
          venueId: 'a',
          isVerified: true,
        ),
        _mocChau,
      ]);
      await tester.pumpWidget(_app(repo, 'san', (_) {}));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.byIcon(Icons.stadium_outlined), findsNWidgets(2));
    });

    testWidgets('searches again only for the latest query', (tester) async {
      final repo = _FakeRepo(const [_mocChau]);
      await tester.pumpWidget(_app(repo, 'pic', (_) {}));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_app(repo, 'pick', (_) {}));
      await tester.pump(const Duration(milliseconds: 600));
      expect(repo.queries, ['pick']);
    });

    testWidgets('shows nothing and does not throw when the search fails', (
      tester,
    ) async {
      final repo = _FakeRepo(const [], fail: true);
      await tester.pumpWidget(_app(repo, 'pick', (_) {}));
      await tester.pump(const Duration(milliseconds: 600));
      expect(repo.queries, ['pick']);
      expect(tester.takeException(), isNull);
      expect(find.byType(ListTile), findsNothing);
    });
  });
}
