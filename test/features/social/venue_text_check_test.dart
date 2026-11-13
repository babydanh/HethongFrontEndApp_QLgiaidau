import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/venue_text_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // TC-VENUE-TEXT-APP-02
  group('checkVenueFields', () {
    test('two empty fields give no hint', () {
      expect(checkVenueFields('', ''), isNull);
      expect(checkVenueFields('  ', ' '), isNull);
    });

    test('names that merely contain a number are names, not addresses', () {
      expect(checkVenueFields('Sân 79', ''), isNull);
      expect(checkVenueFields('Pickleball 36', ''), isNull);
      expect(checkVenueFields('Sân 5A', ''), isNull);
      expect(checkVenueFields('79 Sân Mộc', ''), isNull);
    });

    test('a name typed in the address field is flagged and moved', () {
      final hint = checkVenueFields('', 'Sân 79')!;
      expect(hint.code, VenueTextHintCode.addressIsName);
      expect(hint.next, (name: 'Sân 79', address: ''));

      final swapped = checkVenueFields('1 Lê Lợi', 'Pickleball 36')!;
      expect(swapped.code, VenueTextHintCode.nameIsAddress);
      expect(swapped.next, (name: 'Pickleball 36', address: '1 Lê Lợi'));
    });

    test('name field holding only an address is flagged', () {
      final hint = checkVenueFields('123 Nguyễn Văn A, P.5, Q.3', '')!;
      expect(hint.code, VenueTextHintCode.nameIsAddress);
      expect(hint.next, (name: '', address: '123 Nguyễn Văn A, P.5, Q.3'));

      final withName = checkVenueFields('123 Nguyễn Văn A', 'Sân Mộc')!;
      expect(withName.code, VenueTextHintCode.nameIsAddress);
      expect(withName.next, (name: 'Sân Mộc', address: '123 Nguyễn Văn A'));
    });

    test('name field with venue name followed by an address is split', () {
      final hint = checkVenueFields('Nhà thi đấu Phú Thọ, Q.11', '')!;
      expect(hint.code, VenueTextHintCode.nameHasAddress);
      expect(hint.next, (name: 'Nhà thi đấu Phú Thọ', address: 'Q.11'));

      final three = checkVenueFields('Sân Mộc, 123 Nguyễn Văn A, P.5', '')!;
      expect(three.code, VenueTextHintCode.nameHasAddress);
      expect(three.next, (name: 'Sân Mộc', address: '123 Nguyễn Văn A, P.5'));
    });

    test('split address is prepended to an existing address field', () {
      final hint = checkVenueFields('Sân Mộc, 123 Nguyễn Văn A', 'P.5, Q.3')!;
      expect(hint.code, VenueTextHintCode.nameHasAddress);
      expect(hint.next, (name: 'Sân Mộc', address: '123 Nguyễn Văn A, P.5, Q.3'));
    });

    test('address repeating the typed name is trimmed', () {
      final hint = checkVenueFields('Sân Mộc', 'Sân Mộc, 123 Nguyễn Văn A')!;
      expect(hint.code, VenueTextHintCode.addressRepeatsName);
      expect(hint.next, (name: 'Sân Mộc', address: '123 Nguyễn Văn A'));

      final dash = checkVenueFields('Sân Mộc', 'sân mộc - 123 Lê Lợi')!;
      expect(dash.code, VenueTextHintCode.addressRepeatsName);
      expect(dash.next, (name: 'Sân Mộc', address: '123 Lê Lợi'));
    });

    test('a name sharing only a prefix with the address is not a repeat', () {
      expect(
        checkVenueFields('Sân 7', 'Sân 79 Lê Lợi')?.code,
        isNot(VenueTextHintCode.addressRepeatsName),
      );
      // Names shorter than 3 characters are never treated as repeated.
      expect(checkVenueFields('Ab', 'Ab, 123 Lê Lợi'), isNull);
    });

    test('identical fields are flagged without a replacement', () {
      final hint = checkVenueFields('Sân Mộc', ' sân  MỘC ')!;
      expect(hint.code, VenueTextHintCode.sameText);
      expect(hint.next, isNull);
    });

    test('works without diacritics and with mixed case', () {
      final noTone = checkVenueFields('nha thi dau phu tho, q.11', '')!;
      expect(noTone.code, VenueTextHintCode.nameHasAddress);
      expect(noTone.next, (name: 'nha thi dau phu tho', address: 'q.11'));

      final upper = checkVenueFields('', 'PICKLEBALL 36')!;
      expect(upper.code, VenueTextHintCode.addressIsName);

      final street = checkVenueFields('DUONG Nguyen Hue', '')!;
      expect(street.code, VenueTextHintCode.nameIsAddress);

      final ward = checkVenueFields('PHUONG Ben Nghe', '')!;
      expect(ward.code, VenueTextHintCode.nameIsAddress);
    });

    test('a correct name and address pair gives no hint', () {
      expect(checkVenueFields('Sân Mộc', '123 Nguyễn Văn A, P.5'), isNull);
      expect(checkVenueFields('Pickleball 36', '36 Lê Lợi, Q.1'), isNull);
    });
  });
}
