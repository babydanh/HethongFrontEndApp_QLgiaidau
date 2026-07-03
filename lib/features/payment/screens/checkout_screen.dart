import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String participantId;
  final double amount;
  final String? tournamentName;

  const CheckoutScreen({
    super.key,
    required this.tournamentId,
    required this.participantId,
    required this.amount,
    this.tournamentName,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedGateway = 'PAYOS';
  bool _isSubmitting = false;

  final _gateways = const [
    {
      'id': 'PAYOS',
      'name': 'PayOS',
      'desc': 'Thanh toán qua PayOS (QR ngân hàng)',
      'icon': Icons.payment_rounded,
      'color': Color(0xFFFF5622),
    },
    {
      'id': 'VNPAY',
      'name': 'VNPAY',
      'desc': 'Quét QR / Internet Banking',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Color(0xFF1565C0),
    },
    {
      'id': 'MOMO',
      'name': 'MoMo',
      'desc': 'Quét QR qua Ví MoMo',
      'icon': Icons.mobile_friendly_rounded,
      'color': Color(0xFFD81B60),
    },
    {
      'id': 'TRANSFER',
      'name': 'Chuyển khoản',
      'desc': 'Chuyển khoản thủ công',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF059669),
    },
  ];

  Future<void> _handleCheckout() async {
    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(paymentRepositoryProvider).createPaymentLink(
        CreatePaymentDto(
          tournamentId: widget.tournamentId,
          participantId: widget.participantId,
          amount: widget.amount,
          paymentGateway: _selectedGateway,
        ),
      );

      if (result != null && mounted) {
        final paymentId = result['paymentId'] ?? '';
        if (_selectedGateway == 'PAYOS') {
          final paymentUrl = result['paymentUrl'] ?? '';
          if (paymentUrl.isNotEmpty) {
            final uri = Uri.parse(paymentUrl);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (mounted) {
              context.pushReplacement('/payment/payos-verify', extra: {
                'paymentId': paymentId,
                'amount': widget.amount,
                'tournamentId': widget.tournamentId,
                'tournamentName': widget.tournamentName,
              });
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không nhận được liên kết thanh toán từ PayOS')),
            );
          }
        } else {
          context.push('/payment/mock-gateway', extra: {
            'paymentId': paymentId,
            'gateway': _selectedGateway,
            'amount': widget.amount,
            'tournamentId': widget.tournamentId,
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo liên kết thanh toán')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: const Text('Thanh toán'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('LỆ PHÍ THAM GIA', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Text(
                    '${fmt.format(widget.amount.ceil())}đ',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (widget.tournamentName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.tournamentName!,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),
            Text('CHỌN CỔNG THANH TOÁN',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: context.colors.textSecondary,
                  letterSpacing: 1,
                )),
            const SizedBox(height: 12),

            // Gateway options
            ..._gateways.map((gw) => _buildGatewayOption(context, gw)).toList(),

            const SizedBox(height: 24),
            Text('BẰNG CÁCH NHẤN "THANH TOÁN", BẠN ĐỒNG Ý VỚI ĐIỀU KHOẢN CỦA CHÚNG TÔI',
                style: TextStyle(
                  fontSize: 10, color: context.colors.textMuted, fontWeight: FontWeight.w500,
                )),
            const SizedBox(height: 16),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleCheckout,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_rounded),
                label: Text(
                  _isSubmitting ? 'Đang xử lý...' : 'Thanh toán ${fmt.format(widget.amount.ceil())}đ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayOption(BuildContext context, Map<String, dynamic> gw) {
    final isSelected = _selectedGateway == gw['id'];
    final color = gw['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selectedGateway = gw['id'] as String),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : context.colors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(gw['icon'] as IconData, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gw['name'] as String,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                    Text(gw['desc'] as String,
                        style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
                  ],
                ),
              ),
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : context.colors.border,
                    width: isSelected ? 6 : 2,
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
