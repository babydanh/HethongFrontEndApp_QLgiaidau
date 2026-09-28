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
  testWidgets(
    'searches a province then its ward inline and composes the address',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      SocialRegionSelection? selection;
      var address = '22 Cộng Hòa';
      final repository = _FakeRegionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            regionRepositoryProvider.overrideWith((ref) => repository),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    SocialRegionPicker(
                      onChanged: (value) {
                        address = value.composeAddress(
                          address,
                          previousSelection: selection,
                        );
                        selection = value;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Chọn tỉnh/thành và phường/xã (không bắt buộc)'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('social-region-province-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('social-region-ward-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('social-region-picker-toggle')),
        findsNothing,
      );

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

      expect(
        selection?.composeAddress('22 Cộng Hòa'),
        '22 Cộng Hòa, Phường 1, Thành phố Hồ Chí Minh',
      );
      expect(find.text('Phường 1, Thành phố Hồ Chí Minh'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(provinceField).controller?.text,
        'Thành phố Hồ Chí Minh',
      );
      expect(
        tester.widget<TextFormField>(wardField).controller?.text,
        'Phường 1',
      );
      await tester.tap(provinceField);
      await tester.enterText(provinceField, 'Hà Nội');
      await tester.pumpAndSettle();
      final hanoiOption = find.text('Thành phố Hà Nội');
      expect(hanoiOption, findsOneWidget);
      await tester.tap(hanoiOption);
      await tester.pumpAndSettle();
      expect(selection?.province?.code, '01');
      expect(selection?.ward, isNull);
      expect(repository.lastProvinceCode, '01');
      expect(tester.widget<TextFormField>(wardField).controller?.text, '');
      expect(address, '22 Cộng Hòa, Thành phố Hà Nội');
      await tester.tap(wardField);
      await tester.enterText(wardField, 'Trúc');
      await tester.pumpAndSettle();
      final hanoiWardOption = find.text('Phường Trúc Bạch');
      expect(hanoiWardOption, findsOneWidget);
      await tester.tap(hanoiWardOption);
      await tester.pumpAndSettle();
      expect(address, '22 Cộng Hòa, Phường Trúc Bạch, Thành phố Hà Nội');
      expect(find.byType(SocialRegionPicker), findsOneWidget);
      expect(find.text('Thay đổi khu vực'), findsNothing);
      expect(
        find.byKey(const ValueKey('social-region-picker-toggle')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
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
    expect(
      find.text('Chọn tỉnh/thành và phường/xã (không bắt buộc)'),
      findsOneWidget,
    );

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
  testWidgets('region lookup retries without blocking manual address', (
    tester,
  ) async {
    final addressController = TextEditingController(text: '22 Cộng Hòa');
    final repository = _FakeRegionRepository(failProvinces: true);
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
                  TextFormField(
                    key: const ValueKey('manual-address-input'),
                    controller: addressController,
                  ),
                  SocialRegionPicker(onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final provinceField = find.byKey(
      const ValueKey('social-region-province-input'),
    );
    final manualAddress = find.byKey(const ValueKey('manual-address-input'));
    expect(tester.widget<TextFormField>(provinceField).enabled, isFalse);
    expect(tester.widget<TextFormField>(manualAddress).enabled, isTrue);
    expect(
      tester.widget<TextFormField>(manualAddress).controller?.text,
      '22 Cộng Hòa',
    );
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    repository.failProvinces = false;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(provinceField).enabled, isTrue);
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(tester.takeException(), isNull);
    addressController.dispose();
  });
}

class _FakeRegionRepository implements IRegionRepository {
  _FakeRegionRepository({this.failProvinces = false});

  bool failProvinces;
  String? lastProvinceCode;

  @override
  Future<List<Region>> getProvinces() async {
    if (failProvinces) throw StateError('Region service unavailable');
    return const [
      Region(code: '79', name: 'Thành phố Hồ Chí Minh'),
      Region(code: '01', name: 'Thành phố Hà Nội'),
    ];
  }

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async {
    lastProvinceCode = provinceCode;
    return provinceCode == '79'
        ? const [Region(code: '760', name: 'Phường 1')]
        : const [Region(code: '001', name: 'Phường Trúc Bạch')];
  }
}
