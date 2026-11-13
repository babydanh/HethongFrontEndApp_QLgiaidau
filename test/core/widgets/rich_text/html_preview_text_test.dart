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

  test('TC-HTML-PREVIEW-03 decodes apostrophes and numeric entities', () {
    expect(
      stripHtmlTags('L&#39;équipe &apos;A&apos; &#8211; s&#x1EA3;n'),
      "L'équipe 'A' – sản",
    );
  });

  test(
    'TC-HTML-PREVIEW-04 decodes &amp; last so an escaped entity stays text',
    () {
      expect(
        stripHtmlTags('giá &amp;lt; 100k &amp;amp; quà'),
        'giá &lt; 100k &amp; quà',
      );
    },
  );
}
