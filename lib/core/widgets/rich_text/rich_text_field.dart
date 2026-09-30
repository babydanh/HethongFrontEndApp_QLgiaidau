import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'rich_text_display.dart';

/// Ô nhập mô tả dạng rich text, dùng **đúng Editor.js của web** nhúng trong
/// WebView.
///
/// Vì sao WebView + Editor.js thay vì editor native (flutter_quill…):
/// trường `description` dùng chung giữa web và app, mà web lưu bằng Editor.js và
/// xuất ra **HTML**. Nếu app dùng editor lưu theo định dạng khác (Delta JSON…) thì
/// mỗi lần lưu sẽ phá hỏng nội dung web đang hiển thị. Nhúng lại Editor.js thì
/// hai đầu dùng chung đúng một engine và đúng một hàm quy đổi HTML, không lệch.
///
/// Vì sao mở sheet riêng thay vì nhúng thẳng vào form:
/// 1. Editor.js cần bề ngang đủ rộng, nếu bị bóp trong cột hẹp (~330px) thì hộp
///    công cụ (Ordered List / Checklist / Image) xếp chồng chiếm gần hết khung.
///    Sheet rộng giúp nó nằm gọn ngang hàng như bản web.
/// 2. WebView nạp ~330KB JS (4 file UMD). Nếu dựng trong sheet thì mỗi lần bấm
///    phải chờ nạp lại từ đầu. Widget này giữ controller sống suốt và nạp trước
///    ngay khi màn dựng, nên lúc bấm vào là mở ra luôn.
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
    this.label,
    this.placeholder = 'Nhập mô tả…',
    super.key,
  });

  /// Nội dung hiện tại (HTML).
  final String value;

  /// Gọi khi nội dung HTML thay đổi.
  final ValueChanged<String> onChanged;

  final String? label;

  final String? placeholder;

  @override
  State<RichTextField> createState() => _RichTextFieldState();
}

class _RichTextFieldState extends State<RichTextField> {
  /// Tin nhắn `__ready__` từ trang HTML: đã nạp xong 4 file UMD của Editor.js,
  /// giờ mới gửi giá trị sang. Gọi `setEditorHtml` sớm hơn sẽ hỏng vì
  /// `window.EditorJS` lúc đó chưa tồn tại.
  static const String _readySignal = '__ready__';

  late final WebViewController _controller;
  late String _value = widget.value;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Nạp ngay khi màn dựng thay vì chờ bấm. WebView vẫn chạy khi nằm trong
    // `Opacity(opacity: 0)` nên tới lúc bấm là Editor.js đã sẵn sàng.
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('RichTextChannel', onMessageReceived: _onMessage)
      ..loadFlutterAsset('assets/editorjs/editor.html');
  }

  @override
  void didUpdateWidget(covariant RichTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Form cha nạp lại giá trị (ví dụ sau khi bấm "Xong" rồi sửa tiếp) thì đồng
    // bộ với WebView, không phải chờ lần mở sheet sau.
    if (widget.value != _value && widget.value != oldWidget.value) {
      _value = widget.value;
      _pushValueToEditor();
    }
  }

  @override
  void dispose() {
    // Không `clearCache()`: xoá cache làm mỗi lần mở phải nạp lại 330KB từ
    // đầu. Giữ cache thì lần sau WebView vào thẳng trang đã parse xong.
    // WebViewController không có dispose() — để engine tự hủy cùng widget.
    super.dispose();
  }

  void _pushValueToEditor() {
    if (!_ready) return;
    _controller.runJavaScript('window.setEditorHtml(${jsonEncode(_value)});');
  }

  void _onMessage(JavaScriptMessage message) {
    final html = message.message;
    if (!mounted) return;
    if (html == _readySignal) {
      setState(() => _ready = true);
      _pushValueToEditor();
      return;
    }
    if (html != _value) {
      setState(() => _value = html);
      widget.onChanged(html);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = _value.trim().isNotEmpty;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label ?? '',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            // Ô mở editor: chỉ là thẻ bấm, KHÔNG chứa WebView.
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openEditor(context),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: hasValue
                    // Xem trước: bỏ thẻ HTML cho gọn, tránh nhúng thêm widget
                    // nặng vào màn có sẵn nhiều nội dung.
                    ? Text(
                        stripHtmlTags(_value),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.placeholder!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.disabledColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: theme.disabledColor,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
        // WebView ấm: kích thước 1×1 và trong suốt nên không chiếm chỗ, nhưng vẫn
        // nằm trong cây widget để engine nạp Editor.js ngay. Giữ nguyên vị trí cả
        // sau khi sẵn sàng — bỏ đi là controller mất platform view và sheet mở ra
        // sẽ trắng.
        Positioned(
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          child: Opacity(
            opacity: 0,
            child: IgnorePointer(child: WebViewWidget(controller: _controller)),
          ),
        ),
      ],
    );
  }

  void _openEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Cao ~92% màn hình: đủ rộng cho editor và không che mất nút lưu.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        maxWidth: 720,
      ),
      builder: (sheetContext) => _RichTextEditorSheet(
        controller: _controller,
        ready: _ready,
      ),
    );
  }
}

/// Nội dung sheet: tái dùng controller đã ấm sẵn từ `RichTextField`.
class _RichTextEditorSheet extends StatefulWidget {
  const _RichTextEditorSheet({
    required this.controller,
    required this.ready,
  });

  final WebViewController controller;
  final bool ready;

  @override
  State<_RichTextEditorSheet> createState() => _RichTextEditorSheetState();
}

class _RichTextEditorSheetState extends State<_RichTextEditorSheet> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Header gọn: dùng toolbar cuối cùng của Editor.js làm nút đóng để khỏi
        // thêm một lớp điều hướng.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mô tả',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Xong'),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: widget.controller),
              if (!widget.ready)
                ColoredBox(
                  color: theme.colorScheme.surface,
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
      ],
    );
  }
}
