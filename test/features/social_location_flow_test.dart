import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_flow.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_location_picker.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _place = SocialPlace(
  name: 'Nhà thi đấu Phú Thọ',
  formattedAddress: '1 Lữ Gia, Hồ Chí Minh, Việt Nam',
  latitude: 10.762,
  longitude: 106.657,
);

class _PlaceRepository implements ISocialLocationRepository {
  Future<List<SocialPlace>> Function(String)? onSearch;
  Future<SocialPlace> Function(String)? onResolve;
  Future<SocialPlace> Function(LatLng)? onReverse;

  @override
  Future<List<SocialPlace>> search(String query) =>
      onSearch?.call(query) ?? Future.value([_place]);
  @override
  Future<SocialPlace> resolveInput(String value) =>
      onResolve?.call(value) ?? Future.value(_place);
  @override
  Future<SocialPlace> reverseLookup(LatLng pin) =>
      onReverse?.call(pin) ?? Future.value(_place);
}

void main() {
  Future<List<SocialPlace?>> pumpFlow(
    WidgetTester tester,
    _PlaceRepository repo,
  ) async {
    final applied = <SocialPlace?>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [socialLocationRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    applied.add(await SocialLocationFlow.show(context)),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return applied;
  }

  testWidgets('search result applies a place and closes the sheet', (
    tester,
  ) async {
    final applied = await pumpFlow(tester, _PlaceRepository());
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Phú Thọ');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Nhà thi đấu Phú Thọ'), findsOneWidget);
    expect(find.text('1 Lữ Gia, Hồ Chí Minh, Việt Nam'), findsOneWidget);
    await tester.tap(find.text('Nhà thi đấu Phú Thọ'));
    await tester.pumpAndSettle();
    expect(applied.single?.name, _place.name);
  });

  testWidgets('stale search responses cannot replace newer results', (
    tester,
  ) async {
    final oldQuery = Completer<List<SocialPlace>>();
    final newQuery = Completer<List<SocialPlace>>();
    final repo = _PlaceRepository()
      ..onSearch = (query) =>
          query == 'old' ? oldQuery.future : newQuery.future;
    await pumpFlow(tester, repo);
    await tester.enterText(find.byType(TextField).first, 'old');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField).first, 'new');
    await tester.pump(const Duration(milliseconds: 500));
    newQuery.complete([_place]);
    await tester.pump();
    oldQuery.complete([
      const SocialPlace(name: 'Wrong', formattedAddress: 'Wrong street'),
    ]);
    await tester.pump();
    expect(find.text('Nhà thi đấu Phú Thọ'), findsOneWidget);
    expect(find.text('Wrong'), findsNothing);
  });

  testWidgets('empty and error states keep add action and permit retry', (
    tester,
  ) async {
    var attempts = 0;
    final repo = _PlaceRepository()
      ..onSearch = (_) async {
        attempts++;
        if (attempts == 1) throw const LocationNetworkFailure();
        return [];
      };
    await pumpFlow(tester, repo);
    await tester.enterText(find.byType(TextField).first, 'missing');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Could not search locations.'), findsOneWidget);
    expect(find.text('Add new location'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('No matching locations found.'), findsOneWidget);
  });

  testWidgets('input preview changes location only on confirmation', (
    tester,
  ) async {
    final applied = await pumpFlow(tester, _PlaceRepository());
    await tester.tap(find.text('Add new location'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Next'))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField).last, '1 Lữ Gia');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm location'), findsWidgets);
    expect(applied, isEmpty);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('1 Lữ Gia'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(applied.single?.formattedAddress, _place.formattedAddress);
  });

  testWidgets('unsupported link keeps input and does not apply a place', (
    tester,
  ) async {
    final repo = _PlaceRepository()
      ..onResolve = (_) async => throw const UnsupportedLocationLink();
    final applied = await pumpFlow(tester, repo);
    await tester.tap(find.text('Add new location'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'https://evil.example/maps',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Next'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.text('This Google Maps link is not supported.'),
      findsOneWidget,
    );
    expect(applied, isEmpty);
  });

  testWidgets('network failure keeps the entered address for retry', (
    tester,
  ) async {
    final repo = _PlaceRepository()
      ..onResolve = (_) async => throw const LocationNetworkFailure();
    final applied = await pumpFlow(tester, repo);
    await tester.tap(find.text('Add new location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '1 Lữ Gia');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.text('The location service is unavailable. Please retry.'),
      findsOneWidget,
    );
    expect(find.text('1 Lữ Gia'), findsOneWidget);
    expect(applied, isEmpty);
  });

  testWidgets('a Google Maps link resolves then waits for confirmation', (
    tester,
  ) async {
    String? resolved;
    final repo = _PlaceRepository()
      ..onResolve = (input) async {
        resolved = input;
        return _place;
      };
    final applied = await pumpFlow(tester, repo);
    await tester.tap(find.text('Add new location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '   ');
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Next'))
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byType(TextField).last,
      'https://www.google.com/maps?q=1+Lu+Gia',
    );
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(resolved, 'https://www.google.com/maps?q=1+Lu+Gia');
    expect(applied, isEmpty);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(applied.single?.name, _place.name);
  });

  testWidgets('an incomplete resolved place cannot reach confirmation', (
    tester,
  ) async {
    final repo = _PlaceRepository()
      ..onResolve = (_) async => const SocialPlace(
        name: 'Incomplete',
        formattedAddress: '',
        latitude: 10.7,
        longitude: 106.7,
      );
    final applied = await pumpFlow(tester, repo);
    await tester.tap(find.text('Add new location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'unknown address');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A full street address'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    expect(applied, isEmpty);
  });

  testWidgets(
    'map confirmation reverse looks up a pin and applies its address',
    (tester) async {
      LatLng? lookedUp;
      final repo = _PlaceRepository()
        ..onReverse = (pin) async {
          lookedUp = pin;
          return SocialPlace(
            name: _place.name,
            formattedAddress: _place.formattedAddress,
            latitude: pin.latitude,
            longitude: pin.longitude,
          );
        };
      final applied = await pumpFlow(tester, repo);
      await tester.tap(find.text('Add new location'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'draft address');
      await tester.pump();
      await tester.tap(find.text('Choose from map'));
      await tester.pumpAndSettle();
      expect(find.byType(SocialLocationPicker), findsOneWidget);
      expect(find.textContaining('10.77690'), findsNothing);
      await tester.tap(find.text('Confirm location'));
      await tester.pumpAndSettle();
      expect(lookedUp, isNotNull);
      expect(applied.single?.formattedAddress, _place.formattedAddress);
    },
  );

  testWidgets(
    'failed reverse lookup preserves the input and offers map retry',
    (tester) async {
      final repo = _PlaceRepository()
        ..onReverse = (_) async => throw const UnresolvableLocation();
      final applied = await pumpFlow(tester, repo);
      await tester.tap(find.text('Add new location'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'draft address');
      await tester.pump();
      await tester.tap(find.text('Choose from map'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm location'));
      await tester.pumpAndSettle();
      expect(find.text('draft address'), findsOneWidget);
      expect(
        find.textContaining('Could not find a full address'),
        findsOneWidget,
      );
      expect(find.text('Choose from map'), findsOneWidget);
      expect(applied, isEmpty);
    },
  );

  testWidgets(
    'canceling the map keeps draft input and leaves the form unchanged',
    (tester) async {
      final applied = await pumpFlow(tester, _PlaceRepository());
      await tester.tap(find.text('Add new location'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'draft address');
      await tester.pump();
      await tester.tap(find.text('Choose from map'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();
      expect(find.text('draft address'), findsOneWidget);
      expect(applied, isEmpty);
    },
  );

  testWidgets(
    'input remains usable on a narrow screen with the keyboard focused',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpFlow(tester, _PlaceRepository());
      await tester.tap(find.text('Add new location'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField).last);
      await tester.enterText(find.byType(TextField).last, '1 Lữ Gia');
      await tester.pump();
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('area results show a no-pin note and apply on tap', (
    tester,
  ) async {
    const area = SocialPlace(
      name: 'Phường Bình Trưng',
      formattedAddress: 'Phường Bình Trưng, TP Hồ Chí Minh',
    );
    final repo = _PlaceRepository()..onSearch = (_) async => [area];
    final applied = await pumpFlow(tester, repo);
    await tester.enterText(find.byType(TextField).first, 'Bình Trưng');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Administrative areas'), findsOneWidget);
    expect(find.textContaining('No map pin'), findsOneWidget);
    await tester.tap(find.text('Phường Bình Trưng'));
    await tester.pumpAndSettle();
    expect(applied.single?.formattedAddress, area.formattedAddress);
  });

  testWidgets('region-only resolve cannot skip the pinned preview', (
    tester,
  ) async {
    const area = SocialPlace(
      name: 'Phường Bình Trưng',
      formattedAddress: 'Phường Bình Trưng, TP Hồ Chí Minh',
    );
    final repo = _PlaceRepository()..onResolve = (_) async => area;
    final applied = await pumpFlow(tester, repo);
    await tester.tap(find.text('Add new location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Bình Trưng');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A full street address'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    expect(applied, isEmpty);
    expect(find.text('Bình Trưng'), findsOneWidget);
  });
}
