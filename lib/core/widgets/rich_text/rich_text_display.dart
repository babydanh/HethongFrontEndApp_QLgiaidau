import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'rich_text_styles.dart';

/// Nhận diện nội dung có phải HTML thật không.
///
/// Cũ dùng `contains('<') && contains('>')` — rất lỏng: câu tiếng Việt kiểu
/// "giá < 100k" hay "từ 10 > 5" sẽ bị nhận nhầm rồi đưa vào HTML parser và hiện
/// sai. Ở đây bắt buộc phải khớp một THẺ HTML thật: `<` + chữ cái, `/` hoặc
/// `!` + … + `>`.
final RegExp _htmlTagPattern = RegExp(r'<[a-zA-Z/!][^>]*>');

bool looksLikeHtml(String text) => _htmlTagPattern.hasMatch(text);

/// Bỏ thẻ HTML, giữ lại chữ, để hiển thị khi nội dung không phải HTML.
String stripHtmlTags(String text) => text
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

/// Hiển thị nội dung mô tả (HTML hoặc text thuần) bằng một bộ style duy nhất.
///
/// Thay cho `HtmlWidget` rải rác ở từng màn. Trước đó mỗi màn tự truyền
/// `textStyle` riêng và **không** ép cỡ thẻ tiêu đề, nên `<h1>`/`<h2>` phình to
/// trên điện thoại (xem [RichTextStyles] để rõ vì sao).
class RichTextDisplay extends StatelessWidget {
  const RichTextDisplay({
    required this.data,
    this.fontSize,
    this.height = 1.55,
    this.color,
    super.key,
  });

  /// Nội dung thô đã lưu (HTML do Editor.js sinh, hoặc text thuần).
  final String data;

  /// Ghi đè cỡ chữ gốc nếu màn đó có nhu cầu riêng.
  final double? fontSize;

  final double height;

  /// Màu chữ; mặc định lấy từ theme.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final textColor = color ?? base.color ?? const Color(0xFF0F172A);
    final size = fontSize ?? RichTextStyles.baseFontSize;

    // Không phải HTML (ví dụ mô tả cũ gõ tay) thì hiện text thuần, tránh đưa
    // nhầm vào HTML parser.
    if (!looksLikeHtml(data)) {
      return Text(
        data,
        style: base.copyWith(fontSize: size, height: height, color: textColor),
      );
    }

    return HtmlWidget(
      data,
      // Ép cỡ tiêu đề tuyệt đối, vì mặc định của thư viện dùng `em` và phình
      // to trên màn hình hẹp.
      customStylesBuilder: RichTextStyles.builder(
        baseFontSize: size,
        linkColor: const Color(0xFF2563EB),
      ),
      textStyle: base.copyWith(fontSize: size, height: height, color: textColor),
    );
  }
}
