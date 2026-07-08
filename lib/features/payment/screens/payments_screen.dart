import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:intl/intl.dart';

final myPaymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  return ref.watch(paymentRepositoryProvider).getMyPayments();
});

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(myPaymentsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: const Text('Lịch sử thanh toán'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: paymentsAsync.when(
        data: (payments) => _buildContent(context, ref, payments),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<PaymentModel> payments) {
    final pending = payments.where((p) => p.isPending).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myPaymentsProvider),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Stats header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: context.colors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded,
                        color: context.colors.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng giao dịch', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${payments.length} giao dịch',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pending.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: context.colors.warning,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${pending.length} chờ',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (payments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: context.colors.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.receipt_long_rounded,
                          size: 40, color: context.colors.textMuted.withValues(alpha: 0.4)),
                    ),
                    const SizedBox(height: 16),
                    Text('Chưa có giao dịch nào',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                    const SizedBox(height: 6),
                    Text('Các khoản thanh toán sẽ xuất hiện tại đây',
                        style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPaymentCard(context, payments[index]),
                  childCount: payments.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt);
    Color statusColor;
    IconData statusIcon;
    if (payment.isCompleted) {
      statusColor = context.colors.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (payment.isPending) {
      statusColor = context.colors.warning;
      statusIcon = Icons.access_time_rounded;
    } else if (payment.isFailed) {
      statusColor = context.colors.error;
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = context.colors.textMuted;
      statusIcon = Icons.replay_rounded;
    }

    final fmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.tournamentName ?? 'Thanh toán giải đấu',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${payment.gatewayLabel} • $dateStr',
                      style: TextStyle(fontSize: 11, color: context.colors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${fmt.format(payment.amount.ceil())}đ',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      payment.statusLabel,
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (payment.transactionReference != null) ...[
            const SizedBox(height: 8),
            Text(
              'Mã GD: ${payment.transactionReference}',
              style: TextStyle(fontSize: 10, color: context.colors.textMuted),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
