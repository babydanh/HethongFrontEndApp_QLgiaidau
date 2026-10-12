import 'dart:convert';

import 'package:app_quanly_giaidau/features/social/widgets/social_nearby_filter.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty nearby sheet opens manage and add location pages',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SocialNearbyFilter()),
      ),
    ));

    await tester.tap(find.text('Gần bạn'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa lưu địa điểm'), findsOneWidget);

    await tester.tap(find.text('Quản lý địa điểm'));
    await tester.pumpAndSettle();
    expect(find.text('Địa điểm'), findsOneWidget);
    expect(find.text('Thêm vị trí'), findsOneWidget);

    await tester.tap(find.text('Thêm vị trí'));
    await tester.pumpAndSettle();
    expect(find.text('Tên địa điểm'), findsOneWidget);
    expect(find.text('Vị trí'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);
  });

  testWidgets('saved place becomes the nearby search center', (tester) async {
    SharedPreferences.setMockInitialValues({
      'social_nearby_saved_places_v1': [
        jsonEncode({
          'name': 'Nhà',
          'formattedAddress': '30 Tân Thắng',
          'latitude': 10.8,
          'longitude': 106.6,
        }),
      ],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: SocialNearbyFilter()),
      ),
    ));
    await tester.tap(find.text('Gần bạn'));
    await tester.pumpAndSettle();
    expect(find.text('Nhà'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(container.read(socialFilterProvider).nearbyOnly, isTrue);
    expect(container.read(userLocationProvider).latitude, 10.8);
    expect(container.read(userLocationProvider).longitude, 106.6);
  });
}
