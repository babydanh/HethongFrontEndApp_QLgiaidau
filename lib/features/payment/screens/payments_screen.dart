import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

final myPaymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  return ref.watch(paymentRepositoryProvider).getMyPayments();
});

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _filter = 'all'; // all, completed, pending, failed
  bool _isProcessingLink = false;

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(myPaymentsProvider);
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

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
          l10n.payments_title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textSecondary),
            tooltip: l10n.payments_refreshTooltip,
            onPressed: () => ref.refresh(myPaymentsProvider),
          ),
        ],
      ),
      body: paymentsAsync.when(
        data: (payments) => _buildContent(context, ref, payments, l10n),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
                const SizedBox(height: 12),
                Text(
                  '${l10n.payments_loadError} $e',
                  style: TextStyle(color: colors.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(myPaymentsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.infoRetry),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<PaymentModel> payments,
    AppLocalizations l10n,
  ) {
    final colors = context.colors;
    final pending = payments.where((p) => p.isPending).toList();

    // Apply filter
    final filteredPayments = payments.where((p) {
      switch (_filter) {
        case 'completed':
          return p.isCompleted;
        case 'pending':
          return p.isPending;
        case 'failed':
          return p.isTerminalFailure || p.isRefunded;
        default:
          return true;
      }
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myPaymentsProvider),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Stats header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.payments_totalTransactions,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.payments_transactionCount(payments.length),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pending.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.payments_pendingCount(pending.length),
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(child: _buildFilterChips(context, l10n)),

          if (filteredPayments.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.border),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 40,
                          color: colors.textMuted.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filter == 'all'
                            ? l10n.payments_emptyAll
                            : l10n.payments_emptyFiltered,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.payments_emptySubtitle,
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildPaymentCard(context, filteredPayments[index], l10n),
                  childCount: filteredPayments.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    final filters = [
      ('all', l10n.payments_filterAll, AppTheme.primary),
      ('completed', l10n.payments_filterCompleted, const Color(0xFF10B981)),
      ('pending', l10n.payments_filterPending, const Color(0xFFF59E0B)),
      ('failed', l10n.payments_filterFailed, const Color(0xFFEF4444)),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: filters.map((f) {
          final selected = _filter == f.$1;
          final chipColor = f.$3;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: f != filters.last ? 6 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _filter = f.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? chipColor.withValues(alpha: 0.16)
                          : colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? chipColor : colors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      f.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected ? chipColor : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment, AppLocalizations l10n) {
    final colors = context.colors;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt);
    Color statusColor;
    IconData statusIcon;

    if (payment.isCompleted) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
    } else if (payment.isPending) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.access_time_rounded;
    } else if (payment.isTerminalFailure) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = colors.textMuted;
      statusIcon = Icons.replay_rounded;
    }

    final fmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: payment.isPending
              ? statusColor.withValues(alpha: 0.4)
              : colors.border,
          width: payment.isPending ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPaymentDetailsSheet(context, payment, l10n),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.tournamentName ?? l10n.payments_defaultTournamentName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${payment.gatewayLabel} • $dateStr',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            payment.statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (payment.transactionReference != null &&
                    payment.transactionReference!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.numbers_rounded,
                          size: 14,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.payments_transactionRef(payment.transactionReference!),
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        if (payment.isRetryable)
                          Text(
                            l10n.payments_retryCta,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: colors.textMuted,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  void _showPaymentDetailsSheet(BuildContext context, PaymentModel payment, AppLocalizations l10n) {
    final colors = context.colors;
    final fmt = NumberFormat('#,###', 'vi_VN');
    final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(payment.createdAt);

    Color statusColor;
    IconData statusIcon;
    if (payment.isCompleted) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
    } else if (payment.isPending) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.access_time_rounded;
    } else if (payment.isTerminalFailure) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = colors.textMuted;
      statusIcon = Icons.replay_rounded;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header status
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.statusLabel,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${fmt.format(payment.amount.ceil())}đ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Details rows
                  _buildDetailRow(
                    colors,
                    l10n.payments_detailTournament,
                    payment.tournamentName ?? l10n.payments_detailUnknown,
                  ),
                  if (payment.teamName != null && payment.teamName!.isNotEmpty)
                    _buildDetailRow(colors, l10n.payments_detailTeamName, payment.teamName!),
                  _buildDetailRow(
                    colors,
                    l10n.payments_detailGateway,
                    payment.gatewayLabel,
                  ),
                  if (payment.transactionReference != null &&
                      payment.transactionReference!.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.payments_detailTransactionId,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textMuted,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              payment.transactionReference!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: payment.transactionReference!,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.payments_copied),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Actions area: Re-pay / Refresh status
                  if (payment.isRetryable) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              payment.isPending
                                  ? l10n.payments_retryPendingInfo
                                  : l10n.payments_retryFailedInfo,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref.invalidate(myPaymentsProvider);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(l10n.payments_refreshStatus),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _isProcessingLink
                                ? null
                                : () => _retryPayment(
                                    context,
                                    payment,
                                    setModalState,
                                  ),
                            icon: _isProcessingLink
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.payment_rounded, size: 18),
                            label: Text(
                              _isProcessingLink
                                  ? l10n.payments_processing
                                  : l10n.payments_payNow,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.payments_successInfo,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.bgSurface,
                          foregroundColor: colors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(l10n.payments_close),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    AppColorsExtension colors,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: colors.textMuted)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retryPayment(
    BuildContext context,
    PaymentModel payment,
    StateSetter setModalState,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setModalState(() => _isProcessingLink = true);
    try {
      if (payment.tournamentId.isNotEmpty && payment.participantId.isNotEmpty) {
        final result = await ref
            .read(paymentRepositoryProvider)
            .createPaymentLink(
              CreatePaymentDto(
                tournamentId: payment.tournamentId,
                participantId: payment.participantId,
                divisionId: payment.divisionId,
              ),
            );

        if (result != null) {
          final paymentId = result['paymentId'] ?? payment.id;
          final paymentUrl = result['paymentUrl'] ?? '';
          final qrCode = result['qrCode']?.toString() ?? '';
          final expiresAt = result['expiresAt']?.toString();
          final confirmedAmount =
              double.tryParse(result['amount']?.toString() ?? '') ??
              payment.amount;
          if (paymentUrl.isNotEmpty && context.mounted) {
            final nav = Navigator.of(context);
            final router = GoRouter.of(context);
            nav.pop();
            final uri = Uri.parse(paymentUrl);
            final opened = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (opened) {
              router.push(
                '/payment/payos-verify',
                extra: {
                  'paymentId': paymentId,
                  'amount': confirmedAmount,
                  'tournamentId': payment.tournamentId,
                  'tournamentName': payment.tournamentName,
                  'paymentUrl': paymentUrl,
                  'qrCode': qrCode,
                  'expiresAt': expiresAt,
                  'orderCode': result['orderCode']?.toString(),
                },
              );
              return;
            }
          }
        }
      }

      // Fallback: Navigate to checkout screen directly
      if (context.mounted) {
        final nav = Navigator.of(context);
        final router = GoRouter.of(context);
        nav.pop();
        router.push(
          '/payment/checkout',
          extra: {
            'tournamentId': payment.tournamentId,
            'participantId': payment.participantId,
            'divisionId': payment.divisionId,
            'amount': payment.amount,
            'tournamentName': payment.tournamentName,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorParser.parse(
                e,
                l10n.payments_createLinkError,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setModalState(() => _isProcessingLink = false);
    }
  }
}