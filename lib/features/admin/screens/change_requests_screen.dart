import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';

/// Admin — Danh sách yêu cầu thay đổi (Change Requests)
///
/// Hiển thị các yêu cầu thay đổi từ người dùng:
/// - Thay đổi thông tin giải đấu
/// - Yêu cầu chỉnh sửa kết quả
/// - Yêu cầu hỗ trợ khác
class AdminChangeRequestsScreen extends ConsumerStatefulWidget {
  const AdminChangeRequestsScreen({super.key});

  @override
  ConsumerState<AdminChangeRequestsScreen> createState() => _AdminChangeRequestsScreenState();
}

class _AdminChangeRequestsScreenState extends ConsumerState<AdminChangeRequestsScreen> {
  String _statusFilter = 'all'; // all, pending, approved, rejected

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
        title: const Text('Yêu cầu thay đổi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(colors),
          Expanded(child: _buildRequestList(colors)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppColorsExtension colors) {
    final filters = [
      ('all', 'Tất cả', AppTheme.primary),
      ('pending', 'Chờ xử lý', const Color(0xFFF59E0B)),
      ('approved', 'Đã duyệt', const Color(0xFF10B981)),
      ('rejected', 'Từ chối', const Color(0xFFEF4444)),
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

  Widget _buildRequestList(AppColorsExtension colors) {
    final requestsAsync = ref.watch(_adminChangeRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        final filtered = requests.where((r) {
          if (_statusFilter == 'all') return true;
          return r['status']?.toString().toLowerCase() == _statusFilter;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note_rounded, size: 64, color: colors.textMuted.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text('Không có yêu cầu nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _buildRequestCard(context, filtered[i], colors),
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

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request, AppColorsExtension colors) {
    final status = request['status']?.toString() ?? 'PENDING';
    final type = request['type']?.toString() ?? 'Khác';
    final description = request['description']?.toString() ?? '';
    final requestedBy = request['requestedBy']?['fullName']?.toString() ?? 'Người dùng';
    final createdAt = request['createdAt']?.toString() ?? '';

    final statusColor = status == 'APPROVED'
        ? const Color(0xFF10B981)
        : status == 'REJECTED'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);
    final statusLabel = status == 'APPROVED'
        ? 'Đã duyệt'
        : status == 'REJECTED'
            ? 'Từ chối'
            : 'Chờ xử lý';

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
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(requestedBy, style: TextStyle(fontSize: 11, color: colors.textMuted)),
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
            Text(description, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(createdAt.substring(0, 10), style: TextStyle(fontSize: 10, color: colors.textMuted)),
          ],
          if (status == 'PENDING') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    'Duyệt', Icons.check_rounded, const Color(0xFF10B981), () => _handleAction(request['id'], 'APPROVED', colors),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    'Từ chối', Icons.close_rounded, const Color(0xFFEF4444), () => _handleAction(request['id'], 'REJECTED', colors),
                    outlined: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap, {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: outlined ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: outlined ? color : color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: outlined ? color : color)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(String? id, String status, AppColorsExtension colors) async {
    if (id == null) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/admin/change-requests/$id', data: {'status': status});
      ref.invalidate(_adminChangeRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'APPROVED' ? 'Đã duyệt yêu cầu' : 'Đã từ chối yêu cầu'),
          backgroundColor: const Color(0xFF10B981),
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

final _adminChangeRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/change-requests', queryParameters: {'limit': 100});
  final data = response.data['data'] as List<dynamic>? ?? [];
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
