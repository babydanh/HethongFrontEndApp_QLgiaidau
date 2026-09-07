import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Cropper dùng chung cho avatar/logo: kéo ảnh, zoom và xuất ảnh vuông PNG.
class ImageCropDialog extends StatefulWidget {
  final Uint8List bytes;
  final String title;

  const ImageCropDialog({super.key, required this.bytes, required this.title});

  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List bytes,
    required String title,
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImageCropDialog(bytes: bytes, title: title),
    );
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final _transform = TransformationController();
  late final img.Image _source;
  double _zoom = 1;

  @override
  void initState() {
    super.initState();
    _source = img.decodeImage(widget.bytes) ?? img.Image(width: 1, height: 1);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() => _zoom = 1);
    _transform.value = Matrix4.identity();
  }

  Uint8List _crop() {
    const viewport = 280.0;
    final scale =
        (_source.width > _source.height ? _source.width : _source.height) /
        viewport /
        _zoom;
    final matrix = _transform.value;
    final dx = matrix.getTranslation().x / _zoom;
    final dy = matrix.getTranslation().y / _zoom;
    final size = (viewport * scale).round().clamp(
      1,
      _source.width < _source.height ? _source.width : _source.height,
    );
    final centerX = _source.width / 2 - dx * scale;
    final centerY = _source.height / 2 - dy * scale;
    final left = (centerX - size / 2).round().clamp(0, _source.width - size);
    final top = (centerY - size / 2).round().clamp(0, _source.height - size);
    final cropped = img.copyCrop(
      _source,
      x: left,
      y: top,
      width: size,
      height: size,
    );
    return Uint8List.fromList(
      img.encodePng(img.copyResize(cropped, width: 512, height: 512)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: SizedBox(
                width: 280,
                height: 280,
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(120),
                  child: Image.memory(widget.bytes, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.zoom_out, size: 18),
                Expanded(
                  child: Slider(
                    value: _zoom,
                    min: 1,
                    max: 4,
                    onChanged: (value) => setState(() => _zoom = value),
                  ),
                ),
                const Icon(Icons.zoom_in, size: 18),
              ],
            ),
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Đặt lại căn chỉnh'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _crop()),
          child: const Text('Dùng ảnh này'),
        ),
      ],
    );
  }
}
