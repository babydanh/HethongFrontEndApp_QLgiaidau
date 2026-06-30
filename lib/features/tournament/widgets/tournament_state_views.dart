import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.height = 20.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerBody extends StatelessWidget {
  const ShimmerBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            const ShimmerPlaceholder(height: 48, borderRadius: 12),
            const SizedBox(height: 16),
            const ShimmerPlaceholder(height: 100, borderRadius: 16),
            const SizedBox(height: 16),
            const ShimmerPlaceholder(height: 180, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

class NotFoundView extends StatelessWidget {
  final VoidCallback onGoHome;

  const NotFoundView({
    super.key,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 72,
            color: context.colors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            "Giải đấu không tồn tại",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onGoHome,
            icon: const Icon(Icons.home_rounded),
            label: const Text("Về trang chủ"),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: context.colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              "Không thể tải giải đấu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Thử lại"),
            ),
          ],
        ),
      ),
    );
  }
}
