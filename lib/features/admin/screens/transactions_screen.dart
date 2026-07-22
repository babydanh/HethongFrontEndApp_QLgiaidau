import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:intl/intl.dart';

/// Admin — Lịch sử giao dịch (Transactions)
///
/// Hiển thị tất cả giao dịch trong hệ thống:
/// - Thanh toán giải đấu
/// - Hoàn tiền
/// - Chuyển khoản
class AdminTransactionsScreen extends ConsumerStatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  ConsumerState<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends ConsumerState<AdminTransactionsScreen> {
  String _statusFilter = 'all'; // all, completed, pending, failed

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Lịch sử giao dịch', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(colors),
          Expanded(child: _buildTransactionList(colors)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppColorsExtension colors) {
    final filters = [
      ('all', 'Tất cả', AppTheme.primary),
      ('completed', 'Hoàn thành', const Color(0xFF10B981)),
      ('pending', 'Chờ xử lý', const Color(0xFFF59E0B)),
      ('failed', 'Thất bại', const Color(0xFFEF4444)),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: filters.map((f) {
          final selected = _statusFilter == f.$1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: f != filters.last ? 6 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _statusFilter = f.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? f.$3.withValues(alpha: 0.12) : colors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? f.$3.withValues(alpha: 0.4) : colors.border,
                    ),
                  ),
                  child: Text(
                    f.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected ? f.$3 : colors.textSecondary,
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

  Widget _buildTransactionList(AppColorsExtension colors) {
    final transactionsAsync = ref.watch(_adminTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final filtered = transactions.where((t) {
          if (_statusFilter == 'all') return true;
          final status = t['status']?.toString().toLowerCase() ?? '';
          return status == _statusFilter;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 64, color: colors.textMuted.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text('Không có giao dịch nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _buildTransactionCard(context, filtered[i], colors),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text('Lỗi tải dữ liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> transaction, AppColorsExtension colors) {
    final status = transaction['status']?.toString() ?? 'PENDING';
    final amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
    final gateway = transaction['paymentGateway']?.toString() ?? transaction['gateway']?.toString() ?? '---';
    final tournamentName = transaction['tournament']?['name']?.toString() ?? transaction['tournamentName']?.toString() ?? '---';
    final userName = transaction['user']?['fullName']?.toString() ?? transaction['userName']?.toString() ?? 'Người dùng';
    final createdAt = transaction['createdAt']?.toString() ?? '';
    final reference = transaction['transactionReference']?.toString() ?? '';

    final fmt = NumberFormat('#,###', 'vi_VN');

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Hoàn thành';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'PENDING':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Chờ xử lý';
        statusIcon = Icons.access_time_rounded;
        break;
      case 'FAILED':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Thất bại';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = colors.textMuted;
        statusLabel = status;
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
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
                    Text(tournamentName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('$userName • $gateway', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${fmt.format(amount.ceil())}đ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
                  ),
                ],
              ),
            ],
          ),
          if (reference.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Mã GD: $reference', style: TextStyle(fontSize: 10, color: colors.textMuted)),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(createdAt.length >= 16 ? createdAt.substring(0, 16).replaceAll('T', ' ') : createdAt,
                style: TextStyle(fontSize: 10, color: colors.textMuted)),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

final _adminTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/transactions', queryParameters: {'limit': 100});
  final data = response.data['data'] as List<dynamic>? ?? [];
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
