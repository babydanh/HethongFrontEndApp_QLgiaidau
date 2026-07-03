import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:intl/intl.dart';

class MockGatewayScreen extends ConsumerStatefulWidget {
  const MockGatewayScreen({super.key});

  @override
  ConsumerState<MockGatewayScreen> createState() => _MockGatewayScreenState();
}

class _MockGatewayScreenState extends ConsumerState<MockGatewayScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _timeLeft = 180;
  Timer? _timer;
  bool _isSubmitting = false;
  bool _isExpired = false;

  final _gatewayColors = {
    'VNPAY': const Color(0xFF1565C0),
    'MOMO': const Color(0xFFD81B60),
    'TRANSFER': const Color(0xFF059669),
  };

  final _gatewayLabels = {
    'VNPAY': 'VNPAY',
    'MOMO': 'MoMo',
    'TRANSFER': 'Chuyển khoản ngân hàng',
  };

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft <= 0) {
        _timer?.cancel();
        if (mounted) setState(() => _isExpired = true);
        return;
      }
      if (mounted) setState(() => _timeLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChange(int index, String value) {
    if (value.length > 1) value = value.substring(0, 1);
    if (value.isNotEmpty && !RegExp(r'^\d$').hasMatch(value)) return;
    _otpControllers[index].text = value;
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final extra = GoRouterState.of(context).extra as Map?;
    final paymentId = extra?['paymentId'] ?? '';

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() => _isSubmitting = true);
    try {
      final success = await ref.read(paymentRepositoryProvider).mockVerify(paymentId);
      if (success && mounted) {
        context.pushReplacement('/payment/result', extra: {
          'status': 'success',
          'tournamentId': extra?['tournamentId'] ?? '',
          'amount': extra?['amount'] ?? 0,
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã OTP không hợp lệ!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map?;
    final gateway = extra?['gateway'] ?? 'VNPAY';
    final amount = (extra?['amount'] ?? 0).toDouble();
    final color = _gatewayColors[gateway] ?? AppTheme.primary;
    final label = _gatewayLabels[gateway] ?? gateway;
    final fmt = NumberFormat('#,###', 'vi_VN');
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: Text('Xác thực $label'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_rounded, color: color, size: 36),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text('Thanh toán qua $label',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
            const SizedBox(height: 8),
            Text('${fmt.format(amount.ceil())}đ',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 44, height: 52,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          onChanged: (v) => _onOtpChange(index, v),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.colors.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: context.colors.bgSurface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: 2)),
                            counterText: '',
                          ),
                          maxLength: 1,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_rounded, size: 16,
                          color: _isExpired ? context.colors.error : context.colors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        _isExpired ? 'Mã đã hết hạn' : '$minutes:$seconds',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: _isExpired ? context.colors.error : context.colors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting || _isExpired ? null : _verifyOtp,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(_isSubmitting ? 'Đang xác thực...' : 'Xác nhận thanh toán'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Hủy', style: TextStyle(color: context.colors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
