import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_inline_map.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_row.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_location_picker.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _pinRequired = 'Kéo ghim đến đúng sân';

class _FakeLocationRepository implements ISocialLocationRepository {
  _FakeLocationRepository({
    this.results = const [],
    this.reverse,
    this.failure,
  });

  final List<SocialPlace> results;
  final SocialPlace? reverse;
  final Object? failure;
  final reverseCalls = <LatLng>[];

  @override
  Future<SocialPlace> reverseLookup(LatLng pin) async {
    reverseCalls.add(pin);
    if (failure != null) throw failure!;
    return reverse!;
  }

  @override
  Future<List<SocialPlace>> search(
    String query, {
    LatLng? bias,
    String? categoryId,
    bool requirePin = true,
  }) async => results;

  @override
  Future<SocialPlace> getVenueDetail(String venueId) =>
      throw UnimplementedError();

  @override
  Future<SocialPlace> getPlaceDetail(String placeId) =>
      throw UnimplementedError();

  @override
  Future<SocialPlace> resolveInput(String addressOrMapsUrl) =>
      throw UnimplementedError();
}

const _hcm = Region(code: '79', name: 'Thành phố Hồ Chí Minh');
const _empty = Region(code: '99', name: 'Tỉnh không phường');
const _benNghe = Region(
  code: '79-001',
  name: 'Phường Bến Nghé',
  provinceCode: '79',
  latitude: 10.78,
  longitude: 106.70,
);
const _noCenter = Region(
  code: '79-002',
  name: 'Phường Không Tâm',
  provinceCode: '79',
);

class _FakeRegionRepository implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => const [_hcm, _empty];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async =>
      provinceCode == '79' ? const [_benNghe, _noCenter] : const [];

  @override
  Future<List<Region>> searchRegions(String query, {int limit = 10}) async =>
      const [];
}

class _FakeUserLocation extends UserLocationNotifier {
  @override
  Future<void> useCurrentPosition() async {
    state = const UserLocationState(
      status: UserLocationStatus.granted,
      latitude: 10.80,
      longitude: 106.71,
    );
  }
}

const _resolved = SocialPlace(
  name: 'Phường Bến Nghé',
  formattedAddress: 'Phường Bến Nghé, Thành phố Hồ Chí Minh',
  provinceCode: '79',
  wardCode: '79-001',
);

const _venue = SocialPlace(
  name: 'Sân Tao Đàn',
  formattedAddress: '1 Yersin, Phường Bến Thành',
  latitude: 10.77,
  longitude: 106.69,
  venueId: 'venue-1',
  provinceCode: '79',
  wardCode: '79-001',
);

const _venueNoPin = SocialPlace(
  name: 'Sân chưa ghim',
  formattedAddress: '2 Nguyễn Huệ',
  venueId: 'venue-2',
);

class _Harness {
  SocialPlace? latest;
}

/// Hosts the compact row like the create screen does: tapping it opens the
/// location sheet and the returned place becomes the row summary.
class _Host extends StatefulWidget {
  const _Host({required this.harness});

  final _Harness harness;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  Future<void> _open() async {
    final place = await SocialLocationSheet.show(
      context,
      initialPlace: widget.harness.latest,
    );
    if (place != null && mounted) {
      setState(() => widget.harness.latest = place);
    }
  }

  @override
  Widget build(BuildContext context) =>
      SocialLocationRow(place: widget.harness.latest, onTap: _open);
}

Future<_Harness> _pump(
  WidgetTester tester,
  _FakeLocationRepository repository, {
  bool open = true,
  SocialPlace? initial,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final harness = _Harness()..latest = initial;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialLocationRepositoryProvider.overrideWithValue(repository),
        regionRepositoryProvider.overrideWithValue(_FakeRegionRepository()),
        userLocationProvider.overrideWith(_FakeUserLocation.new),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: _Host(harness: harness)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (open) await _openSheet(tester);
  return harness;
}

/// Taps the compact summary row, which opens the sheet.
Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byType(SocialLocationRow));
  await tester.pumpAndSettle();
}

