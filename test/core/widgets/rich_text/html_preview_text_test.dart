import 'package:app_quanly_giaidau/core/widgets/rich_text/rich_text_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'TC-HTML-PREVIEW-01 decodes entities instead of showing &nbsp; and &amp;',
    () {
      expect(
        htmlPreviewText(
          '<p>&nbsp; 🏆 THƯ MỜI ĐĂNG KÝ THAM DỰ &amp; ĐỒNG HÀNH</p>',
        ),
        '🏆 THƯ MỜI ĐĂNG KÝ THAM DỰ & ĐỒNG HÀNH',
      );
    },
  );

  test('TC-HTML-PREVIEW-02 keeps words of adjacent blocks apart', () {
    expect(
      htmlPreviewText('<p>Kính gửi</p><p>Quý Anh/Chị</p>'),
      'Kính gửi Quý Anh/Chị',
    );
  });
}
