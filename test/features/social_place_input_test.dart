import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_place_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('looksLikeStreetAddress', () {
    test('chấp nhận địa chỉ có dấu phẩy', () {
      expect(looksLikeStreetAddress('30 Tân Thắng, P.15, Q.Tân Bình'), isTrue);
    });

    test('chấp nhận địa chỉ bắt đầu bằng số nhà', () {
      expect(looksLikeStreetAddress('30 Tân Thắng'), isTrue);
      expect(looksLikeStreetAddress('221B Hai Bà Trưng'), isTrue);
    });

    test('chấp nhận địa chỉ bắt đầu bằng từ chỉ đường', () {
      expect(looksLikeStreetAddress('Đường Lê Lợi'), isTrue);
      expect(looksLikeStreetAddress('Hẻm 12 Lữ Gia'), isTrue);
      expect(looksLikeStreetAddress('Ngõ 5 Phố Huế'), isTrue);
      expect(looksLikeStreetAddress('Quốc lộ 1A'), isTrue);
      expect(looksLikeStreetAddress('Số 5 Hà Nội'), isTrue);
      expect(looksLikeStreetAddress('Nhà số 12 Nguyễn Huệ'), isTrue);
    });

    test('từ khoá đường phải đứng đầu chuỗi, không ở giữa', () {
      // "Sân đường Nguyễn Huệ" là tên sân, không phải địa chỉ.
      expect(looksLikeStreetAddress('Sân đường Nguyễn Huệ'), isFalse);
    });

    test('tên sân thuần không phải địa chỉ', () {
      expect(looksLikeStreetAddress('Sân nhà anh Tuấn'), isFalse);
      expect(looksLikeStreetAddress('Nhà thi đấu Phú Thọ'), isFalse);
      expect(looksLikeStreetAddress('Sân bóng'), isFalse);
    });

    test('chuỗi rỗng hoặc toàn khoảng trắng không phải địa chỉ', () {
      expect(looksLikeStreetAddress(''), isFalse);
      expect(looksLikeStreetAddress('   '), isFalse);
    });

    test('so khớp không phân biệt hoa thường', () {
      expect(looksLikeStreetAddress('duong le loi'), isTrue);
      expect(looksLikeStreetAddress('HEM 12'), isTrue);
    });
  });
}
