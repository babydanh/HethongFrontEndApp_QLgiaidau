import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> _handleCheckout() async {
    setState(() => _isSubmitting = true);
    try {
      // Free tournament handling
      if (widget.amount <= 0) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xác nhận tham gia giải đấu (Miễn phí)!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/payments');
          }
        }
        return;
      }

      // Paid tournament handling via PayOS
      final result = await ref.read(paymentRepositoryProvider).createPaymentLink(
        CreatePaymentDto(
          tournamentId: widget.tournamentId,
          participantId: widget.participantId,
          amount: widget.amount,
        ),
      );

      if (result != null && mounted) {
        final paymentId = result['paymentId'] ?? '';
        final paymentUrl = result['paymentUrl'] ?? '';
        if (paymentUrl.isNotEmpty) {
          final uri = Uri.parse(paymentUrl);
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!opened) {
            throw Exception('Không thể mở trang thanh toán PayOS');
          }
          if (mounted) {
            context.pushReplacement('/payment/payos-verify', extra: {
              'paymentId': paymentId,
              'amount': widget.amount,
              'tournamentId': widget.tournamentId,
              'tournamentName': widget.tournamentName,
            });
          }
        } else {
          throw Exception('Không lấy được liên kết thanh toán');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo cổng thanh toán. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');
    final colors = context.colors;
    final isFree = widget.amount <= 0;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          'Xác nhận thanh toán',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Summary Card - Minimal & Clean
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  Text(
                    isFree ? 'MIỄN PHÍ' : 'LỆ PHÍ THAM GIA',
                    style: TextStyle(
                      color: isFree ? const Color(0xFF10B981) : colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isFree ? '0đ' : '${fmt.format(widget.amount.ceil())}đ',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (widget.tournamentName != null &&
                      widget.tournamentName!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.tournamentName!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (!isFree) ...[
              Text(
                'PHƯƠNG THỨC THANH TOÁN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Simple Gateway Option
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selectedGateway = 'PAYOS'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedGateway == 'PAYOS'
                            ? AppTheme.primary
                            : colors.border,
                        width: _selectedGateway == 'PAYOS' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PayOS VietQR',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quét mã QR tự động qua ứng dụng ngân hàng',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedGateway == 'PAYOS'
                                ? AppTheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedGateway == 'PAYOS'
                                  ? AppTheme.primary
                                  : colors.border,
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text(
              'Nhấn bên dưới để xác nhận và hoàn tất đăng ký tham gia.',
              style: TextStyle(
                fontSize: 12,
                color: colors.textMuted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Clean Pay Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isFree
                            ? 'Xác nhận tham gia (Miễn phí)'
                            : 'Thanh toán ${fmt.format(widget.amount.ceil())}đ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
