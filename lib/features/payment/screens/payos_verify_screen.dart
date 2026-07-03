import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:intl/intl.dart';

class PayOSVerifyScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final double amount;
  final String tournamentId;
  final String? tournamentName;

  const PayOSVerifyScreen({
    super.key,
    required this.paymentId,
    required this.amount,
    required this.tournamentId,
    this.tournamentName,
  });

  @override
  ConsumerState<PayOSVerifyScreen> createState() => _PayOSVerifyScreenState();
}

class _PayOSVerifyScreenState extends ConsumerState<PayOSVerifyScreen> {
  bool _isChecking = false;
  Timer? _autoCheckTimer;
  int _checkAttempts = 0;

  @override
  void initState() {
    super.initState();
    // Auto-poll every 5 seconds up to 12 times (1 minute) to check payment completion
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_checkAttempts >= 12) {
        _autoCheckTimer?.cancel();
        return;
      }
      _checkAttempts++;
      _verifyPaymentStatus(silent: true);
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyPaymentStatus({bool silent = false}) async {
    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      final payment = await ref.read(paymentRepositoryProvider).getPaymentById(widget.paymentId);
      if (payment != null) {
        if (payment.isCompleted && mounted) {
          _autoCheckTimer?.cancel();
          context.pushReplacement('/payment/result', extra: {
            'status': 'success',
            'tournamentId': widget.tournamentId,
            'amount': widget.amount,
          });
          return;
        } else if (payment.isFailed && mounted) {
          _autoCheckTimer?.cancel();
          context.pushReplacement('/payment/result', extra: {
            'status': 'fail',
            'tournamentId': widget.tournamentId,
            'amount': widget.amount,
          });
          return;
        }
      }
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hệ thống chưa nhận được thanh toán. Vui lòng kiểm tra lại sau vài giây.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        title: const Text('Xác nhận thanh toán'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5622).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 40,
                  color: Color(0xFFFF5622),
                ),
              ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'Thanh toán qua PayOS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vui lòng hoàn thành giao dịch chuyển khoản trên trình duyệt web vừa mở.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số tiền:', style: TextStyle(color: colors.textSecondary)),
                        Text(
                          '${fmt.format(widget.amount.ceil())}đ',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Trạng thái:', style: TextStyle(color: colors.textSecondary)),
                        Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Đang chờ thanh toán...',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isChecking ? null : () => _verifyPaymentStatus(),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'Tôi đã thanh toán',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _autoCheckTimer?.cancel();
                  context.pushReplacement('/home');
                },
                child: Text(
                  'Hủy và quay về trang chủ',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
