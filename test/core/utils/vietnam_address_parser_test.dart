import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Area = ({String code, String name, String fullName});

_Area _area(String code, String name, [String? fullName]) =>
    (code: code, name: name, fullName: fullName ?? name);

String _code(_Area a) => a.code;
String _name(_Area a) => a.name;
String _full(_Area a) => a.fullName;

String? _province(String address, List<_Area> provinces) =>
    VietnamAddressParser.detectProvince<_Area>(
      rawAddress: address,
      provinces: provinces,
      getCode: _code,
      getName: _name,
      getFullName: _full,
    )?.code;

String? _ward(String address, List<_Area> wards) =>
    VietnamAddressParser.detectWard<_Area>(
      rawAddress: address,
      wards: wards,
      getCode: _code,
      getName: _name,
      getFullName: _full,
    )?.code;

final _provinces = [
  _area('79', 'Thành phố Hồ Chí Minh'),
  _area('01', 'Thành phố Hà Nội'),
  _area('46', 'Thành phố Huế'),
  _area('68', 'Tỉnh Lâm Đồng'),
  _area('48', 'Thành phố Đà Nẵng'),
];

void main() {
  group('removeVietnameseTones', () {
    test('strips diacritics, lower-cases and maps đ to d', () {
      expect(
        VietnamAddressParser.removeVietnameseTones('Đường Nguyễn Huệ'),
        'duong nguyen hue',
      );
      expect(
        VietnamAddressParser.removeVietnameseTones('ẢNH HƯỞNG Ữ'),
        'anh huong u',
      );
    });

    test('turns punctuation into single spaces and trims', () {
      expect(
        VietnamAddressParser.removeVietnameseTones('  Q.1,  P.Bến-Nghé!  '),
        'q 1 p ben nghe',
      );
    });

    test('an empty string stays empty', () {
      expect(VietnamAddressParser.removeVietnameseTones(''), '');
    });
  });

  group('provinceKey and aliases', () {
    test('drops the administrative type prefix and slugifies', () {
      expect(VietnamAddressParser.provinceKey('Thành phố Hà Nội'), 'ha_noi');
      expect(VietnamAddressParser.provinceKey('Tỉnh An Giang'), 'an_giang');
      expect(
        VietnamAddressParser.provinceKey('TP. Hồ Chí Minh'),
        'ho_chi_minh',
      );
      expect(VietnamAddressParser.provinceKey('Thị xã Phú Mỹ'), 'phu_my');
    });

    test(
      'provinceAliasesOf follows the catalogue name, not a numeric code',
      () {
        expect(
          VietnamAddressParser.provinceAliasesOf('Thành phố Hà Nội'),
          contains('hn'),
        );
        expect(
          VietnamAddressParser.provinceAliasesOf('Tỉnh Không Có'),
          isEmpty,
        );
      },
    );

    test('ambiguous street-like aliases are not in the table', () {
      final all = VietnamAddressParser.provinceAliases.values.expand((v) => v);

      expect(all, isNot(contains('hue'))); // "Nguyễn Huệ"
      expect(all, isNot(contains('bien hoa'))); // "Đại lộ Biên Hòa"
      expect(all, isNot(contains('di an'))); // "Đường Dĩ An"
    });
  });

  group('localityName', () {
    test('removes the unit type prefix after stripping tones', () {
      expect(
        VietnamAddressParser.localityName('Phường Bến Thành'),
        'ben thanh',
      );
      expect(VietnamAddressParser.localityName('Xã Cẩm Phế'), 'cam phe');
      expect(
        VietnamAddressParser.localityName('Thị Trấn Vạn Hồng'),
        'van hong',
      );
      expect(VietnamAddressParser.localityName('Đặc khu Phú Quý'), 'phu quy');
      expect(VietnamAddressParser.localityName('Bến Nghé'), 'ben nghe');
    });
  });

  group('detectProvince', () {
    test('returns null for a blank address or an empty catalogue', () {
      expect(_province('   ', _provinces), isNull);
      expect(_province('TP HCM', const []), isNull);
    });

    test('recognises a common alias on a non-street line', () {
      expect(_province('12 Lê Lợi, Quận 1, TP HCM', _provinces), '79');
      expect(_province('1 Trần Phú, HN', _provinces), '01');
      expect(_province('Sân A, Đà Lạt', _provinces), '68'); // city → province
    });

    test('an alias inside the street line is ignored', () {
      // "hn" appears as a word on the street line only.
      expect(_province('12 Hn Street', _provinces), isNull);
    });

    test('a Huế-like street name does not claim the province', () {
      // Only the street line mentions "Huệ"; Hà Nội is named explicitly.
      expect(_province('Đường Nguyễn Huệ, Hà Nội', _provinces), '01');
      expect(_province('Đường Nguyễn Huệ', _provinces), isNull);
    });

    test('an alias whose province is missing from the catalogue does not '
        'jump to another province', () {
      final withoutHcm = _provinces.where((p) => p.code != '79').toList();

      expect(_province('Quận 1, TP HCM', withoutHcm), isNull);
    });

    test('falls back to the official name on the whole address', () {
      final catalogue = [
        _area('99', 'Tỉnh Bình Phước'),
        _area('98', 'Tỉnh Bình Thuận'),
      ];

      expect(
        _province('Thị trấn X, huyện Y, Tỉnh Bình Thuận', catalogue),
        '98',
      );
    });

    test('the longer official name wins over a shorter one it contains', () {
      final catalogue = [
        _area('1', 'Thái Bình'),
        _area('2', 'Thái Bình Dương'),
      ];

      expect(_province('Biển Thái Bình Dương', catalogue), '2');
      expect(_province('Tỉnh Thái Bình', catalogue), '1');
    });

    test('matches the full name when it differs from the short name', () {
      final catalogue = [_area('7', 'Cần Thơ', 'Thành phố Cần Thơ')];

      expect(_province('Số 3, Thành phố Cần Thơ', catalogue), '7');
    });
  });

  group('detectWard', () {
    final wards = [
      _area('w1', 'Phường Bến Thành'),
      _area('w2', 'Phường Thành'),
      _area('w3', 'Phường 5'),
      _area('w4', 'Phường Hai Bà Trưng'),
      _area('w5', 'Xã Cẩm Phế'),
    ];

    test('returns null for a blank address or no wards', () {
      expect(_ward('', wards), isNull);
      expect(_ward('P. Bến Thành', const []), isNull);
    });

    test('an explicit type prefix (even abbreviated) selects the ward', () {
      expect(_ward('1 Lê Lợi, P. Bến Thành, Quận 1', wards), 'w1');
      expect(_ward('Phường Bến Thành', wards), 'w1');
      expect(_ward('xã cẩm phế, huyện Y', wards), 'w5');
    });

    test('the more specific ward wins over a shorter one it contains', () {
      expect(_ward('P. Bến Thành', wards), 'w1');
    });

    test('a numeric ward needs its prefix', () {
      expect(_ward('Phường 5, Quận 3', wards), 'w3');
      expect(_ward('Số 5, Quận 3', wards), isNull); // bare "5" is never a ward
    });

    test('a bare ward name is accepted on a locality line', () {
      expect(_ward('Đường Lê Lợi, Bến Thành, Quận 1', wards), 'w1');
    });

    test('a street named like a ward does not become the ward', () {
      expect(_ward('221B Hai Bà Trưng, Quận 3', wards), isNull);
      expect(_ward('Đường Hai Bà Trưng, Quận 3', wards), isNull);
      // ...but an explicit ward prefix still wins.
      expect(_ward('221B Hai Bà Trưng, Phường Hai Bà Trưng', wards), 'w4');
    });

    test('a bare name shorter than three characters is not matched', () {
      final short = [_area('s1', 'Phường An')];

      expect(_ward('Quận 1, An', short), isNull);
      expect(_ward('P. An', short), 's1'); // with a prefix it is fine
    });

    test('the full name can identify a ward on its own', () {
      final catalogue = [_area('f1', 'Bến Nghé', 'Phường Bến Nghé, Quận 1')];

      expect(_ward('Phường Bến Nghé, Quận 1', catalogue), 'f1');
    });
  });
}
