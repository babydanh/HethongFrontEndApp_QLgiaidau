import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_region_picker.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget coverage for the inline ward/commune -> province/city control on the
/// Social create form.
///
/// The control is part of the form — no modal. It is backed only by the
/// existing `IRegionRepository` plus the deterministic `VietnamAddressParser`:
/// a full typed address proposes a ward + city that the user can apply, the
/// attached club's province only narrows that inference, and the manual ward
/// search stays open for correction. Apply composes locality names into the
/// current address.
void main() {
  group('Social inline area control', () {
    testWidgets('the area control is part of the form, not a modal', (
      tester,
    ) async {
      final repository = _FakeRegionRepository();
      await _pumpSocialForm(tester, regionRepository: repository);

      // No entry point to open: the ward search, the state message and the
      // retry control are on the form itself, right after the address.
      expect(find.byType(SocialRegionPicker), findsOneWidget);
      expect(textCI('Khu vực (không bắt buộc)'), findsOneWidget);
      expect(textCI('Phường/Xã'), findsOneWidget);
      expect(_wardSearch(), findsOneWidget);
      expect(textCI('Nhập ít nhất 2 ký tự để tìm phường/xã.'), findsOneWidget);
      expect(find.text('Phường Mỹ Đình'), findsNothing);
      expect(find.text('Hà Nội'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(repository.wardRequests, <String>['']);

      // The whole flow — search, pick, apply — stays on the form.
      await _ensureAreaVisible(tester);
      await _searchWard(tester, 'Mỹ');
      await _selectOption(tester, 'Phường Mỹ Đình');
      expect(find.text('Áp dụng'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ward search requires two characters and caps results', (
      tester,
    ) async {
      final wards = List<Region>.generate(
        51,
        (index) => Region.fromJson({
          'code': 'HN-${index.toString().padLeft(3, '0')}',
          'name': 'Phường Test ${index.toString().padLeft(2, '0')}',
          'provinceCode': '01',
        }),
      );
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(wardRows: wards),
      );
      await _ensureAreaVisible(tester);

      await _searchWard(tester, 'P');
      expect(textCI('Nhập ít nhất 2 ký tự để tìm phường/xã.'), findsOneWidget);

      await _searchWard(tester, 'Phường');
      expect(find.text('Phường Test 00'), findsOneWidget);
      expect(find.text('Phường Test 49'), findsOneWidget);
      expect(find.text('Phường Test 50'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('duplicate ward names are disambiguated by city', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(
          wardRows: [
            Region.fromJson({
              'code': '01-101',
              'name': 'Phường An Phú',
              'provinceCode': '01',
            }),
            Region.fromJson({
              'code': '48-101',
              'name': 'Phường An Phú',
              'provinceCode': '48',
            }),
          ],
        ),
      );
      await _ensureAreaVisible(tester);
      await _searchWard(tester, 'An Phú');

      expect(find.text('Hà Nội'), findsOneWidget);
      expect(find.text('Đà Nẵng'), findsOneWidget);
      await _tapVisible(
        tester,
        find.ancestor(of: find.text('Đà Nẵng'), matching: find.byType(InkWell)),
      );
      await _pumpUi(tester);

      await _tapVisible(tester, find.text('Áp dụng'));
      expect(find.text('Phường An Phú, Đà Nẵng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'a full typed address proposes a ward and city that compose into the request',
      (tester) async {
        final socialRepository = _RecordingSocialSessionRepository();
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
          socialRepository: socialRepository,
        );
        await tester.enterText(_venueNameField(), _manualVenue);
        await _ensureAreaVisible(tester);
        await tester.enterText(_addressField(), _myDinhAddress);
        await _pumpUi(tester);

        // The proposal is visible on the form without opening anything.
        expect(find.text(_myDinhSummary), findsOneWidget);
        expect(find.text('Áp dụng'), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);

        await _tapVisible(tester, find.text('Áp dụng'));

        expect(find.text(_myDinhSummary), findsOneWidget);
        expect(find.text('Áp dụng'), findsNothing);
        expect(_addressText(tester), _myDinhAddress);

        await _submit(tester);
        expect(socialRepository.creates, hasLength(1));
        final address = socialRepository.creates.single.venueAddress;
        expect(address, contains('Hà Nội'));
        expect('Hà Nội'.allMatches(address).length, 1);
        expect('Phường Mỹ Đình'.allMatches(address).length, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'the attached club province grounds a ward when the address names no city',
      (tester) async {
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
          club: _club(provinceCode: '79'),
        );
        await _ensureAreaVisible(tester);
        await tester.enterText(_addressField(), _benThanhAddress);
        await _pumpUi(tester);

        expect(find.text(_benThanhSummary), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the club province limits the ward inference to its own city', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        club: _club(provinceCode: '79'),
      );
      await _ensureAreaVisible(tester);
      // A Hanoi ward must not be proposed while the club sits in TP.HCM.
      await tester.enterText(
        _addressField(),
        '202 Hoàng Văn Thụ, Phường Mỹ Đình',
      );
      await _pumpUi(tester);

      expect(find.text(_myDinhSummary), findsNothing);
      expect(find.text('Áp dụng'), findsNothing);
      expect(_addressText(tester), '202 Hoàng Văn Thụ, Phường Mỹ Đình');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a city named in the address wins over the club province', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        club: _club(provinceCode: '79'),
      );
      await _ensureAreaVisible(tester);
      await tester.enterText(
        _addressField(),
        '202 Hoàng Văn Thụ, Phường Mỹ Đình, Hà Nội',
      );
      await _pumpUi(tester);

      expect(find.text(_myDinhSummary), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TP.HCM written in the address wins over a Hanoi club', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        club: _club(provinceCode: '01'),
      );
      await _ensureAreaVisible(tester);
      await tester.enterText(
        _addressField(),
        '120 Nguyễn Thị Minh Khai, Phường Bến Thành, TP.HCM',
      );
      await _pumpUi(tester);

      expect(find.text(_benThanhSummary), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'applying a locality does not duplicate a recognized city alias',
      (tester) async {
        final socialRepository = _RecordingSocialSessionRepository();
        const typedAddress =
            '120 Nguyễn Thị Minh Khai, Phường Bến Thành, TP.HCM';
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
          club: _club(provinceCode: '01'),
          socialRepository: socialRepository,
        );
        await tester.enterText(_venueNameField(), _manualVenue);
        await _ensureAreaVisible(tester);
        await tester.enterText(_addressField(), typedAddress);
        await _pumpUi(tester);

        expect(find.text(_benThanhSummary), findsOneWidget);
        await _tapVisible(tester, find.text('Áp dụng'));
        await _submit(tester);

        final savedAddress = socialRepository.creates.single.venueAddress;
        expect(savedAddress, contains('TP.HCM'));
        expect(savedAddress, isNot(contains('TP. Hồ Chí Minh')));
        expect('Phường Bến Thành'.allMatches(savedAddress), hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('ward-only text without any context is not proposed', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        clubId: '',
        clubName: '',
      );
      await _ensureAreaVisible(tester);
      await tester.enterText(
        _addressField(),
        '202 Hoàng Văn Thụ, Phường Mỹ Đình',
      );
      await _pumpUi(tester);

      expect(find.text('Áp dụng'), findsNothing);
      expect(_addressText(tester), '202 Hoàng Văn Thụ, Phường Mỹ Đình');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the manual search corrects a proposed area', (tester) async {
      final socialRepository = _RecordingSocialSessionRepository();
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        club: _club(provinceCode: '79'),
        socialRepository: socialRepository,
      );
      await tester.enterText(_venueNameField(), _manualVenue);
      await _ensureAreaVisible(tester);
      await tester.enterText(_addressField(), _myDinhAddress);
      await _pumpUi(tester);
      expect(find.text(_myDinhSummary), findsOneWidget);

      // A search supersedes the proposal; the proposal comes back on Cancel.
      await _searchWard(tester, 'Cầu');
      await _selectOption(tester, 'Phường Cầu Giấy');
      expect(find.text(_myDinhSummary), findsNothing);
      await _tapVisible(tester, find.text('Hủy'));
      expect(find.text(_myDinhSummary), findsOneWidget);

      await _searchWard(tester, 'Cầu');
      await _selectOption(tester, 'Phường Cầu Giấy');
      await _tapVisible(tester, find.text('Áp dụng'));
      expect(find.text(_cauGiaySummary), findsOneWidget);

      await _submit(tester);
      final address = socialRepository.creates.single.venueAddress;
      expect(address, endsWith('Phường Cầu Giấy'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cancel keeps the applied area and the typed address', (
      tester,
    ) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _applyMyDinh(tester);
      expect(_addressText(tester), _manualDetail);

      await _searchWard(tester, 'Cầu');
      await _selectOption(tester, 'Phường Cầu Giấy');
      await _tapVisible(tester, find.text('Hủy'));

      expect(find.text('Hủy'), findsNothing);
      expect(find.text(_myDinhSummary), findsOneWidget);
      expect(_addressText(tester), _manualDetail);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wards without a known province are not offered', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(
          wardRows: [
            Region.fromJson({
              'code': 'XX-001',
              'name': 'Phường Mồ Côi',
              'provinceCode': 'XX',
            }),
          ],
        ),
      );
      await _ensureAreaVisible(tester);
      await _searchWard(tester, 'Mồ Côi');

      expect(find.text('Phường Mồ Côi'), findsNothing);
      expect(textCI('Không tìm thấy kết quả.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'a region lookup failure leaves the manual address and create path open',
      (tester) async {
        final repository = _FakeRegionRepository(provinceFailures: 1);
        await _pumpSocialForm(tester, regionRepository: repository);

        expect(
          textCI(
            'Không tải được khu vực. Bạn vẫn có thể nhập địa chỉ thủ công.',
          ),
          findsOneWidget,
        );
        await _ensureAreaVisible(tester);
        await tester.tap(find.text('Thử lại'));
        await _pumpUi(tester);
        expect(_wardSearch(), findsOneWidget);
        expect(repository.wardRequests, <String>['']);
        expect(tester.takeException(), isNull);

        await tester.enterText(_venueNameField(), _manualVenue);
        await tester.enterText(_addressField(), _manualDetail);
        await _pumpUi(tester);
        expect(_addressText(tester), _manualDetail);
        expect(_submitAction(tester).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('retry re-queries the province catalog after a failure', (
      tester,
    ) async {
      final repository = _FakeRegionRepository(provinceFailures: 1);
      await _pumpSocialForm(tester, regionRepository: repository);
      expect(
        textCI('Không tải được khu vực. Bạn vẫn có thể nhập địa chỉ thủ công.'),
        findsOneWidget,
      );

      final callsBeforeRetry = repository.provinceCalls;
      await _ensureAreaVisible(tester);
      await tester.tap(find.text('Thử lại'));
      await _pumpUi(tester);

      expect(repository.provinceCalls, callsBeforeRetry + 1);
      expect(repository.wardRequests, <String>['']);
      expect(textCI('Nhập ít nhất 2 ký tự để tìm phường/xã.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty province data offers manual fallback and Retry', (
      tester,
    ) async {
      final repository = _FakeRegionRepository(provinceEmptyResponses: 1);
      await _pumpSocialForm(tester, regionRepository: repository);

      expect(
        textCI(
          'Khu vực hiện không khả dụng. Bạn vẫn có thể nhập địa chỉ thủ công.',
        ),
        findsOneWidget,
      );
      expect(find.text('Hà Nội'), findsNothing);
      final callsBeforeRetry = repository.provinceCalls;
      await _ensureAreaVisible(tester);
      await tester.tap(find.text('Thử lại'));
      await _pumpUi(tester);

      expect(repository.provinceCalls, callsBeforeRetry + 1);
      expect(repository.wardRequests, <String>['']);
      expect(
        textCI(
          'Khu vực hiện không khả dụng. Bạn vẫn có thể nhập địa chỉ thủ công.',
        ),
        findsNothing,
      );
      expect(textCI('Phường/Xã'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty ward data offers manual fallback and Retry', (
      tester,
    ) async {
      final repository = _FakeRegionRepository(wardEmptyResponses: 1);
      await _pumpSocialForm(tester, regionRepository: repository);

      expect(
        textCI(
          'Khu vực hiện không khả dụng. Bạn vẫn có thể nhập địa chỉ thủ công.',
        ),
        findsOneWidget,
      );
      expect(repository.wardRequests, <String>['']);

      await _ensureAreaVisible(tester);
      await tester.tap(find.text('Thử lại'));
      await _pumpUi(tester);
      expect(
        textCI(
          'Khu vực hiện không khả dụng. Bạn vẫn có thể nhập địa chỉ thủ công.',
        ),
        findsNothing,
      );
      expect(textCI('Nhập ít nhất 2 ký tự để tìm phường/xã.'), findsOneWidget);
      expect(repository.wardRequests, <String>['', '']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed club lookup still proposes from the typed city', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        club: _club(provinceCode: '48'),
        clubFailures: 1,
      );
      await _ensureAreaVisible(tester);
      await tester.enterText(
        _addressField(),
        '120 Trần Phú, Phường Hải Châu, Đà Nẵng',
      );
      await _pumpUi(tester);

      expect(find.text('Phường Hải Châu, Đà Nẵng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the inline area control stays usable at 360 px', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        club: _club(provinceCode: '01'),
        size: const Size(360, 844),
      );
      await _ensureAreaVisible(tester);
      await tester.enterText(
        _addressField(),
        '202 Hoàng Văn Thụ, Phường Mỹ Đình',
      );
      await _pumpUi(tester);

      expect(find.text(_myDinhSummary), findsOneWidget);
      expect(find.text('Áp dụng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

const _manualVenue = 'Sân 22 Cộng Hòa';
const _manualDetail = '202 Hoàng Văn Thụ, Quận 3';
const _myDinhAddress = '202 Hoàng Văn Thụ, Phường Mỹ Đình, Hà Nội';
const _myDinhSummary = 'Phường Mỹ Đình, Hà Nội';
const _cauGiaySummary = 'Phường Cầu Giấy, Hà Nội';
const _benThanhAddress = '120 Nguyễn Thị Minh Khai, Phường Bến Thành';
const _benThanhSummary = 'Phường Bến Thành, TP. Hồ Chí Minh';

/// Deterministic frame advance that also flushes the fake repository futures.
/// `pumpAndSettle` is avoided because a progress indicator would keep the
/// scheduler permanently busy.
Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

Future<void> _pumpSocialForm(
  WidgetTester tester, {
  required IRegionRepository regionRepository,
  ISocialSessionRepository? socialRepository,
  Community? club,
  int clubFailures = 0,
  String clubId = 'club-1',
  String clubName = 'CLB Cầu Lông Sài Gòn',
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final form = CreateSocialScreen(clubId: clubId, clubName: clubName);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith(
          (ref) async => [
            CategoryModel(
              id: 'cat-badminton',
              name: 'Cầu lông',
              slug: 'cau-long',
              description: '',
              isActive: true,
            ),
          ],
        ),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'host-1',
            fullName: 'Nguyễn Minh Anh',
            email: 'host@example.com',
          ),
        ),
        communityRepositoryProvider.overrideWith(
          (ref) => _FakeCommunityRepository(club: club, failures: clubFailures),
        ),
        regionRepositoryProvider.overrideWith((ref) => regionRepository),
        socialSessionRepositoryProvider.overrideWith(
          (ref) => socialRepository ?? _RecordingSocialSessionRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        // Pushed so a successful create can pop back to this host.
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => Scaffold(body: form))),
                child: const Text('open-social-form'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await _pumpUi(tester);
  await tester.tap(find.text('open-social-form'));
  await _pumpUi(tester);
}

/// Flushes the create chain: repository call, provider refreshes, the route pop
/// transition and the success message.
Future<void> _pumpSubmit(WidgetTester tester) async {
  for (var step = 0; step < 5; step++) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Taps the create control and flushes the resulting save chain.
Future<void> _submit(WidgetTester tester) async {
  final control = find.byWidget(_submitAction(tester));
  await tester.ensureVisible(control);
  await _pumpUi(tester);
  await tester.tap(control);
  await _pumpSubmit(tester);
}

/// The area section sits at the end of the form, below the fold of the form's
/// own scroll view; bring it on-screen so taps and offsets really land.
Future<void> _ensureAreaVisible(WidgetTester tester) async {
  await tester.ensureVisible(_wardSearch());
  await _pumpUi(tester);
}

Future<void> _selectOption(WidgetTester tester, String label) async {
  var option = find.text(label);
  for (var attempt = 0; option.evaluate().isEmpty && attempt < 3; attempt++) {
    // Options can sit below the fold of the form's own scroll view.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -220));
    await _pumpUi(tester);
    option = find.text(label);
  }
  expect(
    option,
    findsWidgets,
    reason: 'The region option "$label" is not offered',
  );
  await tester.tap(option.last);
  await _pumpUi(tester);
}

/// The form is a single scroll view: every control is brought on-screen
/// before the tap, because a tap on an off-screen offset silently misses.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await _pumpUi(tester);
  await tester.tap(target);
  await _pumpUi(tester);
}

Future<void> _searchWard(WidgetTester tester, String query) async {
  await _ensureAreaVisible(tester);
  await tester.enterText(_wardSearch(), query);
  await _pumpUi(tester);
}

/// Applies "Phường Mỹ Đình / Hà Nội" by hand, so a later case can check what
/// Cancel leaves untouched.
Future<void> _applyMyDinh(WidgetTester tester) async {
  await tester.enterText(_venueNameField(), _manualVenue);
  await _ensureAreaVisible(tester);
  await tester.enterText(_addressField(), _manualDetail);
  await _searchWard(tester, 'Mỹ');
  await _selectOption(tester, 'Phường Mỹ Đình');
  await _tapVisible(tester, find.text('Áp dụng'));
  expect(find.text(_myDinhSummary), findsOneWidget);
}

/// Ward results are searched nationally; city is resolved from response data.
Finder _wardSearch() => _fieldWithCopy('phường/xã');

/// The persistent create control, matched on the create verb so the lookup
/// survives the club/standalone wording split and the area controls.
ButtonStyleButton _submitAction(WidgetTester tester) {
  final finder = find.ancestor(
    of: find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data ?? widget.textSpan?.toPlainText() ?? '')
              .toLowerCase()
              .contains('tạo'),
    ),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  );
  expect(finder, findsOneWidget, reason: 'The create control is missing');
  return tester.widget<ButtonStyleButton>(finder);
}

/// A text input whose label or hint contains [copy]. The copy lives on the
/// surrounding [InputDecorator]; the edit control is that decorator's
/// descendant.
Finder _fieldWithCopy(String copy) {
  final decorator = find.byWidgetPredicate(
    (widget) =>
        widget is InputDecorator &&
        '${widget.decoration.labelText ?? ''} '
                '${widget.decoration.hintText ?? ''}'
            .toLowerCase()
            .contains(copy),
    description: 'text field mentioning "$copy"',
  );
  return find.descendant(of: decorator, matching: find.byType(EditableText));
}

Finder _venueNameField() => _fieldWithCopy('tên sân');

Finder _addressField() => _fieldWithCopy('địa');

String _addressText(WidgetTester tester) {
  final field = _addressField();
  expect(
    field,
    findsOneWidget,
    reason: 'The manual address field must stay available',
  );
  return tester.widget<EditableText>(field).controller.text;
}

/// Case-insensitive text lookup: the same copy may be rendered in a small-caps
/// style, so assertions target the wording rather than its casing.
Finder textCI(String value) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText())?.toLowerCase() ==
          value.toLowerCase(),
);

/// The club the form is attached to; a `null` province models a club whose
/// record carries no locality, which must leave the manual path in charge.
Community _club({String? provinceCode}) => Community(
  id: 'club-1',
  name: 'CLB Cầu Lông Sài Gòn',
  provinceCode: provinceCode,
);

/// Deterministic club source for the attached-club context. `failures` models
/// the club lookup going down, which must degrade to the manual path.
class _FakeCommunityRepository extends Fake implements ICommunityRepository {
  _FakeCommunityRepository({this.club, this.failures = 0});

  final Community? club;
  int failures;

  @override
  Future<Community?> getCommunityById(String id) async {
    if (failures > 0) {
      failures--;
      throw StateError('synthetic club lookup failure');
    }
    return club;
  }
}

/// Deterministic province/ward source with injectable lookup failures.
/// `provinceEmptyResponses`/`wardEmptyResponses` model the other unusable
/// answer: a lookup that succeeds and returns nothing at all.
class _FakeRegionRepository implements IRegionRepository {
  _FakeRegionRepository({
    this.provinceFailures = 0,
    this.provinceEmptyResponses = 0,
    this.wardEmptyResponses = 0,
    List<Region>? wardRows,
  }) : wardRows = wardRows ?? allWards;

  int provinceFailures;
  int provinceEmptyResponses;
  int wardEmptyResponses;
  int provinceCalls = 0;
  final List<String> wardRequests = <String>[];
  final List<Region> wardRows;

  /// Real province codes, so the parser's own alias table ("hcm", "ha noi",
  /// "da nang", ...) resolves the same way it does in the other create flows.
  static const List<Region> provinces = <Region>[
    Region(code: '79', name: 'TP. Hồ Chí Minh'),
    Region(code: '01', name: 'Hà Nội'),
    Region(code: '48', name: 'Đà Nẵng'),
  ];

  static final List<Region> hcmWards = <Region>[
    Region.fromJson({
      'code': '79-001',
      'name': 'Phường Bến Thành',
      'provinceCode': '79',
    }),
    Region.fromJson({
      'code': '79-002',
      'name': 'Phường Nguyễn Hồng Thành',
      'provinceCode': '79',
    }),
  ];

  static final List<Region> hanoiWards = <Region>[
    Region.fromJson({
      'code': '01-001',
      'name': 'Phường Mỹ Đình',
      'provinceCode': '01',
    }),
    Region.fromJson({
      'code': '01-002',
      'name': 'Phường Cầu Giấy',
      'provinceCode': '01',
    }),
  ];

  static final List<Region> danangWards = <Region>[
    Region.fromJson({
      'code': '48-001',
      'name': 'Phường Hải Châu',
      'provinceCode': '48',
    }),
  ];

  static final List<Region> allWards = <Region>[
    ...hcmWards,
    ...hanoiWards,
    ...danangWards,
  ];

  @override
  Future<List<Region>> getProvinces() async {
    provinceCalls++;
    if (provinceFailures > 0) {
      provinceFailures--;
      throw StateError('synthetic province lookup failure');
    }
    if (provinceEmptyResponses > 0) {
      provinceEmptyResponses--;
      return const <Region>[];
    }
    return provinces;
  }

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async {
    wardRequests.add(provinceCode);
    if (wardEmptyResponses > 0) {
      wardEmptyResponses--;
      return const <Region>[];
    }
    if (provinceCode.isEmpty) return wardRows;
    return wardRows;
  }
}

/// Captures the create payload so the composed address can be inspected.
/// `Fake` covers the endpoints the form does not reach during a save.
class _RecordingSocialSessionRepository extends Fake
    implements ISocialSessionRepository {
  final List<CreateSocialSessionRequest> creates = [];

  @override
  Future<SocialSessionModel> create(CreateSocialSessionRequest request) async {
    creates.add(request);
    return _savedSession;
  }

  @override
  Future<SocialSessionModel> getDetail(String sessionId) async => _savedSession;

  @override
  Future<SocialSessionListResponse> listByDate({
    required String date,
    String? sport,
    String? communityId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async => const SocialSessionListResponse(items: <SocialSessionModel>[]);
}

final _savedSession = SocialSessionModel(
  id: 'session-created',
  hostUserId: 'host-1',
  title: 'Kèo đã tạo',
  playFormat: 'Giao lưu',
  startAt: DateTime(2026, 10, 5, 9),
  venueName: _manualVenue,
  venueAddress: _manualDetail,
  sport: 'cau-long',
  sportName: 'Cầu lông',
);
