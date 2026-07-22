import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';

/// Admin — Danh sách khiếu nại (Disputes)
///
/// Hiển thị các khiếu nại từ người dùng về:
/// - Kết quả trận đấu
/// - Hành vi của người chơi
/// - Vấn đề thanh toán
class AdminDisputesScreen extends ConsumerStatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  ConsumerState<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends ConsumerState<AdminDisputesScreen> {
  String _statusFilter = 'all'; // all, open, resolved

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
        title: const Text('Khiếu nại', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(colors),
          Expanded(child: _buildDisputeList(colors)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppColorsExtension colors) {
    final filters = [
      ('all', 'Tất cả', AppTheme.primary),
      ('open', 'Đang mở', const Color(0xFFF59E0B)),
      ('resolved', 'Đã giải quyết', const Color(0xFF10B981)),
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

  Widget _buildDisputeList(AppColorsExtension colors) {
    final disputesAsync = ref.watch(_adminDisputesProvider);

    return disputesAsync.when(
      data: (disputes) {
        final filtered = disputes.where((d) {
          if (_statusFilter == 'all') return true;
          return d['status']?.toString().toLowerCase() == _statusFilter;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel_rounded, size: 64, color: colors.textMuted.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text('Không có khiếu nại nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _buildDisputeCard(context, filtered[i], colors),
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

  Widget _buildDisputeCard(BuildContext context, Map<String, dynamic> dispute, AppColorsExtension colors) {
    final status = dispute['status']?.toString() ?? 'OPEN';
    final reason = dispute['reason']?.toString() ?? '';
    final description = dispute['description']?.toString() ?? '';
    final tournamentName = dispute['tournament']?['name']?.toString() ?? dispute['tournamentName']?.toString() ?? '---';
    final createdBy = dispute['createdBy']?['fullName']?.toString() ?? 'Người dùng';
    final createdAt = dispute['createdAt']?.toString() ?? '';

    final isOpen = status.toUpperCase() == 'OPEN';
    final statusColor = isOpen ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final statusLabel = isOpen ? 'Đang mở' : 'Đã giải quyết';

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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reason.isNotEmpty ? reason : 'Khiếu nại', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('$createdBy • $tournamentName', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(description, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
            ),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Ngày tạo: ${createdAt.substring(0, 10)}', style: TextStyle(fontSize: 10, color: colors.textMuted)),
          ],
          if (isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    'Đóng khiếu nại', Icons.check_rounded, const Color(0xFF10B981),
                    () => _handleResolve(dispute['id'], colors),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResolve(String? id, AppColorsExtension colors) async {
    if (id == null) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/admin/disputes/$id', data: {'status': 'RESOLVED'});
      ref.invalidate(_adminDisputesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã đóng khiếu nại'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

final _adminDisputesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/disputes', queryParameters: {'limit': 100});
  final data = response.data['data'] as List<dynamic>? ?? [];
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
