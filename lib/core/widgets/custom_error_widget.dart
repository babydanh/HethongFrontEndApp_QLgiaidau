import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const CustomErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    // Trong môi trường release, ta không muốn hiển thị chi tiết lỗi cho người dùng.
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: context.colors.error.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: context.colors.error.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_rounded,
                color: context.colors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Đã có lỗi hiển thị',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Đội ngũ kỹ thuật đã được thông báo và sẽ xử lý sớm nhất có thể.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              // Trong Debug Mode có thể hiển thị thêm dòng chi tiết
              // const SizedBox(height: 16),
              // Text(
              //   details.exceptionAsString(),
              //   style: TextStyle(fontSize: 10, color: context.colors.textMuted),
              //   textAlign: TextAlign.center,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
