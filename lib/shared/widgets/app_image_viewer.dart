import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AppImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? title;

  const AppImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.title,
  });

  /// Mở xem 1 ảnh toàn màn hình với tính năng phóng to / thu nhỏ
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? title,
  }) {
    return showGallery(
      context,
      imageUrls: [imageUrl],
      initialIndex: 0,
      title: title,
    );
  }

  /// Mở xem danh sách ảnh toàn màn hình với tính năng phóng to / thu nhỏ & vuốt chuyển ảnh
  static Future<void> showGallery(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? title,
  }) {
    if (imageUrls.isEmpty) return Future.value();
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (ctx, anim, secondaryAnim) => FadeTransition(
          opacity: anim,
          child: AppImageViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            title: title,
          ),
        ),
      ),
    );
  }

  @override
  State<AppImageViewer> createState() => _AppImageViewerState();
}

class _AppImageViewerState extends State<AppImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformController = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() => _currentScale = scale);
    }
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.4).clamp(1.0, 5.0);
    _transformController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.4).clamp(0.8, 5.0);
    if (newScale <= 1.05) {
      _resetZoom();
    } else {
      _transformController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_currentScale > 1.2) {
      _resetZoom();
    } else {
      final position = details.localPosition;
      final x = -position.dx * 1.5;
      final y = -position.dy * 1.5;
      _transformController.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0)
        ..setTranslationRaw(x, y, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasMultiple = widget.imageUrls.length > 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Main Zoomable PageView / InteractiveViewer ───
          PageView.builder(
            controller: _pageController,
            physics: _currentScale > 1.05
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: widget.imageUrls.length,
            onPageChanged: (idx) {
              _resetZoom();
              setState(() => _currentIndex = idx);
            },
            itemBuilder: (context, index) {
              final url = widget.imageUrls[index];
              return Center(
                child: GestureDetector(
                  onDoubleTapDown: _handleDoubleTap,
                  onDoubleTap: () {},
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 6.0,
                    clipBehavior: Clip.none,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        );
                      },
                      errorBuilder: (_, _, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image_rounded, color: Colors.white60, size: 54),
                            const SizedBox(height: 12),
                            Text(
                              l10n.chatImageLoadError,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ─── Top Header Bar ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                12,
                MediaQuery.of(context).padding.top + 6,
                12,
                16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null)
                          Text(
                            widget.title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (hasMultiple)
                          Text(
                            '${_currentIndex + 1} / ${widget.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Reset zoom indicator
                  if (_currentScale > 1.05)
                    TextButton.icon(
                      onPressed: _resetZoom,
                      icon: const Icon(Icons.restart_alt_rounded, color: Colors.white, size: 18),
                      label: Text(
                        '${(_currentScale * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Floating Zoom Controls (Bottom Floating Bar) ───
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out_rounded, color: Colors.white, size: 22),
                    tooltip: l10n.imageViewerZoomOut,
                    onPressed: _zoomOut,
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 22),
                    tooltip: l10n.imageViewerZoomIn,
                    onPressed: _zoomIn,
                  ),
                ],
              ),
            ),
          ),

          // ─── Hint for Pinch to zoom / double tap ───
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 26,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pinch_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Chụm tay hoặc chạm 2 lần để phóng to',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
