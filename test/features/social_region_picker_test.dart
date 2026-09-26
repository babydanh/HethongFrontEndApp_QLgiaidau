import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_region_picker.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('searches a province then its ward and composes the address', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    SocialRegionSelection? selection;
    final repository = _FakeRegionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [regionRepositoryProvider.overrideWith((ref) => repository)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SocialRegionPicker(onChanged: (value) => selection = value),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('social-region-picker-toggle')));
    await tester.pumpAndSettle();

    final provinceField = find.byKey(
      const ValueKey('social-region-province-input'),
    );
    await tester.tap(provinceField);
    await tester.enterText(provinceField, 'Hồ Chí Minh');
    await tester.pumpAndSettle();
    final provinceOption = find.text('Thành phố Hồ Chí Minh');
    expect(provinceOption, findsOneWidget);
    await tester.tap(provinceOption);
    await tester.pumpAndSettle();

    final wardField = find.byKey(const ValueKey('social-region-ward-input'));
    expect(repository.lastProvinceCode, '79');
    expect(tester.widget<TextFormField>(wardField).enabled, isTrue);
    await tester.tap(wardField);
    await tester.enterText(wardField, 'Phường 1');
    await tester.pumpAndSettle();
    final wardOption = find.descendant(
      of: find.byType(ListTile),
      matching: find.text('Phường 1'),
    );
    expect(wardOption, findsOneWidget);
    await tester.tap(wardOption);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('social-region-apply')));
    await tester.pumpAndSettle();

    expect(
      selection?.composeAddress('22 Cộng Hòa'),
      '22 Cộng Hòa, Phường 1, Thành phố Hồ Chí Minh',
    );
    await tester.tap(find.byKey(const ValueKey('social-region-picker-toggle')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(provinceField).controller?.text,
      'Thành phố Hồ Chí Minh',
    );
    expect(
      tester.widget<TextFormField>(wardField).controller?.text,
      'Phường 1',
    );
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('region picker fits a 360px viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          regionRepositoryProvider.overrideWith(
            (ref) => _FakeRegionRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [SocialRegionPicker(onChanged: (_) {})]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('social-region-picker-toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('social-region-province-input')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('social-region-ward-input')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _FakeRegionRepository implements IRegionRepository {
  String? lastProvinceCode;

  @override
  Future<List<Region>> getProvinces() async => const [
    Region(code: '79', name: 'Thành phố Hồ Chí Minh'),
  ];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async {
    lastProvinceCode = provinceCode;
    return const [Region(code: '760', name: 'Phường 1')];
  }
}
