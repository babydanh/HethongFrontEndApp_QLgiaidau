import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Ô soạn thảo mô tả dạng rich text, dùng **đúng Editor.js của web** nhúng trong
/// WebView.
///
/// Vì sao WebView + Editor.js thay vì editor native (flutter_quill…):
/// trường `description` dùng chung giữa web và app, mà web lưu bằng Editor.js và
/// xuất ra **HTML**. Nếu app dùng editor lưu theo định dạng khác (Delta JSON…) thì
/// mỗi lần lưu sẽ phá hỏng nội dung web đang hiển thị. Nhúng lại Editor.js thì
/// hai đầu dùng chung đúng một engine và đúng một hàm quy đổi HTML, không lệch.
///
/// Dùng `loadFlutterAsset` (không phải `loadHtmlString`): file nằm trong
/// `assets/editorjs/` khai báo ở pubspec. `loadHtmlString` với `<script src>`
/// tương đối sẽ ra trang trắng trên Android vì không có base URL để phân giải.
///
/// Hai hàm quy đổi `htmlToEditorjs` / `editorjsToHtml` nằm trong
/// `assets/editorjs/editor.html`, port nguyên văn từ
/// `HethongFrontEndWeb_QLgiaidau/src/components/ui/RichTextEditor.tsx`.
class RichTextField extends StatefulWidget {
  const RichTextField({
    required this.value,
    required this.onChanged,
    this.readOnly = false,
    this.placeholder,
    this.minHeight = 140,
    this.label,
    this.errorText,
    super.key,
  });

  /// Nội dung hiện tại (HTML). Chỉ nạp vào editor một lần khi widget mount.
  final String value;

  /// Gọi mỗi khi nội dung HTML thay đổi. Lưu ý: kèm cả lúc editor vừa sẵn sàng
  /// (giá trị chuẩn hoá), nên màn gọi chỉ cần so sánh rồi mới setState.
  final ValueChanged<String> onChanged;

  final bool readOnly;

  final String? placeholder;

  final double minHeight;

  final String? label;

  final String? errorText;

  @override
  State<RichTextField> createState() => _RichTextFieldState();

}

class _RichTextFieldState extends State<RichTextField> {
  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'RichTextChannel',
        onMessageReceived: _onMessage,
      )
      // Nạp từ flutter_assets: đường dẫn tương đối trong HTML
      // (`editorjs.umd.js`…) sẽ phân giải đúng cạnh file này.
      ..loadFlutterAsset('assets/editorjs/editor.html');
  }

  // Tin nhắn `__ready__` từ trang HTML: đã nạp xong 4 file UMD của Editor.js,
  // giờ mới gửi giá trị ban đầu sang. Mọi tin nhắn khác là nội dung HTML mà
  // người dùng vừa sửa. Gọi `setEditorHtml` sớm hơn sẽ hỏng vì `window.EditorJS`
  // lúc đó chưa tồn tại.
  static const String _readySignal = '__ready__';

  void _onMessage(JavaScriptMessage message) {
    final html = message.message;
    if (!mounted) return;
    if (html == _readySignal) {
      _sendValue();
      return;
    }
    setState(() => _ready = true);
    widget.onChanged(html);
  }

  /// Gửi giá trị hiện tại (HTML) sang editor.
  void _sendValue() {
    _controller.runJavaScript('window.setEditorHtml(${jsonEncode(widget.value)});');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: widget.minHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.errorText != null ? theme.colorScheme.error : theme.dividerColor,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // `WebViewWidget` không có kích thước nội tại. Đặt trong
                // ListView (chiều cao vô hạn) mà chỉ set `minHeight` thì
                // container co về 0 → "Cannot hit test a render box with no size".
                // Vì vậy dùng `height` cố định cho khung editor.
                WebViewWidget(controller: _controller),
                if (!_ready)
                  const ColoredBox(
                    color: Colors.white,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              widget.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