Future<void> _typeName(WidgetTester tester, String text) async {
  await tester.enterText(
    find.byKey(const ValueKey('social-inline-name')),
    text,
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// Taps the map away from the pin and the "my location" button.
Future<void> _tapMap(WidgetTester tester) async {
  final topLeft = tester.getTopLeft(find.byType(FlutterMap));
  await tester.tapAt(topLeft + const Offset(40, 100));
  // flutter_map reports a tap only after its double-tap window closes.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String field, String label) async {
  await tester.tap(find.byKey(ValueKey(field)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) => tester
    .widget<DropdownMenu<Region>>(find.byKey(ValueKey(key)))
    .controller!
    .text;

SocialLocationInlineMap _map(WidgetTester tester) => tester
    .widget<SocialLocationInlineMap>(find.byType(SocialLocationInlineMap));

Finder get _confirmButton => find.widgetWithText(FilledButton, 'Xác nhận');

bool _confirmEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_confirmButton).onPressed != null;

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(_confirmButton);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  testWidgets('TC-SOCIAL-INLINE-APP-01 suggestion picks an existing venue', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      _FakeLocationRepository(results: const [_venue]),
    );
    expect(find.byType(FlutterMap), findsOneWidget);

    await _typeName(tester, 'Tao Đàn');
    expect(find.text('Sân Tao Đàn'), findsOneWidget);
    await tester.tap(find.text('Sân Tao Đàn'));
    await tester.pumpAndSettle();

    // The sheet stays open on the venue; confirming returns it with venueId.
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(_confirmEnabled(tester), isTrue);
    await _confirm(tester);
    expect(harness.latest?.venueId, 'venue-1');
  });

  testWidgets('TC-SOCIAL-INLINE-APP-02 draft pin is not a confirmed place', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(reverse: _resolved);
    final harness = await _pump(tester, repository);
    await _typeName(tester, 'Sân nhà anh Tuấn');

    // The draft pin starts at the HCMC centre and still blocks confirming.
    expect(find.text(_pinRequired), findsOneWidget);
    expect(_confirmEnabled(tester), isFalse);
    expect(_map(tester).pin, const LatLng(10.7769, 106.7009));
    expect(repository.reverseCalls, isEmpty);

    await _tapMap(tester);
    expect(find.text(_pinRequired), findsNothing);
    await _confirm(tester);
    expect(harness.latest?.hasPin, isTrue);
    expect(harness.latest?.venueId, isNull);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-03 confirmed pin fills province and ward', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(reverse: _resolved);
    final harness = await _pump(tester, repository);
    await _typeName(tester, 'Sân nhà anh Tuấn');
    await _tapMap(tester);

    expect(repository.reverseCalls, hasLength(1));
    expect(_text(tester, 'social-inline-province'), _hcm.name);
    expect(_text(tester, 'social-inline-ward'), _benNghe.name);
    await _confirm(tester);
    // The coordinate is the pin, the address is administrative.
    expect(harness.latest?.name, 'Sân nhà anh Tuấn');
    expect(harness.latest?.formattedAddress, _resolved.formattedAddress);
    expect(harness.latest?.latitude, repository.reverseCalls.single.latitude);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-04 unresolved pin leaves boxes empty', (
    tester,
  ) async {
    for (final failure in <Object>[
      const UnresolvableLocation(),
      const LocationNetworkFailure(),
    ]) {
      // Drop the previous tree so each case starts closed again.
      await tester.pumpWidget(const SizedBox());
      final harness = await _pump(
        tester,
        _FakeLocationRepository(failure: failure),
      );
      await _typeName(tester, 'Sân ngoài vùng');
      await _tapMap(tester);

      expect(_text(tester, 'social-inline-province'), isEmpty);
      expect(_text(tester, 'social-inline-ward'), isEmpty);
      expect(_confirmEnabled(tester), isTrue);
      await _confirm(tester);
      expect(harness.latest?.hasPin, isTrue);
      expect(harness.latest?.name, 'Sân ngoài vùng');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('TC-SOCIAL-INLINE-APP-05 decide later hides the map', (
    tester,
  ) async {
    final harness = await _pump(tester, _FakeLocationRepository());
    await tester.tap(find.byKey(const ValueKey('social-inline-deferred')));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsNothing);
    expect(find.byKey(const ValueKey('social-inline-name')), findsNothing);
    expect(_confirmEnabled(tester), isTrue);

    await tester.tap(find.byKey(const ValueKey('social-inline-deferred')));
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(_confirmEnabled(tester), isFalse);

    await tester.tap(find.byKey(const ValueKey('social-inline-deferred')));
    await tester.pumpAndSettle();
    await _confirm(tester);
    expect(harness.latest?.isDeferred, isTrue);
    expect(find.text('Quyết định sau'), findsOneWidget);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-06 ward centre moves the draft pin only', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(reverse: _resolved);
    await _pump(tester, repository);
    await _typeName(tester, 'Sân nhà anh Tuấn');
    await _tapMap(tester);
    expect(_confirmEnabled(tester), isTrue);

    await _choose(tester, 'social-inline-province', _hcm.name);
    await _choose(tester, 'social-inline-ward', _benNghe.name);
    expect(_map(tester).pin, const LatLng(10.78, 106.70));
    // The moved pin is a draft again: not confirmed, no reverse lookup.
    expect(_confirmEnabled(tester), isFalse);
    expect(find.text(_pinRequired), findsOneWidget);
    expect(repository.reverseCalls, hasLength(1));

    await _choose(tester, 'social-inline-ward', _noCenter.name);
    expect(_map(tester).pin, const LatLng(10.78, 106.70));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-07 province without wards does not crash', (
    tester,
  ) async {
    await _pump(tester, _FakeLocationRepository());
    await _choose(tester, 'social-inline-province', _empty.name);

    expect(_text(tester, 'social-inline-ward'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-08 my location confirms the pin', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(reverse: _resolved);
    final harness = await _pump(tester, repository);
    await _typeName(tester, 'Sân nhà anh Tuấn');
    await tester.tap(find.byTooltip('Vị trí của tôi'));
    await tester.pumpAndSettle();
    await _confirm(tester);

    expect(harness.latest?.latitude, 10.80);
    expect(harness.latest?.longitude, 106.71);
    expect(repository.reverseCalls, hasLength(1));
  });

  testWidgets('TC-SOCIAL-INLINE-APP-09 row is compact until tapped', (
    tester,
  ) async {
    await _pump(tester, _FakeLocationRepository(), open: false);

    expect(find.byType(SocialLocationRow), findsOneWidget);
    expect(find.text('Chọn địa điểm'), findsOneWidget);
    expect(find.byType(SocialLocationSheet), findsNothing);
    expect(find.byType(FlutterMap), findsNothing);

    await _openSheet(tester);
    expect(find.byType(SocialLocationSheet), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(SocialLocationSheet), findsNothing);
    expect(find.text('Chọn địa điểm'), findsOneWidget);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-13 map lives in one sheet, no 2nd popup', (
    tester,
  ) async {
    await _pump(tester, _FakeLocationRepository());
    await _typeName(tester, 'Sân nhà anh Tuấn');
    await _tapMap(tester);

    // Only the host Scaffold: no full-screen picker route, no dialog.
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SocialLocationPicker), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-14 confirm needs a name and a pinned map', (
    tester,
  ) async {
    await _pump(tester, _FakeLocationRepository(reverse: _resolved));
    expect(_confirmEnabled(tester), isFalse);

    // A confirmed pin alone is not enough: the name is required too.
    await _tapMap(tester);
    expect(_confirmEnabled(tester), isFalse);
    await _typeName(tester, 'Sân nhà anh Tuấn');
    expect(_confirmEnabled(tester), isTrue);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-15 picking a suggestion shows its map', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      _FakeLocationRepository(results: const [_venue]),
    );
    await _typeName(tester, 'Tao Đàn');
    await tester.tap(find.text('Sân Tao Đàn'));
    await tester.pumpAndSettle();

    // No pop yet: the map jumps to the venue and confirm is already on.
    expect(find.byType(SocialLocationSheet), findsOneWidget);
    expect(_map(tester).pin, const LatLng(10.77, 106.69));
    expect(find.text(_pinRequired), findsNothing);
    expect(find.text('Sân có sẵn: vị trí lấy từ danh bạ'), findsOneWidget);
    expect(harness.latest, isNull);

    await _confirm(tester);
    expect(find.byType(SocialLocationSheet), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SocialLocationRow),
        matching: find.text('Sân Tao Đàn'),
      ),
      findsOneWidget,
    );
    expect(harness.latest?.venueId, 'venue-1');
  });

  testWidgets('TC-SOCIAL-INLINE-APP-16 edit mode keeps the old address', (
    tester,
  ) async {
    const old = SocialPlace(
      name: 'Sân cũ',
      formattedAddress: 'Số 1, Đường A',
      latitude: 10.5,
      longitude: 106.5,
    );
    final harness = await _pump(
      tester,
      _FakeLocationRepository(),
      initial: old,
    );

    // The old pin counts as confirmed, so the sheet can be confirmed as is.
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(_confirmEnabled(tester), isTrue);
    await _confirm(tester);
    expect(harness.latest?.formattedAddress, 'Số 1, Đường A');
    expect(harness.latest?.latitude, 10.5);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-17 venue pin is fixed, region from codes', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(results: const [_venue]);
    final harness = await _pump(tester, repository);
    await _typeName(tester, 'Tao Đàn');
    await tester.tap(find.text('Sân Tao Đàn'));
    await tester.pumpAndSettle();

    expect(_text(tester, 'social-inline-province'), _hcm.name);
    expect(_text(tester, 'social-inline-ward'), _benNghe.name);
    expect(find.byTooltip('Vị trí của tôi'), findsNothing);

    await _tapMap(tester);
    expect(_map(tester).pin, const LatLng(10.77, 106.69));
    expect(repository.reverseCalls, isEmpty);
    await _confirm(tester);
    expect(harness.latest?.latitude, 10.77);
    expect(harness.latest?.longitude, 106.69);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-18 clearing the venue restores the draft', (
    tester,
  ) async {
    await _pump(tester, _FakeLocationRepository(results: const [_venue]));
    await _typeName(tester, 'Tao Đàn');
    await tester.tap(find.text('Sân Tao Đàn'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa vị trí'));
    await tester.pumpAndSettle();
    expect(_map(tester).pin, const LatLng(10.7769, 106.7009));
    expect(find.text(_pinRequired), findsOneWidget);
    expect(_confirmEnabled(tester), isFalse);
    expect(_text(tester, 'social-inline-province'), isEmpty);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-19 reopening on a venue shows its map', (
    tester,
  ) async {
    await _pump(tester, _FakeLocationRepository(), initial: _venue);

    expect(_map(tester).pin, const LatLng(10.77, 106.69));
    expect(_confirmEnabled(tester), isTrue);
    expect(_text(tester, 'social-inline-province'), _hcm.name);
  });

  testWidgets('TC-SOCIAL-INLINE-APP-20 venue without coordinates has no map', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      _FakeLocationRepository(results: const [_venueNoPin]),
    );
    await _typeName(tester, 'Chưa ghim');
    await tester.tap(find.text('Sân chưa ghim'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsNothing);
    expect(_confirmEnabled(tester), isTrue);
    await _confirm(tester);
    expect(harness.latest?.venueId, 'venue-2');
  });
}
