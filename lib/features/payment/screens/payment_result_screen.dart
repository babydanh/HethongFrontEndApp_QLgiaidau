import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:intl/intl.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map?;
    final isSuccess = extra?['status'] == 'success';
    final tournamentId = extra?['tournamentId'] ?? '';
    final amount = (extra?['amount'] ?? 0).toDouble();
    final fmt = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? context.colors.success.withValues(alpha: 0.1)
                      : context.colors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 52,
                  color: isSuccess ? context.colors.success : context.colors.error,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.colors.textPrimary),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Bạn đã thanh toán ${fmt.format(amount.ceil())}đ'
                    : 'Giao dịch không thể hoàn tất. Vui lòng thử lại!',
                style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              if (isSuccess) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colors.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded, color: context.colors.success, size: 20),
                      const SizedBox(width: 8),
                      Text('Chúc bạn thi đấu tốt!',
                          style: TextStyle(color: context.colors.success, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (tournamentId.isNotEmpty) {
                      context.go('/intro/$tournamentId');
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Quay lại giải đấu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text('Về trang chủ', style: TextStyle(color: context.colors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
