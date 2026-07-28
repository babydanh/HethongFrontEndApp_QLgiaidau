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
      'name': 'PayOS VietQR',
      'desc': 'Quét QR thanh toán tự động qua 40+ Ngân hàng & Ví điện tử',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Color(0xFFFF5622),
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
            throw Exception('Không thể mở ứng dụng/trình duyệt thanh toán PayOS');
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
          throw Exception('Cổng PayOS chưa phản hồi đường dẫn thanh toán hợp lệ');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể khởi tạo cổng thanh toán. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thanh toán: ${e.toString().replaceAll('Exception: ', '')}'),
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
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Summary Card (TasteSkill polished)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFree
                          ? colors.success.withValues(alpha: 0.12)
                          : AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isFree ? 'THAM GIA MIỄN PHÍ' : 'LỆ PHÍ THAM GIA GIẢI ĐẤU',
                      style: TextStyle(
                        color: isFree ? colors.success : AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isFree ? '0đ' : '${fmt.format(widget.amount.ceil())}đ',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.tournamentName != null &&
                      widget.tournamentName!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.tournamentName!,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cổng PayOS VietQR • Bảo mật 256-bit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),

            const SizedBox(height: 28),
            Text(
              'CỔNG THANH TOÁN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: colors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Gateway options
            ..._gateways.map((gw) => _buildGatewayOption(context, gw)),

            const SizedBox(height: 28),
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: colors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bằng cách bấm nút bên dưới, bạn đồng ý kích hoạt lượt đăng ký và tuân thủ các quy định của giải đấu.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pay action button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: context.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleCheckout,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_rounded, size: 18),
                  label: Text(
                    _isSubmitting
                        ? 'Đang mở cổng PayOS...'
                        : isFree
                            ? 'Xác nhận tham gia (Miễn phí)'
                            : 'Thanh toán ${fmt.format(widget.amount.ceil())}đ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayOption(BuildContext context, Map<String, dynamic> gw) {
    final colors = context.colors;
    final isSelected = _selectedGateway == gw['id'];
    final color = gw['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedGateway = gw['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.08) : colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : colors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(gw['icon'] as IconData, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            gw['name'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'KHUYÊN DÙNG',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF5622),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gw['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : colors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
