import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
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
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget coverage for the Social create form's inline locality fields.
///
/// The two fields are always on screen, the way the quick-tournament screen
/// shows them, and they use only the existing `IRegionRepository` plus the
/// deterministic `VietnamAddressParser`: a typed address fills them without
/// any tap, each field opens its own searchable list for manual correction,
/// and the applied names are composed into the existing address on save.
void main() {
  group('Social locality fields', () {
    testWidgets('the two locality fields need no tap to be seen', (
      tester,
    ) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _ensureAreaVisible(tester);

      expect(find.byType(SocialRegionInlineFields), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(textCI('Tỉnh / thành'), findsOneWidget);
      expect(textCI('Chọn tỉnh'), findsOneWidget);
      expect(textCI('Phường / xã'), findsOneWidget);
      // Chưa có tỉnh thì phường nói rõ điều kiện và không bấm được.
      expect(textCI('Chọn tỉnh trước'), findsOneWidget);
      expect(_localityField(tester, _wardField()).enabled, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('city options sort by Vietnamese name and filter by letter', (
      tester,
    ) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _openAreaPicker(tester);

      expect(
        tester.getTopLeft(find.text('Đà Nẵng')).dy,
        lessThan(tester.getTopLeft(find.text('Hà Nội')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Hà Nội')).dy,
        lessThan(tester.getTopLeft(find.text('TP. Hồ Chí Minh')).dy),
      );

      await _tapVisible(tester, find.text('H'));
      expect(find.text('Hà Nội'), findsOneWidget);
      expect(find.text('Đà Nẵng'), findsNothing);
      expect(find.text('TP. Hồ Chí Minh'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('city options narrow and lead with the typed term', (
      tester,
    ) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _openAreaPicker(tester);

      // Tone-free typing reaches the accented name it was written without.
      await _searchProvince(tester, 'ho chi minh');
      expect(find.text('TP. Hồ Chí Minh'), findsOneWidget);
      expect(find.text('Đà Nẵng'), findsNothing);
      expect(find.text('Hà Nội'), findsNothing);

      // The short forms the address parser accepts are the same wording here.
      await _searchProvince(tester, 'hcm');
      expect(find.text('TP. Hồ Chí Minh'), findsOneWidget);
      expect(find.text('Đà Nẵng'), findsNothing);

      await _searchProvince(tester, 'zzz');
      expect(textCI('Không tìm thấy kết quả.'), findsOneWidget);
      expect(find.text('TP. Hồ Chí Minh'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ward options lead with the name closest to the typed term', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(
          wardRows: [
            Region.fromJson({
              'code': '01-001',
              'name': 'Phường An Mỹ',
              'provinceCode': '01',
            }),
            Region.fromJson({
              'code': '01-002',
              'name': 'Phường Mỹ Đình',
              'provinceCode': '01',
            }),
          ],
        ),
      );
      await _searchWard(tester, 'Mỹ');

      expect(
        tester.getTopLeft(find.text('Phường Mỹ Đình')).dy,
        lessThan(tester.getTopLeft(find.text('Phường An Mỹ')).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'ward options sort by locality name and filter by its initial',
      (tester) async {
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
        );
        await _searchWard(tester, '');

        expect(
          tester.getTopLeft(find.text('Phường Cầu Giấy')).dy,
          lessThan(tester.getTopLeft(find.text('Phường Mỹ Đình')).dy),
        );
        expect(find.text('Phường Cầu Giấy'), findsOneWidget);
        expect(find.text('Phường Mỹ Đình'), findsOneWidget);

        await _tapVisible(tester, find.text('C'));

        expect(find.text('Phường Cầu Giấy'), findsOneWidget);
        expect(find.text('Phường Mỹ Đình'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('choosing a city fills its field and scopes the ward list', (
      tester,
    ) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _openAreaPicker(tester);
      await _selectOption(tester, 'Hà Nội');

      // Chọn là áp dụng luôn: không còn sheet, không còn bước "Áp dụng".
      expect(find.byType(BottomSheet), findsNothing);
      expect(_fieldText(tester, _provinceField()), 'Hà Nội');
      expect(_fieldText(tester, _wardField()), isEmpty);

      await _openWardList(tester);

      expect(find.text('Phường Cầu Giấy'), findsOneWidget);
      expect(find.text('Phường Mỹ Đình'), findsOneWidget);
      expect(find.text('Phường Bến Thành'), findsNothing);
      expect(find.text('Phường Hải Châu'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the detected area fills the two fields', (
      tester,
    ) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _ensureAreaVisible(tester);
      // Địa chỉ nhận diện được cả tỉnh lẫn phường mà chưa chạm tay vào ô nào.
      await tester.enterText(
        _addressField(),
        '83 Đường A4, Phường Bến Thành, TP. Hồ Chí Minh',
      );
      await _pumpUi(tester);

      // Regression: hai ô phải hiện tên đã nhận diện, không phải vẫn là
      // gợi ý "Chọn tỉnh"/"Chọn phường" trong khi thẻ vị trí đã có tóm tắt.
      expect(_fieldText(tester, _provinceField()), 'TP. Hồ Chí Minh');
      expect(_fieldText(tester, _wardField()), 'Phường Bến Thành');
      expect(textCI('Chọn tỉnh'), findsNothing);
      expect(textCI('Chọn phường'), findsNothing);
      // Cùng lựa chọn đó nằm trong cả hai ô, không lệch nhau.
      expect(_appliedArea(tester), _benThanhSummary);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'editing the address clears an applied locality before saving',
      (tester) async {
        final socialRepository = _RecordingSocialSessionRepository();
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
          socialRepository: socialRepository,
        );
        await tester.enterText(_venueNameField(), _manualVenue);
        await tester.enterText(_addressField(), _myDinhAddress);
        await _pumpUi(tester);
        // Khu vực tự điền từ địa chỉ, host không bấm gì.
        expect(_appliedArea(tester), _myDinhSummary);

        const editedAddress = 'Sân mới, 15 Lê Lợi, Đà Nẵng';
        await tester.enterText(_addressField(), editedAddress);
        await _pumpUi(tester);
        await _submit(tester);

        final savedAddress = socialRepository.creates.single.venueAddress;
        expect(savedAddress, editedAddress);
        expect(savedAddress, isNot(contains('Mỹ Đình')));
        expect(savedAddress, isNot(contains('Hà Nội')));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'editing the address re-places an auto pin on the new ward',
      (tester) async {
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
          dio: _geoDio(),
        );
        await tester.enterText(_addressField(), _myDinhAddress);
        await _pumpUi(tester);
        // Nhận diện xong mới hẹn ghim, nên cần thêm một nhịp cho hẹn 600 ms
        // đó chạy.
        await _pumpUi(tester);
        // Tâm "Phường Mỹ Đình" do server trả về: ghim tự động.
        expect(_cardPin(tester, _myDinhCentroid), findsOneWidget);
        expect(textCI('Ghim tự động theo khu vực'), findsOneWidget);

        await tester.enterText(
          _addressField(),
          '120 Trần Phú, Phường Hải Châu, Đà Nẵng',
        );
        await _pumpUi(tester);
        await _pumpUi(tester);
        // Ghim cũ trỏ vào Mỹ Đình nên phải nhường chỗ cho tâm phường mới,
        // không giữ nguyên một điểm đã không còn đúng với địa chỉ.
        expect(_appliedArea(tester), 'Phường Hải Châu, Đà Nẵng');
        expect(_cardPin(tester, _haiChauCentroid), findsOneWidget);
        expect(_cardPin(tester, _myDinhCentroid), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'editing the address drops an auto pin it can no longer place',
      (tester) async {
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
          dio: _geoDio(),
        );
        await tester.enterText(_addressField(), _myDinhAddress);
        await _pumpUi(tester);
        await _pumpUi(tester);
        expect(_cardPin(tester, _myDinhCentroid), findsOneWidget);

        // Địa chỉ mới chỉ còn tỉnh, nhận diện không ra phường nên không ghim
        // tạm được — nhưng điểm của phường cũ cũng phải mất, chứ không nằm
        // lại chỉ vào một địa chỉ đã bị thay.
        await tester.enterText(_addressField(), '15 Lê Lợi, Đà Nẵng');
        await _pumpUi(tester);
        await _pumpUi(tester);
        expect(_appliedArea(tester), 'Đà Nẵng');
        expect(_cardPin(tester, _myDinhCentroid), findsNothing);
        expect(textCI('Ghim vị trí sân'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('editing the address keeps a pin the host dropped by hand', (
      tester,
    ) async {
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        dio: _geoDio(),
      );
      await _dropPinByHand(tester);
      expect(_cardPin(tester, _handPicked), findsOneWidget);
      expect(textCI('Đã ghim vị trí sân'), findsOneWidget);

      await tester.enterText(_addressField(), '$_myDinhAddress, gần ngã ba');
      await _pumpUi(tester);
      // Host sửa lỗi chính tả trong địa chỉ không phải lý do để mất điểm
      // mình vừa chọn tay; muốn bỏ thì bấm "×" trên thẻ.
      expect(_addressText(tester), contains('gần ngã ba'));
      expect(_cardPin(tester, _handPicked), findsOneWidget);
      expect(textCI('Đã ghim vị trí sân'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the locality fields stay unloaded until a list is opened', (
      tester,
    ) async {
      final repository = _FakeRegionRepository();
      await _pumpSocialForm(tester, regionRepository: repository);

      expect(find.byType(SocialRegionInlineFields), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(repository.provinceCalls, 0);
      expect(repository.wardRequests, isEmpty);

      await _openAreaPicker(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(repository.provinceCalls, 1);
      expect(repository.wardRequests, <String>['']);
      // Danh sách tỉnh chỉ mở ô tìm tỉnh, không mở sẵn ô tìm phường.
      expect(_provinceSearch(), findsOneWidget);
      expect(_wardSearch(), findsNothing);
      await _tapVisible(tester, find.byTooltip('Đóng'));
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

      await _searchWard(tester, 'P');
      await _pumpUi(tester);
      expect(
        textCI('Nhập ít nhất 2 ký tự để tìm phường/xã.'),
        findsOneWidget,
      );
      expect(find.text('Phường Test 00'), findsNothing);

      await _searchWard(tester, 'Phường');
      await _pumpUi(tester);
      expect(find.text('Phường Test 00'), findsOneWidget);
      // Nhiều hơn 50 dòng thì cắt bớt, không dựng hết danh sách.
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -5000));
      await _pumpUi(tester);
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
            // Cùng một tên phường ở hai tỉnh: chỉ tỉnh đang chọn được chào.
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
            Region.fromJson({
              'code': '01-102',
              'name': 'Phường Hải Châu',
              'provinceCode': '01',
            }),
          ],
        ),
      );
      await _ensureAreaVisible(tester);
      await _searchWard(tester, 'Phú', province: 'Đà Nẵng');

      // Phường trùng tên ở tỉnh khác không lẫn vào danh sách tỉnh đang chọn.
      expect(_listOption('Phường Hải Châu'), findsNothing);
      await _selectOption(tester, 'Phường An Phú');

      expect(_fieldText(tester, _provinceField()), 'Đà Nẵng');
      expect(_fieldText(tester, _wardField()), 'Phường An Phú');
      expect(_appliedArea(tester), 'Phường An Phú, Đà Nẵng');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a full typed address fills the area itself and composes into the request', (
      tester,
    ) async {
      final socialRepository = _RecordingSocialSessionRepository();
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        socialRepository: socialRepository,
      );
      await tester.enterText(_venueNameField(), _manualVenue);
      await tester.enterText(_addressField(), _myDinhAddress);
      await _pumpUi(tester);
      // Ngừng gõ là đủ: khu vực tự điền, host không bấm gì.
      expect(_fieldText(tester, _provinceField()), 'Hà Nội');
      expect(_fieldText(tester, _wardField()), 'Phường Mỹ Đình');
      expect(_appliedArea(tester), _myDinhSummary);
      expect(_addressText(tester), _myDinhAddress);
      await _submit(tester);
      expect(socialRepository.creates, hasLength(1));
      final address = socialRepository.creates.single.venueAddress;
      expect(address, contains('Hà Nội'));
      expect('Hà Nội'.allMatches(address).length, 1);
      expect('Phường Mỹ Đình'.allMatches(address).length, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('typing pauses before the area is filled, once province data is already cached', (
      tester,
    ) async {
      final repository = _FakeRegionRepository();
      await _pumpSocialForm(tester, regionRepository: repository);
      await _ensureAreaVisible(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(_addressField(), '202 Hoàng Văn Thụ');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
        _addressField(),
        '202 Hoàng Văn Thụ, Phường Mỹ Đình, Hà Nội',
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Chưa ngừng gõ thì chưa nhận diện, chưa tải danh mục phụ.
      expect(_appliedArea(tester), isNot(_myDinhSummary));
      expect(repository.provinceCalls, 0);
      await _pumpUi(tester);
      // Chưa ngừng gõ thì chưa nhận diện, chưa tải danh mục phụ.
      expect(_appliedArea(tester), _myDinhSummary);
      expect(repository.provinceCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an address with a city only fills that city', (tester) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _ensureAreaVisible(tester);
      await tester.enterText(_addressField(), '15 Lê Lợi, Đà Nẵng');
      await _pumpUi(tester);
      // Tỉnh nhanh nhận diện được thì chốt tỉnh thôi: phường thì không đoán.
      expect(_fieldText(tester, _provinceField()), 'Đà Nẵng');
      expect(_fieldText(tester, _wardField()), isEmpty);
      expect(_appliedArea(tester), 'Đà Nẵng');
      expect(_appliedArea(tester), isNot('Phường Hải Châu, Đà Nẵng'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a bare ward name in the address fills ward and city', (
      tester,
    ) async {
      // wards row 26983 of the catalogue the API serves: the host writes the
      // ward as it reads on the street sign ("Bãy Hiến"), the catalogue stores
      // the official name with its type prefix and its own tones
      // ("Phường Bảy Hiền"). Both spellings must land on the same ward.
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(
          wardRows: [
            Region.fromJson({
              'code': '26983',
              'name': 'Phường Bảy Hiền',
              'fullName': 'Phường Bảy Hiền',
              'provinceCode': '79',
            }),
          ],
        ),
      );
      await _ensureAreaVisible(tester);
      await tester.enterText(
        _addressField(),
        '83 Đường A4, Bãy Hiến, Hồ Chí Minh',
      );
      await _pumpUi(tester);
      // Không gõ tiền tố "Phường" mà vẫn ra đúng phường, vì parser bỏ tiền tố
      // loại ở cả hai đầu so khớp.
      expect(_fieldText(tester, _provinceField()), 'TP. Hồ Chí Minh');
      expect(_fieldText(tester, _wardField()), 'Phường Bảy Hiền');
      expect(_appliedArea(tester), 'Phường Bảy Hiền, TP. Hồ Chí Minh');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a host-made area is not re-decided by the typed address', (
      tester,
    ) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await tester.enterText(_venueNameField(), _manualVenue);
      await _ensureAreaVisible(tester);
      await tester.enterText(_addressField(), _myDinhAddress);
      await _pumpUi(tester);
      expect(_appliedArea(tester), _myDinhSummary);
      // Host tự chọn phường khác: lựa chọn của host là chốt.
      await _searchWard(tester, 'Cầu');
      await _selectOption(tester, 'Phường Cầu Giấy');
      expect(_fieldText(tester, _wardField()), 'Phường Cầu Giấy');
      expect(_appliedArea(tester), _cauGiaySummary);

      await tester.enterText(_addressField(), '$_myDinhAddress, gần ngã ba');
      await _pumpUi(tester);
      // Gõ tiếp không phải chỗ cho tự điền tự quyết lại chốt của host: phường
      // host bấm chọn vẫn còn nguyên, còn địa chỉ thì thêm phần host vừa gõ.
      expect(_appliedArea(tester), _cauGiaySummary);
      expect(_fieldText(tester, _wardField()), 'Phường Cầu Giấy');
      expect(_addressText(tester), contains('gần ngã ba'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a city picked by hand is not overwritten by the address', (
      tester,
    ) async {
      final socialRepository = _RecordingSocialSessionRepository();
      await _pumpSocialForm(
        tester,
        regionRepository: _FakeRegionRepository(),
        socialRepository: socialRepository,
      );
      // Chọn tay chỉ tỉnh, chưa chọn phường: vẫn là lựa chọn của host.
      await _chooseProvince(tester, 'Hà Nội');
      expect(_fieldText(tester, _provinceField()), 'Hà Nội');
      expect(_fieldText(tester, _wardField()), isEmpty);

      await tester.enterText(_venueNameField(), _manualVenue);
      await _ensureAreaVisible(tester);
      await tester.enterText(_addressField(), _benThanhAddress);
      await _pumpUi(tester);
      // Gõ tiếp không phải lý do để tự điền tự quyết lại tỉnh của host.
      expect(_fieldText(tester, _provinceField()), 'Hà Nội');
      expect(_fieldText(tester, _wardField()), isEmpty);
      expect(_appliedArea(tester), 'Hà Nội');
      expect(_appliedArea(tester), isNot(_benThanhSummary));

      await _submit(tester);
      final address = socialRepository.creates.single.venueAddress;
      // Lựa chọn của host được ghép vào địa chỉ đúng một lần, tỉnh của địa
      // chỉ nằm trong địa chỉ gõ tay chứ không bị chèn thêm.
      expect('Hà Nội'.allMatches(address).length, 1);
      expect('Phường Bến Thành'.allMatches(address).length, 1);
      expect(tester.takeException(), isNull);
    });

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

        // Tỉnh của CLB chỉ làm phạm vi tìm phường, rồi chốt thẳng vào hai
        // trường — không cần mở danh sách và bấm "Áp dụng".
        expect(_fieldText(tester, _provinceField()), 'TP. Hồ Chí Minh');
        expect(_fieldText(tester, _wardField()), 'Phường Bến Thành');
        expect(_appliedArea(tester), _benThanhSummary);
        expect(find.byType(BottomSheet), findsNothing);
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

      // Tỉnh của CLB là ngữ cảnh dự phòng nên vẫn chốt, nhưng phường của tỉnh
      // khác thì không được đoán ra, và cặp tỉnh + phường sai lúc nào cũng
      // không được chốt.
      expect(_fieldText(tester, _provinceField()), 'TP. Hồ Chí Minh');
      expect(_fieldText(tester, _wardField()), isEmpty);
      expect(_appliedArea(tester), isNot(_myDinhSummary));
      expect(_appliedArea(tester), isNot('Phường Mỹ Đình, TP. Hồ Chí Minh'));
      expect(_addressText(tester), '202 Hoàng Văn Thụ, Phường Mỹ Đình');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a city named in the address wins over the club province', (
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
        '15 Lê Lợi, Phường Hải Châu, Đà Nẵng',
      );
      await _pumpUi(tester);
      // Khu vực tự điền lấy tỉnh của địa chỉ, không phải tỉnh của CLB.
      expect(_appliedArea(tester), 'Phường Hải Châu, Đà Nẵng');
      expect(_appliedArea(tester), isNot('Hà Nội'));
      expect(_appliedArea(tester), isNot(_myDinhSummary));
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
        '120 Nguyễn Thị Minh Khai, Phường Bến Thành, TP. HCM',
      );
      await _pumpUi(tester);
      // Khu vực tự điền lấy tỉnh của địa chỉ, không phải tỉnh của CLB.
      expect(_appliedArea(tester), _benThanhSummary);
      expect(_appliedArea(tester), isNot(_myDinhSummary));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a self-filled locality does not duplicate a recognized city alias', (
      tester,
    ) async {
      final socialRepository = _RecordingSocialSessionRepository();
      const typedAddress = '120 Nguyễn Thị Minh Khai, Phường Bến Thành, TP. HCM';
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
      // Khu vực tự điền, host không bấm gì.
      expect(_appliedArea(tester), _benThanhSummary);
      await _submit(tester);
      final savedAddress = socialRepository.creates.single.venueAddress;
      expect(savedAddress, contains('TP. HCM'));
      expect('TP. HCM'.allMatches(savedAddress).length, 1);
      expect('Phường Bến Thành'.allMatches(savedAddress).length, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ward-only text without any context fills nothing', (
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

      expect(_fieldText(tester, _provinceField()), isEmpty);
      expect(_fieldText(tester, _wardField()), isEmpty);
      expect(_appliedArea(tester), isNot(_myDinhSummary));
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
      expect(_appliedArea(tester), _myDinhSummary);

      await _searchWard(tester, 'Cầu');
      await _selectOption(tester, 'Phường Cầu Giấy');
      expect(_appliedArea(tester), _cauGiaySummary);

      // Host mở lại danh sách và chọn phường khác: lựa chọn mới thay cũ.
      await _searchWard(tester, 'Mỹ Đình');
      await _selectOption(tester, 'Phường Mỹ Đình');
      expect(_fieldText(tester, _provinceField()), 'Hà Nội');
      expect(_fieldText(tester, _wardField()), 'Phường Mỹ Đình');
      expect(_appliedArea(tester), _myDinhSummary);
      expect(_appliedArea(tester), isNot(_cauGiaySummary));

      await _submit(tester);
      final address = socialRepository.creates.single.venueAddress;
      // Địa chỉ đã có sẵn tên phường và tỉnh, ghép lúc lưu không nhân bản,
      // và phường host đã bỏ không quay lại địa chỉ.
      expect('Phường Mỹ Đình'.allMatches(address).length, 1);
      expect('Hà Nội'.allMatches(address).length, 1);
      expect(address, isNot(contains('Cầu Giấy')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('closing the list keeps the applied area and the typed address', (
      tester,
    ) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _applyMyDinh(tester);
      expect(_addressText(tester), _manualDetail);

      await _searchWard(tester, 'Cầu');
      await _tapVisible(tester, find.byTooltip('Đóng'));

      expect(find.byType(BottomSheet), findsNothing);
      expect(_fieldText(tester, _wardField()), 'Phường Mỹ Đình');
      expect(_appliedArea(tester), _myDinhSummary);
      expect(_addressText(tester), _manualDetail);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping outside the list keeps the applied area', (
      tester,
    ) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _applyMyDinh(tester);

      await _searchWard(tester, 'Cầu');
      // Bấm ra ngoài sheet: không chọn gì thì giữ nguyên lựa chọn đang có.
      await tester.tapAt(const Offset(20, 20));
      await _pumpUi(tester);

      expect(find.byType(BottomSheet), findsNothing);
      expect(_appliedArea(tester), _myDinhSummary);
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
              'code': '01-001',
              'name': 'Phường Mỹ Đình',
              'provinceCode': '01',
            }),
            Region.fromJson({
              'code': 'XX-001',
              'name': 'Phường Mồ Côi',
              'provinceCode': 'XX',
            }),
          ],
        ),
      );
      await _ensureAreaVisible(tester);
      await _searchWard(tester, 'Mồ Côi', province: 'Hà Nội');

      expect(find.text('Phường Mồ Côi'), findsNothing);
      expect(textCI('Không tìm thấy kết quả.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'a region lookup failure leaves the manual address and create path open',
      (tester) async {
        final repository = _FakeRegionRepository(provinceFailures: 1);
        await _pumpSocialForm(tester, regionRepository: repository);

        await _openAreaPicker(tester);
        expect(
          textCI(
            'Không tải được khu vực. Bạn vẫn có thể nhập địa chỉ thủ công.',
          ),
          findsOneWidget,
        );
        await _tapVisible(tester, find.text('Thử lại'));
        expect(_provinceSearch(), findsOneWidget);
        expect(repository.wardRequests, <String>['']);
        await _tapVisible(tester, find.byTooltip('Đóng'));
        expect(find.byType(BottomSheet), findsNothing);
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
      await _openAreaPicker(tester);
      expect(
        textCI('Không tải được khu vực. Bạn vẫn có thể nhập địa chỉ thủ công.'),
        findsOneWidget,
      );
      final callsBeforeRetry = repository.provinceCalls;
      await _tapVisible(tester, find.text('Thử lại'));
      expect(repository.provinceCalls, callsBeforeRetry + 1);
      expect(repository.wardRequests, <String>['']);
      expect(_listOption('Hà Nội'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty province data offers manual fallback and Retry', (
      tester,
    ) async {
      final repository = _FakeRegionRepository(provinceEmptyResponses: 1);
      await _pumpSocialForm(tester, regionRepository: repository);

      await _openAreaPicker(tester);
      expect(
        textCI(
          'Khu vực hiện không khả dụng. Bạn vẫn có thể nhập địa chỉ thủ công.',
        ),
        findsOneWidget,
      );
      expect(_listOption('Hà Nội'), findsNothing);
      final callsBeforeRetry = repository.provinceCalls;
      await _tapVisible(tester, find.text('Thử lại'));

      expect(repository.provinceCalls, callsBeforeRetry + 1);
      // Lần nạp đầu thấy tỉnh rỗng, lần nạp lại thì tải được cả tỉnh lẫn phường.
      expect(repository.wardRequests, <String>['', '']);
      expect(
        textCI('Khu vực hiện không khả dụng. Bạn vẫn có thể nhập địa chỉ thủ công.'),
        findsNothing,
      );
      expect(_provinceSearch(), findsOneWidget);
      expect(_listOption('Hà Nội'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty ward data offers manual fallback and Retry', (
      tester,
    ) async {
      final repository = _FakeRegionRepository(wardEmptyResponses: 1);
      await _pumpSocialForm(tester, regionRepository: repository);

      // Tỉnh vẫn chọn được khi danh mục phường rỗng.
      await _ensureAreaVisible(tester);
      await _chooseProvince(tester, 'Hà Nội');
      expect(_fieldText(tester, _provinceField()), 'Hà Nội');

      await _openWardList(tester);
      expect(
        textCI('Khu vực hiện không khả dụng. Bạn vẫn có thể nhập địa chỉ thủ công.'),
        findsOneWidget,
      );
      expect(repository.wardRequests, <String>['']);
      await _tapVisible(tester, find.text('Thử lại'));
      await _pumpUi(tester);
      expect(
        textCI('Khu vực hiện không khả dụng. Bạn vẫn có thể nhập địa chỉ thủ công.'),
        findsNothing,
      );
      // Nạp lại xong thì danh sách phường của tỉnh đã chọn có dữ liệu trở lại.
      expect(_listOption('Phường Mỹ Đình'), findsOneWidget);
      expect(_listOption('Phường Cầu Giấy'), findsOneWidget);
      expect(repository.wardRequests, <String>['', '']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed club lookup still fills from the typed city', (
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

      // Khu vực tự điền từ địa chỉ, không cần tỉnh của CLB.
      expect(_appliedArea(tester), 'Phường Hải Châu, Đà Nẵng');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the locality fields stay usable at 360 px', (tester) async {
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

      // Hai trường nằm cạnh nhau và tự điền không làm tràn ở màn hẹp nhất.
      expect(
        tester.getTopLeft(_provinceField()).dy,
        tester.getTopLeft(_wardField()).dy,
      );
      expect(_fieldText(tester, _provinceField()), 'Hà Nội');
      expect(_fieldText(tester, _wardField()), 'Phường Mỹ Đình');
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an A–Z filter is activatable by a screen reader', (
      tester,
    ) async {
      await _withSemanticsEnabled(tester, () async {
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
        );
        await _openAreaPicker(tester);

        // Announcing the letter is not enough: it must expose selection and
        // its tap action, so touch is not the only way to filter.
        final filter = find.semantics.byLabel(
          'Lọc kết quả theo chữ cái đầu: H',
        );
        expect(
          filter,
          isSemantics(
            hasTapAction: true,
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
          ),
        );
        tester.semantics.tap(filter);
        await _pumpUi(tester);

        expect(
          filter,
          isSemantics(
            hasTapAction: true,
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
          ),
        );
        expect(find.text('Hà Nội'), findsOneWidget);
        expect(find.text('Đà Nẵng'), findsNothing);
        expect(find.text('TP. Hồ Chí Minh'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('a city option is activatable by a screen reader', (
      tester,
    ) async {
      await _withSemanticsEnabled(tester, () async {
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
        );
        await _openAreaPicker(tester);

        final option = find.semantics.byLabel('Hà Nội');
        expect(
          option,
          isSemantics(
            hasTapAction: true,
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
          ),
        );
        tester.semantics.tap(option);
        await _pumpUi(tester);

        // Chọn xong là áp dụng luôn vào trường tỉnh.
        expect(find.byType(BottomSheet), findsNothing);
        expect(_fieldText(tester, _provinceField()), 'Hà Nội');

        await _openWardList(tester);
        expect(find.text('Phường Mỹ Đình'), findsOneWidget);
        expect(find.text('Phường Cầu Giấy'), findsOneWidget);
        expect(find.text('Phường Bến Thành'), findsNothing);
        expect(find.text('Phường Hải Châu'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('a ward option is activatable by a screen reader', (
      tester,
    ) async {
      await _withSemanticsEnabled(tester, () async {
        await _pumpSocialForm(
          tester,
          regionRepository: _FakeRegionRepository(),
        );
        await _searchWard(tester, 'Mỹ Đình');

        final option = find.semantics.byLabel('Phường Mỹ Đình, Hà Nội');
        expect(
          option,
          isSemantics(
            hasTapAction: true,
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
          ),
        );
        tester.semantics.tap(option);
        await _pumpUi(tester);

        // The applied locality is announced from the two inline fields, and
        // the venue-location card no longer repeats it as a joined summary.
        expect(find.byType(BottomSheet), findsNothing);
        expect(_fieldText(tester, _provinceField()), 'Hà Nội');
        expect(_fieldText(tester, _wardField()), 'Phường Mỹ Đình');
        expect(find.text(_myDinhSummary), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('every A–Z filter keeps a 48 px touch target', (tester) async {
      await _pumpSocialForm(tester, regionRepository: _FakeRegionRepository());
      await _openAreaPicker(tester);

      final letters = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ChoiceChip),
      );
      expect(letters, findsNWidgets(26));
      for (var index = 0; index < 26; index++) {
        expect(
          tester.getSize(letters.at(index)).height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
        );
        expect(
          tester.getSize(letters.at(index)).width,
          greaterThanOrEqualTo(kMinInteractiveDimension),
        );
      }
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

/// Tọa độ tâm phường mà [GET /regions/wards/centroid] trả về cho từng mã
/// phường; mỗi phường một cặp riêng để thấy pin được dời sang phường mới
/// chứ không phải pin cũ còn nằm yên.
const _myDinhCentroid = '21.00000, 105.00000';
const _haiChauCentroid = '16.00000, 108.00000';

/// Điểm bản đồ rơi về khi host mở màn ghim mà chưa có ghim nào và app không
/// lấy được vị trí user: tâm TP.HCM trong [CreateSocialScreen].
const _handPicked = '10.77690, 106.70090';

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
  Dio? dio,
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
        // Only the geo endpoints matter here; a null dio leaves them on the
        // real client, which fails in tests and models "no coordinates yet".
        if (dio != null) dioProvider.overrideWith((ref) => dio),
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

/// Brings the two always-visible locality fields on-screen.
Future<void> _ensureAreaVisible(WidgetTester tester) async {
  await tester.ensureVisible(_provinceField());
  await _pumpUi(tester);
}

/// Opens the province list by tapping its field — there is no popup opener to
/// go through first, the field itself is the control.
Future<void> _openAreaPicker(WidgetTester tester) async {
  if (find.byType(BottomSheet).evaluate().isNotEmpty) return;
  await _tapVisible(tester, _provinceField());
}

/// Opens the ward list of the chosen province by tapping its field.
Future<void> _openWardList(WidgetTester tester) async {
  if (find.byType(BottomSheet).evaluate().isNotEmpty) return;
  await _tapVisible(tester, _wardField());
}

/// Chooses a city by hand: opens the province list and taps the name.
Future<void> _chooseProvince(WidgetTester tester, String name) async {
  await _openAreaPicker(tester);
  await _selectOption(tester, name);
}

/// The area the form is showing right now, spelled exactly the way
/// [SocialRegionSelection.summary] spells it: "Phường Mỹ Đình, Hà Nội", or
/// just "Hà Nẵng" when only a city is chosen. The two always-visible locality
/// fields are the one place the host sees the applied area; the venue
/// location card no longer repeats it, so this is read off the fields.
String _appliedArea(WidgetTester tester) {
  final province = _fieldText(tester, _provinceField());
  final ward = _fieldText(tester, _wardField());
  if (province.isEmpty) return ward;
  if (ward.isEmpty) return province;
  return '$ward, $province';
}

Future<void> _selectOption(WidgetTester tester, String label) async {
  var option = _listOption(label);
  for (var attempt = 0; option.evaluate().isEmpty && attempt < 3; attempt++) {
    // Options can sit below the sheet's bounded result list.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -220));
    await _pumpUi(tester);
    option = _listOption(label);
  }
  expect(
    option,
    findsWidgets,
    reason: 'The region option "$label" is not offered',
  );
  await tester.tap(option.last);
  await _pumpUi(tester);
}

/// Options live in the sheet; the inline fields repeat the same names once a
/// value is applied, so the lookup is scoped to the list under test.
Finder _listOption(String label) => find.descendant(
  of: find.byType(BottomSheet),
  matching: find.text(label),
);

/// The form is a single scroll view: every control is brought on-screen
/// before the tap, because a tap on an off-screen offset silently misses.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await _pumpUi(tester);
  await tester.tap(target);
  await _pumpUi(tester);
}

/// Opens the ward list for [province] and types [query] into it. Wards are
/// listed inside one city, so the city comes first.
Future<void> _searchWard(
  WidgetTester tester,
  String query, {
  String province = 'Hà Nội',
}) async {
  if (_fieldText(tester, _provinceField()) != province) {
    await _chooseProvince(tester, province);
  }
  await _openWardList(tester);
  final field = _wardSearch();
  await tester.ensureVisible(field);
  await tester.tap(field);
  await _pumpUi(tester);
  await tester.enterText(field, query);
  await _pumpUi(tester);
}

/// Types into the city list's search field.
Future<void> _searchProvince(WidgetTester tester, String query) async {
  await _openAreaPicker(tester);
  final field = _provinceSearch();
  await tester.ensureVisible(field);
  await tester.tap(field);
  await _pumpUi(tester);
  await tester.enterText(field, query);
  await _pumpUi(tester);
}

/// Applies "Phường Mỹ Đình / Hà Nội" by hand, so a later case can check what
/// a dismissed list leaves untouched.
Future<void> _applyMyDinh(WidgetTester tester) async {
  await tester.enterText(_venueNameField(), _manualVenue);
  await _ensureAreaVisible(tester);
  await tester.enterText(_addressField(), _manualDetail);
  await _searchWard(tester, 'Mỹ Đình');
  await _selectOption(tester, 'Phường Mỹ Đình');
  expect(_appliedArea(tester), _myDinhSummary);
}

/// Ward results are listed per city; the search field is the one the ward
/// list puts on screen.
Finder _wardSearch() => _fieldWithCopy('phường/xã');

Finder _provinceSearch() => _fieldWithCopy('tỉnh/thành phố');

Finder _provinceField() => _fieldWithCopy('tỉnh / thành');

Finder _wardField() => _fieldWithCopy('phường / xã');

/// The read-only control behind an inline field, checked for its enabled
/// state: the ward field is locked until a city is chosen.
TextField _localityField(WidgetTester tester, Finder field) {
  final control = find.ancestor(
    of: field,
    matching: find.byType(TextField),
  );
  expect(control, findsOneWidget, reason: 'The locality field is missing');
  return tester.widget<TextField>(control);
}

String _fieldText(WidgetTester tester, Finder field) =>
    tester.widget<EditableText>(field).controller.text;

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

/// Tọa độ đang ghim, đọc từ dòng phụ của thẻ vị trí. Thẻ chỉ hiện dòng này
/// khi đang có ghim, nên tìm thấy nó cũng là bằng chứng thẻ không còn ở
/// trạng thái "chưa ghim".
Finder _cardPin(WidgetTester tester, String coords) => find.descendant(
  of: find.byKey(const ValueKey('venue-location-card')),
  matching: find.text(coords),
);

/// Host tự mở bản đồ và bấm xác nhận: đây là nguồn ghim tay, khác hẳn tâm
/// phường mà form tự suy ra.
Future<void> _dropPinByHand(WidgetTester tester) async {
  await _tapVisible(tester, find.byKey(const ValueKey('venue-location-card')));
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, 'Xác nhận vị trí'),
  );
}

Future<void> _withSemanticsEnabled(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

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

/// Answers the two geo endpoints the venue card depends on: the ward centroid
/// that backs the auto pin, and the reverse lookup that follows a hand pin.
/// Everything else 404s, so a test that reaches further than it meant to fails
/// loudly instead of silently getting an empty answer.
Dio _geoDio() {
  const centroids = <String, (double, double)>{
    '01-001': (21, 105),
    '48-001': (16, 108),
  };
  return Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = _GeoAdapter(centroids);
}

class _GeoAdapter implements HttpClientAdapter {
  _GeoAdapter(this.centroids);

  final Map<String, (double, double)> centroids;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (path.startsWith('/regions/wards/centroid')) {
      final point = centroids[options.queryParameters['wardCode']];
      if (point != null) {
        return _json(200, {'centerLat': point.$1, 'centerLng': point.$2});
      }
    }
    if (path.startsWith('/regions/resolve')) {
      return _json(200, {
        'wardCode': '01-001',
        'wardName': 'Phường Mỹ Đình',
        'provinceCode': '01',
        'provinceName': 'Hà Nội',
      });
    }
    return _json(404, const {});
  }

  ResponseBody _json(int status, Map<String, dynamic> body) => ResponseBody.fromString(
    jsonEncode({'data': body}),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
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
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
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
