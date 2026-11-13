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
String stripHtmlTags(String text) => _decodeEntities(
  text.replaceAll(RegExp(r'<[^>]*>'), ''),
).replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

final RegExp _numericEntity = RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);');

/// Decodes the entities rich-text editors emit. `&amp;` goes last so an
/// escaped entity such as `&amp;lt;` stays the literal text `&lt;`.
String _decodeEntities(String text) => text
    .replaceAllMapped(_numericEntity, (match) {
      final digits = match[1]!;
      final code = digits.startsWith('x')
          ? int.tryParse(digits.substring(1), radix: 16)
          : int.tryParse(digits);
      if (code == null || code > 0x10FFFF) return match[0]!;
      return String.fromCharCode(code);
    })
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

/// One-line plain preview of an HTML description: tags become spaces (so
/// adjacent blocks keep their words apart), entities are decoded and
/// whitespace is collapsed.
String htmlPreviewText(String html) => stripHtmlTags(
  html.replaceAll(RegExp(r'<[^>]*>'), ' '),
).replaceAll(RegExp(r'\s+'), ' ').trim();

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
      textStyle: base.copyWith(
        fontSize: size,
        height: height,
        color: textColor,
      ),
    );
  }
}
