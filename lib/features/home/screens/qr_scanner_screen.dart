import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Trích xuất token từ URL nếu QR được tạo theo dạng app_quanly_giaidau:join?code=XXX
    if (code.contains('code=')) {
      final uri = Uri.tryParse(code);
      if (uri != null && uri.queryParameters.containsKey('code')) {
        code = uri.queryParameters['code']!;
      } else {
        final parts = code.split('code=');
        if (parts.length > 1) {
          code = parts[1].split('&').first;
        }
      }
    }

    setState(() => _isProcessing = true);
    
    // Attempt to validate token
    final success = await ref.read(authProvider.notifier).validateToken(code);
    
    if (!mounted) return;

    if (success) {
      final auth = ref.read(authProvider);
      final route = switch (auth.role) {
        UserRole.admin => '/admin/tournament/${auth.tournamentId}',
        UserRole.referee => '/intro/${auth.tournamentId}',
        UserRole.viewer => '/intro/${auth.tournamentId}',
        _ => '/home',
      };
      
      // Stop scanner before navigating away
      _controller.stop();
      context.go(route);
    } else {
      // Show error and resume scanning after a delay
      final auth = ref.read(authProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Mã QR không hợp lệ'),
          backgroundColor: context.colors.error,
        ),
      );
      
      // Wait a bit before allowing another scan
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Quét mã QR', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          
          // Custom scanner overlay
          CustomPaint(
            painter: ScannerOverlayPainter(borderColor: AppTheme.primary),
            child: const SizedBox.expand(),
          ),
          
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Đang xác thực...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;

  ScannerOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scanArea = size.width * 0.7;
    final left = (size.width - scanArea) / 2;
    final top = (size.height - scanArea) / 2;
    final rect = Rect.fromLTWH(left, top, scanArea, scanArea);

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    
    // Draw background with cutout
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
          ..close(),
      ),
      bgPaint,
    );

    // Draw corners
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final double cornerLength = scanArea * 0.1;
    final double radius = 16.0;

    // Top left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + radius)
        ..arcToPoint(Offset(left + radius, top), radius: Radius.circular(radius))
        ..lineTo(left + cornerLength, top),
      borderPaint,
    );

    // Top right
    canvas.drawPath(
      Path()
        ..moveTo(left + scanArea - cornerLength, top)
        ..lineTo(left + scanArea - radius, top)
        ..arcToPoint(Offset(left + scanArea, top + radius), radius: Radius.circular(radius))
        ..lineTo(left + scanArea, top + cornerLength),
      borderPaint,
    );

    // Bottom right
    canvas.drawPath(
      Path()
        ..moveTo(left + scanArea, top + scanArea - cornerLength)
        ..lineTo(left + scanArea, top + scanArea - radius)
        ..arcToPoint(Offset(left + scanArea - radius, top + scanArea), radius: Radius.circular(radius))
        ..lineTo(left + scanArea - cornerLength, top + scanArea),
      borderPaint,
    );

    // Bottom left
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLength, top + scanArea)
        ..lineTo(left + radius, top + scanArea)
        ..arcToPoint(Offset(left, top + scanArea - radius), radius: Radius.circular(radius))
        ..lineTo(left, top + scanArea - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
